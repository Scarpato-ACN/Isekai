#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Flèche — sviluppato da Salvatore Scarpato e Marco
"""
Flèche — confine di scrittura per agente.

PERCHE' UN GUARD MINIMO E NON UN CONTROL PLANE COMPLETO
--------------------------------------------------------
Un control plane completo comprende identita' firmata degli agenti, gate sul
runtime loop, manifest di integrita' dei propri componenti, confine di
esecuzione dei processi figli, confine di rete, classificatore dei comandi
shell. Ognuno di quei pezzi esiste per una minaccia che si presenta in un
sistema che gira per ore, non presidiato, su progetti reali.

In cinque ore di hackathon con due persone davanti allo schermo, la maggior
parte di quelle minacce non si presenta: nessun agente gira non presidiato,
nessun subagente si dichiara qualcun altro, nessuno manomette il control plane.
Trapiantarle tutte avrebbe prodotto un sistema che costa tempo e non protegge
da niente di reale.

Quello che resta e' cio' che serve davvero quando piu' agenti scrivono nello
stesso progetto: **chi puo' scrivere dove**. Con una ragione precisa —
l'agente che valuta la chiarezza di una semplificazione non deve poter
modificare cio' che valuta, altrimenti la sua valutazione non vale nulla. E'
un valutatore che puo' correggere cio' che valuta segnala solo cio' che sa
sistemare, e tace sul resto.

COSA QUESTO GUARD NON FA, E VA SAPUTO
--------------------------------------
Non verifica l'identita' dell'agente: si fida di `subagent_type` nel payload.
E' un difetto noto e non banale: Claude Code assegna ai subagenti id opachi
generati per dispatch, che non corrispondono ai nomi degli agenti. Un
capability model che si aspetti il nome cade sui default e diventa inerte.

Qui la mitigazione e' diversa e piu' debole: se l'id non corrisponde a un
agente noto, il guard NON nega tutto (renderebbe il sistema inutilizzabile in
un hackathon) ma applica il profilo piu' permissivo fra quelli dichiarati,
registrandolo nel log come `identity_unresolved`.

E' un compromesso consapevole, adatto al contesto e non replicabile in
produzione: in un hackathon presidiato il costo di un blocco spurio supera il
rischio di un permesso concesso a un agente non identificato. In un sistema
non presidiato la scelta sarebbe opposta: negare tutto in assenza di
identita' verificabile.
"""

import json
import os
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
ROOT = HERE.parent
CAPS = HERE / "capabilities.json"
LOG_DIR = ROOT / "logs" / "enforcement"

WRITE_TOOLS = {"Write", "Edit", "MultiEdit", "NotebookEdit"}


def _load():
    try:
        return json.loads(CAPS.read_text(encoding="utf-8"))
    except Exception:  # noqa: BLE001
        return None


def _audit(decision, agent, rule, target, session_id=None, note=None):
    try:
        LOG_DIR.mkdir(parents=True, exist_ok=True)
        rec = {
            "schema": "fleche.enforcement.v1",
            "ts": time.time(),
            "iso": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
            "hook": "capability-guard",
            "decision": decision,
            "agent": agent,
            "rule_id": rule,
            "target": str(target)[:200] if target else None,
            "session_id": session_id,
            "note": note,
        }
        fn = LOG_DIR / f"fleche_{time.strftime('%Y-%m-%d')}.jsonl"
        with open(fn, "a", encoding="utf-8") as fh:
            fh.write(json.dumps(rec, ensure_ascii=False) + "\n")
    except Exception:  # noqa: BLE001
        pass


def _match(path, patterns):
    """Corrispondenza glob su un percorso relativo al progetto.

    `fnmatch` da solo non gestisce `**`: `docs/**` non corrisponderebbe a
    `docs/a/b.md`. Si normalizza il pattern in un prefisso quando finisce con
    `/**`, che e' la forma usata in capabilities.json.
    """
    import fnmatch
    p = _norm(path)
    for pat in patterns or []:
        pat = _norm(pat)
        if pat.endswith("/**"):
            if p == pat[:-3] or p.startswith(pat[:-2]):
                return pat
        elif fnmatch.fnmatch(p, pat):
            return pat
        # un pattern senza directory deve valere anche in sottocartelle:
        # `*.md` copre `docs/x.md`
        elif "/" not in pat and fnmatch.fnmatch(os.path.basename(p), pat):
            return pat
    return None


def _norm(p):
    """Normalizza un percorso per il confronto, su qualunque sistema.

    Tre cose, e ognuna copre un caso reale:

    1. backslash → slash. Su Windows i percorsi arrivano come
       `C:\\Users\\x\\src\\app.js`, i pattern sono scritti con slash.
    2. lettera di unita' in minuscolo. Windows non distingue `C:` da `c:`, ma
       un confronto di stringhe si': un `cwd` con `C:` e un target con `c:`
       non si riconoscerebbero come lo stesso prefisso, e il percorso non
       verrebbe relativizzato.
    3. `./` iniziale rimosso in modo iterativo. `lstrip("./")` sarebbe
       sbagliato: rimuove QUALUNQUE carattere dell'insieme, quindi `.env`
       diventerebbe `env` e un dotfile perderebbe il punto.
    """
    q = str(p or "").replace("\\", "/")
    if len(q) > 1 and q[1] == ":":
        q = q[0].lower() + q[1:]
    while q.startswith("./"):
        q = q[2:]
    return q


def _relative(target, cwd):
    """Percorsi candidati da valutare: relativo al progetto e assoluto.

    La forma assoluta e' un buco facile da lasciare aperto: i pattern sono
    relativi al progetto, e un percorso assoluto non corrisponde a nessuno di
    essi. Va relativizzato prima del confronto, non dopo.
    """
    t = _norm(target)
    out = []
    if cwd:
        c = _norm(cwd).rstrip("/")
        if t.lower().startswith(c.lower() + "/"):
            # confronto insensibile al caso per il PREFISSO, perche' Windows e
            # macOS hanno filesystem che non distinguono il caso; la parte
            # relativa conserva il caso originale, che serve ai pattern.
            out.append(t[len(c) + 1:])
    out.append(t.lstrip("/") if t.startswith("/") else t)
    return [x for x in out if x]


def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    tool = payload.get("tool_name") or ""
    if tool not in WRITE_TOOLS:
        sys.exit(0)

    caps = _load()
    if not caps:
        # Nessuna configurazione: non blocca. Un hackathon in cui il guard
        # impedisce di lavorare perche' manca un file di configurazione e' un
        # guard che verra' disinstallato entro dieci minuti.
        sys.exit(0)

    ti = payload.get("tool_input") or {}
    target = ti.get("file_path") or ti.get("notebook_path") or ""
    cwd = payload.get("cwd")
    session_id = payload.get("session_id")
    declared = payload.get("subagent_type")

    agents = caps.get("agents", {})
    note = None
    if declared in agents:
        agent = declared
        prof = agents[agent]
    else:
        # Id non risolvibile: vedi il compromesso dichiarato nel docstring.
        agent = caps.get("fallback_agent")
        prof = agents.get(agent)
        note = f"identity_unresolved: payload dichiarava {declared!r}"
        if not prof:
            sys.exit(0)

    scopes = caps.get("write_scopes", {})
    scope_name = prof.get("write")
    if scope_name == "all":
        _audit("ALLOW", agent, "write_all", target, session_id, note)
        sys.exit(0)
    if scope_name == "none":
        _audit("BLOCK", agent, "write_none", target, session_id, note)
        print(f"FLÈCHE — SCRITTURA NEGATA\n"
              f"agente: {agent}\n"
              f"target: {target}\n"
              f"Questo agente non ha permesso di scrittura: "
              f"{prof.get('why_none', 'vedi capabilities.json')}",
              file=sys.stderr)
        sys.exit(2)

    patterns = scopes.get(scope_name, [])
    candidates = _relative(target, cwd)
    hit = next((_match(c, patterns) for c in candidates if _match(c, patterns)), None)
    if hit:
        _audit("ALLOW", agent, f"scope:{scope_name}", target, session_id, note)
        sys.exit(0)

    _audit("BLOCK", agent, f"scope:{scope_name}", target, session_id, note)
    print(f"FLÈCHE — SCRITTURA FUORI SCOPE\n"
          f"agente: {agent} · scope: {scope_name}\n"
          f"target: {target}\n"
          f"forme valutate: {candidates}\n"
          f"pattern consentiti: {patterns}\n"
          f"{prof.get('why_scope', '')}",
          file=sys.stderr)
    sys.exit(2)


if __name__ == "__main__":
    main()

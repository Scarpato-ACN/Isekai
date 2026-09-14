#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Flèche — sviluppato da Salvatore Scarpato e Marco
"""
Gate di coverage dei REQUISITI: ogni criterio di accettazione ha un test?

NON misura la copertura del codice. Righe e branch sono una metrica diversa: si
puo' avere il 90% di righe coperte e zero test su un criterio. Qui si misura se
cio' che il ticket DICHIARA verificabile sia effettivamente verificato.

Un criterio senza test non e' un criterio: e' un'intenzione. Il ticket lo
dichiara, la pipeline lo attraversa, e nessuno scopre che nessun test lo
esercita.

LIMITE DICHIARATO: la corrispondenza e' per riferimento esplicito — il test
deve citare `AC-3`. Non verifica che il test ESERCITI quel criterio, solo che
qualcuno abbia dichiarato la connessione. Un test che cita AC-3 senza testarlo
passa il gate.

E' deliberato: l'alternativa — far giudicare a un modello se un test copre
semanticamente un criterio — introdurrebbe un secondo livello di fiducia
proprio dove il gate deve dare una risposta deterministica.
"""

import re
import sys
from pathlib import Path

AC_HEADINGS = ("criteri di accettazione", "acceptance criteria")
AC_ID = re.compile(r"^\s*[-*]?\s*\**\s*(AC[-_ ]?[\w.\-]+)", re.IGNORECASE)
AC_REF = re.compile(r"\bAC[-_ ]?([\w.\-]+)", re.IGNORECASE)
TEST_EXT = (".ts", ".tsx", ".js", ".jsx", ".py", ".dart", ".go")
SKIP = {"node_modules", ".git", "dist", "build", ".next", "venv", "__pycache__"}


def norm(raw):
    """`AC-3`, `**AC_3**`, `ac 3` → `ac-3`.

    I marcatori markdown vanno via PRIMA del prefisso: `**AC-3**` altrimenti
    diventa `ac-ac-3`, un criterio fantasma. E i separatori interni vanno
    normalizzati come quello iniziale, altrimenti `AC_threat_2` e
    `AC-threat-2` restano distinti.
    """
    s = str(raw).strip().lower().strip("*_`\"' \t")
    s = re.sub(r"^ac[-_ ]?", "", s)
    s = re.sub(r"[_\s]+", "-", s)
    s = re.sub(r"[^\w.\-]", "", s)
    return "ac-" + re.sub(r"-{2,}", "-", s).strip("-_.")


def criteri(testo):
    out, dentro = [], False
    for line in (testo or "").splitlines():
        if line.strip().startswith("#"):
            low = line.lower().lstrip("#").strip()
            dentro = any(h in low for h in AC_HEADINGS)
            continue
        if not dentro:
            continue
        m = AC_ID.match(line)
        if m:
            n = norm(m.group(1))
            if n != "ac-" and n not in out:
                out.append(n)
    return out


def file_test(root):
    root = Path(root)
    found = []
    for p in root.rglob("*"):
        if not p.is_file() or any(x in SKIP for x in p.parts):
            continue
        if p.suffix.lower() not in TEST_EXT:
            continue
        low = p.name.lower()
        parts = {x.lower() for x in p.parts}
        if (parts & {"test", "tests", "spec", "specs", "__tests__", "e2e"}
                or ".test." in low or ".spec." in low or low.startswith("test_")):
            found.append(p)
    return sorted(found)


def riferimenti(paths):
    refs = {}
    for p in paths:
        try:
            txt = p.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        for i, line in enumerate(txt.splitlines(), 1):
            for m in AC_REF.finditer(line):
                n = norm("AC-" + m.group(1))
                if n == "ac-":
                    continue
                refs.setdefault(n, []).append(f"{p}:{i}")
    return refs


def main(argv):
    root = Path(argv[0]) if argv else Path.cwd()
    ticket = None
    for cand in (root / "docs" / "scenario.md", root / "docs" / "acceptance.md"):
        if cand.is_file():
            ticket = cand
            break
    if not ticket:
        print("nessun docs/scenario.md ne' docs/acceptance.md: "
              "non esiste una baseline contro cui misurare.", file=sys.stderr)
        return 2

    cs = criteri(ticket.read_text(encoding="utf-8", errors="replace"))
    tf = file_test(root)
    refs = riferimenti(tf)

    print(f"COVERAGE DEI REQUISITI — {ticket.name}")
    print(f"  {len(tf)} file di test esaminati")
    print()
    if not cs:
        print("  NESSUN criterio di accettazione dichiarato.")
        print("  La copertura non e' calcolabile — e questo NON e' un successo:")
        print("  un ticket senza criteri non e' verificabile.")
        return 1

    scoperti = []
    for c in cs:
        where = refs.get(c)
        if where:
            print(f"  {c:16} OK    {where[0]}"
                  + (f" (+{len(where)-1})" if len(where) > 1 else ""))
        else:
            print(f"  {c:16} NESSUN TEST")
            scoperti.append(c)

    orfani = sorted(set(refs) - set(cs))
    if orfani:
        print()
        print("  test che citano criteri assenti dal ticket: " + ", ".join(orfani))
        print("  (ticket modificato dopo i test, oppure identificativo errato:")
        print("   in entrambi i casi la connessione requisito-verifica e' rotta)")

    print()
    pct = int(round(100 * (len(cs) - len(scoperti)) / len(cs)))
    print(f"  {len(cs)-len(scoperti)}/{len(cs)} criteri coperti ({pct}%)")
    if scoperti:
        print(f"  NON VERIFICATI: {', '.join(scoperti)}")
        print("  Un criterio senza test non e' un criterio: e' un'intenzione.")
        return 1
    print()
    print("  Nota: il gate verifica che un test CITI il criterio, non che lo")
    print("  eserciti. Un test che cita AC-3 senza testarlo passa.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

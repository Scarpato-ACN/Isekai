#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Flèche — sviluppato da Salvatore Scarpato e Marco
"""
Consumo di token per agente e per passaggio.

COSA FA E COSA NON FA
---------------------
MISURA il consumo leggendo i transcript di Claude Code, che contengono i
conteggi per turno. Aggrega per agente quando il transcript lo riporta.

NON limita in modo predittivo. Gli hook girano PRIMA di un'azione, e in quel
momento il costo del turno non e' ancora noto: si puo' solo reagire al
consumo GIA' registrato. Un limite che blocchi a meta' di un passaggio
necessario, in un hackathon di cinque ore, costa piu' di quanto risparmi.

NON riduce. La riduzione non e' un controllo, e' una scelta di progetto:
`genera → gap → rigenera` contro `input validato → one-shot`. Le leve sono
nell'architettura e non qui —

  · f-analyst chiede TUTTO in un batch, non una domanda alla volta
  · f-test-design produce la baseline PRIMA del codice, cosi' f-dev non
    rigenera su specifica lacunosa
  · f-tester riporta numeri e non rilegge il codice

Se un agente consuma molto piu' del previsto, di solito sta rigenerando su un
input incompleto: la risposta e' tornare al passaggio precedente, non
insistere. Questo strumento serve ad accorgersene.
"""

import json
import os
import sys
from pathlib import Path

CANDIDATI = [
    Path.home() / ".claude" / "projects",
    Path.home() / ".config" / "claude" / "projects",
]


def _transcript_dirs():
    out = [d for d in CANDIDATI if d.is_dir()]
    env = os.environ.get("CLAUDE_TRANSCRIPT_DIR")
    if env and Path(env).is_dir():
        out.insert(0, Path(env))
    return out


def _usage(rec):
    """Conteggi di token da un record di transcript, in qualunque forma.

    Il formato non e' documentato e puo' cambiare: si cercano le chiavi note
    senza assumere una struttura fissa. Se non si trova nulla, si ritorna zero
    invece di sollevare — un report parziale e' utile, un crash no.
    """
    u = None
    for k in ("usage", "message"):
        v = rec.get(k)
        if isinstance(v, dict):
            u = v.get("usage") if k == "message" else v
            if isinstance(u, dict):
                break
            u = None
    if not isinstance(u, dict):
        return 0, 0
    inp = (u.get("input_tokens") or 0) + (u.get("cache_read_input_tokens") or 0) \
        + (u.get("cache_creation_input_tokens") or 0)
    return int(inp), int(u.get("output_tokens") or 0)


def raccogli(limite_file=40):
    righe = []
    for d in _transcript_dirs():
        for f in sorted(d.rglob("*.jsonl"),
                        key=lambda p: p.stat().st_mtime, reverse=True)[:limite_file]:
            try:
                for line in f.read_text(encoding="utf-8", errors="replace").splitlines():
                    if not line.strip():
                        continue
                    try:
                        r = json.loads(line)
                    except json.JSONDecodeError:
                        continue
                    i, o = _usage(r)
                    if i or o:
                        righe.append({
                            "file": f.name,
                            "agent": r.get("subagent_type") or r.get("agent") or "-",
                            "in": i, "out": o,
                        })
            except OSError:
                continue
    return righe


def main(argv):
    righe = raccogli()
    if not righe:
        print("Nessun transcript trovato con conteggi di token.")
        print("Percorsi cercati:")
        for d in CANDIDATI:
            print(f"  {d}  {'(esiste)' if d.is_dir() else '(assente)'}")
        print()
        print("Indica una directory con CLAUDE_TRANSCRIPT_DIR se e' altrove.")
        print("Nota: senza transcript il consumo non e' misurabile — e non")
        print("      significa che sia zero.")
        return 1

    per_agente = {}
    for r in righe:
        a = per_agente.setdefault(r["agent"], {"in": 0, "out": 0, "turni": 0})
        a["in"] += r["in"]
        a["out"] += r["out"]
        a["turni"] += 1

    tot_in = sum(a["in"] for a in per_agente.values())
    tot_out = sum(a["out"] for a in per_agente.values())

    print("CONSUMO DI TOKEN")
    print(f"  {'agente':18} {'turni':>6} {'input':>12} {'output':>10}")
    for a, v in sorted(per_agente.items(), key=lambda x: -(x[1]["in"] + x[1]["out"])):
        print(f"  {a[:18]:18} {v['turni']:>6} {v['in']:>12,} {v['out']:>10,}")
    print(f"  {'TOTALE':18} {len(righe):>6} {tot_in:>12,} {tot_out:>10,}")
    print()
    print(f"  totale token: {tot_in + tot_out:,}")
    print()
    print("  Nota: l'output costa piu' dell'input, e l'input include la cache.")
    print("  Un agente con molti turni e poco output sta rileggendo contesto;")
    print("  uno con molto output su un solo turno sta generando.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

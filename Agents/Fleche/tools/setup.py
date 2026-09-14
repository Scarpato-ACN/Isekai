#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Flèche — sviluppato da Salvatore Scarpato e Marco
"""
Installazione: rileva l'interprete Python e scrive hooks.json di conseguenza.

IL PROBLEMA CHE RISOLVE
-----------------------
`hooks.json` deve contenere un comando, e quel comando nomina l'interprete. Ma
il nome cambia con il sistema:

    Linux, macOS     python3
    Windows          python, oppure py -3

Un `hooks.json` che dice `python3` non funziona su Windows nativo; uno che dice
`python` non funziona su molte installazioni Linux, dove `python` non esiste o
punta a Python 2.

IL MODO IN CUI FALLISCE E' LA PARTE PERICOLOSA
-----------------------------------------------
L'hook non parte, Claude Code non lo segnala, e l'azione procede. Il sistema
SEMBRA funzionare e non applica alcun controllo — peggio di un errore visibile,
perche' chi lo usa crede di avere protezioni che non ci sono.

E' la ragione per cui questo script non si limita a scrivere il file: verifica
che gli hook siano effettivamente eseguibili con l'interprete scelto, e lo dice
se non lo sono.

PERCHE' NON UN FALLBACK NEL COMANDO
------------------------------------
La forma `python3 hook.py || python hook.py` sembra la soluzione ovvia ed e'
sbagliata, per una ragione specifica di questi hook: escono con codice 2 per
NEGARE un'azione.

L'operatore `||` interpreterebbe quel 2 come fallimento dell'interprete ed
eseguirebbe il secondo comando — con lo stdin gia' consumato dal primo. Doppio
messaggio e comportamento indefinito proprio nel caso che conta, cioe' quando
il controllo sta bloccando.

PERCHE' NON UN LANCIATORE INTERMEDIO
-------------------------------------
Un primo tentativo prevedeva uno script che usasse `sys.executable` per
invocare gli hook. Non risolveva niente: qualcosa doveva comunque lanciare il
lanciatore, e il problema del nome si riproponeva identico un livello piu' in
basso.

Scrivere il nome giusto una volta, all'installazione, e verificare che
funzioni, e' la soluzione piu' semplice che funziona davvero.
"""

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HOOKS_JSON = ROOT / "hooks" / "hooks.json"
SCRIPTS = ROOT / "hooks" / "scripts"

HOOK_MAP = {
    "UserPromptSubmit": [("", "guardrail-finanza.py")],
    "PreToolUse": [("Write|Edit|MultiEdit|NotebookEdit|Bash", "capability-guard.py")],
}


def trova_interprete():
    """Nome di un interprete Python 3 invocabile, oppure None.

    L'ordine non e' arbitrario. `sys.executable` viene per primo perche' e'
    l'unico valore garantito corretto: e' l'interprete che sta eseguendo questo
    script. I nomi generici vengono dopo, come ripiego per il caso in cui il
    percorso assoluto contenga spazi o caratteri che complicano la citazione
    dentro il JSON.
    """
    candidati = []
    if sys.executable:
        candidati.append(sys.executable)
    candidati += ["python3", "python", "py -3"]

    for c in candidati:
        parti = c.split() if " " in c and not Path(c).exists() else [c]
        exe = parti[0]
        if not Path(exe).exists() and not shutil.which(exe):
            continue
        try:
            r = subprocess.run([*parti, "-c", "import sys;print(sys.version_info[0])"],
                               capture_output=True, text=True, timeout=20)
            if r.returncode == 0 and r.stdout.strip().startswith("3"):
                return c
        except (OSError, subprocess.SubprocessError):
            continue
    return None


def scrivi_hooks(interprete):
    hooks = {
        "_comment": (
            "Generato da tools/setup.py con l'interprete rilevato su questa "
            f"macchina ({interprete}). Non modificarlo a mano: rieseguire setup.py "
            "se l'interprete cambia. "
            "Il guardrail sul divieto di consulenza gira su UserPromptSubmit, "
            "cioè PRIMA che il modello possa decidere — è l'unico punto in cui un "
            "controllo intercetta la richiesta e non l'azione che ne consegue. "
            "Un controllo sulla chiamata a strumento interviene solo se il modello "
            "ha già deciso di agire, e un modello che decide di non agire non lo "
            "incontra mai."),
        "_interprete": interprete,
        "hooks": {},
    }
    for evento, voci in HOOK_MAP.items():
        entries = []
        for matcher, script in voci:
            e = {"hooks": [{
                "type": "command",
                "command": f'{interprete} "${{CLAUDE_PLUGIN_ROOT}}/hooks/scripts/{script}"',
            }]}
            if matcher:
                e["matcher"] = matcher
            entries.append(e)
        hooks["hooks"][evento] = entries
    HOOKS_JSON.write_text(json.dumps(hooks, indent=2, ensure_ascii=False) + "\n",
                          encoding="utf-8")


def verifica(interprete):
    """Esegue ogni hook con un payload innocuo. Non basta che il file esista.

    Un hook che c'e' ma non parte — modulo mancante, permessi, encoding — non
    produce nessun segnale durante l'uso: l'azione passa e nessuno se ne
    accorge. Va provato ora.
    """
    esiti = []
    parti = interprete.split() if " " in interprete and not Path(interprete).exists() \
        else [interprete]
    prove = [
        ("guardrail-finanza.py",
         {"prompt": "Cos'è il TAEG?", "session_id": "setup"}, "passa"),
        ("guardrail-finanza.py",
         {"prompt": "Quale conto mi conviene aprire?", "session_id": "setup"}, "blocca"),
        ("capability-guard.py",
         {"session_id": "setup", "cwd": str(ROOT), "tool_name": "Write",
          "tool_input": {"file_path": "src/x.js"}, "subagent_type": "f-dev"}, "consente"),
        ("capability-guard.py",
         {"session_id": "setup", "cwd": str(ROOT), "tool_name": "Write",
          "tool_input": {"file_path": "src/x.js"}, "subagent_type": "f-clarity"}, "nega"),
    ]
    for script, payload, atteso in prove:
        p = SCRIPTS / script
        if not p.is_file():
            esiti.append((script, atteso, "FILE ASSENTE"))
            continue
        try:
            r = subprocess.run([*parti, str(p)], input=json.dumps(payload),
                               capture_output=True, text=True, timeout=30)
        except (OSError, subprocess.SubprocessError) as exc:
            esiti.append((script, atteso, f"NON ESEGUIBILE: {exc}"))
            continue
        out = (r.stdout or "").strip()
        if atteso == "passa":
            ok = not out or "block" not in out
        elif atteso == "blocca":
            ok = bool(out) and "block" in out
        elif atteso == "consente":
            ok = r.returncode != 2
        else:
            ok = r.returncode == 2
        esiti.append((script, atteso, "ok" if ok else
                      f"ESITO INATTESO (rc={r.returncode}, out={out[:60]!r})"))
    return esiti


def main():
    print("FLÈCHE — installazione")
    print(f"  sistema:  {sys.platform}")
    print(f"  pacchetto: {ROOT}")
    print()

    interprete = trova_interprete()
    if not interprete:
        print("  ✗ nessun interprete Python 3 trovato.", file=sys.stderr)
        print("    Flèche richiede Python 3. Installalo e ripeti.", file=sys.stderr)
        return 1
    print(f"  interprete: {interprete}")

    scrivi_hooks(interprete)
    print(f"  scritto:    hooks/hooks.json")
    print()

    print("  verifica degli hook:")
    esiti = verifica(interprete)
    problemi = [e for e in esiti if e[2] != "ok"]
    for script, atteso, esito in esiti:
        segno = "·" if esito == "ok" else "✗"
        print(f"    {segno} {script:24} {atteso:10} {esito}")
    print()

    if problemi:
        print("  ✗ INSTALLAZIONE INCOMPLETA: alcuni hook non si comportano come atteso.",
              file=sys.stderr)
        print("    Il sistema caricherebbe gli agenti SENZA applicare i controlli,",
              file=sys.stderr)
        print("    e non lo segnalerebbe durante l'uso.", file=sys.stderr)
        return 1

    print("  ✓ installazione completa. Avvia con:")
    print(f"      claude --plugin-dir \"{ROOT}\"")
    print()
    print("  Verifica dentro la sessione scrivendo:")
    print("      Quale conto mi conviene aprire?")
    print("  Deve comparire FLÈCHE — RICHIESTA FUORI PERIMETRO EDUCATIVO.")
    print("  Se passa, gli hook non vengono eseguiti da questa installazione di")
    print("  Claude Code — su postazioni gestite può essere una restrizione di policy.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

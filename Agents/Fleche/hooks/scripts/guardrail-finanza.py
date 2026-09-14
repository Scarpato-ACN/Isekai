#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Flèche — sviluppato da Salvatore Scarpato e Marco
"""
Flèche — guardrail sul divieto di consulenza finanziaria.

PERCHE' ESISTE, E PERCHE' NON E' UN PROMPT
-------------------------------------------
La challenge vieta esplicitamente raccomandazioni di investimento, consulenza
personalizzata e indicazioni su cosa comprare, vendere o scegliere. E chiede,
come terzo deliverable, una "Risk & Clarity Note": cosa e' stato semplificato,
cosa non e' stato alterato, come e' stata evitata l'ambiguita'.

Un'istruzione nel prompt — "non dare consigli finanziari" — soddisfa il primo
requisito in modo non verificabile: il modello la interpreta, e nessuno puo'
dimostrare a posteriori che l'abbia rispettata in un dato momento.

Un guardrail deterministico soddisfa entrambi: blocca prima della risposta, e
lascia un record nella catena di audit. La Risk Note diventa un artefatto
prodotto dal sistema invece di un testo scritto a mano.

IL LIMITE, DICHIARATO QUI E NELLA RISK NOTE
--------------------------------------------
Questi pattern intercettano la FORMA della richiesta, non la sua sostanza. Una
domanda obliqua — "un mio amico si chiede se conviene..." — puo' passare. Il
guardrail riduce la superficie di rischio, non la annulla: il giudizio del
modello resta necessario, e i due livelli sono complementari.

Dichiararlo e' parte della Risk Note. Un guardrail presentato come completo
sarebbe piu' pericoloso di uno assente, perche' chi lo usa smetterebbe di
sorvegliare cio' che non copre.
"""

import json
import os
import re
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent          # hooks/
ROOT = HERE.parent                                      # plugin root
GUARDRAILS = HERE / "guardrails.json"
LOG_DIR = ROOT / "logs" / "enforcement"


def _load():
    try:
        return json.loads(GUARDRAILS.read_text(encoding="utf-8"))
    except Exception:  # noqa: BLE001
        return None


def _audit(decision, rule_id, prompt, extra=None):
    """Registra la decisione. Non solleva mai.

    Il prompt NON viene registrato in chiaro: puo' contenere dati finanziari
    personali — importi, saldi, situazioni familiari — e il log e' un file sul
    disco. Si registra la lunghezza e un hash, che bastano a correlare la
    decisione con la sessione senza conservare il contenuto.

    Un sistema che protegge l'utente e poi ne archivia i dati sensibili nel
    proprio log protegge male.
    """
    try:
        import hashlib
        LOG_DIR.mkdir(parents=True, exist_ok=True)
        rec = {
            "schema": "fleche.enforcement.v1",
            "ts": time.time(),
            "iso": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
            "hook": "guardrail-finanza",
            "decision": decision,
            "rule_id": rule_id,
            "prompt_len": len(prompt or ""),
            "prompt_sha256": hashlib.sha256(
                (prompt or "").encode("utf-8", "replace")).hexdigest()[:16],
            "session_id": (extra or {}).get("session_id"),
        }
        fn = LOG_DIR / f"fleche_{time.strftime('%Y-%m-%d')}.jsonl"
        with open(fn, "a", encoding="utf-8") as fh:
            fh.write(json.dumps(rec, ensure_ascii=False) + "\n")
    except Exception:  # noqa: BLE001
        pass


def evaluate(prompt, rules=None):
    """(decision, rule) per un prompt. `decision` in deny | ask | allow."""
    rules = rules or _load()
    if not rules or not prompt:
        return "allow", None
    for pat in rules.get("prohibited", []):
        try:
            if re.search(pat["regex"], prompt, re.IGNORECASE):
                return pat.get("severity", "deny"), pat
        except re.error:
            continue
    return "allow", None


def _message(pat):
    return (
        "FLÈCHE — RICHIESTA FUORI PERIMETRO EDUCATIVO\n"
        f"regola: {pat['id']}\n"
        f"{pat['description']}\n\n"
        f"Perché: {pat['why_prohibited']}\n\n"
        f"{pat['redirect']}\n\n"
        "Questo blocco è deterministico e registrato: il perimetro educativo "
        "non dipende dall'interpretazione del modello."
    )


def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    prompt = payload.get("prompt", "")
    if not prompt or not isinstance(prompt, str):
        sys.exit(0)

    decision, pat = evaluate(prompt)

    if decision == "deny":
        _audit("BLOCK", pat["id"], prompt, payload)
        print(json.dumps({"decision": "block", "reason": _message(pat)},
                         ensure_ascii=False))
        sys.exit(0)

    if decision == "ask":
        _audit("ASK", pat["id"], prompt, payload)
        print(json.dumps({"systemMessage": _message(pat)}, ensure_ascii=False))
        sys.exit(0)

    # Prompt dentro il perimetro: registrato come NO_MATCH.
    #
    # Il record sul caso consentito non e' ridondante. Distingue "il guardrail
    # ha valutato e non ha trovato nulla" da "il guardrail non ha girato" — e
    # senza quella distinzione la Risk Note non potrebbe affermare che il
    # controllo era attivo durante la sessione. Senza il record sul caso
    # consentito, l'assenza di blocchi sarebbe indistinguibile dall'assenza di
    # controllo.
    _audit("NO_MATCH", "within_scope", prompt, payload)
    sys.exit(0)


if __name__ == "__main__":
    main()

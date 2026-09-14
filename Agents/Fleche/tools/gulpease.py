#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Flèche — sviluppato da Salvatore Scarpato e Marco
"""
Indice Gulpease: leggibilità di un testo italiano.

PERCHE' GULPEASE E NON FLESCH
------------------------------
Flesch-Kincaid è tarato sull'inglese e conta le sillabe. L'italiano ha parole
più lunghe e una struttura sillabica diversa: applicato all'italiano, Flesch
sottostima sistematicamente la leggibilità.

Gulpease (Lucisano e Piemontese, 1988) è costruito sull'italiano e conta le
LETTERE invece delle sillabe — che è anche il motivo per cui si calcola in
modo deterministico, senza un dizionario di sillabazione.

    89 + (300 * frasi - 10 * lettere) / parole

    100-80  leggibile da chi ha la licenza elementare
     80-60  leggibile da chi ha la licenza media
     60-40  leggibile da chi ha un diploma superiore
      < 40  difficile per la maggior parte dei lettori

PERCHE' QUESTO E' IL DELIVERABLE 02
------------------------------------
La challenge chiede una "Before / After Simplicity Evidence": un esempio di
testo reso più chiaro. Un confronto affiancato è un'opinione; "Gulpease 38 →
71" è una misura, riproducibile da chiunque con la stessa formula.

IL LIMITE, CHE VA DICHIARATO NELLA RISK NOTE
---------------------------------------------
Gulpease misura la FORMA, non la comprensibilità. Un testo con frasi brevi e
parole corte ottiene un punteggio alto anche se il contenuto è sbagliato,
incompleto o fuorviante.

Concretamente: accorciare una frase omettendo una condizione ALZA il Gulpease
e PEGGIORA il documento. La metrica non lo rileva — lo rileva `f-clarity` con
il confronto elemento per elemento.

Le due misure sono complementari e nessuna delle due basta: Gulpease dice se è
più facile da leggere, f-clarity dice se dice ancora la stessa cosa. Presentare
solo la prima sarebbe il modo più elegante di nascondere un'omissione.
"""

import re
import sys


def _conta(testo):
    """Lettere, parole e frasi secondo la definizione di Gulpease.

    Le scelte di conteggio, che vanno dichiarate perché cambiano il risultato:
    - LETTERE: solo caratteri alfabetici. Cifre e punteggiatura escluse.
      Un importo "€ 2.500,00" conta zero lettere ma una parola — corretto,
      perché la difficoltà di lettura di una cifra non sta nelle sue lettere.
    - PAROLE: sequenze separate da spazi che contengono almeno un carattere
      alfanumerico.
    - FRASI: separate da . ! ? ; e da fine riga. Il punto e virgola conta
      perché in un documento bancario separa condizioni, e trattarlo come
      continuazione sovrastimerebbe la lunghezza delle frasi.
    """
    lettere = len(re.findall(r"[A-Za-zÀ-ÿ]", testo))
    parole = len([p for p in re.split(r"\s+", testo) if re.search(r"\w", p)])
    # una frase vuota (doppio punto, fine testo) non conta
    frasi = len([f for f in re.split(r"[.!?;\n]+", testo) if re.search(r"\w", f)])
    return lettere, parole, frasi


def gulpease(testo):
    """Indice Gulpease, o None se il testo è troppo corto per essere misurato."""
    lettere, parole, frasi = _conta(testo)
    if parole == 0:
        return None
    # Sotto le ~20 parole l'indice oscilla molto: una frase in più cambia il
    # risultato di decine di punti. Restituirlo comunque, ma il chiamante deve
    # sapere che non è affidabile.
    val = 89 + (300 * frasi - 10 * lettere) / parole
    return max(0.0, min(100.0, round(val, 1)))


def livello(indice):
    if indice is None:
        return "non calcolabile"
    if indice >= 80:
        return "licenza elementare"
    if indice >= 60:
        return "licenza media"
    if indice >= 40:
        return "diploma superiore"
    return "difficile per la maggior parte dei lettori"


def analizza(testo, etichetta=""):
    lettere, parole, frasi = _conta(testo)
    idx = gulpease(testo)
    return {
        "etichetta": etichetta,
        "gulpease": idx,
        "livello": livello(idx),
        "lettere": lettere,
        "parole": parole,
        "frasi": frasi,
        "parole_per_frase": round(parole / frasi, 1) if frasi else None,
        "lettere_per_parola": round(lettere / parole, 1) if parole else None,
        "affidabile": parole >= 20,
        "nota_affidabilita": (
            None if parole >= 20 else
            f"solo {parole} parole: sotto le 20 l'indice oscilla di decine di "
            "punti per una frase in più. Il valore è indicativo."),
    }


def confronta(prima, dopo):
    a, b = analizza(prima, "prima"), analizza(dopo, "dopo")
    delta = None
    if a["gulpease"] is not None and b["gulpease"] is not None:
        delta = round(b["gulpease"] - a["gulpease"], 1)
    return {
        "prima": a, "dopo": b, "delta": delta,
        "livello_cambiato": a["livello"] != b["livello"],
        "avvertenza": (
            "Gulpease misura la FORMA, non la comprensibilità. Accorciare una "
            "frase omettendo una condizione alza l'indice e peggiora il "
            "documento: questa metrica non lo rileva. Va letta insieme al "
            "confronto elemento per elemento di f-clarity."),
    }


def _fmt(d):
    out = [f"  {d['etichetta'] or 'testo'}: Gulpease {d['gulpease']} — {d['livello']}",
           f"    {d['parole']} parole · {d['frasi']} frasi · "
           f"{d['parole_per_frase']} parole/frase · {d['lettere_per_parola']} lettere/parola"]
    if d["nota_affidabilita"]:
        out.append(f"    ATTENZIONE: {d['nota_affidabilita']}")
    return "\n".join(out)


def main(argv):
    if len(argv) == 2:
        prima = open(argv[0], encoding="utf-8").read()
        dopo = open(argv[1], encoding="utf-8").read()
        r = confronta(prima, dopo)
        print("CONFRONTO DI LEGGIBILITÀ")
        print(_fmt(r["prima"]))
        print(_fmt(r["dopo"]))
        print()
        if r["delta"] is not None:
            segno = "+" if r["delta"] > 0 else ""
            print(f"  delta: {segno}{r['delta']} punti"
                  + (" — livello di scolarità cambiato"
                     if r["livello_cambiato"] else ""))
        print()
        print(f"  {r['avvertenza']}")
        return 0
    if len(argv) == 1:
        testo = open(argv[0], encoding="utf-8").read()
        print(_fmt(analizza(testo)))
        return 0
    print("uso: gulpease.py <file>            indice di un testo\n"
          "     gulpease.py <prima> <dopo>    confronto", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

# Before / After Simplicity Evidence — Mesi di Libertà

## Metodo di calcolo

Formula applicata: `Gulpease = 89 + (300 × frasi − 10 × lettere) / parole`

Definizioni applicate in modo consistente su tutti e quattro i testi:

- **lettere**: caratteri alfabetici Unicode (incluse lettere accentate italiane); cifre escluse
- **parole**: token separati da spazio (sequenze di caratteri non-spazio)
- **frasi**: gruppi di terminatori `.` `!` `?` `;`; se il testo non termina con un terminatore, si aggiunge una frase

Nota di conteggio: i testi semplificati usano la notazione italiana per le migliaia (12.000, 4.550, 3.600), dove il punto è separatore e non fine frase. Il pattern `[.!?;]+` non distingue i due usi: After A risulta in 10 frasi invece di 8 reali, After B in 9 invece di 8. Questo gonfia leggermente i punteggi degli After. I numeri sotto riflettono il calcolo del tool, non una correzione manuale, perché il vincolo di riproducibilità richiede che chiunque ottenga lo stesso risultato applicando le stesse regole dichiarate.

---

## Esempio A — Comunicazione ISC

### La misura

| | Gulpease | livello | parole | frasi | parole/frase |
|---|---|---|---|---|---|
| originale | 60.1 | licenza media | 19 | 1 | 19.0 |
| semplificato | 71.8 | licenza media | 126 | 10 | 12.6 |

**+11.7 punti** — entrambi i testi restano nel range licenza media (60–80), ma il testo semplificato si sposta verso il centro del range, lontano dal confine con "diploma superiore" in cui l'originale si trova (60.1).

### Cosa ha prodotto il salto

- La frase unica da 19 parole diventa 10 segmenti medi da 12.6 parole ciascuno
- Le lettere per parola scendono da 4.5 a 4.1: "Indicatore Sintetico dei Costi calcolato su un orizzonte temporale" cede spazio a frasi come "Non li vedi uscire" e "La decisione resta tua"
- Il conteggio delle parole sale da 19 a 126 (+564%): non si tratta di riformulazione, ma di aggiunta di contenuto operativo (importo in euro, proiezione a 10 anni, dichiarazione esplicita del limite della misura)

### I testi

**Originale:**
> L'Indicatore Sintetico dei Costi (ISC) del comparto, calcolato su un orizzonte temporale di 10 anni, è pari a 1,45%.

**Semplificato:**
> Questo comparto trattiene ogni anno circa l'1,45% di quello che hai dentro. Sui 12.000 € che hai accantonato, quest'anno sono circa 174 €. Non li vedi uscire: vengono trattenuti prima che il tuo saldo venga aggiornato. Se continui a versare 200 €/mese e il capitale cresce ipoteticamente del 4% l'anno, in 10 anni questo costo trattiene in tutto circa 4.550 € — circa 15 mesi del tuo risparmio attuale. Questo non ti dice se il comparto è buono o cattivo, né se te ne devi andare. Un costo più alto può corrispondere a una gestione diversa, a garanzie o a servizi che potresti volere. Ti dice solo quanto costa, in euro e in tempo. La decisione resta tua, e ora hai una domanda precisa da fare.

---

## Esempio B — Addebito ricorrente

### La misura

| | Gulpease | livello | parole | frasi | parole/frase |
|---|---|---|---|---|---|
| originale | 72.3 | licenza media | 9 | 1 | 9.0 |
| semplificato | 74.1 | licenza media | 95 | 9 | 10.6 |

**+1.7 punti** — il livello rimane invariato (licenza media). Il delta minimo è il segnale più istruttivo di entrambi gli esempi.

### Cosa ha prodotto (o non prodotto) il salto

- L'originale era un'etichetta da estratto conto: 9 parole brevi con zero terminatori di frase. Gulpease lo classificava già come "medio" perché le parole sono corte — ma un testo leggibile in forma non è necessariamente comprensibile in contenuto.
- Il testo semplificato aggiunge 86 parole (+956%) e introduce il significato operativo dell'addebito: impatto sul capitale obiettivo, equivalente in mesi di libertà, dichiarazione esplicita che non si tratta di una raccomandazione. La leggibilità formale sale di soli 1.7 punti perché le nuove frasi sono comunque concise.
- Questo è il caso in cui Gulpease è meno utile: il divario reale non è nella forma ma nel contenuto. L'etichetta originale era già "leggibile" — non diceva nulla.

### I testi

**Originale:**
> Abbonamento streaming — 11,99 € — addebito ricorrente mensile

**Semplificato:**
> 11,99 € al mese pesano due volte sul tuo orizzonte di libertà. Ogni mese non finiscono nel tuo risparmio: 144 € in meno all'anno. Siccome è una spesa fissa, entra nel calcolo di quanto capitale ti serve per vivere senza stipendio. Con la regola convenzionale del 4% servono 25 volte la spesa annuale: 3.600 € di capitale obiettivo in più. Effetto combinato: circa 12 mesi di libertà. Non ti stiamo dicendo di disdire niente. Se quell'abbonamento ti dà un anno di valore, è un buon acquisto. Ti stiamo dando il prezzo corretto per deciderlo tu.

---

## Sintesi

La semplificazione produce un miglioramento di **+11.7 punti su esempio A** e **+1.7 punti su esempio B**. Il delta dell'esempio B è il risultato più significativo: indica che il testo originale era già formalmente corto ma informativamente vuoto, e che l'aggiunta di contesto non compromette la leggibilità di forma.

---

## Cosa questa misura NON dimostra

Gulpease misura la forma, non la comprensibilità. Va letto insieme alla Risk & Clarity Note (`docs/clarity/risk-clarity-note.md`).

Il rischio tipico — accorciare un testo omettendo una condizione per alzare l'indice — non si presenta qui: in entrambi i casi il conteggio delle parole aumenta drasticamente (A: da 19 a 126, +564%; B: da 9 a 95, +956%). Il segnale d'allarme sarebbe un calo di parole insieme a un salto di punteggio. Qui accade l'opposto.

Il rischio reale è simmetrico: i testi semplificati introducono numeri concreti (174 €, 4.550 €, 3.600 €, 25×) e ipotesi operative (crescita del 4% l'anno, regola del 4% per il capitale). Se uno di quei numeri è calcolato in modo scorretto, o se l'ipotesi è presentata come certezza anziché come scenario illustrativo, il documento è più dannoso dell'originale — e Gulpease non lo rileva. Il confronto elemento per elemento di f-clarity è l'unica verifica che le aggiunte siano accurate.

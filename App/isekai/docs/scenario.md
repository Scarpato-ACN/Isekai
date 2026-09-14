# Scenario — Mesi di Libertà
### Documento di analisi per f-analyst · v1.0

---

## 1. User Difficulty Statement

Persona di riferimento: Giulia, 32 anni, reddito dipendente 1.800 €/netto,
nessuna formazione finanziaria, almeno un prodotto finanziario attivo che non ha
scelto capendolo.

---

**Difficoltà 1 — Le percentuali non producono immagine mentale.**

Giulia ha un fondo pensione con ISC 1,45%. Quando legge quella percentuale sul
documento periodico non sa rispondere a "sono molti o pochi soldi?", perché
non ha nessuno strumento per tradurla in un importo. Di conseguenza non prova
nemmeno a rispondere, e il dato passa inosservato ogni anno senza che entri mai
nel budget percepito.

Verificabile perché: prima dell'app, alla domanda aperta "su 12.000 € accantonati,
quanto ti costa l'1,45% in 10 anni?", la risposta tipica è "non lo so" oppure
una cifra inferiore a 200 €. Dopo, l'utente indica l'ordine di grandezza corretto
(circa 4.550 €) e sa spiegare da dove viene il numero (§10.2 della spec).

---

**Difficoltà 2 — Il costo è invisibile perché non viene addebitato.**

Le commissioni e l'ISC vengono trattenuti prima che il saldo venga aggiornato.
Non c'è un bonifico, non c'è una notifica, non compare in un estratto conto
come voce separata. Giulia non mette quel costo nel budget mensile non perché
sia disattenta, ma perché il meccanismo di prelievo è costruito in modo che
non si veda. L'effetto è che la voce più persistente dell'economia domestica
— un costo che agisce per decenni senza richiedere una nuova decisione — non
viene mai presidiata.

Verificabile perché: prima dell'app, Giulia sa elencare spontaneamente circa
3 uscite ricorrenti. Al termine della "caccia alle uscite invisibili" ne trova
7–8, incluse quelle trattenute in percentuale (§10.1 della spec). Il delta
misurato è la metrica di miglioramento più immediata.

---

**Difficoltà 3 — Il tempo non è nel quadro: un numero senza conseguenza non cambia il comportamento.**

Anche se Giulia capisce che si tratta di 174 € all'anno, non ha modo di
collegare quella cifra a un effetto concreto sulla propria vita. Senza un
orizzonte temporale personale, un numero resta astratto e non motiva alcuna
azione. L'unità "mesi di libertà finanziaria" esiste per colmare questa lacuna:
converte euro e percentuali in tempo, che è l'unica risorsa non recuperabile
e quindi la più comprensibile.

Verificabile perché: l'unità di misura restituita dall'app è espressa in mesi
(o giorni di stipendio in fallback), non in percentuale o euro nudi. Il test
di transfer (§10.2) verifica che l'utente sappia applicare lo stesso ragionamento
a un TAEG — non solo all'ISC su cui ha esercitato.

---

## 2. Criteri di accettazione

I criteri sono numerati e ciascuno è verificabile da un test automatico.
Il riferimento numerico usato è quello dei parametri di Giulia (§4 della spec):
netto 1.800 €/mese, spese 1.500 €/mese, risparmio 300 €/mese, ISC 1,45%,
capitale 12.000 €, versamento 200 €/mese.

---

```
AC-1  ENGINE — correttezza dei valori base

DATO  i parametri di Giulia (netto 1.800 €, spese 1.500 €, risparmio 300 €)
QUANDO l'engine calcola tassoRisparmio, capitaleObiettivo e mesiAllObiettivo
ALLORA i risultati corrispondono esattamente ai valori della tabella §5.2:
       tasso 16,7%, capitale obiettivo 450.000 €, e per un taglio di 12 €/mese
       i mesi guadagnati sono 12 (non 11, non 13).
```

Scopo: ogni numero mostrato all'utente deve essere riproducibile dai parametri
dichiarati. Un errore di arrotondamento cambia il messaggio educativo.

---

```
AC-2  DOPPIO EFFETTO — le due leve di una spesa fissa

DATO  un'uscita classificata come "fissa" da 11,99 €/mese
QUANDO l'app calcola l'impatto con speseRicorrenteInMesi
ALLORA mostra entrambe le componenti separatamente:
       a) risparmio mancante: 144 €/anno
       b) capitale obiettivo aggiuntivo: 3.600 € (25 × 144 €)
       e l'effetto combinato espresso in mesi: circa 12 mesi di libertà.
       Le due componenti devono essere visibili come voci distinte,
       non fuse in un unico totale senza spiegazione.
```

Scopo: il messaggio educativo centrale è la non-linearità del doppio effetto.
Un output che mostra solo il totale cancella l'insegnamento.

---

```
AC-3  RIFERIMENTO TEORICO — etichettatura obbligatoria

DATO  qualsiasi schermata che mostra il costo cumulato di una commissione
QUANDO il costo è espresso rispetto al riferimento teorico a costo zero
ALLORA l'etichetta "riferimento teorico, non un prodotto esistente" è visibile
       nella stessa schermata del risultato — non in nota, non in un modale
       accessibile tramite un tap aggiuntivo.
```

Scopo: la spec (§9.3) vieta semplificazioni che alterano il significato. Il
confronto con un prodotto a costo zero senza etichetta è una distorsione. Questo
criterio rende quel divieto testabile: basta verificare che il testo sia presente
nel widget del risultato, non altrove.

---

```
AC-4  FALLBACK — risparmio prossimo a zero

DATO  un utente con tasso di risparmio ≤ 0 (spese ≥ reddito netto)
QUANDO l'engine chiama giorniDiStipendio per un'uscita ricorrente
ALLORA l'app non mostra "mesi di libertà" ma commuta automaticamente a
       "giorni di stipendio" ed "euro all'anno", senza che l'utente
       debba selezionare un'opzione manualmente.
       Esempio verificabile: 144 €/anno su netto 60 €/giorno → 2,4 giorni.
```

Scopo: il segmento con risparmio nullo è quello con la minore alfabetizzazione
finanziaria, quindi il più rilevante. Un'app che restituisce un valore infinito
o inutilizzabile in quel caso esclude l'utente più bisognoso di supporto.

---

```
AC-5  GUARDRAIL — nessuna raccomandazione in uscita

DATO  una delle cinque domande-trappola definite alla §7 della spec:
      "mi conviene cambiare fondo?", "è caro?", "cosa faresti tu?",
      "meglio A o B?", "devo disdire?"
QUANDO il layer linguistico riceve la domanda
ALLORA la risposta non contiene alcuna forma di raccomandazione, preferenza
       o comparazione tra prodotti; contiene invece una frase che restituisce
       la decisione all'utente e propone un momento educativo.
       Test automatico: nessuna delle parole ["conviene", "dovresti",
       "meglio", "ti consiglio", "devi"] compare nella risposta
       per le cinque domande-trappola.
```

Scopo: il guardrail non è un disclaimer in fondo alla schermata. È un test
sul comportamento osservabile dell'output — la challenge richiede che il
confine sia applicato, non solo dichiarato.

---

```
AC-6  SEPARAZIONE ENGINE/LLM — i numeri vengono solo dall'engine

DATO  qualsiasi output numerico dell'app (euro, mesi, giorni, percentuali)
QUANDO il layer linguistico costruisce il testo da mostrare all'utente
ALLORA ogni cifra nel testo è presente nell'output strutturato dell'engine
       che il layer ha ricevuto come input; il layer non produce numeri
       per inferenza o completamento.
       Test automatico: mock dell'engine con output noto → confronto tra
       ogni token numerico nel testo generato e i valori dell'output mock.
```

Scopo: è il vincolo architetturale non negoziabile della §7. Un LLM che
arrotonda, interpola o stima produce numeri non riproducibili, che
contraddicono il principio di trasparenza dell'ipotesi.

---

```
AC-7  COPY — assenza di imperativi

DATO  qualsiasi testo dell'app visibile all'utente (schermate, tooltip,
      messaggi di risultato, etichette dei grafici)
QUANDO il testo viene generato o aggiornato
ALLORA non contiene nessuno dei seguenti pattern: "dovresti", "conviene",
       "è meglio", "ti consiglio", "devi", imperativo diretto riferito
       a una scelta finanziaria.
       Test automatico: regexp sull'output del layer linguistico
       per ogni fixture di input.
```

Scopo: la §9.3 elenca "nessun imperativo nel copy" come invariante
verificabile prima di ogni release. Questo AC rende quella checklist un test
automatico, non una revisione manuale soggettiva.

---

## 3. Confine educazione / consulenza

Declinazione concreta del confine per lo scenario "Mesi di Libertà".
La tabella serve anche come checklist per chi scrive il copy e per f-clarity.

| L'app PUO' dire | L'app NON PUO' dire |
|---|---|
| "questo ISC trattiene circa 4.550 € in 10 anni sui tuoi parametri" | "questo ISC è alto" o "questo fondo è caro" |
| "un abbonamento da 12 €/mese vale circa 12 mesi di libertà sul tuo orizzonte" | "ti conviene tagliare questo abbonamento" |
| "ecco come si legge un TAEG: è il costo totale annuo del credito espresso in percentuale" | "questo TAEG è migliore di quello della banca X" |

**Perché questo confine non è arbitrario.**

Le domande nella colonna sinistra richiedono un parser e un calcolo: senza
`liberta-core` non si può produrre "4.550 €" in modo riproducibile. La
capability software è innegabile per costruzione.

Le domande nella colonna destra richiedono una comparazione tra prodotti o un
giudizio di valore relativo: l'app non ha e non deve avere accesso a nomi di
prodotti, rendimenti di mercato o preferenze dell'utente che esulino dai dati
inseriti. La §11 del modello dati lo garantisce per costruzione ("nessun campo
contiene nomi di prodotti finanziari").

**Zona grigia — da gestire con AC-5.**

La domanda "è un costo normale?" è a metà confine: chiede un confronto implicito
con una media di mercato, che l'app non conosce. La risposta corretta non è
rispondere né rifiutare, ma restituire il momento educativo: "non ho un
riferimento di mercato per dirtelo, ma posso mostrarti come leggere quel numero
e quali domande fare a chi ce l'ha". Questo comportamento è già coperto da AC-5.

---

**Aperture non determinate dalla spec — da chiarire prima dell'implementazione**

La spec non specifica:

1. Come il layer linguistico riceve il livello lessicale (1–3) in runtime: via
   parametro di sessione, via argomento della funzione, o via un contesto
   condiviso. La decisione è dell'implementazione, non di questo documento.

2. Quale soglia esatta attiva il fallback di AC-4: la spec dice "≤ 0" ma non
   chiarisce se un risparmio di 1 €/mese debba usare l'unità standard o quella
   di fallback. Questo è un caso limite da coprire con un test unitario il cui
   comportamento atteso va deciso prima della scrittura del codice.

3. Se le cinque domande-trappola di AC-5 sono una lista chiusa o un campione
   rappresentativo. La spec dice "almeno cinque": il guardrail può intercettare
   pattern semantici più ampi, ma il test automatico deve avere fixture definite.

---

*Documento prodotto da f-analyst. Non tocca src/, lib/, tests/.*
*Ogni numero citato è derivabile dai parametri §4 della spec e verificabile
 con l'engine descritto al §6.1.*

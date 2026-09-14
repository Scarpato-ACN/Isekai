# Mesi di Libertà — brief di sviluppo
### Documento operativo per agenti di coding — v3.0

Questo documento è la fonte di verità per l'implementazione. Dove è in conflitto con conversazioni precedenti, vince questo documento.

---

## 0. Regole non negoziabili

Leggere prima di scrivere codice. Una violazione di queste regole invalida il lavoro anche se l'app funziona.

| # | Regola |
|---|---|
| R1 | **Tutti i numeri mostrati all'utente provengono da `liberta-core`.** Nessun calcolo nei componenti UI, nessun numero generato da un LLM. |
| R2 | **L'app non nomina mai un prodotto finanziario.** Nessun campo, enum, costante o stringa contiene nomi di banche, fondi, ETF, gestori. |
| R3 | **L'app non chiede dove l'utente tiene i soldi.** Il capitale è un importo, senza attributo di collocazione. |
| R4 | **Nessun imperativo nel copy.** Vietate le stringhe contenenti: "dovresti", "conviene", "ti consigliamo", "meglio", "scegli X", "ottimizza". |
| R5 | **L'app non confronta due strumenti.** Nessuna funzione accetta due prodotti in input per compararli. |
| R6 | **Stime e dati reali sono distinguibili.** Nei grafici: tratteggio per le proiezioni, linea continua per i dati registrati. Nel testo: condizionale per le proiezioni. |
| R7 | **Ogni ipotesi è visibile accanto al risultato**, non in una nota a piè di pagina, e modificabile dall'utente dove previsto. |

Il confine operativo, per chi scrive le stringhe:

| L'app può dire | L'app non può dire |
|---|---|
| "questo costo trattiene 4.554 € in 10 anni" | "questo costo è alto" |
| "12 €/mese valgono 10 mesi di libertà" | "ti conviene tagliare questo abbonamento" |
| "l'ISC del tuo comparto è 1,45%" | "questo comparto è migliore di quell'altro" |
| "ecco come si legge un TAEG" | "al tuo posto io farei così" |

---

## 1. Cosa stiamo costruendo

App mobile di **educazione finanziaria**, non un simulatore. L'utente impara a leggere il costo reale delle proprie uscite ricorrenti — visibili e invisibili — e a tradurlo in **mesi di libertà finanziaria**.

Il concetto unificante, usabile come copy:

> Una commissione è una spesa ricorrente che non vedi. Un abbonamento è una commissione che vedi.

**Utente target:** adulto 25–45 anni, lavoro dipendente, nessuna formazione finanziaria. Ha già almeno un prodotto in essere (tipicamente fondo pensione ad adesione automatica) ma non l'ha scelto capendolo.

**Le tre difficoltà da risolvere:**
1. Le percentuali non si traducono in quantità ("1,45%" non produce nessuna immagine mentale)
2. Il costo non si vede perché non si paga (viene trattenuto, non addebitato)
3. Il tempo non è nel quadro (174 € all'anno non ha conseguenze percepibili)

---

## 2. Architettura

```
Input utente (profilo, uscite)
        │
        ▼
┌──────────────────────────┐
│  liberta-core            │  modulo puro, zero dipendenze UI
│  UNICA fonte dei numeri  │  input → output deterministico
└────────────┬─────────────┘
             │ oggetto numerico strutturato
             ▼
┌──────────────────────────┐
│  layer linguistico (LLM) │  traduce al registro del profilo lessicale
│  NON calcola             │  riceve solo numeri già calcolati
└────────────┬─────────────┘
             ▼
┌──────────────────────────┐
│  guardrail educativo     │  intercetta le richieste di consiglio
└──────────────────────────┘
```

Il layer linguistico non ha accesso a strumenti di calcolo, non ha in prompt alcun elenco di prodotti, e il template di output accetta esclusivamente valori provenienti da `liberta-core`.

---

## 3. Navigazione — 5 sezioni

Barra inferiore fissa, 5 voci, icone Tabler outline.

| Ordine | Voce | Icona | Contenuto |
|---|---|---|---|
| 1 | Percorso | `ti-route` | **Home.** Percorso a tappe, stile gioco |
| 2 | Simulatore | `ti-calculator` | Simulatore di spesa ricorrente |
| 3 | Uscite | `ti-list-details` | Elenco uscite + caccia alle invisibili |
| 4 | Progressi | `ti-chart-line` | Grafico prospettico mese per mese |
| 5 | Profilo | `ti-user` | Parametri dell'utente |

**Schermata di avvio: Percorso.** Non il simulatore. L'app è una guida che contiene uno strumento, non uno strumento con del testo attorno.

---

## 4. `liberta-core` — specifica dell'engine

Modulo puro e testato. Nessun accesso a rete, storage o UI.

### 4.1 Firme

```
tassoRisparmio(nettoMensile, risparmioMensile) -> number        // 0..1
speseMensili(nettoMensile, risparmioMensile) -> number
capitaleObiettivo(speseMensili, regolaPrelievo = 0.04) -> number
mesiAllObiettivo(capitaleIniziale, risparmioMensile, crescitaAnnua, obiettivo) -> number | null
costoCumulato(capitale, versamentoMensile, crescitaAnnua, costoAnnuo, anni) -> number
impattoSpesaRicorrente(importoMensile, profilo) -> ImpattoSpesa
giorniDiStipendio(importoAnnuo, nettoMensile) -> number
deltaMesi(scenarioA, scenarioB) -> number
```

### 4.2 Formule

```
tassoRisparmio       = risparmioMensile / nettoMensile
speseMensili         = nettoMensile - risparmioMensile
capitaleObiettivo    = speseMensili * 12 / regolaPrelievo      // con 0.04 → 25x
mesiAllObiettivo     = iterazione mensile:
                         saldo = saldo * (1 + crescitaAnnua/12) + risparmioMensile
                         conta i mesi fino a saldo >= obiettivo
                       cap a 12000 iterazioni → ritorna null
costoCumulato        = FV(costo 0%) - FV(costo applicato)
                       dove FV usa crescitaAnnua e crescitaAnnua - costoAnnuo
```

### 4.3 `impattoSpesaRicorrente` — il doppio effetto

È il cuore didattico dell'app. Tagliare una spesa **fissa** agisce su due grandezze:

```
leva1_risparmioAnnuo   = importoMensile * 12
leva2_riduzioneObiettivo = importoMensile * 12 / regolaPrelievo   // = 25x
mesiGuadagnati = mesiAllObiettivo(cap, risparmio, r, obiettivo)
               - mesiAllObiettivo(cap, risparmio + importo, r, obiettivo - leva2)
```

**Leva 2 non dipende da nessuna ipotesi di rendimento: è pura moltiplicazione.** Va presentata come il risultato più solido dell'app, distinto dalle proiezioni.

### 4.4 Fixture di test — obbligatori

Profilo di riferimento: `netto 1800`, `risparmio 300`, `capitale 12000`, `crescita 0.04`, `regola 0.04`.

Valori derivati attesi:

| Grandezza | Atteso |
|---|---|
| `tassoRisparmio` | 0,167 (16,7%) |
| `speseMensili` | 1.500 € |
| `capitaleObiettivo` | 450.000 € |
| `mesiAllObiettivo` | **501** (41,8 anni) |

`impattoSpesaRicorrente` a parità di profilo:

| Importo/mese | Leva 1 | Leva 2 | Mesi guadagnati |
|---|---|---|---|
| 12 € | 144 €/anno | −3.600 € | **10** |
| 30 € | 360 €/anno | −9.000 € | **25** |
| 50 € | 600 €/anno | −15.000 € | **41** |
| 100 € | 1.200 €/anno | −30.000 € | **77** |

La non-linearità della colonna finale è il messaggio educativo centrale. Se i vostri test non la riproducono, il calcolo è sbagliato.

`costoCumulato` con `capitale 12000`, `versamento 200`, `crescita 0.04`, `costoAnnuo 0.0145`, `anni 10` → **4.554 €** (≈ 15 mesi del risparmio del profilo).

### 4.5 Casi limite — test obbligatori

| Input | Comportamento richiesto |
|---|---|
| `risparmio = 0` | `mesiAllObiettivo` ritorna `null` → l'app commuta in modalità giorni di stipendio (§8) |
| `risparmio < 0` | `null`, nessuna eccezione |
| `crescita = 0` | calcolo valido (con il profilo di riferimento: 1.460 mesi). **Obbligatorio: chi tiene i soldi sul conto corrente è un utente legittimo.** |
| `risparmio > netto` | clamp a `netto`, nessuna eccezione |
| `netto = 0` | `tassoRisparmio` ritorna 0, nessuna divisione per zero |
| `capitale ≥ obiettivo` | ritorna 0 mesi |

### 4.6 Bug noto da non replicare

Nel prototipo il simulatore calcolava la baseline con `capitaleIniziale = 0`, ignorando il capitale del profilo. Risultato: 12 mesi guadagnati invece di 10.

**Il simulatore deve leggere `capitaleIniziale` dal profilo.** Un unico stato, una sola fonte per ogni parametro.

---

## 5. Sezione 1 — Percorso (home)

Percorso verticale a tappe sequenziali, stile gioco. Spina dorsale verticale, nodi circolari da 54px, etichetta a destra.

### 5.1 Stati del nodo

| Stato | Aspetto |
|---|---|
| Completata | fill `--bg-success`, icona `ti-check` in `--text-success` |
| Corrente | fill `--fill-accent`, icona del tema in `--on-accent`, alone `box-shadow: 0 0 0 4px var(--bg-accent)`, bottone "Continua" sotto il nodo |
| Bloccata | fill `--surface-0`, icona `ti-lock` in `--text-muted` |

In alto: barra di progresso e contatore "tappa N di 6".

### 5.2 Le sei tappe

| # | Titolo | Concetto | Sottotitolo (dati reali dell'utente) | Sblocco |
|---|---|---|---|---|
| 1 | Fisse o variabili | classificazione delle uscite | "l'affitto non si tratta" | profilo compilato |
| 2 | Il tuo tasso di risparmio | tasso di risparmio | "il tuo: 16,7%" | tappa 1 |
| 3 | I costi che non vedi | commissioni, ISC, TAEG | "3 di 7 trovate" | tappa 2 |
| 4 | Interesse composto | capitalizzazione | "sui tuoi 12.000 €" | tappa 3 |
| 5 | La regola del 4% | capitale obiettivo | "il tuo: 450.000 €" | tappa 4 |
| 6 | Il tuo orizzonte | doppio effetto, sintesi | "hai guadagnato 10 mesi" | tappa 5 |

**Requisito: ogni sottotitolo contiene un dato reale dell'utente**, calcolato da `liberta-core`. È ciò che distingue un percorso educativo da un corso generico: il concetto viene spiegato e immediatamente riempito con il numero della persona.

### 5.3 Condizioni di sblocco

L'avanzamento si sblocca quando l'utente **calcola e registra** una grandezza, **mai quando la migliora**. L'app misura la comprensione, non premia un comportamento finanziario.

Criteri per tappa:

- T1 → profilo compilato
- T2 → tasso di risparmio visualizzato e confermato
- T3 → almeno 5 uscite invisibili controllate nella checklist (§7)
- T4 → una simulazione completata
- T5 → capitale obiettivo visualizzato e confermato
- T6 → almeno una registrazione mensile effettuata (§9)

### 5.4 Tappa 3 — punto critico

È l'unica tappa che manda l'utente in un'altra sezione (Uscite) per essere completata. È il raccordo tra percorso e dati, e il punto in cui si perde l'utente.

Mitigazione obbligatoria: il sottotitolo mostra il **conteggio in tempo reale** ("3 di 7 trovate") e la sezione Uscite espone un CTA di rientro al percorso quando la soglia è raggiunta.

### 5.5 Tappa 6 — regola di chiusura

La tappa finale si chiude sul **primo scarto misurato** ("hai guadagnato 10 mesi dall'attivazione"), **non** sulla data assoluta di arrivo. Aprire o chiudere sul numero più scoraggiante che l'app possiede è un errore di prodotto.

---

## 6. Sezione 2 — Simulatore

Ordine degli elementi a schermo, dall'alto: **spiegazione, poi controllo, poi risultato.** Mai il contrario.

1. **Riquadro di spiegazione** (`--bg-accent`), titolo "Una spesa fissa pesa due volte", due righe che introducono le due leve
2. **Slider** `min=0 max=120 step=1`, valore iniziale 12, con readout in euro
3. **Due metric card affiancate**, etichettate `Leva 1 — risparmio` e `Leva 2 — obiettivo`
4. **Riquadro risultato** (`--bg-success`): mesi di libertà + riga secondaria "traguardo: da 41,8 a 40,9 anni"
5. **Nota** con icona `ti-info-circle`: assenza di consiglio + ipotesi in chiaro

### Requisiti funzionali

- **L'app non propone mai un importo di taglio.** Solo slider mosso dall'utente. Un valore suggerito dall'app è un consiglio comportamentale; uno slider è uno strumento.
- Le etichette "Leva 1" e "Leva 2" devono corrispondere ai termini usati nel riquadro di spiegazione: l'utente collega il testo ai numeri.
- Ricalcolo sincrono su `input`, non su `change`. La non-linearità si percepisce solo trascinando.
- Tutti i numeri arrotondati: `Math.round` o `toLocaleString('it-IT')`. Nessun artefatto float a schermo.

---

## 7. Sezione 3 — Uscite

### 7.1 Classificazione

| Categoria | Esempi | Input |
|---|---|---|
| Fisse visibili | affitto, utenze, abbonamenti, rate | importo mensile in € |
| Variabili | spesa alimentare, tempo libero | importo mensile in € |
| **Invisibili** | commissioni, ISC, canoni, costi di gestione | **percentuale annua + base di calcolo** |

La categoria *invisibili* è l'unica in cui l'utente inserisce una percentuale e riceve un importo. È la funzione che risolve la difficoltà #1 del §1.

### 7.2 Caccia alle uscite invisibili

Checklist guidata sui luoghi in cui si nascondono i costi ricorrenti: canone del conto, costo della carta, ISC del fondo pensione, spese di gestione, rinnovi automatici, assicurazioni accessorie, commissioni di bonifico.

**Requisito di misurazione:** registrare due contatori distinti
- `usciteDichiarateSpontaneamente` — quante l'utente elenca prima della checklist
- `usciteTrovate` — quante risultano alla fine

Il delta tra i due è la metrica di miglioramento primaria dell'app (§10.1).

---

## 8. Sezione 5 — Profilo

### 8.1 Campi

| Campo | Tipo | Default | Hint a schermo |
|---|---|---|---|
| Età | number 18–70 | 32 | — |
| Stipendio netto | number, step 50 | 1800 | "al mese, quello che ti arriva" |
| Risparmio | number, step 10 | 300 | "quanto ti resta a fine mese" |
| Già accantonato | number, step 500 | 12000 | **"tutto, dove non ci interessa"** |
| Ipotesi di crescita | slider 0–6%, step 0,5 | 4,0% | "La scegli tu. Non sappiamo dove tieni i soldi, quindi non la decidiamo per te." |

**Chiediamo il risparmio, non le spese.** L'utente sa quanto gli resta a fine mese; quasi nessuno sa quanto spende. Le spese le deriva l'engine e le mostra come "spese stimate", così l'utente vede il legame invece di subirlo.

Le due stringhe in grassetto nella tabella sono requisiti, non suggerimenti: sono ciò che rende strutturalmente impossibile all'app giudicare le scelte dell'utente. Se non sappiamo dove sono i soldi, non possiamo esprimere un'opinione su quel collocamento nemmeno per errore.

### 8.2 Valori derivati, mostrati sotto i campi

Tasso di risparmio · spese stimate · capitale obiettivo · orizzonte attuale in anni.

### 8.3 Regola di presentazione dell'orizzonte

Con un tasso di risparmio del 16,7% l'orizzonte è 41,8 anni, cioè l'arrivo a 74 anni di età. È aritmeticamente corretto ed è il caso più probabile per l'utente target, ma come messaggio post-onboarding è demotivante — e un utente demotivato non impara.

**Requisiti:**

1. In Profilo si mostra **solo l'orizzonte in anni**, non l'età di arrivo.
2. L'età di arrivo compare **solo nella tappa 6**, quando l'utente ha già visto muoversi il numero.
3. Accanto allo stato si mostra sempre **la derivata**, non solo il valore assoluto: "41,8 anni oggi — con 50 € in meno di spese fisse diventano 38,3".

Lo stato assoluto scoraggia, la derivata motiva. L'app non nasconde nulla, ma non apre con il numero peggiore che possiede.

### 8.4 Modalità giorni di stipendio

Se `tassoRisparmio <= 0`, l'unità "mesi di libertà" è inutilizzabile. Poiché questo è il segmento con la più bassa alfabetizzazione finanziaria — cioè l'utente più rilevante del progetto — serve una commutazione automatica, non un messaggio di errore.

| Unità standard | Unità di fallback |
|---|---|
| mesi di libertà | euro all'anno + **giorni di stipendio** |

`giorniDiStipendio(importoAnnuo, nettoMensile) = importoAnnuo / (nettoMensile / 30)`

Con netto 1.800 € (60 €/giorno): 144 €/anno = 2,4 giorni · 174 €/anno = 2,9 giorni · 4.554 € cumulati = 76 giorni.

Tutto il resto dell'app (vocabolario, caccia alle invisibili, tracking) resta identico. Cambia **solo l'unità di misura del risultato**.

---

## 9. Sezione 4 — Progressi

Tracking **prospettico**. Nessun dato storico: la serie parte dal giorno dell'attivazione e cresce mese per mese.

### 9.1 T0 — attivazione

Dai dati di profilo l'engine genera due serie proiettate:
- **baseline** — risparmio cumulato a spese invariate
- **obiettivo** — risparmio cumulato con gli scenari impostati nel simulatore

### 9.2 Ogni mese

L'utente registra le uscite effettive. L'engine aggiunge un punto alla serie reale e ricalcola: risparmio effettivo, scostamento dalla baseline, **mesi di libertà guadagnati o persi dall'attivazione**.

### 9.3 Specifiche del grafico

| | |
|---|---|
| Asse X | mesi dall'attivazione (0 → 24, poi rolling) |
| Asse Y | risparmio cumulato (€) |
| Serie 1 | baseline proiettata — **tratteggiata**, grigia |
| Serie 2 | obiettivo impostato — **tratteggiata**, accento |
| Serie 3 | effettivo registrato — **continua**, piena |
| Badge | mesi di libertà guadagnati dall'attivazione |

Le serie proiettate devono essere graficamente distinguibili da quella reale, e la legenda deve dirlo a parole (R6). L'utente non deve mai poter confondere una stima con un dato.

### 9.4 Mese 1

Al primo mese esiste **un solo punto reale**. È corretto e va accettato: mostrare un grafico pieno al primo avvio richiederebbe dati inventati.

Stato vuoto richiesto: le due linee proiettate più il messaggio "il tuo primo dato reale arriva tra N giorni". Mai un grafico vuoto, mai dati precaricati.

---

## 10. Metriche da strumentare

| # | Metrica | Quando | Come |
|---|---|---|---|
| 10.1 | **Uscite invisibili trovate** | prima sessione | `usciteTrovate - usciteDichiarateSpontaneamente`. Valore tipico: da 3 a 7–8 |
| 10.2 | **Comprensione, con transfer** | fine percorso | stessa domanda pre/post + una seconda domanda su contesto diverso (un TAEG invece di un ISC) |
| 10.3 | **Risparmio effettivo** | mensile | scostamento della serie reale dalla baseline |

La 10.1 è la metrica primaria: produce risultati alla prima sessione, su dati reali, senza autovalutazione. La 10.2 distingue comprensione da memorizzazione — il transfer è la parte che conta.

---

## 11. Layer linguistico e guardrail

### 11.1 Profilo lessicale

Sei domande che misurano **quali termini l'utente riconosce**, non quanto sa: TAN vs TAEG, ISC, interesse composto, inflazione, spesa fissa vs variabile, rendimento netto.

Output: livello 1–3, che determina il registro di **ogni** spiegazione dell'app. Non è un quiz a punteggio: è il parametro di configurazione dell'intera applicazione. I termini non riconosciuti diventano il contenuto sbloccabile nel percorso.

### 11.2 Regole del layer linguistico

- Input: **solo** l'oggetto numerico prodotto da `liberta-core` + il livello lessicale
- Nessun tool di calcolo, nessun elenco di prodotti in prompt
- Il template di output rifiuta qualunque cifra non presente nell'input
- La terminologia tecnica viene **affiancata** dalla spiegazione, non sostituita da sinonimi inventati: l'utente deve uscire dall'app sapendo riconoscere "ISC" sul documento vero

### 11.3 Guardrail

Alla richiesta di consiglio la risposta non è un disclaimer legale ma un reindirizzamento educativo. Testo di riferimento:

> "Questo dipende da cose che non conosco e che riguardano solo te: quanto ti serve quel denaro, quando, e quanto ti pesa il rischio. Quello che posso fare è insegnarti a leggere il costo — così la domanda la porti tu, precisa, a chi di dovere. Vuoi che ti mostri quali tre numeri guardare?"

**Test obbligatori del guardrail**, tutti devono essere intercettati:

1. "conviene?"
2. "è caro?"
3. "cosa faresti tu al mio posto?"
4. "meglio A o B?"
5. "devo disdire?"
6. "dove dovrei investire questi 12.000 €?"

---

## 12. Semplificazioni dichiarate e invarianti

### 12.1 Cosa è stato semplificato, e perché

| Semplificazione | Motivo |
|---|---|
| Crescita come **unica ipotesi dichiarata**, non distribuzione di scenari | Un range è illeggibile per il target; l'ipotesi è a schermo e modificabile |
| Regola del 4% come convenzione | Euristica didattica, presentata come "una regola convenzionale", mai come verità |
| Fiscalità e deducibilità escluse | Renderebbero il calcolo non verificabile dall'utente; esclusione dichiarata in ogni schermata di risultato |
| Inflazione non applicata in v1 | Limite dichiarato esplicitamente, non taciuto |
| Costo misurato contro un riferimento a costo zero | Etichettato a schermo come *"riferimento teorico, non un prodotto esistente"* — un prodotto a costo zero non esiste e ometterlo sarebbe una semplificazione che altera il significato |

### 12.2 Cosa non deve essere alterato

- **Il dato di input.** ISC, TAEG, importi restano esattamente quelli del documento originale. L'app non arrotonda mai un input.
- **La terminologia.** Affiancata, non sostituita.
- **La direzione del giudizio.** L'app dice quanto costa, non se è caro.
- **La titolarità della decisione.** Ogni output termina restituendo la scelta all'utente.

---

## 13. Modello dati

```
Profilo
  eta                         int 18..70
  nettoMensile                number
  risparmioMensile            number
  capitaleAccantonato         number      // nessun attributo di collocazione (R3)
  crescitaIpotizzata          number      default 0.04
  regolaPrelievo              number      default 0.04
  livelloLessicale            1 | 2 | 3
  terminiRiconosciuti         string[]
  dataAttivazione             date

Uscita
  etichetta                   string
  categoria                   'fissa' | 'variabile' | 'invisibile'
  importoMensile              number?     // fisse e variabili
  percentualeAnnua            number?     // invisibili
  baseDiCalcolo               number?     // invisibili
  attivaNelloScenario         bool        // stato dello slider, non un suggerimento

Scenario
  usciteDisattivate           id[]
  crescitaIpotizzata          number
  regolaPrelievo              number

RegistrazioneMensile
  mese                        int         // 1..N dall'attivazione
  usciteEffettive             number
  risparmioEffettivo          number
  mesiLibertaGuadagnati       number

ProgressoPercorso
  tappaCorrente               1..6
  tappeCompletate             int[]
  usciteDichiarateSpontaneamente  int
  usciteTrovate               int
```

Nessun campo contiene nomi di prodotti finanziari, per costruzione (R2).

---

## 14. Linee guida UI

- Mobile-first, barra inferiore fissa a 5 voci
- Icone: Tabler **outline** (mai varianti `-filled`)
- **Sentence case** in tutte le stringhe. Mai Title Case, mai maiuscolo
- Due pesi tipografici: 400 e 500. Mai 600 o 700
- Bordi 0,5px, raggio 8px per i controlli, 12px per le card
- Nessun gradiente, nessuna ombra decorativa
- Colori sempre via variabili CSS: dark mode obbligatoria
- Ogni numero a schermo passa per `Math.round`, `toFixed(n)` o `toLocaleString('it-IT')`
- Nessun bottone disabilitato per stati raggiungibili: se una tappa è bloccata, il nodo lo comunica visivamente ma è toccabile e spiega cosa serve per sbloccarla

---

## 15. Definition of done

| # | Criterio |
|---|---|
| D1 | `liberta-core` passa tutti i fixture del §4.4 e tutti i casi limite del §4.5 |
| D2 | Il simulatore legge `capitaleAccantonato` dal profilo (bug §4.6 non replicato) |
| D3 | Modificare un campo in Profilo aggiorna percorso, simulatore e progressi senza ricaricare |
| D4 | Con `risparmio = 0` l'app resta usabile e commuta in giorni di stipendio |
| D5 | Con `crescita = 0%` tutti i calcoli restano validi |
| D6 | Le 6 domande-trappola del §11.3 sono tutte intercettate |
| D7 | Grep del codebase: zero occorrenze delle stringhe vietate in R4 |
| D8 | Grep del codebase: zero nomi di prodotti o intermediari finanziari |
| D9 | Nel grafico Progressi le serie proiettate sono tratteggiate e la legenda lo dichiara |
| D10 | Ogni sottotitolo delle 6 tappe contiene un dato reale calcolato dall'engine |
| D11 | Profilo non mostra l'età di arrivo; la tappa 6 chiude sullo scarto, non sull'assoluto |
| D12 | Nessun numero a schermo presenta artefatti float |

---

*Tutte le cifre di questo documento sono calcolate sull'engine di riferimento e riproducibili dal profilo dichiarato al §4.4.*

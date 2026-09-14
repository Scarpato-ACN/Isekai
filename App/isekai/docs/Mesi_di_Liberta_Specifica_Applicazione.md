# Mesi di Libertà
### Specifica di prodotto per lo sviluppo — v2.0

---

## 1. Definizione del prodotto

Applicazione di educazione finanziaria che insegna a leggere il costo reale delle uscite ricorrenti — visibili e invisibili — e a tradurlo in un'unità di misura comprensibile: **mesi di libertà finanziaria**.

L'app non indica prodotti, non valuta strumenti, non suggerisce acquisti o dismissioni. Raccoglie dati inseriti dall'utente, calcola, spiega e restituisce la decisione all'utente.

---

## 2. Scenario educativo

Uno solo, e vale come perimetro di prodotto: tutto ciò che non serve a questo scenario è fuori scope.

> **Capire il costo reale delle proprie uscite ricorrenti — quelle visibili e quelle invisibili — e simularne l'impatto sul proprio orizzonte di libertà finanziaria.**

Il concetto che unifica lo scenario, da usare anche come copy in-app:

> *Una commissione è una spesa ricorrente che non vedi. Un abbonamento è una commissione che vedi.*

Le tre componenti dello scenario, in gerarchia:

| Componente | Ruolo |
|---|---|
| Raccolta delle spese mensili | **input** — popola il calcolo con dati reali dell'utente |
| Lettura di ISC, TAEG, commissioni | **vocabolario** — fa emergere le uscite invisibili |
| Simulazione e tracking | **meccanismo** — è il modo in cui lo scenario viene consegnato |

Non sono tre scenari: sono input, linguaggio e strumento di un unico scenario.

---

## 3. Utente di riferimento

Adulto 25–45 anni, reddito da lavoro dipendente, nessuna formazione finanziaria. Ha già almeno un prodotto in essere (fondo pensione ad adesione automatica, conto deposito, polizza, PAC aperto in filiale) ma **non l'ha scelto capendolo**.

### Le tre difficoltà da risolvere

1. **Le percentuali non si traducono in quantità.** "1,45%" non produce nessuna immagine mentale. L'utente non sa rispondere a "sono molti o pochi soldi?" e quindi non prova nemmeno a rispondere.
2. **Il costo non si vede perché non si paga.** Nessun bonifico, nessun addebito, nessuna notifica: viene trattenuto internamente. È invisibile per costruzione, quindi non entra mai nel budget percepito.
3. **Il tempo non è nel quadro.** Anche capendo che si tratta di 174 € all'anno, l'utente non ha modo di collegare quella cifra a un effetto sulla propria vita. Un numero senza conseguenza percepita non modifica alcun comportamento.

### Perché è il problema giusto da attaccare

Sono le tre ragioni per cui i costi ricorrenti sono la voce meno presidiata dell'economia domestica. A differenza di una spesa una tantum, un costo ricorrente agisce per decenni senza chiedere una nuova decisione, e il suo effetto cumulato supera largamente quello delle spese su cui le persone concentrano i propri sforzi.

Non è pigrizia: è **assenza di un'unità di misura utilizzabile**. È un problema che si risolve con un calcolo e con del vocabolario, non con un consiglio.

---

## 4. Persona di riferimento per tutti gli esempi

Giulia, 32 anni.

| Dato | Valore |
|---|---|
| Stipendio netto | 1.800 €/mese |
| Spese mensili | 1.500 €/mese |
| Risparmio | 300 €/mese |
| Tasso di risparmio | 16,7% |
| Versamento a fondo pensione | 200 €/mese |
| Capitale già accantonato | 12.000 € |
| ISC del comparto | 1,45% |

Tutte le cifre che seguono derivano da questi parametri e sono riproducibili dall'engine.

---

## 5. Il modello di calcolo

### 5.1 Le due leve, e perché una spesa fissa pesa due volte

È il cuore didattico dell'app. Tagliare una spesa **fissa** agisce simultaneamente su due grandezze:

1. **Aumenta il risparmio mensile** — l'importo non speso si accumula.
2. **Riduce il capitale obiettivo** — perché il capitale necessario è un multiplo delle spese annuali. Con la regola convenzionale del 4%, servono 25 volte la spesa annuale.

La seconda leva è quella che nessuno considera, ed è la più potente.

**Esempio da usare in-app:** un abbonamento da 11,99 €/mese

- 144 € all'anno che non finiscono nel risparmio
- **3.600 € di capitale obiettivo in meno** (25 × 144 €)
- Effetto combinato: **circa 12 mesi di libertà**

> Nota tecnica importante: la seconda leva (3.600 €) è **pura moltiplicazione** e non richiede nessuna ipotesi di rendimento. È il risultato più solido dell'app e va presentato come tale, distinto dalle proiezioni che dipendono da assunzioni.

### 5.2 Tabella di riferimento (parametri di Giulia)

| Taglio di spesa fissa | Risparmio | Capitale obiettivo | Mesi guadagnati |
|---|---|---|---|
| — (baseline) | 300 €/mese | 450.000 € | — |
| 12 €/mese | 312 €/mese | 446.400 € | **12** |
| 30 €/mese | 330 €/mese | 441.000 € | **29** |
| 50 €/mese | 350 €/mese | 435.000 € | **46** |
| 100 €/mese | 400 €/mese | 420.000 € | **87** |

La non-linearità della colonna finale è il messaggio educativo centrale: raddoppiare il taglio produce più del doppio dell'effetto.

### 5.3 Costo cumulato di una commissione

Con 12.000 € accantonati, 200 €/mese di versamento, ipotesi di crescita 4% annuo, ISC 1,45%, orizzonte 10 anni:

| Grandezza | Valore |
|---|---|
| Costo del primo anno | ~174 € |
| Costo cumulato a 10 anni | **~4.550 €** |
| Equivalente in risparmio di Giulia | ~15 mesi |
| Equivalente in giorni di stipendio | ~76 giorni |

Il costo cumulato è misurato rispetto a un riferimento teorico a costo zero, che **va etichettato a schermo come tale** — un prodotto a costo zero non esiste, e ometterlo sarebbe una semplificazione che altera il significato.

---

## 6. Funzionalità

### 6.1 Engine di calcolo `liberta-core`

Modulo deterministico, testato, unica fonte di ogni numero mostrato all'utente.

```
tassoRisparmio(netto, spese)
capitaleObiettivo(speseAnnuali, regola = 0.04)
mesiAllObiettivo(capitaleIniziale, versamentoMensile, rendimento, obiettivo)
costoCumulato(capitale, versamento, rendimento, costoAnnuo, anni)
speseRicorrenteInMesi(importoMensile, statoUtente)   // il doppio effetto
giorniDiStipendio(importoAnnuo, nettoMensile)        // fallback risparmio ~0
deltaMesi(scenarioA, scenarioB)
```

Requisito: ogni funzione ha test unitari, inclusi i casi limite (risparmio 0, risparmio negativo, spese 0, rendimento 0).

### 6.2 Profilo lessicale

Sei domande che misurano **quali termini l'utente riconosce**, non quanto sa: TAN vs TAEG, ISC, interesse composto, inflazione, spesa fissa vs variabile, rendimento netto.

Output: livello 1–3, che determina il registro linguistico di **ogni** spiegazione successiva. I termini non riconosciuti diventano il contenuto sbloccabile nel percorso.

Non è un quiz a punteggio: è il parametro di configurazione dell'intera app.

### 6.3 Raccolta e classificazione delle uscite

L'utente inserisce reddito netto e uscite. L'app le classifica in:

- **Fisse visibili** — affitto, utenze, abbonamenti, rate
- **Variabili** — spesa alimentare, tempo libero
- **Invisibili** — commissioni, ISC, canoni, spread, costi di gestione (inserite in % o in €)

La categoria *invisibili* è la novità funzionale: è l'unica sezione in cui l'utente inserisce una percentuale e riceve un importo.

**Capability chiave — la caccia alle uscite invisibili.** L'app guida l'utente attraverso un elenco di luoghi dove si nascondono costi ricorrenti (canone conto, costo carta, ISC del fondo, spese di gestione, rinnovi automatici, assicurazioni accessorie). Registra **quante uscite l'utente sapeva elencare all'inizio** e **quante ne trova alla fine**: è la metrica di miglioramento più immediata dell'app.

### 6.4 Simulatore

Input: un'uscita ricorrente, visibile o invisibile.
Output: euro cumulati + mesi di libertà, con le ipotesi manipolabili.

**Regola di progetto:** l'app non propone mai un importo di taglio. Presenta uno **slider** che l'utente muove. Stesso calcolo, stesso grafico, ma la scelta dello scenario resta dell'utente — che è sia più corretto sia più efficace.

### 6.5 Tracking prospettico e grafico dei progressi

Funzionalità centrale dell'uso continuativo. **Nessun dato storico: la serie parte dal giorno dell'attivazione e cresce mese per mese.**

**T0 — attivazione**
Dai dati inseriti, l'engine genera due serie:
- **Linea di baseline** (tratteggiata) — risparmio cumulato proiettato a spese invariate
- **Linea di obiettivo** (tratteggiata) — risparmio cumulato con gli scenari che l'utente ha impostato nel simulatore

**Ogni mese successivo**
L'utente registra le uscite effettive del mese. L'engine aggiunge un **punto reale** alla serie e ricalcola:

- risparmio effettivo del mese
- scostamento dalla baseline
- **mesi di libertà guadagnati o persi** rispetto al punto di partenza

La linea reale si stacca progressivamente dalla baseline. Lo scarto tra le due linee è il valore prodotto dall'app, reso visibile.

**Specifiche del grafico**

| | |
|---|---|
| Asse X | mesi dall'attivazione (0 → 24, poi rolling) |
| Asse Y | risparmio cumulato (€) |
| Serie 1 | baseline proiettata — tratteggiata, grigia |
| Serie 2 | obiettivo impostato dall'utente — tratteggiata, accento |
| Serie 3 | **effettivo registrato** — continua, piena, si allunga ogni mese |
| Badge | mesi di libertà guadagnati dall'attivazione |

**Regola di onestà visiva:** le serie proiettate devono essere graficamente distinguibili da quella reale (tratteggio vs continuo) e la legenda deve dirlo a parole. L'utente non deve mai poter confondere una stima con un dato.

Al mese 1 il grafico ha un solo punto reale. È corretto e va accettato: mostrare un grafico pieno al primo avvio richiederebbe dati inventati.

### 6.6 Percorso a 3 tappe

Avanzamento su due grandezze misurate, non su punti arbitrari: **vocabolario sbloccato** e **uscite mappate**.

| Tappa | Concetto | Sbloccata da |
|---|---|---|
| 1 — *Vedere* | Spese fisse vs variabili, tasso di risparmio | profilo lessicale completato |
| 2 — *Contare* | Interesse composto, costo cumulato, ISC, TAEG | tappa 1 + caccia alle uscite invisibili completata |
| 3 — *Misurare* | Regola del 4%, orizzonte personale, doppio effetto | tappa 2 + una simulazione completata |

L'avanzamento si sblocca quando l'utente **calcola e registra** una grandezza, mai quando la migliora. L'app misura la comprensione, non premia un comportamento finanziario.

### 6.7 Fallback per risparmio prossimo a zero

Se il tasso di risparmio è ≤ 0, l'unità "mesi di libertà" restituisce un valore inutilizzabile o infinito. Poiché questo è il segmento con la più bassa alfabetizzazione finanziaria — cioè l'utente più rilevante — serve un percorso dedicato.

**Commutazione automatica dell'unità di misura:**

| Unità standard | Unità di fallback |
|---|---|
| mesi di libertà | **euro all'anno** e **giorni di stipendio** |

Con i parametri di Giulia (60 € netti al giorno):

- 144 €/anno = **2,4 giorni di stipendio**
- 174 €/anno = **2,9 giorni di stipendio**
- 4.550 € cumulati = **76 giorni di stipendio**

Il resto dell'app (vocabolario, caccia alle uscite invisibili, tracking) funziona identico. Cambia solo l'unità in cui si esprime il risultato.

---

## 7. Architettura: i numeri non li produce l'LLM

Vincolo architetturale non negoziabile.

```
Input utente (reddito, uscite, % di costo)
     │
     ▼
┌─────────────────────────────┐
│  liberta-core               │  codice puro, coperto da test
│  UNICA fonte dei numeri     │  input → output riproducibile
└─────────────┬───────────────┘
              │ output numerico strutturato
              ▼
┌─────────────────────────────┐
│  LAYER LINGUISTICO          │  traduce e spiega al registro
│  nessun calcolo             │  del profilo lessicale
└─────────────┬───────────────┘
              │
              ▼
┌─────────────────────────────┐
│  GUARDRAIL EDUCATIVO        │  intercetta le richieste di consiglio
└─────────────────────────────┘
```

**Layer linguistico** — riceve solo l'output dell'engine. Non ha strumenti di calcolo, non ha in prompt alcun elenco di prodotti, non può emettere cifre non presenti nell'input. Il template accetta esclusivamente valori provenienti dall'engine.

**Guardrail educativo** — alla richiesta *"quindi mi conviene cambiare fondo?"* la risposta non è un disclaimer legale ma un momento educativo:

> *"Questo dipende da cose che non conosco e che riguardano solo te: quanto ti serve quel denaro, quando, e quanto ti pesa il rischio. Quello che posso fare è insegnarti a leggere il costo — così la domanda la porti tu, precisa, a chi di dovere. Vuoi che ti mostri quali tre numeri guardare?"*

Da testare con almeno cinque domande-trappola: *conviene?*, *è caro?*, *cosa faresti tu?*, *meglio A o B?*, *devo disdire?*

---

## 8. Before / After — evidenza di semplificazione

### Esempio A — riga di comunicazione periodica

**BEFORE**

> *"L'Indicatore Sintetico dei Costi (ISC) del comparto, calcolato su un orizzonte temporale di 10 anni, è pari a 1,45%."*

**AFTER**

> **Questo comparto trattiene ogni anno circa l'1,45% di quello che hai dentro.**
>
> Sui **12.000 €** che hai accantonato, quest'anno sono circa **174 €**.
> Non li vedi uscire: vengono trattenuti prima che il tuo saldo venga aggiornato.
>
> Se continui a versare **200 €/mese** e il capitale cresce ipoteticamente del **4% l'anno**, in 10 anni questo costo trattiene in tutto circa **4.550 €** — circa **15 mesi** del tuo risparmio attuale.
>
> ⚠️ Questo **non** ti dice se il comparto è buono o cattivo, né se te ne devi andare. Un costo più alto può corrispondere a una gestione diversa, a garanzie o a servizi che potresti volere. Ti dice solo **quanto costa**, in euro e in tempo. La decisione resta tua, e ora hai una domanda precisa da fare.

### Esempio B — addebito ricorrente

**BEFORE**

> *Abbonamento streaming — 11,99 € — addebito ricorrente mensile*

**AFTER**

> **11,99 € al mese pesano due volte sul tuo orizzonte di libertà.**
>
> 1. Ogni mese **non finiscono** nel tuo risparmio: **144 € in meno all'anno**.
> 2. Siccome è una spesa *fissa*, entra nel calcolo di quanto capitale ti serve per vivere senza stipendio. Con la regola convenzionale del 4% servono **25 volte** la spesa annuale → **3.600 € di capitale obiettivo in più**.
>
> **Effetto combinato: circa 12 mesi di libertà.**
>
> [ slider: prova a muovere l'importo ]
>
> ⚠️ Non ti stiamo dicendo di disdire niente. Se quell'abbonamento ti dà un anno di valore, è un buon acquisto. Ti stiamo dando **il prezzo corretto** per deciderlo tu.

### Sintesi del salto

| | Before | After |
|---|---|---|
| Unità di misura | percentuale astratta | euro + mesi (o giorni di stipendio) |
| Visibilità del costo | nulla, trattenuto | esplicita |
| Orizzonte | assente o generico | orizzonte personale dell'utente |
| Decisione | implicita e non informata | esplicita e restituita all'utente |
| Confronto tra prodotti | — | assente per progetto |

---

## 9. Semplificazioni, invarianti, disambiguazione

### 9.1 Cosa è stato semplificato

| Semplificazione | Motivo |
|---|---|
| Rendimento come **unica ipotesi dichiarata** (4%), non come distribuzione | Un range di scenari è illeggibile per il target; l'ipotesi è a schermo e modificabile con slider |
| **Regola del 4%** come convenzione di calcolo | Euristica didattica diffusa, presentata come "una regola convenzionale", mai come verità |
| Fiscalità e deducibilità **escluse** | Renderebbero il calcolo non verificabile dall'utente; esclusione dichiarata in ogni schermata di risultato |
| Inflazione non applicata in v1 | Limite dichiarato esplicitamente, non taciuto |

### 9.2 Cosa NON è stato alterato

- **Il numero di partenza.** ISC, TAEG, importo dell'addebito restano esattamente quelli del documento originale. L'app non arrotonda mai il dato di input.
- **La terminologia tecnica.** "ISC", "TAEG", "comparto" non vengono sostituiti da sinonimi inventati: vengono **affiancati** dalla spiegazione. L'utente deve uscire dall'app sapendo riconoscere la parola sul documento vero.
- **La direzione del giudizio.** L'app dice quanto costa. Non dice se è caro, se conviene, se è meglio di un'alternativa.
- **La titolarità della decisione.** Ogni output termina restituendo la scelta all'utente.

### 9.3 Come è evitata l'ambiguità

1. **Nessun confronto tra prodotti.** Il costo si misura contro un riferimento teorico a costo zero, etichettato a schermo come *"riferimento teorico, non un prodotto esistente"*.
2. **Ogni ipotesi è visibile accanto al risultato**, non in nota. Se lo slider del rendimento cambia, il risultato si aggiorna: l'utente impara che il numero dipende da un'assunzione.
3. **Distinzione tra dato e stima**, tipografica nel testo (grassetto per i dati reali, condizionale per le proiezioni) e grafica nei grafici (continuo vs tratteggiato).
4. **Nessun imperativo nel copy.** Mai "dovresti", "conviene", "meglio". Da verificare come checklist prima di ogni release.

### 9.4 Il confine operativo, per chi scrive il copy

| L'app può dire | L'app non può dire |
|---|---|
| "questo costo trattiene 4.550 € in 10 anni" | "questo costo è alto" |
| "12 €/mese valgono 12 mesi di libertà" | "ti conviene tagliare questo abbonamento" |
| "l'ISC del tuo comparto è 1,45%" | "questo fondo è migliore di quell'altro" |
| "ecco come si legge un TAEG" | "cosa faresti tu al mio posto" |

### 9.5 Rischi residui e mitigazioni

| Rischio | Mitigazione |
|---|---|
| L'utente legge il risultato come invito a disinvestire | Il warning è parte del risultato, non un footer |
| Proiezioni a 40 anni demotivanti | Il percorso enfatizza l'effetto su 12–48 mesi, orizzonte governabile |
| Utente con risparmio ≈ 0 escluso dall'unità di misura | Commutazione automatica a giorni di stipendio (§6.7) |
| Dati sensibili | Nessuna persistenza server, nessun login, dati in sessione o storage locale |
| Allucinazione numerica dell'LLM | L'LLM non ha il permesso di generare numeri (§7) |

---

## 10. Misurazione del miglioramento

Tre metriche, dalla più rapida alla più lenta.

### 10.1 Uscite invisibili trovate — immediata

Misurata alla prima sessione, sui dati reali dell'utente.

| | Valore tipico |
|---|---|
| Uscite ricorrenti che l'utente sa elencare spontaneamente | 3 |
| Uscite che l'app gli fa trovare | 7–8 |

È miglioramento della **capacità di gestione**, ottenuto in pochi minuti, su dati veri. È la metrica più difendibile perché non richiede attesa né autovalutazione.

### 10.2 Comprensione, con test di transfer — a fine percorso

Stessa domanda prima e dopo la micro-lezione, risposta numerica aperta:

> *"Il tuo fondo ha un costo dell'1,45% all'anno. Su 12.000 €, quanto ti costa nei prossimi 10 anni?"*

| | Risposta tipica |
|---|---|
| **Prima** | "non lo so" / "1,45%" / cifra sotto i 200 € |
| **Dopo** | ordine di grandezza corretto + capacità di indicare **da dove** viene il numero |

**Test di transfer:** una seconda domanda su un contesto *diverso* — un TAEG invece di un ISC. Verifica che sia stato appreso il metodo e non la singola risposta. È la metrica che distingue comprensione da memorizzazione.

### 10.3 Risparmio effettivo — mese per mese

Dal tracking prospettico (§6.5): scostamento della serie reale dalla baseline, espresso in euro cumulati e in mesi di libertà guadagnati dall'attivazione. Cresce con l'uso; al mese 1 esiste un solo punto.

---

## 11. Modello dati minimo

```
Utente
  nettoMensile
  livelloLessicale            1–3
  terminiRiconosciuti[]
  dataAttivazione

Uscita
  etichetta
  categoria                   fissa | variabile | invisibile
  importoMensile              oppure percentualeAnnua + baseDiCalcolo
  attivaNelloScenario         bool   // stato dello slider, non un suggerimento

Scenario
  uscitaDisattivate[]
  rendimentoIpotizzato        default 0.04
  regolaPrelievo              default 0.04

RegistrazioneMensile          // una per mese, dal mese 1 in poi
  mese
  usciteEffettive
  risparmioEffettivo
  mesiLibertaGuadagnati
```

Nessun campo contiene nomi di prodotti finanziari, per costruzione.

---

## 12. Fuori scope

Login e autenticazione · persistenza su server · parsing automatico di PDF (si carica un documento di esempio preparato) · più di 3 tappe di percorso · gestione di un portafoglio con nomi di prodotti · confronto tra strumenti finanziari · inflazione · fiscalità · notifiche push.

---

*Tutte le cifre del documento sono calcolate sull'engine di riferimento e riproducibili dai parametri dichiarati al §4.*

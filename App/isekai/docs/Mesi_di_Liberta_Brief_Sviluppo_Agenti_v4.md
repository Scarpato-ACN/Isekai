# Mesi di Libertà — brief di sviluppo
### Documento operativo per agenti di coding — v4.1

Questo documento è la fonte di verità per l'implementazione. Dove è in conflitto con conversazioni o versioni precedenti, vince questo documento.

**Novità della v4.0 rispetto alla v3.0** — quattro pilastri fondanti e percorso riorganizzato in 3 fasi / 9 tappe (§3, §6); nuova capability fondo di emergenza (§8); due correzioni all'engine con fixture ricalcolati (§5).

**Novità della v4.1** — la tappa **è** la pagina della mascot: pagina piena, spiegazione più illustrazione del dato, un solo bottone che riporta alla home (§7.2). Aggiunte le specifiche delle 9 illustrazioni (§7.7), il quarto stato di nodo "in corso" (§6.3) e la revisione delle condizioni di sblocco che ne consegue (§6.4).

---

## 0. Regole non negoziabili

Leggere prima di scrivere codice. Una violazione di queste regole invalida il lavoro anche se l'app funziona.

| # | Regola |
|---|---|
| R1 | **Tutti i numeri mostrati all'utente provengono da `liberta-core`.** Nessun calcolo nei componenti UI, nessun numero generato da un LLM. |
| R2 | **L'app non nomina mai un prodotto finanziario.** Nessun campo, enum, costante o stringa contiene nomi di banche, fondi, ETF, gestori. |
| R3 | **L'app non chiede dove l'utente tiene i soldi.** Il capitale è un importo. L'unica proprietà ammessa è la disponibilità dichiarata dall'utente (§8.2), che è funzionale e non identifica alcuno strumento. |
| R4 | **Nessun imperativo sulle scelte di denaro.** Vietate le stringhe contenenti: "dovresti", "conviene", "ti consigliamo", "meglio", "scegli X", "ottimizza". |
| R5 | **L'app non confronta due strumenti.** Nessuna funzione accetta due prodotti in input per compararli. |
| R6 | **Stime e dati reali sono distinguibili.** Nei grafici: tratteggio per le proiezioni, linea continua per i dati registrati. Nel testo: condizionale per le proiezioni. |
| R7 | **Ogni ipotesi è visibile accanto al risultato**, non in nota, e modificabile dall'utente dove previsto. |
| R8 | **La mascot istruisce sull'uso dell'app e sull'osservazione dei propri dati, mai su scelte di prodotto.** "Registra le spese di questa settimana" è ammesso. "Sposta i tuoi risparmi" non lo è. |

Il confine operativo, per chi scrive le stringhe:

| L'app può dire | L'app non può dire |
|---|---|
| "questo costo trattiene 4.554 € in 10 anni" | "questo costo è alto" |
| "12 €/mese valgono 11 mesi di libertà" | "ti conviene tagliare questo abbonamento" |
| "l'ISC del tuo comparto è 1,45%" | "questo comparto è migliore di quell'altro" |
| "un rendimento più alto porta più variabilità" | "questo prodotto rende di più" |
| "ecco come si legge un TAEG" | "al tuo posto io farei così" |

---

## 1. Cosa stiamo costruendo

App mobile di **educazione finanziaria**, non un simulatore. L'utente impara a gestire il quotidiano, a proteggersi dagli imprevisti e a leggere il costo reale delle proprie uscite ricorrenti — visibili e invisibili — tradotto in **mesi di libertà finanziaria**.

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
Input utente (profilo, uscite, registrazioni)
        │
        ▼
┌──────────────────────────┐
│  liberta-core            │  modulo puro, zero dipendenze UI
│  UNICA fonte dei numeri  │  input → output deterministico
└────────────┬─────────────┘
             │ oggetto numerico strutturato
             ▼
┌──────────────────────────┐
│  layer linguistico (LLM) │  registro del profilo lessicale
│  NON calcola             │  produce anche il copy della mascot
└────────────┬─────────────┘
             ▼
┌──────────────────────────┐
│  guardrail educativo     │  intercetta le richieste di consiglio
└──────────────────────────┘
```

Il layer linguistico non ha accesso a strumenti di calcolo, non ha in prompt alcun elenco di prodotti, e il template di output accetta esclusivamente valori provenienti da `liberta-core`.

---

## 3. I quattro pilastri fondanti

Ogni tappa del percorso appartiene a uno e un solo pilastro. Un contenuto che non rientra in un pilastro è fuori scope.

| # | Pilastro | Cosa insegna |
|---|---|---|
| P1 | **Gestione del budget** | Controllare entrate e uscite quotidiane |
| P2 | **Fondo di emergenza** | Accantonare liquidità per imprevisti improvvisi |
| P3 | **Rischio e rendimento** | Capire perché non esistono rendimenti alti senza variabilità |
| P4 | **Previdenza** | Capire come funziona e quanto costa integrare la pensione |

### 3.1 Nota obbligatoria su P3

La formulazione di P3 è vincolante. **Non** va implementato come "valutare i prodotti finanziari": valutare prodotti è consulenza, e l'intera architettura dell'app (R2, R3, R5) esiste per rendere quella valutazione impossibile.

P3 si insegna con uno strumento che l'app già possiede: **lo slider dell'ipotesi di crescita in Profilo**. Quando l'utente lo porta da 0% a 6%, la tappa spiega che sta assumendo anche una variabilità maggiore, e che quel 6% non è un rendimento promesso ma un'ipotesi che si è scelto da sé. La relazione rischio/rendimento viene insegnata sui dati dell'utente, senza nominare alcuno strumento.

La tappa 7 chiude con una schermata **"cosa non ti dirò mai"**: quali prodotti scegliere, se il tuo fondo è buono, dove mettere i soldi. Dichiarare il limite è a sua volta educazione finanziaria — insegna all'utente di cosa diffidare altrove.

---

## 4. Navigazione — 5 sezioni

Barra inferiore fissa, 5 voci, icone Tabler outline.

| Ordine | Voce | Icona | Contenuto |
|---|---|---|---|
| 1 | Percorso | `ti-route` | **Home.** 9 tappe in 3 fasi |
| 2 | Simulatore | `ti-calculator` | Simulatore di spesa ricorrente |
| 3 | Uscite | `ti-list-details` | Elenco uscite + caccia alle invisibili |
| 4 | Progressi | `ti-chart-line` | Grafico prospettico mese per mese |
| 5 | Profilo | `ti-user` | Parametri dell'utente |

**Schermata di avvio: Percorso.** Non il simulatore. L'app è una guida che contiene uno strumento, non uno strumento con del testo attorno.

---

## 5. `liberta-core` — specifica dell'engine

Modulo puro e testato. Nessun accesso a rete, storage o UI.

### 5.1 Firme

```
tassoRisparmio(nettoMensile, risparmioMensile) -> number            // 0..1
speseMensili(nettoMensile, risparmioMensile) -> number
fondoEmergenzaTarget(speseMensili, mesiCopertura = 3) -> number
coperturaMesi(capitaleDisponibile, speseMensili) -> number
capitaleVersoObiettivo(capitaleAccantonato, fondoEmergenzaTarget) -> number
capitaleObiettivo(speseMensili, regolaPrelievo = 0.04) -> number
mesiAllObiettivo(capitaleVersoObiettivo, risparmioMensile, crescitaAnnua, obiettivo) -> number | null
costoCumulato(capitale, versamentoMensile, crescitaAnnua, costoAnnuo, anni) -> number
impattoSpesaRicorrente(importoMensile, profilo) -> ImpattoSpesa
giorniDiStipendio(importoAnnuo, nettoMensile) -> number
deltaMesi(scenarioA, scenarioB) -> number
```

### 5.2 Formule

```
tassoRisparmio         = risparmioMensile / nettoMensile
speseMensili           = nettoMensile - risparmioMensile
fondoEmergenzaTarget   = speseMensili * mesiCopertura            // default 3
coperturaMesi          = capitaleDisponibile / speseMensili
capitaleVersoObiettivo = max(0, capitaleAccantonato - fondoEmergenzaTarget)
capitaleObiettivo      = speseMensili * 12 / regolaPrelievo      // con 0.04 → 25x
mesiAllObiettivo       = iterazione mensile:
                           saldo = saldo * (1 + crescitaAnnua/12) + risparmioMensile
                           conta i mesi fino a saldo >= obiettivo
                         cap a 12000 iterazioni → ritorna null
costoCumulato          = FV(costo 0%) - FV(costo applicato)
```

### 5.3 Correzione obbligatoria — il fondo non corre verso l'obiettivo

Il fondo di emergenza è un cuscinetto fermo, non capitale in avvicinamento al traguardo. **`mesiAllObiettivo` riceve `capitaleVersoObiettivo`, mai `capitaleAccantonato`.**

Con il profilo di riferimento l'errore vale 14 mesi (501 invece di 515): l'orizzonte risulta più vicino del vero. È il tipo di errore che nessuno nota fino a quando i numeri non sono già davanti a qualcuno.

### 5.4 `impattoSpesaRicorrente` — il doppio effetto

Cuore didattico dell'app. Tagliare una spesa **fissa** agisce su due grandezze:

```
leva1_risparmioAnnuo     = importoMensile * 12
leva2_riduzioneObiettivo = importoMensile * 12 / regolaPrelievo    // = 25x
```

Il taglio riduce anche `speseMensili`, quindi ricalcola a cascata `fondoEmergenzaTarget`, `capitaleVersoObiettivo` e `capitaleObiettivo`. Tutti e tre vanno ricomputati, non riusati dallo stato precedente.

**Leva 2 non dipende da nessuna ipotesi di rendimento: è pura moltiplicazione.** Va presentata come il risultato più solido dell'app, distinto dalle proiezioni.

### 5.5 Fixture di test — obbligatori

Profilo di riferimento: `età 32`, `netto 1800`, `risparmio 300`, `capitale 12000`, `crescita 0.04`, `regola 0.04`, `mesiCopertura 3`.

| Grandezza | Atteso |
|---|---|
| `tassoRisparmio` | 0,167 (16,7%) |
| `speseMensili` | 1.500 € |
| `fondoEmergenzaTarget` | **4.500 €** |
| `coperturaMesi` (su 12.000 disponibili) | **8,0** |
| `capitaleVersoObiettivo` | **7.500 €** |
| `capitaleObiettivo` | 450.000 € |
| `mesiAllObiettivo` | **515** (42,9 anni) |

`impattoSpesaRicorrente` a parità di profilo:

| Importo/mese | Leva 1 | Leva 2 | Mesi guadagnati |
|---|---|---|---|
| 12 € | 144 €/anno | −3.600 € | **11** |
| 30 € | 360 €/anno | −9.000 € | **27** |
| 50 € | 600 €/anno | −15.000 € | **44** |
| 100 € | 1.200 €/anno | −30.000 € | **81** |

La non-linearità della colonna finale è il messaggio educativo centrale. Se i test non la riproducono, il calcolo è sbagliato.

Altri fixture:

- `costoCumulato(12000, 200, 0.04, 0.0145, 10)` → **4.554 €** (≈ 15 mesi del risparmio del profilo)
- `mesiAllObiettivo` con `crescita = 0` → **1.475**
- mesi per costruire il fondo di emergenza da zero, a 300 €/mese → **15**

### 5.6 Casi limite — test obbligatori

| Input | Comportamento richiesto |
|---|---|
| `risparmio = 0` | `mesiAllObiettivo` ritorna `null` → commutazione in giorni di stipendio (§8.4) |
| `risparmio < 0` | `null`, nessuna eccezione |
| `crescita = 0` | calcolo valido. **Obbligatorio: chi tiene i soldi sul conto corrente è un utente legittimo.** |
| `risparmio > netto` | clamp a `netto`, nessuna eccezione |
| `netto = 0` | `tassoRisparmio` ritorna 0, nessuna divisione per zero |
| `capitaleAccantonato < fondoEmergenzaTarget` | `capitaleVersoObiettivo = 0`, mai negativo |
| `capitaleVersoObiettivo ≥ obiettivo` | ritorna 0 mesi |

### 5.7 Bug noto da non replicare

Nel prototipo il simulatore calcolava la baseline con `capitaleIniziale = 0`, ignorando il capitale del profilo. Il simulatore deve leggere lo stato del profilo: **un unico stato, una sola fonte per ogni parametro.**

---

## 6. Sezione 1 — Percorso (home)

Percorso verticale a tappe sequenziali, stile gioco, raggruppate in **3 fasi** con intestazione di fase.

### 6.1 Struttura

| Fase | Durata dichiarata | Pilastro | Tappe |
|---|---|---|---|
| **Fase 1** | mese 1 | P1 — budget | 1, 2, 3 |
| **Fase 2** | mesi 2–6 | P2 — fondo di emergenza | 4, 5, 6 |
| **Fase 3** | futuro | P3 + P4 | 7, 8, 9 |

La sequenza è vincolante: prima sai quanto spendi, poi ti proteggi dagli imprevisti, poi guardi lontano. L'orizzonte di lungo periodo arriva alla tappa 9, dove non scoraggia più.

### 6.2 Le nove tappe

| # | Titolo | Pilastro | Sottotitolo (dato reale) | Sblocco |
|---|---|---|---|---|
| 1 | Fisse o variabili | P1 | "l'affitto non si tratta" | profilo compilato |
| 2 | Il tuo tasso di risparmio | P1 | "il tuo: 16,7%" | tappa 1 |
| 3 | Registra un mese | P1 | "12 spese registrate" | tappa 2 |
| 4 | Perché tre mesi | P2 | "il tuo fondo: 4.500 €" | tappa 3 |
| 5 | I costi che non vedi | P2 | "3 di 7 trovate" | tappa 4 |
| 6 | Interesse composto | P2 | "sui tuoi 7.500 €" | tappa 5 |
| 7 | Rischio e rendimento | P3 | "la tua ipotesi: 4,0%" | tappa 6 |
| 8 | Previdenza e i suoi costi | P4 | "il tuo ISC: 1,45%" | tappa 7 |
| 9 | Il tuo orizzonte | P4 | "hai guadagnato 11 mesi" | tappa 8 |

**Requisito: ogni sottotitolo contiene un dato reale dell'utente**, calcolato da `liberta-core`. È ciò che distingue un percorso educativo da un corso generico: il concetto viene spiegato e immediatamente riempito con il numero della persona.

### 6.3 Stati del nodo

| Stato | Aspetto |
|---|---|
| Completata | fill `--bg-success`, icona `ti-check` in `--text-success` |
| Corrente | fill `--fill-accent`, icona del tema in `--on-accent`, alone `box-shadow: 0 0 0 4px var(--bg-accent)`, bottone "Continua" sotto il nodo |
| **In corso** | fill `--bg-warning`, icona del tema in `--text-warning`, sottotitolo con contatore ("3 di 7 trovate") |
| Bloccata | fill `--surface-0`, icona `ti-lock` in `--text-muted` |

Lo stato **in corso** esiste solo per le due tappe con compito (§6.5): la spiegazione è stata letta ma la soglia di dati non è ancora raggiunta.

In alto: barra di progresso e contatore "tappa N di 9". Nodo bloccato toccabile: comunica cosa serve per sbloccarlo, non è disabilitato.

### 6.4 Condizioni di sblocco

L'avanzamento si sblocca quando l'utente **legge il proprio dato**, **mai quando lo migliora**. L'app misura la comprensione, non premia un comportamento finanziario.

Sette tappe su nove sono di pura lettura: la pagina della mascot spiega e illustra il dato, il bottone la completa. Due tappe hanno un compito che richiede dati non ancora presenti.

| Tappa | Tipo | Completata quando |
|---|---|---|
| 1 | lettura | bottone premuto |
| 2 | lettura | bottone premuto |
| **3** | **con compito** | 10 spese registrate in Uscite |
| 4 | lettura | bottone premuto |
| **5** | **con compito** | 5 uscite invisibili controllate |
| 6 | lettura | bottone premuto |
| 7 | lettura | bottone premuto (la pagina contiene lo slider, §7.5) |
| 8 | lettura | bottone premuto |
| 9 | lettura | bottone premuto |

Prerequisito di accesso: tappa N accessibile solo con tappa N−1 completata. Tappa 1 richiede il profilo compilato.

### 6.5 Tappe critiche

**Tappa 3 e tappa 5** mandano l'utente in un'altra sezione per essere completate. Sono i raccordi tra percorso e dati, e i punti in cui si perde l'utente.

Su queste due tappe il bottone della pagina mascot **non** completa la tappa: la porta in stato *in corso* e riapre la home. Etichetta del bottone diversa dalle altre sette — "Vai a registrare le spese" / "Vai a cercare i costi nascosti" — e destinazione la sezione Uscite, non la home.

Mitigazione obbligatoria: il nodo mostra il **conteggio in tempo reale** ("3 di 7 trovate") e la sezione Uscite espone un CTA di rientro al percorso quando la soglia è raggiunta.

Senza queste due tappe la metrica primaria del progetto (§12.1) non raccoglie nulla: sono le uniche che producono dati reali invece di leggerli.

### 6.6 Tappa 9 — regola di chiusura

La tappa finale si chiude sul **primo scarto misurato** ("hai guadagnato 11 mesi dall'attivazione"), **non** sulla data assoluta di arrivo.

---

## 7. La mascot — guida di ogni tappa

### 7.1 Cosa è

Personaggio illustrato che introduce **ogni** tappa prima che l'utente vi acceda. Non è decorazione: è il componente che rende il percorso comprensibile a chi non sa cosa lo aspetta.

Proposta: uno scoiattolo di nome **Nocciola** — l'animale che accantona per l'inverno è la metafora esatta del fondo di emergenza. Il nome è un placeholder sostituibile; il ruolo e le regole che seguono non lo sono.

### 7.2 Il flusso — la tappa è la pagina della mascot

Non esiste un "contenuto della tappa" separato dalla spiegazione. La pagina della mascot **è** la tappa.

```
Percorso (home)
   │  tap sul nodo
   ▼
PAGINA DELLA TAPPA           ← pagina piena, non bottom sheet
   │  la mascot spiega e illustra il dato dell'utente
   │
   │  tappe di lettura (7 su 9)    tappe con compito (3 e 5)
   │  bottone "Ok, ho capito"       bottone "Vai a registrare…"
   ▼                                 ▼
Percorso (home)                   Sezione Uscite
nodo completato                   nodo in stato "in corso"
```

**Requisiti del flusso:**

- **Pagina piena**, non bottom sheet: la pagina deve ospitare l'illustrazione del dato (§7.7), che in un foglio a mezza altezza non ci sta.
- **Un solo bottone primario.** Nessun "avanti" interno, nessuna sequenza di schermate dentro la tappa. Una tappa, una pagina, un'azione.
- Il bottone di ritorno è anche quello di completamento: premerlo **è** la conferma di lettura.
- Barra inferiore **nascosta** nella pagina della tappa: l'utente esce solo dal bottone o dalla freccia indietro in alto. La freccia indietro **non** completa la tappa.
- Al rientro in home il nodo è già aggiornato, senza ricaricare, e la vista scrolla sul nodo successivo.
- Tappa già completata: riapribile, pagina identica, bottone etichettato "Chiudi", nessun doppio conteggio nelle metriche.
- Nessuna animazione bloccante al rientro. Il percorso deve essere leggibile entro un frame.

### 7.3 Struttura della pagina — cinque blocchi fissi

Ogni pagina di tappa ha esattamente questi blocchi, in questo ordine. Nessuna variazione tra tappe.

| # | Blocco | Contenuto | Limite |
|---|---|---|---|
| 1 | Mascot + titolo della tappa | illustrazione, stato *parlante* | — |
| 2 | **Cosa impari qui** | il concetto, in linguaggio quotidiano | max 2 frasi, 25 parole |
| 3 | **Perché riguarda te** | il concetto applicato a un dato reale dell'utente | max 2 frasi, almeno un numero dall'engine |
| 4 | **Illustrazione del dato** | la visualizzazione del numero di cui parla il blocco 3 (§7.7) | una sola, nessun grafico multiplo |
| 5 | **Cosa non ti dirò** | il limite dell'app su questo tema | max 1 frase |
| 6 | Bottone primario | "Ok, ho capito" oppure il CTA della tappa con compito | uno solo |

L'ordine è vincolante: il blocco 3 **nomina** il numero, il blocco 4 **lo mostra**. Invertirli lascia l'utente davanti a un grafico che non sa ancora leggere.

Il blocco 5 è obbligatorio su tutte le nove tappe, non solo su quelle di P3 e P4. È il presidio distribuito del vincolo anti-consulenza: l'utente incontra il limite nove volte, non una.

### 7.4 Esempio — tappa 4, livello lessicale 1

> **Cosa impari qui**
> Un imprevisto non chiede il permesso. Il fondo di emergenza è la cifra che ti fa dormire tranquillo quando arriva.
>
> **Perché riguarda te**
> Tu spendi 1.500 € al mese. Tre mesi di spese fanno **4.500 €**: oggi hai una copertura di **8 mesi**.
>
> **Illustrazione del dato**
> Barra di copertura: tre segmenti da un mese, riempiti, più l'eccedenza in grigio. Soglia dei 3 mesi marcata.
>
> **Cosa non ti dirò**
> Dove tenere questi soldi: quello lo decidi tu.
>
> `[ Ok, ho capito ]`

### 7.5 Regole di scrittura

- **Registro adattato al livello lessicale** (1–3). Al livello 1 nessun termine tecnico non spiegato nella frase stessa.
- **Tutti i numeri vengono dall'engine** (R1). Il template della mascot rifiuta qualunque cifra non presente nell'input.
- **Nessun imperativo sulle scelte di denaro** (R4). Ammessi gli imperativi sull'uso dell'app: "registra le spese di questa settimana", "muovi lo slider".
- **Tono**: caldo, diretto, mai paternalistico. Nessun punto esclamativo. Nessuna congratulazione sproporzionata al gesto.
- **Sentence case.** Nessuna emoji: la mascot è un'illustrazione, non un carattere.
- La mascot **non celebra scelte finanziarie**. Celebra tappe di apprendimento completate. "Hai capito da dove viene il tuo obiettivo" sì; "bravo, hai risparmiato di più" no.

### 7.6 Requisiti tecnici

- **Tre stati visivi della mascot:** neutro, indicante (quando la frase punta al dato illustrato), celebrativo (tappa completata, al rientro in home). Non servono animazioni complesse.
- **Il testo è autosufficiente.** Né la mascot né l'illustrazione portano informazione che non sia anche nel testo: chi non le vede riceve lo stesso contenuto. Mascot `aria-hidden`; l'illustrazione del dato ha `role="img"` con `aria-label` che riporta il numero a parole.
- Il copy è prodotto dal layer linguistico a partire da un template per tappa più i valori dell'engine. I template sono contenuto versionato, non stringhe inline nei componenti.
- La pagina può scorrere, ma con i limiti del §7.3 il contenuto sta in una schermata su un telefono da 390×844. **Il bottone primario deve essere raggiungibile senza scorrere.**

### 7.7 Le nove illustrazioni del dato

Una per tappa, ognuna mostra **un solo numero** — quello nominato nel blocco 3. Tutti i valori provengono da `liberta-core` (R1).

| Tappa | Dato illustrato | Forma |
|---|---|---|
| 1 | ripartizione fisse / variabili | barra unica divisa in due segmenti, etichette in euro |
| 2 | tasso di risparmio 16,7% | anello di progresso, la porzione risparmiata evidenziata |
| 3 | spese registrate finora | contatore grande + barra verso la soglia di 10 |
| 4 | copertura 8 mesi su 3 richiesti | barra a segmenti mensili con soglia marcata |
| 5 | uscite invisibili trovate | 7 caselle, quelle controllate riempite |
| 6 | crescita di 7.500 € nel tempo | curva singola, 20 anni, un solo scenario |
| 7 | effetto dell'ipotesi di crescita | **slider vivo** 0–6% con la curva che cambia sotto |
| 8 | ISC 1,45% in euro | 1.450 € su 100.000 € come area piena su area totale |
| 9 | mesi guadagnati dall'attivazione | due barre: baseline e attuale, differenza etichettata |

**Regole comuni:**

- **Una sola grandezza per illustrazione.** Nessun grafico con due serie tranne la tappa 9, dove il confronto *è* il contenuto.
- Le proiezioni (tappe 6, 7) sono tratteggiate (R6).
- Nessun asse senza etichetta, nessuna legenda superflua: il blocco 3 ha già detto cosa si sta guardando.
- La tappa 7 è l'unica con un controllo interattivo dentro la pagina. È il modo in cui P3 viene insegnato (§3.1): il valore mosso qui scrive su `crescitaIpotizzata` nel profilo, non su una copia locale.
- Dark mode obbligatoria come per il resto dell'app.

---

## 8. Fondo di emergenza — nuova capability

### 8.1 Perché esiste

L'app senza fondo di emergenza ha un solo obiettivo, a 42,9 anni di distanza: nessun traguardo raggiungibile. Con le spese del profilo di riferimento, tre mesi fanno **4.500 €** — un traguardo che l'utente vede avvicinarsi ogni mese.

È anche il solo obiettivo dell'app che un utente a basso reddito possa effettivamente raggiungere.

### 8.2 Il campo di disponibilità

Serve sapere quanto del capitale è utilizzabile subito: un fondo di emergenza che non puoi prelevare non è un fondo di emergenza. Ma R3 vieta di chiedere dove sono i soldi.

Soluzione, unico campo aggiuntivo in Profilo:

> **"Quanto di questi soldi potresti usare domani, senza penali"**

È una proprietà **funzionale dichiarata dall'utente**, non uno strumento che l'app viene a sapere. Continuiamo a non conoscere il collocamento, quindi continuiamo a non poterlo giudicare.

Campo: `capitaleDisponibile`, number, ≤ `capitaleAccantonato`, default pari a `capitaleAccantonato`.

### 8.3 Cosa mostra la tappa 4

- `fondoEmergenzaTarget` in euro (3 × spese mensili)
- `coperturaMesi` attuale, calcolata su `capitaleDisponibile`
- se la copertura è inferiore a 3: mesi necessari a colmarla al ritmo di risparmio attuale
- se è superiore: la tappa si completa con la copertura raggiunta, senza suggerire cosa fare dell'eccedenza

Il numero di mesi di copertura è configurabile (`mesiCopertura`, default 3) ed è dichiarato a schermo come convenzione, non come regola assoluta.

### 8.4 Modalità giorni di stipendio

Se `tassoRisparmio <= 0`, l'unità "mesi di libertà" è inutilizzabile. Poiché questo è il segmento con la più bassa alfabetizzazione finanziaria — cioè l'utente più rilevante del progetto — serve una commutazione automatica, non un messaggio di errore.

| Unità standard | Unità di fallback |
|---|---|
| mesi di libertà | euro all'anno + **giorni di stipendio** |

`giorniDiStipendio(importoAnnuo, nettoMensile) = importoAnnuo / (nettoMensile / 30)`

Con netto 1.800 € (60 €/giorno): 144 €/anno = 2,4 giorni · 174 €/anno = 2,9 giorni · 4.554 € cumulati = 76 giorni.

In questa modalità il fondo di emergenza resta l'obiettivo primario del percorso e le tappe 6–9 restano accessibili come contenuto educativo, senza proiezione temporale.

---

## 9. Sezione 2 — Simulatore

Ordine degli elementi a schermo, dall'alto: **spiegazione, poi controllo, poi risultato.** Mai il contrario.

1. **Riquadro di spiegazione** (`--bg-accent`), titolo "Una spesa fissa pesa due volte", due righe che introducono le due leve
2. **Slider** `min=0 max=120 step=1`, valore iniziale 12, readout in euro
3. **Due metric card affiancate**, etichettate `Leva 1 — risparmio` e `Leva 2 — obiettivo`
4. **Riquadro risultato** (`--bg-success`): mesi di libertà + riga secondaria "traguardo: da 42,9 a 42,0 anni"
5. **Nota** con icona `ti-info-circle`: assenza di consiglio + ipotesi in chiaro

### Requisiti funzionali

- **L'app non propone mai un importo di taglio.** Solo slider mosso dall'utente. Un valore suggerito dall'app è un consiglio comportamentale; uno slider è uno strumento.
- Le etichette "Leva 1" e "Leva 2" corrispondono ai termini del riquadro di spiegazione: l'utente collega il testo ai numeri.
- Ricalcolo sincrono su `input`, non su `change`. La non-linearità si percepisce solo trascinando.
- Il ricalcolo aggiorna a cascata fondo di emergenza e capitale verso obiettivo (§5.4).
- Tutti i numeri arrotondati: `Math.round` o `toLocaleString('it-IT')`.

---

## 10. Sezione 3 — Uscite

### 10.1 Classificazione

| Categoria | Esempi | Input |
|---|---|---|
| Fisse visibili | affitto, utenze, abbonamenti, rate | importo mensile in € |
| Variabili | spesa alimentare, tempo libero | importo mensile in € |
| **Invisibili** | commissioni, ISC, canoni, costi di gestione | **percentuale annua + base di calcolo** |

La categoria *invisibili* è l'unica in cui l'utente inserisce una percentuale e riceve un importo. È la funzione che risolve la difficoltà #1 del §1.

### 10.2 Registrazione spese — fase 1

La tappa 3 richiede almeno 10 spese registrate. La sezione deve quindi permettere inserimento rapido: importo, etichetta, categoria, in un'unica riga. Nessun campo obbligatorio oltre a importo e categoria.

### 10.3 Caccia alle uscite invisibili

Checklist guidata sui luoghi in cui si nascondono i costi ricorrenti: canone del conto, costo della carta, ISC del fondo pensione, spese di gestione, rinnovi automatici, assicurazioni accessorie, commissioni di bonifico.

**Requisito di misurazione:** due contatori distinti
- `usciteDichiarateSpontaneamente` — quante l'utente elenca prima della checklist
- `usciteTrovate` — quante risultano alla fine

Il delta è la metrica di miglioramento primaria (§12.1).

---

## 11. Sezione 4 — Progressi, e Sezione 5 — Profilo

### 11.1 Progressi — tracking prospettico

Nessun dato storico: la serie parte dal giorno dell'attivazione e cresce mese per mese.

**T0:** dai dati di profilo l'engine genera due serie proiettate — baseline (spese invariate) e obiettivo (scenari impostati nel simulatore).

**Ogni mese:** l'utente registra le uscite effettive. L'engine aggiunge un punto alla serie reale e ricalcola risparmio effettivo, scostamento dalla baseline e **mesi di libertà guadagnati o persi dall'attivazione**.

| | |
|---|---|
| Asse X | mesi dall'attivazione (0 → 24, poi rolling) |
| Asse Y | risparmio cumulato (€) |
| Serie 1 | baseline proiettata — **tratteggiata**, grigia |
| Serie 2 | obiettivo impostato — **tratteggiata**, accento |
| Serie 3 | effettivo registrato — **continua**, piena |
| Badge | mesi di libertà guadagnati dall'attivazione |
| Marker | raggiungimento del fondo di emergenza |

Le serie proiettate sono graficamente distinguibili da quella reale e la legenda lo dichiara a parole (R6).

**Mese 1:** esiste un solo punto reale. Stato vuoto richiesto: le due linee proiettate più il messaggio "il tuo primo dato reale arriva tra N giorni". Mai un grafico vuoto, mai dati precaricati. Con la fase 1 questo mese ha uno scopo dichiarato — registrare le spese — quindi non va presentato come attesa passiva.

### 11.2 Profilo — campi

| Campo | Tipo | Default | Hint a schermo |
|---|---|---|---|
| Età | number 18–70 | 32 | — |
| Stipendio netto | number, step 50 | 1800 | "al mese, quello che ti arriva" |
| Risparmio | number, step 10 | 300 | "quanto ti resta a fine mese" |
| Già accantonato | number, step 500 | 12000 | **"tutto, dove non ci interessa"** |
| Disponibile subito | number, step 500 | = accantonato | **"quanto potresti usare domani, senza penali"** |
| Ipotesi di crescita | slider 0–6%, step 0,5 | 4,0% | "La scegli tu. Non sappiamo dove tieni i soldi, quindi non la decidiamo per te." |

**Chiediamo il risparmio, non le spese.** L'utente sa quanto gli resta a fine mese; quasi nessuno sa quanto spende. Le spese le deriva l'engine e le mostra come "spese stimate", così l'utente vede il legame invece di subirlo.

Le stringhe in grassetto sono requisiti, non suggerimenti: sono ciò che rende strutturalmente impossibile all'app giudicare le scelte dell'utente.

**Valori derivati mostrati sotto i campi:** tasso di risparmio · spese stimate · fondo di emergenza target · copertura attuale · capitale obiettivo · orizzonte in anni.

### 11.3 Regola di presentazione dell'orizzonte

Con un tasso di risparmio del 16,7% l'orizzonte è 42,9 anni, cioè l'arrivo a 75 anni di età. È corretto ed è il caso più probabile per l'utente target, ma come messaggio post-onboarding è demotivante — e un utente demotivato non impara.

1. In Profilo si mostra **solo l'orizzonte in anni**, non l'età di arrivo.
2. L'età di arrivo compare **solo nella tappa 9**, quando l'utente ha già visto muoversi il numero.
3. Accanto allo stato si mostra sempre **la derivata**: "42,9 anni oggi — con 50 € in meno di spese fisse diventano 39,2".

Lo stato assoluto scoraggia, la derivata motiva. L'app non nasconde nulla, ma non apre con il numero peggiore che possiede.

---

## 12. Metriche da strumentare

| # | Metrica | Quando | Come |
|---|---|---|---|
| 12.1 | **Uscite invisibili trovate** | prima sessione | `usciteTrovate - usciteDichiarateSpontaneamente`. Valore tipico: da 3 a 7–8 |
| 12.2 | **Comprensione, con transfer** | fine percorso | stessa domanda pre/post + una seconda domanda su contesto diverso (un TAEG invece di un ISC) |
| 12.3 | **Copertura del fondo di emergenza** | mensile | `coperturaMesi` nel tempo — l'unica metrica con un traguardo raggiungibile |
| 12.4 | **Risparmio effettivo** | mensile | scostamento della serie reale dalla baseline |

La 12.1 è la metrica primaria: produce risultati alla prima sessione, su dati reali, senza autovalutazione. La 12.2 distingue comprensione da memorizzazione — il transfer è la parte che conta.

---

## 13. Layer linguistico e guardrail

### 13.1 Profilo lessicale

Sei domande che misurano **quali termini l'utente riconosce**, non quanto sa: TAN vs TAEG, ISC, interesse composto, inflazione, spesa fissa vs variabile, rendimento netto.

Output: livello 1–3, che determina il registro di ogni spiegazione e di ogni intro della mascot. Non è un quiz a punteggio: è il parametro di configurazione dell'intera applicazione. I termini non riconosciuti diventano il contenuto sbloccabile nel percorso.

### 13.2 Regole del layer linguistico

- Input: **solo** l'oggetto numerico prodotto da `liberta-core` + il livello lessicale + il template della tappa
- Nessun tool di calcolo, nessun elenco di prodotti in prompt
- Il template di output rifiuta qualunque cifra non presente nell'input
- La terminologia tecnica viene **affiancata** dalla spiegazione, non sostituita da sinonimi inventati: l'utente deve uscire dall'app sapendo riconoscere "ISC" sul documento vero

### 13.3 Guardrail

Alla richiesta di consiglio la risposta non è un disclaimer legale ma un reindirizzamento educativo:

> "Questo dipende da cose che non conosco e che riguardano solo te: quanto ti serve quel denaro, quando, e quanto ti pesa il rischio. Quello che posso fare è insegnarti a leggere il costo — così la domanda la porti tu, precisa, a chi di dovere. Vuoi che ti mostri quali tre numeri guardare?"

**Test obbligatori**, tutti intercettati:

1. "conviene?"
2. "è caro?"
3. "cosa faresti tu al mio posto?"
4. "meglio A o B?"
5. "devo disdire?"
6. "dove dovrei investire questi 12.000 €?"
7. "dove tengo il fondo di emergenza?"
8. "con il 6% cosa devo comprare?"

Le ultime due sono nuove: il fondo di emergenza e lo slider di crescita creano due nuove porte d'ingresso alla richiesta di consiglio.

---

## 14. Semplificazioni dichiarate e invarianti

| Semplificazione | Motivo |
|---|---|
| Crescita come **unica ipotesi dichiarata**, non distribuzione di scenari | Un range è illeggibile per il target; l'ipotesi è a schermo e modificabile |
| Regola del 4% come convenzione | Euristica didattica, presentata come "una regola convenzionale", mai come verità |
| Fondo di emergenza a 3 mesi | Convenzione dichiarata e configurabile, non una regola assoluta |
| Fiscalità e deducibilità escluse | Renderebbero il calcolo non verificabile dall'utente; esclusione dichiarata in ogni schermata di risultato |
| Inflazione non applicata in v1 | Limite dichiarato esplicitamente, non taciuto |
| Costo misurato contro un riferimento a costo zero | Etichettato come *"riferimento teorico, non un prodotto esistente"* — un prodotto a costo zero non esiste e ometterlo altererebbe il significato |

**Cosa non deve essere alterato:** il dato di input (ISC, TAEG, importi restano quelli del documento originale; l'app non arrotonda mai un input) · la terminologia (affiancata, non sostituita) · la direzione del giudizio (quanto costa, non se è caro) · la titolarità della decisione.

---

## 15. Modello dati

```
Profilo
  eta                         int 18..70
  nettoMensile                number
  risparmioMensile            number
  capitaleAccantonato         number      // nessun attributo di collocazione (R3)
  capitaleDisponibile         number      // <= capitaleAccantonato
  crescitaIpotizzata          number      default 0.04
  regolaPrelievo              number      default 0.04
  mesiCopertura               number      default 3
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
  coperturaMesi               number

ProgressoPercorso
  tappaCorrente               1..9
  tappeCompletate             int[]
  faseCorrente                1 | 2 | 3
  usciteDichiarateSpontaneamente  int
  usciteTrovate               int
  introMascotViste            int[]       // per tappa

TemplateMascot                            // contenuto versionato, non stringhe inline
  tappa                      1..9
  livello                    1 | 2 | 3
  cosaImpari                 string
  percheRiguardaTe           string       // contiene placeholder per valori engine
  cosaNonTiDiro              string
```

Nessun campo contiene nomi di prodotti finanziari, per costruzione (R2).

---

## 16. Linee guida UI

- Mobile-first, barra inferiore fissa a 5 voci
- Icone: Tabler **outline** (mai varianti `-filled`)
- **Sentence case** in tutte le stringhe. Mai Title Case, mai maiuscolo
- Due pesi tipografici: 400 e 500. Mai 600 o 700
- Bordi 0,5px, raggio 8px per i controlli, 12px per le card
- Nessun gradiente, nessuna ombra decorativa
- Colori sempre via variabili CSS: dark mode obbligatoria
- Ogni numero a schermo passa per `Math.round`, `toFixed(n)` o `toLocaleString('it-IT')`
- Nessun bottone disabilitato per stati raggiungibili
- Intro della mascot: bottom sheet ad altezza contenuto, mai a pagina piena, mai con scroll interno

---

## 17. Definition of done

| # | Criterio |
|---|---|
| D1 | `liberta-core` passa tutti i fixture del §5.5 e tutti i casi limite del §5.6 |
| D2 | `mesiAllObiettivo` riceve `capitaleVersoObiettivo`, non `capitaleAccantonato` (§5.3) |
| D3 | Il simulatore legge lo stato del profilo e ricalcola a cascata fondo ed obiettivo |
| D4 | Modificare un campo in Profilo aggiorna percorso, simulatore e progressi senza ricaricare |
| D5 | Con `risparmio = 0` l'app resta usabile e commuta in giorni di stipendio |
| D6 | Con `crescita = 0%` tutti i calcoli restano validi |
| D7 | Le 8 domande-trappola del §13.3 sono tutte intercettate |
| D8 | Grep del codebase: zero occorrenze delle stringhe vietate in R4 |
| D9 | Grep del codebase: zero nomi di prodotti o intermediari finanziari |
| D10 | Ognuna delle 9 tappe è una pagina piena con i sei blocchi del §7.3, tutti presenti e in quell'ordine |
| D11 | Ogni blocco "perché riguarda te" contiene almeno un numero proveniente dall'engine |
| D12 | Ogni blocco "cosa non ti dirò" è presente su tutte e 9 le tappe |
| D13 | Ogni sottotitolo delle 9 tappe contiene un dato reale calcolato dall'engine |
| D14 | Le pagine esistono ai tre livelli lessicali e il registro cambia effettivamente |
| D14b | Ogni tappa ha la sua illustrazione del dato (§7.7), con `aria-label` che riporta il numero a parole |
| D14c | Il bottone primario è raggiungibile senza scorrere su 390×844; la barra inferiore è nascosta nella pagina di tappa |
| D14d | Il bottone completa la tappa e riporta alla home; la freccia indietro non completa nulla |
| D14e | Le tappe 3 e 5 portano in stato "in corso" e puntano alla sezione Uscite, non alla home |
| D14f | Lo slider della tappa 7 scrive su `crescitaIpotizzata` nel profilo, non su una copia locale |
| D15 | Nel grafico Progressi le serie proiettate sono tratteggiate e la legenda lo dichiara |
| D16 | Profilo non mostra l'età di arrivo; la tappa 9 chiude sullo scarto, non sull'assoluto |
| D17 | La tappa 4 non suggerisce cosa fare dell'eccedenza oltre i 3 mesi di copertura |
| D18 | Nessun numero a schermo presenta artefatti float |

---

*Tutte le cifre di questo documento sono calcolate sull'engine di riferimento e riproducibili dal profilo dichiarato al §5.5.*

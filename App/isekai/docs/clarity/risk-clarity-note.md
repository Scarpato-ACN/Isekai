# Risk & Clarity Note — Mesi di Libertà

## Cosa è stato semplificato

- La percentuale astratta (1,45%) è stata tradotta in importi concreti (174 €/anno,
  4.550 € cumulati) e in un'unità di tempo (15 mesi di risparmio).
- La riga piatta "abbonamento — 11,99 € — mensile" è diventata una spiegazione del
  doppio effetto (risparmio mancante + riduzione del capitale obiettivo), con le due
  componenti visibili separatamente come richiesto da AC-2.
- Le proiezioni a 10 anni sono accompagnate dall'ipotesi esplicita (4% annuo) e da
  un disclaimer che restituisce la decisione all'utente.
- Il copy è costruito senza imperativi né parole di comparazione ("conviene",
  "dovresti", "è meglio").

---

## Cosa NON è stato alterato

### Esempio A — ISC 1,45%

Elementi informativi estratti dal BEFORE: 4.

| elemento del BEFORE | presente nel AFTER | alterato | nota |
|---|---|---|---|
| denominazione tecnica "ISC" / "Indicatore Sintetico dei Costi" | **NO** | **omissione** | il AFTER usa solo "questo comparto trattiene"; la sigla ISC non compare. Contraddice §9.2: "ISC non viene sostituito da sinonimi inventati: viene affiancato dalla spiegazione". L'utente non impara a riconoscere il termine sul documento vero. |
| ambito "del comparto" | sì | no | "Questo comparto" — preservato |
| orizzonte "calcolato su 10 anni" | parziale | **alterazione semantica** | nel BEFORE l'orizzonte è l'attributo convenzionale del metodo di calcolo dell'ISC (norma regolatoria); nel AFTER "in 10 anni" è l'orizzonte della simulazione dell'utente. I due significati non coincidono: uno descrive come è costruita la metrica, l'altro quanti anni l'utente vuole simulare. Un lettore del AFTER può credere di aver scelto lui l'orizzonte. |
| valore 1,45% | sì | no | invariato |

**Cifre aggiunte nel AFTER verificate sui parametri §4 e tabella §5.3:**

| cifra nel AFTER | fonte | verificabile |
|---|---|---|
| 12.000 € accantonati | §4 Giulia | sì |
| 174 € primo anno | §5.3 "Costo del primo anno ~174 €" | sì |
| 200 €/mese versamento | §4 Giulia | sì |
| 4% ipotesi rendimento | §5.1, dichiarata come ipotesi | sì |
| 4.550 € cumulati 10 anni | §5.3 "Costo cumulato a 10 anni ~4.550 €" | sì |
| 15 mesi | §5.3 "Equivalente in risparmio di Giulia ~15 mesi" | sì |

**2 su 4 elementi preservati senza alterazione. 1 omissione, 1 alterazione semantica.**

---

### Esempio B — abbonamento 11,99 €

Elementi informativi estratti dal BEFORE: 3.

| elemento del BEFORE | presente nel AFTER | alterato | nota |
|---|---|---|---|
| categoria "Abbonamento streaming" | parziale | alterazione minore | "streaming" scompare dall'apertura; il AFTER apre con "11,99 € al mese pesano due volte" senza nominare la categoria. La parola "abbonamento" compare solo più avanti ("quell'abbonamento"). La categoria specifica si perde. |
| importo 11,99 € | sì | no | invariato, prima parola del AFTER |
| periodicità "addebito ricorrente mensile" | sì | no | "al mese" — preservato |

**Cifre aggiunte nel AFTER verificate sui parametri §4 e §5.1:**

| cifra nel AFTER | calcolo | verificabile |
|---|---|---|
| 144 € all'anno | 11,99 × 12 = 143,88 → arrotondato a 144 come in §5.1 | sì |
| 25 volte la spesa annuale | regola del 4% §5.1 | sì |
| 3.600 € capitale obiettivo in più | 25 × 144 = 3.600, §5.1 | sì |
| 12 mesi di libertà | §5.1 e tabella §5.2 per taglio 12 €/mese | sì |

**1 su 3 elementi preservati senza riserve. 1 alterazione minore. Nessun numero inventato.**

---

## Rischi identificati

1. **[MEDIO] Omissione del termine "ISC" — Esempio A.**
   Il termine tecnico "ISC" non compare nel AFTER. La spec §9.2 lo dichiara invariante:
   "ISC, TAEG, comparto non vengono sostituiti da sinonimi inventati: vengono affiancati
   dalla spiegazione." L'omissione rende il testo più leggibile ma impedisce all'utente
   di riconoscere la sigla sul documento vero. Contraddice l'obiettivo dichiarato del
   prodotto (l'utente deve uscire dall'app sapendo riconoscere la parola).

2. **[MEDIO] Cambio di contesto semantico dell'orizzonte "10 anni" — Esempio A.**
   Nel BEFORE l'orizzonte è un attributo definitorio del calcolo dell'ISC (convenzione
   regolatoria); nel AFTER è l'orizzonte della simulazione dell'utente. Un lettore del
   AFTER non sa che l'ISC è definito su 10 anni per convenzione, non per scelta sua.
   La distinzione è rilevante: l'ISC a 5 anni dello stesso fondo sarebbe un numero
   diverso, e l'utente non ha gli strumenti per saperlo.

3. **[BASSO] Riferimento teorico a costo zero non esplicitato nel testo AFTER — Esempio A.**
   Il AFTER dice "in 10 anni questo costo trattiene in tutto circa 4.550 €" senza
   specificare rispetto a quale baseline. La spec §5.3 richiede che il confronto con
   il riferimento teorico a costo zero "vada etichettato a schermo come tale" e AC-3
   richiede che l'etichetta sia "visibile nella stessa schermata del risultato, non in
   nota". Il testo del §8 non mostra questa etichetta. Potrebbe essere un elemento UI
   separato non incluso nel testo dell'esempio — ma non è verificabile da questo documento.

4. **[BASSO] Giudizio di valore condizionale non intercettato — Esempio B.**
   La frase "Se quell'abbonamento ti dà un anno di valore, è un buon acquisto."
   introduce un frame di giudizio ("è un buon acquisto"), seppur condizionale. Non viola
   le parole proibite di AC-7 (["conviene", "dovresti", "è meglio", "ti consiglio",
   "devi"]) né la lista trapQuestions di guardrail.dart. È una zona grigia: la tabella
   §9.4 elenca "questo costo è alto" come non consentito, e un giudizio positivo
   condizionale è strutturalmente analogo. Non viene intercettato.

5. **[BASSO] Categoria "streaming" assente dall'apertura — Esempio B.**
   Alterazione minore: la categoria del BEFORE scompare dalla prima frase del AFTER.
   L'impatto è limitato perché il testo AFTER è contestuale (l'utente ha inserito
   l'uscita) e il riferimento "quell'abbonamento" è presente.

---

## Mitigazioni presenti

| rischio | mitigazione in vigore | copertura |
|---|---|---|
| Rischio 1 — omissione "ISC" | nessuna nel testo AFTER | **non coperto** |
| Rischio 2 — cambio contesto "10 anni" | nessuna nel testo AFTER | **non coperto** |
| Rischio 3 — baseline teorica non etichettata | AC-3 richiede l'etichetta in UI; guardrail.dart non interviene sui testi statici | **parzialmente coperto** se AC-3 è rispettato nell'implementazione UI; **non verificabile** dal solo testo del §8 |
| Rischio 4 — "è un buon acquisto" | forbidden list in guardrail.dart (righe 15–21) non intercetta questa frase; AC-7 non copre il pattern | **non coperto** dal guardrail automatico; affidato al giudizio del modello |
| Rischio 5 — categoria streaming assente | nessuna mitigazione formale; rischio basso per contesto | accettabile |

**Copertura di AC-5 e AC-7 verificata sui testi AFTER:**

Il testo di Esempio A non contiene nessuna delle parole proibite ("conviene",
"dovresti", "è meglio", "ti consiglio", "devi"). Il warning esplicito ("questo non ti
dice se il comparto è buono o cattivo, né se te ne devi andare") restituisce la
decisione all'utente. AC-5 e AC-7 risultano rispettati per Esempio A.

Il testo di Esempio B non contiene parole proibite dalla lista di guardrail.dart.
La frase "è un buon acquisto" (rischio 4) non è nella lista e non viene intercettata.
AC-5 risulta rispettato. AC-7 risulta formalmente rispettato per le parole monitorate;
il rischio residuo risiede in un pattern non incluso nella regexp.

---

## Giudizio complessivo

La semplificazione **preserva il significato operativo** — ogni numero è riproducibile
dai parametri dichiarati, nessuna soglia è modificata, nessuna condizione è invertita —
ma introduce due alterazioni che richiedono attenzione: l'omissione del termine "ISC"
contraddice un invariante dichiarato dalla spec (§9.2), e il cambio di contesto
semantico dell'orizzonte "10 anni" trasforma un attributo regolamentare della metrica
in un parametro di simulazione dell'utente, senza che il testo AFTER segnali la
differenza.

---

## Limite dichiarato

Il guardrail (guardrail.dart) intercetta la forma della richiesta, non la sostanza.
Una domanda obliqua può passare: `isTrapQuestion` confronta per sottostringa
case-insensitive sulle cinque fixture esatte; un'intenzione di consiglio espressa
con parole diverse non viene intercettata. Il giudizio del modello resta necessario,
e i due livelli — guardrail deterministico e layer linguistico — sono complementari,
non alternativi.

Il confronto elemento per elemento copre gli elementi che ho identificato nei testi
BEFORE come forniti nel §8 della spec. Se l'originale del documento periodico contiene
informazione implicita non inclusa nel BEFORE del §8 (ad esempio: nome del comparto,
ISIN, periodo di riferimento della comunicazione), quella informazione non è coperta
da questo confronto.

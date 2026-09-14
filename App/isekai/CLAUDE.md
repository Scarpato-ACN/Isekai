# Isekai — Mesi di Libertà

App mobile di educazione finanziaria. Hackathon Tema 02 · Inclusione Finanziaria · Salvatore Scarpato e Marco

**Fonte di verità**: `docs/Mesi_di_Liberta_Brief_Sviluppo_Agenti.md` (v3.0) — vince su tutto.

---

## Avvio app

```bash
flutter run                  # macOS/iOS/Android
flutter test                 # suite: 61/61 test
```

La app parte dalla `SplashScreen` (2.5 s) → `AppShell` con bottom nav 5 voci → schermata iniziale: Percorso.

---

## Struttura del progetto

```
lib/
  liberta_core.dart          engine deterministico — UNICA fonte dei numeri
  guardrail.dart             intercetta le 6 domande-trappola
  main.dart                  AppShell + NavigationBar 5 voci
  screens/
    splash_screen.dart       logo Isekai, 2.5 s poi → AppShell
    percorso_screen.dart     6 tappe sequenziali (home)
    simulator_screen.dart    slider + doppio effetto leva
    uscite_screen.dart       lista uscite + caccia alle invisibili
    progressi_screen.dart    grafico prospettico tratteggiato/continuo
    profilo_screen.dart      parametri utente — campo primario: risparmioMensile

assets/images/splash.png     immagine branding Isekai

docs/
  Mesi_di_Liberta_Brief_Sviluppo_Agenti.md   FONTE DI VERITA' v3
  scenario.md                7 AC verificabili (f-analyst)
  clarity/
    gulpease.md              Before/After misurato
    risk-clarity-note.md     3 trovate da f-clarity
  pipeline/stato.md          stato agenti e decisioni

test/
  liberta_core_test.dart     59 test unitari D1-D12
  widget_test.dart           2 test widget
```

---

## Regole non negoziabili (R1–R7)

Una violazione invalida il lavoro anche se l'app funziona.

| # | Regola |
|---|---|
| R1 | **Tutti i numeri mostrati all'utente provengono da `liberta_core`.** Nessun calcolo in UI. |
| R2 | **Zero nomi di prodotti finanziari.** Nessun campo, enum o stringa contiene nomi di banche, fondi, ETF, gestori. |
| R3 | **Il capitale è un importo senza collocazione.** L'app non chiede dove l'utente tiene i soldi. |
| R4 | **Nessun imperativo nel copy.** Vietate: "dovresti", "conviene", "ti consigliamo", "meglio", "scegli X", "ottimizza". |
| R5 | **Nessuna comparazione tra strumenti.** Nessuna funzione accetta due prodotti in input. |
| R6 | **Stime vs dati reali distinguibili.** Grafici: tratteggio per proiezioni, continuo per registrato. Testo: condizionale per proiezioni. |
| R7 | **Ogni ipotesi è visibile accanto al risultato**, non in nota, e modificabile dove previsto. |

Grep di verifica R4 — deve restituire zero occorrenze in UI/engine:
```bash
grep -rn "dovresti\|conviene\|ti consigliamo\|ottimizza" lib/
```

---

## Engine `liberta_core.dart` — firme e formule

```dart
double tassoRisparmio(double nettoMensile, double risparmioMensile)
// = risparmioMensile / nettoMensile

double speseMensili(double nettoMensile, double risparmioMensile)
// = nettoMensile - risparmioMensile

double capitaleObiettivo(double speseMensili, {double regolaPrelievo = 0.04})
// = speseMensili * 12 / regolaPrelievo  (con 0.04 → 25×)

double? mesiAllObiettivo(double capitaleIniziale, double risparmioMensile,
                         double crescitaAnnua, double obiettivo)
// iterazione mensile, cap 12000 → null se non converge

double costoCumulato(double capitale, double versamentoMensile,
                     double crescitaAnnua, double costoAnnuo, int anni)
// costoAnnuo è FRAZIONE (0.0145), non euro (174)
// = FV(crescita 0%) - FV(crescita - costoAnnuo)

ImpattoSpesa impattoSpesaRicorrente(double importoMensile, Profilo profilo)
// leva1 = importoMensile * 12
// leva2 = importoMensile * 12 / regolaPrelievo (25×, senza ipotesi di crescita)
// SEMPRE usa capitaleAccantonato dal profilo — MAI 0 (bug §4.6)

double giorniDiStipendio(double importoAnnuo, double nettoMensile)
// = importoAnnuo / (nettoMensile / 30)

double deltaMesi(double scenarioA, double scenarioB)
```

---

## Fixture obbligatori — profilo di riferimento

`netto 1800, risparmio 300, capitale 12000, crescita 0.04, regola 0.04`

| Grandezza | Valore atteso |
|---|---|
| `tassoRisparmio(1800, 300)` | 0.1667 |
| `speseMensili(1800, 300)` | 1500.0 |
| `capitaleObiettivo(18000)` | 450000.0 |
| `mesiAllObiettivo(12000, 300, 0.04, 450000)` | 501 |
| `impattoSpesaRicorrente(12).mesiGuadagnati` | **10** (non 12 — il 12 era il bug) |
| `impattoSpesaRicorrente(30).mesiGuadagnati` | 25 |
| `impattoSpesaRicorrente(50).mesiGuadagnati` | 41 |
| `impattoSpesaRicorrente(100).mesiGuadagnati` | 77 |
| `costoCumulato(12000, 200, 0.04, 0.0145, 10)` | 4554 |
| `giorniDiStipendio(144, 1800)` | 2.4 |

Tolleranza sui `mesiGuadagnati`: ±1 mese.

---

## Definition of Done (D1–D12)

| # | Criterio |
|---|---|
| D1 | `liberta_core` passa tutti i fixture sopra e i casi limite |
| D2 | Il simulatore legge `capitaleAccantonato` dal profilo (bug §4.6 non replicato) |
| D3 | Modificare un campo in Profilo aggiorna percorso, simulatore e progressi senza ricaricare |
| D4 | Con `risparmio = 0` l'app commuta in giorni di stipendio |
| D5 | Con `crescita = 0%` tutti i calcoli restano validi |
| D6 | Le 6 domande-trappola del guardrail sono tutte intercettate |
| D7 | Grep R4 zero occorrenze di parole vietate in UI e output engine |
| D8 | Grep zero nomi di prodotti o intermediari finanziari nel codebase |
| D9 | Nel grafico Progressi le serie proiettate sono tratteggiate e la legenda lo dichiara |
| D10 | Ogni sottotitolo delle 6 tappe contiene un dato reale calcolato dall'engine |
| D11 | Profilo non mostra l'età di arrivo; la tappa 6 chiude sullo scarto, non sull'assoluto |
| D12 | Nessun numero a schermo presenta artefatti float |

---

## Guardrail — 6 domande-trappola

Definite in `lib/guardrail.dart`. Tutte devono essere intercettate:

1. "conviene?"
2. "è caro?"
3. "cosa faresti tu al mio posto?"
4. "meglio a o b?"
5. "devo disdire?"
6. "dove dovrei investire questi 12.000 €?"

La risposta è sempre un reindirizzamento educativo, mai un disclaimer legale.

---

## Flèche — sistema agentico per l'orchestrazione

Hackathon Tema 02 · Inclusione Finanziaria · Salvatore Scarpato e Marco

## Installazione Flèche

**macOS e Linux (sistema Flèche)**
```bash
./install.sh
```

**Windows, in PowerShell**
```powershell
.\install.ps1
```

Lo script rileva l'interprete Python, scrive `hooks/hooks.json` con il nome
corretto per il sistema, e **verifica che gli hook funzionino davvero** — quattro
prove reali, non solo la presenza dei file.

Quest'ultimo passo non è una formalità. Su Windows `python3` di norma non
esiste: l'eseguibile è `python` o `py -3`. Un `hooks.json` che nomina
l'interprete sbagliato non produce alcun errore visibile — l'hook non parte,
l'azione passa, e il sistema **sembra** funzionare senza applicare nessun
controllo. È peggio di un errore, perché chi lo usa crede di avere protezioni
che non ci sono.

## Come si avvia

```
claude --plugin-dir <percorso-di-Fleche>
```

Poi, dentro la sessione, la verifica che conta:

```
Quale conto mi conviene aprire?
```

Deve comparire `FLÈCHE — RICHIESTA FUORI PERIMETRO EDUCATIVO`. Se la domanda
passa, gli hook non vengono eseguiti — e su una postazione gestita può essere
una restrizione di policy, non un problema di installazione.

Poi, nell'ordine:

```
1. invoca f-analyst   → docs/scenario.md con difficulty statement e criteri
2. invoca f-dev       → implementazione, ogni test cita il criterio
3. invoca f-clarity   → docs/clarity/risk-clarity-note.md
```

## I nove agenti, e perché non vanno invocati tutti

**Cinque ore per due persone sono dieci ore-persona.** La pipeline stessa
consuma tempo: il criterio di successo è «i tre deliverable esistono e la demo
funziona», non «tutti gli agenti hanno contribuito».

```
PERCORSO MINIMO — produce i tre deliverable
  f-analyst      → docs/scenario.md              deliverable 01
  f-dev          → src/, tests/                  la capability software
  f-readability  → docs/clarity/gulpease.md      deliverable 02, MISURATO
  f-clarity      → docs/clarity/risk-...md       deliverable 03

OPZIONALI, in ordine di valore
  f-test-design  → docs/acceptance.md      PRIMA di f-dev, non dopo
  f-tester       → esegue, riporta numeri
  f-critic       → review contro rubrica
  f-devil        → attacca la semplificazione

COORDINAMENTO
  f-orc          → docs/pipeline/stato.md
```

`f-test-design` è il primo opzionale da recuperare, e va invocato **prima** di
`f-dev`: la sua ragione d'essere è che i test siano progettati senza vedere
l'implementazione. Invocarlo dopo lo rende inutile.

## Ogni deliverable ha un proprietario e un verificatore

```
01 User Difficulty Statement    f-analyst           verificato da f-critic
02 Before/After Simplicity      f-readability       misurato con Gulpease
03 Risk & Clarity Note          f-clarity           attaccato da f-devil
```

È l'argomento più forte sull'architettura: non «abbiamo nove agenti» ma «ogni
requisito della challenge ha un agente che lo possiede e un altro che lo
verifica».

## Gli strumenti

```bash
python3 tools/gulpease.py docs/originale.txt docs/semplificato.txt
  → Gulpease 32.3 → 73.6, +41.3 punti, livello cambiato

python3 tools/coverage.py
  → quali criteri di accettazione hanno un test che li cita

python3 tools/budget.py
  → consumo di token per agente
```

Il primo è la capability che produce il deliverable 02 come **misura**: un
confronto affiancato è un'opinione, `Gulpease 32.3 → 73.6` è riproducibile da
chiunque con la stessa formula.

**Il limite di Gulpease, da dichiarare sempre:** misura la forma, non la
comprensibilità. Accorciare una frase omettendo una condizione **alza**
l'indice e **peggiora** il documento. Va letto insieme al confronto elemento
per elemento di `f-clarity` — le due misure sono complementari e nessuna basta.

## I confini di scrittura, e perché ciascuno



| agente | scrive in | e non altrove perché |
|--------|-----------|----------------------|
| f-analyst | `docs/` | se implementasse, specifica e codice convergerebbero e nessuno verificherebbe che il secondo soddisfi la prima |
| f-dev | `src/`, `lib/`, `tests/` | se scrivesse in docs/ potrebbe adattare la specifica al codice, che è la direzione sbagliata |
| f-clarity | `docs/clarity/` | valuta la semplificazione: se potesse modificarla, valuterebbe il proprio lavoro |

Il terzo vincolo è quello che conta. Un valutatore che può correggere ciò che
valuta segnala solo ciò che sa sistemare.

## Il guardrail sul divieto di consulenza

La challenge vieta raccomandazioni di investimento, consulenza personalizzata e
indicazioni su cosa comprare, vendere o scegliere.

Il divieto **non è nel prompt**: è in `hooks/guardrails.json`, cinque regole
deterministiche che bloccano la richiesta su `UserPromptSubmit` — prima che il
modello possa decidere. Ogni valutazione lascia un record in
`logs/enforcement/`.

La differenza è dimostrabile. Un'istruzione «non dare consigli finanziari» è
un'intenzione che nessuno può verificare a posteriori; un blocco con un record
nel log è un fatto. Il terzo deliverable chiede di documentare come l'ambiguità
è stata evitata: il log è la risposta.

**Il limite, dichiarato anche nella Risk Note:** i pattern intercettano la
forma della richiesta, non la sostanza. Una domanda obliqua può passare. Il
guardrail riduce la superficie, non la annulla — il giudizio del modello resta
necessario, e i due livelli sono complementari.

## Cosa il log dimostra

```bash
python3 -c "
import json, glob
for f in glob.glob('logs/enforcement/*.jsonl'):
    for l in open(f):
        r = json.loads(l)
        print(r['decision'], r.get('rule_id'), r.get('agent') or '')
"
```

I prompt non sono registrati in chiaro: solo lunghezza e hash. Possono
contenere dati finanziari personali, e un sistema che protegge l'utente e poi
ne archivia i dati nel proprio log protegge male.

I record `NO_MATCH` sui casi consentiti non sono ridondanti: distinguono «il
guardrail ha valutato e non ha trovato nulla» da «il guardrail non ha girato».
Senza quella distinzione la Risk Note non potrebbe affermare che il controllo
era attivo.

## Su quale macchina gira

Gli hook di Claude Code sono **bloccati dalle managed settings sulle
postazioni Accenture gestite**. Su quelle macchine Flèche carica i tre agenti
ma i guardrail e i confini di scrittura **non vengono applicati**.

Per la demo servono entrambe le cose: il sistema deve girare dove gli hook
sono eseguiti, altrimenti il log resta vuoto e il terzo deliverable perde la
sua evidenza.

## Cosa Flèche non ha, e perché

Deliberatamente assenti: runtime loop con budget e checkpoint, identità firmata
degli agenti, manifest di integrità dei propri componenti, confine di
esecuzione dei processi figli, suite di certificazione.

Ognuno di quei meccanismi esiste per una minaccia che si presenta in un sistema
che gira per ore, non presidiato, su progetti reali: un agente che consuma
budget indefinitamente, un subagente che si dichiara qualcun altro, un processo
che modifica il control plane che dovrebbe governarlo.

In cinque ore di hackathon, con due persone davanti allo schermo, nessuna di
quelle minacce si presenta. Includerle avrebbe prodotto un sistema che costa
tempo di sviluppo e non protegge da niente di reale — e un controllo che costa
senza proteggere viene disattivato, che è il modo peggiore di averlo.

Resta ciò che serve davvero quando più agenti scrivono nello stesso progetto:
**chi può scrivere dove**, e **cosa non si può chiedere**.

## Vincoli di progetto

```
autonomy_level: L2
environment: LOCAL

## Git policy
mode: ask
```

# Flèche — sistema agentico per l'educazione finanziaria di base

Hackathon Tema 02 · Inclusione Finanziaria · Salvatore Scarpato e Marco

## Installazione

**macOS e Linux**
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

L'orchestratore si invoca come comando:

```
/f-orc realizza lo scenario sul tema Inclusione Finanziaria
/f-orc stato
```

È una **skill** e non un agente, per una ragione funzionale: gira nel thread
principale, l'unico contesto che può dispatchare subagent via `Task`. Un
subagent non può dispatchare altri subagent.

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
  /f-orc         → docs/pipeline/stato.md   (skill, thread principale)
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

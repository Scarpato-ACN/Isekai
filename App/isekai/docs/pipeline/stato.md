# Stato pipeline — Mesi di Libertà (brief v4.1 — fonte di verità)

Scenario: capire il costo reale delle uscite ricorrenti e simularne l'impatto in mesi di libertà finanziaria.
Spec di riferimento: `docs/Mesi_di_Liberta_Specifica_Applicazione.md`
Piattaforma: Flutter (Dart) — progetto `isekai`

| passo | agente | esito | artefatto | token |
|-------|--------|-------|-----------|-------|
| 1 | f-analyst | fatto | docs/scenario.md — 7 AC | 20k |
| 2a | f-dev v1 | superato | lib/ — spec v1, valori fixture errati | 82k |
| 2b | f-dev v3 | fatto | lib/ completo brief v3 — 61/61 | 120k |
| 2c | splash | fatto | assets/images/splash.png + SplashScreen — 61/61 | 28k |
| 3 | f-readability | fatto | docs/clarity/gulpease.md — +11.7pt (A), +1.7pt (B) | 26k |
| 4 | f-clarity | fatto | docs/clarity/risk-clarity-note.md — 3 trovate | 30k |

## Criteri e copertura
AC-1 engine correttezza valori base
AC-2 doppio effetto spese fisse (due componenti visibili)
AC-3 etichetta "riferimento teorico" nella schermata risultato
AC-4 fallback risparmio ≤ 0 → giorni di stipendio
AC-5 guardrail: nessuna raccomandazione in uscita
AC-6 separazione engine/LLM: numeri solo dall'engine
AC-7 copy: assenza di imperativi

## Deliverable
01 ✓ docs/scenario.md
02 ✓ docs/clarity/gulpease.md
03 ✓ docs/clarity/risk-clarity-note.md

## In coda (dopo design RPG)
- copy uscite_screen: chiarire le definizioni di categoria — deciso dall'operatore 2026-09-14:
  · **Fisse** = spese con cadenza periodica fissa (affitto, luce, gas, abbonamenti)
  · **Variabili** = spese discrezionali (cene fuori, cinema, abbigliamento)
  · toccare solo label/subtitle/tooltip — nessuna logica engine

## In coda (in corso — design RPG) — f-dev v4.1-design
- design fantasy RPG da `docs/design/Percorso Fantasy.dc.html`:
  · dark theme: bg #0d1714, accent gold #f0b429, teal #43c3a3
  · font: Cinzel (titoli) + Nunito (corpo) via google_fonts
  · nodi sigilli animati: pulse gold (corrente), verde (completata), lock (bloccata)
  · bottom nav dark con bordo gold e tab attivo gold
  · mascot bob animation

## In coda precedente
- splash screen con `/Users/salvatore.scarpato/Downloads/ChatGPT Image Sep 14, 2026, 11_33_27 AM.png`
  branding Isekai: logo, tagline "Un viaggio oggi, una libertà domani.", tre feature icons

## Trovate aperte (f-clarity)
- [ALTA] ISC abbreviazione assente nel testo AFTER Esempio A — contradice §9.2
- [MEDIA] "in 10 anni" cambia contesto semantico (regolamentare → utente)
- [BASSA] "è un buon acquisto" — giudizio condizionale non intercettato da guardrail

## Decisioni prese e da chi
- **definizioni categorie uscite** — operatore 2026-09-14:
  · Fisse = periodicità fissa (affitto, luce, gas) — NON necessariamente grandi
  · Variabili = discrezionali (cene, cinema) — non ricorrenti o facoltative
- piattaforma Flutter confermata: progetto già scaffolded con SDK ^3.11.5
- scenario unico confermato dall'operatore: costi ricorrenti → mesi di libertà
- pipeline minima avviata: f-analyst → f-dev → f-readability → f-clarity
- aperture f-analyst risolte dall'operatore:
  · livello lessicale → parametro int 1–3 passato come argomento
  · soglia fallback → ≤ 0 stretta (1 €/mese usa unità standard)
  · domande-trappola → lista chiusa di 5 + regex semantica più ampia

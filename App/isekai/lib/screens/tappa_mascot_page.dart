import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isekai/liberta_core.dart' as engine;

// Palette dark-fantasy locale
const Color _bgBase      = Color(0xFF0D1714);
const Color _bgCard      = Color(0xFF19302A);
const Color _accentGold  = Color(0xFFF0B429);
const Color _textPrimary = Color(0xFFF6EFE0);
const Color _textMuted   = Color(0x9FF4EAD6);
const Color _borderGold  = Color(0x59F0B429);

/// TappaMascotPage — pagina piena della tappa, con mascot, spiegazione e
/// illustrazione del dato (§7.2 e §7.3 del brief).
///
/// Struttura in 6 blocchi fissi (§7.3):
///   1. Mascot + titolo
///   2. Cosa impari qui (max 2 frasi, 25 parole)
///   3. Perché riguarda te (almeno 1 numero dall'engine)
///   4. Illustrazione del dato
///   5. Cosa non ti dirò (max 1 frase)
///   6. Bottone primario
///
/// Barra inferiore nascosta (D14c). Bottone sempre visibile senza scroll.
/// La freccia indietro NON completa la tappa (D14d).
class TappaMascotPage extends StatefulWidget {
  const TappaMascotPage({
    super.key,
    required this.tappa,
    required this.profilo,
    required this.completata,
    required this.usciteRegistrate,
    required this.usciteTrovate,
    required this.onCompleta,
    required this.onInCorso,
    required this.onNavigateTo,
    required this.onCrescitaChanged,
  });

  final int tappa;
  final engine.Profilo profilo;
  final bool completata;
  final int usciteRegistrate;
  final int usciteTrovate;
  final VoidCallback onCompleta;
  final VoidCallback onInCorso;
  final void Function(int) onNavigateTo;
  final void Function(double) onCrescitaChanged;

  @override
  State<TappaMascotPage> createState() => _TappaMascotPageState();
}

class _TappaMascotPageState extends State<TappaMascotPage> {
  // Tappa 7: stato locale dello slider (scrive sul profilo globale via callback)
  late double _crescitaLocale;

  @override
  void initState() {
    super.initState();
    _crescitaLocale = widget.profilo.crescitaIpotizzata;
  }

  // ---------------------------------------------------------------------------
  // Calcoli dall'engine (R1 — nessun numero hardcoded)
  // ---------------------------------------------------------------------------

  double get _spese =>
      engine.speseMensili(widget.profilo.nettoMensile, widget.profilo.risparmioMensile);
  double get _tasso =>
      engine.tassoRisparmio(widget.profilo.nettoMensile, widget.profilo.risparmioMensile);
  double get _fondo =>
      engine.fondoEmergenzaTarget(_spese, mesiCopertura: widget.profilo.mesiCopertura);
  double get _copertura =>
      engine.coperturaMesi(widget.profilo.capitaleDisponibile, _spese);
  double get _capVersoObi =>
      engine.capitaleVersoObiettivo(widget.profilo.capitaleAccantonato, _fondo);
  double get _obiettivo =>
      engine.capitaleObiettivo(_spese * 12, regolaPrelievo: widget.profilo.regolaPrelievo);
  int? get _mesiBase =>
      engine.mesiAllObiettivo(_capVersoObi, widget.profilo.risparmioMensile,
          widget.profilo.crescitaIpotizzata, _obiettivo);
  double get _mesiGuadagnati {
    final imp = engine.impattoSpesaRicorrente(50, widget.profilo);
    return imp.mesiGuadagnati ?? 0;
  }

  // ISC placeholder (tappa 8): fixture educativo evidentemente fittizio
  static const double _iscFittizio = 0.0145;
  double get _costoAnno1 =>
      widget.profilo.capitaleAccantonato * _iscFittizio;

  // ---------------------------------------------------------------------------
  // Contenuto testuale delle 9 tappe (D10-D12, R8)
  // ---------------------------------------------------------------------------

  String get _titolo {
    const titoli = [
      'Fisse o variabili',
      'Il tuo tasso di risparmio',
      'Registra un mese',
      'Perché tre mesi',
      'I costi che non vedi',
      'Interesse composto',
      'Rischio e rendimento',
      'Il costo del capitale',
      'Il tuo orizzonte',
    ];
    return titoli[widget.tappa - 1];
  }

  String get _cosaImpari {
    final t = widget.tappa;
    if (t == 1) return 'Ogni uscita mensile appartiene a una categoria: fissa o variabile. '
        'Le fisse hanno cadenza periodica e importo prevedibile — affitto, bollette, abbonamenti. '
        'Le variabili dipendono dalle tue scelte di ogni giorno — cene fuori, cinema, acquisti occasionali. '
        'Sapere in quale categoria cade una spesa è il primo passo per capire quanto margine hai.';
    if (t == 2) return 'Il tasso di risparmio è la percentuale del reddito che non spendi. '
        'Si calcola dividendo ciò che accantoni ogni mese per il reddito netto. '
        'Un tasso più alto riduce i mesi necessari per raggiungere l\'indipendenza finanziaria. '
        'Non indica da solo se stai facendo bene — indica solo il tuo punto di partenza.';
    if (t == 3) return 'Registrare le spese serve a vedere dove va davvero il reddito, non dove pensi che vada. '
        'La memoria tende a ricordare le uscite grandi e dimenticare le piccole, ricorrenti. '
        'Un mese registrato basta per avere un\'immagine abbastanza fedele delle abitudini. '
        'Non serve la perfezione: anche una lista incompleta è più informativa di nessuna lista.';
    if (t == 4) return 'Il fondo di emergenza è una riserva di liquidità pensata per gli imprevisti. '
        'La sua funzione è permetterti di coprire una spesa inattesa — riparazione, spesa medica, mese di transizione — senza toccare il capitale investito o fare debiti. '
        'La soglia minima più usata in letteratura è tra tre e sei mesi di spese. '
        'Finché il fondo non è completo, il capitale disponibile serve prima a quello.';
    if (t == 5) return 'Alcuni costi vengono addebitati prima che il saldo arrivi a te — o in modo così frammentato che non li percepisci come uscite. '
        'Commissioni bancarie, costi di gestione di strumenti finanziari, rinnovi automatici: non compaiono nelle spese del mese perché vengono trattenuti alla fonte o distribuiti su tutto l\'anno. '
        'Per renderli visibili bisogna andarli a cercare, non aspettare che appaiano. '
        'L\'effetto sul capitale, sommato nel tempo, è spesso sorprendente.';
    if (t == 6) return 'L\'interesse composto si produce quando i rendimenti di un capitale vengono reinvestiti anziché prelevati. '
        'Il periodo successivo il rendimento matura non solo sul capitale iniziale, ma anche su ciò che ha già reso. '
        'Nel lungo periodo questo meccanismo produce una crescita esponenziale invece di lineare. '
        'La differenza tra le due curve — con e senza reinvestimento — è il contributo visibile dell\'interesse composto.';
    if (t == 7) return 'Un rendimento più alto significa una curva di crescita più ripida nel grafico, ma anche più incertezza sulla posizione effettiva in ogni anno futuro. '
        'La variabilità di un investimento e il suo rendimento atteso tendono a muoversi nella stessa direzione: non esistono rendimenti storicamente elevati senza periodi di forte calo. '
        'L\'ipotesi che inserisci qui è solo un parametro educativo — il valore reale dipende dallo strumento scelto, dal mercato e dall\'orizzonte temporale. '
        'Il grafico mostra l\'effetto del parametro, non una previsione.';
    if (t == 8) return 'Un costo percentuale annuo sul capitale si traduce in un importo che viene sottratto al rendimento ogni anno prima che tu veda il saldo. '
        'Spesso non appare come uscita esplicita, ma come differenza tra il rendimento lordo e quello netto. '
        'Percentuali che sembrano piccole — 1%, 1,5% — su orizzonti lunghi e capitali crescenti producono differenze significative. '
        'Conoscere il costo annuo del proprio capitale accantonato è parte del quadro.';
    return 'Il percorso non finisce qui: ogni modifica alle tue abitudini sposta la data di arrivo. '
        'L\'orizzonte che hai calcolato oggi è una proiezione basata sui parametri che hai inserito. '
        'Se il risparmio mensile cresce, o se una spesa fissa cade, la curva si aggiorna. '
        'Il confronto tra il punto di partenza e quello attuale misura il lavoro fatto finora.';
  }

  String get _percheRiguardaTe {
    final t = widget.tappa;
    final speseStr = _formatEuro(_spese);
    final tassoStr = '${(_tasso * 100).toStringAsFixed(1)}%';
    final rispStr = _formatEuro(widget.profilo.risparmioMensile);
    final fondoStr = _formatEuro(_fondo);
    final copStr = _copertura.isInfinite ? '∞' : _copertura.toStringAsFixed(1);
    final capStr = _formatEuro(_capVersoObi);
    final crescitaStr = '${(_crescitaLocale * 100).toStringAsFixed(1)}%';
    final capTotStr = _formatEuro(widget.profilo.capitaleAccantonato);
    final costoStr = _formatEuro(_costoAnno1);
    final mesiStr = _mesiGuadagnati.round().toString();

    if (t == 1) return 'Ogni mese hai spese per circa $speseStr. '
        'Una parte ha cadenza fissa — la puoi stimare in anticipo. '
        'L\'altra dipende dalle scelte: è lì che c\'è più margine di variazione. '
        'Vedere la proporzione ti dice dove si concentra la flessibilità del tuo bilancio.';
    if (t == 2) return 'Il tuo tasso di risparmio attuale è $tassoStr: ogni 100 € guadagnati, $rispStr rimangono. '
        'Questo valore si ricava direttamente dal profilo che hai inserito. '
        'Non dice se sei "a posto" — non esiste una soglia universale valida per tutti. '
        'Dice solo da dove parti nel calcolo del tuo orizzonte.';
    if (t == 3) return 'Hai registrato ${widget.usciteRegistrate} spese finora. Ne servono almeno 10 per passare. '
        'Non è un limite arbitrario: sotto una certa soglia la lista non è abbastanza rappresentativa del mese reale. '
        'Ogni spesa che aggiungi rende il quadro più fedele. '
        'Le categorie non contano — conta che ci siano.';
    if (t == 4) return 'Con spese di $speseStr al mese, tre mesi fanno $fondoStr. '
        'Oggi hai una copertura di $copStr mesi con il capitale dichiarato come disponibile subito. '
        'Se la copertura è sotto la soglia, il capitale va prima lì prima di poter correre verso l\'obiettivo. '
        'La funzione del fondo non è crescere — è stare fermo e fare da scudo.';
    if (t == 5) return 'Hai trovato ${widget.usciteTrovate} uscite invisibili su 7. '
        'Ognuna che spunti è un importo che prima non vedevi e che ora puoi quantificare. '
        'Non serve fare nulla adesso — serve solo sapere che esistono. '
        'Il passo successivo, se vuoi, è registrarle come uscite nel tab "Le tue uscite".';
    if (t == 6) return 'Con il tuo capitale di $capStr che cresce mese dopo mese, il tempo amplifica tutto. '
        'La linea tratteggiata mostra come lo stesso risparmio mensile produce due curve diverse: '
        'con reinvestimento dei rendimenti la traiettoria sale più ripida, senza rimane lineare. '
        'Più lungo è l\'orizzonte, più ampio è il divario tra le due curve.';
    if (t == 7) return 'La tua ipotesi attuale è $crescitaStr. Quella percentuale la hai inserita tu — non è una raccomandazione. '
        'Cambiarla aggiorna in tempo reale sia la curva qui che il calcolo dell\'orizzonte nel percorso. '
        'Prova a spostarla verso il basso: l\'orizzonte si allunga. Spostarla verso l\'alto lo accorcia — '
        'ma non significa che quel rendimento sia ottenibile o appropriato per te.';
    if (t == 8) return 'Il tuo capitale accantonato è $capTotStr. '
        'Un costo percentuale dell\'1,45% su quel valore corrisponde a $costoStr all\'anno, sottratti dal rendimento. '
        'Non è un\'uscita che vedi nel conto — è una differenza nel saldo finale. '
        'Conoscerlo ti permette di capire quanto del rendimento lordo rimane effettivamente a tuo favore.';
    return 'Dall\'attivazione di questa sessione hai compreso come si sposta l\'orizzonte cambiando le variabili. '
        'Il calcolo dell\'orizzonte mostrato è basato sui parametri attuali del tuo profilo. '
        'Ogni spesa ricorrente che riduci guadagna mesi: finora l\'effetto stimato è $mesiStr mesi. '
        'Il punto di arrivo è cambiato — anche se non hai ancora mosso un euro.';
  }

  String get _cosaNonTiDiro {
    final t = widget.tappa;
    if (t == 1) return 'Quali tagliare: quello lo sai tu.';
    if (t == 2) return 'Se è abbastanza o no: non lo so.';
    if (t == 3) return 'Come spenderle meglio: quello è tuo.';
    if (t == 4) return 'Dove tenerli: quello lo decidi tu.';
    if (t == 5) return 'Cosa cambiare: la scelta è tua.';
    if (t == 6) return 'Con quale strumento farlo crescere: non lo so e non te lo dico.';
    if (t == 7) return 'Quale prodotto rende di più: non lo so e non puoi saperlo.';
    if (t == 8) return 'Se il costo che stai pagando è alto o basso: non ho modo di saperlo.';
    return 'Quando smettere di lavorare, o se farlo mai: quello appartiene solo a te.';
  }

  String get _labelBottone {
    if (widget.completata) return 'Chiudi';
    if (widget.tappa == 3) return 'Vai a registrare le spese';
    if (widget.tappa == 5) return 'Vai a cercare i costi nascosti';
    return 'Ok, ho capito';
  }

  void _onBottonePressed() {
    if (widget.completata) {
      Navigator.of(context).pop(null);
      return;
    }
    if (widget.tappa == 3 || widget.tappa == 5) {
      widget.onInCorso();
      Navigator.of(context).pop(null);
      widget.onNavigateTo(2); // → Uscite
    } else {
      widget.onCompleta();
      Navigator.of(context).pop(true);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBase,
      appBar: AppBar(
        backgroundColor: const Color(0xFF122420),
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Tappa ${widget.tappa}',
          style: GoogleFonts.cinzel(
            color: _textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        leading: BackButton(
          color: _textPrimary,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0x38F0B429)),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.95),
            radius: 1.1,
            colors: [Color(0xFF1D3A33), Color(0xFF142822), Color(0xFF0B1512)],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Blocco 1: Mascot + titolo
                    Center(
                      child: ExcludeSemantics(
                        child: Image.asset(
                          'assets/images/mascot.png',
                          height: 120,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.emoji_nature_outlined,
                            size: 80,
                            color: _accentGold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _titolo,
                      style: GoogleFonts.cinzel(
                        color: _textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 26,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Blocco 2: Cosa impari qui
                    _Blocco(
                      etichetta: 'Cosa impari qui',
                      child: Text(_cosaImpari,
                          style: GoogleFonts.nunito(
                              color: _textPrimary, fontSize: 15)),
                    ),
                    const SizedBox(height: 16),

                    // Blocco 3: Perché riguarda te
                    _Blocco(
                      etichetta: 'Perché riguarda te',
                      child: Text(_percheRiguardaTe,
                          style: GoogleFonts.nunito(
                              color: _textPrimary, fontSize: 15)),
                    ),
                    const SizedBox(height: 16),

                    // Blocco 4: Illustrazione del dato
                    _Blocco(
                      etichetta: 'Illustrazione del dato',
                      child: _buildIllustrazione(context),
                    ),
                    const SizedBox(height: 16),

                    // Blocco 5: Cosa non ti dirò
                    _Blocco(
                      etichetta: 'Cosa non ti dirò',
                      child: Text(
                        _cosaNonTiDiro,
                        style: GoogleFonts.nunito(
                          color: _textMuted,
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Blocco 6: Bottone primario gold — fisso in fondo (D14c)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: GestureDetector(
                  onTap: _onBottonePressed,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD775), Color(0xFFE5A41C)],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x4DF0B429),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _labelBottone,
                        style: GoogleFonts.nunito(
                          color: const Color(0xFF17332C),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Illustrazioni del dato — §7.7
  // ---------------------------------------------------------------------------

  Widget _buildIllustrazione(BuildContext context) {
    switch (widget.tappa) {
      case 1:
        return _IllustrazioneT1(spese: _spese, profilo: widget.profilo);
      case 2:
        return _IllustrazioneT2(tasso: _tasso);
      case 3:
        return _IllustrazioneT3(registrate: widget.usciteRegistrate);
      case 4:
        return _IllustrazioneT4(
          copertura: _copertura,
          fondo: _fondo,
          mesiCopertura: widget.profilo.mesiCopertura,
        );
      case 5:
        return _IllustrazioneT5(trovate: widget.usciteTrovate);
      case 6:
        return _IllustrazioneT6(
          capitale: _capVersoObi,
          risparmio: widget.profilo.risparmioMensile,
          crescita: widget.profilo.crescitaIpotizzata,
        );
      case 7:
        return _IllustrazioneRischioRendimento(
          crescitaLocale: _crescitaLocale,
          onCrescitaChanged: (v) {
            setState(() => _crescitaLocale = v);
            widget.onCrescitaChanged(v);
          },
        );
      case 8:
        return _IllustrazioneT8(profilo: widget.profilo);
      case 9:
        return _IllustrazioneOrizzonte(profilo: widget.profilo);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ---------------------------------------------------------------------------
// Widget di supporto
// ---------------------------------------------------------------------------

class _Blocco extends StatelessWidget {
  const _Blocco({required this.etichetta, required this.child});

  final String etichetta;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderGold),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etichetta.toUpperCase(),
            style: GoogleFonts.nunito(
              color: _accentGold,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Illustrazioni individuali (§7.7)
// ---------------------------------------------------------------------------

/// T1 — barra divisa in due segmenti con effetto acqua (fisse) e fuoco (variabili)
class _IllustrazioneT1 extends StatelessWidget {
  const _IllustrazioneT1({required this.spese, required this.profilo});
  final double spese;
  final engine.Profilo profilo;

  @override
  Widget build(BuildContext context) {
    final fisse = spese * 0.6;
    final variabili = spese * 0.4;
    final totale = fisse + variabili;
    if (totale <= 0) return const SizedBox.shrink();
    final ratioF = fisse / totale;

    return Semantics(
      label: 'Spese fisse circa ${_formatEuro(fisse)}, variabili circa ${_formatEuro(variabili)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 52,
              child: CustomPaint(
                size: const Size(double.infinity, 52),
                painter: _AcquaFuocoPainter(ratioFisse: ratioF),
                child: Row(
                  children: [
                    Expanded(
                      flex: (ratioF * 100).round(),
                      child: Center(
                        child: Text(
                          _formatEuro(fisse),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            shadows: [Shadow(color: Color(0x99000000), blurRadius: 4)],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 100 - (ratioF * 100).round(),
                      child: Center(
                        child: Text(
                          _formatEuro(variabili),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            shadows: [Shadow(color: Color(0x99000000), blurRadius: 4)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _LegendaAcquaFuoco(tipo: 'acqua', etichetta: 'Fisse (stima 60%)'),
              _LegendaAcquaFuoco(tipo: 'fuoco', etichetta: 'Variabili (stima 40%)'),
            ],
          ),
        ],
      ),
    );
  }
}

/// CustomPainter che disegna il segmento acqua (sinistra) e fuoco (destra)
/// con gradiente e linea divisoria ondulata/seghettata.
class _AcquaFuocoPainter extends CustomPainter {
  const _AcquaFuocoPainter({required this.ratioFisse});
  final double ratioFisse;

  @override
  void paint(Canvas canvas, Size size) {
    final splitX = size.width * ratioFisse;

    // ── Segmento ACQUA (sinistra) ──────────────────────────────────────────
    final paintAcqua = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF7DD8F0),  // azzurro cielo
          Color(0xFF1A8FC0),  // blu mare
          Color(0xFF0B5F8A),  // blu profondo
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, splitX, size.height));

    // Path acqua: rettangolo sinistro con bordo destro ondulato
    final pathAcqua = Path();
    pathAcqua.moveTo(0, 0);
    pathAcqua.lineTo(splitX - 6, 0);
    // Onda verticale sul bordo destro (3 creste)
    final stepH = size.height / 3;
    pathAcqua.cubicTo(splitX + 4, stepH * 0.25, splitX - 10, stepH * 0.75, splitX - 2, stepH);
    pathAcqua.cubicTo(splitX + 6, stepH * 1.25, splitX - 8, stepH * 1.75, splitX - 2, stepH * 2);
    pathAcqua.cubicTo(splitX + 4, stepH * 2.25, splitX - 10, stepH * 2.75, splitX - 6, size.height);
    pathAcqua.lineTo(0, size.height);
    pathAcqua.close();
    canvas.drawPath(pathAcqua, paintAcqua);

    // Riflesso acqua: striscia orizzontale semi-trasparente
    final paintRiflesso = Paint()
      ..color = const Color(0x33FFFFFF)
      ..style = PaintingStyle.fill;
    final pathRiflesso = Path()
      ..moveTo(6, 10)
      ..lineTo(splitX - 12, 10)
      ..lineTo(splitX - 14, 18)
      ..lineTo(8, 18)
      ..close();
    canvas.drawPath(pathRiflesso, paintRiflesso);

    // ── Segmento FUOCO (destra) ────────────────────────────────────────────
    final paintFuoco = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Color(0xFFCC1500),  // rosso brace
          Color(0xFFFF4500),  // arancio fiamma
          Color(0xFFFF8C00),  // ambra
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(splitX, 0, size.width - splitX, size.height));

    // Path fuoco: bordo sinistro speculare all'onda, top con punte di fiamma
    final pathFuoco = Path();
    pathFuoco.moveTo(splitX - 6, size.height);
    pathFuoco.cubicTo(splitX + 4, stepH * 2.25, splitX - 8, stepH * 1.75, splitX - 2, stepH * 2);
    pathFuoco.cubicTo(splitX + 6, stepH * 1.25, splitX - 10, stepH * 0.75, splitX - 2, stepH);
    pathFuoco.cubicTo(splitX + 4, stepH * 0.25, splitX - 8, -stepH * 0.1, splitX - 6, 0);
    // Top con punte di fiamma
    final fw = size.width - splitX;
    pathFuoco.lineTo(splitX + fw * 0.15, 0);
    // Prima punta
    pathFuoco.cubicTo(splitX + fw * 0.22, -8, splitX + fw * 0.30, -4, splitX + fw * 0.38, 0);
    // Seconda punta
    pathFuoco.cubicTo(splitX + fw * 0.50, -12, splitX + fw * 0.60, -6, splitX + fw * 0.68, 0);
    // Terza punta
    pathFuoco.cubicTo(splitX + fw * 0.78, -7, splitX + fw * 0.88, -3, size.width, 0);
    pathFuoco.lineTo(size.width, size.height);
    pathFuoco.close();
    canvas.drawPath(pathFuoco, paintFuoco);

    // Brace incandescente: punto luminoso in basso al centro del segmento fuoco
    final centerX = splitX + fw * 0.5;
    final paintBrace = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFFFFE566), const Color(0x00FF4500)],
      ).createShader(Rect.fromCircle(
          center: Offset(centerX, size.height - 10), radius: 20));
    canvas.drawCircle(Offset(centerX, size.height - 10), 20, paintBrace);
  }

  @override
  bool shouldRepaint(_AcquaFuocoPainter old) => old.ratioFisse != ratioFisse;
}

class _LegendaAcquaFuoco extends StatelessWidget {
  const _LegendaAcquaFuoco({required this.tipo, required this.etichetta});
  final String tipo; // 'acqua' | 'fuoco'
  final String etichetta;

  @override
  Widget build(BuildContext context) {
    final isAcqua = tipo == 'acqua';
    final gradient = isAcqua
        ? const LinearGradient(colors: [Color(0xFF7DD8F0), Color(0xFF0B5F8A)])
        : const LinearGradient(colors: [Color(0xFFFF8C00), Color(0xFFCC1500)]);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            gradient: gradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: isAcqua
                    ? const Color(0x551A8FC0)
                    : const Color(0x55FF4500),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          etichetta,
          style: const TextStyle(
            color: Color(0x9FF4EAD6),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda({required this.colore, required this.etichetta});
  final Color colore;
  final String etichetta;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: colore, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(etichetta, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

/// T2 — anello fantasy: verde incantesimo (risparmio) + rosso scarlatto (speso)
class _IllustrazioneT2 extends StatelessWidget {
  const _IllustrazioneT2({required this.tasso});
  final double tasso;

  @override
  Widget build(BuildContext context) {
    final tassoStr = '${(tasso * 100).toStringAsFixed(1)}%';
    final spesoStr = '${((1 - tasso) * 100).toStringAsFixed(1)}%';

    return Semantics(
      label: 'Tasso di risparmio $tassoStr, speso $spesoStr',
      child: Column(
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: _RunaPainter(tasso: tasso.clamp(0.0, 1.0)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendaRuna(
                colore: const Color(0xFF34D399),
                glow: const Color(0x5534D399),
                etichetta: 'Risparmio $tassoStr',
              ),
              const SizedBox(width: 24),
              _LegendaRuna(
                colore: const Color(0xFFEF4444),
                glow: const Color(0x55EF4444),
                etichetta: 'Speso $spesoStr',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RunaPainter extends CustomPainter {
  const _RunaPainter({required this.tasso});
  final double tasso;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    const startAngle = -pi / 2; // 12 o'clock
    const fullSweep = 2 * pi;

    // ── Anello background (scuro) ──────────────────────────────────────────
    final bgPaint = Paint()
      ..color = const Color(0xFF0D1714)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26;
    canvas.drawCircle(center, radius, bgPaint);

    // ── Arco SPESO (rosso scarlatto) ──────────────────────────────────────
    final sweepSpeso = fullSweep * (1 - tasso);
    final startSpeso = startAngle + fullSweep * tasso;

    final paintSpeso = Paint()
      ..shader = SweepGradient(
        startAngle: startSpeso,
        endAngle: startSpeso + sweepSpeso,
        colors: const [Color(0xFFDC2626), Color(0xFFEF4444), Color(0xFFFF6B6B)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.butt;

    final glowSpeso = Paint()
      ..color = const Color(0x44EF4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 34
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    if (sweepSpeso > 0.01) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startSpeso, sweepSpeso, false, glowSpeso,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startSpeso, sweepSpeso, false, paintSpeso,
      );
    }

    // ── Arco RISPARMIO (verde incantesimo) ────────────────────────────────
    final sweepRisparmio = fullSweep * tasso;

    final paintRisparmio = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepRisparmio,
        colors: const [Color(0xFF059669), Color(0xFF34D399), Color(0xFF6EE7B7)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.butt;

    final glowRisparmio = Paint()
      ..color = const Color(0x5534D399)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 34
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    if (sweepRisparmio > 0.01) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle, sweepRisparmio, false, glowRisparmio,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle, sweepRisparmio, false, paintRisparmio,
      );
    }

    // ── Bordo runa: cerchio tratteggiato dorato esterno ───────────────────
    final runaPaint = Paint()
      ..color = const Color(0x66F0B429)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const runaRadius = 200 / 2 - 2.0;
    const segments = 36;
    for (int i = 0; i < segments; i++) {
      final a = (2 * pi / segments) * i;
      final aEnd = a + (2 * pi / segments) * 0.55;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: runaRadius),
        a, aEnd - a, false, runaPaint,
      );
    }

    // ── Centro: sfondo scuro + percentuale ────────────────────────────────
    final centerBg = Paint()..color = const Color(0xFF0D1714);
    canvas.drawCircle(center, radius - 14, centerBg);

    // Testo percentuale — disegnato via TextPainter
    final pct = (tasso * 100);
    final pctStr = pct < 10
        ? '${pct.toStringAsFixed(1)}%'
        : '${pct.toStringAsFixed(0)}%';

    final tp = TextPainter(
      text: TextSpan(
        text: pctStr,
        style: const TextStyle(
          color: Color(0xFFF0B429),
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2 + 10));

    final label = TextPainter(
      text: const TextSpan(
        text: 'risparmio',
        style: TextStyle(
          color: Color(0x9FF4EAD6),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, center - Offset(label.width / 2, -tp.height / 2 + 4));
  }

  @override
  bool shouldRepaint(_RunaPainter old) => old.tasso != tasso;
}

class _LegendaRuna extends StatelessWidget {
  const _LegendaRuna({
    required this.colore,
    required this.glow,
    required this.etichetta,
  });
  final Color colore;
  final Color glow;
  final String etichetta;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: colore,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: glow, blurRadius: 8)],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          etichetta,
          style: const TextStyle(
            color: Color(0x9FF4EAD6),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// T3 — riga di 10 cerchi, riempiti fino a usciteRegistrate
class _IllustrazioneT3 extends StatelessWidget {
  const _IllustrazioneT3({required this.registrate});
  final int registrate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final n = registrate.clamp(0, 10);

    return Semantics(
      label: '$n spese registrate su 10',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(10, (i) {
              final filled = i < n;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  filled ? Icons.circle : Icons.circle_outlined,
                  size: 22,
                  color: filled ? cs.primary : cs.outlineVariant,
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            '$n di 10',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// T4 — barra a segmenti mensili (max 8), soglia a mesiCopertura
class _IllustrazioneT4 extends StatelessWidget {
  const _IllustrazioneT4({
    required this.copertura,
    required this.fondo,
    required this.mesiCopertura,
  });
  final double copertura;
  final double fondo;
  final double mesiCopertura;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final copClamp = copertura.clamp(0.0, 8.0);
    final soglia = mesiCopertura.round().clamp(1, 8);
    final copStr = copertura.isInfinite ? '∞' : copertura.toStringAsFixed(1);

    return Semantics(
      label: 'Copertura $copStr mesi, soglia $soglia mesi',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Row(
                children: List.generate(8, (i) {
                  final filled = i < copClamp;
                  final isSoglia = i == soglia - 1;
                  return Expanded(
                    child: Container(
                      height: 36,
                      margin: const EdgeInsets.only(right: 3),
                      decoration: BoxDecoration(
                        color: filled ? cs.primary : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                        border: isSoglia
                            ? Border.all(color: cs.error, width: 2)
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Copertura attuale: $copStr mesi',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                'Soglia: $soglia mesi',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.error,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// T5 — 7 icone, riempite per usciteTrovate
class _IllustrazioneT5 extends StatelessWidget {
  const _IllustrazioneT5({required this.trovate});
  final int trovate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final n = trovate.clamp(0, 7);

    return Semantics(
      label: '$n uscite invisibili trovate su 7',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (i) {
              final found = i < n;
              return Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: found ? cs.primary : cs.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  found ? Icons.search : Icons.search_outlined,
                  size: 18,
                  color: found ? cs.onPrimary : cs.onSurfaceVariant,
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            '$n di 7 trovate',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// T6 — due curve: con e senza interesse composto, assi X (anni) e Y (capitale)
class _IllustrazioneT6 extends StatelessWidget {
  const _IllustrazioneT6({
    required this.capitale,
    required this.risparmio,
    required this.crescita,
  });
  final double capitale;
  final double risparmio;
  final double crescita;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final valoreFinalCon = _fvCalc(capitale, risparmio, crescita, 20);
    final valoreFinalSenza = _fvCalc(capitale, risparmio, 0, 20);
    final valoreFinalConStr = _formatEuro(valoreFinalCon);
    final valoreFinalSenzaStr = _formatEuro(valoreFinalSenza);

    return Semantics(
      label: 'Proiezione a 20 anni con interesse composto: $valoreFinalConStr, '
          'senza interesse composto: $valoreFinalSenzaStr',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Etichetta asse Y (in alto a sinistra)
          Text(
            'Capitale (€)',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withAlpha(140),
                ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: _DoppiaCurvaPainter(
                capitale: capitale,
                risparmio: risparmio,
                crescita: crescita,
                anni: 20,
                coloreCon: cs.primary,
                coloreSenza: cs.outlineVariant,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Etichetta asse X
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Oggi', style: Theme.of(context).textTheme.labelSmall),
              Text('5 anni', style: Theme.of(context).textTheme.labelSmall),
              Text('10 anni', style: Theme.of(context).textTheme.labelSmall),
              Text('15 anni', style: Theme.of(context).textTheme.labelSmall),
              Text('20 anni', style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 8),
          // Legenda
          Row(
            children: [
              _Legenda(colore: cs.primary, etichetta: 'Con interesse composto'),
              const SizedBox(width: 16),
              _Legenda(colore: cs.outlineVariant, etichetta: 'Senza (lineare)'),
            ],
          ),
        ],
      ),
    );
  }
}

/// T7 — slider vivo 0-6% con curva che si aggiorna (D14f, §3.1)
class _IllustrazioneT7 extends StatelessWidget {
  const _IllustrazioneT7({
    required this.crescitaIniziale,
    required this.capitale,
    required this.risparmio,
    required this.onCrescitaChanged,
  });
  final double crescitaIniziale;
  final double capitale;
  final double risparmio;
  final void Function(double) onCrescitaChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final crescitaStr = '${(crescitaIniziale * 100).toStringAsFixed(1)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Ipotesi di crescita', style: Theme.of(context).textTheme.labelSmall),
            Text(crescitaStr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: cs.primary,
                    )),
          ],
        ),
        Slider(
          value: crescitaIniziale * 100,
          min: 0,
          max: 6,
          divisions: 12,
          label: crescitaStr,
          onChanged: (v) => onCrescitaChanged(v / 100),
        ),
        Semantics(
          label: 'Proiezione con ipotesi $crescitaStr',
          child: SizedBox(
            height: 80,
            child: CustomPaint(
              size: const Size(double.infinity, 80),
              painter: _CurvaPainter(
                capitale: capitale,
                risparmio: risparmio,
                crescita: crescitaIniziale,
                anni: 20,
                colore: cs.primary,
              ),
            ),
          ),
        ),
        Text(
          'La percentuale la scegli tu — più alta porta più variabilità.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withAlpha(150),
              ),
        ),
      ],
    );
  }
}

/// T7 (Rischio e rendimento) — slider crescita + doppia curva tratteggiata (R6).
/// Curva A (oro): crescita composta con l'ipotesi corrente.
/// Curva B (grigio): lineare, senza alcun rendimento.
/// Valori educativi evidentemente fittizi: capitale 10 000 €, versamento 200 €/mese.
class _IllustrazioneRischioRendimento extends StatelessWidget {
  const _IllustrazioneRischioRendimento({
    required this.crescitaLocale,
    required this.onCrescitaChanged,
  });

  final double crescitaLocale;
  final void Function(double) onCrescitaChanged;

  // Valori educativi — evidentemente fittizi, non corrispondono al profilo
  static const double _capEdu  = 10000;
  static const double _versEdu = 200;
  static const int    _mesiEdu = 240; // 20 anni

  List<double> _valoriCon() {
    final rM = crescitaLocale / 12;
    final punti = <double>[];
    var cap = _capEdu;
    for (int i = 0; i < _mesiEdu; i++) {
      cap = rM == 0 ? cap + _versEdu : cap * (1 + rM) + _versEdu;
      punti.add(cap);
    }
    return punti;
  }

  List<double> _valoriSenza() =>
      List.generate(_mesiEdu, (i) => _capEdu + _versEdu * (i + 1));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final crescitaStr = '${(crescitaLocale * 100).toStringAsFixed(1)}%';

    // Y-axis labels — calcolati dagli stessi dati del painter
    final vCon   = _valoriCon();
    final vSenza = _valoriSenza();
    final maxVal = [vCon.reduce(max), vSenza.reduce(max)].reduce(max);
    final midVal = maxVal / 2;

    const greyColor = Color(0x99C8BEBA);

    return Semantics(
      label: 'Doppia curva: con rendimento $crescitaStr e senza, su 20 anni',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Slider ipotesi di crescita ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ipotesi di crescita',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: _textMuted)),
              Text(crescitaStr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _accentGold,
                        fontWeight: FontWeight.w700,
                      )),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _accentGold,
              thumbColor: _accentGold,
              inactiveTrackColor: const Color(0x33F0B429),
              overlayColor: const Color(0x22F0B429),
            ),
            child: Slider(
              value: crescitaLocale * 100,
              min: 0,
              max: 6,
              divisions: 12,
              label: crescitaStr,
              onChanged: (v) => onCrescitaChanged(v / 100),
            ),
          ),
          const SizedBox(height: 8),

          // ── Etichetta asse Y ───────────────────────────────────────────────
          Text(
            'Capitale (€)  —  valori educativi fittizi',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: _textMuted.withAlpha(140)),
          ),
          const SizedBox(height: 4),

          // ── Asse Y + CustomPaint ───────────────────────────────────────────
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Y ticks
                SizedBox(
                  width: 48,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_formatEuro(maxVal),
                          style: const TextStyle(
                              color: _textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w500)),
                      Text(_formatEuro(midVal),
                          style: const TextStyle(
                              color: _textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w500)),
                      Text('0 €',
                          style: const TextStyle(
                              color: _textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: CustomPaint(
                    painter: _RischioRendimentoPainter(crescita: crescitaLocale),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // ── Etichette asse X ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Oggi',    style: TextStyle(color: _textMuted, fontSize: 10)),
                Text('5 anni',  style: TextStyle(color: _textMuted, fontSize: 10)),
                Text('10 anni', style: TextStyle(color: _textMuted, fontSize: 10)),
                Text('15 anni', style: TextStyle(color: _textMuted, fontSize: 10)),
                Text('20 anni', style: TextStyle(color: _textMuted, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Legenda ────────────────────────────────────────────────────────
          Row(
            children: [
              _Legenda(colore: _accentGold, etichetta: 'Con rendimento'),
              const SizedBox(width: 16),
              _Legenda(colore: greyColor, etichetta: 'Senza rendimento'),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            'La percentuale la scegli tu — più alta porta più variabilità.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withAlpha(150),
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }
}

/// T8 — Due curve: capitale con e senza costi percentuali annui su 20 anni
///
/// Comunica un'unica cosa: quanto capitale in meno hai accumulato dopo 20 anni
/// a causa dei costi. Curva A (teal, continua) = senza costi; Curva B (rosso,
/// tratteggiata) = con costi all'1,45% annuo (es. fittizio, visibile in legenda).
/// L'area tra le due curve è la "perdita visiva". Tutti i dati dall'engine (R1).
class _IllustrazioneT8 extends StatelessWidget {
  const _IllustrazioneT8({required this.profilo});
  final engine.Profilo profilo;

  // Costo esempio fittizio — visibile nella legenda, non nascosto (R7).
  static const double _costoEsempio = 0.0145;

  // Curva A: crescita pura senza costi, punto per anno 0..20
  List<double> _buildCurvaA() {
    return List.generate(21, (anno) => _fvCalc(
      profilo.capitaleAccantonato,
      profilo.risparmioMensile,
      profilo.crescitaIpotizzata,
      anno,
    ));
  }

  // Curva B: curvaA - costoCumulato per ogni anno (engine, R1)
  List<double> _buildCurvaB(List<double> a) {
    return List.generate(21, (anno) {
      if (anno == 0) return a[0];
      final perso = engine.costoCumulato(
        profilo.capitaleAccantonato,
        profilo.risparmioMensile,
        profilo.crescitaIpotizzata,
        _costoEsempio,
        anno,
      );
      return a[anno] - perso;
    });
  }

  @override
  Widget build(BuildContext context) {
    final a = _buildCurvaA();
    final b = _buildCurvaB(a);
    final gap = a[20] - b[20];
    final gapStr = '- ${_formatEuro(gap)}';
    final pctStr = '${(_costoEsempio * 100).toStringAsFixed(2)}%';

    return Semantics(
      label: 'Capitale perso in 20 anni con costi $pctStr annuo: $gapStr',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Capitale perso in 20 anni',
              style: GoogleFonts.cinzel(
                color: _accentGold,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 240,
            child: CustomPaint(
              size: const Size(double.infinity, 240),
              painter: _CostoCapitalePainter(
                curvaA: a,
                curvaB: b,
                gap20Str: gapStr,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _LegendaT8(
                colore: Color(0xFF43C3A3),
                tratteggio: false,
                etichetta: 'Senza costi',
              ),
              SizedBox(width: 16),
              _LegendaT8(
                colore: Color(0xFFEF4444),
                tratteggio: true,
                etichetta: 'Con costi (es. 1,45%/anno)',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// CustomPainter per T8 — due curve con area di perdita riempita
class _CostoCapitalePainter extends CustomPainter {
  _CostoCapitalePainter({
    required this.curvaA,
    required this.curvaB,
    required this.gap20Str,
  });

  final List<double> curvaA;
  final List<double> curvaB;
  final String gap20Str;

  static const double _mT = 24.0; // margin top
  static const double _mB = 40.0; // margin bottom
  static const double _mL = 52.0; // margin left
  static const double _mR = 16.0; // margin right

  static const Color _teal  = Color(0xFF43C3A3);
  static const Color _rosso = Color(0xFFEF4444);
  static const Color _asse  = Color(0x66F4EAD6); // rgba(244,234,214,0.4)
  static const Color _area  = Color(0x26EF4444); // rgba(239,68,68,0.15)

  @override
  void paint(Canvas canvas, Size size) {
    final pL = _mL;
    final pT = _mT;
    final pR = size.width - _mR;
    final pB = size.height - _mB;
    final pW = pR - pL;
    final pH = pB - pT;

    final maxVal = curvaA.reduce(max);
    if (maxVal <= 0) return;

    double xOf(int i)    => pL + (i / 20.0) * pW;
    double yOf(double v) => pB - (v / maxVal) * pH;

    // 1 — Area riempita tra le due curve (perdita visiva)
    final areaPath = Path();
    areaPath.moveTo(xOf(0), yOf(curvaA[0]));
    for (int i = 1; i <= 20; i++) {
      areaPath.lineTo(xOf(i), yOf(curvaA[i]));
    }
    for (int i = 20; i >= 0; i--) {
      areaPath.lineTo(xOf(i), yOf(curvaB[i]));
    }
    areaPath.close();
    canvas.drawPath(areaPath, Paint()..color = _area);

    // 2 — Assi
    final axisPaint = Paint()
      ..color = _asse
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(pL, pT), Offset(pL, pB), axisPaint);
    canvas.drawLine(Offset(pL, pB), Offset(pR, pB), axisPaint);

    // Tick e label asse Y (0, metà, max)
    final yTicks = [0.0, maxVal / 2, maxVal];
    for (final v in yTicks) {
      final y = yOf(v);
      canvas.drawLine(Offset(pL - 4, y), Offset(pL, y), axisPaint);
      _lbl(canvas, _formatK(v), Offset(0, y - 6), _mL - 8, TextAlign.right);
    }

    // Tick e label asse X (0, 5, 10, 15, 20 anni)
    for (final yr in [0, 5, 10, 15, 20]) {
      final x = xOf(yr);
      canvas.drawLine(Offset(x, pB), Offset(x, pB + 4), axisPaint);
      _lbl(canvas, '${yr}a', Offset(x - 12, pB + 6), 24, TextAlign.center);
    }

    // Label "€" (etichetta asse Y)
    _lbl(canvas, '€', Offset(pL - 16, pT - 14), 16, TextAlign.center);

    // 3 — Curva A: teal, linea continua (R6: dati della proiezione base)
    final pathA = _linePath(xOf, yOf, curvaA);
    canvas.drawPath(pathA, Paint()
      ..color = _teal
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);

    // 4 — Curva B: rosso, tratteggiata (R6: proiezione scenario con costi)
    final pathB = _linePath(xOf, yOf, curvaB);
    _dashed(canvas, pathB, _rosso, 2.0);

    // 5 — Etichetta differenza a 20 anni (mostrata solo se il gap è leggibile)
    final yA20 = yOf(curvaA[20]);
    final yB20 = yOf(curvaB[20]);
    if ((yB20 - yA20).abs() > 12) {
      final yMid = (yA20 + yB20) / 2.0;
      final boxW = _mL - 8;
      _lbl(canvas, gap20Str, Offset(xOf(20) - boxW, yMid - 6),
          boxW, TextAlign.right, color: _rosso);
    }
  }

  Path _linePath(double Function(int) xOf, double Function(double) yOf,
      List<double> vals) {
    final path = Path();
    for (int i = 0; i < vals.length; i++) {
      if (i == 0) {
        path.moveTo(xOf(i), yOf(vals[i]));
      } else {
        path.lineTo(xOf(i), yOf(vals[i]));
      }
    }
    return path;
  }

  void _dashed(Canvas canvas, Path path, Color color, double width) {
    const dl = 6.0;
    const gl = 3.0;
    final p = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final m in path.computeMetrics()) {
      double d = 0;
      bool draw = true;
      while (d < m.length) {
        final e = (d + (draw ? dl : gl)).clamp(0.0, m.length);
        if (draw) canvas.drawPath(m.extractPath(d, e), p);
        d = e;
        draw = !draw;
      }
    }
  }

  void _lbl(Canvas canvas, String text, Offset offset, double maxW,
      TextAlign align, {Color color = _asse}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout(maxWidth: maxW);
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_CostoCapitalePainter old) =>
      old.curvaA.last != curvaA.last || old.gap20Str != gap20Str;
}

/// Voce di legenda per T8: linea (continua o tratteggiata) + etichetta testo
class _LegendaT8 extends StatelessWidget {
  const _LegendaT8({
    required this.colore,
    required this.tratteggio,
    required this.etichetta,
  });
  final Color colore;
  final bool tratteggio;
  final String etichetta;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          height: 12,
          child: CustomPaint(
            painter: _LegendaLinePainter(colore: colore, tratteggio: tratteggio),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          etichetta,
          style: const TextStyle(
            color: _textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LegendaLinePainter extends CustomPainter {
  const _LegendaLinePainter({required this.colore, required this.tratteggio});
  final Color colore;
  final bool tratteggio;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final paint = Paint()
      ..color = colore
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (!tratteggio) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    } else {
      double x = 0;
      bool draw = true;
      while (x < size.width) {
        final end = (x + (draw ? 4.0 : 2.0)).clamp(0.0, size.width);
        if (draw) canvas.drawLine(Offset(x, y), Offset(end, y), paint);
        x = end;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(_LegendaLinePainter old) =>
      old.colore != colore || old.tratteggio != tratteggio;
}

/// T9 — "Il tuo orizzonte": grafico con due curve basate sul profilo reale.
///
/// Curva A (oro #F0B429, continua 2.5pt): capitale accumulato mese per mese
///   partendo da [profilo.capitaleAccantonato], con crescita e versamento mensile.
/// Curva B (teal #43C3A3, tratteggiata 2pt): obiettivo FIRE (linea orizzontale).
///
/// Tutti i valori numerici provengono dall'engine (R1).
/// L'ipotesi di crescita è visibile accanto al grafico (R7).
/// Le linee proiettate sono tratteggiate (curva B) o continue/proiettate (curva A) (R6).
class _IllustrazioneOrizzonte extends StatelessWidget {
  const _IllustrazioneOrizzonte({required this.profilo});
  final engine.Profilo profilo;

  static const Color _teal = Color(0xFF43C3A3);

  @override
  Widget build(BuildContext context) {
    // Calcoli dall'engine — R1
    final spese = engine.speseMensili(
      profilo.nettoMensile,
      profilo.risparmioMensile,
    );
    final obiettivo = engine.capitaleObiettivo(
      spese * 12,
      regolaPrelievo: profilo.regolaPrelievo,
    );
    final mesiTotali = engine.mesiAllObiettivo(
          profilo.capitaleAccantonato,
          profilo.risparmioMensile,
          profilo.crescitaIpotizzata,
          obiettivo,
        ) ??
        480;

    // Curva A: iterazione mensile — stesso algoritmo dell'engine (R1)
    final curvaA = <double>[];
    var cap = profilo.capitaleAccantonato;
    final rM = profilo.crescitaIpotizzata / 12;
    for (int m = 0; m <= mesiTotali; m++) {
      curvaA.add(cap);
      cap = rM == 0
          ? cap + profilo.risparmioMensile
          : cap * (1 + rM) + profilo.risparmioMensile;
    }

    final anniTotali = (mesiTotali / 12).round();
    final crescitaStr =
        '${(profilo.crescitaIpotizzata * 100).toStringAsFixed(1)}%';
    final obiettivoStr = _formatK(obiettivo);

    return Semantics(
      label:
          'Grafico percorso FIRE: orizzonte $anniTotali anni, obiettivo $obiettivoStr',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ipotesi visibile accanto al grafico (R7)
          Text(
            'Ipotesi crescita: $crescitaStr  ·  Obiettivo: $obiettivoStr',
            style: const TextStyle(
              color: _textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Etichetta asse Y
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '€',
                  style: TextStyle(color: _textMuted, fontSize: 10),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: SizedBox(
                  height: 200,
                  child: CustomPaint(
                    size: const Size(double.infinity, 200),
                    painter: _OrizzontePainter(
                      curvaA: curvaA,
                      obiettivo: obiettivo,
                      mesiTotali: mesiTotali,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Etichette asse X
          Padding(
            padding: const EdgeInsets.only(left: 52, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _buildXLabels(mesiTotali),
            ),
          ),
          const SizedBox(height: 8),
          // Legenda (R6)
          Row(
            children: const [
              _LegendaT8(
                colore: _accentGold,
                tratteggio: false,
                etichetta: 'Capitale accumulato',
              ),
              SizedBox(width: 16),
              _LegendaT8(
                colore: _teal,
                tratteggio: true,
                etichetta: 'Obiettivo FIRE',
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Annotazione — fuori dal painter (R6, R7)
          Text(
            anniTotali > 0
                ? 'Orizzonte stimato: $anniTotali anni — con i dati che hai inserito.'
                : 'Orizzonte non calcolabile con i dati attuali.',
            style: const TextStyle(
              color: _textMuted,
              fontSize: 12,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildXLabels(int mesiTotali) {
    return List.generate(5, (i) {
      if (i == 0) {
        return const Text(
          'Oggi',
          style: TextStyle(color: _textMuted, fontSize: 10),
        );
      }
      if (i == 4) {
        return const Text(
          '✦ FIRE',
          style: TextStyle(
            color: _accentGold,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        );
      }
      final mesi = (mesiTotali * i / 4.0).round();
      final anni = mesi ~/ 12;
      return Text(
        '${anni}a',
        style: const TextStyle(color: _textMuted, fontSize: 10),
      );
    });
  }
}

/// CustomPainter per _IllustrazioneOrizzonte.
///
/// Disegna:
///   - Curva A (oro, continua 2.5pt): vettore curvaA mese per mese
///   - Curva B (teal, tratteggiata 2pt): linea orizzontale all'obiettivo FIRE
///   - Punto di incontro: cerchio dorato raggio 6 + linea verticale tratteggiata
///   - Assi Y (0, metà, obiettivo) e X (tick a 0%, 25%, 50%, 75%, 100%)
///
/// Tutti i valori (curvaA, obiettivo, mesiTotali) sono calcolati dal widget
/// tramite l'engine (R1). Il painter non calcola nulla autonomamente.
class _OrizzontePainter extends CustomPainter {
  const _OrizzontePainter({
    required this.curvaA,
    required this.obiettivo,
    required this.mesiTotali,
  });

  final List<double> curvaA;
  final double obiettivo;
  final int mesiTotali;

  static const double _mT = 16.0;
  static const double _mB = 8.0;
  static const double _mL = 48.0;
  static const double _mR = 16.0;

  static const Color _oro  = Color(0xFFF0B429);
  static const Color _teal = Color(0xFF43C3A3);
  static const Color _asse = Color(0x66F4EAD6);

  @override
  void paint(Canvas canvas, Size size) {
    final pL = _mL;
    final pT = _mT;
    final pR = size.width - _mR;
    final pB = size.height - _mB;
    final pW = pR - pL;
    final pH = pB - pT;

    final yMax = obiettivo * 1.1;
    if (yMax <= 0 || mesiTotali <= 0 || curvaA.isEmpty) return;

    double xOf(int m) => pL + (m / mesiTotali.toDouble()) * pW;
    double yOf(double v) => pB - (v / yMax) * pH;

    // 1 — Assi
    final axisPaint = Paint()
      ..color = _asse
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(pL, pT), Offset(pL, pB), axisPaint);
    canvas.drawLine(Offset(pL, pB), Offset(pR, pB), axisPaint);

    // 2 — Tick e label asse Y (0, metà, obiettivo)
    for (final v in [0.0, obiettivo / 2, obiettivo]) {
      final y = yOf(v);
      canvas.drawLine(Offset(pL - 4, y), Offset(pL, y), axisPaint);
      _lbl(canvas, _formatK(v), Offset(0, y - 6), pL - 6, TextAlign.right);
    }

    // 3 — Tick asse X a 0%, 25%, 50%, 75%, 100%
    for (int i = 0; i <= 4; i++) {
      final x = pL + (i / 4.0) * pW;
      canvas.drawLine(Offset(x, pB), Offset(x, pB + 4), axisPaint);
    }

    // 4 — Linea guida orizzontale leggera all'obiettivo
    canvas.drawLine(
      Offset(pL, yOf(obiettivo)),
      Offset(pR, yOf(obiettivo)),
      Paint()
        ..color = const Color(0x22F4EAD6)
        ..strokeWidth = 0.5,
    );

    // 5 — Curva B: teal, tratteggiata (obiettivo FIRE — proiezione di riferimento)
    final yObj = yOf(obiettivo);
    _dashed(
      canvas,
      Path()
        ..moveTo(pL, yObj)
        ..lineTo(pR, yObj),
      _teal,
      2.0,
    );

    // 6 — Curva A: oro, continua (capitale accumulato — proiettato dal punto reale)
    final pathA = Path();
    final n = curvaA.length.clamp(0, mesiTotali + 1);
    for (int m = 0; m < n; m++) {
      final x = xOf(m);
      final y = yOf(curvaA[m]);
      if (m == 0) {
        pathA.moveTo(x, y);
      } else {
        pathA.lineTo(x, y);
      }
    }
    canvas.drawPath(
      pathA,
      Paint()
        ..color = _oro
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // 7 — Punto di incontro: primo mese in cui curvaA raggiunge obiettivo
    int? mesiIncontro;
    for (int m = 1; m < n; m++) {
      if (curvaA[m] >= obiettivo) {
        mesiIncontro = m;
        break;
      }
    }

    if (mesiIncontro != null) {
      final xInc = xOf(mesiIncontro);
      final yInc = yOf(curvaA[mesiIncontro]);

      // Linea verticale tratteggiata dal punto di incontro all'asse X
      _dashed(
        canvas,
        Path()
          ..moveTo(xInc, yInc)
          ..lineTo(xInc, pB),
        _oro.withAlpha(120),
        1.5,
      );

      // Cerchio dorato pieno
      canvas.drawCircle(
        Offset(xInc, yInc),
        6,
        Paint()
          ..color = _oro
          ..style = PaintingStyle.fill,
      );
      // Alone bianco sottile
      canvas.drawCircle(
        Offset(xInc, yInc),
        6,
        Paint()
          ..color = const Color(0x55FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  void _dashed(Canvas canvas, Path path, Color color, double width) {
    const dl = 6.0;
    const gl = 3.0;
    final p = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final m in path.computeMetrics()) {
      double d = 0;
      bool draw = true;
      while (d < m.length) {
        final e = (d + (draw ? dl : gl)).clamp(0.0, m.length);
        if (draw) canvas.drawPath(m.extractPath(d, e), p);
        d = e;
        draw = !draw;
      }
    }
  }

  void _lbl(Canvas canvas, String text, Offset offset, double maxW,
      TextAlign align, {Color color = _asse}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout(maxWidth: maxW);
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_OrizzontePainter old) =>
      old.obiettivo != obiettivo || old.mesiTotali != mesiTotali;
}

/// T9 (vecchio) — due barre verticali: baseline e attuale, delta etichettato
/// Mantenuto per compatibilità — non più usato nella tappa 9.
class _IllustrazioneT9 extends StatelessWidget {
  const _IllustrazioneT9({
    required this.mesiBase,
    required this.mesiGuadagnati,
  });
  final int mesiBase;
  final int mesiGuadagnati;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mesiAttuali = (mesiBase - mesiGuadagnati).clamp(0, mesiBase);
    final maxMesi = mesiBase > 0 ? mesiBase : 1;

    return Semantics(
      label:
          'Baseline $mesiBase mesi, attuale $mesiAttuali mesi, hai guadagnato $mesiGuadagnati mesi',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _BarraVerticale(
                altezzaFrazione: 1.0,
                colore: cs.surfaceContainerHighest,
                etichetta: '${(mesiBase / 12).toStringAsFixed(1)} anni\n(senza tagli)',
                context: context,
              ),
              const SizedBox(width: 24),
              _BarraVerticale(
                altezzaFrazione:
                    mesiBase > 0 ? mesiAttuali / maxMesi : 0.5,
                colore: cs.primary,
                etichetta: '${(mesiAttuali / 12).toStringAsFixed(1)} anni\n(con tagli)',
                context: context,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Delta: −$mesiGuadagnati mesi guadagnati',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                ),
          ),
        ],
      ),
    );
  }
}

class _BarraVerticale extends StatelessWidget {
  const _BarraVerticale({
    required this.altezzaFrazione,
    required this.colore,
    required this.etichetta,
    required this.context,
  });
  final double altezzaFrazione;
  final Color colore;
  final String etichetta;
  final BuildContext context;

  @override
  Widget build(BuildContext ctx) {
    final maxH = 80.0;
    final h = (altezzaFrazione * maxH).clamp(8.0, maxH);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: h,
          decoration: BoxDecoration(
            color: colore,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          etichetta,
          textAlign: TextAlign.center,
          style: Theme.of(ctx).textTheme.labelSmall,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// CustomPainter per le curve (tappe 6 e 7) — tratteggiate (R6)
// ---------------------------------------------------------------------------

/// Disegna due curve tratteggiate: una con crescita composta, una senza (R6).
class _DoppiaCurvaPainter extends CustomPainter {
  const _DoppiaCurvaPainter({
    required this.capitale,
    required this.risparmio,
    required this.crescita,
    required this.anni,
    required this.coloreCon,
    required this.coloreSenza,
  });

  final double capitale;
  final double risparmio;
  final double crescita;
  final int anni;
  final Color coloreCon;
  final Color coloreSenza;

  List<double> _calcola(double r) {
    final mesi = anni * 12;
    final valori = <double>[];
    double saldo = capitale;
    final rM = r / 12;
    for (int m = 0; m <= mesi; m++) {
      valori.add(saldo);
      if (rM == 0) {
        saldo += risparmio;
      } else {
        saldo = saldo * (1 + rM) + risparmio;
      }
    }
    return valori;
  }

  void _disegnaCurva(Canvas canvas, Size size, List<double> valori,
      double maxVal, Color colore) {
    final paint = Paint()
      ..color = colore
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final mesi = valori.length - 1;
    final path = Path();
    for (int m = 0; m <= mesi; m++) {
      final x = size.width * m / mesi;
      final y = size.height * (1 - valori[m] / maxVal);
      if (m == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    const dashLen = 8.0;
    const gapLen = 4.0;
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double dist = 0;
      bool draw = true;
      while (dist < metric.length) {
        final end =
            (dist + (draw ? dashLen : gapLen)).clamp(0.0, metric.length);
        if (draw) canvas.drawPath(metric.extractPath(dist, end), paint);
        dist = end;
        draw = !draw;
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final valoriCon = _calcola(crescita);
    final valoriSenza = _calcola(0);
    final maxVal = [
      valoriCon.reduce(max),
      valoriSenza.reduce(max),
    ].reduce(max);
    if (maxVal <= 0) return;

    _disegnaCurva(canvas, size, valoriSenza, maxVal, coloreSenza);
    _disegnaCurva(canvas, size, valoriCon, maxVal, coloreCon);
  }

  @override
  bool shouldRepaint(_DoppiaCurvaPainter old) =>
      old.capitale != capitale ||
      old.risparmio != risparmio ||
      old.crescita != crescita;
}

class _CurvaPainter extends CustomPainter {
  const _CurvaPainter({
    required this.capitale,
    required this.risparmio,
    required this.crescita,
    required this.anni,
    required this.colore,
  });

  final double capitale;
  final double risparmio;
  final double crescita;
  final int anni;
  final Color colore;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colore
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Tratteggio per le proiezioni (R6)
    paint.strokeCap = StrokeCap.round;

    final mesi = anni * 12;
    final valori = <double>[];
    double saldo = capitale;
    final r = crescita / 12;
    for (int m = 0; m <= mesi; m++) {
      valori.add(saldo);
      if (r == 0) {
        saldo += risparmio;
      } else {
        saldo = saldo * (1 + r) + risparmio;
      }
    }

    final maxVal = valori.reduce(max);
    if (maxVal <= 0) return;

    final path = Path();
    for (int m = 0; m <= mesi; m++) {
      final x = size.width * m / mesi;
      final y = size.height * (1 - valori[m] / maxVal);
      if (m == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Simula tratteggio con segmenti alternati
    const dashLen = 8.0;
    const gapLen = 4.0;
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double dist = 0;
      bool draw = true;
      while (dist < metric.length) {
        final end = (dist + (draw ? dashLen : gapLen)).clamp(0.0, metric.length);
        if (draw) {
          final segment = metric.extractPath(dist, end);
          canvas.drawPath(segment, paint);
        }
        dist = end;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(_CurvaPainter old) =>
      old.capitale != capitale ||
      old.risparmio != risparmio ||
      old.crescita != crescita;
}

/// Painter per la doppia curva rischio/rendimento (R6 — entrambe tratteggiate).
/// Valori educativi fittizi: capitale 10 000 €, versamento mensile 200 €.
/// Usa lo stesso algoritmo dell'engine (r / 12 mensile, iterazione mese per mese).
class _RischioRendimentoPainter extends CustomPainter {
  const _RischioRendimentoPainter({required this.crescita});
  final double crescita;

  // Costanti educative — identiche a quelle del widget
  static const double _capEdu  = 10000;
  static const double _versEdu = 200;
  static const int    _mesi    = 240;

  List<double> _calcola(double r) {
    final rM = r / 12;
    final valori = <double>[];
    var cap = _capEdu;
    for (int m = 0; m < _mesi; m++) {
      cap = rM == 0 ? cap + _versEdu : cap * (1 + rM) + _versEdu;
      valori.add(cap);
    }
    return valori;
  }

  void _disegnaCurva(Canvas canvas, Size size, List<double> valori,
      double maxVal, Color colore) {
    final paint = Paint()
      ..color = colore
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final n = valori.length;
    final path = Path();
    for (int m = 0; m < n; m++) {
      final x = size.width * m / (n - 1);
      final y = size.height * (1 - valori[m] / maxVal);
      if (m == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Tratteggio — proiezioni (R6)
    const dashLen = 8.0;
    const gapLen  = 4.0;
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      bool draw = true;
      while (dist < metric.length) {
        final end = (dist + (draw ? dashLen : gapLen)).clamp(0.0, metric.length);
        if (draw) canvas.drawPath(metric.extractPath(dist, end), paint);
        dist = end;
        draw = !draw;
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final valoriCon   = _calcola(crescita);
    final valoriSenza = _calcola(0);
    final maxVal = [valoriCon.reduce(max), valoriSenza.reduce(max)].reduce(max);
    if (maxVal <= 0) return;

    // Linee guida orizzontali (basso, metà, alto)
    final gridPaint = Paint()
      ..color = const Color(0x22F0B429)
      ..strokeWidth = 0.5;
    for (final frac in [0.0, 0.5, 1.0]) {
      final y = size.height * (1 - frac);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Curva senza rendimento (grigio, disegnata prima — sotto)
    _disegnaCurva(canvas, size, valoriSenza, maxVal, const Color(0x99C8BEBA));
    // Curva con rendimento (oro, sopra)
    _disegnaCurva(canvas, size, valoriCon,   maxVal, const Color(0xFFF0B429));
  }

  @override
  bool shouldRepaint(_RischioRendimentoPainter old) => old.crescita != crescita;
}

// ---------------------------------------------------------------------------
// Utility
// ---------------------------------------------------------------------------

double _fvCalc(double pv, double pmt, double r, int anni) {
  final n = anni * 12;
  final rM = r / 12;
  if (rM == 0) return pv + pmt * n;
  final growth = pow(1 + rM, n).toDouble();
  return pv * growth + pmt * (growth - 1) / rM;
}

/// Formattazione compatta per le label degli assi (es. 45000 → "45K")
String _formatK(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).round()}K';
  return v.round().toString();
}

String _formatEuro(double valore) {
  if (valore.isInfinite) return '∞';
  if (valore >= 1000000) return '${(valore / 1000000).toStringAsFixed(2)} M€';
  if (valore >= 1000) return '${(valore / 1000).toStringAsFixed(1)} k€';
  return '${valore.toStringAsFixed(0)} €';
}

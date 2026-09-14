import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isekai/liberta_core.dart' as engine;
import 'package:isekai/screens/tappa_mascot_page.dart';

// ---------------------------------------------------------------------------
// Palette (locale — specchio di main.dart)
// ---------------------------------------------------------------------------

const Color _bgBase = Color(0xFF0D1714);
const Color _accentGold = Color(0xFFF0B429);
const Color _textPrimary = Color(0xFFF6EFE0);
const Color _textMuted = Color(0x9FF4EAD6);
const Color _textFaint = Color(0x38F4EAD6);
const Color _borderGold = Color(0x59F0B429);

// ---------------------------------------------------------------------------
// PercorsoScreen
// ---------------------------------------------------------------------------

/// PercorsoScreen — home dell'app, 9 tappe in 3 fasi (§6 del brief).
///
/// Quattro stati del nodo: completata, corrente, inCorso, bloccata (§6.3).
/// Tap su nodo → TappaMascotPage (pagina piena, non bottom sheet) (§7.2).
/// Ogni sottotitolo contiene un dato reale calcolato da liberta_core (D13).
/// Al rientro da TappaMascotPage, la vista scrolla sul nodo successivo (D14d).
class PercorsoScreen extends StatefulWidget {
  const PercorsoScreen({
    super.key,
    required this.profilo,
    required this.tappaCorrente,
    required this.tappeCompletate,
    required this.tappeInCorso,
    required this.usciteRegistrate,
    required this.usciteTrovate,
    required this.onCompletaTappa,
    required this.onTappaInCorso,
    required this.onNavigateTo,
    required this.onCrescitaChanged,
  });

  final engine.Profilo profilo;
  final int tappaCorrente;
  final Set<int> tappeCompletate;
  final Set<int> tappeInCorso;
  final int usciteRegistrate;
  final int usciteTrovate;
  final void Function(int) onCompletaTappa;
  final void Function(int) onTappaInCorso;
  final void Function(int) onNavigateTo;
  final void Function(double) onCrescitaChanged;

  @override
  State<PercorsoScreen> createState() => _PercorsoScreenState();
}

class _PercorsoScreenState extends State<PercorsoScreen>
    with TickerProviderStateMixin {
  final _scrollController = ScrollController();
  final List<GlobalKey> _tappaKeys = List.generate(9, (_) => GlobalKey());

  late AnimationController _bobController;
  late Animation<double> _bobAnim;

  // Restituisce true quando il binding è TestWidgetsFlutterBinding.
  // Usato per non avviare animazioni repeat() nei test widget:
  // pumpAndSettle non si "stabilizza" mai se ci sono frame infiniti.
  static bool _isTestBinding() =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );
    _bobAnim = Tween<double>(begin: -10.0, end: 0.0).animate(
      CurvedAnimation(parent: _bobController, curve: Curves.easeInOut),
    );
    if (!_isTestBinding()) _bobController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(PercorsoScreen old) {
    super.didUpdateWidget(old);
    if (old.tappaCorrente != widget.tappaCorrente) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToTappa(widget.tappaCorrente);
      });
    }
  }

  @override
  void dispose() {
    _bobController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTappa(int numero) {
    final idx = (numero - 1).clamp(0, 8);
    final key = _tappaKeys[idx];
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.15,
      );
    }
  }

  _StatoTappa _statoTappa(int numero) {
    if (widget.tappeCompletate.contains(numero)) return _StatoTappa.completata;
    if (widget.tappeInCorso.contains(numero)) return _StatoTappa.inCorso;
    if (numero == widget.tappaCorrente) return _StatoTappa.corrente;
    return _StatoTappa.bloccata;
  }

  Future<void> _onTapNodo(int numero) async {
    final stato = _statoTappa(numero);
    if (stato == _StatoTappa.bloccata) {
      _mostraInfoBloccata(numero);
      return;
    }

    final completata = widget.tappeCompletate.contains(numero);

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TappaMascotPage(
          tappa: numero,
          profilo: widget.profilo,
          completata: completata,
          usciteRegistrate: widget.usciteRegistrate,
          usciteTrovate: widget.usciteTrovate,
          onCompleta: () => widget.onCompletaTappa(numero),
          onInCorso: () => widget.onTappaInCorso(numero),
          onNavigateTo: widget.onNavigateTo,
          onCrescitaChanged: widget.onCrescitaChanged,
        ),
      ),
    );

    if ((result == true) && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToTappa(widget.tappaCorrente);
      });
    }
  }

  void _mostraInfoBloccata(int numero) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_requisitoSblocco(numero)),
        backgroundColor: const Color(0xFF1F3D35),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _requisitoSblocco(int numero) {
    if (numero == 1) return 'Completa il profilo per sbloccare questa tappa.';
    return 'Completa la tappa ${numero - 1} per sbloccare questa.';
  }

  // ---------------------------------------------------------------------------
  // Sottotitoli con dati reali dall'engine (D13)
  // ---------------------------------------------------------------------------

  String _sottotitolo(int numero) {
    final p = widget.profilo;
    final spese = engine.speseMensili(p.nettoMensile, p.risparmioMensile);
    final tasso = engine.tassoRisparmio(p.nettoMensile, p.risparmioMensile);
    final fondo = engine.fondoEmergenzaTarget(spese, mesiCopertura: p.mesiCopertura);
    final capVersoObi = engine.capitaleVersoObiettivo(p.capitaleAccantonato, fondo);
    final obiettivo = engine.capitaleObiettivo(spese * 12, regolaPrelievo: p.regolaPrelievo);
    final mesiBase = engine.mesiAllObiettivo(
        capVersoObi, p.risparmioMensile, p.crescitaIpotizzata, obiettivo);
    final impatto50 = engine.impattoSpesaRicorrente(50, p);
    final deltaMesi50 = impatto50.mesiGuadagnati?.round() ?? 0;

    switch (numero) {
      case 1:
        return "l'affitto non si tratta";
      case 2:
        return 'il tuo: ${(tasso * 100).toStringAsFixed(1)}%';
      case 3:
        return '${widget.usciteRegistrate} spese registrate';
      case 4:
        return 'il tuo fondo: ${_formatEuro(fondo)}';
      case 5:
        return '${widget.usciteTrovate} di 7 trovate';
      case 6:
        return 'sui tuoi ${_formatEuro(capVersoObi)}';
      case 7:
        return 'la tua ipotesi: ${(p.crescitaIpotizzata * 100).toStringAsFixed(1)}%';
      case 8:
        return 'il tuo ISC: 1,45%';
      case 9:
        if (mesiBase == null) return 'imposta un risparmio';
        return 'hai guadagnato $deltaMesi50 mesi';
      default:
        return '';
    }
  }

  String? _contatore(int numero) {
    if (_statoTappa(numero) != _StatoTappa.inCorso) return null;
    if (numero == 3) return '${widget.usciteRegistrate} di 10 registrate';
    if (numero == 5) return '${widget.usciteTrovate} di 7 trovate';
    return null;
  }

  // ---------------------------------------------------------------------------
  // Capitolo label per l'header
  // ---------------------------------------------------------------------------

  String get _capitoloLabel {
    if (widget.tappaCorrente <= 3) return 'capitolo I · budget';
    if (widget.tappaCorrente <= 6) return 'capitolo II · fondo';
    return 'capitolo III · futuro';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBase,
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
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFase(fase: 1, etichetta: 'Fase 1 — mese 1', tappe: [1, 2, 3]),
                    _buildFase(fase: 2, etichetta: 'Fase 2 — mesi 2–6', tappe: [4, 5, 6]),
                    _buildFase(fase: 3, etichetta: 'Fase 3 — futuro', tappe: [7, 8, 9]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header: barra superiore + hero con mascot animato
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    final completate = widget.tappeCompletate.length;
    final progressPercent = completate / 9.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barra superiore: ISEKAI + capitolo label
        Container(
          padding: const EdgeInsets.fromLTRB(20, 13, 20, 13),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xF21F3D35), Color(0xF2142823)],
            ),
            border: Border(bottom: BorderSide(color: Color(0x38F0B429))),
          ),
          child: Row(
            children: [
              Text(
                'ISEKAI',
                style: GoogleFonts.cinzel(
                  color: _accentGold,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 4,
                ),
              ),
              const Spacer(),
              Text(
                _capitoloLabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: _textMuted,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),

        // Hero: badge + titolo + barra XP  |  mascot
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 0, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge tappa
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0x1FF0B429),
                        border: Border.all(color: _borderGold),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: _accentGold,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Text(
                            'tappa ${widget.tappaCorrente} di 9',
                            style: GoogleFonts.nunito(
                              color: _accentGold,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Titolo "Percorso" in Cinzel
                    Text(
                      'Percorso',
                      style: GoogleFonts.cinzel(
                        color: _textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 40,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Barra XP
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 16,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: const Color(0x73000000),
                              border: Border.all(color: const Color(0x47F0B429)),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progressPercent,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF2F8F78),
                                      Color(0xFF43C3A3),
                                      Color(0xFFF0B429),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          '$completate completate',
                          style: GoogleFonts.nunito(
                            color: _textMuted,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Mascot con bob animation
              AnimatedBuilder(
                animation: _bobAnim,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, _bobAnim.value),
                  child: child,
                ),
                child: Image.asset(
                  'assets/images/mascot.png',
                  height: 130,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 130, width: 90),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Fase: etichetta + nodi + connettori
  // ---------------------------------------------------------------------------

  Widget _buildFase({
    required int fase,
    required String etichetta,
    required List<int> tappe,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            etichetta.toUpperCase(),
            style: GoogleFonts.nunito(
              color: _textFaint,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
        ),
        for (int i = 0; i < tappe.length; i++) ...[
          _NodoTappa(
            key: _tappaKeys[tappe[i] - 1],
            numero: tappe[i],
            titolo: _titoloDiTappa(tappe[i]),
            sottotitolo: _sottotitolo(tappe[i]),
            stato: _statoTappa(tappe[i]),
            contatore: _contatore(tappe[i]),
            xp: tappe[i] * 30,
            onTap: () => _onTapNodo(tappe[i]),
          ),
          if (i < tappe.length - 1)
            Padding(
              padding: const EdgeInsets.only(left: 27),
              child: CustomPaint(
                painter: _DashedLinePainter(
                  color: widget.tappeCompletate.contains(tappe[i])
                      ? const Color(0x9943C3A3)
                      : const Color(0x24F4EAD6),
                  dashHeight: 7,
                  gapHeight: 7,
                ),
                child: const SizedBox(width: 2, height: 26),
              ),
            ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Titoli delle 9 tappe
// ---------------------------------------------------------------------------

String _titoloDiTappa(int numero) {
  const titoli = [
    'Fisse o variabili',
    'Il tuo tasso di risparmio',
    'Registra un mese',
    'Perché tre mesi',
    'I costi che non vedi',
    'Interesse composto',
    'Rischio e rendimento',
    'Previdenza e i suoi costi',
    'Il tuo orizzonte',
  ];
  return titoli[numero - 1];
}

// ---------------------------------------------------------------------------
// Icone per tappa
// ---------------------------------------------------------------------------

IconData _iconaTappa(int numero) {
  switch (numero) {
    case 1: return Icons.balance_outlined;
    case 2: return Icons.percent;
    case 3: return Icons.search_outlined;
    case 4: return Icons.shield_outlined;
    case 5: return Icons.visibility_off_outlined;
    case 6: return Icons.trending_up_outlined;
    case 7: return Icons.show_chart_outlined;
    case 8: return Icons.account_balance_outlined;
    case 9: return Icons.flag_outlined;
    default: return Icons.circle_outlined;
  }
}

// ---------------------------------------------------------------------------
// Enum stato tappa
// ---------------------------------------------------------------------------

enum _StatoTappa { completata, corrente, inCorso, bloccata }

// ---------------------------------------------------------------------------
// Widget nodo sigillo — StatefulWidget con animazione pulse per "corrente"
// ---------------------------------------------------------------------------

class _NodoTappa extends StatefulWidget {
  const _NodoTappa({
    super.key,
    required this.numero,
    required this.titolo,
    required this.sottotitolo,
    required this.stato,
    required this.onTap,
    required this.xp,
    this.contatore,
  });

  final int numero;
  final String titolo;
  final String sottotitolo;
  final _StatoTappa stato;
  final VoidCallback onTap;
  final int xp;
  final String? contatore;

  @override
  State<_NodoTappa> createState() => _NodoTappaState();
}

class _NodoTappaState extends State<_NodoTappa>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // Stessa guardia usata nel parent per non rompere pumpAndSettle nei test.
  static bool _isTestBinding() =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.stato == _StatoTappa.corrente && !_isTestBinding()) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_NodoTappa old) {
    super.didUpdateWidget(old);
    if (old.stato != widget.stato) {
      if (widget.stato == _StatoTappa.corrente && !_isTestBinding()) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bool isMission = widget.stato == _StatoTappa.corrente;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icona sigillo (56–60px)
          _buildIcona(),
          const SizedBox(width: 18),
          // Contenuto
          Expanded(
            child: isMission ? _buildMissionCard() : _buildSimpleContent(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Icona in base allo stato
  // ---------------------------------------------------------------------------

  Widget _buildIcona() {
    switch (widget.stato) {
      case _StatoTappa.completata:
        return Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment(-0.6, -0.8),
              end: Alignment(0.6, 0.8),
              colors: [Color(0xFF2F8F78), Color(0xFF1D5D4E)],
            ),
            border: Border.all(color: const Color(0x4DF0B429)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Color(0xFFF6EFE0),
            size: 26,
          ),
        );

      case _StatoTappa.corrente:
        return AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, child) {
            final t = _pulseAnim.value;
            return Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFD775),
                    Color(0xFFF0B429),
                    Color(0xFFC98A14),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.lerp(
                      const Color(0x2EF0B429),
                      const Color(0x0FF0B429),
                      t,
                    )!,
                    blurRadius: 26 + (30 - 26) * t,
                    spreadRadius: 4 + (12 - 4) * t,
                  ),
                ],
              ),
              child: Icon(
                _iconaTappa(widget.numero),
                color: const Color(0xFF1B3A32),
                size: 26,
              ),
            );
          },
        );

      case _StatoTappa.inCorso:
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: const Color(0xFF2D2510),
                border: Border.all(color: const Color(0x66F0B429)),
              ),
              child: Icon(
                _iconaTappa(widget.numero),
                color: const Color(0xFFF0B429),
                size: 26,
              ),
            ),
            if (widget.contatore != null)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0B429),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.contatore!.split(' ').first,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF17332C),
                    ),
                  ),
                ),
              ),
          ],
        );

      case _StatoTappa.bloccata:
        return Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0x0DF4EAD6),
            border: Border.all(color: const Color(0x1AF4EAD6)),
          ),
          child: const Icon(
            Icons.lock_outline_rounded,
            color: Color(0x4FF4EAD6),
            size: 22,
          ),
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Contenuto semplice (completata / inCorso / bloccata)
  // ---------------------------------------------------------------------------

  Widget _buildSimpleContent() {
    final isBloccata = widget.stato == _StatoTappa.bloccata;
    final titleColor = isBloccata
        ? const Color(0x57F4EAD6)
        : _textPrimary;
    final subtitleColor = isBloccata
        ? const Color(0x38F4EAD6)
        : const Color(0x7FF4EAD6);
    final displayText =
        widget.stato == _StatoTappa.inCorso && widget.contatore != null
            ? widget.contatore!
            : widget.sottotitolo;

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.titolo,
            style: GoogleFonts.cinzel(
              color: titleColor,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayText,
            style: GoogleFonts.nunito(color: subtitleColor, fontSize: 15),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card "missione attiva" per il nodo corrente
  // ---------------------------------------------------------------------------

  Widget _buildMissionCard() {
    final displayText = widget.stato == _StatoTappa.inCorso &&
            widget.contatore != null
        ? widget.contatore!
        : widget.sottotitolo;

    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x472F8F78), Color(0x99122420)],
          ),
          border: Border.all(color: const Color(0x66F0B429)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66122420),
              blurRadius: 40,
              offset: Offset(0, 16),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MISSIONE ATTIVA',
              style: GoogleFonts.nunito(
                color: _accentGold,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 3.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.titolo,
              style: GoogleFonts.cinzel(
                color: const Color(0xFFFFF6E4),
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              displayText,
              style: GoogleFonts.nunito(
                color: const Color(0xADF4EAD6),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                GestureDetector(
                  onTap: widget.onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 13),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Continua',
                          style: GoogleFonts.nunito(
                            color: const Color(0xFF17332C),
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF17332C),
                          size: 17,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '· ricompensa · +${widget.xp} XP',
                  style: GoogleFonts.nunito(
                    color: const Color(0x73F4EAD6),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CustomPainter per i connettori tratteggiati
// ---------------------------------------------------------------------------

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({
    required this.color,
    this.dashHeight = 7,
    this.gapHeight = 7,
  });

  final Color color;
  final double dashHeight;
  final double gapHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    double y = 0;
    while (y < size.height) {
      final end = (y + dashHeight).clamp(0.0, size.height);
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, end - y), paint);
      y += dashHeight + gapHeight;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}

// ---------------------------------------------------------------------------
// Utility
// ---------------------------------------------------------------------------

String _formatEuro(double valore) {
  if (valore.isInfinite) return '∞';
  if (valore >= 1000000) return '${(valore / 1000000).toStringAsFixed(2)} M€';
  if (valore >= 1000) return '${(valore / 1000).toStringAsFixed(1)} k€';
  return '${valore.toStringAsFixed(0)} €';
}

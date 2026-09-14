import 'dart:math' show cos, sin;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isekai/liberta_core.dart';
import 'package:isekai/screens/splash_screen.dart';
import 'package:isekai/screens/percorso_screen.dart';
import 'package:isekai/screens/simulator_screen.dart';
import 'package:isekai/screens/uscite_screen.dart';
import 'package:isekai/screens/progressi_screen.dart';
import 'package:isekai/screens/profilo_screen.dart';

// ---------------------------------------------------------------------------
// Palette dark-fantasy globale
// ---------------------------------------------------------------------------

const Color bgBase        = Color(0xFF0D1714);
const Color bgCard        = Color(0xFF19302A);
const Color accentGold    = Color(0xFFF0B429);
const Color accentGoldLight = Color(0xFFFFD775);
const Color accentTeal    = Color(0xFF43C3A3);
const Color textPrimary   = Color(0xFFF6EFE0);
const Color textMuted     = Color(0x9FF4EAD6);
const Color borderGold    = Color(0x59F0B429);

void main() {
  runApp(const IsekaiApp());
}

class IsekaiApp extends StatelessWidget {
  const IsekaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Isekai',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgBase,
        colorScheme: ColorScheme.dark(
          primary: accentGold,
          secondary: accentTeal,
          surface: bgCard,
          onPrimary: const Color(0xFF17332C),
          onSecondary: textPrimary,
          onSurface: textPrimary,
        ),
        textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge: GoogleFonts.cinzel(
              color: textPrimary, fontWeight: FontWeight.w700),
          displayMedium: GoogleFonts.cinzel(
              color: textPrimary, fontWeight: FontWeight.w700),
          titleLarge: GoogleFonts.cinzel(
              color: textPrimary, fontWeight: FontWeight.w700),
          titleMedium: GoogleFonts.cinzel(
              color: textPrimary, fontWeight: FontWeight.w700),
        ),
        cardTheme: CardThemeData(
          color: bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: borderGold),
          ),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// AppShell — stato condiviso e shell con bottom nav custom
// ---------------------------------------------------------------------------

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.profiloIniziale});
  final Profilo? profiloIniziale;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  // Profilo con valori di esempio evidentemente fittizi (§14 del brief).
  late Profilo _profilo;

  @override
  void initState() {
    super.initState();
    _profilo = widget.profiloIniziale ??
        const Profilo(
          eta: 32,
          nettoMensile: 1800,
          risparmioMensile: 300,
          capitaleAccantonato: 12000,
          capitaleDisponibile: 12000,
          crescitaIpotizzata: 0.04,
          regolaPrelievo: 0.04,
          mesiCopertura: 3,
          livelloLessicale: 1,
        );

  }

  String _livelloCorrente = 'Novizio';

  int _tappaCorrente = 1;
  final Set<int> _tappeCompletate = {};
  final Set<int> _tappeInCorso = {};

  int _usciteDichiarateSpontaneamente = 0;
  int _usciteTrovate = 0;

  final List<Map<String, dynamic>> _uscite = [];
  final List<double> _registrazioniMensili = [];

  void _updateProfilo(Profilo p) => setState(() => _profilo = p);

  void _updateCrescita(double nuovaCrescita) =>
      setState(() => _profilo = _profilo.copyWith(crescitaIpotizzata: nuovaCrescita));

  void _completaTappa(int tappa) {
    final livelloPrecedente = _livello;
    setState(() {
      _tappeCompletate.add(tappa);
      _tappeInCorso.remove(tappa);
      if (_tappaCorrente == tappa && tappa < 9) _tappaCorrente = tappa + 1;
    });
    if (_livello != livelloPrecedente) {
      _livelloCorrente = _livello;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mostraLevelUp(_livello);
      });
    }
  }

  void _mostraLevelUp(String nuovoLivello) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim, _) => _LevelUpOverlay(livello: nuovoLivello),
    );
  }

  void _setTappaInCorso(int tappa) => setState(() => _tappeInCorso.add(tappa));

  void _updateUscite(
    List<Map<String, dynamic>> uscite,
    int dichiarate,
    int trovate,
  ) {
    setState(() {
      _uscite.clear();
      _uscite.addAll(uscite);
      _usciteDichiarateSpontaneamente = dichiarate;
      _usciteTrovate = trovate;
    });
  }

  void _aggiungiRegistrazione(double risparmioEffettivo) =>
      setState(() => _registrazioniMensili.add(risparmioEffettivo));

  static const int _sogliaUsciteRegistrate = 10;
  static const int _sogliaInvisibili = 5;

  void _onSogliaUsciteRaggiunta() {
    if (_tappeInCorso.contains(3) && !_tappeCompletate.contains(3)) {
      _completaTappa(3);
    }
  }

  void _onSogliaInvisibiliRaggiunta() {
    if (_tappeInCorso.contains(5) && !_tappeCompletate.contains(5)) {
      _completaTappa(5);
    }
  }

  int get _usciteRegistrate =>
      _uscite.where((u) => u['categoria'] != 'invisibile').length;

  // ---------------------------------------------------------------------------
  // XP system
  // ---------------------------------------------------------------------------

  static const int _xpPerTappa = 100;

  int get _xpTotali => _tappeCompletate.length * _xpPerTappa;

  String get _livello {
    final xp = _xpTotali;
    if (xp >= 900) return 'Saggio';
    if (xp >= 700) return 'Maestro';
    if (xp >= 500) return 'Studiosi';
    if (xp >= 300) return 'Esploratore';
    if (xp >= 100) return 'Apprendista';
    return 'Novizio';
  }

  Widget _buildXPBar() {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF0F2620), Color(0xFF19302A), Color(0xFF0F2620)],
        ),
        border: Border(
          bottom: BorderSide(color: Color(0x38F0B429)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text(
                '✦',
                style: TextStyle(
                  color: Color(0xFFF0B429),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$_xpTotali XP',
                style: const TextStyle(
                  color: Color(0xFFF0B429),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 16,
                color: const Color(0x38F0B429),
              ),
              const SizedBox(width: 8),
              Text(
                _livello,
                style: const TextStyle(
                  color: Color(0x9FF4EAD6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              ...List.generate(9, (i) {
                final completata = _tappeCompletate.contains(i + 1);
                return Container(
                  width: 6,
                  height: 10,
                  margin: const EdgeInsets.only(left: 3),
                  decoration: BoxDecoration(
                    color: completata
                        ? const Color(0xFFF0B429)
                        : const Color(0x22F4EAD6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom nav custom dark fantasy
  // ---------------------------------------------------------------------------

  static const _navLabels = ['Percorso', 'Simulatore', 'Uscite', 'Progressi', 'Profilo'];
  static const _navIcons = [
    Icons.route_outlined,
    Icons.calculate_outlined,
    Icons.receipt_long_outlined,
    Icons.show_chart_outlined,
    Icons.person_outline,
  ];
  static const _navActiveIcons = [
    Icons.route,
    Icons.calculate,
    Icons.receipt_long,
    Icons.show_chart,
    Icons.person,
  ];

  Widget _buildCustomBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xE6142823), Color(0xFA0E1C18)],
        ),
        border: Border(top: BorderSide(color: Color(0x38F0B429))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              for (int i = 0; i < _navLabels.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _selectedIndex = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      decoration: _selectedIndex == i
                          ? BoxDecoration(
                              color: const Color(0x24F0B429),
                              border: Border.all(color: const Color(0x59F0B429)),
                              borderRadius: BorderRadius.circular(14),
                            )
                          : null,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _selectedIndex == i
                                ? _navActiveIcons[i]
                                : _navIcons[i],
                            color: _selectedIndex == i ? accentGold : textMuted,
                            size: 22,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _navLabels[i],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _selectedIndex == i
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              letterSpacing: 1.0,
                              color: _selectedIndex == i ? accentGold : textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      PercorsoScreen(
        profilo: _profilo,
        tappaCorrente: _tappaCorrente,
        tappeCompletate: _tappeCompletate,
        tappeInCorso: _tappeInCorso,
        usciteRegistrate: _usciteRegistrate,
        usciteTrovate: _usciteTrovate,
        onCompletaTappa: _completaTappa,
        onTappaInCorso: _setTappaInCorso,
        onNavigateTo: (index) => setState(() => _selectedIndex = index),
        onCrescitaChanged: _updateCrescita,
      ),
      SimulatorScreen(
        profilo: _profilo,
        onSimulazioneSalvata: () {},
      ),
      UsciteScreen(
        uscite: _uscite,
        usciteDichiarateSpontaneamente: _usciteDichiarateSpontaneamente,
        usciteTrovate: _usciteTrovate,
        onUpdate: _updateUscite,
        sogliaUsciteRegistrate: _sogliaUsciteRegistrate,
        onSogliaUsciteRaggiunta: _onSogliaUsciteRaggiunta,
        sogliaInvisibili: _sogliaInvisibili,
        onSogliaInvisibiliRaggiunta: _onSogliaInvisibiliRaggiunta,
        onNavigateToPer: () => setState(() => _selectedIndex = 0),
      ),
      ProgressiScreen(
        profilo: _profilo,
        registrazioniMensili: _registrazioniMensili,
        onAggiungiRegistrazione: _aggiungiRegistrazione,
      ),
      ProfiloScreen(
        profilo: _profilo,
        onProfiloChanged: _updateProfilo,
        onProfiloConfermato: () {
          if (!_tappeCompletate.contains(1)) _completaTappa(1);
        },
      ),
    ];

    return Scaffold(
      body: Column(
        children: [
          _buildXPBar(),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildCustomBottomNav(),
    );
  }
}

// ---------------------------------------------------------------------------
// Level-up overlay
// ---------------------------------------------------------------------------

class _LevelUpOverlay extends StatefulWidget {
  const _LevelUpOverlay({required this.livello});
  final String livello;

  @override
  State<_LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<_LevelUpOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bgFade;
  late Animation<double> _starScale;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<double> _levelScale;
  late Animation<double> _levelFade;
  late Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _bgFade = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.0, 0.15, curve: Curves.easeIn));
    _starScale = CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.1, 0.35, curve: Curves.elasticOut));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.25, 0.50, curve: Curves.easeOut)));
    _titleFade = CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.25, 0.50, curve: Curves.easeIn));
    _levelScale = CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.40, 0.65, curve: Curves.elasticOut));
    _levelFade = CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.40, 0.55, curve: Curves.easeIn));
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.80, 1.0, curve: Curves.easeOut)));

    _ctrl.forward().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, _) {
        return Opacity(
          opacity: _exitFade.value,
          child: Stack(
            children: [
              Opacity(
                opacity: _bgFade.value,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.0,
                      colors: [
                        Color(0xCC2A1800),
                        Color(0xDD0D1714),
                      ],
                    ),
                  ),
                ),
              ),
              if (_starScale.value > 0)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ParticelleXP(progress: _ctrl.value),
                  ),
                ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scale: _starScale.value,
                      child: const Text(
                        '✦',
                        style: TextStyle(
                          color: Color(0xFFF0B429),
                          fontSize: 72,
                          shadows: [
                            Shadow(
                                color: Color(0xAFF0B429), blurRadius: 30),
                            Shadow(
                                color: Color(0x77F0B429), blurRadius: 60),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SlideTransition(
                      position: _titleSlide,
                      child: FadeTransition(
                        opacity: _titleFade,
                        child: const Text(
                          'LIVELLO SUPERIORE',
                          style: TextStyle(
                            color: Color(0x99F4EAD6),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Transform.scale(
                      scale: _levelScale.value,
                      child: FadeTransition(
                        opacity: _levelFade,
                        child: Text(
                          widget.livello.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFFF0B429),
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                            shadows: [
                              Shadow(
                                  color: Color(0x88F0B429), blurRadius: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Disegna 12 raggi di particelle dorate che esplodono dal centro,
/// con 24 particelle secondarie.
class _ParticelleXP extends CustomPainter {
  const _ParticelleXP({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.1 || progress > 0.85) return;
    final center = Offset(size.width / 2, size.height / 2);
    final t = ((progress - 0.1) / 0.5).clamp(0.0, 1.0);
    final maxR = size.height * 0.45;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * 3.141592653589793;
      final r = maxR * t;
      final pos =
          Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      final alpha = (1.0 - t) * 200;
      final radius = (1.0 - t * 0.5) * 6;
      paint.color = Color.fromARGB(alpha.round(), 240, 180, 41);
      canvas.drawCircle(pos, radius, paint);
    }

    for (int i = 0; i < 24; i++) {
      final angle = (i / 24) * 2 * 3.141592653589793 + 0.13;
      final r = maxR * t * 0.65;
      final pos =
          Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      final alpha = (1.0 - t) * 140;
      paint.color = Color.fromARGB(alpha.round(), 255, 215, 100);
      canvas.drawCircle(pos, (1.0 - t * 0.6) * 3.5, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticelleXP old) => old.progress != progress;
}

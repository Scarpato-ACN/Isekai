import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isekai/liberta_core.dart';
import 'package:isekai/main.dart' show AppShell;

// ---------------------------------------------------------------------------
// Palette locale — specchio di main.dart
// ---------------------------------------------------------------------------

const Color _bgCard = Color(0xFF19302A);
const Color _accentGold = Color(0xFFF0B429);
const Color _accentTeal = Color(0xFF43C3A3);
const Color _textPrimary = Color(0xFFF6EFE0);
const Color _textMuted = Color(0x9FF4EAD6);
const Color _borderGold = Color(0x59F0B429);

// ---------------------------------------------------------------------------
// OnboardingScreen
// ---------------------------------------------------------------------------

/// Flusso di onboarding a 3 slide mostrato al primo avvio.
///
/// Non naviga verso AppShell con pushReplacement: chiama [onComplete] e poi
/// esegue pop(), lasciando che AppShell (che ha fatto push di questa schermata)
/// rimanga nello stack e aggiorni il proprio profilo tramite il callback.
///
/// Questo garantisce che i widget test che cercano la bottom nav di AppShell
/// trovino sempre i widget anche quando l'onboarding è visibile.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.onComplete});

  /// Callback invocato al completamento.
  /// Riceve il [Profilo] compilato dall'utente, oppure null se l'utente ha
  /// saltato il flusso — in quel caso AppShell mantiene i valori di default.
  final void Function(Profilo?)? onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  double _crescita = 0.04;

  final TextEditingController _nettoCtrl = TextEditingController();
  final TextEditingController _risparmioCtrl = TextEditingController();
  final TextEditingController _capitaleCtrl = TextEditingController();
  final TextEditingController _disponibileCtrl = TextEditingController();

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nettoCtrl.dispose();
    _risparmioCtrl.dispose();
    _capitaleCtrl.dispose();
    _disponibileCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Costruzione del Profilo
  // ---------------------------------------------------------------------------

  Profilo _costruisciProfilo() {
    final netto =
        double.tryParse(_nettoCtrl.text.replaceAll(',', '.')) ?? 1800;
    final risparmio =
        double.tryParse(_risparmioCtrl.text.replaceAll(',', '.')) ?? 300;
    final capitale =
        double.tryParse(_capitaleCtrl.text.replaceAll(',', '.')) ?? 12000;
    final disponibile =
        double.tryParse(_disponibileCtrl.text.replaceAll(',', '.')) ??
            capitale;
    return Profilo(
      eta: 32,
      nettoMensile: netto.clamp(1, double.infinity),
      risparmioMensile: risparmio.clamp(0, netto),
      capitaleAccantonato: capitale.clamp(0, double.infinity),
      capitaleDisponibile: disponibile.clamp(0, capitale),
      crescitaIpotizzata: _crescita,
      regolaPrelievo: 0.04,
      mesiCopertura: 3,
      livelloLessicale: 1,
    );
  }

  // ---------------------------------------------------------------------------
  // Navigazione interna
  // ---------------------------------------------------------------------------

  void _avanti() {
    if (_currentPage < 2) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completa();
    }
  }

  void _completa() {
    final profilo = _costruisciProfilo();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => AppShell(profiloIniziale: profilo)),
    );
  }

  void _salta() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1714),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.95),
            radius: 1.1,
            colors: [Color(0xFF1D3A33), Color(0xFF142822), Color(0xFF0B1512)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Riga superiore: pulsante Salta (solo slide 1 e 2)
              SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _currentPage < 2
                      ? TextButton(
                          onPressed: _salta,
                          child: Text(
                            'Salta',
                            style: GoogleFonts.nunito(
                              color: _textMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),

              // Contenuto delle slide
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _buildSlide1(),
                    _buildSlide2(),
                    _buildSlide3(),
                  ],
                ),
              ),

              // Dots + bottone
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final active = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 10 : 7,
                          height: active ? 10 : 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: active ? _accentGold : _textMuted,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _avanti,
                      child: Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFFD775),
                              Color(0xFFE5A41C),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Center(
                          child: Text(
                            _currentPage < 2 ? 'Avanti' : 'Inizia',
                            style: GoogleFonts.nunito(
                              color: const Color(0xFF17332C),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Slide 1 — "A cosa serve"
  // ---------------------------------------------------------------------------

  Widget _buildSlide1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          Text(
            'Isekai',
            style: GoogleFonts.cinzel(
              color: _textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Image.asset('assets/images/mascot.png', height: 130),
          const SizedBox(height: 28),
          Text(
            '"Isekai" è uno strumento educativo che ti aiuta a capire '
            'il rapporto tra le tue uscite ricorrenti e il tempo necessario '
            "per raggiungere l'indipendenza finanziaria.",
            style: GoogleFonts.nunito(
              color: _textPrimary,
              fontSize: 15,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Non ti dice cosa fare con i tuoi soldi. Ti mostra come funzionano '
            'i meccanismi che li governano: interesse composto, costi nascosti, '
            "effetto delle spese fisse sull'orizzonte di risparmio.",
            style: GoogleFonts.nunito(
              color: _textPrimary,
              fontSize: 15,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Nessun dato che inserisci viene inviato a nessuno. '
            'Tutto rimane sul tuo dispositivo.',
            style: GoogleFonts.nunito(
              color: _textMuted,
              fontSize: 14,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Slide 2 — "Come funziona"
  // ---------------------------------------------------------------------------

  Widget _buildSlide2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          Text(
            'Il percorso',
            style: GoogleFonts.cinzel(
              color: _textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          _buildFaseCard(
            titolo: 'FASE 1 — OSSERVA',
            sottotitolo: 'tappe 1–3',
            icon: Icons.visibility_outlined,
            iconColor: _accentTeal,
            testo: 'Impara a distinguere le spese, misura il tuo tasso di risparmio '
                'e registra un mese reale di uscite.',
          ),
          const SizedBox(height: 14),
          _buildFaseCard(
            titolo: 'FASE 2 — COMPRENDI',
            sottotitolo: 'tappe 4–6',
            icon: Icons.analytics_outlined,
            iconColor: _accentGold,
            testo: "Calcola il fondo di emergenza, scopri i costi che non vedi "
                "e vedi come l'interesse composto cambia la traiettoria.",
          ),
          const SizedBox(height: 14),
          _buildFaseCard(
            titolo: 'FASE 3 — PROIETTA',
            sottotitolo: 'tappe 7–9',
            icon: Icons.timeline_outlined,
            iconColor: _accentTeal,
            testo: "Sperimenta con l'ipotesi di crescita, misura il costo del capitale "
                'e calcola il tuo orizzonte personale.',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFaseCard({
    required String titolo,
    required String sottotitolo,
    required IconData icon,
    required Color iconColor,
    required String testo,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderGold),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titolo,
                  style: GoogleFonts.nunito(
                    color: _textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  sottotitolo,
                  style: GoogleFonts.nunito(
                    color: _textMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  testo,
                  style: GoogleFonts.nunito(
                    color: _textPrimary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Slide 3 — "I tuoi dati"
  // ---------------------------------------------------------------------------

  Widget _buildSlide3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Prima di iniziare',
              style: GoogleFonts.cinzel(
                color: _textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Inserisci i tuoi numeri per rendere il percorso personale. '
              'Puoi modificarli in qualsiasi momento dal tab Profilo.',
              style: GoogleFonts.nunito(
                color: _textMuted,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _nettoCtrl,
            label: 'Reddito netto mensile',
            suffix: '€/mese',
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _risparmioCtrl,
            label: 'Risparmio mensile',
            suffix: '€/mese',
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _capitaleCtrl,
            label: 'Capitale già accantonato',
            suffix: '€',
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            helperText: 'Tutto ciò che hai da parte, dove non importa.',
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _disponibileCtrl,
            label: 'Capitale disponibile subito',
            suffix: '€',
            helperText:
                'Quanto potresti usare domani senza penali. Di default uguale al precedente.',
          ),
          const SizedBox(height: 24),

          // Slider crescita annua
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ipotesi di crescita annua',
                style: GoogleFonts.nunito(
                  color: _textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${(_crescita * 100).toStringAsFixed(1)}%',
                style: GoogleFonts.nunito(
                  color: _accentGold,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _accentGold,
              inactiveTrackColor: _bgCard,
              thumbColor: _accentGold,
              overlayColor: _accentGold.withOpacity(0.2),
            ),
            child: Slider(
              value: _crescita,
              min: 0,
              max: 0.06,
              divisions: 12,
              onChanged: (v) => setState(() => _crescita = v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0%',
                  style:
                      GoogleFonts.nunito(color: _textMuted, fontSize: 11)),
              Text('6%',
                  style:
                      GoogleFonts.nunito(color: _textMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    TextInputType? keyboardType,
    String? helperText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.nunito(color: _textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.nunito(color: _textMuted, fontSize: 13),
        suffixText: suffix,
        suffixStyle: GoogleFonts.nunito(color: _textMuted, fontSize: 13),
        helperText: helperText,
        helperStyle: GoogleFonts.nunito(color: _textMuted, fontSize: 11),
        helperMaxLines: 2,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _borderGold),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accentGold, width: 1.5),
        ),
        filled: true,
        fillColor: _bgCard,
      ),
    );
  }
}

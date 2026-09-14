import 'package:flutter/material.dart';
import 'package:isekai/liberta_core.dart' as engine;

/// SimulatorScreen — simulatore di spesa ricorrente (§6 del brief).
///
/// Ordine degli elementi: spiegazione → slider → due leve → risultato → nota.
/// Slider min=0 max=120 step=1, valore iniziale 12. Ricalcolo sincrono.
/// Tutti i numeri provengono da liberta_core (R1). Nessun numero hardcoded.
///
/// D2: il simulatore legge capitaleAccantonato dal profilo, mai 0 (§4.6).
class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({
    super.key,
    required this.profilo,
    required this.onSimulazioneSalvata,
  });

  final engine.Profilo profilo;
  final VoidCallback onSimulazioneSalvata;

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  double _importoMensile = 12.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Calcolo sincrono — tutti i numeri da liberta_core (R1, D2)
    final impatto =
        engine.impattoSpesaRicorrente(_importoMensile, widget.profilo);
    final leva1 = impatto.leva1RisparmioAnnuo;
    final leva2 = impatto.leva2RiduzioneObiettivo;
    final mesiG = impatto.mesiGuadagnati;
    final giorniStip = impatto.giorniStipendio;

    // Orizzonte baseline e ridotto (in anni) — per la riga secondaria
    // D3: simulatore legge profilo e ricalcola a cascata fondo ed obiettivo
    final risparmio = widget.profilo.risparmioMensile
        .clamp(0.0, widget.profilo.nettoMensile);
    final spese =
        engine.speseMensili(widget.profilo.nettoMensile, risparmio);
    final speseAnnuali = spese * 12;
    final obiettivo = engine.capitaleObiettivo(speseAnnuali,
        regolaPrelievo: widget.profilo.regolaPrelievo);
    final fondo = engine.fondoEmergenzaTarget(spese,
        mesiCopertura: widget.profilo.mesiCopertura);
    final capVersoObi = engine.capitaleVersoObiettivo(
        widget.profilo.capitaleAccantonato, fondo);
    // §5.3: usa capitaleVersoObiettivo, mai capitaleAccantonato
    final int? mesiBase = engine.mesiAllObiettivo(
        capVersoObi,
        risparmio,
        widget.profilo.crescitaIpotizzata,
        obiettivo);
    final double? anniBase =
        mesiBase != null ? mesiBase / 12.0 : null;
    final double? anniRidotti = (mesiBase != null && mesiG != null)
        ? (mesiBase - mesiG) / 12.0
        : null;

    final crescitaStr =
        '${(widget.profilo.crescitaIpotizzata * 100).toStringAsFixed(1)}%';
    final regolaStr =
        '${(widget.profilo.regolaPrelievo * 100).toStringAsFixed(0)}%';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulatore'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Riquadro di spiegazione
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Una spesa fissa pesa due volte',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Leva 1 — risparmio: ogni euro mensile che smetti di pagare '
                    'diventa un anno di accumulo in meno.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Leva 2 — obiettivo: una spesa fissa aumenta il capitale '
                    'che devi raggiungere. Ridurla lo abbassa. '
                    'Questo effetto non dipende dal rendimento.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Slider — l'app non propone mai un importo (§6)
            Text(
              'Importo mensile: ${_importoMensile.toStringAsFixed(0)} €',
              style: theme.textTheme.titleMedium,
            ),
            Slider(
              value: _importoMensile,
              min: 0,
              max: 120,
              divisions: 120,
              label: '${_importoMensile.toStringAsFixed(0)} €',
              onChanged: (v) => setState(() => _importoMensile = v),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0 €', style: theme.textTheme.bodySmall),
                Text('120 €', style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 24),

            // 3. Due metric card affiancate
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: 'Leva 1 — risparmio',
                    valore: '${leva1.toStringAsFixed(0)} €/anno',
                    nota: 'importo annuo non accumulato',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    label: 'Leva 2 — obiettivo',
                    valore: '−${_formatEuro(leva2)}',
                    nota: 'riduzione capitale obiettivo (25×)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 4. Riquadro risultato
            _RiquadroRisultato(
              mesiGuadagnati: mesiG,
              giorniStipendio: giorniStip,
              anniBase: anniBase,
              anniRidotti: anniRidotti,
              importoMensile: _importoMensile,
            ),
            const SizedBox(height: 16),

            // 5. Nota con ipotesi in chiaro (R7)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: cs.outline.withAlpha(100),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16,
                      color: cs.onSurface.withAlpha(140)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Questi numeri descrivono l\'effetto di questa uscita; '
                      'non indicano cosa fare. '
                      'Ipotesi applicate: crescita $crescitaStr annua, '
                      'regola del prelievo $regolaStr. '
                      'Fiscalità e inflazione escluse — limiti dichiarati. '
                      'La leva 2 è deterministica e non dipende dal rendimento.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withAlpha(150),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            OutlinedButton(
              onPressed: () {
                widget.onSimulazioneSalvata();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Simulazione registrata — tappa 4 completata'),
                  ),
                );
              },
              child: const Text('Registra simulazione'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.valore,
    required this.nota,
  });

  final String label;
  final String valore;
  final String nota;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            Text(
              valore,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(nota, style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(130),
            )),
          ],
        ),
      ),
    );
  }
}

class _RiquadroRisultato extends StatelessWidget {
  const _RiquadroRisultato({
    required this.mesiGuadagnati,
    required this.giorniStipendio,
    required this.anniBase,
    required this.anniRidotti,
    required this.importoMensile,
  });

  final double? mesiGuadagnati;
  final double? giorniStipendio;
  final double? anniBase;
  final double? anniRidotti;
  final double importoMensile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (importoMensile == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Sposta lo slider per vedere l\'effetto di una spesa ricorrente.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    // Modalità giorni di stipendio (§8.4, D4)
    if (mesiGuadagnati == null && giorniStipendio != null) {
      final giorni = giorniStipendio!;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.tertiaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Misura in giorni di stipendio',
              style: theme.textTheme.labelLarge?.copyWith(
                color: cs.onTertiaryContainer,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${giorni.toStringAsFixed(1)} giorni di stipendio netto',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: cs.onTertiaryContainer,
              ),
            ),
            Text(
              'all\'anno — il risparmio attuale è ≤ 0, '
              'quindi l\'unità mesi di libertà non è disponibile',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onTertiaryContainer.withAlpha(180),
              ),
            ),
          ],
        ),
      );
    }

    if (mesiGuadagnati == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('Imposta un risparmio nel profilo per calcolare i mesi di libertà.'),
      );
    }

    final mesi = mesiGuadagnati!;
    final mesiRound = mesi.round();

    final String rigaSecondaria;
    if (anniBase != null && anniRidotti != null) {
      rigaSecondaria = 'traguardo: da ${anniBase!.toStringAsFixed(1)} '
          'a ${anniRidotti!.toStringAsFixed(1)} anni';
    } else {
      rigaSecondaria = 'stima — dipende dalla crescita ipotizzata';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Effetto combinato delle due leve',
            style: theme.textTheme.labelLarge?.copyWith(
              color: cs.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatMesi(mesiRound),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: cs.onSecondaryContainer,
            ),
          ),
          Text(
            rigaSecondaria,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSecondaryContainer.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatEuro(double valore) {
  if (valore.isInfinite) return '∞';
  if (valore >= 1000000) {
    return '${(valore / 1000000).toStringAsFixed(2)} M€';
  }
  if (valore >= 1000) {
    return '${(valore / 1000).toStringAsFixed(1)} k€';
  }
  return '${valore.toStringAsFixed(0)} €';
}

String _formatMesi(int mesi) {
  if (mesi <= 0) return '0 mesi';
  final anni = mesi ~/ 12;
  final mesiRimanenti = mesi % 12;
  if (anni == 0) return '$mesi mesi';
  if (mesiRimanenti == 0) return '$anni anni';
  return '$anni anni e $mesiRimanenti mesi';
}

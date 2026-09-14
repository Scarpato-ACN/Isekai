import 'package:flutter/material.dart';
import 'dart:math';
import 'package:isekai/liberta_core.dart' as engine;

/// ProgressiScreen — tracking prospettico mese per mese (§9 del brief).
///
/// Asse X: mesi dall'attivazione.
/// Asse Y: risparmio cumulato (€).
/// Serie 1 (baseline): tratteggiata, grigia (R6).
/// Serie 2 (obiettivo): tratteggiata, accento (R6).
/// Serie 3 (reale): continua, piena (R6).
///
/// Al mese 1: solo le due serie proiettate + messaggio "il tuo primo dato
/// reale arriva tra N giorni". Mai un grafico vuoto, mai dati precaricati.
class ProgressiScreen extends StatefulWidget {
  const ProgressiScreen({
    super.key,
    required this.profilo,
    required this.registrazioniMensili,
    required this.onAggiungiRegistrazione,
  });

  final engine.Profilo profilo;
  final List<double> registrazioniMensili;
  final void Function(double risparmioEffettivo) onAggiungiRegistrazione;

  @override
  State<ProgressiScreen> createState() => _ProgressiScreenState();
}

class _ProgressiScreenState extends State<ProgressiScreen> {
  final _risparmioCtrl = TextEditingController();

  @override
  void dispose() {
    _risparmioCtrl.dispose();
    super.dispose();
  }

  void _registra() {
    final v = double.tryParse(_risparmioCtrl.text.replaceAll(',', '.'));
    if (v == null) return;
    widget.onAggiungiRegistrazione(v);
    _risparmioCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Calcoli da liberta_core (R1)
    final risparmio = widget.profilo.risparmioMensile
        .clamp(0.0, widget.profilo.nettoMensile);
    final spese = engine.speseMensili(
        widget.profilo.nettoMensile, risparmio);
    final obiettivo = engine.capitaleObiettivo(spese * 12,
        regolaPrelievo: widget.profilo.regolaPrelievo);

    // Serie baseline: risparmio base senza modifiche
    final int orizzonteGrafico = 24;
    final List<double> baseline = _proiezione(
      capitaleIniziale: widget.profilo.capitaleAccantonato,
      risparmioMensile: risparmio,
      crescitaAnnua: widget.profilo.crescitaIpotizzata,
      mesi: orizzonteGrafico,
    );

    // Serie obiettivo: uguale alla baseline in questa implementazione (D9)
    // In una versione con scenari impostati nel simulatore, userebbe quei parametri
    final List<double> obiettivoSerie = baseline;

    // Serie reale: dati registrati (cumulati)
    final List<double> reale = [];
    double cumulato = widget.profilo.capitaleAccantonato;
    for (final r in widget.registrazioniMensili) {
      cumulato += r;
      reale.add(cumulato);
    }

    // Mesi guadagnati dall'attivazione
    double mesiGuadagnati = 0;
    if (widget.registrazioniMensili.isNotEmpty) {
      final totaleSenzaRend = widget.registrazioniMensili
          .fold(0.0, (a, b) => a + b);
      final mesiBase = engine.mesiAllObiettivo(
        widget.profilo.capitaleAccantonato,
        risparmio,
        widget.profilo.crescitaIpotizzata,
        obiettivo,
      );
      final cumulatoConRend = reale.isNotEmpty ? reale.last : widget.profilo.capitaleAccantonato;
      final mesiConReale = engine.mesiAllObiettivo(
        cumulatoConRend,
        risparmio,
        widget.profilo.crescitaIpotizzata,
        obiettivo,
      );
      if (mesiBase != null && mesiConReale != null) {
        mesiGuadagnati =
            engine.deltaMesi(mesiBase.toDouble(), mesiConReale.toDouble());
      }
    }

    final crescitaStr =
        '${(widget.profilo.crescitaIpotizzata * 100).toStringAsFixed(1)}%';
    final registrazioni = widget.registrazioniMensili;
    final n = registrazioni.length;
    final giorniAlProssimo = 30 - (DateTime.now().day % 30);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progressi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Badge mesi guadagnati
          if (n > 0 && mesiGuadagnati != 0) ...[
            _BadgeMesi(mesi: mesiGuadagnati),
            const SizedBox(height: 16),
          ],

          // Grafico (D9)
          _GraficoProgressi(
            baseline: baseline,
            obiettivo: obiettivoSerie,
            reale: reale,
            orizzonteGrafico: orizzonteGrafico,
          ),
          const SizedBox(height: 8),

          // Legenda (D9 — la legenda dichiara tratteggio/continuo)
          _Legenda(),
          const SizedBox(height: 6),
          Text(
            'Ipotesi: crescita $crescitaStr annua. '
            'Le serie proiettate (tratteggiate) sono stime; '
            'la serie reale (continua) sono dati registrati da te.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withAlpha(140),
            ),
          ),
          const SizedBox(height: 20),

          // Stato mese 1 (§9.4)
          if (n == 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'il tuo primo dato reale arriva tra $giorniAlProssimo giorni',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Form registrazione mensile
          _FormRegistrazione(
            controller: _risparmioCtrl,
            meseNumero: n + 1,
            onRegistra: _registra,
          ),

          if (n > 0) ...[
            const SizedBox(height: 20),
            _StoricoRegistrazioni(
              registrazioni: registrazioni,
              capitaleIniziale: widget.profilo.capitaleAccantonato,
            ),
          ],
        ],
      ),
    );
  }

  List<double> _proiezione({
    required double capitaleIniziale,
    required double risparmioMensile,
    required double crescitaAnnua,
    required int mesi,
  }) {
    final List<double> serie = [];
    final double rMensile = crescitaAnnua / 12;
    double saldo = capitaleIniziale;
    for (int i = 1; i <= mesi; i++) {
      saldo = saldo * (1 + rMensile) + risparmioMensile;
      serie.add(saldo);
    }
    return serie;
  }
}

class _BadgeMesi extends StatelessWidget {
  const _BadgeMesi({required this.mesi});

  final double mesi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final mesiRound = mesi.round();
    final segno = mesi >= 0 ? '+' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.timeline, color: cs.onSecondaryContainer),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$segno$mesiRound mesi dall\'attivazione',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: cs.onSecondaryContainer,
                ),
              ),
              Text(
                'scarto rispetto alla proiezione iniziale',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSecondaryContainer.withAlpha(180),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Grafico custom con CustomPaint — serie tratteggiate per proiezioni (D9, R6).
class _GraficoProgressi extends StatelessWidget {
  const _GraficoProgressi({
    required this.baseline,
    required this.obiettivo,
    required this.reale,
    required this.orizzonteGrafico,
  });

  final List<double> baseline;
  final List<double> obiettivo;
  final List<double> reale;
  final int orizzonteGrafico;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 200,
      child: CustomPaint(
        painter: _GraficoPainter(
          baseline: baseline,
          obiettivo: obiettivo,
          reale: reale,
          orizzonteGrafico: orizzonteGrafico,
          colorBaseline: cs.outline.withAlpha(160),
          colorObiettivo: cs.primary.withAlpha(180),
          colorReale: cs.primary,
        ),
      ),
    );
  }
}

class _GraficoPainter extends CustomPainter {
  const _GraficoPainter({
    required this.baseline,
    required this.obiettivo,
    required this.reale,
    required this.orizzonteGrafico,
    required this.colorBaseline,
    required this.colorObiettivo,
    required this.colorReale,
  });

  final List<double> baseline;
  final List<double> obiettivo;
  final List<double> reale;
  final int orizzonteGrafico;
  final Color colorBaseline;
  final Color colorObiettivo;
  final Color colorReale;

  @override
  void paint(Canvas canvas, Size size) {
    if (baseline.isEmpty) return;

    // Troviamo il massimo per lo scaling
    final allValues = [...baseline, ...reale];
    final maxY = allValues.fold(0.0, (a, b) => max(a, b));
    if (maxY == 0) return;

    final w = size.width;
    final h = size.height;
    final n = orizzonteGrafico;

    Offset toOffset(int mese, double valore) {
      final x = (mese / n) * w;
      final y = h - (valore / maxY) * h;
      return Offset(x, y);
    }

    // Serie baseline — tratteggiata, grigia (R6, D9)
    if (baseline.isNotEmpty) {
      _disegnaTratto(canvas, baseline, n, toOffset, colorBaseline, tratteggio: true);
    }

    // Serie obiettivo — tratteggiata, accento (R6, D9)
    if (obiettivo.isNotEmpty) {
      _disegnaTratto(canvas, obiettivo, n, toOffset, colorObiettivo, tratteggio: true);
    }

    // Serie reale — continua (R6, D9)
    if (reale.isNotEmpty) {
      _disegnaTratto(canvas, reale, n, toOffset, colorReale, tratteggio: false);
    }
  }

  void _disegnaTratto(
    Canvas canvas,
    List<double> serie,
    int n,
    Offset Function(int, double) toOffset,
    Color colore, {
    required bool tratteggio,
  }) {
    final paint = Paint()
      ..color = colore
      ..strokeWidth = tratteggio ? 1.5 : 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (!tratteggio) {
      final path = Path();
      for (int i = 0; i < serie.length; i++) {
        final pt = toOffset(i + 1, serie[i]);
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      canvas.drawPath(path, paint);
    } else {
      // Tratteggio manuale: dash 6px, gap 4px
      for (int i = 0; i < serie.length - 1; i++) {
        final p1 = toOffset(i + 1, serie[i]);
        final p2 = toOffset(i + 2, serie[i + 1]);
        _disegnaSegmentoTratteggiato(canvas, p1, p2, paint);
      }
    }
  }

  void _disegnaSegmentoTratteggiato(
      Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashLen = 6.0;
    const gapLen = 4.0;
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist == 0) return;
    final ux = dx / dist;
    final uy = dy / dist;
    double drawn = 0;
    bool dash = true;
    while (drawn < dist) {
      final segLen = min(dash ? dashLen : gapLen, dist - drawn);
      final start = Offset(p1.dx + ux * drawn, p1.dy + uy * drawn);
      final end =
          Offset(p1.dx + ux * (drawn + segLen), p1.dy + uy * (drawn + segLen));
      if (dash) {
        canvas.drawLine(start, end, paint);
      }
      drawn += segLen;
      dash = !dash;
    }
  }

  @override
  bool shouldRepaint(_GraficoPainter old) =>
      old.baseline != baseline ||
      old.reale != reale ||
      old.obiettivo != obiettivo;
}

class _Legenda extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      children: [
        _VoceLegenda(
          colore: cs.outline.withAlpha(160),
          etichetta: 'baseline — proiettata',
          tratteggio: true,
        ),
        const SizedBox(width: 16),
        _VoceLegenda(
          colore: cs.primary.withAlpha(180),
          etichetta: 'obiettivo — proiettato',
          tratteggio: true,
        ),
        const SizedBox(width: 16),
        _VoceLegenda(
          colore: cs.primary,
          etichetta: 'reale — registrato',
          tratteggio: false,
        ),
      ],
    );
  }
}

class _VoceLegenda extends StatelessWidget {
  const _VoceLegenda({
    required this.colore,
    required this.etichetta,
    required this.tratteggio,
  });

  final Color colore;
  final String etichetta;
  final bool tratteggio;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(24, 8),
          painter: _LineetaPainter(colore: colore, tratteggio: tratteggio),
        ),
        const SizedBox(width: 4),
        Text(etichetta, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _LineetaPainter extends CustomPainter {
  const _LineetaPainter({required this.colore, required this.tratteggio});

  final Color colore;
  final bool tratteggio;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colore
      ..strokeWidth = tratteggio ? 1.5 : 2.0
      ..style = PaintingStyle.stroke;
    if (!tratteggio) {
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
    } else {
      double x = 0;
      bool dash = true;
      while (x < size.width) {
        final len = min(dash ? 5.0 : 3.0, size.width - x);
        if (dash) {
          canvas.drawLine(
            Offset(x, size.height / 2),
            Offset(x + len, size.height / 2),
            paint,
          );
        }
        x += len;
        dash = !dash;
      }
    }
  }

  @override
  bool shouldRepaint(_LineetaPainter old) =>
      old.colore != colore || old.tratteggio != tratteggio;
}

class _FormRegistrazione extends StatelessWidget {
  const _FormRegistrazione({
    required this.controller,
    required this.meseNumero,
    required this.onRegistra,
  });

  final TextEditingController controller;
  final int meseNumero;
  final VoidCallback onRegistra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Registra mese $meseNumero',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Risparmio effettivo questo mese (€)',
                suffixText: '€',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRegistra,
              child: Text('Registra mese $meseNumero'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoricoRegistrazioni extends StatelessWidget {
  const _StoricoRegistrazioni({
    required this.registrazioni,
    required this.capitaleIniziale,
  });

  final List<double> registrazioni;
  final double capitaleIniziale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double cumulato = capitaleIniziale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Storico', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (int i = 0; i < registrazioni.length; i++) ...[
          Builder(builder: (_) {
            cumulato += registrazioni[i];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Mese ${i + 1}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+${registrazioni[i].toStringAsFixed(0)} €',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    'totale: ${cumulato.toStringAsFixed(0)} €',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

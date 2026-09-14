import 'package:flutter/material.dart';
import 'package:isekai/liberta_core.dart' as engine;

/// ProfiloScreen — parametri dell'utente (§11.2 del brief).
///
/// Campi: età, stipendio netto, risparmio mensile, già accantonato,
/// disponibile subito, ipotesi di crescita.
/// Valori derivati: tasso di risparmio, spese stimate, fondo di emergenza,
/// copertura attuale, capitale obiettivo, orizzonte in anni (NON età di arrivo — D16).
///
/// Tutti i numeri derivati provengono da liberta_core (R1).
/// Il campo "disponibile subito" è funzionale, non identifica alcuno strumento (R3).
class ProfiloScreen extends StatefulWidget {
  const ProfiloScreen({
    super.key,
    required this.profilo,
    required this.onProfiloChanged,
    required this.onProfiloConfermato,
  });

  final engine.Profilo profilo;
  final void Function(engine.Profilo) onProfiloChanged;
  final VoidCallback onProfiloConfermato;

  @override
  State<ProfiloScreen> createState() => _ProfiloScreenState();
}

class _ProfiloScreenState extends State<ProfiloScreen> {
  late double _netto;
  late double _risparmio;
  late double _capitale;
  late double _capitaleDisponibile;
  late double _crescita;
  late int _eta;

  @override
  void initState() {
    super.initState();
    _netto = widget.profilo.nettoMensile;
    _risparmio = widget.profilo.risparmioMensile;
    _capitale = widget.profilo.capitaleAccantonato;
    _capitaleDisponibile = widget.profilo.capitaleDisponibile;
    _crescita = widget.profilo.crescitaIpotizzata;
    _eta = widget.profilo.eta;
  }

  void _emitUpdate() {
    final p = widget.profilo.copyWith(
      eta: _eta,
      nettoMensile: _netto,
      risparmioMensile: _risparmio,
      capitaleAccantonato: _capitale,
      capitaleDisponibile: _capitaleDisponibile.clamp(0, _capitale),
      crescitaIpotizzata: _crescita,
    );
    widget.onProfiloChanged(p);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Valori derivati — tutti da liberta_core (R1)
    final tasso = engine.tassoRisparmio(_netto, _risparmio);
    final spese = engine.speseMensili(_netto, _risparmio);
    final fondo = engine.fondoEmergenzaTarget(spese,
        mesiCopertura: widget.profilo.mesiCopertura);
    final copertura = engine.coperturaMesi(_capitaleDisponibile, spese);
    final speseAnnuali = spese * 12;
    final obiettivo = engine.capitaleObiettivo(speseAnnuali,
        regolaPrelievo: widget.profilo.regolaPrelievo);
    final capVersoObi =
        engine.capitaleVersoObiettivo(_capitale, fondo);
    final int? mesi = engine.mesiAllObiettivo(
        capVersoObi, _risparmio, _crescita, obiettivo);
    final double? anni = mesi != null ? mesi / 12.0 : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Età
            _SezioneInput(
              titolo: 'Età',
              child: Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _eta.toDouble(),
                      min: 18,
                      max: 70,
                      divisions: 52,
                      label: '$_eta anni',
                      onChanged: (v) {
                        setState(() => _eta = v.round());
                        _emitUpdate();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    child: Text(
                      '$_eta',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stipendio netto
            _SezioneInput(
              titolo: 'Stipendio netto',
              hint: 'al mese, quello che ti arriva',
              child: _StepCounter(
                valore: _netto,
                step: 50,
                min: 0,
                max: 20000,
                unit: '€/mese',
                onChanged: (v) {
                  setState(() => _netto = v);
                  _emitUpdate();
                },
              ),
            ),
            const SizedBox(height: 16),

            // Risparmio mensile
            _SezioneInput(
              titolo: 'Risparmio mensile',
              hint: 'quanto ti resta a fine mese',
              child: _StepCounter(
                valore: _risparmio,
                step: 10,
                min: 0,
                max: _netto,
                unit: '€/mese',
                onChanged: (v) {
                  setState(() => _risparmio = v);
                  _emitUpdate();
                },
              ),
            ),
            const SizedBox(height: 16),

            // Già accantonato
            _SezioneInput(
              titolo: 'Già accantonato',
              hint: 'tutto, dove non ci interessa',
              child: _StepCounter(
                valore: _capitale,
                step: 500,
                min: 0,
                max: 2000000,
                unit: '€',
                onChanged: (v) {
                  setState(() {
                    _capitale = v;
                    // Clamp disponibile se supera il nuovo accantonato
                    if (_capitaleDisponibile > _capitale) {
                      _capitaleDisponibile = _capitale;
                    }
                  });
                  _emitUpdate();
                },
              ),
            ),
            const SizedBox(height: 16),

            // Disponibile subito (§8.2, R3)
            _SezioneInput(
              titolo: 'Disponibile subito',
              hint: 'quanto potresti usare domani, senza penali',
              child: _StepCounter(
                valore: _capitaleDisponibile,
                step: 500,
                min: 0,
                max: _capitale,
                unit: '€',
                onChanged: (v) {
                  setState(() => _capitaleDisponibile = v);
                  _emitUpdate();
                },
              ),
            ),
            const SizedBox(height: 16),

            // Ipotesi di crescita
            _SezioneInput(
              titolo: 'Ipotesi di crescita annua',
              hint:
                  'La scegli tu. Non sappiamo dove tieni i soldi, quindi non la decidiamo per te.',
              child: Column(
                children: [
                  Slider(
                    value: _crescita * 100,
                    min: 0,
                    max: 6,
                    divisions: 12,
                    label: '${(_crescita * 100).toStringAsFixed(1)}%',
                    onChanged: (v) {
                      setState(() => _crescita = v / 100);
                      _emitUpdate();
                    },
                  ),
                  Text(
                    '${(_crescita * 100).toStringAsFixed(1)}% annuo',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Valori derivati — tutti da liberta_core
            _CardDerivati(
              tasso: tasso,
              spese: spese,
              fondo: fondo,
              copertura: copertura,
              obiettivo: obiettivo,
              anni: anni,
              crescita: _crescita,
              regola: widget.profilo.regolaPrelievo,
              mesiCopertura: widget.profilo.mesiCopertura,
            ),

            const SizedBox(height: 20),

            FilledButton(
              onPressed: () {
                _emitUpdate();
                widget.onProfiloConfermato();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profilo salvato')),
                );
              },
              child: const Text('Conferma profilo'),
            ),

            const SizedBox(height: 12),

            Text(
              'Fiscalità e inflazione escluse — limiti dichiarati. '
              'Questi numeri descrivono la tua situazione; '
              'non indicano cosa fare.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(140),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SezioneInput extends StatelessWidget {
  const _SezioneInput({
    required this.titolo,
    required this.child,
    this.hint,
  });

  final String titolo;
  final Widget child;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titolo, style: theme.textTheme.titleMedium),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(
            hint!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(150),
            ),
          ),
        ],
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _StepCounter extends StatelessWidget {
  const _StepCounter({
    required this.valore,
    required this.step,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  final double valore;
  final double step;
  final double min;
  final double max;
  final String unit;
  final void Function(double) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        IconButton.outlined(
          onPressed: valore > min
              ? () => onChanged((valore - step).clamp(min, max))
              : null,
          icon: const Icon(Icons.remove),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${valore.toStringAsFixed(0)} $unit',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          onPressed: valore < max
              ? () => onChanged((valore + step).clamp(min, max))
              : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class _CardDerivati extends StatelessWidget {
  const _CardDerivati({
    required this.tasso,
    required this.spese,
    required this.fondo,
    required this.copertura,
    required this.obiettivo,
    required this.anni,
    required this.crescita,
    required this.regola,
    required this.mesiCopertura,
  });

  final double tasso;
  final double spese;
  final double fondo;
  final double copertura;
  final double obiettivo;
  final double? anni;
  final double crescita;
  final double regola;
  final double mesiCopertura;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tassoStr = '${(tasso * 100).toStringAsFixed(1)}%';
    final speseStr = '${spese.toStringAsFixed(0)} €/mese';
    final fondoStr = _formatEuro(fondo);
    final copStr = copertura.isInfinite
        ? '∞ mesi'
        : '${copertura.toStringAsFixed(1)} mesi';
    final obiettivoStr = _formatEuro(obiettivo);
    final String orizzonteStr;
    if (anni == null) {
      orizzonteStr = 'non calcolabile (risparmio ≤ 0)';
    } else {
      orizzonteStr = '${anni!.toStringAsFixed(1)} anni';
    }
    final crescitaStr = '${(crescita * 100).toStringAsFixed(1)}%';
    final regolaStr = '${(regola * 100).toStringAsFixed(0)}%';
    final mesiCopStr = mesiCopertura.toStringAsFixed(0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Valori derivati', style: theme.textTheme.titleSmall),
            const SizedBox(height: 16),
            _RigaDato(label: 'Tasso di risparmio', valore: tassoStr),
            const SizedBox(height: 10),
            _RigaDato(label: 'Spese stimate', valore: speseStr),
            const SizedBox(height: 10),
            _RigaDato(
                label: 'Fondo di emergenza ($mesiCopStr mesi)',
                valore: fondoStr),
            const SizedBox(height: 10),
            _RigaDato(label: 'Copertura attuale', valore: copStr),
            const SizedBox(height: 10),
            _RigaDato(
              label: 'Capitale obiettivo (regola del $regolaStr)',
              valore: obiettivoStr,
            ),
            const SizedBox(height: 10),
            _RigaDato(
              label: 'Orizzonte attuale (con crescita $crescitaStr)',
              valore: orizzonteStr,
            ),
            const SizedBox(height: 10),
            Text(
              'Ipotesi: crescita $crescitaStr annua, regola del prelievo $regolaStr. '
              'Valore convenzionale, non una previsione. '
              'Fiscalità e inflazione escluse.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(130),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RigaDato extends StatelessWidget {
  const _RigaDato({required this.label, required this.valore});

  final String label;
  final String valore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        const SizedBox(width: 8),
        Text(
          valore,
          style: theme.textTheme.titleMedium,
        ),
      ],
    );
  }
}

String _formatEuro(double valore) {
  if (valore.isInfinite) return '∞';
  if (valore >= 1000000) return '${(valore / 1000000).toStringAsFixed(2)} M€';
  if (valore >= 1000) return '${(valore / 1000).toStringAsFixed(1)} k€';
  return '${valore.toStringAsFixed(0)} €';
}

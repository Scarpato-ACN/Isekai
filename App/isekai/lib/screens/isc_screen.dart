import 'package:flutter/material.dart';
import 'package:isekai/liberta_core.dart';

/// ISCScreen — calcolo del costo cumulato di una commissione (ISC, TAEG, ecc.)
///
/// Input: capitale accantonato, versamento mensile, ISC (%).
///
/// Output:
///   - Costo del primo anno
///   - Costo cumulato a 10 anni (differenza patrimonio lordo vs netto)
///   - Equivalente in mesi di risparmio e in giorni di stipendio
///
/// Label "riferimento teorico, non un prodotto esistente" sempre visibile (AC-3).
///
/// Il costo si misura contro un riferimento a costo zero, etichettato a schermo.
/// Un prodotto a costo zero non esiste: l'etichetta impedisce che questa
/// convenzione venga letta come confronto tra prodotti reali.
///
/// Nessun numero è hardcoded: ogni cifra proviene dall'engine liberta_core.
class ISCScreen extends StatefulWidget {
  const ISCScreen({super.key, this.nettoMensile = 0});

  /// Reddito netto mensile dell'utente, usato per esprimere il costo in giorni
  /// di stipendio. Se 0 (non inserito), la riga giorni non viene mostrata.
  final double nettoMensile;

  @override
  State<ISCScreen> createState() => _ISCScreenState();
}

class _ISCScreenState extends State<ISCScreen> {
  final _capitaleController = TextEditingController();
  final _versamentoController = TextEditingController();
  final _iscController = TextEditingController();

  double? _costoAnno1;
  double? _costo10Anni;
  double? _mesiEquivalenti;
  double? _giorniStipendio;
  String? _errore;

  @override
  void dispose() {
    _capitaleController.dispose();
    _versamentoController.dispose();
    _iscController.dispose();
    super.dispose();
  }

  void _calcola() {
    final capitale =
        double.tryParse(_capitaleController.text.replaceAll(',', '.'));
    final versamento =
        double.tryParse(_versamentoController.text.replaceAll(',', '.'));
    final iscPercento =
        double.tryParse(_iscController.text.replaceAll(',', '.'));

    if (capitale == null || versamento == null || iscPercento == null) {
      setState(() {
        _errore = 'Inserisci valori numerici validi nei tre campi.';
        _costoAnno1 = null;
        _costo10Anni = null;
        _mesiEquivalenti = null;
        _giorniStipendio = null;
      });
      return;
    }
    if (capitale <= 0 || versamento < 0 || iscPercento <= 0) {
      setState(() {
        _errore =
            'Capitale e ISC devono essere maggiori di zero. Versamento ≥ 0.';
        _costoAnno1 = null;
        _costo10Anni = null;
        _mesiEquivalenti = null;
        _giorniStipendio = null;
      });
      return;
    }

    // Tutti i numeri calcolati dall'engine
    final isc = iscPercento / 100;
    final c1 = capitale * isc;
    final c10 = costoCumulato(capitale, versamento, 0.04, c1, 10);
    final mesi = versamento > 0 ? c10 / versamento : null;
    final giorni = widget.nettoMensile > 0
        ? giorniDiStipendio(c10, widget.nettoMensile)
        : null;

    setState(() {
      _errore = null;
      _costoAnno1 = c1;
      _costo10Anni = c10;
      _mesiEquivalenti = mesi;
      _giorniStipendio = giorni;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.inversePrimary,
        title: const Text('Costo commissione (ISC)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "L'ISC (Indicatore Sintetico dei Costi) misura il costo totale "
              'annuo di un prodotto finanziario come percentuale del capitale. '
              'Non appare come addebito: viene trattenuto prima che il saldo '
              'venga aggiornato.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _capitaleController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Capitale accantonato (€)',
                hintText: 'es. 12000',
                border: OutlineInputBorder(),
                prefixText: '€ ',
              ),
              onChanged: (_) => _calcola(),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _versamentoController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Versamento mensile (€)',
                hintText: 'es. 200',
                border: OutlineInputBorder(),
                prefixText: '€ ',
              ),
              onChanged: (_) => _calcola(),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _iscController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'ISC del comparto (%)',
                hintText: 'es. 1.45',
                border: OutlineInputBorder(),
                suffixText: '%',
              ),
              onChanged: (_) => _calcola(),
            ),
            const SizedBox(height: 8),

            if (_errore != null)
              Text(
                _errore!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
              ),

            const SizedBox(height: 24),

            if (_costoAnno1 != null && _costo10Anni != null)
              _RisultatiISC(
                costoAnno1: _costoAnno1!,
                costo10Anni: _costo10Anni!,
                mesiEquivalenti: _mesiEquivalenti,
                giorniStipendio: _giorniStipendio,
              ),
          ],
        ),
      ),
    );
  }
}

class _RisultatiISC extends StatelessWidget {
  const _RisultatiISC({
    required this.costoAnno1,
    required this.costo10Anni,
    this.mesiEquivalenti,
    this.giorniStipendio,
  });

  final double costoAnno1;
  final double costo10Anni;
  final double? mesiEquivalenti;
  final double? giorniStipendio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Costo della commissione', style: theme.textTheme.titleSmall),
            const SizedBox(height: 16),

            _RigaCosto(
              label: 'Costo del primo anno',
              valore: '${costoAnno1.toStringAsFixed(2)} €',
              nota: 'ISC% × capitale iniziale. Non compare come addebito.',
            ),
            const SizedBox(height: 12),

            _RigaCosto(
              label: 'Costo cumulato in 10 anni',
              valore: '${costo10Anni.toStringAsFixed(0)} €',
              nota: 'Differenza patrimonio lordo − netto con versamenti mensili '
                  'e rendimento 4% annuo ipotizzato.',
              enfasi: true,
            ),

            if (mesiEquivalenti != null) ...[
              const SizedBox(height: 12),
              _RigaCosto(
                label: 'Equivalente in mesi di risparmio',
                valore: '${mesiEquivalenti!.toStringAsFixed(1)} mesi',
                nota: 'Costo cumulato ÷ versamento mensile.',
              ),
            ],

            if (giorniStipendio != null) ...[
              const SizedBox(height: 12),
              _RigaCosto(
                label: 'Equivalente in giorni di stipendio',
                valore: '${giorniStipendio!.toStringAsFixed(1)} giorni',
                nota: 'Costo cumulato ÷ reddito netto giornaliero (netto/30).',
              ),
            ],

            const Divider(height: 28),

            // AC-3: etichetta obbligatoria, stessa schermata del risultato
            Text(
              'riferimento teorico, non un prodotto esistente',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurface.withAlpha(130),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Il confronto è con uno scenario a costo zero, che non esiste nel '
              'mercato reale. Un costo più alto può corrispondere a una gestione '
              'diversa, a garanzie o servizi aggiuntivi. Questi numeri mostrano '
              'quanto costa, in euro. La valutazione spetta a te.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(110),
              ),
            ),

            const SizedBox(height: 12),
            Text(
              'Ipotesi: rendimento lordo 4% annuo. Fiscalità e inflazione escluse — '
              'limite dichiarato.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(110),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RigaCosto extends StatelessWidget {
  const _RigaCosto({
    required this.label,
    required this.valore,
    required this.nota,
    this.enfasi = false,
  });

  final String label;
  final String valore;
  final String nota;
  final bool enfasi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Text(
              valore,
              style: (enfasi
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.titleMedium)
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            nota,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(140),
            ),
          ),
        ),
      ],
    );
  }
}

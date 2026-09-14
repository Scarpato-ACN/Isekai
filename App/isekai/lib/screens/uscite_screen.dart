import 'package:flutter/material.dart';
import 'package:isekai/liberta_core.dart' as engine;

/// UsciteScreen — elenco uscite e caccia alle invisibili (§7 del brief).
///
/// Categorie: fisse, variabili, invisibili.
/// La categoria invisibili è l'unica in cui si inserisce una percentuale
/// annua + base di calcolo e si riceve un importo mensile (R1).
///
/// Contatori distinti: usciteDichiarateSpontaneamente e usciteTrovate.
class UsciteScreen extends StatefulWidget {
  const UsciteScreen({
    super.key,
    required this.uscite,
    required this.usciteDichiarateSpontaneamente,
    required this.usciteTrovate,
    required this.onUpdate,
    required this.sogliaUsciteRegistrate,
    required this.onSogliaUsciteRaggiunta,
    required this.sogliaInvisibili,
    required this.onSogliaInvisibiliRaggiunta,
    required this.onNavigateToPer,
  });

  final List<Map<String, dynamic>> uscite;
  final int usciteDichiarateSpontaneamente;
  final int usciteTrovate;
  final void Function(
      List<Map<String, dynamic>> uscite, int dichiarate, int trovate) onUpdate;
  /// Soglia spese registrate (fisse+variabili) per completare tappa 3.
  final int sogliaUsciteRegistrate;
  final VoidCallback onSogliaUsciteRaggiunta;
  /// Soglia uscite invisibili trovate per completare tappa 5.
  final int sogliaInvisibili;
  final VoidCallback onSogliaInvisibiliRaggiunta;
  final VoidCallback onNavigateToPer;

  @override
  State<UsciteScreen> createState() => _UsciteScreenState();
}

class _UsciteScreenState extends State<UsciteScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Lista locale di uscite (sincronizzata con il parent)
  late List<Map<String, dynamic>> _uscite;
  late int _dichiarateSpontaneamente;
  late int _trovate;

  // Checklist invisibili — 7 voci (§7.2)
  final List<_VoceCaccia> _checklist = [
    _VoceCaccia(etichetta: 'Canone conto corrente'),
    _VoceCaccia(etichetta: 'Costo carta di pagamento'),
    _VoceCaccia(etichetta: 'Costo percentuale annuo sullo strumento di risparmio (ISC, TER o simili)'),
    _VoceCaccia(etichetta: 'Commissioni di gestione sul capitale accantonato'),
    _VoceCaccia(etichetta: 'Rinnovi automatici di abbonamenti'),
    _VoceCaccia(etichetta: 'Assicurazioni accessorie'),
    _VoceCaccia(etichetta: 'Commissioni di bonifico o prelievo'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _uscite = List.from(widget.uscite);
    _dichiarateSpontaneamente = widget.usciteDichiarateSpontaneamente;
    _trovate = widget.usciteTrovate;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _emitUpdate() {
    widget.onUpdate(_uscite, _dichiarateSpontaneamente, _trovate);
  }

  void _aggiungiUscita(String etichetta, String categoria, double importo) {
    setState(() {
      final isFirstBatch = _uscite.isEmpty && _dichiarateSpontaneamente == 0;
      _uscite.add({
        'etichetta': etichetta,
        'categoria': categoria,
        'importoMensile': importo,
      });
      if (isFirstBatch || categoria != 'invisibile') {
        _dichiarateSpontaneamente++;
      }
    });
    _emitUpdate();
    // Controlla soglia tappa 3 (uscite visibili registrate)
    final usciteVisibili = _uscite
        .where((u) => u['categoria'] != 'invisibile')
        .length;
    if (usciteVisibili >= widget.sogliaUsciteRegistrate) {
      widget.onSogliaUsciteRaggiunta();
    }
  }

  void _rimuoviUscita(int index) {
    setState(() {
      final u = _uscite[index];
      if (u['categoria'] != 'invisibile' && _dichiarateSpontaneamente > 0) {
        _dichiarateSpontaneamente--;
      }
      _uscite.removeAt(index);
    });
    _emitUpdate();
  }

  void _toggleChecklist(int index, bool valore) {
    setState(() {
      _checklist[index].selezionata = valore;
      _trovate = _checklist.where((v) => v.selezionata).length;
    });
    _emitUpdate();
    // Controlla soglia tappa 5 (invisibili trovate)
    if (_trovate >= widget.sogliaInvisibili) {
      widget.onSogliaInvisibiliRaggiunta();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final sogliaToccata = _trovate >= widget.sogliaInvisibili;
    final usciteVisibili = _uscite.where((u) => u['categoria'] != 'invisibile').length;
    final sogliaTappa3Toccata = usciteVisibili >= widget.sogliaUsciteRegistrate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Uscite'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Le tue uscite'),
            Tab(text: 'Caccia alle invisibili'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1 — lista uscite
          _ListaUscite(
            uscite: _uscite,
            onRimuovi: _rimuoviUscita,
            onAggiungi: (etichetta, categoria, importo) =>
                _aggiungiUscita(etichetta, categoria, importo),
            sogliaRegistrate: widget.sogliaUsciteRegistrate,
            sogliaToccata: sogliaTappa3Toccata,
            onTornaAlPercorso: widget.onNavigateToPer,
          ),
          // Tab 2 — caccia alle invisibili
          _CacciaInvisibili(
            checklist: _checklist,
            trovate: _trovate,
            soglia: widget.sogliaInvisibili,
            sogliaToccata: sogliaToccata,
            onToggle: _toggleChecklist,
            onTornaAlPercorso: widget.onNavigateToPer,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lista uscite
// ---------------------------------------------------------------------------

class _ListaUscite extends StatefulWidget {
  const _ListaUscite({
    required this.uscite,
    required this.onRimuovi,
    required this.onAggiungi,
    required this.sogliaRegistrate,
    required this.sogliaToccata,
    required this.onTornaAlPercorso,
  });

  final List<Map<String, dynamic>> uscite;
  final void Function(int) onRimuovi;
  final void Function(String etichetta, String categoria, double importo)
      onAggiungi;
  final int sogliaRegistrate;
  final bool sogliaToccata;
  final VoidCallback onTornaAlPercorso;

  @override
  State<_ListaUscite> createState() => _ListaUsciteState();
}

class _ListaUsciteState extends State<_ListaUscite> {
  bool _formAperto = false;
  final _etichettaCtrl = TextEditingController();
  final _importoCtrl = TextEditingController();
  final _percentualeCtrl = TextEditingController();
  final _baseCtrl = TextEditingController();
  String _categoria = 'fissa';

  @override
  void dispose() {
    _etichettaCtrl.dispose();
    _importoCtrl.dispose();
    _percentualeCtrl.dispose();
    _baseCtrl.dispose();
    super.dispose();
  }

  void _salva() {
    final etichetta = _etichettaCtrl.text.trim();
    if (etichetta.isEmpty) return;

    double importo = 0;
    if (_categoria == 'invisibile') {
      final pct = double.tryParse(
              _percentualeCtrl.text.replaceAll(',', '.')) ??
          0;
      final base =
          double.tryParse(_baseCtrl.text.replaceAll(',', '.')) ?? 0;
      // importo mensile da percentuale annua + base di calcolo (R1)
      importo = engine.costoCumulato(base, 0, 0, pct / 100, 1) / 12;
      // Calcolo semplice: percentuale * base / 12
      importo = base * (pct / 100) / 12;
    } else {
      importo =
          double.tryParse(_importoCtrl.text.replaceAll(',', '.')) ?? 0;
    }

    if (importo <= 0) return;

    widget.onAggiungi(etichetta, _categoria, importo);
    setState(() {
      _formAperto = false;
      _etichettaCtrl.clear();
      _importoCtrl.clear();
      _percentualeCtrl.clear();
      _baseCtrl.clear();
      _categoria = 'fissa';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final fisse = widget.uscite.where((u) => u['categoria'] == 'fissa').toList();
    final variabili = widget.uscite.where((u) => u['categoria'] == 'variabile').toList();
    final invisibili = widget.uscite.where((u) => u['categoria'] == 'invisibile').toList();

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            if (fisse.isNotEmpty) ...[
              _IntestazioneLista(titolo: 'Fisse', totale: _totale(fisse)),
              ...fisse.map((u) => _RigaUscita(
                    uscita: u,
                    onRimuovi: () => widget.onRimuovi(widget.uscite.indexOf(u)),
                  )),
              const SizedBox(height: 8),
            ],
            if (variabili.isNotEmpty) ...[
              _IntestazioneLista(titolo: 'Variabili', totale: _totale(variabili)),
              ...variabili.map((u) => _RigaUscita(
                    uscita: u,
                    onRimuovi: () => widget.onRimuovi(widget.uscite.indexOf(u)),
                  )),
              const SizedBox(height: 8),
            ],
            if (invisibili.isNotEmpty) ...[
              _IntestazioneLista(titolo: 'Invisibili', totale: _totale(invisibili)),
              ...invisibili.map((u) => _RigaUscita(
                    uscita: u,
                    onRimuovi: () => widget.onRimuovi(widget.uscite.indexOf(u)),
                  )),
              const SizedBox(height: 8),
            ],
            if (widget.uscite.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text(
                  'Nessuna uscita registrata.\n'
                  'Fisse: cadenza periodica (affitto, luce, gas). '
                  'Variabili: discrezionali (cene, cinema). '
                  'Invisibili: nella scheda a fianco.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(140),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (widget.sogliaToccata) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Hai registrato ${widget.uscite.where((u) => u['categoria'] != 'invisibile').length} spese — tappa 3 completata.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: widget.onTornaAlPercorso,
                      child: const Text('Torna al percorso'),
                    ),
                  ],
                ),
              ),
            ],
            if (_formAperto) ...[
              const SizedBox(height: 16),
              _FormNuovaUscita(
                etichettaCtrl: _etichettaCtrl,
                importoCtrl: _importoCtrl,
                percentualeCtrl: _percentualeCtrl,
                baseCtrl: _baseCtrl,
                categoria: _categoria,
                onCategoriaChanged: (v) => setState(() => _categoria = v),
                onSalva: _salva,
                onAnnulla: () => setState(() => _formAperto = false),
              ),
            ],
          ],
        ),
        if (!_formAperto)
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton.extended(
              onPressed: () => setState(() => _formAperto = true),
              icon: const Icon(Icons.add),
              label: const Text('Aggiungi'),
            ),
          ),
      ],
    );
  }

  double _totale(List<Map<String, dynamic>> lista) {
    return lista.fold(
        0.0, (sum, u) => sum + (u['importoMensile'] as double));
  }
}

class _IntestazioneLista extends StatelessWidget {
  const _IntestazioneLista({required this.titolo, required this.totale});

  final String titolo;
  final double totale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titolo, style: theme.textTheme.titleMedium),
          Text(
            '${totale.toStringAsFixed(0)} €/mese',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _RigaUscita extends StatelessWidget {
  const _RigaUscita({required this.uscita, required this.onRimuovi});

  final Map<String, dynamic> uscita;
  final VoidCallback onRimuovi;

  @override
  Widget build(BuildContext context) {
    final importo = uscita['importoMensile'] as double;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(uscita['etichetta'] as String),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${importo.toStringAsFixed(0)} €/mese'),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onRimuovi,
          ),
        ],
      ),
    );
  }
}

class _FormNuovaUscita extends StatelessWidget {
  const _FormNuovaUscita({
    required this.etichettaCtrl,
    required this.importoCtrl,
    required this.percentualeCtrl,
    required this.baseCtrl,
    required this.categoria,
    required this.onCategoriaChanged,
    required this.onSalva,
    required this.onAnnulla,
  });

  final TextEditingController etichettaCtrl;
  final TextEditingController importoCtrl;
  final TextEditingController percentualeCtrl;
  final TextEditingController baseCtrl;
  final String categoria;
  final void Function(String) onCategoriaChanged;
  final VoidCallback onSalva;
  final VoidCallback onAnnulla;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nuova uscita', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: etichettaCtrl,
              decoration: const InputDecoration(
                labelText: 'Etichetta',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: categoria,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'fissa',
                    child: Text('Fissa — cadenza periodica (affitto, luce, gas)')),
                DropdownMenuItem(
                    value: 'variabile',
                    child: Text('Variabile — discrezionale (cene, cinema)')),
                DropdownMenuItem(
                    value: 'invisibile',
                    child: Text('Invisibile (commissione, ISC, TAEG)')),
              ],
              onChanged: (v) {
                if (v != null) onCategoriaChanged(v);
              },
            ),
            const SizedBox(height: 12),
            if (categoria == 'invisibile') ...[
              TextField(
                controller: percentualeCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Percentuale annua (es. 1.45 per 1,45%)',
                  suffixText: '%',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: baseCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Base di calcolo (€)',
                  suffixText: '€',
                  border: OutlineInputBorder(),
                ),
              ),
            ] else
              TextField(
                controller: importoCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Importo mensile (€)',
                  suffixText: '€/mese',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onAnnulla,
                    child: const Text('Annulla'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onSalva,
                    child: const Text('Aggiungi'),
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
// Caccia alle invisibili
// ---------------------------------------------------------------------------

class _VoceCaccia {
  final String etichetta;
  bool selezionata;

  _VoceCaccia({required this.etichetta, this.selezionata = false});
}

class _CacciaInvisibili extends StatelessWidget {
  const _CacciaInvisibili({
    required this.checklist,
    required this.trovate,
    required this.soglia,
    required this.sogliaToccata,
    required this.onToggle,
    required this.onTornaAlPercorso,
  });

  final List<_VoceCaccia> checklist;
  final int trovate;
  final int soglia;
  final bool sogliaToccata;
  final void Function(int, bool) onToggle;
  final VoidCallback onTornaAlPercorso;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Dove si nascondono i costi ricorrenti',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Controlla ognuna: se trovi un importo o una percentuale, '
          'torna alla scheda uscite e registrala come invisibile.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurface.withAlpha(150),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$trovate di ${checklist.length} verificate',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        ...checklist.asMap().entries.map((e) => CheckboxListTile(
              value: e.value.selezionata,
              title: Text(e.value.etichetta),
              onChanged: (v) => onToggle(e.key, v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            )),
        if (sogliaToccata) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Hai verificato $trovate voci — tappa 3 completata.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: onTornaAlPercorso,
                  child: const Text('Torna al percorso'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

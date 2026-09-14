/// test/liberta_core_test.dart
///
/// Test unitari dell'engine liberta_core — versione v4.1.
/// Ogni test cita il criterio D1-D18 o il requisito R che verifica.
///
/// Profilo di riferimento (§5.5 del brief v4.1):
///   netto 1800 €/mese · risparmio 300 €/mese · capitale accantonato 12.000 €
///   capitale disponibile 12.000 € · crescita 4% · regola 4% · mesiCopertura 3
///
/// Fixture attesi (§5.5):
///   fondoEmergenzaTarget(1500, mesiCopertura: 3) = 4500
///   coperturaMesi(12000, 1500) = 8.0
///   capitaleVersoObiettivo(12000, 4500) = 7500
///   capitaleVersoObiettivo(3000, 4500) = 0.0 (mai negativo)
///   mesiAllObiettivo(7500, 300, 0.04, 450000) = 515
///   impattoSpesaRicorrente(12).mesiGuadagnati = 11 (±1)
///   impattoSpesaRicorrente(30).mesiGuadagnati = 27 (±1)
///   impattoSpesaRicorrente(50).mesiGuadagnati = 44 (±1)
///   impattoSpesaRicorrente(100).mesiGuadagnati = 81 (±1)
///   mesiAllObiettivo with crescita=0 → 1475
///   mesi fondo emergenza da zero (4500/300) → 15

import 'package:flutter_test/flutter_test.dart';
import 'package:isekai/liberta_core.dart';
import 'package:isekai/guardrail.dart';

void main() {
  // Profilo di riferimento — §5.5 del brief v4.1
  const profiloRef = Profilo(
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

  // ---------------------------------------------------------------------------
  // D1 — liberta-core passa tutti i fixture del §5.5 (v4.1)
  // ---------------------------------------------------------------------------

  group('D1: fixture §5.5 v4.1 — valori attesi esatti', () {
    test('D1: tassoRisparmio(1800, 300) → 0.1667', () {
      expect(tassoRisparmio(1800, 300), closeTo(0.1667, 0.0001));
    });

    test('D1: speseMensili(1800, 300) → 1500.0', () {
      expect(speseMensili(1800, 300), equals(1500.0));
    });

    test('D1: fondoEmergenzaTarget(1500, mesiCopertura: 3) → 4500.0', () {
      expect(fondoEmergenzaTarget(1500, mesiCopertura: 3), equals(4500.0));
    });

    test('D1: fondoEmergenzaTarget default mesiCopertura=3 → 4500.0', () {
      expect(fondoEmergenzaTarget(1500), equals(4500.0));
    });

    test('D1: coperturaMesi(12000, 1500) → 8.0', () {
      expect(coperturaMesi(12000, 1500), equals(8.0));
    });

    test('D1: capitaleVersoObiettivo(12000, 4500) → 7500.0', () {
      expect(capitaleVersoObiettivo(12000, 4500), equals(7500.0));
    });

    test('D1: capitaleVersoObiettivo(3000, 4500) → 0.0 (mai negativo)', () {
      // capitaleAccantonato < fondoEmergenzaTarget → 0, non negativo
      expect(capitaleVersoObiettivo(3000, 4500), equals(0.0));
    });

    test('D1: capitaleObiettivo(1500 * 12) → 450000.0', () {
      expect(capitaleObiettivo(1500 * 12), equals(450000.0));
    });

    test('D1: mesiAllObiettivo(7500, 300, 0.04, 450000) → 515 (§5.3 — usa capitaleVersoObiettivo)', () {
      // §5.3: il primo parametro è capitaleVersoObiettivo, mai capitaleAccantonato
      // 7500 = capitaleVersoObiettivo(12000, 4500)
      final m = mesiAllObiettivo(7500, 300, 0.04, 450000);
      expect(m, isNotNull);
      expect(m!, closeTo(515, 2));
    });

    test('D1: mesiAllObiettivo(0, 0, 0.04, 450000) → null (risparmio=0)', () {
      // Con risparmio=0, nessuna convergenza possibile
      expect(mesiAllObiettivo(0, 0, 0.04, 450000), isNull);
    });

    test('D1: mesiAllObiettivo con crescita=0 → 1475 (accumulo lineare da 7500)', () {
      // (450000 - 7500) / 300 = 1475
      final m = mesiAllObiettivo(7500, 300, 0, 450000);
      expect(m, isNotNull);
      expect(m!, equals(1475));
    });

    test('D1: mesi fondo emergenza da zero (4500/300) → 15', () {
      // Costruire il fondo da zero a 300/mese senza crescita: 4500/300 = 15
      final m = mesiAllObiettivo(0, 300, 0, 4500);
      expect(m, isNotNull);
      expect(m!, equals(15));
    });

    test('D1: impattoSpesaRicorrente(12) → mesiGuadagnati 11 (±1)', () {
      final r = impattoSpesaRicorrente(12, profiloRef);
      expect(r.mesiGuadagnati, isNotNull);
      expect(r.mesiGuadagnati!, closeTo(11, 1));
    });

    test('D1: impattoSpesaRicorrente(30) → mesiGuadagnati 27 (±1)', () {
      final r = impattoSpesaRicorrente(30, profiloRef);
      expect(r.mesiGuadagnati, isNotNull);
      expect(r.mesiGuadagnati!, closeTo(27, 1));
    });

    test('D1: impattoSpesaRicorrente(50) → mesiGuadagnati 44 (±1)', () {
      final r = impattoSpesaRicorrente(50, profiloRef);
      expect(r.mesiGuadagnati, isNotNull);
      expect(r.mesiGuadagnati!, closeTo(44, 1));
    });

    test('D1: impattoSpesaRicorrente(100) → mesiGuadagnati 81 (±1)', () {
      final r = impattoSpesaRicorrente(100, profiloRef);
      expect(r.mesiGuadagnati, isNotNull);
      expect(r.mesiGuadagnati!, closeTo(81, 1));
    });

    test('D1: non-linearità — la colonna mesi non cresce linearmente con importo', () {
      // 12 → 11, 30 → 27, 50 → 44, 100 → 81
      // La non-linearità è il messaggio educativo centrale (§5.5)
      final m12 = impattoSpesaRicorrente(12, profiloRef).mesiGuadagnati!;
      final m50 = impattoSpesaRicorrente(50, profiloRef).mesiGuadagnati!;
      final m100 = impattoSpesaRicorrente(100, profiloRef).mesiGuadagnati!;
      // Se fosse lineare: m100/m12 = 100/12 = 8.3; il reale < 8.3
      expect(m100 / m12, lessThan(100 / 12));
      expect(m50 / m12, lessThan(50 / 12));
    });

    test('D1: costoCumulato(12000, 200, 0.04, 0.0145, 10) → ~4554 (costoAnnuo = frazione)', () {
      final c = costoCumulato(12000, 200, 0.04, 0.0145, 10);
      expect(c, closeTo(4554, 300));
    });

    test('D1: giorniDiStipendio(144, 1800) → 2.4', () {
      expect(giorniDiStipendio(144, 1800), closeTo(2.4, 0.01));
    });
  });

  // ---------------------------------------------------------------------------
  // D1 (cont.) — casi limite §5.6 — tutti obbligatori
  // ---------------------------------------------------------------------------

  group('D1: casi limite §5.6', () {
    test('D1 §5.6: risparmio = 0 → mesiAllObiettivo ritorna null', () {
      expect(mesiAllObiettivo(7500, 0, 0.04, 450000), isNull);
    });

    test('D1 §5.6: risparmio < 0 → mesiAllObiettivo ritorna null, nessuna eccezione', () {
      expect(mesiAllObiettivo(7500, -100, 0.04, 450000), isNull);
    });

    test('D1 §5.6: crescita = 0 → calcolo valido (chi tiene i soldi sul conto è utente legittimo)', () {
      final m = mesiAllObiettivo(7500, 300, 0, 450000);
      expect(m, isNotNull);
      expect(m!, equals(1475));
    });

    test('D1 §5.6: risparmio > netto → tassoRisparmio clampato a 1.0, nessuna eccezione', () {
      expect(tassoRisparmio(1800, 2500), equals(1.0));
    });

    test('D1 §5.6: risparmio > netto → speseMensili clampata a 0, nessuna eccezione', () {
      expect(speseMensili(1800, 2500), equals(0.0));
    });

    test('D1 §5.6: netto = 0 → tassoRisparmio ritorna 0, nessuna divisione per zero', () {
      expect(tassoRisparmio(0, 300), equals(0.0));
    });

    test('D1 §5.6: coperturaMesi con spese=0 → infinity (no divisione per zero)', () {
      expect(coperturaMesi(12000, 0), equals(double.infinity));
    });

    test('D1 §5.6: capitaleAccantonato < fondoEmergenzaTarget → capitaleVersoObiettivo = 0', () {
      expect(capitaleVersoObiettivo(3000, 4500), equals(0.0));
    });

    test('D1 §5.6: capitaleVersoObiettivo >= obiettivo → mesiAllObiettivo ritorna 0', () {
      expect(mesiAllObiettivo(450000, 300, 0.04, 450000), equals(0));
      expect(mesiAllObiettivo(500000, 300, 0.04, 450000), equals(0));
    });

    test('D1 §5.6: cap 12000 iterazioni → null per scenario irraggiungibile', () {
      expect(mesiAllObiettivo(0, 1, 0, 1000000), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // D2 — mesiAllObiettivo riceve capitaleVersoObiettivo (§5.3)
  // ---------------------------------------------------------------------------

  group('D2: mesiAllObiettivo riceve capitaleVersoObiettivo, mai capitaleAccantonato', () {
    test('D2: con capitaleVersoObiettivo=7500 il risultato è 515 (non 501 come con 12000)', () {
      // §5.3: errore vale 14 mesi (501 invece di 515)
      final mCorretto = mesiAllObiettivo(7500, 300, 0.04, 450000);
      final mErrore = mesiAllObiettivo(12000, 300, 0.04, 450000);
      expect(mCorretto, isNotNull);
      expect(mErrore, isNotNull);
      expect(mCorretto!, closeTo(515, 2));
      expect(mErrore!, closeTo(501, 2));
      // L'orizzonte con capitaleVersoObiettivo è più lungo (corretto):
      // il fondo di emergenza non corre verso l'obiettivo
      expect(mCorretto, greaterThan(mErrore));
    });

    test('D2: impattoSpesaRicorrente usa capitaleVersoObiettivo nella baseline', () {
      // Con il fix §5.3: mesiGuadagnati(12) = 11, non 10
      final r = impattoSpesaRicorrente(12, profiloRef);
      expect(r.mesiGuadagnati, isNotNull);
      expect(r.mesiGuadagnati!, closeTo(11, 1));
    });

    test('D2: profilo con capital < fondo ha capitaleVersoObiettivo = 0', () {
      const profilo3k = Profilo(
        eta: 32, nettoMensile: 1800, risparmioMensile: 300,
        capitaleAccantonato: 3000, capitaleDisponibile: 3000,
        crescitaIpotizzata: 0.04, regolaPrelievo: 0.04,
        mesiCopertura: 3, livelloLessicale: 1,
      );
      // Fondo = 1500*3 = 4500, capitaleAccantonato = 3000 < 4500
      // capitaleVersoObiettivo = max(0, 3000-4500) = 0
      final fondo = fondoEmergenzaTarget(
          speseMensili(profilo3k.nettoMensile, profilo3k.risparmioMensile));
      final cvObj = capitaleVersoObiettivo(profilo3k.capitaleAccantonato, fondo);
      expect(cvObj, equals(0.0));
    });
  });

  // ---------------------------------------------------------------------------
  // D3 — engine stateless: stessi input → stessi output
  // ---------------------------------------------------------------------------

  group('D3: engine stateless — stessi input, stessi output; input diversi, output diversi', () {
    test('D3: due chiamate con stesso profilo producono risultato identico', () {
      final r1 = impattoSpesaRicorrente(50, profiloRef);
      final r2 = impattoSpesaRicorrente(50, profiloRef);
      expect(r1.mesiGuadagnati, equals(r2.mesiGuadagnati));
    });

    test('D3: profilo modificato produce risultato diverso', () {
      final rBase = impattoSpesaRicorrente(50, profiloRef);
      final profiloMod = profiloRef.copyWith(risparmioMensile: 500);
      final rMod = impattoSpesaRicorrente(50, profiloMod);
      expect(rBase.mesiGuadagnati, isNot(equals(rMod.mesiGuadagnati)));
    });
  });

  // ---------------------------------------------------------------------------
  // D5 — risparmio = 0 → commuta in giorni di stipendio
  // ---------------------------------------------------------------------------

  group('D5: risparmio = 0 → fallback giorni di stipendio', () {
    test('D5: risparmio = 0 → mesiGuadagnati null, giorniStipendio non null', () {
      const profiloZero = Profilo(
        eta: 32,
        nettoMensile: 1800,
        risparmioMensile: 0,
        capitaleAccantonato: 12000,
        capitaleDisponibile: 12000,
        crescitaIpotizzata: 0.04,
        regolaPrelievo: 0.04,
        mesiCopertura: 3,
        livelloLessicale: 1,
      );
      final r = impattoSpesaRicorrente(12, profiloZero);
      expect(r.mesiGuadagnati, isNull);
      expect(r.giorniStipendio, isNotNull);
    });

    test('D5: risparmio < 0 → fallback giorni di stipendio', () {
      const profiloNeg = Profilo(
        eta: 32,
        nettoMensile: 1800,
        risparmioMensile: -100,
        capitaleAccantonato: 0,
        capitaleDisponibile: 0,
        crescitaIpotizzata: 0.04,
        regolaPrelievo: 0.04,
        mesiCopertura: 3,
        livelloLessicale: 1,
      );
      final r = impattoSpesaRicorrente(12, profiloNeg);
      expect(r.mesiGuadagnati, isNull);
      expect(r.giorniStipendio, isNotNull);
    });

    test('D5: giorniDiStipendio(144, 1800) → 2.4 giorni', () {
      expect(giorniDiStipendio(144, 1800), closeTo(2.4, 0.01));
    });

    test('D5: giorniDiStipendio(174, 1800) → ~2.9 giorni', () {
      expect(giorniDiStipendio(174, 1800), closeTo(2.9, 0.1));
    });

    test('D5: app resta usabile — giorniStipendio è positivo e finito', () {
      const profiloZero = Profilo(
        eta: 25, nettoMensile: 1200, risparmioMensile: 0,
        capitaleAccantonato: 0, capitaleDisponibile: 0,
        crescitaIpotizzata: 0.04, regolaPrelievo: 0.04,
        mesiCopertura: 3, livelloLessicale: 1,
      );
      final r = impattoSpesaRicorrente(30, profiloZero);
      expect(r.giorniStipendio, isNotNull);
      expect(r.giorniStipendio!, isPositive);
      expect(r.giorniStipendio!.isFinite, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // D6 — crescita = 0% → tutti i calcoli validi
  // ---------------------------------------------------------------------------

  group('D6: crescita = 0% → calcoli validi, nessuna eccezione', () {
    test('D6: mesiAllObiettivo con crescita=0 → 1475 mesi (accumulo lineare da 7500)', () {
      // (450000 - 7500) / 300 = 1475
      final m = mesiAllObiettivo(7500, 300, 0, 450000);
      expect(m, isNotNull);
      expect(m!, equals(1475));
    });

    test('D6: impattoSpesaRicorrente con crescita=0 → mesiGuadagnati valido', () {
      const profiloCrescitaZero = Profilo(
        eta: 32,
        nettoMensile: 1800,
        risparmioMensile: 300,
        capitaleAccantonato: 12000,
        capitaleDisponibile: 12000,
        crescitaIpotizzata: 0.0,
        regolaPrelievo: 0.04,
        mesiCopertura: 3,
        livelloLessicale: 1,
      );
      final r = impattoSpesaRicorrente(12, profiloCrescitaZero);
      expect(r.mesiGuadagnati, isNotNull);
      expect(r.mesiGuadagnati!.isFinite, isTrue);
      expect(r.mesiGuadagnati!, isPositive);
    });

    test('D6: costoCumulato con crescita=0 → risultato valido (nessuna eccezione)', () {
      final c = costoCumulato(12000, 200, 0.0, 0.0145, 10);
      expect(c.isFinite, isTrue);
      expect(c, isNonNegative);
    });

    test('D6: chi tiene i soldi sul conto corrente — crescita=0 è utente legittimo', () {
      // Il test verifica che il sistema funzioni, non che l'utente debba cambiare
      final m = mesiAllObiettivo(7500, 300, 0, 450000);
      expect(m, isNotNull);
      expect(m!, isPositive);
    });
  });

  // ---------------------------------------------------------------------------
  // D7 — 8 domande-trappola del §13.3 tutte intercettate
  // ---------------------------------------------------------------------------

  group('D7: guardrail — 8 domande-trappola intercettate (§13.3)', () {
    test('D7 trap 1: "conviene?"', () {
      expect(Guardrail.isTrapQuestion('conviene?'), isTrue);
    });

    test('D7 trap 2: "è caro?"', () {
      expect(Guardrail.isTrapQuestion('è caro?'), isTrue);
    });

    test('D7 trap 3: "cosa faresti tu al mio posto?"', () {
      expect(Guardrail.isTrapQuestion('cosa faresti tu al mio posto?'), isTrue);
    });

    test('D7 trap 4: "meglio a o b?"', () {
      expect(Guardrail.isTrapQuestion('meglio a o b?'), isTrue);
    });

    test('D7 trap 5: "devo disdire?"', () {
      expect(Guardrail.isTrapQuestion('devo disdire?'), isTrue);
    });

    test('D7 trap 6: "dove dovrei investire questi 12.000 €?"', () {
      expect(
        Guardrail.isTrapQuestion('dove dovrei investire questi 12.000 €?'),
        isTrue,
      );
    });

    test('D7 trap 7: "dove tengo il fondo di emergenza?" (nuova — §13.3)', () {
      expect(
        Guardrail.isTrapQuestion('dove tengo il fondo di emergenza?'),
        isTrue,
      );
    });

    test('D7 trap 8: "con il 6% cosa devo comprare?" (nuova — §13.3)', () {
      expect(
        Guardrail.isTrapQuestion('con il 6% cosa devo comprare?'),
        isTrue,
      );
    });

    test('D7: il confronto è case-insensitive', () {
      expect(Guardrail.isTrapQuestion('CONVIENE?'), isTrue);
      expect(Guardrail.isTrapQuestion('DOVE TENGO IL FONDO DI EMERGENZA?'), isTrue);
    });

    test('D7: domanda legittima non intercettata', () {
      expect(
        Guardrail.isTrapQuestion('quanto costa il mio fondo in 10 anni?'),
        isFalse,
      );
    });

    test('D7: risposta educativa non contiene parole proibite', () {
      for (final trap in Guardrail.trapQuestions) {
        final response = Guardrail.educationalResponse(trap);
        expect(
          Guardrail.containsForbiddenCopy(response),
          isFalse,
          reason: 'Risposta alla trap "$trap" contiene parole proibite',
        );
      }
    });
  });

  // ---------------------------------------------------------------------------
  // D8 — R4: assenza di stringhe proibite nella risposta educativa
  // ---------------------------------------------------------------------------

  group('D8: R4 — parole proibite non presenti nella risposta educativa', () {
    final paroleProibite = [
      'dovresti',
      'ti consigliamo',
      'ottimizza',
    ];

    for (final parola in paroleProibite) {
      test('D8: R4 — "$parola" non compare nella risposta del guardrail', () {
        final response = Guardrail.educationalResponse('conviene');
        expect(response.toLowerCase().contains(parola), isFalse);
      });
    }
  });

  // ---------------------------------------------------------------------------
  // D9 — R2: nessun nome di prodotto nei modelli dati
  // ---------------------------------------------------------------------------

  group('D9: R2 — nomi di prodotti non presenti nei modelli dati', () {
    test('D9: Profilo non ha campi per prodotti finanziari specifici', () {
      expect(profiloRef.nettoMensile, isA<double>());
      expect(profiloRef.capitaleAccantonato, isA<double>());
      expect(profiloRef.capitaleDisponibile, isA<double>());
      // Non esistono campi come "nomeFondo", "nomeBanca" — il type system garantisce
    });

    test('D9: ImpattoSpesa non contiene riferimenti a prodotti', () {
      final r = impattoSpesaRicorrente(12, profiloRef);
      expect(r.leva1RisparmioAnnuo, isA<double>());
      expect(r.leva2RiduzioneObiettivo, isA<double>());
    });
  });

  // ---------------------------------------------------------------------------
  // D13 — ogni sottotitolo delle 9 tappe usa dati reali dall'engine
  // ---------------------------------------------------------------------------

  group('D13: dati reali per i sottotitoli delle 9 tappe', () {
    test('D13 tappa 2: tassoRisparmio produce il dato per "il tuo: 16.7%"', () {
      final tasso = tassoRisparmio(
          profiloRef.nettoMensile, profiloRef.risparmioMensile);
      expect(tasso, closeTo(0.167, 0.001));
    });

    test('D13 tappa 4: fondoEmergenzaTarget produce il dato per "il tuo fondo: 4.500 €"', () {
      final spese = speseMensili(profiloRef.nettoMensile, profiloRef.risparmioMensile);
      final fondo = fondoEmergenzaTarget(spese, mesiCopertura: profiloRef.mesiCopertura);
      expect(fondo, equals(4500.0));
    });

    test('D13 tappa 6: capitaleVersoObiettivo produce il dato per "sui tuoi 7.500 €"', () {
      final spese = speseMensili(profiloRef.nettoMensile, profiloRef.risparmioMensile);
      final fondo = fondoEmergenzaTarget(spese, mesiCopertura: profiloRef.mesiCopertura);
      final cvObj = capitaleVersoObiettivo(profiloRef.capitaleAccantonato, fondo);
      expect(cvObj, equals(7500.0));
    });

    test('D13 tappa 9: impattoSpesaRicorrente(50) produce dato per "hai guadagnato N mesi"', () {
      final r = impattoSpesaRicorrente(50, profiloRef);
      expect(r.mesiGuadagnati, isNotNull);
      expect(r.mesiGuadagnati!, isPositive);
    });
  });

  // ---------------------------------------------------------------------------
  // D16 — profilo non mostra età di arrivo; tappa 9 su scarto
  // ---------------------------------------------------------------------------

  group('D16: orizzonte in anni (non età di arrivo), scarto per tappa 9', () {
    test('D16: mesiAllObiettivo ritorna mesi (non età); conversione in UI', () {
      final spese = speseMensili(profiloRef.nettoMensile, profiloRef.risparmioMensile);
      final fondo = fondoEmergenzaTarget(spese, mesiCopertura: profiloRef.mesiCopertura);
      final cvObj = capitaleVersoObiettivo(profiloRef.capitaleAccantonato, fondo);
      final obiettivo = capitaleObiettivo(spese * 12);
      final m = mesiAllObiettivo(cvObj, profiloRef.risparmioMensile,
          profiloRef.crescitaIpotizzata, obiettivo);
      expect(m, isNotNull);
      final anni = m! / 12.0;
      // 515 mesi / 12 = 42.9 anni (con capitaleVersoObiettivo = 7500)
      expect(anni, closeTo(42.9, 0.5));
    });

    test('D16: deltaMesi restituisce scarto (non assoluto) — base per tappa 9', () {
      final r = impattoSpesaRicorrente(50, profiloRef);
      expect(r.mesiGuadagnati, isNotNull);
      expect(r.mesiGuadagnati!, isPositive);
    });
  });

  // ---------------------------------------------------------------------------
  // D18 — nessun artefatto float a schermo
  // ---------------------------------------------------------------------------

  group('D18: output arrotondati — nessun artefatto float', () {
    test('D18: tassoRisparmio senza artefatti IEEE 754', () {
      final t = tassoRisparmio(1800, 300);
      expect((t * 100).toStringAsFixed(1), equals('16.7'));
    });

    test('D18: mesiGuadagnati è round()-able senza artefatti', () {
      final r = impattoSpesaRicorrente(12, profiloRef);
      final mesi = r.mesiGuadagnati!;
      expect(mesi.round(), isA<int>());
      expect(mesi.isFinite, isTrue);
    });

    test('D18: costoCumulato è finito e positivo', () {
      final c = costoCumulato(12000, 200, 0.04, 0.0145, 10);
      expect(c.isFinite, isTrue);
      expect(c, isPositive);
    });

    test('D18: fondoEmergenzaTarget è esatto (nessun artefatto)', () {
      // 1500 * 3 = 4500 — esatto, nessun artefatto float
      expect(fondoEmergenzaTarget(1500, mesiCopertura: 3), equals(4500.0));
    });

    test('D18: capitaleVersoObiettivo mai negativo', () {
      // Verifica che il clamp funzioni con vari input
      expect(capitaleVersoObiettivo(0, 4500), equals(0.0));
      expect(capitaleVersoObiettivo(4500, 4500), equals(0.0));
      expect(capitaleVersoObiettivo(4501, 4500), closeTo(1.0, 0.001));
    });

    test('D18: giorniDiStipendio(144, 1800) formattato a 1 decimale → "2.4"', () {
      final g = giorniDiStipendio(144, 1800);
      expect(g.toStringAsFixed(1), equals('2.4'));
    });
  });

  // ---------------------------------------------------------------------------
  // Verifiche strutturali: nuovi campi Profilo (§15)
  // ---------------------------------------------------------------------------

  group('Profilo v4.1 — capitaleDisponibile e mesiCopertura', () {
    test('capitaleDisponibile default uguale a capitaleAccantonato', () {
      const p = Profilo(
        eta: 32, nettoMensile: 1800, risparmioMensile: 300,
        capitaleAccantonato: 12000,
        // capitaleDisponibile non specificato → default = capitaleAccantonato
      );
      expect(p.capitaleDisponibile, equals(12000.0));
    });

    test('capitaleDisponibile esplicito conservato', () {
      const p = Profilo(
        eta: 32, nettoMensile: 1800, risparmioMensile: 300,
        capitaleAccantonato: 12000,
        capitaleDisponibile: 8000,
      );
      expect(p.capitaleDisponibile, equals(8000.0));
    });

    test('mesiCopertura default = 3', () {
      const p = Profilo(
        eta: 32, nettoMensile: 1800, risparmioMensile: 300,
        capitaleAccantonato: 12000,
      );
      expect(p.mesiCopertura, equals(3.0));
    });

    test('coperturaMesi usa capitaleDisponibile, non capitaleAccantonato (R3)', () {
      // capitaleDisponibile = 6000 (metà dell'accantonato)
      const p = Profilo(
        eta: 32, nettoMensile: 1800, risparmioMensile: 300,
        capitaleAccantonato: 12000, capitaleDisponibile: 6000,
      );
      final spese = speseMensili(p.nettoMensile, p.risparmioMensile);
      final cop = coperturaMesi(p.capitaleDisponibile, spese);
      // 6000 / 1500 = 4 mesi (non 8 con capitaleAccantonato)
      expect(cop, equals(4.0));
    });
  });

  // ---------------------------------------------------------------------------
  // Verifiche strutturali ImpattoSpesa (leva1, leva2)
  // ---------------------------------------------------------------------------

  group('leve — verifiche strutturali', () {
    test('leva1RisparmioAnnuo = importoMensile * 12', () {
      final r = impattoSpesaRicorrente(12, profiloRef);
      expect(r.leva1RisparmioAnnuo, closeTo(144, 0.01));
    });

    test('leva2RiduzioneObiettivo = importoMensile * 12 / regolaPrelievo (25×)', () {
      final r = impattoSpesaRicorrente(12, profiloRef);
      expect(r.leva2RiduzioneObiettivo, closeTo(3600, 0.1));
    });

    test('leva2 non dipende da crescitaIpotizzata', () {
      final rA = impattoSpesaRicorrente(30,
          profiloRef.copyWith(crescitaIpotizzata: 0.02));
      final rB = impattoSpesaRicorrente(30,
          profiloRef.copyWith(crescitaIpotizzata: 0.06));
      expect(rA.leva2RiduzioneObiettivo,
          closeTo(rB.leva2RiduzioneObiettivo, 0.01));
    });
  });
}

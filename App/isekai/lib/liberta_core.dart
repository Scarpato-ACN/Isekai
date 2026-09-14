/// liberta_core — engine deterministico per "Mesi di Libertà"
///
/// Modulo puro: zero dipendenze Flutter, zero accessi a rete o storage.
/// Unica fonte di tutti i numeri mostrati all'utente (R1).
/// Ogni funzione ha test unitari in test/liberta_core_test.dart.
library;

import 'dart:math';

// ---------------------------------------------------------------------------
// Modelli dati
// ---------------------------------------------------------------------------

/// Profilo dell'utente. Campo primario: [risparmioMensile] (quanto resta a
/// fine mese), non le spese. Le spese sono un valore derivato ([speseMensili]).
///
/// [capitaleAccantonato] non porta alcun attributo di collocazione (R3).
/// [capitaleDisponibile] è la quota liquidabile senza penali — proprietà
///   funzionale dichiarata dall'utente, non uno strumento (§8.2).
///   Default = [capitaleAccantonato] se non specificato.
/// [mesiCopertura] numero di mesi del fondo di emergenza target (default 3).
/// [crescitaIpotizzata] default 0.04: ipotesi dichiarata, modificabile.
/// [regolaPrelievo] default 0.04: convenzione didattica, non una previsione.
class Profilo {
  final int eta;
  final double nettoMensile;
  final double risparmioMensile;
  final double capitaleAccantonato;
  final double capitaleDisponibile;
  final double crescitaIpotizzata;
  final double regolaPrelievo;
  final double mesiCopertura;
  final int livelloLessicale;

  const Profilo({
    required this.eta,
    required this.nettoMensile,
    required this.risparmioMensile,
    this.capitaleAccantonato = 0,
    double? capitaleDisponibile,
    this.crescitaIpotizzata = 0.04,
    this.regolaPrelievo = 0.04,
    this.mesiCopertura = 3,
    this.livelloLessicale = 1,
  }) : capitaleDisponibile = capitaleDisponibile ?? capitaleAccantonato;

  Profilo copyWith({
    int? eta,
    double? nettoMensile,
    double? risparmioMensile,
    double? capitaleAccantonato,
    double? capitaleDisponibile,
    double? crescitaIpotizzata,
    double? regolaPrelievo,
    double? mesiCopertura,
    int? livelloLessicale,
  }) {
    return Profilo(
      eta: eta ?? this.eta,
      nettoMensile: nettoMensile ?? this.nettoMensile,
      risparmioMensile: risparmioMensile ?? this.risparmioMensile,
      capitaleAccantonato: capitaleAccantonato ?? this.capitaleAccantonato,
      capitaleDisponibile: capitaleDisponibile ?? this.capitaleDisponibile,
      crescitaIpotizzata: crescitaIpotizzata ?? this.crescitaIpotizzata,
      regolaPrelievo: regolaPrelievo ?? this.regolaPrelievo,
      mesiCopertura: mesiCopertura ?? this.mesiCopertura,
      livelloLessicale: livelloLessicale ?? this.livelloLessicale,
    );
  }
}

/// Risultato di [impattoSpesaRicorrente] — il doppio effetto di una spesa fissa.
///
/// [leva1RisparmioAnnuo]: importo annuo non accumulato (importoMensile × 12).
/// [leva2RiduzioneObiettivo]: riduzione del capitale obiettivo (25× leva1).
///   Non dipende da nessuna ipotesi di rendimento: è pura moltiplicazione.
/// [mesiGuadagnati]: delta in mesi tra baseline e scenario con taglio.
///   null quando [risparmioMensile] del profilo è ≤ 0.
/// [giorniStipendio]: unità di fallback quando mesiGuadagnati è null.
class ImpattoSpesa {
  final double leva1RisparmioAnnuo;
  final double leva2RiduzioneObiettivo;
  final double? mesiGuadagnati;
  final double? giorniStipendio;

  const ImpattoSpesa({
    required this.leva1RisparmioAnnuo,
    required this.leva2RiduzioneObiettivo,
    this.mesiGuadagnati,
    this.giorniStipendio,
  });
}

// ---------------------------------------------------------------------------
// Funzioni pubbliche dell'engine
// ---------------------------------------------------------------------------

/// Tasso di risparmio: risparmioMensile / nettoMensile.
///
/// Restituisce 0.0 se [nettoMensile] ≤ 0.
/// [risparmioMensile] viene clampato a [nettoMensile] prima del calcolo
/// (caso risparmio > netto).
double tassoRisparmio(double nettoMensile, double risparmioMensile) {
  if (nettoMensile <= 0) return 0.0;
  final r = risparmioMensile.clamp(0.0, nettoMensile);
  return r / nettoMensile;
}

/// Spese mensili stimate: nettoMensile − risparmioMensile.
///
/// Non scende sotto zero (clamp): se risparmio > netto, spese = 0.
double speseMensili(double nettoMensile, double risparmioMensile) {
  final r = risparmioMensile.clamp(0.0, nettoMensile);
  return nettoMensile - r;
}

/// Target del fondo di emergenza: speseMensili × mesiCopertura.
///
/// [mesiCopertura] default 3 — convenzione dichiarata, non regola assoluta.
/// È la cifra che permette di coprire gli imprevisti senza intaccare
/// il percorso verso l'obiettivo (§8.1 del brief).
double fondoEmergenzaTarget(double spese, {double mesiCopertura = 3}) {
  return spese * mesiCopertura;
}

/// Mesi di copertura: capitaleDisponibile / speseMensili.
///
/// Protetto dalla divisione per zero: restituisce [double.infinity] se
/// le spese sono ≤ 0. Usa [capitaleDisponibile] (quota liquidabile), non
/// il totale accantonato (§8.2 del brief).
double coperturaMesi(double capitaleDisponibile, double spese) {
  if (spese <= 0) return double.infinity;
  return capitaleDisponibile / spese;
}

/// Capitale che corre effettivamente verso l'obiettivo.
///
/// = max(0, capitaleAccantonato − fondoEmergenzaTarget).
/// MAI negativo: il fondo di emergenza è un cuscinetto fermo, non capitale
/// in avvicinamento al traguardo (§5.3 del brief).
double capitaleVersoObiettivo(
    double capitaleAccantonato, double fondoTarget) {
  return (capitaleAccantonato - fondoTarget).clamp(0.0, double.infinity);
}

/// Capitale obiettivo secondo la regola convenzionale del prelievo sostenibile.
///
/// [speseAnnuali] / [regolaPrelievo] — con regola 0.04 il risultato è 25×
/// la spesa annuale. Presentato come convenzione didattica, non come verità.
///
/// Il chiamante passa [speseAnnuali] = speseMensili × 12.
double capitaleObiettivo(double speseAnnuali, {double regolaPrelievo = 0.04}) {
  if (regolaPrelievo <= 0) return double.infinity;
  return speseAnnuali / regolaPrelievo;
}

/// Mesi necessari per raggiungere [obiettivo] partendo da [capitaleVersoObiettivo]
/// con versamento mensile [risparmioMensile] e crescita annua [crescitaAnnua].
///
/// IMPORTANTE (§5.3): il primo parametro è [capitaleVersoObiettivo], mai
/// [capitaleAccantonato]. Il fondo di emergenza non corre verso il traguardo.
///
/// Algoritmo iterativo:
///   saldo = saldo × (1 + crescitaAnnua/12) + risparmioMensile
/// Conta i mesi fino a saldo ≥ obiettivo. Cap a 12000 iterazioni → null.
///
/// Restituisce 0 se capitaleVersoObiettivo ≥ obiettivo.
/// Restituisce null se risparmioMensile ≤ 0 o se non converge entro 12000 mesi.
int? mesiAllObiettivo(
  double capitaleVersoObiettivo,
  double risparmioMensile,
  double crescitaAnnua,
  double obiettivo,
) {
  if (capitaleVersoObiettivo >= obiettivo) return 0;
  if (risparmioMensile <= 0) return null;

  final double rMensile = crescitaAnnua / 12;
  double saldo = capitaleVersoObiettivo;
  for (int mese = 1; mese <= 12000; mese++) {
    saldo = saldo * (1 + rMensile) + risparmioMensile;
    if (saldo >= obiettivo) return mese;
  }
  return null;
}

/// Costo cumulato di una commissione ricorrente su un orizzonte pluriennale.
///
/// [costoAnnuo] è una **frazione** (es. 0.0145 per 1,45%), non un importo euro.
/// Formula: FV(crescita 0%) − FV(crescita − costoAnnuo), con versamento mensile.
///
/// Misura quanto patrimonio viene trattenuto dalla commissione nel periodo.
double costoCumulato(
  double capitale,
  double versamentoMensile,
  double crescitaAnnua,
  double costoAnnuo,
  int anni,
) {
  final double tassoLordoMensile = crescitaAnnua / 12;
  final double tassoNettoMensile = (crescitaAnnua - costoAnnuo) / 12;
  final int n = anni * 12;
  final double fvLordo = _fv(capitale, versamentoMensile, tassoLordoMensile, n);
  final double fvNetto = _fv(capitale, versamentoMensile, tassoNettoMensile, n);
  return fvLordo - fvNetto;
}

/// Doppio effetto di una spesa fissa ricorrente sul percorso di libertà.
///
/// Calcola le due leve e i mesi guadagnati dal taglio di [importoMensile].
///
/// La baseline usa [capitaleVersoObiettivo] (non [capitaleAccantonato] — §5.3).
/// Il taglio riduce [speseMensili], che ricalcola a cascata:
///   fondoEmergenzaTarget → capitaleVersoObiettivo → capitaleObiettivo (§5.4).
///
/// Fallback automatico in giorni di stipendio quando [risparmioMensile] ≤ 0.
ImpattoSpesa impattoSpesaRicorrente(double importoMensile, Profilo profilo) {
  final double risparmio =
      profilo.risparmioMensile.clamp(0.0, profilo.nettoMensile);
  final double leva1 = importoMensile * 12;
  final double leva2 = leva1 / profilo.regolaPrelievo;

  // Fallback: l'unità "mesi di libertà" non è utilizzabile; si commuta a giorni
  if (risparmio <= 0) {
    return ImpattoSpesa(
      leva1RisparmioAnnuo: leva1,
      leva2RiduzioneObiettivo: leva2,
      mesiGuadagnati: null,
      giorniStipendio: giorniDiStipendio(leva1, profilo.nettoMensile),
    );
  }

  final double spese = speseMensili(profilo.nettoMensile, risparmio);

  // Baseline — usa capitaleVersoObiettivo, mai capitaleAccantonato (§5.3)
  final double fondoBase =
      fondoEmergenzaTarget(spese, mesiCopertura: profilo.mesiCopertura);
  final double capVersoObiBase =
      capitaleVersoObiettivo(profilo.capitaleAccantonato, fondoBase);
  final double obBase =
      capitaleObiettivo(spese * 12, regolaPrelievo: profilo.regolaPrelievo);

  final int? mesiBase = mesiAllObiettivo(
    capVersoObiBase,
    risparmio,
    profilo.crescitaIpotizzata,
    obBase,
  );

  if (mesiBase == null) {
    return ImpattoSpesa(
      leva1RisparmioAnnuo: leva1,
      leva2RiduzioneObiettivo: leva2,
    );
  }

  // Scenario con taglio: ricalcola a cascata fondo ed obiettivo (§5.4)
  final double speseMensiliRidotte = spese - importoMensile;
  final double fondoRidotto = fondoEmergenzaTarget(speseMensiliRidotte,
      mesiCopertura: profilo.mesiCopertura);
  final double capVersoObiRidotto =
      capitaleVersoObiettivo(profilo.capitaleAccantonato, fondoRidotto);
  final double obiettivoRidotto = capitaleObiettivo(speseMensiliRidotte * 12,
      regolaPrelievo: profilo.regolaPrelievo);

  final int? mesiRidottoNullable =
      capVersoObiRidotto >= obiettivoRidotto
          ? 0
          : mesiAllObiettivo(
              capVersoObiRidotto,
              risparmio + importoMensile,
              profilo.crescitaIpotizzata,
              obiettivoRidotto,
            );

  final int mesiRidotto = mesiRidottoNullable ?? 0;

  return ImpattoSpesa(
    leva1RisparmioAnnuo: leva1,
    leva2RiduzioneObiettivo: leva2,
    mesiGuadagnati: deltaMesi(mesiBase.toDouble(), mesiRidotto.toDouble()),
    giorniStipendio: null,
  );
}

/// Converte un importo annuo in giorni di stipendio netto.
///
/// Netto giornaliero = nettoMensile / 30.
/// Unità di fallback quando il risparmio è ≤ 0 (§8.4).
///
/// Esempio: giorniDiStipendio(144, 1800) = 2.4 giorni
double giorniDiStipendio(double importoAnnuo, double nettoMensile) {
  if (nettoMensile <= 0) return 0.0;
  return importoAnnuo / (nettoMensile / 30.0);
}

/// Delta tra due scenari in mesi: scenarioA − scenarioB.
///
/// Positivo se scenarioA richiede più mesi di scenarioB.
double deltaMesi(double scenarioA, double scenarioB) {
  return scenarioA - scenarioB;
}

// ---------------------------------------------------------------------------
// Funzioni private
// ---------------------------------------------------------------------------

/// Valore futuro di un investimento con versamento mensile costante.
///
/// FV = PV × (1+r)^n + PMT × ((1+r)^n − 1) / r
/// Con r = 0: FV = PV + PMT × n (accumulo lineare).
double _fv(double pv, double pmt, double r, int n) {
  if (r == 0) return pv + pmt * n;
  final double growth = pow(1 + r, n).toDouble();
  return pv * growth + pmt * (growth - 1) / r;
}

/// guardrail — controllo educativo sul perimetro dell'app
///
/// Intercetta le richieste di consiglio o comparazione tra strumenti
/// e restituisce un reindirizzamento educativo invece di una raccomandazione.
///
/// La risposta è testo fisso, non generato da LLM. I numeri non passano
/// da qui: vengono solo dall'engine in liberta_core.dart.
library;

class Guardrail {
  Guardrail._();

  /// Le 8 domande-trappola da §13.3 del brief.
  /// Lista chiusa: il test automatico usa queste fixture esatte (D7).
  /// Le ultime due (7 e 8) presidiano le porte di ingresso create dalle
  /// nuove feature: fondo di emergenza e slider di crescita.
  static const List<String> trapQuestions = [
    'conviene',
    'è caro',
    'cosa faresti tu al mio posto',
    'meglio a o b',
    'devo disdire',
    'dove dovrei investire',
    'dove tengo il fondo di emergenza',
    'cosa devo comprare',
  ];

  /// Restituisce true se [input] corrisponde a una domanda-trappola.
  /// Confronto case-insensitive, per sottostringa.
  static bool isTrapQuestion(String input) {
    final normalized = input.toLowerCase().trim();
    for (final trap in trapQuestions) {
      if (normalized.contains(trap)) return true;
    }
    return false;
  }

  /// Parole che l'app non deve mai produrre in output (R4).
  static const List<String> forbiddenCopy = [
    'dovresti',
    'ti consigliamo',
    'ottimizza',
  ];

  /// Restituisce true se [text] contiene una stringa proibita (R4).
  /// Confronto case-insensitive.
  static bool containsForbiddenCopy(String text) {
    final normalized = text.toLowerCase();
    for (final word in forbiddenCopy) {
      if (normalized.contains(word)) return true;
    }
    return false;
  }

  /// Risposta educativa fissa per le domande-trappola (§13.3).
  ///
  /// Non contiene raccomandazioni, preferenze o comparazioni.
  /// Non genera numeri. Restituisce la decisione all'utente.
  static String educationalResponse(String trapQuestion) {
    return 'Questo dipende da cose che non conosco e che riguardano solo te: '
        'quanto ti serve quel denaro, quando, e quanto ti pesa il rischio. '
        'Quello che posso fare è insegnarti a leggere il costo — '
        'così la domanda la porti tu, precisa, a chi di dovere. '
        'Vuoi che ti mostri quali tre numeri guardare?';
  }
}

// Widget smoke test — verifica che l'app si avvii senza crash
// e che, dopo la splash screen, la schermata di avvio sia Percorso.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isekai/main.dart';

void main() {
  // Avanza il timer fittizio oltre i 2500 ms della SplashScreen
  // per far atterrare l'app su AppShell prima di cercare i widget.
  Future<void> pumpPastSplash(WidgetTester tester) async {
    await tester.pumpWidget(const IsekaiApp());
    await tester.pump(); // primo frame (SplashScreen visibile)
    await tester.pump(const Duration(milliseconds: 2600)); // scatta il timer → OnboardingScreen
    await tester.pumpAndSettle(); // completa navigazione
    // Salta l'onboarding per arrivare ad AppShell
    final saltaButton = find.text('Salta');
    if (saltaButton.evaluate().isNotEmpty) {
      await tester.tap(saltaButton.first);
      await tester.pumpAndSettle();
    }
  }

  testWidgets('app si avvia e mostra la schermata Percorso', (tester) async {
    await pumpPastSplash(tester);
    // La schermata di avvio è Percorso (§3 del brief: "Schermata di avvio: Percorso")
    expect(find.text('Percorso'), findsWidgets);
  });

  testWidgets('BottomNavigationBar ha 5 voci', (tester) async {
    await pumpPastSplash(tester);
    expect(find.text('Simulatore'), findsOneWidget);
    expect(find.text('Uscite'), findsOneWidget);
    expect(find.text('Progressi'), findsOneWidget);
    expect(find.text('Profilo'), findsOneWidget);
  });
}

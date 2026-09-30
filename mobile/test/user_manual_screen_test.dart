import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronomed/features/manual/screens/user_manual_screen.dart';

void main() {
  testWidgets('UserManualScreen renders header, search and all chapters', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: UserManualScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify AppBar and header
    expect(find.text('Manual de Usuario'), findsOneWidget);
    expect(find.text('ChronoMed Guía Oficial'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Verify initial chapter titles
    expect(find.text('1. Marco Sanitario y Advertencias Legales'), findsOneWidget);
    expect(find.text('2. Guía de Uso: Modo Senior (Simple)'), findsOneWidget);
    expect(find.text('3. Bloqueo Anti-Sobredosis y Escalamiento'), findsOneWidget);
  });

  testWidgets('UserManualScreen search filters chapters dynamically', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: UserManualScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Search for "RUT"
    await tester.enterText(find.byType(TextField), 'RUT');
    await tester.pumpAndSettle();

    // Verify filtered result
    expect(find.textContaining('Resultados para "RUT"'), findsOneWidget);
    expect(find.text('6. Ajustes, RUT Módulo 11 y Gestión de PIN'), findsOneWidget);

    // Clear search using suffix icon button
    await tester.tap(find.byIcon(Icons.clear_rounded));
    await tester.pumpAndSettle();

    // Verify full list restored
    expect(find.text('1. Marco Sanitario y Advertencias Legales'), findsOneWidget);
  });

  testWidgets('UserManualScreen expansion reveals detailed section content', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: UserManualScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap to expand Chapter 1
    await tester.tap(find.text('1. Marco Sanitario y Advertencias Legales'));
    await tester.pumpAndSettle();

    // Verify detailed section subtitle appears
    expect(find.text('Ley N° 20.584 (Derechos y Deberes del Paciente)'), findsOneWidget);
    expect(find.text('Canal de Urgencia Vital: SAMU 131 y CITUC'), findsOneWidget);
  });

  testWidgets('UserManualScreen opens and closes SAMU emergency dialog', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: UserManualScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap SAMU button in AppBar
    await tester.tap(find.byIcon(Icons.emergency_rounded).first);
    await tester.pumpAndSettle();

    // Verify dialog content
    expect(find.text('Urgencias SAMU 131'), findsOneWidget);
    expect(find.text('SAMU: 131'), findsOneWidget);
    expect(find.text('CITUC UC: +56 2 2635 3800'), findsOneWidget);

    // Dismiss dialog
    await tester.tap(find.text('ENTENDIDO'));
    await tester.pumpAndSettle();

    expect(find.text('Urgencias SAMU 131'), findsNothing);
  });
}

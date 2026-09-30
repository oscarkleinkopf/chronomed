import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronomed/core/storage/local_storage_service.dart';
import 'package:chronomed/features/settings/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await LocalStorageService.instance.init(inMemory: true);
    await LocalStorageService.instance.resetAllData();
  });

  group('ChronoMed SettingsScreen Test Suite', () {
    testWidgets('Renders all configuration sections and initial patient values', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // AppBar
      expect(find.text('Configuración'), findsOneWidget);

      // Section 1: Datos del Paciente
      expect(find.text('Datos del Paciente'), findsOneWidget);
      expect(find.text('Marcela'), findsOneWidget);
      expect(find.text('14.567.890-K'), findsOneWidget);

      // Section 2: Modo Senior
      expect(find.text('Modo Senior'), findsOneWidget);
      expect(find.text('PIN de Cuidador actual'), findsOneWidget);
      expect(find.text('Cambiar PIN'), findsOneWidget);

      // Section 3: Datos
      expect(find.text('Datos'), findsOneWidget);
      expect(find.text('Restablecer todos los datos'), findsOneWidget);

      // Section 4: Acerca de
      expect(find.text('ChronoMed v1.0.0'), findsOneWidget);
      expect(find.text('Adherencia medicamentosa para adultos mayores'), findsOneWidget);
    });

    testWidgets('Updates patient name and RUT with Chilean format validation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find the name and RUT fields
      final nameFinder = find.widgetWithText(TextFormField, 'Marcela');
      final rutFinder = find.widgetWithText(TextFormField, '14.567.890-K');

      await tester.enterText(nameFinder, 'Roberto Gómez');
      await tester.enterText(rutFinder, '12.345.678-5');
      await tester.pumpAndSettle();

      // Tap Guardar cambios
      final saveButton = find.text('Guardar cambios');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify that LocalStorageService updated
      expect(LocalStorageService.instance.patientName, equals('Roberto Gómez'));
      expect(LocalStorageService.instance.patientRut, equals('12.345.678-5'));
    });

    testWidgets('Opens PIN change dialog and successfully updates caregiver PIN', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Cambiar PIN button
      final changePinButton = find.text('Cambiar PIN');
      await tester.tap(changePinButton);
      await tester.pumpAndSettle();

      // Dialog should be visible
      expect(find.text('Cambiar PIN'), findsNWidgets(2)); // Title and original button
      expect(find.text('Ingresa un nuevo PIN de 4 dígitos para acceder al Modo Cuidador y ajustes.'), findsOneWidget);

      // Find text fields inside the dialog
      final pinInputs = find.byType(TextFormField);
      // Last two TextFormFields are the ones in dialog
      expect(pinInputs, findsNWidgets(5));

      await tester.enterText(pinInputs.at(3), '9876');
      await tester.enterText(pinInputs.at(4), '9876');
      await tester.pumpAndSettle();

      // Tap Guardar in dialog
      final dialogSaveBtn = find.widgetWithText(ElevatedButton, 'Guardar');
      await tester.tap(dialogSaveBtn);
      await tester.pumpAndSettle();

      // Verify PIN updated in LocalStorage
      expect(LocalStorageService.instance.caregiverPin, equals('9876'));
    });

    testWidgets('Shows confirmation dialog before resetting all data', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll down and find the reset button
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      final resetBtn = find.text('Restablecer todos los datos');
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('¿Restablecer todos los datos?'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Sí, restablecer todo'), findsOneWidget);

      // Cancel dismissal
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('¿Restablecer todos los datos?'), findsNothing);
    });
  });
}

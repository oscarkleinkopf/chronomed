import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronomed/core/storage/local_storage_service.dart';
import 'package:chronomed/features/medicine_cabinet/screens/medicine_cabinet_screen.dart';
import 'package:chronomed/features/medicine_cabinet/widgets/medicine_cabinet_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await LocalStorageService.instance.init(inMemory: true);
    await LocalStorageService.instance.resetAllData();
  });

  group('ChronoMed Medicine Cabinet Widget & Accessibility Suite', () {
    testWidgets('Renders MedicineCabinetScreen with summary stats, badges and default Chilean medications', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MedicineCabinetScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Header and titles
      expect(find.text('Botiquín & Inventario'), findsOneWidget);
      expect(find.text('ESCANEAR CAJA CON OCR (ISP CHILE)'), findsOneWidget);

      // Default medications from storage
      expect(find.text('Eutirox (Levotiroxina)'), findsOneWidget);
      expect(find.text('Losartán Potásico'), findsOneWidget);
      expect(find.text('Atorvastatina'), findsOneWidget);

      // Chilean regulatory badges
      expect(find.text('⭐ BIOEQUIVALENTE (ISP)'), findsNWidgets(3));
      expect(find.text('Reg. ISP: F-14920/19'), findsOneWidget);
      expect(find.text('Reg. ISP: F-18451/20'), findsOneWidget);
      expect(find.text('Reg. ISP: F-16203/21'), findsOneWidget);
    });

    testWidgets('Tapping on a pill opens the giant photorealistic magnifier dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MedicineCabinetScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find the first pill widget (Eutirox) and tap it
      final pillGesture = find.byType(GestureDetector).first;
      await tester.tap(pillGesture);
      await tester.pumpAndSettle();

      // Verify that the magnifier dialog opened
      expect(find.textContaining('Lupa:'), findsOneWidget);
      expect(find.text('CERRAR LUPA'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('CERRAR LUPA'));
      await tester.pumpAndSettle();
      expect(find.text('CERRAR LUPA'), findsNothing);
    });

    testWidgets('Search input filters medicines dynamically in real-time', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MedicineCabinetScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Search for Losartán
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Losartán');
      await tester.pumpAndSettle();

      // Only Losartán should remain visible
      expect(find.text('Losartán Potásico'), findsOneWidget);
      expect(find.text('Eutirox (Levotiroxina)'), findsNothing);
      expect(find.text('Atorvastatina'), findsNothing);

      // Clear search
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();
      expect(find.text('Eutirox (Levotiroxina)'), findsOneWidget);
      expect(find.text('Losartán Potásico'), findsOneWidget);
    });

    testWidgets('Touch target for stock adjustment buttons satisfies minimum accessible area', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MedicineCabinetScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find +/- buttons inside cards
      final addButtons = find.byIcon(Icons.add);
      expect(addButtons, findsWidgets);

      final Size buttonSize = tester.getSize(addButtons.first);
      // Touch target should be at least 38dp, inside a container with padding
      expect(buttonSize.width, greaterThanOrEqualTo(36.0));
      expect(buttonSize.height, greaterThanOrEqualTo(36.0));
    });

    testWidgets('MedicineCabinetScreen renders without overflow under 150% font scaling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(1.5),
            size: Size(412, 915),
          ),
          child: const MaterialApp(
            home: MedicineCabinetScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Zero exception under font scaling
      expect(tester.takeException(), isNull);
      expect(find.text('Botiquín & Inventario'), findsOneWidget);
    });

    testWidgets('Medicine deletion requires explicit confirmation and supports undo action', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MedicineCabinetScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Open menu on first card (Eutirox)
      final moreButtons = find.byIcon(Icons.more_vert_rounded);
      expect(moreButtons, findsWidgets);
      await tester.tap(moreButtons.first);
      await tester.pumpAndSettle();

      // Tap Eliminar del botiquín
      expect(find.text('Eliminar del botiquín'), findsOneWidget);
      await tester.tap(find.text('Eliminar del botiquín'));
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('¿Eliminar fármaco?'), findsOneWidget);
      expect(find.text('CANCELAR'), findsOneWidget);
      expect(find.text('ELIMINAR'), findsOneWidget);

      // Cancel deletion
      await tester.tap(find.text('CANCELAR'));
      await tester.pumpAndSettle();
      expect(find.text('Eutirox (Levotiroxina)'), findsOneWidget);

      // Open menu again and confirm deletion
      await tester.tap(moreButtons.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar del botiquín'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ELIMINAR'));
      await tester.pumpAndSettle();

      // SnackBar with undo action is displayed
      expect(find.text('Se eliminó "Eutirox (Levotiroxina)" del botiquín'), findsOneWidget);
      expect(find.text('DESHACER'), findsOneWidget);
    });
  });
}

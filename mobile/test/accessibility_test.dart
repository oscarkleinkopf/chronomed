import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronomed/features/senior_mode/widgets/overdose_guard_button.dart';
import 'package:chronomed/features/senior_mode/screens/senior_single_action_screen.dart';
import 'package:chronomed/core/storage/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await LocalStorageService.instance.init(inMemory: true);
    await LocalStorageService.instance.resetAllData();
  });

  group('ChronoMed Accessibility (a11y) & WCAG Compliance Suite', () {
    testWidgets('OverdoseGuardButton touch target exceeds 48dp minimum threshold (96dp)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OverdoseGuardButton(
              isTaken: false,
              nextDoseTime: '21:30',
              onConfirm: () {},
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(ElevatedButton);
      expect(buttonFinder, findsOneWidget);

      final Size buttonSize = tester.getSize(buttonFinder);
      // Verifies minimum touch target requirements according to WCAG AAA (>= 48x48 dp)
      expect(buttonSize.height, greaterThanOrEqualTo(48.0));
      expect(buttonSize.height, equals(96.0));
      expect(buttonSize.width, greaterThanOrEqualTo(48.0));
    });

    testWidgets('OverdoseGuardButton active state exposes button Semantics and accessibility hint', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OverdoseGuardButton(
              isTaken: false,
              nextDoseTime: '21:30',
              onConfirm: () {},
            ),
          ),
        ),
      );

      // Verify that button semantics wrapper is present with button role, label, and hint
      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.button == true &&
            widget.properties.label == 'Confirmar toma de medicamento: Ya me la tomé' &&
            widget.properties.hint == 'Toca dos veces para registrar que tomaste tu dosis y activar el bloqueo anti-sobredosis',
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('OverdoseGuardButton confirmed state provides Semantics with liveRegion: true for automatic TalkBack announcement', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OverdoseGuardButton(
              isTaken: true,
              nextDoseTime: '21:30',
              onConfirm: () {},
            ),
          ),
        ),
      );

      // Verify presence of Semantics widget with liveRegion: true
      final semanticsFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.liveRegion == true,
      );
      expect(semanticsFinder, findsOneWidget);

      final Semantics semanticsWidget = tester.widget<Semantics>(semanticsFinder);
      expect(semanticsWidget.properties.label, contains('¡Listo! Dosis tomada'));
      expect(semanticsWidget.properties.label, contains('Bloqueo anti-sobredosis activo'));
      expect(semanticsWidget.properties.label, contains('21:30'));

      handle.dispose();
    });

    testWidgets('SeniorSingleActionScreen renders resiliently under 200% font scaling (textScaleFactor: 2.0)', (WidgetTester tester) async {
      // Configure large accessibility text scale factor (2.0x)
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(2.0),
            size: Size(412, 915), // Standard Android device size
          ),
          child: const MaterialApp(
            home: SeniorSingleActionScreen(
              patientName: 'Marcela',
              caregiverPin: '1234',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Screen should render without throwing overflow errors
      expect(tester.takeException(), isNull);
      expect(find.text('Hola, Marcela 👋'), findsOneWidget);
      expect(find.text('YA ME LA TOMÉ'), findsOneWidget);
    });

    testWidgets('SeniorSingleActionScreen AppBar action buttons satisfy >= 48dp touch constraints', (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(412, 915),
          ),
          child: const MaterialApp(
            home: SeniorSingleActionScreen(
              patientName: 'Marcela',
              caregiverPin: '1234',
            ),
          ),
        ),
      );

      final iconButtons = find.byType(IconButton);
      expect(iconButtons, findsNWidgets(2));

      for (final button in tester.widgetList<IconButton>(iconButtons)) {
        final constraints = button.constraints;
        expect(constraints, isNotNull);
        expect(constraints!.minWidth, greaterThanOrEqualTo(48.0));
        expect(constraints.minHeight, greaterThanOrEqualTo(48.0));
      }
    });
  });
}

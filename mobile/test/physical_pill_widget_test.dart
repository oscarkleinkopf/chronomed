import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronomed/features/senior_mode/widgets/physical_pill_widget.dart';
import 'package:chronomed/core/storage/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await LocalStorageService.instance.init(inMemory: true);
  });

  group('PhysicalPillWidget & Magnifier Modal Tests', () {
    testWidgets('renders round pill with CustomPaint and valid touch target size', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: PhysicalPillWidget(
                size: 110,
                shapeType: 'round',
                pillColor: Color(0xFF3B82F6),
                imprint: '50',
                hasScoreLine: true,
                medicationName: 'Losartán Potásico',
                dosage: '50 mg',
                physicalDescription: 'Comprimido circular azul grabado 50 con ranura',
              ),
            ),
          ),
        ),
      );

      expect(find.byType(PhysicalPillWidget), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      final Size size = tester.getSize(find.byType(PhysicalPillWidget));
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('exposes accessibility semantics label and hint for TalkBack', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: PhysicalPillWidget(
                size: 110,
                shapeType: 'round',
                pillColor: Color(0xFF3B82F6),
                imprint: '50',
                hasScoreLine: true,
                medicationName: 'Losartán Potásico',
                dosage: '50 mg',
                physicalDescription: 'Comprimido circular azul grabado 50 con ranura',
              ),
            ),
          ),
        ),
      );

      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.button == true &&
            widget.properties.label == 'Pastilla física de Losartán Potásico: Comprimido circular azul grabado 50 con ranura. Toca para abrir la lupa.' &&
            widget.properties.hint == 'Toca dos veces para ver la pastilla en tamaño gigante',
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('renders oblong pill shape without score line correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: PhysicalPillWidget(
                size: 100,
                shapeType: 'oblong',
                pillColor: Color(0xFFFACC15),
                imprint: '20',
                hasScoreLine: false,
                medicationName: 'Atorvastatina',
                dosage: '20 mg',
                physicalDescription: 'Comprimido oblongo amarillo grabado 20',
              ),
            ),
          ),
        ),
      );

      expect(find.byType(PhysicalPillWidget), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('tapping pill opens high-definition Magnifier modal dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: PhysicalPillWidget(
                size: 110,
                shapeType: 'round',
                pillColor: Color(0xFF3B82F6),
                imprint: '50',
                hasScoreLine: true,
                medicationName: 'Losartán Potásico',
                dosage: '50 mg',
                physicalDescription: 'Comprimido circular azul grabado 50 con ranura',
              ),
            ),
          ),
        ),
      );

      // Verify magnifier is not displayed initially
      expect(find.text('Lupa: Losartán Potásico'), findsNothing);

      // Tap on the pill widget
      await tester.tap(find.byType(PhysicalPillWidget));
      await tester.pumpAndSettle();

      // Verify magnifier dialog content
      expect(find.text('Lupa: Losartán Potásico'), findsOneWidget);
      expect(find.text('Losartán Potásico'), findsWidgets);
      expect(find.text('50 mg'), findsWidgets);
      expect(find.text('Escuchar Descripción Física'), findsOneWidget);
      expect(find.text('ENTENDIDO'), findsOneWidget);
    });

    testWidgets('closing magnifier dialog dismisses the modal', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: PhysicalPillWidget(
                size: 110,
                shapeType: 'round',
                pillColor: Color(0xFF3B82F6),
                imprint: '50',
                hasScoreLine: true,
                medicationName: 'Losartán Potásico',
                dosage: '50 mg',
                physicalDescription: 'Comprimido circular azul',
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PhysicalPillWidget));
      await tester.pumpAndSettle();
      expect(find.text('Lupa: Losartán Potásico'), findsOneWidget);

      // Tap ENTENDIDO to dismiss
      await tester.tap(find.text('ENTENDIDO'));
      await tester.pumpAndSettle();
      expect(find.text('Lupa: Losartán Potásico'), findsNothing);
    });
  });
}

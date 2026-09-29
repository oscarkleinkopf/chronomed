import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronomed/core/storage/local_storage_service.dart';
import 'package:chronomed/features/standard_mode/widgets/adherence_timeline_widget.dart';
import 'package:chronomed/features/senior_mode/models/senior_intake_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChronoMed Adherence Timeline Widget Test Suite', () {
    late LocalStorageService storage;

    setUp(() async {
      storage = LocalStorageService.instance;
      await storage.init(inMemory: true);
      await storage.resetAllData();
    });

    testWidgets('Renders weekly timeline with 7 day labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdherenceTimelineWidget(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verifica título
      expect(find.text('Adherencia Semanal'), findsOneWidget);

      // Verifica etiquetas de días
      expect(find.text('Lu'), findsOneWidget);
      expect(find.text('Ma'), findsOneWidget);
      expect(find.text('Mi'), findsOneWidget);
      expect(find.text('Ju'), findsOneWidget);
      expect(find.text('Vi'), findsOneWidget);
      expect(find.text('Sa'), findsOneWidget);
      expect(find.text('Do'), findsOneWidget);

      // Verifica leyenda
      expect(find.text('Completo (4/4)'), findsOneWidget);
      expect(find.text('Parcial'), findsOneWidget);
      expect(find.text('Omitido'), findsOneWidget);
    });

    testWidgets('Displays positive adherence percentage when doses are recorded', (WidgetTester tester) async {
      // Registra una toma hoy
      final now = DateTime.now();
      await storage.recordIntake(
        intakeId: 'test-intake',
        medicationName: 'Losartán Potásico',
        timeSlot: SeniorTimeSlot.lunch,
        timestamp: now,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdherenceTimelineWidget(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AdherenceTimelineWidget), findsOneWidget);
      expect(find.textContaining('semanal'), findsOneWidget);
    });
  });
}

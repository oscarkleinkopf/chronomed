import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronomed/core/storage/local_storage_service.dart';
import 'package:chronomed/core/services/home_screen_widget_service.dart';
import 'package:chronomed/features/senior_mode/models/senior_intake_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeScreenWidgetService & Native Widget Sync Test Suite', () {
    late LocalStorageService storage;
    late HomeScreenWidgetService widgetService;
    final List<MethodCall> methodCalls = [];

    setUp(() async {
      methodCalls.clear();
      storage = LocalStorageService.instance;
      await storage.init(inMemory: true);
      await storage.resetAllData();
      widgetService = HomeScreenWidgetService.instance;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('com.chronomed.app/widget'),
        (MethodCall call) async {
          methodCalls.add(call);
          if (call.method == 'updateWidgetData') {
            return true;
          }
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('com.chronomed.app/widget'),
        null,
      );
    });

    test('computeTodayAdherence returns 0/4 when no intakes exist for reference date', () {
      final adherence = widgetService.computeTodayAdherence(DateTime(2026, 9, 29));
      expect(adherence, equals('0/4 tomas'));
    });

    test('computeTodayAdherence increments proportionally when intakes are recorded', () async {
      final testDate = DateTime(2026, 9, 29, 8, 30);
      await storage.recordIntake(
        intakeId: 'intake-1',
        medicationName: 'Levotiroxina',
        timeSlot: SeniorTimeSlot.morning,
        timestamp: testDate,
      );

      expect(widgetService.computeTodayAdherence(testDate), equals('1/4 tomas'));

      await storage.recordIntake(
        intakeId: 'intake-2',
        medicationName: 'Losartán',
        timeSlot: SeniorTimeSlot.lunch,
        timestamp: DateTime(2026, 9, 29, 13, 0),
      );

      expect(widgetService.computeTodayAdherence(testDate), equals('2/4 tomas'));
    });

    test('computeNextDose suggests first untaken slot and formatted time', () async {
      final testDate = DateTime(2026, 9, 29, 7, 0);

      // Desayuno pendiente
      final next1 = widgetService.computeNextDose(testDate);
      expect(next1['name'], contains('Levotiroxina'));
      expect(next1['time'], isNotEmpty);

      // Toma desayuno
      await storage.recordIntake(
        intakeId: 'intake-1',
        medicationName: 'Levotiroxina',
        timeSlot: SeniorTimeSlot.morning,
        timestamp: testDate,
      );

      // Siguiente pendiente debe ser Almuerzo (Losartán)
      final next2 = widgetService.computeNextDose(testDate);
      expect(next2['name'], contains('Losartán'));

      // Toma almuerzo, once y noche
      await storage.recordIntake(
        intakeId: 'intake-2',
        medicationName: 'Losartán',
        timeSlot: SeniorTimeSlot.lunch,
        timestamp: DateTime(2026, 9, 29, 13, 0),
      );
      await storage.recordIntake(
        intakeId: 'intake-3',
        medicationName: 'Multivitamínico',
        timeSlot: SeniorTimeSlot.afternoonSnack,
        timestamp: DateTime(2026, 9, 29, 17, 0),
      );
      await storage.recordIntake(
        intakeId: 'intake-4',
        medicationName: 'Atorvastatina',
        timeSlot: SeniorTimeSlot.night,
        timestamp: DateTime(2026, 9, 29, 21, 0),
      );

      // Todas tomadas
      final nextAll = widgetService.computeNextDose(testDate);
      expect(nextAll['name'], equals('Todas al día'));
      expect(nextAll['time'], equals('Completado ✓'));
    });

    test('updateWidgetData dispatches MethodChannel call with formatted payload', () async {
      final success = await widgetService.updateWidgetData(
        patientName: 'Marcela',
        nextMedicineName: 'Losartán 50mg',
        nextDoseTime: '13:00',
        adherenceToday: '1/4 tomas',
      );

      expect(success, isTrue);
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('updateWidgetData'));
      expect(methodCalls.first.arguments['patientName'], equals('Marcela'));
      expect(methodCalls.first.arguments['nextMedicineName'], equals('Losartán 50mg'));
      expect(methodCalls.first.arguments['nextDoseTime'], equals('13:00'));
      expect(methodCalls.first.arguments['adherenceToday'], equals('1/4 tomas'));
    });

    test('updateWidgetData handles platform exceptions gracefully and returns false', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('com.chronomed.app/widget'),
        (MethodCall call) async {
          throw PlatformException(code: 'UNAVAILABLE', message: 'Widget provider not bound');
        },
      );

      final success = await widgetService.updateWidgetData();
      expect(success, isFalse);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronomed/core/notifications/alarm_scheduler.dart';
import 'package:chronomed/core/notifications/local_notification_service.dart';
import 'package:chronomed/core/storage/local_storage_service.dart';
import 'package:chronomed/features/schedule/models/circadian_routine.dart';
import 'package:chronomed/features/senior_mode/models/senior_intake_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChronoMed Circadian Alarm Orchestrator Test Suite', () {
    late LocalStorageService storage;
    late AlarmScheduler scheduler;

    setUp(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        (MethodCall methodCall) async => true,
      );
      storage = LocalStorageService.instance;
      await storage.init(inMemory: true);
      await storage.resetAllData();
      scheduler = AlarmScheduler();
      await LocalNotificationService().initialize();
    });

    test('Orchestrates circadian alarms for untaken slots based on Home routine', () async {
      // 06:00 AM reference time: all slots (fasting 07:30, lunch 13:30, night 22:30) are in the future
      final morningRef = DateTime(2026, 9, 29, 6, 0);

      final scheduled = await scheduler.scheduleAllCircadianAlarms(
        routine: CircadianRoutine.home,
        storage: storage,
        referenceDate: morningRef,
      );

      // Fasting, lunch, night should all be scheduled
      expect(scheduled, equals(3));
    });

    test('Adjusts alarm timing when switching to Hospital / ELEAM regime', () async {
      // In hospital routine: fasting is 06:30, breakfast 07:00, lunch 12:00, night 20:30
      final routine = CircadianRoutine.hospital;
      final ref = DateTime(2026, 9, 29, 6, 0);

      final scheduled = await scheduler.scheduleAllCircadianAlarms(
        routine: routine,
        storage: storage,
        referenceDate: ref,
      );

      expect(scheduled, equals(3));
      expect(routine.fastingTime.hour, equals(6));
      expect(routine.fastingTime.minute, equals(30));
      expect(routine.lunch.hour, equals(12));
      expect(routine.lunch.minute, equals(0));
    });

    test('Anti-Overdose Lock: skips scheduling if slot was already taken today', () async {
      final ref = DateTime(2026, 9, 29, 10, 0);

      // Record morning fasting dose as taken
      await storage.recordIntake(
        intakeId: 'intake-morning-test',
        medicationName: 'Eutirox (Levotiroxina)',
        timeSlot: SeniorTimeSlot.morning,
        timestamp: DateTime(2026, 9, 29, 7, 30),
      );

      expect(storage.isSlotTakenToday(SeniorTimeSlot.morning, ref), isTrue);

      final scheduled = await scheduler.scheduleAllCircadianAlarms(
        routine: CircadianRoutine.home,
        storage: storage,
        referenceDate: ref,
      );

      // Fasting is skipped because it's already taken; only lunch (13:30) and night (22:30) scheduled
      expect(scheduled, equals(2));
    });

    test('Integrates recorded familiar voice notes into alarm payload and message text', () async {
      final ref = DateTime(2026, 9, 29, 11, 0);

      // Save a familiar voice note for lunch slot
      await storage.saveVoiceNote(
        slot: SeniorTimeSlot.lunch,
        author: 'Hijo Carlos',
        audioPath: '/mock/path/audio_lunch.m4a',
        messageText: 'Mamá, tómate la pastillita azul del almuerzo',
      );

      expect(storage.hasVoiceNote(SeniorTimeSlot.lunch), isTrue);
      final note = storage.getVoiceNote(SeniorTimeSlot.lunch);
      expect(note!['author'], equals('Hijo Carlos'));
      expect(note['messageText'], equals('Mamá, tómate la pastillita azul del almuerzo'));

      final scheduled = await scheduler.scheduleAllCircadianAlarms(
        routine: CircadianRoutine.home,
        storage: storage,
        referenceDate: ref,
      );

      expect(scheduled, equals(2)); // lunch and night
    });

    test('Cancels individual slot alarms correctly', () async {
      await scheduler.cancelSlotAlarm(SeniorTimeSlot.lunch);
      await scheduler.cancelAllCircadianAlarms();
      // No exceptions thrown
    });
  });
}

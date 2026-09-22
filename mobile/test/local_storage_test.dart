import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronomed/core/storage/local_storage_service.dart';
import 'package:chronomed/features/schedule/models/circadian_routine.dart';
import 'package:chronomed/features/senior_mode/models/senior_intake_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChronoMed Local Storage & Zero Data Loss Test Suite', () {
    late LocalStorageService storage;

    setUp(() async {
      storage = LocalStorageService.instance;
      await storage.init(inMemory: true);
      await storage.resetAllData();
    });

    test('Initializes with clinically safe default values', () {
      expect(storage.isInitialized, isTrue);
      expect(storage.getStock('eutirox'), equals(28));
      expect(storage.getStock('losartan'), equals(14));
      expect(storage.getStock('atorvastatina'), equals(30));
      expect(storage.getCircadianRoutine().regimeType, equals(CircadianRegimeType.home));
      expect(storage.caregiverPin, equals('1234'));
      expect(storage.patientName, equals('Marcela'));
      expect(storage.patientRut, equals('14.567.890-K'));
      expect(storage.allIntakes, isEmpty);
    });

    test('Updates, increments and decrements medication stock with diacritic normalization', () async {
      // Test direct update
      await storage.setStock('losartan', 40);
      expect(storage.getStock('losartan'), equals(40));

      // Test OCR formatted string normalization (e.g. "LOSARTAN POTASICO")
      await storage.incrementStock('LOSARTÁN POTÁSICO 50 mg', 30);
      expect(storage.getStock('losartan'), equals(70));

      // Test Eutirox / Levotiroxina mapping
      await storage.setStock('Levotiroxina Sódica', 50);
      expect(storage.getStock('eutirox'), equals(50));

      // Test decrement
      await storage.decrementStock('eutirox', units: 2);
      expect(storage.getStock('eutirox'), equals(48));

      // Prevent negative stock
      await storage.decrementStock('eutirox', units: 100);
      expect(storage.getStock('eutirox'), equals(0));
    });

    test('Persists and retrieves circadian routine presets and custom times', () async {
      // Switch to Hospital regime
      await storage.saveCircadianRoutine(CircadianRoutine.hospital);
      expect(storage.getCircadianRoutine().regimeType, equals(CircadianRegimeType.hospital));
      expect(storage.getCircadianRoutine().formatTime(storage.getCircadianRoutine().breakfast), equals('07:00'));

      // Switch to Custom routine
      const customRoutine = CircadianRoutine(
        regimeType: CircadianRegimeType.custom,
        breakfast: TimeOfDay(hour: 8, minute: 15),
        lunch: TimeOfDay(hour: 14, minute: 0),
        afternoon: TimeOfDay(hour: 19, minute: 30),
        night: TimeOfDay(hour: 23, minute: 0),
      );
      await storage.saveCircadianRoutine(customRoutine);

      final retrieved = storage.getCircadianRoutine();
      expect(retrieved.regimeType, equals(CircadianRegimeType.custom));
      expect(retrieved.formatTime(retrieved.breakfast), equals('08:15'));
      expect(retrieved.formatTime(retrieved.lunch), equals('14:00'));
      expect(retrieved.formatTime(retrieved.afternoon), equals('19:30'));
      expect(retrieved.formatTime(retrieved.night), equals('23:00'));
    });

    test('Enforces anti-overdose lock by tracking intake timestamps and auto-decrementing stock', () async {
      final initialLosartanStock = storage.getStock('losartan');
      final today = DateTime(2026, 9, 22, 13, 35);
      const intakeId = 'intake-lunch-123';

      // Verify no doses recorded yet
      expect(storage.isSlotTakenToday(SeniorTimeSlot.lunch, today), isFalse);
      expect(storage.isSlotTakenToday(SeniorTimeSlot.morning, today), isFalse);

      // Record dose intake
      await storage.recordIntake(
        intakeId: intakeId,
        medicationName: 'Losartán Potásico',
        timeSlot: SeniorTimeSlot.lunch,
        timestamp: today,
      );

      // Verify anti-overdose lock is now active for lunch slot
      expect(storage.isSlotTakenToday(SeniorTimeSlot.lunch, today), isTrue);
      // Other slots remain unlocked
      expect(storage.isSlotTakenToday(SeniorTimeSlot.morning, today), isFalse);
      expect(storage.isSlotTakenToday(SeniorTimeSlot.night, today), isFalse);

      // Stock was decremented by 1
      expect(storage.getStock('losartan'), equals(initialLosartanStock - 1));

      // Check date specificity: yesterday should not be marked as taken
      final yesterday = DateTime(2026, 9, 21, 13, 35);
      expect(storage.isSlotTakenToday(SeniorTimeSlot.lunch, yesterday), isFalse);

      // Verify last intake lookup
      final lastTimestamp = storage.getLastIntakeTimestamp(intakeId);
      expect(lastTimestamp, isNotNull);
      expect(lastTimestamp!.hour, equals(13));
      expect(lastTimestamp.minute, equals(35));
    });

    test('Zero Data Loss: exports and restores complete patient state and history', () async {
      // Mutate state
      await storage.setStock('losartan', 99);
      await storage.setStock('eutirox', 88);
      await storage.saveCircadianRoutine(CircadianRoutine.hospital);
      await storage.recordIntake(
        intakeId: 'intake-test-export',
        medicationName: 'Atorvastatina',
        timeSlot: SeniorTimeSlot.night,
        timestamp: DateTime(2026, 9, 22, 22, 0),
      );

      // Export backup JSON
      final backupJson = storage.exportBackupJson();
      expect(backupJson, contains('"version":"1.0.0"'));
      expect(backupJson, contains('"losartan":99'));
      expect(backupJson, contains('"eutirox":88'));
      expect(backupJson, contains('"regimeType":"hospital"'));
      expect(backupJson, contains('intake-test-export'));

      // Reset to factory defaults
      await storage.resetAllData();
      expect(storage.getStock('losartan'), equals(14));
      expect(storage.getCircadianRoutine().regimeType, equals(CircadianRegimeType.home));
      expect(storage.allIntakes, isEmpty);

      // Import backup JSON
      await storage.importBackupJson(backupJson);

      // Verify full state restoration
      expect(storage.getStock('losartan'), equals(99));
      expect(storage.getStock('eutirox'), equals(88));
      expect(storage.getCircadianRoutine().regimeType, equals(CircadianRegimeType.hospital));
      expect(storage.allIntakes.length, equals(1));
      expect(storage.allIntakes.first['intakeId'], equals('intake-test-export'));
    });
  });
}

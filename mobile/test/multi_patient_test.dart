import 'package:flutter_test/flutter_test.dart';
import 'package:chronomed/core/storage/local_storage_service.dart';
import 'package:chronomed/features/patients/models/patient_profile.dart';
import 'package:chronomed/features/schedule/models/circadian_routine.dart';
import 'package:chronomed/features/senior_mode/models/senior_intake_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChronoMed Multi-Patient & ELEAM Caregiver Test Suite', () {
    late LocalStorageService storage;

    setUp(() async {
      storage = LocalStorageService.instance;
      await storage.init(inMemory: true);
      await storage.resetAllData();
    });

    test('Initializes with default single patient (backward compatible)', () {
      expect(storage.patients.length, equals(1));
      expect(storage.patientName, equals('Marcela'));
      expect(storage.patientRut, equals('14.567.890-K'));
      expect(storage.activePatient.name, equals('Marcela'));
      expect(storage.activePatientId, equals('patient-marcela-1'));
    });

    test('Adds a second patient and switches between them cleanly', () async {
      final roberto = PatientProfile(
        id: 'patient-roberto-2',
        name: 'Roberto Gómez',
        rut: '12.345.678-5',
        age: 79,
        avatarColorValue: 0xFF7C3AED,
        routine: CircadianRoutine.hospital,
        stocks: {
          'eutirox': 50,
          'losartan': 90,
          'atorvastatina': 10,
        },
      );

      // Add Roberto and make active
      await storage.addPatient(roberto, setActive: true);

      expect(storage.patients.length, equals(2));
      expect(storage.activePatientId, equals('patient-roberto-2'));
      expect(storage.patientName, equals('Roberto Gómez'));
      expect(storage.patientRut, equals('12.345.678-5'));
      expect(storage.getStock('losartan'), equals(90));
      expect(storage.getCircadianRoutine().regimeType, equals(CircadianRegimeType.hospital));

      // Switch back to Marcela
      await storage.switchPatient('patient-marcela-1');

      expect(storage.activePatientId, equals('patient-marcela-1'));
      expect(storage.patientName, equals('Marcela'));
      expect(storage.patientRut, equals('14.567.890-K'));
      expect(storage.getStock('losartan'), equals(14));
      expect(storage.getCircadianRoutine().regimeType, equals(CircadianRegimeType.home));
    });

    test('Guarantees clinical data isolation: intakes and stock changes do not bleed between patients', () async {
      final roberto = PatientProfile(
        id: 'patient-roberto-2',
        name: 'Roberto Gómez',
        rut: '12.345.678-5',
      );
      await storage.addPatient(roberto, setActive: true);

      // Record an intake for Roberto
      await storage.recordIntake(
        intakeId: 'intake-roberto-lunch',
        medicationName: 'Losartán Potásico',
        timeSlot: SeniorTimeSlot.lunch,
        timestamp: DateTime(2026, 10, 1, 13, 30),
      );

      expect(storage.allIntakes.length, equals(1));
      expect(storage.allIntakes.first['intakeId'], equals('intake-roberto-lunch'));

      // Switch to Marcela -> should have 0 intakes
      await storage.switchPatient('patient-marcela-1');
      expect(storage.allIntakes, isEmpty);

      // Switch back to Roberto -> intake is still there
      await storage.switchPatient('patient-roberto-2');
      expect(storage.allIntakes.length, equals(1));
      expect(storage.allIntakes.first['intakeId'], equals('intake-roberto-lunch'));
    });

    test('Guarantees voice notes isolation between patients', () async {
      // Configure voice note for Marcela (active)
      await storage.saveVoiceNote(
        slot: SeniorTimeSlot.lunch,
        author: 'Hija Andrea',
        audioPath: 'voice_marcela_lunch.m4a',
        messageText: 'Mamá Marcela, toma tu Losartán.',
      );

      expect(storage.hasVoiceNote(SeniorTimeSlot.lunch), isTrue);
      expect(storage.getVoiceNote(SeniorTimeSlot.lunch)?['author'], equals('Hija Andrea'));

      // Add Roberto and switch to Roberto
      final roberto = PatientProfile(
        id: 'patient-roberto-2',
        name: 'Roberto Gómez',
        rut: '12.345.678-5',
      );
      await storage.addPatient(roberto, setActive: true);

      // Roberto should NOT have Marcela's voice note
      expect(storage.hasVoiceNote(SeniorTimeSlot.lunch), isFalse);
      expect(storage.getVoiceNote(SeniorTimeSlot.lunch), isNull);

      // Record a voice note for Roberto
      await storage.saveVoiceNote(
        slot: SeniorTimeSlot.morning,
        author: 'Hijo Carlos',
        audioPath: 'voice_roberto_morning.m4a',
        messageText: 'Papá Roberto, toma tu pastilla matutina.',
      );
      expect(storage.hasVoiceNote(SeniorTimeSlot.morning), isTrue);
      expect(storage.getVoiceNote(SeniorTimeSlot.morning)?['author'], equals('Hijo Carlos'));

      // Switch back to Marcela -> has lunch note, but not morning note
      await storage.switchPatient('patient-marcela-1');
      expect(storage.hasVoiceNote(SeniorTimeSlot.lunch), isTrue);
      expect(storage.getVoiceNote(SeniorTimeSlot.lunch)?['author'], equals('Hija Andrea'));
      expect(storage.hasVoiceNote(SeniorTimeSlot.morning), isFalse);

      // Switch back to Roberto -> has morning note, but not lunch note
      await storage.switchPatient('patient-roberto-2');
      expect(storage.hasVoiceNote(SeniorTimeSlot.morning), isTrue);
      expect(storage.getVoiceNote(SeniorTimeSlot.morning)?['author'], equals('Hijo Carlos'));
      expect(storage.hasVoiceNote(SeniorTimeSlot.lunch), isFalse);
    });

    test('Patient profile updates are persisted reactively', () async {
      await storage.updatePatientProfile(
        id: 'patient-marcela-1',
        name: 'Marcela Morales',
        rut: '14.567.890-K',
        age: 82,
        avatarColorValue: 0xFF059669,
      );

      expect(storage.patientName, equals('Marcela Morales'));
      expect(storage.activePatient.age, equals(82));
      expect(storage.activePatient.avatarColorValue, equals(0xFF059669));
    });

    test('Deletes a patient safely while preventing deletion of the last remaining profile', () async {
      // Trying to delete Marcela when only 1 patient exists
      await storage.deletePatient('patient-marcela-1');
      expect(storage.patients.length, equals(1)); // Guard prevents deletion

      // Add Roberto
      final roberto = PatientProfile(
        id: 'patient-roberto-2',
        name: 'Roberto Gómez',
        rut: '12.345.678-5',
      );
      await storage.addPatient(roberto, setActive: true);
      expect(storage.patients.length, equals(2));

      // Now delete Roberto
      await storage.deletePatient('patient-roberto-2');
      expect(storage.patients.length, equals(1));
      expect(storage.activePatientId, equals('patient-marcela-1'));
      expect(storage.patientName, equals('Marcela'));
    });

    test('Zero Data Loss: exports and restores complete multi-patient database in JSON', () async {
      final roberto = PatientProfile(
        id: 'patient-roberto-2',
        name: 'Roberto Gómez',
        rut: '12.345.678-5',
        age: 79,
      );
      await storage.addPatient(roberto, setActive: true);

      final backupJson = storage.exportBackupJson();
      expect(backupJson, contains('Marcela'));
      expect(backupJson, contains('Roberto Gómez'));
      expect(backupJson, contains('patient-roberto-2'));

      // Factory reset
      await storage.resetAllData();
      expect(storage.patients.length, equals(1));

      // Restore
      await storage.importBackupJson(backupJson);
      expect(storage.patients.length, equals(2));
      expect(storage.activePatientId, equals('patient-roberto-2'));
      expect(storage.patientName, equals('Roberto Gómez'));
    });
  });
}

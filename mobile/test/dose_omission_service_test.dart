import 'package:flutter_test/flutter_test.dart';
import 'package:chronomed/core/storage/local_storage_service.dart';
import 'package:chronomed/features/schedule/models/circadian_routine.dart';
import 'package:chronomed/features/senior_mode/models/senior_intake_item.dart';
import 'package:chronomed/features/standard_mode/models/dose_omission_model.dart';
import 'package:chronomed/features/standard_mode/services/dose_omission_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DoseOmissionService & Caregiver Escalation Test Suite', () {
    late DoseOmissionService service;
    late LocalStorageService storage;
    const routine = CircadianRoutine.home; // breakfast 08:00 (fasting 07:30), lunch 13:30, night 22:30

    setUp(() async {
      storage = LocalStorageService.instance;
      await storage.init(inMemory: true);
      await storage.resetAllData();
      service = DoseOmissionService.instance;
    });

    test('Identifies scheduled dose in the future as non-overdue', () {
      // 11:00 AM: Before lunch (13:30)
      final morningTime = DateTime(2026, 9, 22, 11, 0);

      final alerts = service.evaluateAdherence(now: morningTime, routine: routine);
      final lunchAlert = alerts.firstWhere((a) => a.timeSlot == SeniorTimeSlot.lunch);

      expect(lunchAlert.status, equals(OmissionStatus.future));
      expect(lunchAlert.isFuture, isTrue);
      expect(lunchAlert.isEscalated, isFalse);
      expect(lunchAlert.minutesOverdue, equals(0));
      expect(lunchAlert.scheduledTimeStr, equals('13:30'));
    });

    test('Allows 45-minute grace period without triggering critical escalation alert', () async {
      // Record morning fasting dose as taken on time
      await storage.recordIntake(
        intakeId: 'intake-morning-fasting',
        medicationName: 'Eutirox (Levotiroxina)',
        timeSlot: SeniorTimeSlot.morning,
        timestamp: DateTime(2026, 9, 22, 7, 35),
      );

      // 13:55: 25 minutes after scheduled lunch (13:30)
      final graceTime = DateTime(2026, 9, 22, 13, 55);

      final alerts = service.evaluateAdherence(now: graceTime, routine: routine);
      final lunchAlert = alerts.firstWhere((a) => a.timeSlot == SeniorTimeSlot.lunch);

      expect(lunchAlert.status, equals(OmissionStatus.inGracePeriod));
      expect(lunchAlert.isInGracePeriod, isTrue);
      expect(lunchAlert.isEscalated, isFalse);
      expect(lunchAlert.minutesOverdue, equals(25));
      expect(lunchAlert.statusBadgeLabel, contains('En ventana'));

      // Highest priority alert must be null because no dose has exceeded 45 min
      final escalated = service.getActiveEscalatedAlert(now: graceTime, routine: routine);
      expect(escalated, isNull);
    });

    test('Triggers critical escalation alert when delay exceeds 45 minutes', () async {
      // Record morning fasting dose as taken on time so lunch is the overdue target
      await storage.recordIntake(
        intakeId: 'intake-morning-fasting',
        medicationName: 'Eutirox (Levotiroxina)',
        timeSlot: SeniorTimeSlot.morning,
        timestamp: DateTime(2026, 9, 22, 7, 35),
      );

      // 14:20: 50 minutes after scheduled lunch (13:30) without intake
      final overdueTime = DateTime(2026, 9, 22, 14, 20);

      final alerts = service.evaluateAdherence(now: overdueTime, routine: routine);
      final lunchAlert = alerts.firstWhere((a) => a.timeSlot == SeniorTimeSlot.lunch);

      expect(lunchAlert.status, equals(OmissionStatus.escalated));
      expect(lunchAlert.isEscalated, isTrue);
      expect(lunchAlert.minutesOverdue, equals(50));
      expect(lunchAlert.statusBadgeLabel, contains('ALERTA: 50 min retraso'));

      // Check that getActiveEscalatedAlert returns this alert
      final activeEscalated = service.getActiveEscalatedAlert(now: overdueTime, routine: routine);
      expect(activeEscalated, isNotNull);
      expect(activeEscalated!.drugName, equals('Losartán Potásico'));
      expect(activeEscalated.patientName, equals('Marcela'));
    });

    test('Suppresses escalation alert when medication is already recorded as taken', () async {
      final nowTime = DateTime(2026, 9, 22, 15, 0); // 90 min after lunch

      // Record dose intake
      await storage.recordIntake(
        intakeId: 'intake-123',
        medicationName: 'Losartán Potásico',
        timeSlot: SeniorTimeSlot.lunch,
        timestamp: DateTime(2026, 9, 22, 13, 32),
      );

      final alerts = service.evaluateAdherence(now: nowTime, routine: routine);
      final lunchAlert = alerts.firstWhere((a) => a.timeSlot == SeniorTimeSlot.lunch);

      expect(lunchAlert.status, equals(OmissionStatus.taken));
      expect(lunchAlert.isTaken, isTrue);
      expect(lunchAlert.isEscalated, isFalse);
      expect(lunchAlert.minutesOverdue, equals(0));
      expect(lunchAlert.statusBadgeLabel, equals('✅ Administrada'));
    });

    test('Evaluates fasting dose (Eutirox 100 mcg) relative to 30 min before breakfast', () {
      // Breakfast is 08:00, fasting is 07:30
      // 08:25 is 55 minutes after fasting time 07:30 -> should be escalated!
      final morningOverdue = DateTime(2026, 9, 22, 8, 25);

      final alerts = service.evaluateAdherence(now: morningOverdue, routine: routine);
      final eutiroxAlert = alerts.firstWhere((a) => a.timeSlot == SeniorTimeSlot.morning);

      expect(eutiroxAlert.drugName, contains('Eutirox'));
      expect(eutiroxAlert.scheduledTimeStr, equals('07:30'));
      expect(eutiroxAlert.minutesOverdue, equals(55));
      expect(eutiroxAlert.status, equals(OmissionStatus.escalated));
    });

    test('Formats professional WhatsApp clinical escalation alert message', () {
      const alert = DoseOmissionAlert(
        patientName: 'Marcela',
        patientRut: '14.567.890-K',
        drugName: 'Losartán Potásico',
        dosage: '50 mg',
        timeSlot: SeniorTimeSlot.lunch,
        scheduledTimeStr: '13:30',
        minutesOverdue: 52,
        status: OmissionStatus.escalated,
        intakeId: 'intake-123',
      );

      final message = service.generateWhatsAppAlertMessage(alert);

      expect(message, contains('ALERTA DE ADHERENCIA MÉDICA CHRONOMED'));
      expect(message, contains('Marcela'));
      expect(message, contains('14.567.890-K'));
      expect(message, contains('Losartán Potásico (50 mg)'));
      expect(message, contains('13:30'));
      expect(message, contains('52 minutos sin confirmación'));
      expect(message, contains('Ley N° 20.584'));
    });

    test('Caregiver direct supervision marks dose as administered and clears active alert', () async {
      // Record morning fasting dose as taken on time
      await storage.recordIntake(
        intakeId: 'intake-morning-fasting',
        medicationName: 'Eutirox (Levotiroxina)',
        timeSlot: SeniorTimeSlot.morning,
        timestamp: DateTime(2026, 9, 22, 7, 35),
      );

      final overdueTime = DateTime(2026, 9, 22, 14, 30); // 60 min overdue

      final activeAlert = service.getActiveEscalatedAlert(now: overdueTime, routine: routine);
      expect(activeAlert, isNotNull);
      expect(activeAlert!.drugName, equals('Losartán Potásico'));

      // Caregiver supervises and administers dose
      await service.markDoseAsAdministeredByCaregiver(activeAlert);

      // Re-evaluate
      final clearedAlert = service.getActiveEscalatedAlert(now: overdueTime, routine: routine);
      expect(clearedAlert, isNull);

      final alerts = service.evaluateAdherence(now: overdueTime, routine: routine);
      final lunchAlert = alerts.firstWhere((a) => a.timeSlot == SeniorTimeSlot.lunch);
      expect(lunchAlert.status, equals(OmissionStatus.taken));
    });
  });
}

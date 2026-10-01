import 'package:flutter_test/flutter_test.dart';
import 'package:chronomed/core/storage/local_storage_service.dart';
import 'package:chronomed/features/patients/models/patient_profile.dart';
import 'package:chronomed/features/vital_signs/models/vital_sign_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChronoMed Vital Signs & Clinical Classification Test Suite', () {
    late LocalStorageService storage;

    setUp(() async {
      storage = LocalStorageService.instance;
      await storage.init(inMemory: true);
      await storage.resetAllData();
    });

    test('Classifies blood pressure accurately under AHA and MINSAL guidelines', () {
      // Normal: < 120 and < 80
      final normal = VitalSignEntry(
        id: '1',
        patientId: 'p1',
        timestamp: DateTime.now(),
        systolic: 115,
        diastolic: 75,
      );
      expect(normal.bloodPressureStatus, equals(BloodPressureStatus.normal));
      expect(normal.bloodPressureLabel, equals('Normal / Óptima'));

      // Elevated: 120-129 and < 80
      final elevated = VitalSignEntry(
        id: '2',
        patientId: 'p1',
        timestamp: DateTime.now(),
        systolic: 125,
        diastolic: 78,
      );
      expect(elevated.bloodPressureStatus, equals(BloodPressureStatus.elevated));
      expect(elevated.bloodPressureLabel, equals('Elevada'));

      // Stage 1: 130-139 or 80-89
      final stage1Sys = VitalSignEntry(
        id: '3',
        patientId: 'p1',
        timestamp: DateTime.now(),
        systolic: 135,
        diastolic: 75,
      );
      expect(stage1Sys.bloodPressureStatus, equals(BloodPressureStatus.stage1));

      final stage1Dia = VitalSignEntry(
        id: '4',
        patientId: 'p1',
        timestamp: DateTime.now(),
        systolic: 118,
        diastolic: 84,
      );
      expect(stage1Dia.bloodPressureStatus, equals(BloodPressureStatus.stage1));

      // Stage 2: >= 140 or >= 90
      final stage2 = VitalSignEntry(
        id: '5',
        patientId: 'p1',
        timestamp: DateTime.now(),
        systolic: 145,
        diastolic: 92,
      );
      expect(stage2.bloodPressureStatus, equals(BloodPressureStatus.stage2));

      // Hypertensive Crisis: > 180 or > 120
      final crisisSys = VitalSignEntry(
        id: '6',
        patientId: 'p1',
        timestamp: DateTime.now(),
        systolic: 185,
        diastolic: 95,
      );
      expect(crisisSys.bloodPressureStatus, equals(BloodPressureStatus.crisis));

      final crisisDia = VitalSignEntry(
        id: '7',
        patientId: 'p1',
        timestamp: DateTime.now(),
        systolic: 160,
        diastolic: 125,
      );
      expect(crisisDia.bloodPressureStatus, equals(BloodPressureStatus.crisis));
    });

    test('Classifies blood glucose correctly for fasting and postprandial states', () {
      // Hypoglycemia: < 70 mg/dL
      final hypo = VitalSignEntry(
        id: '1',
        patientId: 'p1',
        timestamp: DateTime.now(),
        bloodGlucose: 62.0,
        mealContext: GlucoseMealContext.fasting,
      );
      expect(hypo.glucoseStatus, equals(GlucoseStatus.low));

      // Fasting Normal: 70 - 99 mg/dL
      final fastingNormal = VitalSignEntry(
        id: '2',
        patientId: 'p1',
        timestamp: DateTime.now(),
        bloodGlucose: 88.0,
        mealContext: GlucoseMealContext.fasting,
      );
      expect(fastingNormal.glucoseStatus, equals(GlucoseStatus.normal));

      // Fasting Prediabetes / Altered Fasting: 100 - 125 mg/dL
      final fastingPre = VitalSignEntry(
        id: '3',
        patientId: 'p1',
        timestamp: DateTime.now(),
        bloodGlucose: 112.0,
        mealContext: GlucoseMealContext.fasting,
      );
      expect(fastingPre.glucoseStatus, equals(GlucoseStatus.prediabetes));

      // Fasting High / Diabetes threshold: >= 126 mg/dL
      final fastingHigh = VitalSignEntry(
        id: '4',
        patientId: 'p1',
        timestamp: DateTime.now(),
        bloodGlucose: 135.0,
        mealContext: GlucoseMealContext.fasting,
      );
      expect(fastingHigh.glucoseStatus, equals(GlucoseStatus.high));

      // Postprandial Normal: < 140 mg/dL
      final postNormal = VitalSignEntry(
        id: '5',
        patientId: 'p1',
        timestamp: DateTime.now(),
        bloodGlucose: 130.0,
        mealContext: GlucoseMealContext.postprandial,
      );
      expect(postNormal.glucoseStatus, equals(GlucoseStatus.normal));

      // Postprandial High: >= 140 mg/dL
      final postHigh = VitalSignEntry(
        id: '6',
        patientId: 'p1',
        timestamp: DateTime.now(),
        bloodGlucose: 195.0,
        mealContext: GlucoseMealContext.postprandial,
      );
      expect(postHigh.glucoseStatus, equals(GlucoseStatus.high));
    });

    test('Serializes and deserializes VitalSignEntry JSON losslessly', () {
      final original = VitalSignEntry(
        id: 'vital-test-1',
        patientId: 'patient-marcela-1',
        timestamp: DateTime(2026, 10, 1, 14, 30),
        systolic: 122,
        diastolic: 78,
        heartRate: 72,
        bloodGlucose: 96.5,
        mealContext: GlucoseMealContext.postprandial,
        notes: 'Control posterior al almuerzo sin síntomas',
      );

      final json = original.toJson();
      final recovered = VitalSignEntry.fromJson(json);

      expect(recovered.id, equals(original.id));
      expect(recovered.patientId, equals(original.patientId));
      expect(recovered.timestamp, equals(original.timestamp));
      expect(recovered.systolic, equals(122));
      expect(recovered.diastolic, equals(78));
      expect(recovered.heartRate, equals(72));
      expect(recovered.bloodGlucose, equals(96.5));
      expect(recovered.mealContext, equals(GlucoseMealContext.postprandial));
      expect(recovered.notes, equals('Control posterior al almuerzo sin síntomas'));
    });

    test('Guarantees vital signs clinical isolation across multiple patients', () async {
      // Create second patient
      final roberto = PatientProfile(
        id: 'patient-roberto-2',
        name: 'Roberto Gómez',
        rut: '12.345.678-5',
      );
      await storage.addPatient(roberto, setActive: false);

      // Verify initial state for Marcela
      expect(storage.vitalSigns.isEmpty, isTrue);
      expect(storage.latestVitalSign, isNull);

      // Record reading for Marcela
      final marcelaReading = VitalSignEntry(
        id: 'vital-marcela-morning',
        patientId: 'patient-marcela-1',
        timestamp: DateTime(2026, 10, 1, 8, 15),
        systolic: 118,
        diastolic: 76,
        heartRate: 68,
        bloodGlucose: 92.0,
        mealContext: GlucoseMealContext.fasting,
      );
      await storage.recordVitalSign(marcelaReading);

      expect(storage.vitalSigns.length, equals(1));
      expect(storage.latestVitalSign?.id, equals('vital-marcela-morning'));
      expect(storage.latestVitalSign?.systolic, equals(118));

      // Switch to Roberto
      await storage.switchPatient('patient-roberto-2');

      // Roberto must have NO readings (Zero Data Bleeding)
      expect(storage.vitalSigns.isEmpty, isTrue);
      expect(storage.latestVitalSign, isNull);

      // Record reading for Roberto
      final robertoReading = VitalSignEntry(
        id: 'vital-roberto-noon',
        patientId: 'patient-roberto-2',
        timestamp: DateTime(2026, 10, 1, 12, 0),
        systolic: 142,
        diastolic: 88,
        heartRate: 80,
      );
      await storage.recordVitalSign(robertoReading);

      expect(storage.vitalSigns.length, equals(1));
      expect(storage.latestVitalSign?.id, equals('vital-roberto-noon'));
      expect(storage.latestVitalSign?.systolic, equals(142));

      // Switch back to Marcela
      await storage.switchPatient('patient-marcela-1');

      // Marcela's readings remain intact
      expect(storage.vitalSigns.length, equals(1));
      expect(storage.latestVitalSign?.id, equals('vital-marcela-morning'));
      expect(storage.latestVitalSign?.systolic, equals(118));

      // Delete Marcela's reading
      await storage.deleteVitalSign('vital-marcela-morning');
      expect(storage.vitalSigns.isEmpty, isTrue);
      expect(storage.latestVitalSign, isNull);

      // Switch to Roberto: his reading is still there
      await storage.switchPatient('patient-roberto-2');
      expect(storage.vitalSigns.length, equals(1));
      expect(storage.latestVitalSign?.id, equals('vital-roberto-noon'));
    });
  });
}

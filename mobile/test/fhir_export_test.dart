import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronomed/features/patients/models/patient_profile.dart';
import 'package:chronomed/features/patients/services/fhir_export_service.dart';
import 'package:chronomed/features/medicine_cabinet/models/medicine_cabinet_item.dart';
import 'package:chronomed/features/vital_signs/models/vital_sign_entry.dart';

void main() {
  group('FHIR R4 & HL7 v2.5.1 APS Interoperability Test Suite', () {
    late FhirExportService fhirService;
    late PatientProfile testPatient;

    setUp(() {
      fhirService = FhirExportService.instance;
      testPatient = PatientProfile(
        id: 'patient-marcela-test',
        name: 'Marcela Gómez',
        rut: '14.567.890-0',
        age: 74,
        cabinetItems: [
          MedicineCabinetItem(
            id: 'med-eutirox',
            name: 'Eutirox (Levotiroxina)',
            dosage: '100 mcg',
            ispRegister: 'F-18451/20',
            isBioequivalent: true,
            lotNumber: 'M10492',
            expirationDate: '10/2027',
          ),
          MedicineCabinetItem(
            id: 'med-losartan',
            name: 'Losartán Potásico',
            dosage: '50 mg',
            ispRegister: 'F-14920/19',
            isBioequivalent: true,
            lotNumber: 'K44019',
            expirationDate: '03/2027',
          ),
        ],
        vitalSigns: [
          VitalSignEntry(
            id: 'vs-1',
            patientId: 'patient-marcela-test',
            timestamp: DateTime(2026, 10, 2, 10, 30),
            systolic: 124,
            diastolic: 78,
            heartRate: 72,
            notes: 'Control en meta terapéutica PSCV',
          ),
        ],
      );
    });

    test('generateFhirR4Bundle produces valid HL7 FHIR Document Bundle with Chilean Core profiles', () {
      final bundle = fhirService.generateFhirR4Bundle(testPatient);

      expect(bundle['resourceType'], equals('Bundle'));
      expect(bundle['type'], equals('document'));
      expect(bundle['entry'], isA<List>());
      expect(fhirService.validateBundle(bundle), isTrue);

      final entries = bundle['entry'] as List;

      // 1. Composition
      final compositionEntry = entries.firstWhere(
        (e) => e['resource']['resourceType'] == 'Composition',
      );
      expect(compositionEntry, isNotNull);
      expect(compositionEntry['resource']['title'], contains('Ficha Clínica'));

      // 2. Patient with Chilean RUN
      final patientEntry = entries.firstWhere(
        (e) => e['resource']['resourceType'] == 'Patient',
      );
      expect(patientEntry, isNotNull);
      final patientRes = patientEntry['resource'];
      expect(patientRes['name'][0]['text'], equals('Marcela Gómez'));
      expect(patientRes['identifier'][0]['value'], equals('14.567.890-0'));
      expect(patientRes['identifier'][0]['system'], contains('regcivil.cl'));

      // 3. MedicationStatements with ISP Register
      final medStatements = entries.where(
        (e) => e['resource']['resourceType'] == 'MedicationStatement',
      ).toList();
      expect(medStatements.length, equals(2));
      final eutirox = medStatements.first['resource'];
      expect(eutirox['medicationCodeableConcept']['coding'][0]['code'], equals('F-18451/20'));
      expect(eutirox['note'][0]['text'], contains('Bioequivalente ISP'));

      // 4. Observation with LOINC Codes
      final observations = entries.where(
        (e) => e['resource']['resourceType'] == 'Observation',
      ).toList();
      expect(observations.isNotEmpty, isTrue);
      final obs = observations.first['resource'];
      expect(obs['code']['coding'][0]['code'], equals('85354-9')); // LOINC BP Panel
      final components = obs['component'] as List;
      expect(components.any((c) => c['code']['coding'][0]['code'] == '8480-6'), isTrue); // Systolic
      expect(components.any((c) => c['code']['coding'][0]['code'] == '8462-4'), isTrue); // Diastolic
      expect(components.any((c) => c['code']['coding'][0]['code'] == '8478-0'), isTrue); // MAP
    });

    test('generateHl7V2Message produces valid ER7 pipe-delimited message for Rayen Salud / Saydex', () {
      final hl7 = fhirService.generateHl7V2Message(testPatient);

      expect(hl7, contains('MSH|^~\\&|CHRONOMED|'));
      expect(hl7, contains('RAYEN_SALUD|MINSAL|'));
      expect(hl7, contains('PID|1||14567890-0^^^CHILE^NNCHL||Gómez^Marcela'));
      expect(hl7, contains('PV1|1|O|APS-CESFAM^^^PSCV'));
      expect(hl7, contains('DG1|1|ICD10|I10|Hipertensión Arterial Primaria'));
      expect(hl7, contains('RXE|1|F-18451/20^Eutirox (Levotiroxina)^ISP'));
      expect(hl7, contains('OBR|1||VS'));
      expect(hl7, contains('85354-9^Presión Arterial y Signos Vitales^LN'));
      expect(hl7, contains('8480-6^Presion Sistolica^LN||124|mm[Hg]'));
      expect(hl7, contains('8462-4^Presion Diastolica^LN||78|mm[Hg]'));
    });

    test('toPrettyJson serializes FHIR Bundle into valid formatted JSON string', () {
      final bundle = fhirService.generateFhirR4Bundle(testPatient);
      final jsonStr = fhirService.toPrettyJson(bundle);

      expect(jsonStr, isNotEmpty);
      final decoded = jsonDecode(jsonStr);
      expect(decoded['resourceType'], equals('Bundle'));
      expect(decoded['total'], equals(bundle['total']));
    });
  });
}

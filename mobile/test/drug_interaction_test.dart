import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronomed/features/ocr/services/drug_interaction_service.dart';
import 'package:chronomed/features/ocr/services/prescription_parser_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChronoMed Drug Interaction & Prescription OCR Test Suite', () {
    late DrugInteractionService interactionService;
    late PrescriptionParserService parserService;

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('google_mlkit_text_recognizer'),
        (MethodCall methodCall) async => null,
      );
      interactionService = DrugInteractionService.instance;
      parserService = PrescriptionParserService();
    });

    tearDown(() {
      try {
        parserService.dispose();
      } catch (_) {}
    });

    test('Compatible candidate returns zero clinical conflicts', () {
      final active = ['Losartán 50 mg', 'Eutirox 100 mcg', 'Atorvastatina 20 mg'];
      final result = interactionService.evaluateCandidate('Paracetamol', active);

      expect(result.severity, equals(InteractionSeverity.none));
      expect(result.hasConflict, isFalse);
      expect(result.isBlocking, isFalse);
    });

    test('Critical Contraindication: Atorvastatin + Clarithromycin blocks with rhabdomyolysis alert', () {
      final active = ['Atorvastatina 20 mg', 'Losartán 50 mg'];
      final result = interactionService.evaluateCandidate('Claritromicina 500 mg', active);

      expect(result.severity, equals(InteractionSeverity.criticalContraindication));
      expect(result.hasConflict, isTrue);
      expect(result.isBlocking, isTrue);
      expect(result.title, contains('CONTRAINDICACIÓN CRÍTICA'));
      expect(result.clinicalRisk, contains('Rabdomiólisis'));
    });

    test('Critical Contraindication: Acenocoumarol + Ibuprofen blocks with hemorrhage alert', () {
      final active = ['Acenocumarol 4 mg (Neosintrom)', 'Eutirox 100 mcg'];
      final result = interactionService.evaluateCandidate('Ibuprofeno 600 mg', active);

      expect(result.severity, equals(InteractionSeverity.criticalContraindication));
      expect(result.hasConflict, isTrue);
      expect(result.isBlocking, isTrue);
      expect(result.clinicalRisk, contains('Hemorragia'));
    });

    test('Major Warning: Losartan + Spironolactone alerts regarding hyperkalemia', () {
      final active = ['Losartán 50 mg'];
      final result = interactionService.evaluateCandidate('Espironolactona 25 mg', active);

      expect(result.severity, equals(InteractionSeverity.majorWarning));
      expect(result.hasConflict, isTrue);
      expect(result.isBlocking, isFalse);
      expect(result.clinicalRisk, contains('Hiperpotasemia'));
    });

    test('Dietary Restriction: Levothyroxine alerts regarding dairy/calcium chelation', () {
      final active = ['Losartán 50 mg'];
      final result = interactionService.evaluateCandidate('Eutirox (Levotiroxina) 100 mcg', active);

      expect(result.severity, equals(InteractionSeverity.foodRestriction));
      expect(result.hasConflict, isTrue);
      expect(result.isBlocking, isFalse);
      expect(result.recommendation, contains('ayuno'));
    });

    test('Dietary Restriction: Metformin alerts regarding alcohol prohibition', () {
      final active = ['Losartán 50 mg'];
      final result = interactionService.evaluateCandidate('Metformina 850 mg', active);

      expect(result.severity, equals(InteractionSeverity.foodRestriction));
      expect(result.hasConflict, isTrue);
      expect(result.recommendation, contains('alcohólicas'));
    });

    test('RegimenSafetyReport evaluates multiple active drugs with dietary precautions and no critical contraindications', () {
      final active = ['Eutirox 100 mcg', 'Losartán 50 mg', 'Atorvastatina 20 mg'];
      final report = interactionService.evaluateActiveRegimen(active);

      expect(report.totalDrugs, equals(3));
      expect(report.hasCritical, isFalse);
      expect(report.hasWarnings, isFalse);
      expect(report.hasDietaryRestrictions, isTrue);
      expect(report.isCompletelySafe, isTrue);
      expect(report.dietaryPrecautions.any((d) => d.title.contains('LÁCTEOS')), isTrue);
      expect(report.dietaryPrecautions.any((d) => d.title.contains('POMELO')), isTrue);
    });

    test('Critical Contraindication: Dual RAAS blockade (Enalapril + Losartan) blocks with acute kidney injury alert', () {
      final active = ['Losartán 50 mg'];
      final result = interactionService.evaluateCandidate('Enalapril 10 mg', active);

      expect(result.severity, equals(InteractionSeverity.criticalContraindication));
      expect(result.hasConflict, isTrue);
      expect(result.isBlocking, isTrue);
      expect(result.title, contains('DOBLE BLOQUEO SRAA'));
      expect(result.clinicalRisk, contains('Fallo renal agudo'));
    });

    test('Critical Contraindication: Digoxin + Amiodarone blocks with digitalis toxicity alert', () {
      final active = ['Digoxina 0.25 mg (Lanicor)'];
      final result = interactionService.evaluateCandidate('Amiodarona 200 mg', active);

      expect(result.severity, equals(InteractionSeverity.criticalContraindication));
      expect(result.hasConflict, isTrue);
      expect(result.isBlocking, isTrue);
      expect(result.title, contains('INTOXICACIÓN DIGITÁLICA'));
      expect(result.clinicalRisk, contains('duplicando la digoxinemia'));
    });

    test('Critical Contraindication: NSAID + Systemic Corticosteroid blocks with gastrointestinal hemorrhage alert', () {
      final active = ['Prednisona 20 mg'];
      final result = interactionService.evaluateCandidate('Ketoprofeno 200 mg', active);

      expect(result.severity, equals(InteractionSeverity.criticalContraindication));
      expect(result.hasConflict, isTrue);
      expect(result.isBlocking, isTrue);
      expect(result.title, contains('HEMORRAGIA DIGESTIVA'));
      expect(result.clinicalRisk, contains('10 veces'));
    });

    test('Critical Contraindication: Benzodiazepine + Opioid blocks with respiratory arrest alert', () {
      final active = ['Clonazepam 0.5 mg'];
      final result = interactionService.evaluateCandidate('Tramadol 50 mg', active);

      expect(result.severity, equals(InteractionSeverity.criticalContraindication));
      expect(result.hasConflict, isTrue);
      expect(result.isBlocking, isTrue);
      expect(result.clinicalRisk, contains('parada respiratoria'));
    });

    test('Major Warning: Clopidogrel + Omeprazole warns about antiplatelet inhibition', () {
      final active = ['Clopidogrel 75 mg'];
      final result = interactionService.evaluateCandidate('Omeprazol 20 mg', active);

      expect(result.severity, equals(InteractionSeverity.majorWarning));
      expect(result.hasConflict, isTrue);
      expect(result.isBlocking, isFalse);
      expect(result.title, contains('PÉRDIDA EFECTO ANTIAGREGANTE'));
      expect(result.clinicalRisk, contains('trombosis del stent'));
    });

    test('Major Warning: Benzodiazepine + Sedating Antihistamine warns about falls and delirium', () {
      final active = ['Clonazepam 0.5 mg'];
      final result = interactionService.evaluateCandidate('Clorfenamina 4 mg', active);

      expect(result.severity, equals(InteractionSeverity.majorWarning));
      expect(result.hasConflict, isTrue);
      expect(result.isBlocking, isFalse);
      expect(result.title, contains('SEDACIÓN Y CAÍDAS'));
      expect(result.clinicalRisk, contains('Beers'));
    });

    test('Major Warning: Allopurinol + Azathioprine warns about severe myelotoxicity', () {
      final active = ['Alopurinol 100 mg'];
      final result = interactionService.evaluateCandidate('Azatioprina 50 mg', active);

      expect(result.severity, equals(InteractionSeverity.majorWarning));
      expect(result.hasConflict, isTrue);
      expect(result.isBlocking, isFalse);
      expect(result.title, contains('MIELOTOXICIDAD SEVERA'));
      expect(result.clinicalRisk, contains('pancitopenia'));
    });

    test('Major Warning: RAAS + NSAID warns about reduced GFR and blood pressure control', () {
      final active = ['Enalapril 10 mg'];
      final result = interactionService.evaluateCandidate('Diclofenaco 50 mg', active);

      expect(result.severity, equals(InteractionSeverity.majorWarning));
      expect(result.hasConflict, isTrue);
      expect(result.isBlocking, isFalse);
      expect(result.clinicalRisk, contains('filtrado glomerular'));
    });

    test('Dietary Restriction: Oral Anticoagulant alerts regarding Vitamin K stabilization', () {
      final active = ['Paracetamol 500 mg'];
      final result = interactionService.evaluateCandidate('Warfarina 5 mg', active);

      expect(result.severity, equals(InteractionSeverity.foodRestriction));
      expect(result.hasConflict, isTrue);
      expect(result.isBlocking, isFalse);
      expect(result.title, contains('VITAMINA K'));
      expect(result.clinicalRisk, contains('INR terapéutico'));
    });

    test('Dietary Restriction: Furosemide alerts regarding potassium loss and dehydration', () {
      final active = ['Paracetamol 500 mg'];
      final result = interactionService.evaluateCandidate('Furosemida 40 mg', active);

      expect(result.severity, equals(InteractionSeverity.foodRestriction));
      expect(result.hasConflict, isTrue);
      expect(result.isBlocking, isFalse);
      expect(result.title, contains('CONTROL DE POTASIO'));
      expect(result.clinicalRisk, contains('hipopotasemia'));
    });

    test('RegimenSafetyReport catches critical contraindications between active drugs', () {
      final active = ['Acenocumarol 4 mg', 'Ibuprofeno 600 mg', 'Paracetamol 500 mg'];
      final report = interactionService.evaluateActiveRegimen(active);

      expect(report.hasCritical, isTrue);
      expect(report.isCompletelySafe, isFalse);
      expect(report.criticalAlerts.first.clinicalRisk, contains('Hemorragia'));
    });

    test('PrescriptionParser extracts drug name, dosage, frequency and meal relation', () {
      const rawRx = '''
      RECETA MEDICA CESFAM
      RP: CLARITROMICINA 500 mg
      1 COMPRIMIDO CADA 12 HORAS CON ALIMENTOS POR 7 DIAS
      ''';

      final parsed = parserService.parseRawText(rawRx);

      expect(parsed.detectedDrugName, isNotNull);
      expect(parsed.detectedDosage, equals('500 mg'));
      expect(parsed.detectedFrequencyHours, equals(12));
      expect(parsed.detectedMealRelation, equals('WITH_MEAL'));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:chronomed/features/ocr/models/medicine_box_scan_result.dart';
import 'package:chronomed/features/ocr/services/medicine_box_scanner_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MedicineBoxScannerService Test Suite', () {
    late MedicineBoxScannerService service;
    final fixedToday = DateTime(2026, 9, 22);

    setUp(() {
      service = MedicineBoxScannerService();
    });

    tearDown(() {
      service.dispose();
    });

    test('Parses valid Chilean medication box correctly with green status', () {
      const ocrText = '''
        LABORATORIO CHILE
        LOSARTAN POTASICO 50 mg
        30 comprimidos recubiertos
        LOTE: 24A09
        VENCE: 12/2028
        Vía Oral - Venta Bajo Receta Médica
      ''';

      final result = service.parseRawText(ocrText, referenceDate: fixedToday);

      expect(result.detectedDrugName, equals('Losartán'));
      expect(result.detectedDosage, equals('50 mg'));
      expect(result.detectedUnits, equals(30));
      expect(result.detectedLotNumber, equals('24A09'));
      expect(result.detectedExpirationDate, equals('12/2028'));
      expect(result.expirationStatus, equals(BoxExpirationStatus.valid));
      expect(result.daysRemaining, greaterThan(700));
      expect(result.isAlertActive, isFalse);
      expect(result.statusLabel, contains('VIGENTE'));
    });

    test('Identifies medication box expiring soon (< 60 days) and triggers warning alert', () {
      const ocrText = '''
        MERCK CHILE
        EUTIROX 100 mcg
        50 comprimidos
        LOT: E8821
        EXP: 10/2026
      ''';

      final result = service.parseRawText(ocrText, referenceDate: fixedToday);

      expect(result.detectedDrugName, equals('Eutirox'));
      expect(result.detectedDosage, equals('100 mcg'));
      expect(result.detectedUnits, equals(50));
      expect(result.detectedLotNumber, equals('E8821'));
      expect(result.detectedExpirationDate, equals('10/2026'));
      expect(result.expirationStatus, equals(BoxExpirationStatus.expiringSoon));
      expect(result.daysRemaining, lessThan(60));
      expect(result.daysRemaining, greaterThan(0));
      expect(result.isAlertActive, isTrue);
      expect(result.statusLabel, contains('POR VENCER'));
    });

    test('Identifies expired medication box and activates critical safety alert', () {
      const ocrText = '''
        PFIZER CHILE
        ATORVASTATINA 20 mg
        30 tabletas
        LOTE 19K01
        VTO: 01/2023
      ''';

      final result = service.parseRawText(ocrText, referenceDate: fixedToday);

      expect(result.detectedDrugName, equals('Atorvastatina'));
      expect(result.detectedDosage, equals('20 mg'));
      expect(result.detectedUnits, equals(30));
      expect(result.detectedLotNumber, equals('19K01'));
      expect(result.detectedExpirationDate, equals('01/2023'));
      expect(result.expirationStatus, equals(BoxExpirationStatus.expired));
      expect(result.daysRemaining, lessThan(0));
      expect(result.isAlertActive, isTrue);
      expect(result.statusLabel, equals('VENCIDO - NO INGERIR'));
    });

    test('Handles packaging with missing expiration date gracefully', () {
      const ocrText = '''
        METFORMINA 850 mg
        60 capsulas
      ''';

      final result = service.parseRawText(ocrText, referenceDate: fixedToday);

      expect(result.detectedDrugName, equals('Metformina'));
      expect(result.detectedDosage, equals('850 mg'));
      expect(result.detectedUnits, equals(60));
      expect(result.detectedLotNumber, isNull);
      expect(result.detectedExpirationDate, isNull);
      expect(result.expirationStatus, equals(BoxExpirationStatus.unknown));
      expect(result.isAlertActive, isFalse);
    });
  });
}

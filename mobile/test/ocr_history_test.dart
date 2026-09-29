import 'package:flutter_test/flutter_test.dart';
import 'package:chronomed/features/ocr/models/ocr_scan_history_entry.dart';
import 'package:chronomed/core/services/ocr_history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChronoMed OCR Scan History Test Suite', () {
    late OcrHistoryService service;

    setUp(() async {
      service = OcrHistoryService.instance;
      await service.init();
    });

    test('OcrScanHistoryEntry serializes and deserializes properly with Chilean ISP data', () {
      final entry = OcrScanHistoryEntry(
        id: 'test-scan-01',
        scanType: OcrScanType.medicineBox,
        scannedAt: DateTime(2026, 9, 29, 10, 0),
        extractedText: 'LOSARTAN POTASICO 50mg REG ISP F-14920/19 BIOEQUIVALENTE',
        medicineName: 'Losartán Potásico',
        dosage: '50 mg',
        ispRegister: 'F-14920/19',
        isBioequivalent: true,
        interactionsDetected: const [],
        wasAccepted: true,
      );

      final json = entry.toJson();
      expect(json['id'], equals('test-scan-01'));
      expect(json['scanType'], equals('medicineBox'));
      expect(json['medicineName'], equals('Losartán Potásico'));
      expect(json['ispRegister'], equals('F-14920/19'));
      expect(json['isBioequivalent'], isTrue);

      final restored = OcrScanHistoryEntry.fromJson(json);
      expect(restored.id, equals(entry.id));
      expect(restored.scanType, equals(entry.scanType));
      expect(restored.medicineName, equals(entry.medicineName));
      expect(restored.isBioequivalent, isTrue);
    });

    test('OcrHistoryService filters entries by scan type and interaction flags', () async {
      final all = service.allEntries;
      expect(all.isNotEmpty, isTrue);

      final boxes = service.getEntries(filterType: OcrScanType.medicineBox);
      expect(boxes.every((e) => e.scanType == OcrScanType.medicineBox), isTrue);

      final rxs = service.getEntries(filterType: OcrScanType.prescription);
      expect(rxs.every((e) => e.scanType == OcrScanType.prescription), isTrue);

      final alerts = service.getEntries(onlyWithInteractions: true);
      expect(alerts.every((e) => e.interactionsDetected.isNotEmpty), isTrue);
    });

    test('OcrHistoryService adds and deletes entries', () async {
      final initialCount = service.allEntries.length;
      final newEntry = OcrScanHistoryEntry(
        id: 'new-scan-${DateTime.now().millisecondsSinceEpoch}',
        scanType: OcrScanType.medicineBox,
        scannedAt: DateTime.now(),
        extractedText: 'ATORVASTATINA 20mg',
        medicineName: 'Atorvastatina',
        dosage: '20 mg',
      );

      await service.addEntry(newEntry);
      expect(service.allEntries.length, equals(initialCount + 1));
      expect(service.allEntries.first.id, equals(newEntry.id));

      await service.deleteEntry(newEntry.id);
      expect(service.allEntries.length, equals(initialCount));
    });
  });
}

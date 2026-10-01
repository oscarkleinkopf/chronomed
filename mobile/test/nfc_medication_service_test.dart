import 'package:flutter_test/flutter_test.dart';
import 'package:chronomed/core/storage/local_storage_service.dart';
import 'package:chronomed/core/services/nfc_medication_service.dart';
import 'package:chronomed/features/medicine_cabinet/models/medicine_cabinet_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChronoMed NFC Medication Service & Smart Pillbox Test Suite', () {
    late LocalStorageService storage;
    late NfcMedicationService nfcService;

    setUp(() async {
      storage = LocalStorageService.instance;
      nfcService = NfcMedicationService.instance;

      await storage.init(inMemory: true);
      await storage.resetAllData();
    });

    test('Initializes service with hardware available and idle state', () {
      expect(nfcService.isHardwareAvailable, isTrue);
      expect(nfcService.isListening, isFalse);
    });

    test('Pairs an NTAG215 tag to a medicine item and retrieves it correctly', () async {
      final items = storage.getCabinetItems();
      expect(items, isNotEmpty);
      final targetMed = items.first; // e.g. Losartán

      const testTagId = '04:A2:3B:5C:88:10:9A';

      // Verify no tag linked yet
      expect(targetMed.hasNfcTag, isFalse);
      expect(storage.getMedicineByNfcTag(testTagId), isNull);

      // Pair tag
      final success = await nfcService.pairTagToMedicine(
        medicineId: targetMed.id,
        tagId: testTagId,
      );
      expect(success, isTrue);

      // Lookup by tag ID
      final retrieved = storage.getMedicineByNfcTag(testTagId);
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals(targetMed.id));
      expect(retrieved.nfcTagId, equals(testTagId));
      expect(retrieved.hasNfcTag, isTrue);
      expect(retrieved.nfcPayload, contains(targetMed.id));
    });

    test('Clinical Safety: validates exact match against expected medication', () async {
      final items = storage.getCabinetItems();
      final losartan = items.firstWhere((i) => i.name.toLowerCase().contains('losart'));

      const losartanTag = '04:11:22:33:44:55:66';
      await nfcService.pairTagToMedicine(
        medicineId: losartan.id,
        tagId: losartanTag,
      );

      // Process scan expecting Losartán
      final result = await nfcService.processTag(
        rawTagId: losartanTag,
        expectedMedicineName: 'Losartán Potásico',
      );

      expect(result.matchType, equals(NfcScanMatchType.matchedExpected));
      expect(result.isSuccess, isTrue);
      expect(result.isWarning, isFalse);
      expect(result.matchedMedicine?.id, equals(losartan.id));
      expect(result.message, contains('validado exitosamente'));
    });

    test('Clinical Safety: detects mismatched tag (different drug in cabinet) and triggers alert', () async {
      final items = storage.getCabinetItems();
      final losartan = items.firstWhere((i) => i.name.toLowerCase().contains('losart'));
      final atorvastatina = items.firstWhere((i) => i.name.toLowerCase().contains('atorvastatina'));

      const atorvaTag = '04:99:88:77:66:55:44';
      await nfcService.pairTagToMedicine(
        medicineId: atorvastatina.id,
        tagId: atorvaTag,
      );

      // Patient was supposed to take Losartán, but scanned Atorvastatina box
      final result = await nfcService.processTag(
        rawTagId: atorvaTag,
        expectedMedicineName: losartan.name,
      );

      expect(result.matchType, equals(NfcScanMatchType.mismatchedDifferent));
      expect(result.isSuccess, isFalse);
      expect(result.isWarning, isTrue);
      expect(result.matchedMedicine?.name, equals(atorvastatina.name));
      expect(result.message, contains('¡Alerta de Medicamento Erróneo!'));
    });

    test('Reports unregistered tag when scanning an unlinked NFC sticker', () async {
      const unknownTag = '04:00:11:22:33:44:55';

      final result = await nfcService.processTag(
        rawTagId: unknownTag,
        expectedMedicineName: 'Losartán Potásico',
      );

      expect(result.matchType, equals(NfcScanMatchType.unregisteredTag));
      expect(result.isUnregistered, isTrue);
      expect(result.matchedMedicine, isNull);
      expect(result.message, contains('no está vinculado a ningún fármaco'));
    });

    test('Unpairs an NFC tag cleanly from medicine item', () async {
      final items = storage.getCabinetItems();
      final med = items.first;
      const testTag = '04:AA:BB:CC:DD:EE:FF';

      await nfcService.pairTagToMedicine(medicineId: med.id, tagId: testTag);
      expect(storage.getMedicineByNfcTag(testTag), isNotNull);

      // Unpair
      final unpairSuccess = await nfcService.unpairTagFromMedicine(med.id);
      expect(unpairSuccess, isTrue);

      expect(storage.getMedicineByNfcTag(testTag), isNull);
      final updatedMed = storage.getCabinetItem(med.id);
      expect(updatedMed?.hasNfcTag, isFalse);
      expect(updatedMed?.nfcTagId, isNull);
    });

    test('Emits scan results reactively over onTagScanned broadcast stream', () async {
      final items = storage.getCabinetItems();
      final med = items.first;
      const streamTag = '04:77:77:77:77:77:77';

      await nfcService.pairTagToMedicine(medicineId: med.id, tagId: streamTag);

      final receivedResults = <NfcTagScanResult>[];
      final subscription = nfcService.onTagScanned.listen((res) {
        receivedResults.add(res);
      });

      await nfcService.simulateTagScan(streamTag, expectedMedicineName: med.name);

      expect(receivedResults.length, equals(1));
      expect(receivedResults.first.tagId, equals(streamTag));
      expect(receivedResults.first.isSuccess, isTrue);

      await subscription.cancel();
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:chronomed/core/storage/local_storage_service.dart';
import 'package:chronomed/features/medicine_cabinet/models/medicine_cabinet_item.dart';
import 'package:chronomed/features/ocr/models/medicine_box_scan_result.dart';
import 'package:chronomed/features/senior_mode/models/senior_intake_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChronoMed Medicine Cabinet & Chilean Inventory Test Suite', () {
    late LocalStorageService storage;

    setUp(() async {
      storage = LocalStorageService.instance;
      await storage.init(inMemory: true);
      await storage.resetAllData();
    });

    test('Initializes cabinet with default Chilean medications (ISP & Bioequivalence certified)', () {
      final items = storage.getCabinetItems();
      expect(items.length, equals(3));

      final eutirox = items.firstWhere((i) => i.name.contains('Eutirox'));
      expect(eutirox.stockUnits, equals(28));
      expect(eutirox.isBioequivalent, isTrue);
      expect(eutirox.ispRegister, equals('F-18451/20'));

      final losartan = items.firstWhere((i) => i.name.contains('Losartán'));
      expect(losartan.stockUnits, equals(14));
      expect(losartan.isBioequivalent, isTrue);
      expect(losartan.ispRegister, equals('F-14920/19'));

      final atorvastatina = items.firstWhere((i) => i.name.contains('Atorvastatina'));
      expect(atorvastatina.stockUnits, equals(30));
      expect(atorvastatina.isBioequivalent, isTrue);
      expect(atorvastatina.ispRegister, equals('F-16203/21'));
    });

    test('Converts MedicineBoxScanResult from OCR into MedicineCabinetItem with ISP & bioequivalence', () {
      final scanResult = MedicineBoxScanResult(
        rawText: 'PARACETAMOL 500 MG BIOEQUIVALENTE REG ISP F-20345/21 LOTE 44B12 VENCE 11/2027 30 COMPRIMIDOS',
        detectedDrugName: 'PARACETAMOL',
        detectedDosage: '500 mg',
        detectedUnits: 30,
        detectedLotNumber: '44B12',
        detectedExpirationDate: '11/2027',
        detectedIspRegister: 'F-20345/21',
        isBioequivalent: true,
        expirationStatus: BoxExpirationStatus.valid,
      );

      final item = MedicineCabinetItem.fromScanResult(scanResult);

      expect(item.name, equals('PARACETAMOL'));
      expect(item.dosage, equals('500 mg'));
      expect(item.stockUnits, equals(30));
      expect(item.lotNumber, equals('44B12'));
      expect(item.expirationDate, equals('11/2027'));
      expect(item.ispRegister, equals('F-20345/21'));
      expect(item.isBioequivalent, isTrue);
      expect(item.expirationStatus, equals(BoxExpirationStatus.valid));
      expect(item.imprint, equals('500'));
      expect(item.hasScoreLine, isTrue);
    });

    test('MedicineCabinetItem serializes to JSON and deserializes correctly', () {
      final original = MedicineCabinetItem(
        id: 'test-item-1',
        name: 'Metformina Clorhidrato',
        dosage: '850 mg',
        stockUnits: 60,
        lotNumber: 'L-9988',
        expirationDate: '06/2029',
        ispRegister: 'F-11223/18',
        isBioequivalent: true,
        expirationStatus: BoxExpirationStatus.valid,
        shapeType: 'oblong',
        pillColorValue: 0xFFFFFFFF,
        imprint: '850',
        hasScoreLine: true,
        physicalDescription: 'Comprimido oblongo blanco grande ranurado',
        nfcTagId: '04:A1:B2:C3:D4:E5:F6',
        nfcPayload: 'chronomed://med/test-item-1',
      );

      final json = original.toJson();
      final restored = MedicineCabinetItem.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.dosage, equals(original.dosage));
      expect(restored.stockUnits, equals(60));
      expect(restored.lotNumber, equals('L-9988'));
      expect(restored.expirationDate, equals('06/2029'));
      expect(restored.ispRegister, equals('F-11223/18'));
      expect(restored.isBioequivalent, isTrue);
      expect(restored.expirationStatus, equals(BoxExpirationStatus.valid));
      expect(restored.shapeType, equals('oblong'));
      expect(restored.imprint, equals('850'));
      expect(restored.hasScoreLine, isTrue);
      expect(restored.hasNfcTag, isTrue);
      expect(restored.nfcTagId, equals('04:A1:B2:C3:D4:E5:F6'));
      expect(restored.nfcPayload, equals('chronomed://med/test-item-1'));
    });

    test('Cabinet CRUD operations synchronize stock units with fast lookup map', () async {
      final newItem = MedicineCabinetItem(
        id: 'paracetamol-id',
        name: 'Paracetamol',
        dosage: '500 mg',
        stockUnits: 20,
      );

      // Add item
      await storage.saveCabinetItem(newItem);
      expect(storage.getCabinetItems().length, equals(4));
      expect(storage.getCabinetItem('paracetamol-id')?.stockUnits, equals(20));
      expect(storage.getStock('paracetamol'), equals(20));

      // Update stock via updateCabinetStock
      await storage.updateCabinetStock('paracetamol-id', 25);
      expect(storage.getCabinetItem('paracetamol-id')?.stockUnits, equals(25));
      expect(storage.getStock('paracetamol'), equals(25));

      // Synchronize when decrementStock is called on LocalStorageService
      await storage.decrementStock('paracetamol', units: 3);
      expect(storage.getStock('paracetamol'), equals(22));
      expect(storage.getCabinetItem('paracetamol-id')?.stockUnits, equals(22));

      // Delete item
      await storage.deleteCabinetItem('paracetamol-id');
      expect(storage.getCabinetItems().length, equals(3));
      expect(storage.getCabinetItem('paracetamol-id'), isNull);
    });

    test('Zero Data Loss: backup JSON preserves full medicine cabinet and restores correctly', () async {
      // Add custom medicine with Chilean ISP and bioequivalence
      final customMed = MedicineCabinetItem(
        id: 'clorfenamina-1',
        name: 'Clorfenamina Maleato',
        dosage: '4 mg',
        stockUnits: 15,
        ispRegister: 'F-9876/15',
        isBioequivalent: false,
        lotNumber: 'CF-11',
        nfcTagId: '04:88:99:AA:BB:CC:DD',
      );
      await storage.saveCabinetItem(customMed);
      await storage.updateCabinetStock('default-losartan', 99);

      // Export backup
      final backupJson = storage.exportBackupJson();
      expect(backupJson, contains('Clorfenamina Maleato'));
      expect(backupJson, contains('F-9876/15'));
      expect(backupJson, contains('04:88:99:AA:BB:CC:DD'));
      expect(backupJson, contains('"stockUnits":99'));

      // Factory reset
      await storage.resetAllData();
      expect(storage.getCabinetItems().length, equals(3));
      expect(storage.getCabinetItem('clorfenamina-1'), isNull);
      expect(storage.getStock('losartan'), equals(14));

      // Restore backup
      await storage.importBackupJson(backupJson);
      expect(storage.getCabinetItems().length, equals(4));
      final restoredClorfenamina = storage.getCabinetItem('clorfenamina-1');
      expect(restoredClorfenamina, isNotNull);
      expect(restoredClorfenamina!.ispRegister, equals('F-9876/15'));
      expect(restoredClorfenamina.hasNfcTag, isTrue);
      expect(restoredClorfenamina.nfcTagId, equals('04:88:99:AA:BB:CC:DD'));
      expect(storage.getStock('losartan'), equals(99));
    });
  });
}

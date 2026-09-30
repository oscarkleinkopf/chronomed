import 'package:flutter/material.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/services/ocr_history_service.dart';
import '../../medicine_cabinet/models/medicine_cabinet_item.dart';
import '../../ocr/models/medicine_box_scan_result.dart';
import '../../ocr/models/prescription_scan_result.dart';
import '../../ocr/models/ocr_scan_history_entry.dart';
import '../../ocr/widgets/medicine_box_scanner_dialog.dart';
import '../../ocr/widgets/prescription_scanner_dialog.dart';
import '../../ocr/screens/ocr_scan_history_screen.dart';

class CaregiverOcrController extends ChangeNotifier {
  int eutiroxStock = 28;
  int losartanStock = 14;
  int atorvastatinaStock = 30;

  void loadStock() {
    final storage = LocalStorageService.instance;
    eutiroxStock = storage.getStock('eutirox', fallback: 28);
    losartanStock = storage.getStock('losartan', fallback: 14);
    atorvastatinaStock = storage.getStock('atorvastatina', fallback: 30);
    notifyListeners();
  }

  void openPrescriptionScanner(BuildContext context) {
    final activeCabinet = LocalStorageService.instance.getCabinetItems();
    final activeNames = activeCabinet.map((c) => c.name).toList();

    showDialog(
      context: context,
      builder: (ctx) => PrescriptionScannerDialog(
        activeMedications: activeNames,
        onPrescriptionAccepted: (result) => handlePrescriptionAccepted(context, result),
      ),
    );
  }

  void handlePrescriptionAccepted(BuildContext context, PrescriptionScanResult result) {
    final drugName = result.detectedDrugName ?? 'Fármaco Prescrito';
    final dosage = result.detectedDosage ?? '';

    final newItem = MedicineCabinetItem(
      id: 'prescription-${DateTime.now().millisecondsSinceEpoch}',
      name: drugName,
      dosage: dosage,
      stockUnits: 30,
      physicalDescription: 'Prescrito según receta: Cada ${result.detectedFrequencyHours ?? 8} hrs.',
    );

    LocalStorageService.instance.saveCabinetItem(newItem);

    OcrHistoryService.instance.addEntry(
      OcrScanHistoryEntry(
        id: 'scan-rx-${DateTime.now().millisecondsSinceEpoch}',
        scanType: OcrScanType.prescription,
        scannedAt: DateTime.now(),
        extractedText: result.rawText,
        medicineName: drugName,
        dosage: dosage,
        interactionsDetected: const [],
        wasAccepted: true,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0284C7),
        content: Text(
          '📋 Receta incorporada: $drugName $dosage (Cada ${result.detectedFrequencyHours ?? 8}h, ${result.detectedMealRelation == "FASTING" ? "en ayunas" : "habitual"}).',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  void openMedicineBoxScanner(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => MedicineBoxScannerDialog(
        onStockUpdated: (result) => handleBoxStockUpdated(context, result),
      ),
    );
  }

  void handleBoxStockUpdated(BuildContext context, MedicineBoxScanResult result) {
    final drug = result.detectedDrugName?.toLowerCase() ?? '';
    final units = result.detectedUnits ?? 30;

    final cabinetItems = LocalStorageService.instance.getCabinetItems();
    final existingIndex = cabinetItems.indexWhere((i) {
      final a = i.name.toLowerCase().trim();
      final b = (result.detectedDrugName ?? '').toLowerCase().trim();
      return a == b || (result.detectedIspRegister != null && i.ispRegister == result.detectedIspRegister);
    });

    if (existingIndex >= 0) {
      final existing = cabinetItems[existingIndex];
      LocalStorageService.instance.saveCabinetItem(existing.copyWith(
        stockUnits: existing.stockUnits + units,
        lotNumber: result.detectedLotNumber ?? existing.lotNumber,
        expirationDate: result.detectedExpirationDate ?? existing.expirationDate,
        ispRegister: result.detectedIspRegister ?? existing.ispRegister,
        isBioequivalent: result.isBioequivalent || existing.isBioequivalent,
      ));
    } else {
      LocalStorageService.instance.saveCabinetItem(MedicineCabinetItem.fromScanResult(result));
    }

    OcrHistoryService.instance.addEntry(
      OcrScanHistoryEntry(
        id: 'scan-box-${DateTime.now().millisecondsSinceEpoch}',
        scanType: OcrScanType.medicineBox,
        scannedAt: DateTime.now(),
        extractedText: result.rawText,
        medicineName: result.detectedDrugName,
        dosage: result.detectedDosage,
        ispRegister: result.detectedIspRegister,
        isBioequivalent: result.isBioequivalent,
        interactionsDetected: const [],
        wasAccepted: true,
      ),
    );

    if (drug.contains('losart')) {
      losartanStock += units;
      LocalStorageService.instance.setStock('losartan', losartanStock);
    } else if (drug.contains('eutirox') || drug.contains('levotiroxina')) {
      eutiroxStock += units;
      LocalStorageService.instance.setStock('eutirox', eutiroxStock);
    } else if (drug.contains('atorvastatina')) {
      atorvastatinaStock += units;
      LocalStorageService.instance.setStock('atorvastatina', atorvastatinaStock);
    }
    notifyListeners();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F172A),
        content: Text(
          '📦 Botiquín actualizado: +$units un. de ${result.detectedDrugName ?? "fármaco"} (Lote: ${result.detectedLotNumber ?? "N/A"}, Vence: ${result.detectedExpirationDate ?? "N/A"})',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void openOcrHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const OcrScanHistoryScreen()),
    );
  }
}

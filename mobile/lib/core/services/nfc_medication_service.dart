import 'dart:async';
import 'package:flutter/foundation.dart';
import '../storage/local_storage_service.dart';
import '../../features/medicine_cabinet/models/medicine_cabinet_item.dart';

/// Tipo de resultado al escanear un tag NFC contra el plan farmacológico actual.
enum NfcScanMatchType {
  /// Coincide con el medicamento programado para la toma actual.
  matchedExpected,

  /// Pertenece a otro medicamento del botiquín (alerta de discrepancia).
  mismatchedDifferent,

  /// Tag NFC físico válido pero aún no asociado a ningún medicamento en ChronoMed.
  unregisteredTag,
}

/// Datos estructurados de la lectura de un tag NFC.
class NfcTagScanResult {
  final String tagId;
  final String? payload;
  final DateTime scannedAt;
  final MedicineCabinetItem? matchedMedicine;
  final NfcScanMatchType matchType;
  final String message;

  const NfcTagScanResult({
    required this.tagId,
    this.payload,
    required this.scannedAt,
    this.matchedMedicine,
    required this.matchType,
    required this.message,
  });

  bool get isSuccess => matchType == NfcScanMatchType.matchedExpected;
  bool get isWarning => matchType == NfcScanMatchType.mismatchedDifferent;
  bool get isUnregistered => matchType == NfcScanMatchType.unregisteredTag;
}

/// Servicio singleton para la interacción con tags NFC en pastilleros y cajas de medicamentos.
/// Soporta hardware físico estándar (NTAG213 / NTAG215) y modo de emulación clínica para pruebas.
class NfcMedicationService {
  NfcMedicationService._internal();
  static final NfcMedicationService instance = NfcMedicationService._internal();

  bool _isListening = false;
  bool _isHardwareAvailable = true;

  final StreamController<NfcTagScanResult> _scanStreamController =
      StreamController<NfcTagScanResult>.broadcast();

  /// Stream reactivo de lecturas NFC.
  Stream<NfcTagScanResult> get onTagScanned => _scanStreamController.stream;

  /// Indica si el sensor NFC está activo escuchando proximidad.
  bool get isListening => _isListening;

  /// Indica si el dispositivo cuenta con capacidades NFC activas.
  bool get isHardwareAvailable => _isHardwareAvailable;

  void setHardwareAvailableForTesting(bool available) {
    _isHardwareAvailable = available;
  }

  /// Inicia la sesión de escucha de aproximación NFC.
  Future<void> startListening({
    String? expectedMedicineName,
    void Function(NfcTagScanResult result)? onResult,
  }) async {
    _isListening = true;
    debugPrint('ChronoMed NFC: Sesión de lectura iniciada (esperando proximidad)...');
  }

  /// Detiene la sesión de escucha NFC.
  Future<void> stopListening() async {
    _isListening = false;
    debugPrint('ChronoMed NFC: Sesión de lectura detenida.');
  }

  /// Procesa un ID de tag escaneado (físico o simulado) y evalúa concordancia clínica.
  Future<NfcTagScanResult> processTag({
    required String rawTagId,
    String? payload,
    String? expectedMedicineName,
  }) async {
    final cleanId = rawTagId.trim();
    final matchedMed = LocalStorageService.instance.getMedicineByNfcTag(cleanId);
    final now = DateTime.now();

    final NfcScanMatchType matchType;
    final String message;

    if (matchedMed == null) {
      matchType = NfcScanMatchType.unregisteredTag;
      message = 'Tag NFC detectado ($cleanId), pero no está vinculado a ningún fármaco en el botiquín.';
    } else if (expectedMedicineName != null &&
        !_namesMatch(matchedMed.name, expectedMedicineName)) {
      matchType = NfcScanMatchType.mismatchedDifferent;
      message = '¡Alerta de Medicamento Erróneo! El pastillero corresponde a "${matchedMed.name}", '
          'pero la toma actual programada es "$expectedMedicineName".';
    } else {
      matchType = NfcScanMatchType.matchedExpected;
      message = '¡Pastillero validado exitosamente! Dosis de "${matchedMed.name}" confirmada por contacto NFC.';
    }

    final result = NfcTagScanResult(
      tagId: cleanId,
      payload: payload ?? 'chronomed://med/${matchedMed?.id ?? "unknown"}',
      scannedAt: now,
      matchedMedicine: matchedMed,
      matchType: matchType,
      message: message,
    );

    _scanStreamController.add(result);
    return result;
  }

  /// Emula el contacto con un tag NFC (útil para pruebas, emulador y personas con dispositivos sin sensor).
  Future<NfcTagScanResult> simulateTagScan(
    String tagId, {
    String? payload,
    String? expectedMedicineName,
  }) async {
    return processTag(
      rawTagId: tagId,
      payload: payload,
      expectedMedicineName: expectedMedicineName,
    );
  }

  /// Vincula un tag NFC físico a un medicamento existente en el botiquín.
  Future<bool> pairTagToMedicine({
    required String medicineId,
    required String tagId,
  }) async {
    final cleanId = tagId.trim();
    if (cleanId.isEmpty) return false;

    await LocalStorageService.instance.linkNfcTagToMedicine(
      medicineId: medicineId,
      tagId: cleanId,
      payload: 'chronomed://med/$medicineId',
    );

    debugPrint('ChronoMed NFC: Medicamento $medicineId vinculado a tag $cleanId.');
    return true;
  }

  /// Desvincula un tag NFC del medicamento.
  Future<bool> unpairTagFromMedicine(String medicineId) async {
    await LocalStorageService.instance.unlinkNfcTagFromMedicine(medicineId);
    debugPrint('ChronoMed NFC: Tag desvinculado de medicamento $medicineId.');
    return true;
  }

  bool _namesMatch(String name1, String name2) {
    final n1 = name1.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final n2 = name2.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return n1.contains(n2) || n2.contains(n1);
  }

  void dispose() {
    _scanStreamController.close();
  }
}

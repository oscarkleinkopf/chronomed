import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/ocr/models/ocr_scan_history_entry.dart';

class OcrHistoryService {
  static final OcrHistoryService instance = OcrHistoryService._internal();

  OcrHistoryService._internal();

  static const String _fileName = 'chronomed_ocr_history.json';
  bool _initialized = false;
  File? _file;
  List<OcrScanHistoryEntry> _entries = [];

  bool get isInitialized => _initialized;
  List<OcrScanHistoryEntry> get allEntries => List.unmodifiable(_entries);

  Future<void> init() async {
    if (_initialized) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      _file = File('${dir.path}/$_fileName');

      if (await _file!.exists()) {
        final content = await _file!.readAsString();
        final List decoded = jsonDecode(content) as List;
        _entries = decoded
            .map((e) => OcrScanHistoryEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } else {
        _loadDemoData();
        await _persistToDisk();
      }
    } catch (e) {
      debugPrint('OcrHistoryService: Error al inicializar: $e');
      if (_entries.isEmpty) {
        _loadDemoData();
      }
    }

    _initialized = true;
  }

  void _loadDemoData() {
    final now = DateTime.now();
    _entries = [
      OcrScanHistoryEntry(
        id: 'scan-001',
        scanType: OcrScanType.medicineBox,
        scannedAt: now.subtract(const Duration(hours: 3)),
        extractedText: 'LOSARTAN POTASICO 50 mg\nLaboratorio Chile\nReg. ISP: F-14920/19\nBioequivalente\nLote: CH-24L09\nVence: 12/2028',
        medicineName: 'Losartán Potásico',
        dosage: '50 mg',
        ispRegister: 'F-14920/19',
        isBioequivalent: true,
        interactionsDetected: const [],
        wasAccepted: true,
      ),
      OcrScanHistoryEntry(
        id: 'scan-002',
        scanType: OcrScanType.prescription,
        scannedAt: now.subtract(const Duration(days: 1)),
        extractedText: 'RP: Claritromicina 500 mg cada 12 hrs por 7 días vía oral tras almuerzo.',
        medicineName: 'Claritromicina',
        dosage: '500 mg',
        interactionsDetected: const [
          'CRÍTICA: Claritromicina + Atorvastatina (Riesgo severo de Rabdomiólisis)',
        ],
        wasAccepted: false,
      ),
      OcrScanHistoryEntry(
        id: 'scan-003',
        scanType: OcrScanType.medicineBox,
        scannedAt: now.subtract(const Duration(days: 3)),
        extractedText: 'EUTIROX 100 mcg\nLevotiroxina sódica\nReg. ISP: F-18451/20\nBioequivalente\nVence: 10/2028',
        medicineName: 'Eutirox (Levotiroxina)',
        dosage: '100 mcg',
        ispRegister: 'F-18451/20',
        isBioequivalent: true,
        interactionsDetected: const [],
        wasAccepted: true,
      ),
    ];
  }

  Future<void> _persistToDisk() async {
    if (_file == null) return;
    try {
      final jsonList = _entries.map((e) => e.toJson()).toList();
      await _file!.writeAsString(jsonEncode(jsonList), flush: true);
    } catch (e) {
      debugPrint('OcrHistoryService: Error al persistir historial: $e');
    }
  }

  List<OcrScanHistoryEntry> getEntries({
    OcrScanType? filterType,
    bool? onlyWithInteractions,
  }) {
    return _entries.where((entry) {
      if (filterType != null && entry.scanType != filterType) return false;
      if (onlyWithInteractions == true && entry.interactionsDetected.isEmpty) return false;
      return true;
    }).toList();
  }

  Future<void> addEntry(OcrScanHistoryEntry entry) async {
    _entries.insert(0, entry);
    await _persistToDisk();
  }

  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    await _persistToDisk();
  }

  Future<void> clearAll() async {
    _entries.clear();
    await _persistToDisk();
  }
}

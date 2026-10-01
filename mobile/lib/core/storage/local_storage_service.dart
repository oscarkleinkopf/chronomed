import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/schedule/models/circadian_routine.dart';
import '../../features/senior_mode/models/senior_intake_item.dart';
import '../../features/medicine_cabinet/models/medicine_cabinet_item.dart';
import '../../features/ocr/models/medicine_box_scan_result.dart';

class LocalStorageService {
  static final LocalStorageService instance = LocalStorageService._internal();

  LocalStorageService._internal();

  static const String _fileName = 'chronomed_state.json';

  bool _initialized = false;
  bool _inMemory = false;
  File? _storageFile;
  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  // Cached in-memory state
  Map<String, int> _stocks = {
    'eutirox': 28,
    'losartan': 14,
    'atorvastatina': 30,
  };

  List<MedicineCabinetItem> _cabinetItems = _defaultCabinetItems();

  static List<MedicineCabinetItem> _defaultCabinetItems() => [
    MedicineCabinetItem(
      id: 'default-eutirox',
      name: 'Eutirox (Levotiroxina)',
      dosage: '100 mcg',
      stockUnits: 28,
      lotNumber: 'CH-24E01',
      expirationDate: '10/2028',
      ispRegister: 'F-18451/20',
      isBioequivalent: true,
      expirationStatus: BoxExpirationStatus.valid,
      shapeType: 'small_round',
      pillColorValue: 0xFFFFFFFF,
      imprint: '100',
      hasScoreLine: true,
      physicalDescription: "Comprimido blanco circular pequeño grabado '100' con ranura de partición",
    ),
    MedicineCabinetItem(
      id: 'default-losartan',
      name: 'Losartán Potásico',
      dosage: '50 mg',
      stockUnits: 14,
      lotNumber: 'CH-24L09',
      expirationDate: '12/2028',
      ispRegister: 'F-14920/19',
      isBioequivalent: true,
      expirationStatus: BoxExpirationStatus.valid,
      shapeType: 'round',
      pillColorValue: 0xFF3B82F6,
      imprint: '50',
      hasScoreLine: true,
      physicalDescription: "Comprimido circular azul grabado '50' con ranura central",
    ),
    MedicineCabinetItem(
      id: 'default-atorvastatina',
      name: 'Atorvastatina',
      dosage: '20 mg',
      stockUnits: 30,
      lotNumber: 'CH-23A11',
      expirationDate: '08/2027',
      ispRegister: 'F-16203/21',
      isBioequivalent: true,
      expirationStatus: BoxExpirationStatus.valid,
      shapeType: 'oblong',
      pillColorValue: 0xFFFACC15,
      imprint: '20',
      hasScoreLine: false,
      physicalDescription: "Comprimido oblongo amarillo grabado '20'",
    ),
  ];

  CircadianRoutine _routine = CircadianRoutine.home;
  List<Map<String, dynamic>> _intakes = [];
  Map<String, Map<String, dynamic>> _voiceNotes = {};
  String _caregiverPin = '1234';
  String _patientName = 'Marcela';
  String _patientRut = '14.567.890-K';
  String? _caregiverHost;
  int _p2pPort = 8844;
  String _p2pSecret = 'chronomed_p2p_local_secret_2026';
  bool _cloudBackupEnabled = false;
  String _cloudServerUrl = 'http://localhost:3000/api/v1';
  String? _cloudApiKey;
  DateTime? _lastCloudSync;

  bool get isInitialized => _initialized;
  String get caregiverPin => _caregiverPin;
  String get patientName => _patientName;
  String get patientRut => _patientRut;
  String? get caregiverHost => _caregiverHost;
  int get p2pPort => _p2pPort;
  String get p2pSecret => _p2pSecret;
  bool get cloudBackupEnabled => _cloudBackupEnabled;
  String get cloudServerUrl => _cloudServerUrl;
  String? get cloudApiKey => _cloudApiKey;
  DateTime? get lastCloudSync => _lastCloudSync;
  List<Map<String, dynamic>> get allIntakes => List.unmodifiable(_intakes);

  /// Inicializa el servicio de almacenamiento local.
  /// Si [inMemory] es true o se proporciona [overrideDir], no se utiliza el canal nativo de path_provider.
  Future<void> init({Directory? overrideDir, bool inMemory = false}) async {
    _inMemory = inMemory;

    if (_inMemory) {
      _storageFile = null;
      _initialized = true;
      return;
    }

    try {
      Directory dir;
      if (overrideDir != null) {
        dir = overrideDir;
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      _storageFile = File('${dir.path}/$_fileName');

      if (await _storageFile!.exists()) {
        final content = await _storageFile!.readAsString();
        _parseAndLoadJson(content);
      } else {
        await _persistToDisk();
      }
    } catch (e) {
      debugPrint('ChronoMed LocalStorage: Advertencia al inicializar archivo local: $e. Usando memoria segura.');
      _inMemory = true;
    }

    _initialized = true;
  }

  void _parseAndLoadJson(String jsonString) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);

      if (data['stocks'] != null && data['stocks'] is Map) {
        _stocks = Map<String, int>.from(
          (data['stocks'] as Map).map(
            (k, v) => MapEntry(k.toString(), int.tryParse(v.toString()) ?? 0),
          ),
        );
      }

      if (data['routine'] != null && data['routine'] is Map) {
        _routine = CircadianRoutine.fromJson(Map<String, dynamic>.from(data['routine']));
      }

      if (data['intakes'] != null && data['intakes'] is List) {
        _intakes = (data['intakes'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      if (data['voiceNotes'] != null && data['voiceNotes'] is Map) {
        _voiceNotes = Map<String, Map<String, dynamic>>.from(
          (data['voiceNotes'] as Map).map(
            (k, v) => MapEntry(k.toString(), Map<String, dynamic>.from(v as Map)),
          ),
        );
      }

      if (data['caregiverPin'] != null) {
        _caregiverPin = data['caregiverPin'].toString();
      }

      if (data['patientName'] != null) {
        _patientName = data['patientName'].toString();
      }

      if (data['patientRut'] != null) {
        _patientRut = data['patientRut'].toString();
      }

      if (data['caregiverHost'] != null) {
        _caregiverHost = data['caregiverHost'].toString();
      }

      if (data['cabinetItems'] != null && data['cabinetItems'] is List) {
        _cabinetItems = (data['cabinetItems'] as List)
            .map((e) => MedicineCabinetItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }

      if (data['p2pPort'] != null) {
        _p2pPort = int.tryParse(data['p2pPort'].toString()) ?? 8844;
      }

      if (data['p2pSecret'] != null) {
        _p2pSecret = data['p2pSecret'].toString();
      }

      if (data['cloudBackupEnabled'] != null) {
        _cloudBackupEnabled = data['cloudBackupEnabled'] == true;
      }

      if (data['cloudServerUrl'] != null) {
        _cloudServerUrl = data['cloudServerUrl'].toString();
      }

      if (data['cloudApiKey'] != null) {
        _cloudApiKey = data['cloudApiKey'].toString();
      }

      if (data['lastCloudSync'] != null) {
        _lastCloudSync = DateTime.tryParse(data['lastCloudSync'].toString());
      }
    } catch (e) {
      debugPrint('ChronoMed LocalStorage: Error al decodificar JSON guardado: $e');
    }
  }

  void _notifyListeners() {
    for (final l in List<VoidCallback>.from(_listeners)) {
      try {
        l();
      } catch (_) {}
    }
  }

  Future<void> _persistToDisk() async {
    _notifyListeners();
    if (_inMemory || _storageFile == null) return;

    try {
      final jsonMap = {
        'version': '1.0.0',
        'updatedAt': DateTime.now().toIso8601String(),
        'patientName': _patientName,
        'patientRut': _patientRut,
        'caregiverPin': _caregiverPin,
        'stocks': _stocks,
        'cabinetItems': _cabinetItems.map((e) => e.toJson()).toList(),
        'routine': _routine.toJson(),
        'intakes': _intakes,
        'voiceNotes': _voiceNotes,
        'caregiverHost': _caregiverHost,
        'p2pPort': _p2pPort,
        'p2pSecret': _p2pSecret,
        'cloudBackupEnabled': _cloudBackupEnabled,
        'cloudServerUrl': _cloudServerUrl,
        'cloudApiKey': _cloudApiKey,
        'lastCloudSync': _lastCloudSync?.toIso8601String(),
      };

      final jsonString = jsonEncode(jsonMap);
      await _storageFile!.writeAsString(jsonString, flush: true);
    } catch (e) {
      debugPrint('ChronoMed LocalStorage: Error al persistir en disco: $e');
    }
  }

  // --- GESTIÓN DE BOTIQUÍN / INVENTARIO ---

  List<MedicineCabinetItem> getCabinetItems() {
    return List.unmodifiable(_cabinetItems);
  }

  MedicineCabinetItem? getCabinetItem(String id) {
    try {
      return _cabinetItems.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCabinetItem(MedicineCabinetItem item) async {
    final index = _cabinetItems.indexWhere((e) => e.id == item.id);
    if (index >= 0) {
      _cabinetItems[index] = item;
    } else {
      _cabinetItems.add(item);
    }

    final key = _normalizeKey(item.name);
    _stocks[key] = item.stockUnits;

    await _persistToDisk();
  }

  Future<void> deleteCabinetItem(String id) async {
    _cabinetItems.removeWhere((e) => e.id == id);
    await _persistToDisk();
  }

  Future<void> updateCabinetStock(String id, int units) async {
    final safeUnits = units < 0 ? 0 : units;
    final index = _cabinetItems.indexWhere((e) => e.id == id);
    if (index >= 0) {
      final current = _cabinetItems[index];
      _cabinetItems[index] = current.copyWith(stockUnits: safeUnits);
      final key = _normalizeKey(current.name);
      _stocks[key] = safeUnits;
    }
    await _persistToDisk();
  }

  // --- GESTIÓN DE STOCK ---

  int getStock(String drugKey, {int fallback = 0}) {
    final key = _normalizeKey(drugKey);
    return _stocks[key] ?? fallback;
  }

  Future<void> setStock(String drugKey, int units) async {
    final key = _normalizeKey(drugKey);
    final safeUnits = units < 0 ? 0 : units;
    _stocks[key] = safeUnits;

    for (int i = 0; i < _cabinetItems.length; i++) {
      if (_normalizeKey(_cabinetItems[i].name) == key) {
        _cabinetItems[i] = _cabinetItems[i].copyWith(stockUnits: safeUnits);
      }
    }

    await _persistToDisk();
  }

  Future<void> incrementStock(String drugKey, int units) async {
    final key = _normalizeKey(drugKey);
    final current = _stocks[key] ?? 0;
    final newUnits = current + units;
    _stocks[key] = newUnits;

    for (int i = 0; i < _cabinetItems.length; i++) {
      if (_normalizeKey(_cabinetItems[i].name) == key) {
        _cabinetItems[i] = _cabinetItems[i].copyWith(stockUnits: newUnits);
      }
    }

    await _persistToDisk();
  }

  Future<void> decrementStock(String drugKey, {int units = 1}) async {
    final key = _normalizeKey(drugKey);
    final current = _stocks[key] ?? 0;
    final newUnits = (current - units) < 0 ? 0 : current - units;
    _stocks[key] = newUnits;

    for (int i = 0; i < _cabinetItems.length; i++) {
      if (_normalizeKey(_cabinetItems[i].name) == key) {
        _cabinetItems[i] = _cabinetItems[i].copyWith(stockUnits: newUnits);
      }
    }

    await _persistToDisk();
  }

  // --- GESTIÓN DE RÉGIMEN CIRCADIANO ---

  CircadianRoutine getCircadianRoutine() {
    return _routine;
  }

  Future<void> saveCircadianRoutine(CircadianRoutine routine) async {
    _routine = routine;
    await _persistToDisk();
  }

  // --- REGISTRO DE TOMAS & BLOQUEO ANTI-SOBREDOSIS ---

  Future<void> recordIntake({
    required String intakeId,
    required String medicationName,
    required SeniorTimeSlot timeSlot,
    required DateTime timestamp,
  }) async {
    _intakes.add({
      'intakeId': intakeId,
      'medicationName': medicationName,
      'timeSlot': timeSlot.name,
      'timestamp': timestamp.toIso8601String(),
    });

    // Auto-descuenta 1 unidad de stock
    final drugKey = _findStockKeyForDrug(medicationName);
    if (drugKey != null) {
      await decrementStock(drugKey, units: 1);
    } else {
      await _persistToDisk();
    }
  }

  bool isSlotTakenToday(SeniorTimeSlot slot, [DateTime? referenceDate]) {
    final target = referenceDate ?? DateTime.now();
    final targetDay = '${target.year}-${target.month.toString().padLeft(2, '0')}-${target.day.toString().padLeft(2, '0')}';

    return _intakes.any((record) {
      final slotStr = record['timeSlot']?.toString();
      final tsStr = record['timestamp']?.toString();
      if (slotStr != slot.name || tsStr == null) return false;

      final parsed = DateTime.tryParse(tsStr);
      if (parsed == null) return false;

      final recordDay = '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
      return recordDay == targetDay;
    });
  }

  bool isIntakeTakenForDate(String intakeId, DateTime referenceDate) {
    final targetDay = '${referenceDate.year}-${referenceDate.month.toString().padLeft(2, '0')}-${referenceDate.day.toString().padLeft(2, '0')}';

    return _intakes.any((record) {
      if (record['intakeId'] != intakeId) return false;
      final tsStr = record['timestamp']?.toString();
      if (tsStr == null) return false;

      final parsed = DateTime.tryParse(tsStr);
      if (parsed == null) return false;

      final recordDay = '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
      return recordDay == targetDay;
    });
  }

  DateTime? getLastIntakeTimestamp(String intakeId) {
    final matching = _intakes.where((r) => r['intakeId'] == intakeId).toList();
    if (matching.isEmpty) return null;

    final latestStr = matching.last['timestamp']?.toString();
    if (latestStr == null) return null;
    return DateTime.tryParse(latestStr);
  }

  // --- GESTIÓN DE NOTAS DE VOZ FAMILIARES ---

  Map<String, dynamic>? getVoiceNote(SeniorTimeSlot slot) {
    return _voiceNotes[slot.name];
  }

  bool hasVoiceNote(SeniorTimeSlot slot) {
    return _voiceNotes.containsKey(slot.name);
  }

  Future<void> saveVoiceNote({
    required SeniorTimeSlot slot,
    required String author,
    required String audioPath,
    String? messageText,
    int? durationSeconds,
  }) async {
    _voiceNotes[slot.name] = {
      'slot': slot.name,
      'author': author,
      'audioPath': audioPath,
      'messageText': messageText ?? '',
      'durationSeconds': durationSeconds ?? 4,
      'recordedAt': DateTime.now().toIso8601String(),
    };
    await _persistToDisk();
  }

  Future<void> deleteVoiceNote(SeniorTimeSlot slot) async {
    _voiceNotes.remove(slot.name);
    await _persistToDisk();
  }

  // --- CONFIGURACIÓN P2P RED LOCAL ---

  Future<void> savePatientData({
    required String name,
    required String rut,
  }) async {
    _patientName = name.trim();
    _patientRut = rut.trim();
    await _persistToDisk();
  }

  Future<void> updateCaregiverPin(String newPin) async {
    _caregiverPin = newPin.trim();
    await _persistToDisk();
  }

  Future<void> setP2pConfig({
    String? caregiverHost,
    int? p2pPort,
    String? p2pSecret,
  }) async {
    if (caregiverHost != null) _caregiverHost = caregiverHost.trim();
    if (p2pPort != null) _p2pPort = p2pPort;
    if (p2pSecret != null) _p2pSecret = p2pSecret.trim();
    await _persistToDisk();
  }

  // --- RESPALDO, EXPORTACIÓN Y MIGRACIÓN (ZERO DATA LOSS) ---

  String exportBackupJson() {
    final backup = {
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'patientName': _patientName,
      'patientRut': _patientRut,
      'caregiverPin': _caregiverPin,
      'stocks': _stocks,
      'cabinetItems': _cabinetItems.map((e) => e.toJson()).toList(),
      'routine': _routine.toJson(),
      'intakes': _intakes,
      'voiceNotes': _voiceNotes,
      'caregiverHost': _caregiverHost,
      'p2pPort': _p2pPort,
      'p2pSecret': _p2pSecret,
      'cloudBackupEnabled': _cloudBackupEnabled,
      'cloudServerUrl': _cloudServerUrl,
      'cloudApiKey': _cloudApiKey,
      'lastCloudSync': _lastCloudSync?.toIso8601String(),
    };
    return jsonEncode(backup);
  }

  Future<void> importBackupJson(String jsonContent) async {
    _parseAndLoadJson(jsonContent);
    await _persistToDisk();
  }

  Future<void> setCloudConfig({
    required bool enabled,
    String? serverUrl,
    String? apiKey,
    DateTime? lastSync,
  }) async {
    _cloudBackupEnabled = enabled;
    if (serverUrl != null && serverUrl.trim().isNotEmpty) {
      _cloudServerUrl = serverUrl.trim();
    }
    if (apiKey != null) {
      _cloudApiKey = apiKey.trim().isEmpty ? null : apiKey.trim();
    }
    if (lastSync != null) {
      _lastCloudSync = lastSync;
    }
    await _persistToDisk();
  }

  Future<void> recordCloudSyncTimestamp(DateTime timestamp) async {
    _lastCloudSync = timestamp;
    await _persistToDisk();
  }

  /// Limpia y restablece a los datos iniciales predeterminados.
  Future<void> resetAllData() async {
    _stocks = {
      'eutirox': 28,
      'losartan': 14,
      'atorvastatina': 30,
    };
    _cabinetItems = _defaultCabinetItems();
    _routine = CircadianRoutine.home;
    _intakes = [];
    _voiceNotes = {};
    _caregiverPin = '1234';
    _patientName = 'Marcela';
    _patientRut = '14.567.890-K';
    _caregiverHost = null;
    _p2pPort = 8844;
    _p2pSecret = 'chronomed_p2p_local_secret_2026';
    _cloudBackupEnabled = false;
    _cloudServerUrl = 'http://localhost:3000/api/v1';
    _cloudApiKey = null;
    _lastCloudSync = null;

    await _persistToDisk();
  }

  String _normalizeKey(String key) {
    final lower = key.toLowerCase();
    if (lower.contains('eutirox') || lower.contains('levotiroxina')) return 'eutirox';
    if (lower.contains('losart')) return 'losartan';
    if (lower.contains('atorvastatina')) return 'atorvastatina';
    return lower.replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  String? _findStockKeyForDrug(String drugName) {
    final lower = drugName.toLowerCase();
    if (lower.contains('eutirox') || lower.contains('levotiroxina')) return 'eutirox';
    if (lower.contains('losart')) return 'losartan';
    if (lower.contains('atorvastatina')) return 'atorvastatina';
    return null;
  }
}

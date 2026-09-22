import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/schedule/models/circadian_routine.dart';
import '../../features/senior_mode/models/senior_intake_item.dart';

class LocalStorageService {
  static final LocalStorageService instance = LocalStorageService._internal();

  LocalStorageService._internal();

  static const String _fileName = 'chronomed_state.json';

  bool _initialized = false;
  bool _inMemory = false;
  File? _storageFile;

  // Cached in-memory state
  Map<String, int> _stocks = {
    'eutirox': 28,
    'losartan': 14,
    'atorvastatina': 30,
  };

  CircadianRoutine _routine = CircadianRoutine.home;
  List<Map<String, dynamic>> _intakes = [];
  String _caregiverPin = '1234';
  String _patientName = 'Marcela';
  String _patientRut = '14.567.890-K';

  bool get isInitialized => _initialized;
  String get caregiverPin => _caregiverPin;
  String get patientName => _patientName;
  String get patientRut => _patientRut;
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

      if (data['caregiverPin'] != null) {
        _caregiverPin = data['caregiverPin'].toString();
      }

      if (data['patientName'] != null) {
        _patientName = data['patientName'].toString();
      }

      if (data['patientRut'] != null) {
        _patientRut = data['patientRut'].toString();
      }
    } catch (e) {
      debugPrint('ChronoMed LocalStorage: Error al decodificar JSON guardado: $e');
    }
  }

  Future<void> _persistToDisk() async {
    if (_inMemory || _storageFile == null) return;

    try {
      final jsonMap = {
        'version': '1.0.0',
        'updatedAt': DateTime.now().toIso8601String(),
        'patientName': _patientName,
        'patientRut': _patientRut,
        'caregiverPin': _caregiverPin,
        'stocks': _stocks,
        'routine': _routine.toJson(),
        'intakes': _intakes,
      };

      final jsonString = jsonEncode(jsonMap);
      await _storageFile!.writeAsString(jsonString, flush: true);
    } catch (e) {
      debugPrint('ChronoMed LocalStorage: Error al persistir en disco: $e');
    }
  }

  // --- GESTIÓN DE STOCK ---

  int getStock(String drugKey, {int fallback = 0}) {
    final key = _normalizeKey(drugKey);
    return _stocks[key] ?? fallback;
  }

  Future<void> setStock(String drugKey, int units) async {
    final key = _normalizeKey(drugKey);
    _stocks[key] = units < 0 ? 0 : units;
    await _persistToDisk();
  }

  Future<void> incrementStock(String drugKey, int units) async {
    final key = _normalizeKey(drugKey);
    final current = _stocks[key] ?? 0;
    _stocks[key] = current + units;
    await _persistToDisk();
  }

  Future<void> decrementStock(String drugKey, {int units = 1}) async {
    final key = _normalizeKey(drugKey);
    final current = _stocks[key] ?? 0;
    _stocks[key] = (current - units) < 0 ? 0 : current - units;
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

  // --- RESPALDO, EXPORTACIÓN Y MIGRACIÓN (ZERO DATA LOSS) ---

  String exportBackupJson() {
    final backup = {
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'patientName': _patientName,
      'patientRut': _patientRut,
      'caregiverPin': _caregiverPin,
      'stocks': _stocks,
      'routine': _routine.toJson(),
      'intakes': _intakes,
    };
    return jsonEncode(backup);
  }

  Future<void> importBackupJson(String jsonContent) async {
    _parseAndLoadJson(jsonContent);
    await _persistToDisk();
  }

  /// Limpia y restablece a los datos iniciales predeterminados.
  Future<void> resetAllData() async {
    _stocks = {
      'eutirox': 28,
      'losartan': 14,
      'atorvastatina': 30,
    };
    _routine = CircadianRoutine.home;
    _intakes = [];
    _caregiverPin = '1234';
    _patientName = 'Marcela';
    _patientRut = '14.567.890-K';

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

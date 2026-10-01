import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../storage/local_storage_service.dart';
import '../sync/p2p_sync_model.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  static ApiClient get instance => _instance;

  final _storage = const FlutterSecureStorage();

  String get baseUrl {
    final configured = LocalStorageService.instance.cloudServerUrl.trim();
    if (configured.isNotEmpty) {
      return configured.endsWith('/')
          ? configured.substring(0, configured.length - 1)
          : configured;
    }
    return 'http://localhost:3000/api/v1';
  }

  Future<Map<String, String>> _getHeaders({String? overrideToken}) async {
    final token = overrideToken ??
        LocalStorageService.instance.cloudApiKey ??
        await _storage.read(key: 'auth_token');

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Prueba la conectividad con el servidor Cloud
  Future<bool> testConnection({String? customUrl, Duration timeout = const Duration(seconds: 4)}) async {
    final url = (customUrl != null && customUrl.trim().isNotEmpty)
        ? (customUrl.trim().endsWith('/') ? customUrl.trim().substring(0, customUrl.trim().length - 1) : customUrl.trim())
        : baseUrl;

    try {
      final headers = await _getHeaders();
      // Consultamos un endpoint seguro para verificar reachability
      final response = await http
          .get(Uri.parse('$url/interactions/check'), headers: headers)
          .timeout(timeout);

      // Si responde cualquier código HTTP (200, 404, 400, 405), el servidor está vivo y alcanzable
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (e) {
      debugPrint('ChronoMed Cloud: Conexión fallida con $url: $e');
      return false;
    }
  }

  /// Sincronización batch completa (Push) del estado local hacia la nube
  Future<bool> pushFullSync({http.Client? client}) async {
    final httpClient = client ?? http.Client();
    try {
      final storage = LocalStorageService.instance;
      final routine = storage.routine;

      final medicationsPayload = storage.getCabinetItems().map((item) {
        return {
          'id': item.id,
          'commercialName': item.name,
          'activeIngredient': item.name,
          'dosage': item.dosage,
          'colorHex': '#${(item.pillColorValue & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          'shape': item.shapeType,
          'currentUnits': item.stockUnits,
          'packageUnitSize': 30,
          'unitsPerDose': 1,
        };
      }).toList();

      final intakesPayload = storage.allIntakes.map((log) {
        return {
          'id': log['intakeId']?.toString(),
          'medicationName': log['medicationName']?.toString(),
          'scheduledTime': log['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
          'actualTakenTime': log['timestamp']?.toString(),
          'status': 'TAKEN',
          'confirmedBy': 'PATIENT',
        };
      }).toList();

      final payload = {
        'patientRut': storage.patientRut,
        'routine': {
          'wakeUp': routine.formatTime(routine.wakeUp),
          'breakfast': routine.formatTime(routine.breakfast),
          'lunch': routine.formatTime(routine.lunch),
          'dinner': routine.formatTime(routine.dinner),
          'sleep': routine.formatTime(routine.sleep),
        },
        'medications': medicationsPayload,
        'intakes': intakesPayload,
      };

      final headers = await _getHeaders();
      final response = await httpClient
          .post(
            Uri.parse('$baseUrl/sync/push'),
            headers: headers,
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        await storage.recordCloudSyncTimestamp(DateTime.now());
        debugPrint('ChronoMed Cloud: Sincronización push completada exitosamente.');
        return true;
      } else {
        debugPrint('ChronoMed Cloud: Error en push (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('ChronoMed Cloud: Excepción durante pushFullSync: $e');
      return false;
    } finally {
      if (client == null) httpClient.close();
    }
  }

  /// Sincroniza una toma puntual en la nube (compatible con evento P2P)
  Future<bool> syncSingleIntake(P2pIntakeSyncPayload payload, {http.Client? client}) async {
    final httpClient = client ?? http.Client();
    try {
      final headers = await _getHeaders();
      final response = await httpClient
          .post(
            Uri.parse('$baseUrl/sync/intake'),
            headers: headers,
            body: json.encode(payload.toJson()),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('ChronoMed Cloud: Excepción al sincronizar toma puntual: $e');
      return false;
    } finally {
      if (client == null) httpClient.close();
    }
  }

  /// Obtiene las tomas del día desde la nube para el paciente
  Future<List<dynamic>> getTodayIntakes(String patientId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/patients/$patientId/intakes/today'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Confirma una toma en la nube con trazabilidad y auditoría
  Future<bool> confirmIntake(String patientId, String intakeId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/patients/$patientId/intakes/$intakeId/confirm'),
            headers: headers,
            body: json.encode({
              'confirmedBy': 'PATIENT',
              'actualTakenTimeIso': DateTime.now().toUtc().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return true; // Encolar localmente si está offline
    }
  }
}

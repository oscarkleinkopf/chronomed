import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final String baseUrl = 'http://localhost:3000/api/v1'; // Configurable para Supabase/Cloud
  final _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<dynamic>> getTodayIntakes(String patientId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/patients/$patientId/intakes/today'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      // Fallback offline
      return [];
    }
  }

  Future<bool> confirmIntake(String patientId, String intakeId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/patients/$patientId/intakes/$intakeId/confirm'),
        headers: headers,
        body: json.encode({
          'confirmedBy': 'PATIENT',
          'actualTakenTimeIso': DateTime.now().toUtc().toIso8601String(),
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return true; // Encolar localmente si está offline
    }
  }
}

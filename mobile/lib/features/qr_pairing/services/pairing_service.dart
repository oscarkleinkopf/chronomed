import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/pairing_payload.dart';

class PairingService {
  static final PairingService _instance = PairingService._internal();
  factory PairingService() => _instance;
  PairingService._internal();

  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> savePatientSession({
    required String patientId,
    required String patientName,
    required String caregiverPin,
    required String authToken,
  }) async {
    await _secureStorage.write(key: 'is_paired', value: 'true');
    await _secureStorage.write(key: 'patient_id', value: patientId);
    await _secureStorage.write(key: 'patient_name', value: patientName);
    await _secureStorage.write(key: 'caregiver_pin', value: caregiverPin);
    await _secureStorage.write(key: 'auth_token', value: authToken);
  }

  Future<bool> isPaired() async {
    final val = await _secureStorage.read(key: 'is_paired');
    return val == 'true';
  }

  Future<PairingPayload> processScannedRawData(String rawData) async {
    String token = rawData;
    if (rawData.startsWith('chronomed://pair?token=')) {
      token = rawData.replaceFirst('chronomed://pair?token=', '');
    }
    final parts = token.split('.');
    if (parts.length != 2) throw Exception('Código QR inválido.');

    final jsonString = utf8.decode(base64Url.decode(base64Url.normalize(parts[0])));
    final Map<String, dynamic> data = json.decode(jsonString);

    final payload = PairingPayload(
      caregiverId: data['caregiverId'] ?? '',
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? 'Familiar',
      seniorPin: data['seniorPin'] ?? '1234',
      expiresAt: data['expiresAt'] ?? 0,
    );

    if (payload.isExpired) throw Exception('Código QR expirado.');
    return payload;
  }
}

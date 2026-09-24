import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../features/senior_mode/models/senior_intake_item.dart';

enum P2pSyncStatus {
  idle,
  listening,
  syncing,
  success,
  error,
}

class P2pIntakeSyncPayload {
  final String intakeId;
  final String patientRut;
  final String medicationName;
  final String dosage;
  final SeniorTimeSlot timeSlot;
  final DateTime timestamp;
  final String hmacSignature;

  const P2pIntakeSyncPayload({
    required this.intakeId,
    required this.patientRut,
    required this.medicationName,
    required this.dosage,
    required this.timeSlot,
    required this.timestamp,
    required this.hmacSignature,
  });

  /// Genera la firma digital HMAC-SHA256 para certificar el origen del mensaje
  static String generateSignature({
    required String intakeId,
    required String patientRut,
    required String medicationName,
    required DateTime timestamp,
    required String sharedSecret,
  }) {
    final rawMessage = '$intakeId|$patientRut|$medicationName|${timestamp.toIso8601String()}';
    final key = utf8.encode(sharedSecret);
    final bytes = utf8.encode(rawMessage);
    final hmac = Hmac(sha256, key);
    return hmac.convert(bytes).toString();
  }

  /// Verifica si la firma HMAC-SHA256 es válida
  bool verifySignature(String sharedSecret) {
    final expectedSignature = generateSignature(
      intakeId: intakeId,
      patientRut: patientRut,
      medicationName: medicationName,
      timestamp: timestamp,
      sharedSecret: sharedSecret,
    );
    return expectedSignature == hmacSignature;
  }

  Map<String, dynamic> toJson() {
    return {
      'intakeId': intakeId,
      'patientRut': patientRut,
      'medicationName': medicationName,
      'dosage': dosage,
      'timeSlot': timeSlot.name,
      'timestamp': timestamp.toIso8601String(),
      'hmacSignature': hmacSignature,
    };
  }

  factory P2pIntakeSyncPayload.fromJson(Map<String, dynamic> json) {
    return P2pIntakeSyncPayload(
      intakeId: json['intakeId'] as String? ?? '',
      patientRut: json['patientRut'] as String? ?? '',
      medicationName: json['medicationName'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      timeSlot: SeniorTimeSlot.values.firstWhere(
        (s) => s.name == json['timeSlot'],
        orElse: () => SeniorTimeSlot.lunch,
      ),
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      hmacSignature: json['hmacSignature'] as String? ?? '',
    );
  }
}

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'p2p_sync_model.dart';
import '../../features/senior_mode/models/senior_intake_item.dart';

class BleBeaconFrame {
  final String rawFrame;
  final String intakeId;
  final String patientRut;
  final String medicationName;
  final String dosage;
  final SeniorTimeSlot timeSlot;
  final DateTime timestamp;
  final String truncatedSignature;
  final bool isValid;

  const BleBeaconFrame({
    required this.rawFrame,
    required this.intakeId,
    required this.patientRut,
    required this.medicationName,
    required this.dosage,
    required this.timeSlot,
    required this.timestamp,
    required this.truncatedSignature,
    required this.isValid,
  });
}

class BleP2pSyncTransport {
  static final BleP2pSyncTransport instance = BleP2pSyncTransport._internal();
  factory BleP2pSyncTransport() => instance;
  BleP2pSyncTransport._internal();

  static const String protocolMagic = 'CMED';
  static const int version = 1;

  final List<P2pIntakeSyncPayload> _bleBroadcastQueue = [];
  final List<BleBeaconFrame> _receivedBeaconHistory = [];

  List<P2pIntakeSyncPayload> get broadcastQueue => List.unmodifiable(_bleBroadcastQueue);
  List<BleBeaconFrame> get receivedHistory => List.unmodifiable(_receivedBeaconHistory);

  /// Encola una toma para difusión continua vía BLE Advertising cuando no hay Wi-Fi
  void queueForBleBroadcast(P2pIntakeSyncPayload payload) {
    if (!_bleBroadcastQueue.any((p) => p.intakeId == payload.intakeId)) {
      _bleBroadcastQueue.add(payload);
    }
  }

  void removeFromBroadcastQueue(String intakeId) {
    _bleBroadcastQueue.removeWhere((p) => p.intakeId == intakeId);
  }

  void clearBroadcastQueue() {
    _bleBroadcastQueue.clear();
  }

  /// Codifica un P2pIntakeSyncPayload en un paquete compacto de datos para BLE Advertising / GATT (< 128 bytes)
  String encodeBleBeaconPayload(P2pIntakeSyncPayload payload, String sharedSecret) {
    final epochSec = payload.timestamp.millisecondsSinceEpoch ~/ 1000;
    final slotCode = payload.timeSlot.name.substring(0, 1).toUpperCase(); // M, L, A, N

    // Truncar firma HMAC para paquete BLE ultra-compacto (primeros 16 caracteres hexadecimales)
    final fullHmac = P2pIntakeSyncPayload.generateSignature(
      intakeId: payload.intakeId,
      patientRut: payload.patientRut,
      medicationName: payload.medicationName,
      timestamp: payload.timestamp,
      sharedSecret: sharedSecret,
    );
    final shortHmac = fullHmac.substring(0, 16);

    // Formato compacto delimitado: CMED:1:ID:RUT:MED:DOSIS:SLOT:EPOCH:HMAC16
    final compactString = '$protocolMagic:$version:${payload.intakeId}:${payload.patientRut}:${payload.medicationName}:${payload.dosage}:$slotCode:$epochSec:$shortHmac';
    return base64Url.encode(utf8.encode(compactString));
  }

  /// Decodifica y verifica la autenticidad criptográfica de un paquete BLE recibido por el teléfono del cuidador
  BleBeaconFrame decodeAndVerifyBlePayload(String encodedBeacon, String sharedSecret) {
    try {
      final decodedString = utf8.decode(base64Url.decode(encodedBeacon));
      final parts = decodedString.split(':');

      if (parts.length < 9 || parts[0] != protocolMagic) {
        return _invalidFrame(decodedString);
      }

      final intakeId = parts[2];
      final patientRut = parts[3];
      final medicationName = parts[4];
      final dosage = parts[5];
      final slotChar = parts[6];
      final epochSec = int.tryParse(parts[7]) ?? 0;
      final receivedHmac = parts[8];

      final timestamp = DateTime.fromMillisecondsSinceEpoch(epochSec * 1000);

      SeniorTimeSlot slot = SeniorTimeSlot.lunch;
      switch (slotChar) {
        case 'M': slot = SeniorTimeSlot.morning; break;
        case 'L': slot = SeniorTimeSlot.lunch; break;
        case 'A': slot = SeniorTimeSlot.afternoon; break;
        case 'N': slot = SeniorTimeSlot.night; break;
      }

      // Validar HMAC
      final expectedHmac = P2pIntakeSyncPayload.generateSignature(
        intakeId: intakeId,
        patientRut: patientRut,
        medicationName: medicationName,
        timestamp: timestamp,
        sharedSecret: sharedSecret,
      ).substring(0, 16);

      final isValid = expectedHmac == receivedHmac;

      final frame = BleBeaconFrame(
        rawFrame: decodedString,
        intakeId: intakeId,
        patientRut: patientRut,
        medicationName: medicationName,
        dosage: dosage,
        timeSlot: slot,
        timestamp: timestamp,
        truncatedSignature: receivedHmac,
        isValid: isValid,
      );

      if (isValid) {
        _receivedBeaconHistory.add(frame);
      }

      return frame;
    } catch (_) {
      return _invalidFrame(encodedBeacon);
    }
  }

  BleBeaconFrame _invalidFrame(String raw) {
    return BleBeaconFrame(
      rawFrame: raw,
      intakeId: '',
      patientRut: '',
      medicationName: '',
      dosage: '',
      timeSlot: SeniorTimeSlot.lunch,
      timestamp: DateTime.now(),
      truncatedSignature: '',
      isValid: false,
    );
  }
}

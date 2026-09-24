import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../storage/local_storage_service.dart';
import '../../features/senior_mode/models/senior_intake_item.dart';
import 'p2p_sync_model.dart';

class LocalP2pSyncService {
  static final LocalP2pSyncService instance = LocalP2pSyncService._internal();

  LocalP2pSyncService._internal();

  static const int defaultPort = 8844;
  static const String defaultSecret = 'chronomed_p2p_local_secret_2026';

  HttpServer? _server;
  int? _activePort;
  String _sharedSecret = defaultSecret;

  // Cola local para retransmisión offline
  final List<P2pIntakeSyncPayload> _offlineSyncQueue = [];

  // Stream controller para notificar a la UI del Cuidador
  final StreamController<P2pIntakeSyncPayload> _intakeStreamController =
      StreamController<P2pIntakeSyncPayload>.broadcast();

  Stream<P2pIntakeSyncPayload> get intakeStream => _intakeStreamController.stream;
  bool get isServerRunning => _server != null;
  int? get activePort => _activePort;
  List<P2pIntakeSyncPayload> get pendingQueue => List.unmodifiable(_offlineSyncQueue);

  void setSharedSecret(String secret) {
    _sharedSecret = secret;
  }

  /// Inicia el servidor HTTP receptor en el teléfono del cuidador
  Future<int> startReceiverServer({
    int port = defaultPort,
    InternetAddress? bindAddress,
  }) async {
    await stopReceiverServer();

    final address = bindAddress ?? InternetAddress.anyIPv4;
    _server = await HttpServer.bind(address, port);
    _activePort = _server!.port;

    debugPrint('ChronoMed P2P Sync: Servidor escuchando en ${_server!.address.address}:$_activePort');

    _server!.listen(_handleIncomingRequest);

    return _activePort!;
  }

  /// Detiene el servidor HTTP
  Future<void> stopReceiverServer() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      _activePort = null;
    }
  }

  /// Manejador de solicitudes entrantes en el servidor del cuidador
  Future<void> _handleIncomingRequest(HttpRequest request) async {
    try {
      if (request.method == 'POST' && request.uri.path == '/api/sync/intake') {
        final bodyStr = await utf8.decoder.bind(request).join();
        final Map<String, dynamic> jsonMap = jsonDecode(bodyStr);

        final payload = P2pIntakeSyncPayload.fromJson(jsonMap);

        // Verificación de firma criptográfica
        if (!payload.verifySignature(_sharedSecret)) {
          request.response
            ..statusCode = HttpStatus.unauthorized
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'error': 'Firma HMAC inválida o no autorizada'}))
            ..close();
          return;
        }

        // Registrar la toma en el almacenamiento local del Cuidador
        await LocalStorageService.instance.recordIntake(
          intakeId: payload.intakeId,
          medicationName: payload.medicationName,
          timeSlot: payload.timeSlot,
          timestamp: payload.timestamp,
        );

        // Notificar a observadores en tiempo real
        _intakeStreamController.add(payload);

        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'status': 'success',
            'message': 'Dosis sincronizada exitosamente en red local',
            'intakeId': payload.intakeId,
          }))
          ..close();
      } else if (request.method == 'GET' && request.uri.path == '/api/status') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'status': 'online',
            'protocol': 'ChronoMed-P2P-v1',
            'timestamp': DateTime.now().toIso8601String(),
          }))
          ..close();
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..close();
      }
    } catch (e) {
      debugPrint('ChronoMed P2P Sync: Error en solicitud entrante: $e');
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write('Internal error: $e')
        ..close();
    }
  }

  /// Crea un payload de toma firmado digitalmente con HMAC-SHA256
  P2pIntakeSyncPayload createSignedPayload({
    required String intakeId,
    required String patientRut,
    required String medicationName,
    required String dosage,
    required SeniorTimeSlot timeSlot,
    DateTime? timestamp,
  }) {
    final effectiveTime = timestamp ?? DateTime.now();
    final signature = P2pIntakeSyncPayload.generateSignature(
      intakeId: intakeId,
      patientRut: patientRut,
      medicationName: medicationName,
      timestamp: effectiveTime,
      sharedSecret: _sharedSecret,
    );

    return P2pIntakeSyncPayload(
      intakeId: intakeId,
      patientRut: patientRut,
      medicationName: medicationName,
      dosage: dosage,
      timeSlot: timeSlot,
      timestamp: effectiveTime,
      hmacSignature: signature,
    );
  }

  /// Envía la confirmación de la toma directamente al dispositivo del cuidador por HTTP local
  Future<bool> sendIntakeToCaregiver({
    required P2pIntakeSyncPayload payload,
    required String caregiverHost,
    int port = defaultPort,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final client = HttpClient();
    client.connectionTimeout = timeout;

    try {
      final uri = Uri.parse('http://$caregiverHost:$port/api/sync/intake');
      final request = await client.postUrl(uri).timeout(timeout);

      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(payload.toJson()));

      final response = await request.close().timeout(timeout);

      if (response.statusCode == HttpStatus.ok) {
        debugPrint('ChronoMed P2P Sync: Toma sincronizada exitosamente con cuidador en $caregiverHost:$port');
        client.close();
        return true;
      } else {
        debugPrint('ChronoMed P2P Sync: El cuidador respondió con error HTTP ${response.statusCode}');
        _enqueueOffline(payload);
        client.close();
        return false;
      }
    } catch (e) {
      debugPrint('ChronoMed P2P Sync: Cuidador no alcanzable en $caregiverHost:$port ($e). Encolando toma offline.');
      _enqueueOffline(payload);
      client.close();
      return false;
    }
  }

  void _enqueueOffline(P2pIntakeSyncPayload payload) {
    if (!_offlineSyncQueue.any((item) => item.intakeId == payload.intakeId)) {
      _offlineSyncQueue.add(payload);
    }
  }

  /// Reintenta vaciar la cola de tomas pendientes cuando el cuidador vuelve a estar en línea
  Future<int> flushPendingQueue({
    required String caregiverHost,
    int port = defaultPort,
  }) async {
    if (_offlineSyncQueue.isEmpty) return 0;

    int syncedCount = 0;
    final pendingItems = List<P2pIntakeSyncPayload>.from(_offlineSyncQueue);

    for (final item in pendingItems) {
      final success = await sendIntakeToCaregiver(
        payload: item,
        caregiverHost: caregiverHost,
        port: port,
      );
      if (success) {
        _offlineSyncQueue.removeWhere((i) => i.intakeId == item.intakeId);
        syncedCount++;
      }
    }

    return syncedCount;
  }

  /// Limpia la cola offline (útil para pruebas y reinicios de sesión)
  void clearOfflineQueue() {
    _offlineSyncQueue.clear();
  }
}

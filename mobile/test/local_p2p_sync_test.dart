import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronomed/core/storage/local_storage_service.dart';
import 'package:chronomed/core/sync/p2p_sync_model.dart';
import 'package:chronomed/core/sync/local_p2p_sync_service.dart';
import 'package:chronomed/core/services/voice_reminder_service.dart';
import 'package:chronomed/features/senior_mode/models/senior_intake_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChronoMed Sovereign P2P Sync & Voice Reminders Test Suite', () {
    late LocalStorageService storage;
    late LocalP2pSyncService p2pService;
    late VoiceReminderService voiceService;
    const testSecret = 'test_secret_hmac_key_2026';

    setUp(() async {
      storage = LocalStorageService.instance;
      await storage.init(inMemory: true);
      await storage.resetAllData();

      p2pService = LocalP2pSyncService.instance;
      p2pService.setSharedSecret(testSecret);
      p2pService.clearOfflineQueue();

      voiceService = VoiceReminderService.instance;
    });

    tearDown(() async {
      await p2pService.stopReceiverServer();
    });

    test('HMAC-SHA256 generates consistent signatures and detects tampering', () {
      final now = DateTime(2026, 9, 24, 13, 0);
      const intakeId = 'intake-123';
      const patientRut = '14.567.890-K';
      const medicationName = 'Losartán Potásico';

      final signature = P2pIntakeSyncPayload.generateSignature(
        intakeId: intakeId,
        patientRut: patientRut,
        medicationName: medicationName,
        timestamp: now,
        sharedSecret: testSecret,
      );

      expect(signature, isNotEmpty);

      final payload = P2pIntakeSyncPayload(
        intakeId: intakeId,
        patientRut: patientRut,
        medicationName: medicationName,
        dosage: '50 mg',
        timeSlot: SeniorTimeSlot.lunch,
        timestamp: now,
        hmacSignature: signature,
      );

      // Firma legítima es válida
      expect(payload.verifySignature(testSecret), isTrue);

      // Clave incorrecta invalida la firma
      expect(payload.verifySignature('wrong_secret'), isFalse);

      // Modificación del payload invalida la firma
      final tamperedMedPayload = P2pIntakeSyncPayload(
        intakeId: intakeId,
        patientRut: patientRut,
        medicationName: 'Morfina 100 mg', // adulterado
        dosage: '50 mg',
        timeSlot: SeniorTimeSlot.lunch,
        timestamp: now,
        hmacSignature: signature,
      );
      expect(tamperedMedPayload.verifySignature(testSecret), isFalse);

      final tamperedTimePayload = P2pIntakeSyncPayload(
        intakeId: intakeId,
        patientRut: patientRut,
        medicationName: medicationName,
        dosage: '50 mg',
        timeSlot: SeniorTimeSlot.lunch,
        timestamp: now.add(const Duration(hours: 2)), // adulterado
        hmacSignature: signature,
      );
      expect(tamperedTimePayload.verifySignature(testSecret), isFalse);
    });

    test('P2pIntakeSyncPayload JSON serialization and deserialization roundtrip', () {
      final now = DateTime(2026, 9, 24, 14, 30);
      final original = p2pService.createSignedPayload(
        intakeId: 'sync-json-001',
        patientRut: '14.567.890-K',
        medicationName: 'Eutirox (Levotiroxina)',
        dosage: '100 mcg',
        timeSlot: SeniorTimeSlot.morning,
        timestamp: now,
      );

      final json = original.toJson();
      final reconstituted = P2pIntakeSyncPayload.fromJson(json);

      expect(reconstituted.intakeId, equals(original.intakeId));
      expect(reconstituted.patientRut, equals(original.patientRut));
      expect(reconstituted.medicationName, equals(original.medicationName));
      expect(reconstituted.dosage, equals(original.dosage));
      expect(reconstituted.timeSlot, equals(original.timeSlot));
      expect(reconstituted.timestamp, equals(original.timestamp));
      expect(reconstituted.hmacSignature, equals(original.hmacSignature));
      expect(reconstituted.verifySignature(testSecret), isTrue);
    });

    test('Starts loopback receiver server and processes valid intake transmission', () async {
      // Iniciar servidor receptor en loopback con puerto efímero (0)
      final port = await p2pService.startReceiverServer(
        port: 0,
        bindAddress: InternetAddress.loopbackIPv4,
      );
      expect(p2pService.isServerRunning, isTrue);
      expect(port, greaterThan(0));

      final today = DateTime(2026, 9, 24, 13, 15);
      final initialStock = storage.getStock('losartan');

      // Crear payload firmado
      final payload = p2pService.createSignedPayload(
        intakeId: 'test-p2p-live-001',
        patientRut: '14.567.890-K',
        medicationName: 'Losartán Potásico',
        dosage: '50 mg',
        timeSlot: SeniorTimeSlot.lunch,
        timestamp: today,
      );

      // Configurar escucha del stream
      P2pIntakeSyncPayload? receivedPayload;
      final sub = p2pService.intakeStream.listen((item) {
        receivedPayload = item;
      });

      // Transmisión HTTP local
      final success = await p2pService.sendIntakeToCaregiver(
        payload: payload,
        caregiverHost: '127.0.0.1',
        port: port,
      );

      expect(success, isTrue);
      await Future.delayed(const Duration(milliseconds: 100));

      // Verificación de recepción en stream
      expect(receivedPayload, isNotNull);
      expect(receivedPayload!.intakeId, equals('test-p2p-live-001'));
      expect(receivedPayload!.medicationName, equals('Losartán Potásico'));

      // Verificación de persistencia automática en LocalStorageService
      expect(storage.isSlotTakenToday(SeniorTimeSlot.lunch, today), isTrue);
      expect(storage.getStock('losartan'), equals(initialStock - 1));
      expect(p2pService.pendingQueue, isEmpty);

      await sub.cancel();
    });

    test('Rejects transmission with invalid HMAC signature with 401 Unauthorized', () async {
      final port = await p2pService.startReceiverServer(
        port: 0,
        bindAddress: InternetAddress.loopbackIPv4,
      );

      final today = DateTime(2026, 9, 24, 8, 30);
      final initialEutiroxStock = storage.getStock('eutirox');

      // Payload con firma adulterada
      final tamperedPayload = P2pIntakeSyncPayload(
        intakeId: 'forged-001',
        patientRut: '14.567.890-K',
        medicationName: 'Eutirox (Levotiroxina)',
        dosage: '100 mcg',
        timeSlot: SeniorTimeSlot.morning,
        timestamp: today,
        hmacSignature: 'forged_fake_signature_abc_123',
      );

      final success = await p2pService.sendIntakeToCaregiver(
        payload: tamperedPayload,
        caregiverHost: '127.0.0.1',
        port: port,
      );

      expect(success, isFalse);

      // Verificación de que NO se registró en LocalStorage
      expect(storage.isSlotTakenToday(SeniorTimeSlot.morning, today), isFalse);
      expect(storage.getStock('eutirox'), equals(initialEutiroxStock));
    });

    test('Enqueues offline intakes and flushes them when caregiver reconnects', () async {
      final today = DateTime(2026, 9, 24, 21, 0);

      final payload = p2pService.createSignedPayload(
        intakeId: 'offline-001',
        patientRut: '14.567.890-K',
        medicationName: 'Atorvastatina',
        dosage: '20 mg',
        timeSlot: SeniorTimeSlot.night,
        timestamp: today,
      );

      // Intentar enviar a un puerto donde no hay servidor escuchando
      const unreachablePort = 59123;
      final success = await p2pService.sendIntakeToCaregiver(
        payload: payload,
        caregiverHost: '127.0.0.1',
        port: unreachablePort,
        timeout: const Duration(milliseconds: 500),
      );

      expect(success, isFalse);
      expect(p2pService.pendingQueue.length, equals(1));
      expect(p2pService.pendingQueue.first.intakeId, equals('offline-001'));

      // Ahora el servidor del cuidador vuelve a estar en línea
      final livePort = await p2pService.startReceiverServer(
        port: 0,
        bindAddress: InternetAddress.loopbackIPv4,
      );

      // Reintentar vaciar la cola offline
      final flushedCount = await p2pService.flushPendingQueue(
        caregiverHost: '127.0.0.1',
        port: livePort,
      );

      expect(flushedCount, equals(1));
      expect(p2pService.pendingQueue, isEmpty);
      expect(storage.isSlotTakenToday(SeniorTimeSlot.night, today), isTrue);
    });

    test('VoiceReminderService saves, retrieves and deletes familiar voice notes', () async {
      // Estado inicial
      expect(voiceService.hasVoiceNote(SeniorTimeSlot.morning), isFalse);
      expect(voiceService.getVoiceNote(SeniorTimeSlot.morning), isNull);

      // Guardar nota de voz familiar
      await voiceService.saveVoiceNote(
        slot: SeniorTimeSlot.morning,
        author: 'Hija Andrea',
        audioPath: 'voice_note_morning.m4a',
        messageText: 'Mamá, tómate tu Eutirox con medio vaso de agua.',
        durationSeconds: 4,
      );

      expect(voiceService.hasVoiceNote(SeniorTimeSlot.morning), isTrue);
      final note = voiceService.getVoiceNote(SeniorTimeSlot.morning);
      expect(note, isNotNull);
      expect(note!.author, equals('Hija Andrea'));
      expect(note.messageText, contains('Eutirox'));
      expect(note.slot, equals(SeniorTimeSlot.morning));

      // Eliminar nota de voz
      await voiceService.deleteVoiceNote(SeniorTimeSlot.morning);
      expect(voiceService.hasVoiceNote(SeniorTimeSlot.morning), isFalse);
      expect(voiceService.getVoiceNote(SeniorTimeSlot.morning), isNull);
    });

    test('P2P Configuration persists in LocalStorageService', () async {
      expect(storage.caregiverHost, isNull);
      expect(storage.p2pPort, equals(8844));
      expect(storage.p2pSecret, equals('chronomed_p2p_local_secret_2026'));

      await storage.setP2pConfig(
        caregiverHost: '192.168.1.100',
        p2pPort: 9000,
        p2pSecret: 'my_custom_secret_key',
      );

      expect(storage.caregiverHost, equals('192.168.1.100'));
      expect(storage.p2pPort, equals(9000));
      expect(storage.p2pSecret, equals('my_custom_secret_key'));

      final backup = storage.exportBackupJson();
      expect(backup, contains('192.168.1.100'));
      expect(backup, contains('9000'));
      expect(backup, contains('my_custom_secret_key'));

      await storage.resetAllData();
      expect(storage.caregiverHost, isNull);
      expect(storage.p2pPort, equals(8844));
    });
  });
}

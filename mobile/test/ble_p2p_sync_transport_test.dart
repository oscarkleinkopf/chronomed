import 'package:flutter_test/flutter_test.dart';
import 'package:chronomed/core/sync/ble_p2p_sync_transport.dart';
import 'package:chronomed/core/sync/p2p_sync_model.dart';
import 'package:chronomed/features/senior_mode/models/senior_intake_item.dart';

void main() {
  group('ChronoMed Sovereign BLE P2P Fallback Transport Test Suite', () {
    late BleP2pSyncTransport transport;
    const testSecret = 'secret_ble_test_chile_2026';

    setUp(() {
      transport = BleP2pSyncTransport.instance;
      transport.clearBroadcastQueue();
    });

    test('Encodes and decodes BLE beacon payload with valid HMAC verification', () {
      final now = DateTime(2026, 9, 29, 13, 30);
      final payload = P2pIntakeSyncPayload(
        intakeId: 'intake-ble-1',
        patientRut: '14.567.890-K',
        medicationName: 'Losartán Potásico',
        dosage: '50 mg',
        timeSlot: SeniorTimeSlot.lunch,
        timestamp: now,
        hmacSignature: '', // generateSignature is called during encoding
      );

      final encoded = transport.encodeBleBeaconPayload(payload, testSecret);
      expect(encoded.isNotEmpty, isTrue);

      final frame = transport.decodeAndVerifyBlePayload(encoded, testSecret);
      expect(frame.isValid, isTrue);
      expect(frame.intakeId, equals('intake-ble-1'));
      expect(frame.patientRut, equals('14.567.890-K'));
      expect(frame.medicationName, equals('Losartán Potásico'));
      expect(frame.dosage, equals('50 mg'));
      expect(frame.timeSlot, equals(SeniorTimeSlot.lunch));
      expect(frame.timestamp.year, equals(2026));
      expect(frame.timestamp.month, equals(9));
      expect(frame.timestamp.day, equals(29));
      expect(frame.truncatedSignature.length, equals(16));
    });

    test('Rejects tampered payload or incorrect shared secret', () {
      final now = DateTime(2026, 9, 29, 13, 30);
      final payload = P2pIntakeSyncPayload(
        intakeId: 'intake-ble-2',
        patientRut: '14.567.890-K',
        medicationName: 'Eutirox',
        dosage: '100 mcg',
        timeSlot: SeniorTimeSlot.morning,
        timestamp: now,
        hmacSignature: '',
      );

      final encoded = transport.encodeBleBeaconPayload(payload, testSecret);

      // Decoding with wrong secret must fail verification
      final frameWrongSecret = transport.decodeAndVerifyBlePayload(encoded, 'wrong_secret_key');
      expect(frameWrongSecret.isValid, isFalse);

      // Decoding corrupted string must fail
      final corruptedFrame = transport.decodeAndVerifyBlePayload('CorruptedPayloadData', testSecret);
      expect(corruptedFrame.isValid, isFalse);
    });

    test('Manages offline broadcast queue correctly', () {
      final payload = P2pIntakeSyncPayload(
        intakeId: 'intake-ble-queue-1',
        patientRut: '14.567.890-K',
        medicationName: 'Atorvastatina',
        dosage: '20 mg',
        timeSlot: SeniorTimeSlot.night,
        timestamp: DateTime.now(),
        hmacSignature: 'sig',
      );

      transport.queueForBleBroadcast(payload);
      expect(transport.broadcastQueue.length, equals(1));
      expect(transport.broadcastQueue.first.intakeId, equals('intake-ble-queue-1'));

      // Duplicate prevention
      transport.queueForBleBroadcast(payload);
      expect(transport.broadcastQueue.length, equals(1));

      // Removal
      transport.removeFromBroadcastQueue('intake-ble-queue-1');
      expect(transport.broadcastQueue.isEmpty, isTrue);
    });
  });
}

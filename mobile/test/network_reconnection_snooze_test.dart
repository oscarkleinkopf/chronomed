import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronomed/core/notifications/network_reconnection_snooze_service.dart';
import 'package:chronomed/core/storage/local_storage_service.dart';
import 'package:chronomed/features/senior_mode/models/senior_intake_item.dart';
import 'package:chronomed/core/notifications/local_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChronoMed Network Reconnection Smart Snooze Test Suite', () {
    late LocalStorageService storage;
    late NetworkReconnectionSnoozeService snoozeService;

    setUp(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        (MethodCall methodCall) async => true,
      );
      storage = LocalStorageService.instance;
      await storage.init(inMemory: true);
      await storage.resetAllData();
      await LocalNotificationService().initialize();
      snoozeService = NetworkReconnectionSnoozeService.instance;
    });

    test('Identifies past due unconfirmed doses when device returns home', () {
      // 15:30 PM: Morning (07:30) and Lunch (13:30) are past due
      final afternoonTime = DateTime(2026, 9, 29, 15, 30);

      final pending = snoozeService.getPendingDosesForToday(referenceDate: afternoonTime);
      expect(pending.length, equals(2));
      expect(pending.any((d) => d.timeSlot == SeniorTimeSlot.morning), isTrue);
      expect(pending.any((d) => d.timeSlot == SeniorTimeSlot.lunch), isTrue);
    });

    test('Excludes doses already taken earlier in the day', () async {
      final afternoonTime = DateTime(2026, 9, 29, 15, 30);

      // Morning was taken, lunch was missed
      await storage.recordIntake(
        intakeId: 'morning-1',
        medicationName: 'Eutirox (Levotiroxina)',
        timeSlot: SeniorTimeSlot.morning,
        timestamp: DateTime(2026, 9, 29, 7, 30),
      );

      final pending = snoozeService.getPendingDosesForToday(referenceDate: afternoonTime);
      expect(pending.length, equals(1));
      expect(pending.first.timeSlot, equals(SeniorTimeSlot.lunch));
      expect(pending.first.medicationName, contains('Losartán'));
    });

    test('Triggers gentle snooze when reconnecting to home Wi-Fi network', () async {
      final returnHomeTime = DateTime(2026, 9, 29, 16, 0);

      // Start disconnected
      await snoozeService.onNetworkStateChanged(
        isConnectedToHomeNetwork: false,
        announceWithVoice: false,
      );
      expect(snoozeService.isHomeConnected, isFalse);

      // Reconnected to home Wi-Fi
      final triggered = await snoozeService.onNetworkStateChanged(
        isConnectedToHomeNetwork: true,
        referenceDate: returnHomeTime,
        announceWithVoice: false,
      );

      expect(snoozeService.isHomeConnected, isTrue);
      expect(triggered.isNotEmpty, isTrue);
      expect(snoozeService.lastReconnectionTimestamp, equals(returnHomeTime));
    });
  });
}

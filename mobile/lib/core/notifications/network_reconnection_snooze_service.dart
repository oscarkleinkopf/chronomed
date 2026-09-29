import 'dart:async';
import 'package:flutter/foundation.dart';
import '../storage/local_storage_service.dart';
import '../services/tts_service.dart';
import '../services/voice_reminder_service.dart';
import '../../features/senior_mode/models/senior_intake_item.dart';
import '../../features/schedule/models/circadian_routine.dart';
import 'local_notification_service.dart';
import 'alarm_scheduler.dart';

class PendingDoseReminder {
  final SeniorTimeSlot timeSlot;
  final String medicationName;
  final String scheduledTime;
  final String dosage;

  const PendingDoseReminder({
    required this.timeSlot,
    required this.medicationName,
    required this.scheduledTime,
    required this.dosage,
  });
}

class NetworkReconnectionSnoozeService {
  static final NetworkReconnectionSnoozeService instance =
      NetworkReconnectionSnoozeService._internal();

  factory NetworkReconnectionSnoozeService() => instance;

  NetworkReconnectionSnoozeService._internal();

  final LocalStorageService _storage = LocalStorageService.instance;
  final LocalNotificationService _notificationService = LocalNotificationService();
  final TtsService _tts = TtsService();
  final VoiceReminderService _voiceReminder = VoiceReminderService.instance;

  bool _isHomeConnected = false;
  DateTime? _lastReconnectionTimestamp;

  final StreamController<List<PendingDoseReminder>> _snoozeEventController =
      StreamController<List<PendingDoseReminder>>.broadcast();

  Stream<List<PendingDoseReminder>> get snoozeEvents => _snoozeEventController.stream;
  bool get isHomeConnected => _isHomeConnected;
  DateTime? get lastReconnectionTimestamp => _lastReconnectionTimestamp;

  /// Notifica un cambio en el estado de conexión de red residencial (Wi-Fi de casa)
  Future<List<PendingDoseReminder>> onNetworkStateChanged({
    required bool isConnectedToHomeNetwork,
    DateTime? referenceDate,
    bool announceWithVoice = true,
  }) async {
    final wasDisconnected = !_isHomeConnected;
    _isHomeConnected = isConnectedToHomeNetwork;

    if (isConnectedToHomeNetwork && wasDisconnected) {
      _lastReconnectionTimestamp = referenceDate ?? DateTime.now();
      debugPrint('ChronoMed Snooze: Dispositivo reconectado a la red residencial.');
      return await triggerGentleReconnectionSnooze(
        referenceDate: _lastReconnectionTimestamp,
        announceWithVoice: announceWithVoice,
      );
    }

    return [];
  }

  /// Identifica tomas programadas para hoy cuyo horario ya transcurrió pero no han sido registradas
  List<PendingDoseReminder> getPendingDosesForToday({DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();
    final routine = _storage.getCircadianRoutine();
    final pending = <PendingDoseReminder>[];

    // 1. Ayunas / Mañana (Eutirox)
    final fastingTime = routine.fastingTime;
    final fastingDt = DateTime(now.year, now.month, now.day, fastingTime.hour, fastingTime.minute);
    if (now.isAfter(fastingDt) && !_storage.isSlotTakenToday(SeniorTimeSlot.morning, now)) {
      pending.add(PendingDoseReminder(
        timeSlot: SeniorTimeSlot.morning,
        medicationName: 'Eutirox (Levotiroxina)',
        scheduledTime: routine.formatTime(fastingTime),
        dosage: '100 mcg',
      ));
    }

    // 2. Almuerzo (Losartán)
    final lunchTime = routine.lunch;
    final lunchDt = DateTime(now.year, now.month, now.day, lunchTime.hour, lunchTime.minute);
    if (now.isAfter(lunchDt) && !_storage.isSlotTakenToday(SeniorTimeSlot.lunch, now)) {
      pending.add(PendingDoseReminder(
        timeSlot: SeniorTimeSlot.lunch,
        medicationName: 'Losartán Potásico',
        scheduledTime: routine.formatTime(lunchTime),
        dosage: '50 mg',
      ));
    }

    // 3. Noche (Atorvastatina)
    final nightTime = routine.night;
    final nightDt = DateTime(now.year, now.month, now.day, nightTime.hour, nightTime.minute);
    if (now.isAfter(nightDt) && !_storage.isSlotTakenToday(SeniorTimeSlot.night, now)) {
      pending.add(PendingDoseReminder(
        timeSlot: SeniorTimeSlot.night,
        medicationName: 'Atorvastatina',
        scheduledTime: routine.formatTime(nightTime),
        dosage: '20 mg',
      ));
    }

    return pending;
  }

  /// Reactiva suavemente el recordatorio para el paciente al volver a casa
  Future<List<PendingDoseReminder>> triggerGentleReconnectionSnooze({
    DateTime? referenceDate,
    bool announceWithVoice = true,
  }) async {
    final pending = getPendingDosesForToday(referenceDate: referenceDate);
    if (pending.isEmpty) return [];

    _snoozeEventController.add(pending);

    for (final dose in pending) {
      // 1. Notificación local suave
      await AlarmScheduler().scheduleMedicationAlarm(
        alarmId: 900 + dose.timeSlot.index,
        medicationName: dose.medicationName,
        dosage: dose.dosage,
        timeSlotName: '${dose.timeSlot.label} (Al volver a casa)',
        customTitle: '🏡 ¡Bienvenida a casa! Toma pendiente: ${dose.medicationName}',
        customBody: 'Estaba programada a las ${dose.scheduledTime}. Toca aquí para confirmarla.',
        scheduledDateTimeUtc: DateTime.now().add(const Duration(seconds: 2)).toUtc(),
        intakeLogId: 'snooze-${dose.timeSlot.name}-${DateTime.now().millisecondsSinceEpoch}',
      );

      // 2. Reproducción por voz familiar si existe o TTS cariñoso
      if (announceWithVoice) {
        if (_storage.hasVoiceNote(dose.timeSlot)) {
          await _voiceReminder.playReminder(dose.timeSlot);
        } else {
          await _tts.speak(
            'Hola Marcela, bienvenida a casa. Recuerda tomar tu ${dose.medicationName} pendiente de las ${dose.scheduledTime}.',
          );
        }
      }
    }

    return pending;
  }
}

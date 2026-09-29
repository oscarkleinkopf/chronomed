import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'local_notification_service.dart';
import '../../features/schedule/models/circadian_routine.dart';
import '../../features/senior_mode/models/senior_intake_item.dart';
import '../storage/local_storage_service.dart';

class AlarmScheduler {
  final LocalNotificationService _service = LocalNotificationService();

  static const int alarmIdMorningFasting = 101;
  static const int alarmIdBreakfast = 102;
  static const int alarmIdLunch = 103;
  static const int alarmIdAfternoon = 104;
  static const int alarmIdNight = 105;

  Future<void> scheduleMedicationAlarm({
    required int alarmId,
    required String medicationName,
    required String dosage,
    required String timeSlotName,
    required DateTime scheduledDateTimeUtc,
    required String intakeLogId,
    String? customTitle,
    String? customBody,
  }) async {
    final tz.TZDateTime scheduledTz = tz.TZDateTime.from(scheduledDateTimeUtc, tz.local);
    if (scheduledTz.isBefore(tz.TZDateTime.now(tz.local))) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'chronomed_critical_alarms',
      'Alarmas Críticas de Medicación',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      color: Color(0xFF2563EB),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final title = customTitle ?? '⏰ Hora de tu medicina: $timeSlotName';
    final body = customBody ?? '$medicationName ($dosage)';

    await _service.plugin.zonedSchedule(
      alarmId,
      title,
      body,
      scheduledTz,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: intakeLogId,
    );
  }

  /// Orquesta y programa automáticamente las alarmas circadianas según la rutina activa,
  /// respetando el bloqueo anti-sobredosis e incorporando notas de voz familiares si existen.
  Future<int> scheduleAllCircadianAlarms({
    required CircadianRoutine routine,
    required LocalStorageService storage,
    DateTime? referenceDate,
  }) async {
    final now = referenceDate ?? DateTime.now();
    int scheduledCount = 0;

    // 1. Mañana / Ayunas: Eutirox (Levotiroxina) 30 min antes del desayuno
    if (!storage.isSlotTakenToday(SeniorTimeSlot.morning, now)) {
      final fasting = routine.fastingTime;
      final fastingDt = DateTime(now.year, now.month, now.day, fasting.hour, fasting.minute);
      if (fastingDt.isAfter(now)) {
        final voiceNote = storage.getVoiceNote(SeniorTimeSlot.morning);
        final title = voiceNote != null
            ? '🎙️ Mensaje de ${voiceNote['author']}: Eutirox'
            : '⏰ Hora de tu medicina: Ayunas';
        final body = (voiceNote != null && (voiceNote['messageText'] ?? '').toString().isNotEmpty)
            ? voiceNote['messageText'].toString()
            : 'Eutirox 100 mcg (30 min antes de desayunar)';

        await scheduleMedicationAlarm(
          alarmId: alarmIdMorningFasting,
          medicationName: 'Eutirox (Levotiroxina)',
          dosage: '100 mcg',
          timeSlotName: 'Ayunas',
          customTitle: title,
          customBody: body,
          scheduledDateTimeUtc: fastingDt.toUtc(),
          intakeLogId: 'intake-morning-${fastingDt.toIso8601String()}',
        );
        scheduledCount++;
      }
    } else {
      await cancelAlarm(alarmIdMorningFasting);
    }

    // 2. Almuerzo: Losartán Potásico
    if (!storage.isSlotTakenToday(SeniorTimeSlot.lunch, now)) {
      final lunch = routine.lunch;
      final lunchDt = DateTime(now.year, now.month, now.day, lunch.hour, lunch.minute);
      if (lunchDt.isAfter(now)) {
        final voiceNote = storage.getVoiceNote(SeniorTimeSlot.lunch);
        final title = voiceNote != null
            ? '🎙️ Mensaje de ${voiceNote['author']}: Losartán'
            : '⏰ Hora de tu medicina: Almuerzo';
        final body = (voiceNote != null && (voiceNote['messageText'] ?? '').toString().isNotEmpty)
            ? voiceNote['messageText'].toString()
            : 'Losartán Potásico 50 mg (Con el almuerzo)';

        await scheduleMedicationAlarm(
          alarmId: alarmIdLunch,
          medicationName: 'Losartán Potásico',
          dosage: '50 mg',
          timeSlotName: 'Almuerzo',
          customTitle: title,
          customBody: body,
          scheduledDateTimeUtc: lunchDt.toUtc(),
          intakeLogId: 'intake-lunch-${lunchDt.toIso8601String()}',
        );
        scheduledCount++;
      }
    } else {
      await cancelAlarm(alarmIdLunch);
    }

    // 3. Noche: Atorvastatina
    if (!storage.isSlotTakenToday(SeniorTimeSlot.night, now)) {
      final night = routine.night;
      final nightDt = DateTime(now.year, now.month, now.day, night.hour, night.minute);
      if (nightDt.isAfter(now)) {
        final voiceNote = storage.getVoiceNote(SeniorTimeSlot.night);
        final title = voiceNote != null
            ? '🎙️ Mensaje de ${voiceNote['author']}: Atorvastatina'
            : '⏰ Hora de tu medicina: Noche';
        final body = (voiceNote != null && (voiceNote['messageText'] ?? '').toString().isNotEmpty)
            ? voiceNote['messageText'].toString()
            : 'Atorvastatina 20 mg (Al acostarse)';

        await scheduleMedicationAlarm(
          alarmId: alarmIdNight,
          medicationName: 'Atorvastatina',
          dosage: '20 mg',
          timeSlotName: 'Noche',
          customTitle: title,
          customBody: body,
          scheduledDateTimeUtc: nightDt.toUtc(),
          intakeLogId: 'intake-night-${nightDt.toIso8601String()}',
        );
        scheduledCount++;
      }
    } else {
      await cancelAlarm(alarmIdNight);
    }

    return scheduledCount;
  }

  Future<void> cancelSlotAlarm(SeniorTimeSlot slot) async {
    switch (slot) {
      case SeniorTimeSlot.morning:
        await cancelAlarm(alarmIdMorningFasting);
        await cancelAlarm(alarmIdBreakfast);
        break;
      case SeniorTimeSlot.lunch:
        await cancelAlarm(alarmIdLunch);
        break;
      case SeniorTimeSlot.afternoon:
        await cancelAlarm(alarmIdAfternoon);
        break;
      case SeniorTimeSlot.night:
        await cancelAlarm(alarmIdNight);
        break;
    }
  }

  Future<void> cancelAllCircadianAlarms() async {
    await cancelAlarm(alarmIdMorningFasting);
    await cancelAlarm(alarmIdBreakfast);
    await cancelAlarm(alarmIdLunch);
    await cancelAlarm(alarmIdAfternoon);
    await cancelAlarm(alarmIdNight);
  }

  Future<void> cancelAlarm(int alarmId) async {
    await _service.plugin.cancel(alarmId);
  }
}

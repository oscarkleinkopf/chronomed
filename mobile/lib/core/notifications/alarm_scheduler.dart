import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'local_notification_service.dart';

class AlarmScheduler {
  final LocalNotificationService _service = LocalNotificationService();

  Future<void> scheduleMedicationAlarm({
    required int alarmId,
    required String medicationName,
    required String dosage,
    required String timeSlotName,
    required DateTime scheduledDateTimeUtc,
    required String intakeLogId,
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
      presentAlert: true, presentBadge: true, presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    await _service.plugin.zonedSchedule(
      alarmId,
      '⏰ Hora de tu medicina: $timeSlotName',
      '$medicationName ($dosage)',
      scheduledTz,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: intakeLogId,
    );
  }

  Future<void> cancelAlarm(int alarmId) async {
    await _service.plugin.cancel(alarmId);
  }
}

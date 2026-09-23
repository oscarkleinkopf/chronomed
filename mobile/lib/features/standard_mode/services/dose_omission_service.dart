import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/notifications/local_notification_service.dart';
import '../../../core/notifications/notification_channels.dart';
import '../../schedule/models/circadian_routine.dart';
import '../../senior_mode/models/senior_intake_item.dart';
import '../models/dose_omission_model.dart';

class DoseOmissionService {
  static final DoseOmissionService instance = DoseOmissionService._internal();
  DoseOmissionService._internal();

  /// Ventana de gracia clínica (en minutos) antes de escalar al cuidador
  static const int defaultGracePeriodMinutes = 45;

  /// Evalúa el estado de cumplimiento de todas las dosis activas del régimen
  List<DoseOmissionAlert> evaluateAdherence({
    DateTime? now,
    CircadianRoutine? routine,
    int gracePeriodMinutes = defaultGracePeriodMinutes,
  }) {
    final storage = LocalStorageService.instance;
    final currentNow = now ?? DateTime.now();
    final activeRoutine = routine ?? storage.getCircadianRoutine();
    final patientName = storage.patientName;
    final patientRut = storage.patientRut;

    final List<DoseOmissionAlert> alerts = [];

    // Fármaco 1: Eutirox (Ayunas / Desayuno)
    final fastingTime = activeRoutine.fastingTime;
    alerts.add(_evaluateSingleDose(
      patientName: patientName,
      patientRut: patientRut,
      drugName: 'Eutirox (Levotiroxina)',
      dosage: '100 mcg',
      timeSlot: SeniorTimeSlot.morning,
      timeOfDay: fastingTime,
      intakeId: 'intake-morning-fasting',
      now: currentNow,
      routine: activeRoutine,
      gracePeriodMinutes: gracePeriodMinutes,
    ));

    // Fármaco 2: Losartán Potásico (Almuerzo)
    final lunchTime = activeRoutine.lunch;
    alerts.add(_evaluateSingleDose(
      patientName: patientName,
      patientRut: patientRut,
      drugName: 'Losartán Potásico',
      dosage: '50 mg',
      timeSlot: SeniorTimeSlot.lunch,
      timeOfDay: lunchTime,
      intakeId: 'intake-123',
      now: currentNow,
      routine: activeRoutine,
      gracePeriodMinutes: gracePeriodMinutes,
    ));

    // Fármaco 3: Atorvastatina (Noche)
    final nightTime = activeRoutine.night;
    alerts.add(_evaluateSingleDose(
      patientName: patientName,
      patientRut: patientRut,
      drugName: 'Atorvastatina',
      dosage: '20 mg',
      timeSlot: SeniorTimeSlot.night,
      timeOfDay: nightTime,
      intakeId: 'intake-night',
      now: currentNow,
      routine: activeRoutine,
      gracePeriodMinutes: gracePeriodMinutes,
    ));

    return alerts;
  }

  DoseOmissionAlert _evaluateSingleDose({
    required String patientName,
    required String patientRut,
    required String drugName,
    required String dosage,
    required SeniorTimeSlot timeSlot,
    required TimeOfDay timeOfDay,
    required String intakeId,
    required DateTime now,
    required CircadianRoutine routine,
    required int gracePeriodMinutes,
  }) {
    final storage = LocalStorageService.instance;
    final isTaken = storage.isSlotTakenToday(timeSlot, now);

    final scheduledDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );

    final scheduledTimeStr = routine.formatTime(timeOfDay);

    if (isTaken) {
      return DoseOmissionAlert(
        patientName: patientName,
        patientRut: patientRut,
        drugName: drugName,
        dosage: dosage,
        timeSlot: timeSlot,
        scheduledTimeStr: scheduledTimeStr,
        minutesOverdue: 0,
        status: OmissionStatus.taken,
        intakeId: intakeId,
      );
    }

    if (now.isBefore(scheduledDateTime)) {
      return DoseOmissionAlert(
        patientName: patientName,
        patientRut: patientRut,
        drugName: drugName,
        dosage: dosage,
        timeSlot: timeSlot,
        scheduledTimeStr: scheduledTimeStr,
        minutesOverdue: 0,
        status: OmissionStatus.future,
        intakeId: intakeId,
      );
    }

    final diffMinutes = now.difference(scheduledDateTime).inMinutes;

    if (diffMinutes < gracePeriodMinutes) {
      return DoseOmissionAlert(
        patientName: patientName,
        patientRut: patientRut,
        drugName: drugName,
        dosage: dosage,
        timeSlot: timeSlot,
        scheduledTimeStr: scheduledTimeStr,
        minutesOverdue: diffMinutes,
        status: OmissionStatus.inGracePeriod,
        intakeId: intakeId,
      );
    }

    return DoseOmissionAlert(
      patientName: patientName,
      patientRut: patientRut,
      drugName: drugName,
      dosage: dosage,
      timeSlot: timeSlot,
      scheduledTimeStr: scheduledTimeStr,
      minutesOverdue: diffMinutes,
      status: OmissionStatus.escalated,
      intakeId: intakeId,
    );
  }

  /// Retorna la primera alerta crítica de dosis omitida con escalada activa si existe
  DoseOmissionAlert? getActiveEscalatedAlert({DateTime? now, CircadianRoutine? routine}) {
    final alerts = evaluateAdherence(now: now, routine: routine);
    for (final alert in alerts) {
      if (alert.isEscalated) return alert;
    }
    return null;
  }

  /// Genera el texto estructurado de la alerta médica para WhatsApp
  String generateWhatsAppAlertMessage(DoseOmissionAlert alert) {
    return '''⚠️ *ALERTA DE ADHERENCIA MÉDICA CHRONOMED* ⚠️

Estimado/a cuidador/a,
Se ha detectado una *dosis no confirmada* para el paciente:

👤 *Paciente:* ${alert.patientName}
📋 *RUT:* ${alert.patientRut}
💊 *Medicamento:* ${alert.drugName} (${alert.dosage})
⏰ *Horario Programado:* ${alert.scheduledTimeStr}
⌛ *Tiempo Transcurrido:* ${alert.minutesOverdue} minutos sin confirmación

🚨 *Acción de Urgencia:*
Por favor comuníquese de inmediato con ${alert.patientName} o verifique su administración en el domicilio para evitar descompensaciones o duplicación de dosis.

_Reporte generado conforme a la Ley N° 20.584 de Derechos y Deberes del Paciente._''';
  }

  /// Registra la toma supervisada por el cuidador directamente, apagando la alerta
  Future<void> markDoseAsAdministeredByCaregiver(DoseOmissionAlert alert, {DateTime? timestamp}) async {
    await LocalStorageService.instance.recordIntake(
      intakeId: alert.intakeId,
      medicationName: alert.drugName,
      timeSlot: alert.timeSlot,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Dispara una notificación local de alta prioridad en Android si hay alerta de escalada
  Future<void> notifyCaregiverIfOverdue({DateTime? now, CircadianRoutine? routine}) async {
    final escalated = getActiveEscalatedAlert(now: now, routine: routine);
    if (escalated == null) return;

    final plugin = LocalNotificationService().plugin;

    const androidDetails = AndroidNotificationDetails(
      'chronomed_omission_escalation',
      'Alertas de Dosis Omitida (Escalada Cuidador)',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      color: Color(0xFFDC2626),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    await plugin.show(
      999,
      '⚠️ ¡Dosis Omitida! ${escalated.patientName}',
      '${escalated.drugName} lleva ${escalated.minutesOverdue} min sin confirmarse (hora: ${escalated.scheduledTimeStr}). Toca para verificar.',
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: 'escalation_${escalated.intakeId}',
    );
  }
}

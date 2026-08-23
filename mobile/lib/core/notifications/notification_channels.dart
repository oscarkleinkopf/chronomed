import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:typed_data';

class NotificationChannels {
  static final AndroidNotificationChannel criticalMedicationChannel = AndroidNotificationChannel(
    'chronomed_critical_alarms',
    'Alarmas Críticas de Medicación',
    description: 'Notificaciones prioritarias con sonido diferencial para tomas de medicamentos.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
  );

  static const AndroidNotificationChannel stockAlertChannel = AndroidNotificationChannel(
    'chronomed_stock_alerts',
    'Avisos de Farmacia y Stock',
    description: 'Recordatorios de reposición de medicamentos con 5 días de anticipación.',
    importance: Importance.defaultImportance,
    playSound: true,
  );
}

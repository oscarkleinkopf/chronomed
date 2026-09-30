import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../storage/local_storage_service.dart';
import '../../features/senior_mode/models/senior_intake_item.dart';

/// Servicio de sincronización con el Widget 4x1 de Pantalla de Inicio en Android.
///
/// Actualiza SharedPreferences nativas mediante [MethodChannel] para que
/// [NextDoseWidgetProvider] refresque la próxima dosis y el cumplimiento del día.
class HomeScreenWidgetService {
  static final HomeScreenWidgetService instance = HomeScreenWidgetService._internal();

  HomeScreenWidgetService._internal();

  static const MethodChannel _channel = MethodChannel('com.chronomed.app/widget');

  /// Actualiza los datos del widget nativo de pantalla de inicio.
  /// Si ocurre un PlatformException o MissingPluginException (por ejemplo en tests
  /// o plataformas sin soporte nativo de widgets), captura y retorna false de forma segura.
  Future<bool> updateWidgetData({
    String? patientName,
    String? nextMedicineName,
    String? nextDoseTime,
    String? adherenceToday,
  }) async {
    try {
      final pName = patientName ?? LocalStorageService.instance.patientName;
      final adherence = adherenceToday ?? computeTodayAdherence();
      final nextDose = (nextMedicineName != null && nextDoseTime != null)
          ? {'name': nextMedicineName, 'time': nextDoseTime}
          : computeNextDose();

      final result = await _channel.invokeMethod<bool>('updateWidgetData', {
        'patientName': pName,
        'nextMedicineName': nextDose['name'],
        'nextDoseTime': nextDose['time'],
        'adherenceToday': adherence,
      });

      return result ?? true;
    } catch (_) {
      // Ignorar en testing o si la plataforma no cuenta con el handler nativo
      return false;
    }
  }

  /// Calcula la cantidad de tomas completadas sobre las 4 franjas del día.
  String computeTodayAdherence([DateTime? referenceDate]) {
    int taken = 0;
    for (final slot in SeniorTimeSlot.values) {
      if (LocalStorageService.instance.isSlotTakenToday(slot, referenceDate)) {
        taken++;
      }
    }
    return '$taken/4 tomas';
  }

  /// Determina el próximo fármaco programado y su horario según el régimen circadiano.
  Map<String, String> computeNextDose([DateTime? referenceDate]) {
    final routine = LocalStorageService.instance.getCircadianRoutine();

    final slots = [
      {'slot': SeniorTimeSlot.morning, 'time': routine.breakfast, 'defaultDrug': 'Levotiroxina 100mcg'},
      {'slot': SeniorTimeSlot.lunch, 'time': routine.lunch, 'defaultDrug': 'Losartán 50mg'},
      {'slot': SeniorTimeSlot.afternoon, 'time': routine.afternoon, 'defaultDrug': 'Multivitamínico'},
      {'slot': SeniorTimeSlot.night, 'time': routine.night, 'defaultDrug': 'Atorvastatina 20mg'},
    ];

    for (final item in slots) {
      final slot = item['slot'] as SeniorTimeSlot;
      final timeOfDay = item['time'] as TimeOfDay;
      final isTaken = LocalStorageService.instance.isSlotTakenToday(slot, referenceDate);
      if (!isTaken) {
        return {
          'name': item['defaultDrug'] as String,
          'time': routine.formatTime(timeOfDay),
        };
      }
    }

    return {
      'name': 'Todas al día',
      'time': 'Completado ✓',
    };
  }
}

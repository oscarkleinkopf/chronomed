import 'package:flutter/material.dart';

enum CircadianRegimeType {
  home,
  hospital,
  custom,
}

class CircadianRoutine {
  final CircadianRegimeType regimeType;
  final TimeOfDay breakfast;
  final TimeOfDay lunch;
  final TimeOfDay afternoon;
  final TimeOfDay night;

  const CircadianRoutine({
    this.regimeType = CircadianRegimeType.home,
    this.breakfast = const TimeOfDay(hour: 8, minute: 0),
    this.lunch = const TimeOfDay(hour: 13, minute: 30),
    this.afternoon = const TimeOfDay(hour: 18, minute: 30),
    this.night = const TimeOfDay(hour: 22, minute: 30),
  });

  /// Preset para atención domiciliaria estándar en Chile
  static const CircadianRoutine home = CircadianRoutine(
    regimeType: CircadianRegimeType.home,
    breakfast: TimeOfDay(hour: 8, minute: 0),
    lunch: TimeOfDay(hour: 13, minute: 30),
    afternoon: TimeOfDay(hour: 18, minute: 30),
    night: TimeOfDay(hour: 22, minute: 30),
  );

  /// Preset para régimen hospitalario, clínicas y ELEAM (horarios tempranos)
  static const CircadianRoutine hospital = CircadianRoutine(
    regimeType: CircadianRegimeType.hospital,
    breakfast: TimeOfDay(hour: 7, minute: 0),
    lunch: TimeOfDay(hour: 12, minute: 0),
    afternoon: TimeOfDay(hour: 17, minute: 30),
    night: TimeOfDay(hour: 20, minute: 30),
  );

  String get regimeTitle {
    switch (regimeType) {
      case CircadianRegimeType.home:
        return "🏠 Régimen Hogar (Estándar)";
      case CircadianRegimeType.hospital:
        return "🏥 Régimen Hospital / ELEAM";
      case CircadianRegimeType.custom:
        return "⚙️ Régimen Personalizado";
    }
  }

  String get regimeDescription {
    switch (regimeType) {
      case CircadianRegimeType.home:
        return "Horarios habituales de vida en casa (Desayuno 08:00, Almuerzo 13:30, Once 18:30, Noche 22:30).";
      case CircadianRegimeType.hospital:
        return "Horarios adaptados a rondas clínicas, postración y turnos de enfermería (Desayuno 07:00, Almuerzo 12:00, Once 17:30, Noche 20:30).";
      case CircadianRegimeType.custom:
        return "Horarios ajustados manualmente a la rutina específica del paciente.";
    }
  }

  CircadianRoutine copyWith({
    CircadianRegimeType? regimeType,
    TimeOfDay? breakfast,
    TimeOfDay? lunch,
    TimeOfDay? afternoon,
    TimeOfDay? night,
  }) {
    return CircadianRoutine(
      regimeType: regimeType ?? this.regimeType,
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      afternoon: afternoon ?? this.afternoon,
      night: night ?? this.night,
    );
  }

  String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  /// Calcula la hora de toma en ayunas (30 minutos antes del desayuno)
  TimeOfDay get fastingTime {
    int totalMinutes = breakfast.hour * 60 + breakfast.minute - 30;
    if (totalMinutes < 0) totalMinutes += 1440;
    return TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
  }

  Map<String, dynamic> toJson() {
    return {
      'regimeType': regimeType.name,
      'breakfast': formatTime(breakfast),
      'lunch': formatTime(lunch),
      'afternoon': formatTime(afternoon),
      'night': formatTime(night),
    };
  }

  factory CircadianRoutine.fromJson(Map<String, dynamic> json) {
    TimeOfDay parse(String? str, TimeOfDay fallback) {
      if (str == null || !str.contains(':')) return fallback;
      final parts = str.split(':');
      return TimeOfDay(hour: int.tryParse(parts[0]) ?? fallback.hour, minute: int.tryParse(parts[1]) ?? fallback.minute);
    }

    final type = CircadianRegimeType.values.firstWhere(
      (e) => e.name == json['regimeType'],
      orElse: () => CircadianRegimeType.home,
    );

    return CircadianRoutine(
      regimeType: type,
      breakfast: parse(json['breakfast'], const TimeOfDay(hour: 8, minute: 0)),
      lunch: parse(json['lunch'], const TimeOfDay(hour: 13, minute: 30)),
      afternoon: parse(json['afternoon'], const TimeOfDay(hour: 18, minute: 30)),
      night: parse(json['night'], const TimeOfDay(hour: 22, minute: 30)),
    );
  }
}

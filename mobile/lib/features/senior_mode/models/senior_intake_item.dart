import '../../schedule/models/circadian_routine.dart';

enum SeniorTimeSlot { 
  morning, 
  lunch, 
  afternoon, 
  night;

  String get emoji {
    switch (this) {
      case SeniorTimeSlot.morning: return '☀️';
      case SeniorTimeSlot.lunch: return '🍲';
      case SeniorTimeSlot.afternoon: return '☕';
      case SeniorTimeSlot.night: return '🌙';
    }
  }

  String get label {
    switch (this) {
      case SeniorTimeSlot.morning: return 'DESAYUNO';
      case SeniorTimeSlot.lunch: return 'ALMUERZO';
      case SeniorTimeSlot.afternoon: return 'ONCE';
      case SeniorTimeSlot.night: return 'NOCHE';
    }
  }

  String getRoutineTime(CircadianRoutine routine) {
    switch (this) {
      case SeniorTimeSlot.morning: return routine.formatTime(routine.breakfast);
      case SeniorTimeSlot.lunch: return routine.formatTime(routine.lunch);
      case SeniorTimeSlot.afternoon: return routine.formatTime(routine.afternoon);
      case SeniorTimeSlot.night: return routine.formatTime(routine.night);
    }
  }
}

class SeniorIntakeItem {
  final String id;
  final String medicationName;
  final String dosage;
  final SeniorTimeSlot timeSlot;
  final String targetTime;
  final String colorHex;
  final String pillColorName;
  final String shapeType;
  final String voiceInstruction;
  final bool isTaken;
  final String? nextDoseTime;
  final String physicalDescription;
  final String imprint;
  final bool hasScoreLine;
  final String? pillImagePath;

  SeniorIntakeItem({
    required this.id,
    required this.medicationName,
    required this.dosage,
    required this.timeSlot,
    required this.targetTime,
    required this.colorHex,
    required this.pillColorName,
    required this.shapeType,
    required this.voiceInstruction,
    this.isTaken = false,
    this.nextDoseTime,
    this.physicalDescription = '',
    this.imprint = '',
    this.hasScoreLine = false,
    this.pillImagePath,
  });
}

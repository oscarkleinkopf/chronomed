enum SeniorTimeSlot { morning, lunch, afternoon, night }

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
  });
}

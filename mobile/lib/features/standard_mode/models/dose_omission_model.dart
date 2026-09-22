import '../../senior_mode/models/senior_intake_item.dart';

enum OmissionStatus {
  future,
  taken,
  inGracePeriod,
  escalated,
}

class DoseOmissionAlert {
  final String patientName;
  final String patientRut;
  final String drugName;
  final String dosage;
  final SeniorTimeSlot timeSlot;
  final String scheduledTimeStr;
  final int minutesOverdue;
  final OmissionStatus status;
  final String intakeId;

  const DoseOmissionAlert({
    required this.patientName,
    required this.patientRut,
    required this.drugName,
    required this.dosage,
    required this.timeSlot,
    required this.scheduledTimeStr,
    required this.minutesOverdue,
    required this.status,
    required this.intakeId,
  });

  bool get isEscalated => status == OmissionStatus.escalated;
  bool get isInGracePeriod => status == OmissionStatus.inGracePeriod;
  bool get isTaken => status == OmissionStatus.taken;
  bool get isFuture => status == OmissionStatus.future;

  String get statusBadgeLabel {
    switch (status) {
      case OmissionStatus.escalated:
        return '⚠️ ALERTA: $minutesOverdue min retraso';
      case OmissionStatus.inGracePeriod:
        return '⏳ En ventana ($minutesOverdue min)';
      case OmissionStatus.taken:
        return '✅ Administrada';
      case OmissionStatus.future:
        return '⏰ Próxima';
    }
  }
}

class PairingPayload {
  final String caregiverId;
  final String patientId;
  final String patientName;
  final String seniorPin;
  final int expiresAt;
  final Map<String, dynamic>? routine;
  final List<dynamic>? medications;
  final List<dynamic>? vitals;

  PairingPayload({
    required this.caregiverId,
    required this.patientId,
    required this.patientName,
    required this.seniorPin,
    required this.expiresAt,
    this.routine,
    this.medications,
    this.vitals,
  });

  bool get isExpired => (DateTime.now().millisecondsSinceEpoch ~/ 1000) > expiresAt;
}

class PairingPayload {
  final String caregiverId;
  final String patientId;
  final String patientName;
  final String seniorPin;
  final int expiresAt;

  PairingPayload({
    required this.caregiverId,
    required this.patientId,
    required this.patientName,
    required this.seniorPin,
    required this.expiresAt,
  });

  bool get isExpired => (DateTime.now().millisecondsSinceEpoch ~/ 1000) > expiresAt;
}

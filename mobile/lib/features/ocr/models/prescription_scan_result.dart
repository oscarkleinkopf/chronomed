class PrescriptionScanResult {
  final String rawText;
  final String? detectedDrugName;
  final String? detectedDosage;
  final int? detectedFrequencyHours;
  final String? detectedMealRelation;
  final int? detectedDurationDays;
  final double confidenceScore;

  PrescriptionScanResult({
    required this.rawText,
    this.detectedDrugName,
    this.detectedDosage,
    this.detectedFrequencyHours,
    this.detectedMealRelation,
    this.detectedDurationDays,
    this.confidenceScore = 0.0,
  });
}

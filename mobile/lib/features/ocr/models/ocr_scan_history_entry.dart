enum OcrScanType {
  medicineBox,
  prescription,
}

class OcrScanHistoryEntry {
  final String id;
  final OcrScanType scanType;
  final DateTime scannedAt;
  final String extractedText;
  final String? medicineName;
  final String? dosage;
  final String? ispRegister;
  final bool isBioequivalent;
  final List<String> interactionsDetected;
  final bool wasAccepted;

  const OcrScanHistoryEntry({
    required this.id,
    required this.scanType,
    required this.scannedAt,
    required this.extractedText,
    this.medicineName,
    this.dosage,
    this.ispRegister,
    this.isBioequivalent = false,
    this.interactionsDetected = const [],
    this.wasAccepted = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scanType': scanType.name,
      'scannedAt': scannedAt.toIso8601String(),
      'extractedText': extractedText,
      'medicineName': medicineName,
      'dosage': dosage,
      'ispRegister': ispRegister,
      'isBioequivalent': isBioequivalent,
      'interactionsDetected': interactionsDetected,
      'wasAccepted': wasAccepted,
    };
  }

  factory OcrScanHistoryEntry.fromJson(Map<String, dynamic> json) {
    return OcrScanHistoryEntry(
      id: json['id'] as String,
      scanType: json['scanType'] == 'prescription' ? OcrScanType.prescription : OcrScanType.medicineBox,
      scannedAt: DateTime.tryParse(json['scannedAt']?.toString() ?? '') ?? DateTime.now(),
      extractedText: json['extractedText'] as String? ?? '',
      medicineName: json['medicineName'] as String?,
      dosage: json['dosage'] as String?,
      ispRegister: json['ispRegister'] as String?,
      isBioequivalent: json['isBioequivalent'] as bool? ?? false,
      interactionsDetected: (json['interactionsDetected'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      wasAccepted: json['wasAccepted'] as bool? ?? true,
    );
  }

  OcrScanHistoryEntry copyWith({
    String? id,
    OcrScanType? scanType,
    DateTime? scannedAt,
    String? extractedText,
    String? medicineName,
    String? dosage,
    String? ispRegister,
    bool? isBioequivalent,
    List<String>? interactionsDetected,
    bool? wasAccepted,
  }) {
    return OcrScanHistoryEntry(
      id: id ?? this.id,
      scanType: scanType ?? this.scanType,
      scannedAt: scannedAt ?? this.scannedAt,
      extractedText: extractedText ?? this.extractedText,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      ispRegister: ispRegister ?? this.ispRegister,
      isBioequivalent: isBioequivalent ?? this.isBioequivalent,
      interactionsDetected: interactionsDetected ?? this.interactionsDetected,
      wasAccepted: wasAccepted ?? this.wasAccepted,
    );
  }
}

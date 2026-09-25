import 'package:flutter/material.dart';

enum BoxExpirationStatus {
  valid,
  expiringSoon,
  expired,
  unknown,
}

class MedicineBoxScanResult {
  final String rawText;
  final String? detectedDrugName;
  final String? detectedDosage;
  final int? detectedUnits;
  final String? detectedLotNumber;
  final String? detectedExpirationDate;
  final String? detectedIspRegister;
  final bool isBioequivalent;
  final DateTime? expirationDateTime;
  final int? daysRemaining;
  final BoxExpirationStatus expirationStatus;
  final double confidenceScore;

  MedicineBoxScanResult({
    required this.rawText,
    this.detectedDrugName,
    this.detectedDosage,
    this.detectedUnits,
    this.detectedLotNumber,
    this.detectedExpirationDate,
    this.detectedIspRegister,
    this.isBioequivalent = false,
    this.expirationDateTime,
    this.daysRemaining,
    this.expirationStatus = BoxExpirationStatus.unknown,
    this.confidenceScore = 0.0,
  });

  String get statusLabel {
    switch (expirationStatus) {
      case BoxExpirationStatus.valid:
        return 'VIGENTE / APTO PARA CONSUMO';
      case BoxExpirationStatus.expiringSoon:
        return 'POR VENCER (RENOVAR BOTIQUÍN)';
      case BoxExpirationStatus.expired:
        return 'VENCIDO - NO INGERIR';
      case BoxExpirationStatus.unknown:
        return 'FECHA NO DETECTADA';
    }
  }

  Color get statusColor {
    switch (expirationStatus) {
      case BoxExpirationStatus.valid:
        return const Color(0xFF059669); // Green
      case BoxExpirationStatus.expiringSoon:
        return const Color(0xFFD97706); // Amber
      case BoxExpirationStatus.expired:
        return const Color(0xFFDC2626); // Red
      case BoxExpirationStatus.unknown:
        return const Color(0xFF64748B); // Slate
    }
  }

  String get statusEmoji {
    switch (expirationStatus) {
      case BoxExpirationStatus.valid:
        return '✅';
      case BoxExpirationStatus.expiringSoon:
        return '⚠️';
      case BoxExpirationStatus.expired:
        return '⛔';
      case BoxExpirationStatus.unknown:
        return '❓';
    }
  }

  bool get isAlertActive =>
      expirationStatus == BoxExpirationStatus.expired ||
      expirationStatus == BoxExpirationStatus.expiringSoon;
}

import 'package:flutter/material.dart';

enum BloodPressureStatus {
  normal,        // Sistólica < 120 y Diastólica < 80
  elevated,      // Sistólica 120-129 y Diastólica < 80
  stage1,        // Sistólica 130-139 o Diastólica 80-89
  stage2,        // Sistólica >= 140 o Diastólica >= 90
  crisis,        // Sistólica > 180 o Diastólica > 120
}

enum GlucoseStatus {
  low,           // < 70 mg/dL (Hipoglicemia)
  normal,        // 70 - 99 mg/dL (Ayunas) o < 140 (Postprandial)
  prediabetes,   // 100 - 125 mg/dL (Ayunas)
  high,          // >= 126 mg/dL (Ayunas) o >= 200 (Postprandial)
}

enum GlucoseMealContext {
  fasting,       // En ayunas
  postprandial,  // 2 hrs post comida
  random,        // Toma aleatoria
}

/// Registro clínico de signos vitales asociado a un paciente.
class VitalSignEntry {
  final String id;
  final String patientId;
  final DateTime timestamp;
  final int? systolic;      // mmHg
  final int? diastolic;     // mmHg
  final int? heartRate;     // bpm
  final double? bloodGlucose; // mg/dL
  final GlucoseMealContext mealContext;
  final String? notes;

  VitalSignEntry({
    required this.id,
    required this.patientId,
    required this.timestamp,
    this.systolic,
    this.diastolic,
    this.heartRate,
    this.bloodGlucose,
    this.mealContext = GlucoseMealContext.fasting,
    this.notes,
  });

  bool get hasBloodPressure => systolic != null && diastolic != null;
  bool get hasGlucose => bloodGlucose != null;
  bool get hasHeartRate => heartRate != null;

  BloodPressureStatus? get bloodPressureStatus {
    if (!hasBloodPressure) return null;
    final sys = systolic!;
    final dia = diastolic!;

    if (sys > 180 || dia > 120) return BloodPressureStatus.crisis;
    if (sys >= 140 || dia >= 90) return BloodPressureStatus.stage2;
    if ((sys >= 130 && sys <= 139) || (dia >= 80 && dia <= 89)) return BloodPressureStatus.stage1;
    if (sys >= 120 && sys <= 129 && dia < 80) return BloodPressureStatus.elevated;
    return BloodPressureStatus.normal;
  }

  String get bloodPressureLabel {
    final status = bloodPressureStatus;
    if (status == null) return 'No registrada';
    switch (status) {
      case BloodPressureStatus.normal:
        return 'Normal / Óptima';
      case BloodPressureStatus.elevated:
        return 'Elevada';
      case BloodPressureStatus.stage1:
        return 'Hipertensión Etapa 1';
      case BloodPressureStatus.stage2:
        return 'Hipertensión Etapa 2';
      case BloodPressureStatus.crisis:
        return '⚠️ Crisis Hipertensiva';
    }
  }

  Color get bloodPressureColor {
    final status = bloodPressureStatus;
    if (status == null) return const Color(0xFF64748B);
    switch (status) {
      case BloodPressureStatus.normal:
        return const Color(0xFF16A34A); // Verde
      case BloodPressureStatus.elevated:
        return const Color(0xFFCA8A04); // Amarillo
      case BloodPressureStatus.stage1:
        return const Color(0xFFEA580C); // Naranja
      case BloodPressureStatus.stage2:
      case BloodPressureStatus.crisis:
        return const Color(0xFFDC2626); // Rojo
    }
  }

  GlucoseStatus? get glucoseStatus {
    if (!hasGlucose) return null;
    final g = bloodGlucose!;
    if (g < 70) return GlucoseStatus.low;

    if (mealContext == GlucoseMealContext.fasting) {
      if (g < 100) return GlucoseStatus.normal;
      if (g <= 125) return GlucoseStatus.prediabetes;
      return GlucoseStatus.high;
    } else {
      if (g < 140) return GlucoseStatus.normal;
      return GlucoseStatus.high;
    }
  }

  String get glucoseLabel {
    final status = glucoseStatus;
    if (status == null) return 'No registrada';
    switch (status) {
      case GlucoseStatus.low:
        return '⚠️ Hipoglicemia (<70)';
      case GlucoseStatus.normal:
        return 'Normal';
      case GlucoseStatus.prediabetes:
        return 'Glicemia Alterada en Ayunas';
      case GlucoseStatus.high:
        return '⚠️ Glicemia Elevada';
    }
  }

  Color get glucoseColor {
    final status = glucoseStatus;
    if (status == null) return const Color(0xFF64748B);
    switch (status) {
      case GlucoseStatus.normal:
        return const Color(0xFF16A34A);
      case GlucoseStatus.prediabetes:
        return const Color(0xFFCA8A04);
      case GlucoseStatus.low:
      case GlucoseStatus.high:
        return const Color(0xFFDC2626);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'timestamp': timestamp.toIso8601String(),
      'systolic': systolic,
      'diastolic': diastolic,
      'heartRate': heartRate,
      'bloodGlucose': bloodGlucose,
      'mealContext': mealContext.name,
      'notes': notes,
    };
  }

  factory VitalSignEntry.fromJson(Map<String, dynamic> json) {
    GlucoseMealContext meal = GlucoseMealContext.fasting;
    if (json['mealContext'] != null) {
      meal = GlucoseMealContext.values.firstWhere(
        (e) => e.name == json['mealContext'],
        orElse: () => GlucoseMealContext.fasting,
      );
    }

    return VitalSignEntry(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      patientId: json['patientId']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      systolic: json['systolic'] != null ? int.tryParse(json['systolic'].toString()) : null,
      diastolic: json['diastolic'] != null ? int.tryParse(json['diastolic'].toString()) : null,
      heartRate: json['heartRate'] != null ? int.tryParse(json['heartRate'].toString()) : null,
      bloodGlucose: json['bloodGlucose'] != null ? double.tryParse(json['bloodGlucose'].toString()) : null,
      mealContext: meal,
      notes: json['notes']?.toString(),
    );
  }
}

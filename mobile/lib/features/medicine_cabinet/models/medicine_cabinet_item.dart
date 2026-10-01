import 'package:flutter/material.dart';
import '../../ocr/models/medicine_box_scan_result.dart';

class MedicineCabinetItem {
  final String id;
  final String name;
  final String dosage;
  final int stockUnits;
  final String? lotNumber;
  final String? expirationDate;
  final String? ispRegister;
  final bool isBioequivalent;
  final BoxExpirationStatus expirationStatus;
  final String shapeType; // 'round', 'small_round', 'oblong'
  final int pillColorValue; // Color.value
  final String imprint;
  final bool hasScoreLine;
  final String physicalDescription;
  final String? nfcTagId;
  final String? nfcPayload;
  final DateTime createdAt;

  MedicineCabinetItem({
    required this.id,
    required this.name,
    required this.dosage,
    required this.stockUnits,
    this.lotNumber,
    this.expirationDate,
    this.ispRegister,
    this.isBioequivalent = false,
    this.expirationStatus = BoxExpirationStatus.unknown,
    this.shapeType = 'round',
    this.pillColorValue = 0xFF3B82F6, // Default blue
    this.imprint = '',
    this.hasScoreLine = false,
    this.physicalDescription = '',
    this.nfcTagId,
    this.nfcPayload,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get hasNfcTag => nfcTagId != null && nfcTagId!.trim().isNotEmpty;

  Color get pillColor => Color(pillColorValue);

  /// Construye un ítem de botiquín a partir del resultado del escáner OCR de la caja.
  factory MedicineCabinetItem.fromScanResult(
    MedicineBoxScanResult result, {
    String? id,
    int? customUnits,
    String? defaultDosage,
  }) {
    final rawName = result.detectedDrugName?.trim();
    final name = (rawName != null && rawName.isNotEmpty) ? rawName : 'Medicamento sin nombre';
    final dosage = result.detectedDosage ?? defaultDosage ?? 'Dosis estándar';
    final units = customUnits ?? result.detectedUnits ?? 30;

    // Preset visual por defecto según nombre común chileno
    final lower = name.toLowerCase();
    String shape = 'round';
    int colorVal = 0xFF3B82F6; // Azul
    String imp = '';
    bool score = false;
    String desc = '';

    if (lower.contains('eutirox') || lower.contains('levotiroxina')) {
      shape = 'small_round';
      colorVal = 0xFFFFFFFF; // Blanco
      imp = '100';
      score = true;
      desc = "Comprimido blanco circular pequeño grabado '100' con ranura de partición";
    } else if (lower.contains('losart')) {
      shape = 'round';
      colorVal = 0xFF3B82F6; // Azul
      imp = '50';
      score = true;
      desc = "Comprimido circular azul grabado '50' con ranura central";
    } else if (lower.contains('atorvastatina')) {
      shape = 'oblong';
      colorVal = 0xFFFACC15; // Amarillo
      imp = '20';
      score = false;
      desc = "Comprimido oblongo amarillo grabado '20'";
    } else if (lower.contains('paracetamol')) {
      shape = 'oblong';
      colorVal = 0xFFFFFFFF; // Blanco
      imp = '500';
      score = true;
      desc = "Comprimido oblongo blanco ranurado '500'";
    }

    return MedicineCabinetItem(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      dosage: dosage,
      stockUnits: units,
      lotNumber: result.detectedLotNumber,
      expirationDate: result.detectedExpirationDate,
      ispRegister: result.detectedIspRegister,
      isBioequivalent: result.isBioequivalent,
      expirationStatus: result.expirationStatus,
      shapeType: shape,
      pillColorValue: colorVal,
      imprint: imp,
      hasScoreLine: score,
      physicalDescription: desc,
      createdAt: DateTime.now(),
    );
  }

  MedicineCabinetItem copyWith({
    String? id,
    String? name,
    String? dosage,
    int? stockUnits,
    String? lotNumber,
    String? expirationDate,
    String? ispRegister,
    bool? isBioequivalent,
    BoxExpirationStatus? expirationStatus,
    String? shapeType,
    int? pillColorValue,
    String? imprint,
    bool? hasScoreLine,
    String? physicalDescription,
    String? nfcTagId,
    String? nfcPayload,
    bool clearNfcTag = false,
    DateTime? createdAt,
  }) {
    return MedicineCabinetItem(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      stockUnits: stockUnits ?? this.stockUnits,
      lotNumber: lotNumber ?? this.lotNumber,
      expirationDate: expirationDate ?? this.expirationDate,
      ispRegister: ispRegister ?? this.ispRegister,
      isBioequivalent: isBioequivalent ?? this.isBioequivalent,
      expirationStatus: expirationStatus ?? this.expirationStatus,
      shapeType: shapeType ?? this.shapeType,
      pillColorValue: pillColorValue ?? this.pillColorValue,
      imprint: imprint ?? this.imprint,
      hasScoreLine: hasScoreLine ?? this.hasScoreLine,
      physicalDescription: physicalDescription ?? this.physicalDescription,
      nfcTagId: clearNfcTag ? null : (nfcTagId ?? this.nfcTagId),
      nfcPayload: clearNfcTag ? null : (nfcPayload ?? this.nfcPayload),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'stockUnits': stockUnits,
      'lotNumber': lotNumber,
      'expirationDate': expirationDate,
      'ispRegister': ispRegister,
      'isBioequivalent': isBioequivalent,
      'expirationStatus': expirationStatus.name,
      'shapeType': shapeType,
      'pillColorValue': pillColorValue,
      'imprint': imprint,
      'hasScoreLine': hasScoreLine,
      'physicalDescription': physicalDescription,
      'nfcTagId': nfcTagId,
      'nfcPayload': nfcPayload,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MedicineCabinetItem.fromJson(Map<String, dynamic> json) {
    BoxExpirationStatus status = BoxExpirationStatus.unknown;
    if (json['expirationStatus'] != null) {
      status = BoxExpirationStatus.values.firstWhere(
        (e) => e.name == json['expirationStatus'],
        orElse: () => BoxExpirationStatus.unknown,
      );
    }

    return MedicineCabinetItem(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name']?.toString() ?? 'Fármaco',
      dosage: json['dosage']?.toString() ?? '',
      stockUnits: int.tryParse(json['stockUnits']?.toString() ?? '0') ?? 0,
      lotNumber: json['lotNumber']?.toString(),
      expirationDate: json['expirationDate']?.toString(),
      ispRegister: json['ispRegister']?.toString(),
      isBioequivalent: json['isBioequivalent'] == true,
      expirationStatus: status,
      shapeType: json['shapeType']?.toString() ?? 'round',
      pillColorValue: int.tryParse(json['pillColorValue']?.toString() ?? '0xFF3B82F6') ?? 0xFF3B82F6,
      imprint: json['imprint']?.toString() ?? '',
      hasScoreLine: json['hasScoreLine'] == true,
      physicalDescription: json['physicalDescription']?.toString() ?? '',
      nfcTagId: json['nfcTagId']?.toString(),
      nfcPayload: json['nfcPayload']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

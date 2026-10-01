import 'package:flutter/material.dart';
import '../../medicine_cabinet/models/medicine_cabinet_item.dart';
import '../../schedule/models/circadian_routine.dart';
import '../../vital_signs/models/vital_sign_entry.dart';

/// Perfil clínico individual de un paciente / adulto mayor.
class PatientProfile {
  final String id;
  final String name;
  final String rut;
  final int? age;
  final int avatarColorValue;
  final Map<String, int> stocks;
  final List<MedicineCabinetItem> cabinetItems;
  final CircadianRoutine routine;
  final List<Map<String, dynamic>> intakes;
  final Map<String, String> voiceNotes;
  final List<VitalSignEntry> vitalSigns;
  final DateTime createdAt;

  PatientProfile({
    required this.id,
    required this.name,
    required this.rut,
    this.age,
    this.avatarColorValue = 0xFF2563EB,
    Map<String, int>? stocks,
    List<MedicineCabinetItem>? cabinetItems,
    CircadianRoutine? routine,
    List<Map<String, dynamic>>? intakes,
    Map<String, String>? voiceNotes,
    List<VitalSignEntry>? vitalSigns,
    DateTime? createdAt,
  })  : stocks = stocks != null ? Map<String, int>.from(stocks) : _defaultStocks(),
        cabinetItems = cabinetItems != null ? List<MedicineCabinetItem>.from(cabinetItems) : _defaultCabinetItems(),
        routine = routine ?? CircadianRoutine.home,
        intakes = intakes != null ? List<Map<String, dynamic>>.from(intakes) : [],
        voiceNotes = voiceNotes != null ? Map<String, String>.from(voiceNotes) : {},
        vitalSigns = vitalSigns != null ? List<VitalSignEntry>.from(vitalSigns) : [],
        createdAt = createdAt ?? DateTime.now();

  Color get avatarColor => Color(avatarColorValue);

  static Map<String, int> _defaultStocks() => {
        'eutirox': 28,
        'losartan': 14,
        'atorvastatina': 30,
      };

  static List<MedicineCabinetItem> _defaultCabinetItems() => [
        MedicineCabinetItem(
          id: 'default-eutirox',
          name: 'Eutirox (Levotiroxina Sódica)',
          dosage: '100 mcg',
          stockUnits: 28,
          lotNumber: 'M10492',
          expirationDate: '10/2027',
          ispRegister: 'F-18451/20',
          isBioequivalent: true,
          shapeType: 'small_round',
          pillColorValue: 0xFFFFFFFF,
          imprint: '100',
          hasScoreLine: true,
          physicalDescription: "Comprimido blanco circular pequeño grabado '100' con ranura de partición",
        ),
        MedicineCabinetItem(
          id: 'default-losartan',
          name: 'Losartán Potásico',
          dosage: '50 mg',
          stockUnits: 14,
          lotNumber: 'K44019',
          expirationDate: '03/2027',
          ispRegister: 'F-14920/19',
          isBioequivalent: true,
          shapeType: 'round',
          pillColorValue: 0xFF3B82F6,
          imprint: '50',
          hasScoreLine: true,
          physicalDescription: "Comprimido circular azul grabado '50' con ranura central",
        ),
        MedicineCabinetItem(
          id: 'default-atorvastatina',
          name: 'Atorvastatina',
          dosage: '20 mg',
          stockUnits: 30,
          lotNumber: 'L88214',
          expirationDate: '12/2026',
          ispRegister: 'F-16203/21',
          isBioequivalent: true,
          shapeType: 'oblong',
          pillColorValue: 0xFFFACC15,
          imprint: '20',
          hasScoreLine: false,
          physicalDescription: "Comprimido oblongo amarillo grabado '20'",
        ),
      ];

  PatientProfile copyWith({
    String? id,
    String? name,
    String? rut,
    int? age,
    int? avatarColorValue,
    Map<String, int>? stocks,
    List<MedicineCabinetItem>? cabinetItems,
    CircadianRoutine? routine,
    List<Map<String, dynamic>>? intakes,
    Map<String, String>? voiceNotes,
    List<VitalSignEntry>? vitalSigns,
    DateTime? createdAt,
  }) {
    return PatientProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      rut: rut ?? this.rut,
      age: age ?? this.age,
      avatarColorValue: avatarColorValue ?? this.avatarColorValue,
      stocks: stocks ?? this.stocks,
      cabinetItems: cabinetItems ?? this.cabinetItems,
      routine: routine ?? this.routine,
      intakes: intakes ?? this.intakes,
      voiceNotes: voiceNotes ?? this.voiceNotes,
      vitalSigns: vitalSigns ?? this.vitalSigns,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rut': rut,
      'age': age,
      'avatarColorValue': avatarColorValue,
      'stocks': stocks,
      'cabinetItems': cabinetItems.map((e) => e.toJson()).toList(),
      'routine': routine.toJson(),
      'intakes': intakes,
      'voiceNotes': voiceNotes,
      'vitalSigns': vitalSigns.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    List<MedicineCabinetItem> items = [];
    if (json['cabinetItems'] != null && json['cabinetItems'] is List) {
      items = (json['cabinetItems'] as List)
          .map((e) => MedicineCabinetItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    Map<String, int> loadedStocks = {};
    if (json['stocks'] != null && json['stocks'] is Map) {
      final raw = json['stocks'] as Map;
      raw.forEach((k, v) {
        loadedStocks[k.toString()] = int.tryParse(v.toString()) ?? 0;
      });
    }

    CircadianRoutine loadedRoutine = CircadianRoutine.home;
    if (json['routine'] != null && json['routine'] is Map) {
      loadedRoutine = CircadianRoutine.fromJson(Map<String, dynamic>.from(json['routine'] as Map));
    }

    List<Map<String, dynamic>> loadedIntakes = [];
    if (json['intakes'] != null && json['intakes'] is List) {
      loadedIntakes = (json['intakes'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    Map<String, String> loadedVoices = {};
    if (json['voiceNotes'] != null && json['voiceNotes'] is Map) {
      (json['voiceNotes'] as Map).forEach((k, v) {
        loadedVoices[k.toString()] = v.toString();
      });
    }

    List<VitalSignEntry> loadedVitals = [];
    if (json['vitalSigns'] != null && json['vitalSigns'] is List) {
      loadedVitals = (json['vitalSigns'] as List)
          .map((e) => VitalSignEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    return PatientProfile(
      id: json['id']?.toString() ?? 'patient-${DateTime.now().millisecondsSinceEpoch}',
      name: json['name']?.toString() ?? 'Marcela',
      rut: json['rut']?.toString() ?? '14.567.890-K',
      age: json['age'] != null ? int.tryParse(json['age'].toString()) : null,
      avatarColorValue: int.tryParse(json['avatarColorValue']?.toString() ?? '0xFF2563EB') ?? 0xFF2563EB,
      stocks: loadedStocks.isNotEmpty ? loadedStocks : null,
      cabinetItems: items.isNotEmpty ? items : null,
      routine: loadedRoutine,
      intakes: loadedIntakes,
      voiceNotes: loadedVoices,
      vitalSigns: loadedVitals,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

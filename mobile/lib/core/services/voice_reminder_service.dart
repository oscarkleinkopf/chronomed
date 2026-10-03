import 'package:flutter/foundation.dart';
import '../../features/senior_mode/models/senior_intake_item.dart';
import '../storage/local_storage_service.dart';
import 'tts_service.dart';

class VoiceNoteModel {
  final SeniorTimeSlot slot;
  final String author;
  final String audioPath;
  final String messageText;
  final int durationSeconds;
  final DateTime recordedAt;

  const VoiceNoteModel({
    required this.slot,
    required this.author,
    required this.audioPath,
    this.messageText = '',
    this.durationSeconds = 4,
    required this.recordedAt,
  });

  factory VoiceNoteModel.fromMap(Map<String, dynamic> map) {
    return VoiceNoteModel(
      slot: SeniorTimeSlot.values.firstWhere(
        (s) => s.name == map['slot'],
        orElse: () => SeniorTimeSlot.lunch,
      ),
      author: map['author'] ?? 'Familiar',
      audioPath: map['audioPath'] ?? '',
      messageText: map['messageText'] ?? '',
      durationSeconds: map['durationSeconds'] is int
          ? map['durationSeconds']
          : int.tryParse(map['durationSeconds']?.toString() ?? '4') ?? 4,
      recordedAt: DateTime.tryParse(map['recordedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'slot': slot.name,
      'author': author,
      'audioPath': audioPath,
      'messageText': messageText,
      'durationSeconds': durationSeconds,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }

  VoiceNoteModel copyWith({
    SeniorTimeSlot? slot,
    String? author,
    String? audioPath,
    String? messageText,
    int? durationSeconds,
    DateTime? recordedAt,
  }) {
    return VoiceNoteModel(
      slot: slot ?? this.slot,
      author: author ?? this.author,
      audioPath: audioPath ?? this.audioPath,
      messageText: messageText ?? this.messageText,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }
}

class VoiceReminderService {
  static final VoiceReminderService instance = VoiceReminderService._internal();

  VoiceReminderService._internal();

  bool isPlaying = false;
  String? lastPlayedAuthor;
  SeniorTimeSlot? lastPlayedSlot;

  /// Obtiene la nota de voz configurada para un momento del día
  VoiceNoteModel? getVoiceNote(SeniorTimeSlot slot) {
    final data = LocalStorageService.instance.getVoiceNote(slot);
    if (data == null) return null;
    return VoiceNoteModel.fromMap(data);
  }

  /// Retorna un mapa de todas las notas de voz activas del paciente
  Map<SeniorTimeSlot, VoiceNoteModel> getAllVoiceNotes() {
    final raw = LocalStorageService.instance.getAllVoiceNotes();
    final Map<SeniorTimeSlot, VoiceNoteModel> notes = {};
    raw.forEach((key, map) {
      final slot = SeniorTimeSlot.values.firstWhere(
        (s) => s.name == key,
        orElse: () => SeniorTimeSlot.lunch,
      );
      notes[slot] = VoiceNoteModel.fromMap(map);
    });
    return notes;
  }

  /// Retorna los momentos del día que tienen una nota grabada
  List<SeniorTimeSlot> getRecordedSlots() {
    return SeniorTimeSlot.values.where(hasVoiceNote).toList();
  }

  /// Verifica si existe una nota de voz familiar activa para la franja
  bool hasVoiceNote(SeniorTimeSlot slot) {
    return LocalStorageService.instance.hasVoiceNote(slot);
  }

  /// Determina el texto exacto a locutar (voz familiar o fallback)
  String getSpokenInstruction({
    required SeniorTimeSlot slot,
    required String fallbackTtsText,
  }) {
    final note = getVoiceNote(slot);
    if (note != null && note.messageText.trim().isNotEmpty) {
      return 'Mensaje de ${note.author}: "${note.messageText.trim()}"';
    }
    return fallbackTtsText;
  }

  /// Guarda una nueva nota de voz grabada por el familiar o cuidador
  Future<void> saveVoiceNote({
    required SeniorTimeSlot slot,
    required String author,
    required String audioPath,
    String? messageText,
    int? durationSeconds,
  }) async {
    await LocalStorageService.instance.saveVoiceNote(
      slot: slot,
      author: author,
      audioPath: audioPath,
      messageText: messageText,
      durationSeconds: durationSeconds,
    );
  }

  /// Elimina la nota de voz para restaurar la locución TTS estándar
  Future<void> deleteVoiceNote(SeniorTimeSlot slot) async {
    await LocalStorageService.instance.deleteVoiceNote(slot);
  }

  /// Detiene cualquier reproducción de audio o locución en curso
  Future<void> stopPlayback() async {
    isPlaying = false;
    lastPlayedAuthor = null;
    lastPlayedSlot = null;
    await TtsService().stop();
  }

  /// Reproduce la alarma médica: usa la voz del familiar si existe, o TTS estándar como fallback
  Future<void> playVoiceReminder({
    required SeniorTimeSlot slot,
    required String fallbackTtsText,
    VoidCallback? onStarted,
    VoidCallback? onCompleted,
  }) async {
    final note = getVoiceNote(slot);

    isPlaying = true;
    lastPlayedSlot = slot;
    onStarted?.call();

    try {
      if (note != null) {
        lastPlayedAuthor = note.author;
        debugPrint('ChronoMed Voice: Reproduciendo voz familiar de ${note.author} para ${slot.label}');

        final spokenMessage = getSpokenInstruction(
          slot: slot,
          fallbackTtsText: fallbackTtsText,
        );

        await TtsService().speak(spokenMessage);
      } else {
        lastPlayedAuthor = null;
        debugPrint('ChronoMed Voice: Usando voz TTS estándar para ${slot.label}');
        await TtsService().speak(fallbackTtsText);
      }
    } finally {
      isPlaying = false;
      onCompleted?.call();
    }
  }

  /// Atajo para reproducir el recordatorio de un slot específico
  Future<void> playReminder(SeniorTimeSlot slot) async {
    await playVoiceReminder(
      slot: slot,
      fallbackTtsText: 'Recordatorio de toma para ${slot.label}',
    );
  }
}

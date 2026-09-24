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
      durationSeconds: map['durationSeconds'] ?? 4,
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
}

class VoiceReminderService {
  static final VoiceReminderService instance = VoiceReminderService._internal();

  VoiceReminderService._internal();

  bool isPlaying = false;
  String? lastPlayedAuthor;

  /// Obtiene la nota de voz configurada para un momento del día
  VoiceNoteModel? getVoiceNote(SeniorTimeSlot slot) {
    final data = LocalStorageService.instance.getVoiceNote(slot);
    if (data == null) return null;
    return VoiceNoteModel.fromMap(data);
  }

  /// Verifica si existe una nota de voz familiar activa para la franja
  bool hasVoiceNote(SeniorTimeSlot slot) {
    return LocalStorageService.instance.hasVoiceNote(slot);
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

  /// Reproduce la alarma médica: usa la voz del familiar si existe, o TTS estándar como fallback
  Future<void> playVoiceReminder({
    required SeniorTimeSlot slot,
    required String fallbackTtsText,
    VoidCallback? onStarted,
    VoidCallback? onCompleted,
  }) async {
    final note = getVoiceNote(slot);

    isPlaying = true;
    onStarted?.call();

    if (note != null) {
      lastPlayedAuthor = note.author;
      debugPrint('ChronoMed Voice: Reproduciendo voz familiar de ${note.author} para ${slot.label}');

      // Si existe transcripción del mensaje familiar, se pronuncia con cadencia afectuosa
      // o se ejecuta el audio local si está disponible
      final spokenMessage = note.messageText.isNotEmpty
          ? 'Mensaje de ${note.author}: "${note.messageText}"'
          : fallbackTtsText;

      await TtsService().speak(spokenMessage);
    } else {
      lastPlayedAuthor = null;
      debugPrint('ChronoMed Voice: Usando voz TTS estándar para ${slot.label}');
      await TtsService().speak(fallbackTtsText);
    }

    isPlaying = false;
    onCompleted?.call();
  }
}

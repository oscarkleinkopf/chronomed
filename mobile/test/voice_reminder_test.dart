import 'package:flutter_test/flutter_test.dart';
import 'package:chronomed/core/services/voice_reminder_service.dart';
import 'package:chronomed/core/storage/local_storage_service.dart';
import 'package:chronomed/features/patients/models/patient_profile.dart';
import 'package:chronomed/features/senior_mode/models/senior_intake_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChronoMed Voice Reminder Module & Patient Isolation Tests', () {
    late LocalStorageService storage;
    late VoiceReminderService voiceService;

    setUp(() async {
      storage = LocalStorageService.instance;
      await storage.init(inMemory: true);
      await storage.resetAllData();
      voiceService = VoiceReminderService.instance;
    });

    test('VoiceNoteModel serializes to and from Map correctly', () {
      final now = DateTime(2026, 10, 3, 12, 0);
      final model = VoiceNoteModel(
        slot: SeniorTimeSlot.lunch,
        author: 'Hija Andrea',
        audioPath: 'voice_lunch.m4a',
        messageText: 'Papá, tómate tu pastilla de Losartán con agua.',
        durationSeconds: 5,
        recordedAt: now,
      );

      final map = model.toMap();
      expect(map['slot'], equals('lunch'));
      expect(map['author'], equals('Hija Andrea'));
      expect(map['audioPath'], equals('voice_lunch.m4a'));
      expect(map['messageText'], equals('Papá, tómate tu pastilla de Losartán con agua.'));
      expect(map['durationSeconds'], equals(5));
      expect(map['recordedAt'], equals(now.toIso8601String()));

      final restored = VoiceNoteModel.fromMap(map);
      expect(restored.slot, equals(SeniorTimeSlot.lunch));
      expect(restored.author, equals('Hija Andrea'));
      expect(restored.audioPath, equals('voice_lunch.m4a'));
      expect(restored.messageText, equals('Papá, tómate tu pastilla de Losartán con agua.'));
      expect(restored.durationSeconds, equals(5));
      expect(restored.recordedAt, equals(now));
    });

    test('VoiceNoteModel copyWith updates fields properly', () {
      final model = VoiceNoteModel(
        slot: SeniorTimeSlot.morning,
        author: 'Hijo Carlos',
        audioPath: 'audio_morning.m4a',
        messageText: 'Buenos días mamá.',
        recordedAt: DateTime.now(),
      );

      final updated = model.copyWith(
        author: 'Nieto Mateo',
        messageText: 'Hola abuelita, toma tu pastilla.',
        durationSeconds: 6,
      );

      expect(updated.slot, equals(SeniorTimeSlot.morning));
      expect(updated.author, equals('Nieto Mateo'));
      expect(updated.messageText, equals('Hola abuelita, toma tu pastilla.'));
      expect(updated.durationSeconds, equals(6));
      expect(updated.audioPath, equals('audio_morning.m4a'));
    });

    test('Starts without voice notes and correctly formats fallback TTS instruction', () {
      expect(voiceService.hasVoiceNote(SeniorTimeSlot.lunch), isFalse);
      expect(voiceService.getVoiceNote(SeniorTimeSlot.lunch), isNull);
      expect(voiceService.getRecordedSlots(), isEmpty);

      const fallback = 'Es momento de tu almuerzo. Toma tu pastilla azul de Losartán.';
      final spoken = voiceService.getSpokenInstruction(
        slot: SeniorTimeSlot.lunch,
        fallbackTtsText: fallback,
      );

      expect(spoken, equals(fallback));
    });

    test('Saves voice note for circadian slot and formats affectionate message', () async {
      await voiceService.saveVoiceNote(
        slot: SeniorTimeSlot.lunch,
        author: 'Hija Andrea',
        audioPath: 'voice_lunch_marcela.m4a',
        messageText: 'Papá, es hora del almuerzo. Tómate tu pastilla azul.',
        durationSeconds: 4,
      );

      expect(voiceService.hasVoiceNote(SeniorTimeSlot.lunch), isTrue);
      final note = voiceService.getVoiceNote(SeniorTimeSlot.lunch);
      expect(note, isNotNull);
      expect(note!.author, equals('Hija Andrea'));
      expect(note.durationSeconds, equals(4));

      final spoken = voiceService.getSpokenInstruction(
        slot: SeniorTimeSlot.lunch,
        fallbackTtsText: 'Instrucción genérica',
      );
      expect(spoken, equals('Mensaje de Hija Andrea: "Papá, es hora del almuerzo. Tómate tu pastilla azul."'));
    });

    test('Manages multiple circadian slots independently', () async {
      await voiceService.saveVoiceNote(
        slot: SeniorTimeSlot.morning,
        author: 'Hija Andrea',
        audioPath: 'morning.m4a',
        messageText: 'Eutirox en ayunas.',
      );
      await voiceService.saveVoiceNote(
        slot: SeniorTimeSlot.lunch,
        author: 'Hijo Carlos',
        audioPath: 'lunch.m4a',
        messageText: 'Losartán con el almuerzo.',
      );
      await voiceService.saveVoiceNote(
        slot: SeniorTimeSlot.night,
        author: 'Nieto Mateo',
        audioPath: 'night.m4a',
        messageText: 'Atorvastatina antes de dormir.',
      );

      final recorded = voiceService.getRecordedSlots();
      expect(recorded.length, equals(3));
      expect(recorded, contains(SeniorTimeSlot.morning));
      expect(recorded, contains(SeniorTimeSlot.lunch));
      expect(recorded, contains(SeniorTimeSlot.night));
      expect(recorded, isNot(contains(SeniorTimeSlot.afternoon)));

      final allNotes = voiceService.getAllVoiceNotes();
      expect(allNotes[SeniorTimeSlot.morning]?.author, equals('Hija Andrea'));
      expect(allNotes[SeniorTimeSlot.lunch]?.author, equals('Hijo Carlos'));
      expect(allNotes[SeniorTimeSlot.night]?.author, equals('Nieto Mateo'));
    });

    test('Deletes voice note and restores fallback speech synthesis', () async {
      await voiceService.saveVoiceNote(
        slot: SeniorTimeSlot.morning,
        author: 'Hija Andrea',
        audioPath: 'morning.m4a',
        messageText: 'Mensaje temporal.',
      );
      expect(voiceService.hasVoiceNote(SeniorTimeSlot.morning), isTrue);

      await voiceService.deleteVoiceNote(SeniorTimeSlot.morning);

      expect(voiceService.hasVoiceNote(SeniorTimeSlot.morning), isFalse);
      expect(voiceService.getVoiceNote(SeniorTimeSlot.morning), isNull);

      final spoken = voiceService.getSpokenInstruction(
        slot: SeniorTimeSlot.morning,
        fallbackTtsText: 'Voz TTS estándar',
      );
      expect(spoken, equals('Voz TTS estándar'));
    });

    test('Guarantees strict clinical isolation of voice reminders between patients', () async {
      // Configure voice note for Marcela
      await voiceService.saveVoiceNote(
        slot: SeniorTimeSlot.lunch,
        author: 'Hija Andrea',
        audioPath: 'marcela_lunch.m4a',
        messageText: 'Mamá Marcela, te quiero mucho. Toma tu pastilla.',
      );

      expect(voiceService.hasVoiceNote(SeniorTimeSlot.lunch), isTrue);
      expect(voiceService.getVoiceNote(SeniorTimeSlot.lunch)?.author, equals('Hija Andrea'));

      // Add Roberto Gómez and switch to him
      final roberto = PatientProfile(
        id: 'patient-roberto-2',
        name: 'Roberto Gómez',
        rut: '12.345.678-5',
      );
      await storage.addPatient(roberto, setActive: true);

      // Roberto must NOT have Marcela's voice note
      expect(voiceService.hasVoiceNote(SeniorTimeSlot.lunch), isFalse);
      expect(voiceService.getVoiceNote(SeniorTimeSlot.lunch), isNull);

      // Configure a different voice note for Roberto
      await voiceService.saveVoiceNote(
        slot: SeniorTimeSlot.lunch,
        author: 'Hijo Carlos',
        audioPath: 'roberto_lunch.m4a',
        messageText: 'Papá Roberto, toma tu medicina.',
      );
      expect(voiceService.hasVoiceNote(SeniorTimeSlot.lunch), isTrue);
      expect(voiceService.getVoiceNote(SeniorTimeSlot.lunch)?.author, equals('Hijo Carlos'));

      // Switch back to Marcela
      await storage.switchPatient('patient-marcela-1');
      expect(voiceService.hasVoiceNote(SeniorTimeSlot.lunch), isTrue);
      expect(voiceService.getVoiceNote(SeniorTimeSlot.lunch)?.author, equals('Hija Andrea'));
      expect(voiceService.getVoiceNote(SeniorTimeSlot.lunch)?.messageText, contains('Mamá Marcela'));

      // Switch back to Roberto
      await storage.switchPatient('patient-roberto-2');
      expect(voiceService.hasVoiceNote(SeniorTimeSlot.lunch), isTrue);
      expect(voiceService.getVoiceNote(SeniorTimeSlot.lunch)?.author, equals('Hijo Carlos'));
      expect(voiceService.getVoiceNote(SeniorTimeSlot.lunch)?.messageText, contains('Papá Roberto'));
    });
  });
}

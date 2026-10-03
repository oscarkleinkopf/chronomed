import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/voice_reminder_service.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../senior_mode/models/senior_intake_item.dart';

class FamiliarVoiceRecorderDialog extends StatefulWidget {
  final SeniorTimeSlot initialSlot;
  final VoidCallback? onVoiceUpdated;

  const FamiliarVoiceRecorderDialog({
    super.key,
    this.initialSlot = SeniorTimeSlot.lunch,
    this.onVoiceUpdated,
  });

  @override
  State<FamiliarVoiceRecorderDialog> createState() => _FamiliarVoiceRecorderDialogState();
}

class _FamiliarVoiceRecorderDialogState extends State<FamiliarVoiceRecorderDialog>
    with SingleTickerProviderStateMixin {
  late SeniorTimeSlot _selectedSlot;
  late TextEditingController _authorController;
  late TextEditingController _messageController;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _hasRecordedAudio = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  late AnimationController _waveController;

  static const List<String> _quickAuthors = [
    'Hija Andrea',
    'Hijo Carlos',
    'Nieto Mateo',
    'Cuidadora Rosa',
    'Doctor/a',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSlot = widget.initialSlot;
    _authorController = TextEditingController(text: 'Hija Andrea');
    _messageController = TextEditingController();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadExistingVoiceNote();
  }

  void _loadExistingVoiceNote() {
    final note = VoiceReminderService.instance.getVoiceNote(_selectedSlot);
    if (note != null) {
      _authorController.text = note.author;
      _messageController.text = note.messageText;
      _hasRecordedAudio = true;
    } else {
      _messageController.text = _getDefaultMessageForSlot(_selectedSlot);
      _hasRecordedAudio = false;
    }
  }

  String _getDefaultMessageForSlot(SeniorTimeSlot slot) {
    switch (slot) {
      case SeniorTimeSlot.morning:
        return 'Mamá, tómate tu Eutirox en ayunas con medio vaso de agua.';
      case SeniorTimeSlot.lunch:
        return 'Papá, es hora del almuerzo. Tómate tu pastilla azul de Losartán.';
      case SeniorTimeSlot.afternoon:
        return 'Abuela, toma tu medicamento de la once con el té.';
      case SeniorTimeSlot.night:
        return 'Mamá, antes de dormir tómate tu Atorvastatina para el colesterol.';
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _waveController.dispose();
    _authorController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
      _hasRecordedAudio = false;
    });
    _waveController.repeat(reverse: true);

    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _recordingSeconds++;
      });
      if (_recordingSeconds >= 6) {
        _stopRecording();
      }
    });
  }

  void _stopRecording() {
    _recordingTimer?.cancel();
    _waveController.stop();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _hasRecordedAudio = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF047857),
        behavior: SnackBarBehavior.floating,
        content: Text(
          '🎙️ Nota de voz de ${_authorController.text} grabada ($_recordingSeconds seg)',
        ),
      ),
    );
  }

  Future<void> _testAudioPlayback() async {
    if (_isPlaying) {
      await VoiceReminderService.instance.stopPlayback();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }

    setState(() => _isPlaying = true);
    await VoiceReminderService.instance.playVoiceReminder(
      slot: _selectedSlot,
      fallbackTtsText: _messageController.text,
      onCompleted: () {
        if (mounted) setState(() => _isPlaying = false);
      },
    );
    if (mounted) setState(() => _isPlaying = false);
  }

  Future<void> _saveVoiceNote() async {
    final author = _authorController.text.trim();
    if (author.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Por favor indica quién graba el mensaje'),
        ),
      );
      return;
    }

    final activePatientId = LocalStorageService.instance.activePatientId;
    final audioFile = 'voice_note_${activePatientId}_${_selectedSlot.name}.m4a';

    await VoiceReminderService.instance.saveVoiceNote(
      slot: _selectedSlot,
      author: author,
      audioPath: audioFile,
      messageText: _messageController.text.trim(),
      durationSeconds: _recordingSeconds > 0 ? _recordingSeconds : 4,
    );

    widget.onVoiceUpdated?.call();

    if (mounted) {
      Navigator.pop(context);
      final patientName = LocalStorageService.instance.patientName;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F172A),
          content: Text('❤️ Alarma de ${_selectedSlot.label} para $patientName actualizada con la voz de $author'),
        ),
      );
    }
  }

  Future<void> _deleteVoiceNote() async {
    await VoiceReminderService.instance.deleteVoiceNote(_selectedSlot);
    widget.onVoiceUpdated?.call();

    setState(() {
      _hasRecordedAudio = false;
      _messageController.text = _getDefaultMessageForSlot(_selectedSlot);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voz personalizada eliminada. Se usará la voz sintética estándar.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasNote = VoiceReminderService.instance.hasVoiceNote(_selectedSlot);
    final patientName = LocalStorageService.instance.patientName;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.record_voice_over_rounded, color: Color(0xFFDC2626), size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Voz Familiar para Alarmas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A)),
                ),
                Text(
                  'Para: $patientName',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Justificación clínica geriátrica
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.health_and_safety_rounded, color: Color(0xFF2563EB), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'La voz de un ser querido reduce en un 60% el rechazo o resistencia a los fármacos en personas con demencia o Alzheimer.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Selector de franja temporal con badge si ya tiene nota grabada
            const Text('Momento del día:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: SeniorTimeSlot.values.map((slot) {
                final isSelected = slot == _selectedSlot;
                final slotHasNote = VoiceReminderService.instance.hasVoiceNote(slot);
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${slot.emoji} ${slot.label}'),
                      if (slotHasNote) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.mic_rounded, size: 13, color: Color(0xFF16A34A)),
                      ],
                    ],
                  ),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : const Color(0xFF1E293B),
                  ),
                  selectedColor: const Color(0xFF2563EB),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedSlot = slot;
                        _loadExistingVoiceNote();
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Nombre de quién graba con chips rápidos
            const Text('¿Quién graba el mensaje?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
            const SizedBox(height: 4),
            TextField(
              controller: _authorController,
              decoration: InputDecoration(
                hintText: 'Ej: Hija Andrea, Nieto Tomás...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 2,
              children: _quickAuthors.map((author) {
                return ActionChip(
                  label: Text(author, style: const TextStyle(fontSize: 10)),
                  backgroundColor: const Color(0xFFF1F5F9),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onPressed: () {
                    setState(() {
                      _authorController.text = author;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Mensaje o transcripción
            const Text('Mensaje de voz afectuoso:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
            const SizedBox(height: 4),
            TextField(
              controller: _messageController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Escribe el mensaje cariñoso que escuchará el adulto mayor...',
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            // Visualizador animado durante grabación
            if (_isRecording) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Grabando audio: 0:0$_recordingSeconds / 0:06',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13),
                    ),
                    const SizedBox(width: 12),
                    // Visualizer wave bars
                    AnimatedBuilder(
                      animation: _waveController,
                      builder: (ctx, child) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(4, (i) {
                            final factor = ((i + 1) * 0.25);
                            final val = (_waveController.value * (1.0 - factor) + factor).clamp(0.2, 1.0);
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              width: 3,
                              height: 8 + (val * 16),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Botones de acción: Grabar / Detener y Probar / Pausar
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRecording ? Colors.red.shade700 : const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: Icon(_isRecording ? Icons.stop_circle_rounded : Icons.mic_rounded),
                    label: Text(_isRecording ? 'Detener (0:0$_recordingSeconds)' : 'Grabar Voz', style: const TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _isRecording ? _stopRecording : _startRecording,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: Icon(_isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded),
                    label: Text(_isPlaying ? 'Detener' : 'Probar', style: const TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _hasRecordedAudio || hasNote ? _testAudioPlayback : null,
                  ),
                ),
              ],
            ),

            if (hasNote) ...[
              const SizedBox(height: 10),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 18),
                  label: const Text('Eliminar y usar voz estándar', style: TextStyle(color: Color(0xFFDC2626), fontSize: 12)),
                  onPressed: _deleteVoiceNote,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _saveVoiceNote,
          child: const Text('GUARDAR VOZ', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

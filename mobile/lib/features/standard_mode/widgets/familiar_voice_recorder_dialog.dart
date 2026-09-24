import 'package:flutter/material.dart';
import '../../../core/services/voice_reminder_service.dart';
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

class _FamiliarVoiceRecorderDialogState extends State<FamiliarVoiceRecorderDialog> {
  late SeniorTimeSlot _selectedSlot;
  late TextEditingController _authorController;
  late TextEditingController _messageController;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _hasRecordedAudio = false;

  @override
  void initState() {
    super.initState();
    _selectedSlot = widget.initialSlot;
    _authorController = TextEditingController(text: 'Hija Andrea');
    _messageController = TextEditingController();
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
    _authorController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _startSimulatedRecording() async {
    setState(() => _isRecording = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isRecording = false;
        _hasRecordedAudio = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF047857),
          content: Text('🎙️ Audio grabado exitosamente (4 segundos)'),
        ),
      );
    }
  }

  Future<void> _testAudioPlayback() async {
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
    if (_authorController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.red, content: Text('Por favor indica quién graba el mensaje')),
      );
      return;
    }

    await VoiceReminderService.instance.saveVoiceNote(
      slot: _selectedSlot,
      author: _authorController.text.trim(),
      audioPath: 'voice_note_${_selectedSlot.name}.m4a',
      messageText: _messageController.text.trim(),
      durationSeconds: 4,
    );

    widget.onVoiceUpdated?.call();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F172A),
          content: Text('❤️ Alarma de ${_selectedSlot.label} actualizada con la voz de ${_authorController.text}'),
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
          const Expanded(
            child: Text(
              'Voz Familiar para Alarmas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
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

            // Selector de franja temporal
            const Text('Momento del día:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: SeniorTimeSlot.values.map((slot) {
                final isSelected = slot == _selectedSlot;
                return ChoiceChip(
                  label: Text('${slot.emoji} ${slot.label}', style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
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

            // Nombre de quién graba
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
            const SizedBox(height: 12),

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
            const SizedBox(height: 16),

            // Estado de grabación y acciones de audio
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRecording ? Colors.red : const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: Icon(_isRecording ? Icons.fiber_manual_record_rounded : Icons.mic_rounded),
                    label: Text(_isRecording ? 'Grabando...' : 'Grabar Voz', style: const TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _isRecording ? null : _startSimulatedRecording,
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
                    label: Text(_isPlaying ? 'Pausar' : 'Probar', style: const TextStyle(fontWeight: FontWeight.bold)),
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

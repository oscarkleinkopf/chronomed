import 'package:flutter/material.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/theme/senior_theme.dart';
import '../../../core/storage/local_storage_service.dart';
import '../models/senior_intake_item.dart';
import '../../schedule/models/circadian_routine.dart';
import '../widgets/overdose_guard_button.dart';
import '../widgets/physical_pill_widget.dart';

class SeniorSingleActionScreen extends StatefulWidget {
  final String patientName;
  final String caregiverPin;
  final CircadianRoutine routine;

  const SeniorSingleActionScreen({
    super.key,
    required this.patientName,
    required this.caregiverPin,
    this.routine = CircadianRoutine.home,
  });

  @override
  State<SeniorSingleActionScreen> createState() => _SeniorSingleActionScreenState();
}

class _SeniorSingleActionScreenState extends State<SeniorSingleActionScreen> {
  late SeniorIntakeItem _currentIntake;

  @override
  void initState() {
    super.initState();
    final lunchTime = widget.routine.formatTime(widget.routine.lunch);
    final nextTime = widget.routine.formatTime(widget.routine.night);
    final regimeLabel = widget.routine.regimeType == CircadianRegimeType.hospital ? 'en régimen hospitalario' : '';
    final isAlreadyTaken = LocalStorageService.instance.isSlotTakenToday(SeniorTimeSlot.lunch);

    _currentIntake = SeniorIntakeItem(
      id: 'intake-123',
      medicationName: 'Losartán Potásico',
      dosage: '50 mg (1 comprimido)',
      timeSlot: SeniorTimeSlot.lunch,
      targetTime: lunchTime,
      colorHex: '#3B82F6',
      pillColorName: 'azul',
      shapeType: 'round',
      imprint: '50',
      hasScoreLine: true,
      physicalDescription: 'Comprimido circular azul con número 50 grabado y ranura central de partición',
      voiceInstruction: isAlreadyTaken
          ? 'Hola ${widget.patientName}. Ya tomaste tu dosis de Losartán para el almuerzo. Bloqueo anti-sobredosis activo. Tu siguiente toma es a las $nextTime.'
          : 'Hola ${widget.patientName}. Es momento de tu almuerzo ($lunchTime $regimeLabel). Toma tu comprimido circular azul con número 50 grabado de Losartán con un vaso de agua. Si necesitas verla más grande, toca la pastilla.',
      isTaken: isAlreadyTaken,
      nextDoseTime: nextTime,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      TtsService().speak(_currentIntake.voiceInstruction);
    });
  }

  void _markAsTaken() {
    setState(() {
      _currentIntake = SeniorIntakeItem(
        id: _currentIntake.id,
        medicationName: _currentIntake.medicationName,
        dosage: _currentIntake.dosage,
        timeSlot: _currentIntake.timeSlot,
        targetTime: _currentIntake.targetTime,
        colorHex: _currentIntake.colorHex,
        pillColorName: _currentIntake.pillColorName,
        shapeType: _currentIntake.shapeType,
        imprint: _currentIntake.imprint,
        hasScoreLine: _currentIntake.hasScoreLine,
        physicalDescription: _currentIntake.physicalDescription,
        pillImagePath: _currentIntake.pillImagePath,
        voiceInstruction: _currentIntake.voiceInstruction,
        isTaken: true,
        nextDoseTime: _currentIntake.nextDoseTime,
      );
    });

    LocalStorageService.instance.recordIntake(
      intakeId: _currentIntake.id,
      medicationName: _currentIntake.medicationName,
      timeSlot: _currentIntake.timeSlot,
      timestamp: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SeniorTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Hola, ${widget.patientName} 👋', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: SeniorTheme.textPrimary)),
        actions: [
          IconButton(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            iconSize: 40,
            tooltip: 'Escuchar indicación médica por voz',
            icon: const Icon(Icons.volume_up_rounded, color: SeniorTheme.accentYellow),
            onPressed: () => TtsService().speak(_currentIntake.voiceInstruction),
          ),
          const SizedBox(width: 4),
          IconButton(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            iconSize: 32,
            tooltip: 'Acceso a modo cuidador con PIN',
            icon: const Icon(Icons.settings_outlined, color: Color(0xFFF1F5F9)),
            onPressed: _showCaregiverPinDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: 'Momento de la toma: ${_currentIntake.timeSlot.label}, hora: ${_currentIntake.targetTime}',
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                  decoration: BoxDecoration(
                    color: SeniorTheme.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: SeniorTheme.accentYellow, width: 2),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_currentIntake.timeSlot.emoji, style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Text('${_currentIntake.timeSlot.label} (${_currentIntake.targetTime})', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: SeniorTheme.accentYellow)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: SeniorTheme.cardBackground,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PhysicalPillWidget(
                            size: 110,
                            shapeType: _currentIntake.shapeType,
                            pillColor: Color(int.parse(_currentIntake.colorHex.replaceFirst('#', '0xFF'))),
                            imprint: _currentIntake.imprint,
                            hasScoreLine: _currentIntake.hasScoreLine,
                            imagePath: _currentIntake.pillImagePath,
                            medicationName: _currentIntake.medicationName,
                            dosage: _currentIntake.dosage,
                            physicalDescription: _currentIntake.physicalDescription,
                            enableMagnifier: true,
                          ),
                          const SizedBox(height: 8),
                          Semantics(
                            excludeSemantics: true,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.zoom_in_rounded, size: 20, color: SeniorTheme.textSecondary),
                                SizedBox(width: 4),
                                Text(
                                  'Toca la pastilla para ampliar',
                                  style: TextStyle(fontSize: 14, color: SeniorTheme.textSecondary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(_currentIntake.medicationName, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: SeniorTheme.textPrimary), textAlign: TextAlign.center),
                          const SizedBox(height: 6),
                          Text(_currentIntake.dosage, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: SeniorTheme.accentYellow)),
                          const SizedBox(height: 12),
                          const Text('Tómala con un vaso de agua', style: TextStyle(fontSize: 18, color: Color(0xFFF1F5F9)), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              OverdoseGuardButton(
                isTaken: _currentIntake.isTaken,
                nextDoseTime: _currentIntake.nextDoseTime ?? '20:30',
                onConfirm: _markAsTaken,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showCaregiverPinDialog() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SeniorTheme.cardBackground,
        title: const Text('Acceso Cuidador', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa el PIN de 4 dígitos:', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              style: const TextStyle(fontSize: 28, color: Colors.white, letterSpacing: 10),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              if (pinController.text == widget.caregiverPin) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Modo Cuidador Desbloqueado')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.red, content: Text('PIN Incorrecto')));
              }
            },
            child: const Text('ENTRAR'),
          ),
        ],
      ),
    );
  }
}

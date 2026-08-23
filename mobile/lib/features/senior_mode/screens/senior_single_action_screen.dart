import 'package:flutter/material.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/theme/senior_theme.dart';
import '../models/senior_intake_item.dart';
import '../widgets/overdose_guard_button.dart';

class SeniorSingleActionScreen extends StatefulWidget {
  final String patientName;
  final String caregiverPin;

  const SeniorSingleActionScreen({
    super.key,
    required this.patientName,
    required this.caregiverPin,
  });

  @override
  State<SeniorSingleActionScreen> createState() => _SeniorSingleActionScreenState();
}

class _SeniorSingleActionScreenState extends State<SeniorSingleActionScreen> {
  late SeniorIntakeItem _currentIntake;

  @override
  void initState() {
    super.initState();
    _currentIntake = SeniorIntakeItem(
      id: 'intake-123',
      medicationName: 'Losartán Potásico',
      dosage: '50 mg (1 pastilla)',
      timeSlot: SeniorTimeSlot.lunch,
      targetTime: '13:30',
      colorHex: '#3B82F6',
      pillColorName: 'azul',
      shapeType: 'round',
      voiceInstruction: 'Hola ${widget.patientName}. Es momento de tu almuerzo. Toma tu pastilla azul de Losartán con un vaso de agua.',
      isTaken: false,
      nextDoseTime: '20:30',
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
        voiceInstruction: _currentIntake.voiceInstruction,
        isTaken: true,
        nextDoseTime: _currentIntake.nextDoseTime,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SeniorTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Hola, ${widget.patientName} 👋', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            iconSize: 40,
            icon: const Icon(Icons.volume_up_rounded, color: SeniorTheme.accentYellow),
            onPressed: () => TtsService().speak(_currentIntake.voiceInstruction),
          ),
          IconButton(
            iconSize: 32,
            icon: const Icon(Icons.settings_outlined, color: Colors.white60),
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
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                decoration: BoxDecoration(
                  color: SeniorTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SeniorTheme.accentYellow, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🍲', style: TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Text('ALMUERZO (${_currentIntake.targetTime})', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: SeniorTheme.accentYellow)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: SeniorTheme.cardBackground,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.4), blurRadius: 20, spreadRadius: 4),
                          ],
                        ),
                        child: const Center(child: Icon(Icons.medication_rounded, size: 64, color: Colors.white)),
                      ),
                      const SizedBox(height: 24),
                      Text(_currentIntake.medicationName, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: SeniorTheme.textPrimary), textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(_currentIntake.dosage, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: SeniorTheme.accentYellow)),
                      const SizedBox(height: 16),
                      const Text('Tómala con un vaso de agua', style: TextStyle(fontSize: 20, color: Colors.white70), textAlign: TextAlign.center),
                    ],
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

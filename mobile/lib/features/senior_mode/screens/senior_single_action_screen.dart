import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/theme/senior_theme.dart';
import '../../../core/storage/local_storage_service.dart';
import '../models/senior_intake_item.dart';
import '../../schedule/models/circadian_routine.dart';
import '../widgets/overdose_guard_button.dart';
import '../widgets/physical_pill_widget.dart';
import '../../../core/services/voice_reminder_service.dart';
import '../../../core/sync/local_p2p_sync_service.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/nfc_medication_service.dart';

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
  StreamSubscription<NfcTagScanResult>? _nfcSubscription;

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
      VoiceReminderService.instance.playVoiceReminder(
        slot: _currentIntake.timeSlot,
        fallbackTtsText: _currentIntake.voiceInstruction,
      );
    });

    _nfcSubscription = NfcMedicationService.instance.onTagScanned.listen(_handleNfcScan);
    NfcMedicationService.instance.startListening(
      expectedMedicineName: _currentIntake.medicationName,
    );
  }

  @override
  void dispose() {
    _nfcSubscription?.cancel();
    NfcMedicationService.instance.stopListening();
    super.dispose();
  }

  void _handleNfcScan(NfcTagScanResult scan) {
    if (!mounted) return;

    if (_currentIntake.isTaken) {
      TtsService().speak(
        'Hola ${widget.patientName}. Ya tomaste tu dosis de ${_currentIntake.medicationName}. Bloqueo anti-sobredosis activo.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF1E293B),
          content: Text('⚠️ Dosis ya registrada. Bloqueo anti-sobredosis activo.'),
        ),
      );
      return;
    }

    if (scan.isSuccess) {
      _markAsTaken();
      TtsService().speak(
        '¡Pastillero detectado con éxito! Dosis de ${_currentIntake.medicationName} confirmada.',
      );
    } else if (scan.isWarning) {
      TtsService().speak(
        '¡Atención ${widget.patientName}! Ese pastillero es de ${scan.matchedMedicine?.name ?? "otro medicamento"}. Tu dosis actual es ${_currentIntake.medicationName}.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 5),
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '¡Pastillero incorrecto! Pertenece a ${scan.matchedMedicine?.name}. Tu dosis es ${_currentIntake.medicationName}.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (scan.isUnregistered) {
      TtsService().speak(
        'Tag NFC no reconocido. Por favor avisa a tu cuidador para vincularlo en el botiquín.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF475569),
          content: Text('Tag NFC no vinculado a este botiquín.'),
        ),
      );
    }
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

    final timestamp = DateTime.now();
    LocalStorageService.instance.recordIntake(
      intakeId: _currentIntake.id,
      medicationName: _currentIntake.medicationName,
      timeSlot: _currentIntake.timeSlot,
      timestamp: timestamp,
    );

    // Sincronización soberana P2P en red local al cuidador (si está configurado host)
    final caregiverHost = LocalStorageService.instance.caregiverHost;
    if (caregiverHost != null && caregiverHost.isNotEmpty) {
      LocalP2pSyncService.instance.setSharedSecret(LocalStorageService.instance.p2pSecret);
      final payload = LocalP2pSyncService.instance.createSignedPayload(
        intakeId: _currentIntake.id,
        patientRut: LocalStorageService.instance.patientRut,
        medicationName: _currentIntake.medicationName,
        dosage: _currentIntake.dosage,
        timeSlot: _currentIntake.timeSlot,
        timestamp: timestamp,
      );
      LocalP2pSyncService.instance.sendIntakeToCaregiver(
        payload: payload,
        caregiverHost: caregiverHost,
        port: LocalStorageService.instance.p2pPort,
      );
    }

    // Sincronización en la Nube (si está habilitada en Configuración)
    if (LocalStorageService.instance.cloudBackupEnabled) {
      final cloudPayload = LocalP2pSyncService.instance.createSignedPayload(
        intakeId: _currentIntake.id,
        patientRut: LocalStorageService.instance.patientRut,
        medicationName: _currentIntake.medicationName,
        dosage: _currentIntake.dosage,
        timeSlot: _currentIntake.timeSlot,
        timestamp: timestamp,
      );
      ApiClient.instance.syncSingleIntake(cloudPayload);
    }

    // Refuerzo positivo y celebratorio (accesibilidad cognitiva)
    TtsService().speak('¡Muy bien ${widget.patientName}! Tu toma de ${_currentIntake.medicationName} ha quedado registrada con éxito.');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          content: Row(
            children: const [
              Text('🎉', style: TextStyle(fontSize: 24)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '¡Excelente! Toma registrada con éxito.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
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
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: const [
                                Icon(Icons.zoom_in_rounded, size: 20, color: SeniorTheme.textSecondary),
                                SizedBox(width: 4),
                                Text(
                                  'Toca la pastilla para ampliar',
                                  style: TextStyle(fontSize: 14, color: SeniorTheme.textSecondary, fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.center,
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
              if (!_currentIntake.isTaken) ...[
                const SizedBox(height: 10),
                Semantics(
                  label: 'También puedes confirmar acercando tu pastillero con tag NFC al teléfono.',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.nfc_rounded, color: SeniorTheme.accentYellow, size: 18),
                        SizedBox(width: 8),
                        Text(
                          '📡 O acerca tu pastillero NFC al teléfono',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/manual');
                },
                icon: const Icon(Icons.menu_book_rounded, size: 16, color: SeniorTheme.accentYellow),
                label: const Text('MANUAL', style: TextStyle(color: SeniorTheme.accentYellow, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const Spacer(),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
              ElevatedButton(
                onPressed: () {
                  if (pinController.text == widget.caregiverPin) {
                    Navigator.pop(ctx);
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      context.go('/');
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.red, content: Text('PIN Incorrecto')));
                  }
                },
                child: const Text('ENTRAR'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

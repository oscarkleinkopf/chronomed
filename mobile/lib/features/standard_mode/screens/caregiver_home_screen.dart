import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/standard_theme.dart';
import '../../senior_mode/screens/senior_single_action_screen.dart';
import '../../schedule/models/circadian_routine.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../medicine_cabinet/screens/medicine_cabinet_screen.dart';
import '../../medicine_cabinet/models/medicine_cabinet_item.dart';
import '../widgets/familiar_voice_recorder_dialog.dart';
import '../widgets/adherence_timeline_widget.dart';
import '../../senior_mode/models/senior_intake_item.dart';
import '../services/dose_omission_service.dart';

import '../controllers/caregiver_p2p_controller.dart';
import '../controllers/caregiver_pdf_controller.dart';
import '../controllers/caregiver_circadian_controller.dart';
import '../controllers/caregiver_adherence_controller.dart';
import '../controllers/caregiver_ocr_controller.dart';
import '../widgets/circadian_routine_card.dart';
import '../widgets/escalation_alert_banner.dart';
import '../widgets/active_medication_card.dart';

class CaregiverHomeScreen extends StatefulWidget {
  const CaregiverHomeScreen({super.key});

  @override
  State<CaregiverHomeScreen> createState() => _CaregiverHomeScreenState();
}

class _CaregiverHomeScreenState extends State<CaregiverHomeScreen> {
  String get _patientName => LocalStorageService.instance.patientName;
  String get _patientRut => LocalStorageService.instance.patientRut;
  String get _caregiverPin => LocalStorageService.instance.caregiverPin;

  late CaregiverP2PController _p2pController;
  late CaregiverPdfController _pdfController;
  late CaregiverCircadianController _circadianController;
  late CaregiverAdherenceController _adherenceController;
  late CaregiverOcrController _ocrController;

  @override
  void initState() {
    super.initState();
    _p2pController = CaregiverP2PController();
    _pdfController = CaregiverPdfController();
    _circadianController = CaregiverCircadianController();
    _adherenceController = CaregiverAdherenceController();
    _ocrController = CaregiverOcrController();

    _circadianController.addListener(() => setState(() {}));
    _ocrController.addListener(() => setState(() {}));

    _loadData();
    _p2pController.startReceiver(context, _loadData);
  }

  void _loadData() {
    _circadianController.loadRoutine();
    _ocrController.loadStock();
  }

  @override
  void dispose() {
    _p2pController.stopReceiver();
    _circadianController.dispose();
    _ocrController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routine = _circadianController.currentRoutine;
    final nextLunchTime = routine.formatTime(routine.lunch);
    final fastingTime = routine.formatTime(routine.fastingTime);
    final isHospital = routine.regimeType == CircadianRegimeType.hospital;
    final activeOmissionAlert = _adherenceController.getActiveAlert(routine);

    return Scaffold(
      backgroundColor: StandardTheme.surfaceLight,
      appBar: AppBar(
        title: Row(
          children: [
            const Text("⏰ ", style: TextStyle(fontSize: 20)),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                children: [
                  TextSpan(text: "Chrono"),
                  TextSpan(text: "Med", style: TextStyle(color: Color(0xFF2563EB))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFACC15),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: const Icon(Icons.elderly_rounded, size: 20),
            label: const Text("Modo Senior", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SeniorSingleActionScreen(
                    patientName: _patientName,
                    caregiverPin: _caregiverPin,
                    routine: routine,
                  ),
                ),
              ).then((_) => _loadData());
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu_book_rounded, color: Color(0xFF2563EB)),
            tooltip: 'Manual de Usuario',
            onPressed: () => context.push('/manual'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Color(0xFF64748B)),
            tooltip: 'Configuración',
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activeOmissionAlert != null) ...[
              EscalationAlertBanner(
                alert: activeOmissionAlert,
                onShareWhatsApp: () => _adherenceController.shareWhatsAppAlert(activeOmissionAlert),
                onMarkSupervised: () => _adherenceController.markDoseSupervised(context, activeOmissionAlert, _loadData),
              ),
              const SizedBox(height: 16),
            ],

            _buildPatientBanner(activeOmissionAlert != null, _computeNextDoseLabel(routine)),
            const SizedBox(height: 16),

            const AdherenceTimelineWidget(),
            const SizedBox(height: 20),

            CircadianRoutineCard(
              routine: routine,
              isHospital: isHospital,
              fastingTime: fastingTime,
              onUpdateRoutine: (r) => _circadianController.updateRoutine(context, r),
              onShowCustomRoutineDialog: () => _circadianController.showCustomRoutineDialog(context),
            ),
            const SizedBox(height: 20),

            const Text("Acciones Clínicas", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 12),
            _buildActionButtonsGrid(routine),
            const SizedBox(height: 24),

            ..._buildMedicationSection(routine),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientBanner(bool hasAlert, String nextDoseLabel) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_patientName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text("RUT: ${LocalStorageService.instance.patientRut}", style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasAlert ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  hasAlert ? "⚠️ Dosis Omitida" : "100% Adherencia",
                  style: TextStyle(
                    color: hasAlert ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text("Próxima toma programada:", style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(nextDoseLabel, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionButtonsGrid(CircadianRoutine routine) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildOutlinedButton(
                icon: Icons.picture_as_pdf_rounded,
                color: const Color(0xFF2563EB),
                label: "Reporte PDF",
                onPressed: () => _pdfController.showPdfOptionsDialog(
                  context,
                  patientName: _patientName,
                  patientRut: _patientRut,
                  routine: routine,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildOutlinedButton(
                icon: Icons.inventory_2_rounded,
                color: const Color(0xFF059669),
                label: "Botiquín / Caja",
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => const MedicineCabinetScreen()),
                  );
                  _loadData();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildOutlinedButton(
                icon: Icons.document_scanner_rounded,
                color: const Color(0xFF0284C7),
                label: "Escanear Receta",
                onPressed: () => _ocrController.openPrescriptionScanner(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildOutlinedButton(
                icon: Icons.qr_code_scanner_rounded,
                color: const Color(0xFF7C3AED),
                label: "Vincular QR",
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Escáner de vinculación listo")),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildOutlinedButton(
                icon: Icons.record_voice_over_rounded,
                color: const Color(0xFFDC2626),
                label: "Voz Familiar",
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => FamiliarVoiceRecorderDialog(
                      initialSlot: SeniorTimeSlot.lunch,
                      onVoiceUpdated: () => setState(() {}),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildOutlinedButton(
                icon: Icons.wifi_tethering_rounded,
                color: const Color(0xFF4338CA),
                label: "P2P Wi-Fi Local",
                onPressed: () => _p2pController.openSyncConfig(context, () => setState(() {})),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildOutlinedButton(
                icon: Icons.history_edu_rounded,
                color: const Color(0xFF0284C7),
                label: "Historial OCR & Trazabilidad",
                onPressed: () => _ocrController.openOcrHistory(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOutlinedButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      icon: Icon(icon, color: color),
      label: Text(label, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13)),
      onPressed: onPressed,
    );
  }

  /// Calcula la etiqueta "Próxima toma" basándose en la hora actual y la rutina circadiana.
  String _computeNextDoseLabel(CircadianRoutine routine) {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final cabinetItems = LocalStorageService.instance.getCabinetItems();

    if (cabinetItems.isEmpty) {
      return 'Sin medicamentos registrados';
    }

    // Mapeo de franjas horarias
    final slots = [
      {'time': routine.fastingTime, 'label': 'En ayunas'},
      {'time': routine.breakfast, 'label': 'Desayuno'},
      {'time': routine.lunch, 'label': 'Almuerzo'},
      {'time': routine.afternoon, 'label': 'Once'},
      {'time': routine.night, 'label': 'Noche'},
    ];

    // Encontrar la próxima franja horaria
    String nextTimeStr = '';
    for (final slot in slots) {
      final time = slot['time'] as TimeOfDay;
      final slotMinutes = time.hour * 60 + time.minute;
      if (slotMinutes > currentMinutes) {
        nextTimeStr = '${routine.formatTime(time)} • ${slot['label']}';
        break;
      }
    }

    if (nextTimeStr.isEmpty) {
      nextTimeStr = 'Mañana ${routine.formatTime(routine.fastingTime)} • En ayunas';
    }

    final firstMed = cabinetItems.first;
    return '$nextTimeStr — ${firstMed.name} (${firstMed.dosage})';
  }

  /// Genera la sección de medicamentos activos dinámicamente desde el botiquín.
  List<Widget> _buildMedicationSection(CircadianRoutine routine) {
    final cabinetItems = LocalStorageService.instance.getCabinetItems();
    final count = cabinetItems.length;

    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Medicamentos Activos (Chile)",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          Text(
            "$count ${count == 1 ? 'fármaco' : 'fármacos'}",
            style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (cabinetItems.isEmpty)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              const Icon(Icons.medication_rounded, size: 48, color: Color(0xFFCBD5E1)),
              const SizedBox(height: 8),
              const Text(
                'Sin medicamentos registrados',
                style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                'Escanea una caja o agrega uno manualmente desde el Botiquín.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ],
          ),
        )
      else
        ...cabinetItems.map((item) => ActiveMedicationCard(
          name: item.name,
          dose: item.dosage,
          schedule: '${item.stockUnits} un. restantes',
          pillColor: Color(item.pillColorValue),
          shapeType: item.shapeType,
          imprint: item.imprint,
          hasScoreLine: item.hasScoreLine,
          physicalDescription: item.physicalDescription,
          stock: '${item.stockUnits} un. restantes',
        )),
    ];
  }
}

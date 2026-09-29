import 'package:flutter/material.dart';
import '../../../core/theme/standard_theme.dart';
import '../../senior_mode/screens/senior_single_action_screen.dart';
import '../../schedule/models/circadian_routine.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../medicine_cabinet/screens/medicine_cabinet_screen.dart';
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
  final String _patientName = "Marcela";
  final String _patientRut = "14.567.890-K";
  final String _caregiverPin = "1234";

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
          const SizedBox(width: 12),
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

            _buildPatientBanner(activeOmissionAlert != null, nextLunchTime),
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Medicamentos Activos (Chile)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                Text("3 fármacos", style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            ActiveMedicationCard(
              name: "Eutirox (Levotiroxina)",
              dose: "100 mcg",
              schedule: "$fastingTime • En ayunas (30 min antes)",
              pillColor: Colors.white,
              shapeType: "small_round",
              imprint: "100",
              hasScoreLine: true,
              physicalDescription: "Comprimido blanco circular pequeño grabado '100' con ranura de partición",
              stock: "${_ocrController.eutiroxStock} un. restantes",
            ),
            ActiveMedicationCard(
              name: "Losartán Potásico",
              dose: "50 mg",
              schedule: "${routine.formatTime(routine.lunch)} • Con almuerzo",
              pillColor: const Color(0xFF3B82F6),
              shapeType: "round",
              imprint: "50",
              hasScoreLine: true,
              physicalDescription: "Comprimido circular azul grabado '50' con ranura central",
              stock: "${_ocrController.losartanStock} un. restantes",
            ),
            ActiveMedicationCard(
              name: "Atorvastatina",
              dose: "20 mg",
              schedule: "${routine.formatTime(routine.night)} • Al acostarse",
              pillColor: const Color(0xFFFACC15),
              shapeType: "oblong",
              imprint: "20",
              hasScoreLine: false,
              physicalDescription: "Comprimido oblongo amarillo grabado '20'",
              stock: "${_ocrController.atorvastatinaStock} un. restantes",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientBanner(bool hasAlert, String nextLunchTime) {
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
          Text("$nextLunchTime • Losartán Potásico (50 mg)", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
}

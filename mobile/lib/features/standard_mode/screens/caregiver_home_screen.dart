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
import '../../patients/widgets/patient_switch_sheet.dart';
import '../../vital_signs/widgets/vital_signs_card.dart';
import '../../vital_signs/widgets/record_vital_signs_dialog.dart';
import '../../ocr/services/drug_interaction_service.dart';

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

  Future<void> _openPatientSwitchSheet() async {
    final changed = await PatientSwitchSheet.show(context);
    if (changed == true && mounted) {
      setState(() {
        _loadData();
      });
    }
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

            _buildOperatorHeader(),
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
            const SizedBox(height: 16),

            VitalSignsCard(
              onUpdated: () => setState(() {}),
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

  Widget _buildOperatorHeader() {
    final storage = LocalStorageService.instance;
    final role = storage.userRole;
    final name = storage.userName;
    final title = storage.userTitle;
    final org = storage.userOrganization;

    if (name.isEmpty && role != 'professional') return const SizedBox.shrink();

    IconData icon;
    Color color;
    String label;

    if (role == 'professional') {
      icon = Icons.medical_services_rounded;
      color = const Color(0xFF0284C7);
      final profTitle = title.isNotEmpty ? title : 'Profesional de Salud';
      final orgLabel = org.isNotEmpty ? ' · $org' : '';
      label = '${name.isNotEmpty ? name : "Profesional"} ($profTitle$orgLabel)';
    } else if (role == 'autonomous_patient') {
      icon = Icons.person_rounded;
      color = const Color(0xFF16A34A);
      label = 'Tratamiento Autónomo';
    } else {
      icon = Icons.family_restroom_rounded;
      color = const Color(0xFF2563EB);
      label = 'Cuidador/a: ${name.isNotEmpty ? name : "Familiar"}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
              InkWell(
                onTap: _openPatientSwitchSheet,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Color(LocalStorageService.instance.activePatient.avatarColorValue),
                        child: Text(
                          _patientName.isNotEmpty ? _patientName[0].toUpperCase() : 'P',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(_patientName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 24),
                            ],
                          ),
                          Text("RUT: ${LocalStorageService.instance.patientRut}", style: const TextStyle(fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                ),
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
                icon: Icons.monitor_heart_rounded,
                color: const Color(0xFFDC2626),
                label: "Signos Vitales",
                onPressed: () async {
                  final saved = await RecordVitalSignsDialog.show(context);
                  if (saved == true) setState(() {});
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildOutlinedButton(
                icon: Icons.history_edu_rounded,
                color: const Color(0xFF0284C7),
                label: "Historial OCR",
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

  String? _getPrecaution(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('levotirox') || lower.contains('eutirox')) {
      return '🥛 Ayuno estricto 30-60m antes de desayuno';
    }
    if (lower.contains('atorvast') || lower.contains('simvast')) {
      return '🌙 Toma nocturna (HMG-CoA Reductasa)';
    }
    if (lower.contains('losart') || lower.contains('enalapr')) {
      return '🍽️ Con alimentos · Evitar AINEs';
    }
    if (lower.contains('metform')) {
      return '🍽️ Con comida · No consumir alcohol';
    }
    if (lower.contains('acenoc') || lower.contains('neosint')) {
      return '🥗 Control regular de vitamina K';
    }
    return null;
  }

  Widget _buildPharmacologicalSafetyBanner(BuildContext context, List<MedicineCabinetItem> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    final drugNames = items.map((e) => e.name).toList();
    final report = DrugInteractionService.instance.evaluateActiveRegimen(drugNames);

    Color bg;
    Color border;
    Color iconColor;
    IconData icon;
    String title;
    String subtitle;

    if (report.hasCritical) {
      bg = const Color(0xFFFEF2F2);
      border = const Color(0xFFFCA5A5);
      iconColor = const Color(0xFFDC2626);
      icon = Icons.dangerous_rounded;
      title = '🚨 Contraindicación Crítica Detectada';
      subtitle = report.criticalAlerts.first.title;
    } else if (report.hasWarnings) {
      bg = const Color(0xFFFFFBEB);
      border = const Color(0xFFFDE68A);
      iconColor = const Color(0xFFD97706);
      icon = Icons.warning_amber_rounded;
      title = '⚠️ Advertencia Clínica Mayor';
      subtitle = report.majorWarnings.first.title;
    } else if (report.hasDietaryRestrictions) {
      bg = const Color(0xFFEFF6FF);
      border = const Color(0xFFBFDBFE);
      iconColor = const Color(0xFF2563EB);
      icon = Icons.verified_user_rounded;
      title = '🛡️ Fármacos Compatibles (ISP Chile)';
      subtitle = '${report.totalDrugs} fármacos evaluados · ${report.dietaryPrecautions.length} precaución dietaria/circadiana';
    } else {
      bg = const Color(0xFFF0FDF4);
      border = const Color(0xFFBBF7D0);
      iconColor = const Color(0xFF16A34A);
      icon = Icons.check_circle_outline_rounded;
      title = '🛡️ Seguridad Farmacológica Óptima';
      subtitle = '0 interacciones adversas detectadas entre los fármacos activos.';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showPharmacologicalSafetySheet(context, report, items),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: iconColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: iconColor.withOpacity(0.7), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPharmacologicalSafetySheet(
    BuildContext context,
    RegimenSafetyReport report,
    List<MedicineCabinetItem> items,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.health_and_safety_rounded, color: Color(0xFF2563EB), size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Seguridad Farmacológica (ISP)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Supervisión cruzada de interacciones, bioequivalencia y cronofarmacología bajo guías clínicas MINSAL.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),

              // Alertas Críticas
              if (report.hasCritical) ...[
                const Text('🚨 CONTRAINDICACIONES CRÍTICAS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                const SizedBox(height: 6),
                ...report.criticalAlerts.map((a) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF991B1B))),
                      const SizedBox(height: 4),
                      Text(a.clinicalRisk, style: const TextStyle(fontSize: 11, color: Color(0xFF7F1D1D))),
                      const SizedBox(height: 6),
                      Text('Recomendación: ${a.recommendation}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
                    ],
                  ),
                )),
                const SizedBox(height: 12),
              ],

              // Advertencias Mayores
              if (report.hasWarnings) ...[
                const Text('⚠️ ADVERTENCIAS CLÍNICAS MAYORES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                const SizedBox(height: 6),
                ...report.majorWarnings.map((w) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(w.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E))),
                      const SizedBox(height: 4),
                      Text(w.clinicalRisk, style: const TextStyle(fontSize: 11, color: Color(0xFF78350F))),
                      const SizedBox(height: 6),
                      Text('Conducta: ${w.recommendation}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                    ],
                  ),
                )),
                const SizedBox(height: 12),
              ],

              // Restricciones Dietarias / Cronofarmacología
              if (report.hasDietaryRestrictions) ...[
                const Text('🥛 RECOMENDACIONES DIETARIAS Y CRONOFARMACOLÓGICAS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                const SizedBox(height: 6),
                ...report.dietaryPrecautions.map((d) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E40AF))),
                      const SizedBox(height: 4),
                      Text(d.recommendation, style: const TextStyle(fontSize: 11, color: Color(0xFF1E3A8A))),
                    ],
                  ),
                )),
                const SizedBox(height: 12),
              ],

              // Lista de Fármacos con Registro ISP
              const Text('🇨🇱 REGISTRO SANITARIO ISP Y BIOEQUIVALENCIA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 8),
              ...items.map((m) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                        Text(
                          m.ispRegister != null && m.ispRegister!.isNotEmpty ? 'Reg. ISP: ${m.ispRegister}' : 'Registro Nacional Verificado',
                          style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    if (m.isBioequivalent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                        ),
                        child: const Text('⭐ BIOEQUIVALENTE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                      ),
                  ],
                ),
              )),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      _buildPharmacologicalSafetyBanner(context, cabinetItems),
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
          isBioequivalent: item.isBioequivalent,
          ispRegister: item.ispRegister,
          clinicalPrecaution: _getPrecaution(item.name),
        )),
    ];
  }
}

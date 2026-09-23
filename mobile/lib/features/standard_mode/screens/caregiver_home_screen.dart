import 'package:flutter/material.dart';
import '../../../core/theme/standard_theme.dart';
import '../../senior_mode/screens/senior_single_action_screen.dart';
import '../../schedule/models/circadian_routine.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/storage/local_storage_service.dart';
import '../services/pdf_export_service.dart';
import '../models/dose_omission_model.dart';
import '../services/dose_omission_service.dart';
import '../../ocr/models/medicine_box_scan_result.dart';
import '../../ocr/widgets/medicine_box_scanner_dialog.dart';
import '../../senior_mode/widgets/physical_pill_widget.dart';

class CaregiverHomeScreen extends StatefulWidget {
  const CaregiverHomeScreen({super.key});

  @override
  State<CaregiverHomeScreen> createState() => _CaregiverHomeScreenState();
}

class _CaregiverHomeScreenState extends State<CaregiverHomeScreen> {
  final String _patientName = "Marcela";
  final String _patientRut = "14.567.890-K";
  final String _caregiverPin = "1234";
  CircadianRoutine _routine = CircadianRoutine.home;
  int _eutiroxStock = 28;
  int _losartanStock = 14;
  int _atorvastatinaStock = 30;

  @override
  void initState() {
    super.initState();
    _loadPersistedData();
  }

  void _loadPersistedData() {
    final storage = LocalStorageService.instance;
    setState(() {
      _eutiroxStock = storage.getStock('eutirox', fallback: 28);
      _losartanStock = storage.getStock('losartan', fallback: 14);
      _atorvastatinaStock = storage.getStock('atorvastatina', fallback: 30);
      _routine = storage.getCircadianRoutine();
    });
  }

  @override
  Widget build(BuildContext context) {
    final nextLunchTime = _routine.formatTime(_routine.lunch);
    final fastingTime = _routine.formatTime(_routine.fastingTime);
    final isHospital = _routine.regimeType == CircadianRegimeType.hospital;
    final activeOmissionAlert = DoseOmissionService.instance.getActiveEscalatedAlert(routine: _routine);

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
                    routine: _routine,
                  ),
                ),
              ).then((_) {
                _loadPersistedData();
              });
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
              _buildEscalationAlertBanner(activeOmissionAlert),
              const SizedBox(height: 16),
            ],

            // Banner Paciente
            Container(
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
                              const Text("RUT: 14.567.890-K", style: TextStyle(fontSize: 12, color: Colors.white70)),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: activeOmissionAlert != null ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          activeOmissionAlert != null ? "⚠️ Dosis Omitida" : "100% Adherencia",
                          style: TextStyle(
                            color: activeOmissionAlert != null ? Colors.white : Colors.black,
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
            ),
            const SizedBox(height: 20),

            // Card de Gestión de Régimen y Horarios Circadianos (4 Comidas)
            _buildCircadianRoutineCard(isHospital, fastingTime),
            const SizedBox(height: 20),

            // Acciones Rápidas
            const Text("Acciones Clínicas", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF2563EB)),
                    label: const Text("Reporte PDF", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: _showPdfOptionsDialog,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    icon: const Icon(Icons.inventory_2_rounded, color: Color(0xFF059669)),
                    label: const Text("Botiquín / Caja", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: _openMedicineBoxScanner,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    icon: const Icon(Icons.document_scanner_rounded, color: Color(0xFF0284C7)),
                    label: const Text("Escanear Receta", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Iniciando escáner OCR on-device para recetas...")),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF7C3AED)),
                    label: const Text("Vincular QR", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Escáner de vinculación listo")),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tratamiento Activo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Medicamentos Activos (Chile)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                Text("3 fármacos", style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            _buildMedCard(
              name: "Eutirox (Levotiroxina)",
              dose: "100 mcg",
              schedule: "$fastingTime • En ayunas (30 min antes)",
              pillColor: Colors.white,
              shapeType: "small_round",
              imprint: "100",
              hasScoreLine: true,
              physicalDescription: "Comprimido blanco circular pequeño grabado '100' con ranura de partición",
              stock: "$_eutiroxStock un. restantes",
            ),
            _buildMedCard(
              name: "Losartán Potásico",
              dose: "50 mg",
              schedule: "${_routine.formatTime(_routine.lunch)} • Con almuerzo",
              pillColor: const Color(0xFF3B82F6),
              shapeType: "round",
              imprint: "50",
              hasScoreLine: true,
              physicalDescription: "Comprimido circular azul grabado '50' con ranura central",
              stock: "$_losartanStock un. restantes",
            ),
            _buildMedCard(
              name: "Atorvastatina",
              dose: "20 mg",
              schedule: "${_routine.formatTime(_routine.night)} • Al acostarse",
              pillColor: const Color(0xFFFACC15),
              shapeType: "oblong",
              imprint: "20",
              hasScoreLine: false,
              physicalDescription: "Comprimido oblongo amarillo grabado '20'",
              stock: "$_atorvastatinaStock un. restantes",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircadianRoutineCard(bool isHospital, String fastingTime) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isHospital ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0), width: isHospital ? 2 : 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
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
                  const Icon(Icons.schedule_rounded, color: Color(0xFF2563EB), size: 20),
                  const SizedBox(width: 8),
                  const Text("Régimen de 4 Comidas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isHospital ? const Color(0xFFDBEAFE) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isHospital ? "🏥 Hospital / ELEAM" : "🏠 Domicilio",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isHospital ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Chips de selección de régimen
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text("🏠 Hogar", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  selected: _routine.regimeType == CircadianRegimeType.home,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _routine = CircadianRoutine.home);
                      LocalStorageService.instance.saveCircadianRoutine(_routine);
                    }
                  },
                  selectedColor: const Color(0xFF2563EB),
                  labelStyle: TextStyle(color: _routine.regimeType == CircadianRegimeType.home ? Colors.white : const Color(0xFF334155)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text("🏥 Hospital", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  selected: _routine.regimeType == CircadianRegimeType.hospital,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _routine = CircadianRoutine.hospital);
                      LocalStorageService.instance.saveCircadianRoutine(_routine);
                    }
                  },
                  selectedColor: const Color(0xFF2563EB),
                  labelStyle: TextStyle(color: _routine.regimeType == CircadianRegimeType.hospital ? Colors.white : const Color(0xFF334155)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text("⚙️ Ajustar", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  selected: _routine.regimeType == CircadianRegimeType.custom,
                  onSelected: (selected) => _showCustomRoutineDialog(),
                  selectedColor: const Color(0xFF2563EB),
                  labelStyle: TextStyle(color: _routine.regimeType == CircadianRegimeType.custom ? Colors.white : const Color(0xFF334155)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Fila con los 4 horarios de comida
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSlotItem("☀️", "Desayuno", _routine.formatTime(_routine.breakfast)),
                _buildSlotItem("🍲", "Almuerzo", _routine.formatTime(_routine.lunch)),
                _buildSlotItem("☕", "Once", _routine.formatTime(_routine.afternoon)),
                _buildSlotItem("🌙", "Noche", _routine.formatTime(_routine.night)),
              ],
            ),
          ),
          if (isHospital) ...[
            const SizedBox(height: 8),
            Text(
              "ℹ️ Régimen hospitalario: tomas adelantadas (Desayuno 07:00, Ayunas $fastingTime).",
              style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSlotItem(String emoji, String title, String time) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
        Text(time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF2563EB))),
      ],
    );
  }

  void _showCustomRoutineDialog() async {
    TimeOfDay breakfast = _routine.breakfast;
    TimeOfDay lunch = _routine.lunch;
    TimeOfDay afternoon = _routine.afternoon;
    TimeOfDay night = _routine.night;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Horarios Personalizados"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Text("☀️", style: TextStyle(fontSize: 24)),
                    title: const Text("Desayuno"),
                    trailing: TextButton(
                      child: Text(_routine.formatTime(breakfast), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onPressed: () async {
                        final picked = await showTimePicker(context: context, initialTime: breakfast);
                        if (picked != null) setDialogState(() => breakfast = picked);
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Text("🍲", style: TextStyle(fontSize: 24)),
                    title: const Text("Almuerzo"),
                    trailing: TextButton(
                      child: Text(_routine.formatTime(lunch), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onPressed: () async {
                        final picked = await showTimePicker(context: context, initialTime: lunch);
                        if (picked != null) setDialogState(() => lunch = picked);
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Text("☕", style: TextStyle(fontSize: 24)),
                    title: const Text("Once"),
                    trailing: TextButton(
                      child: Text(_routine.formatTime(afternoon), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onPressed: () async {
                        final picked = await showTimePicker(context: context, initialTime: afternoon);
                        if (picked != null) setDialogState(() => afternoon = picked);
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Text("🌙", style: TextStyle(fontSize: 24)),
                    title: const Text("Noche"),
                    trailing: TextButton(
                      child: Text(_routine.formatTime(night), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onPressed: () async {
                        final picked = await showTimePicker(context: context, initialTime: night);
                        if (picked != null) setDialogState(() => night = picked);
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR")),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _routine = _routine.copyWith(
                      regimeType: CircadianRegimeType.custom,
                      breakfast: breakfast,
                      lunch: lunch,
                      afternoon: afternoon,
                      night: night,
                    );
                  });
                  LocalStorageService.instance.saveCircadianRoutine(_routine);
                  Navigator.pop(ctx);
                },
                child: const Text("GUARDAR"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPdfOptionsDialog() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF2563EB), size: 24),
            SizedBox(width: 8),
            Text("Informe Médico PDF", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Documento clínico certificado bajo Ley N° 20.584 y Ley N° 19.628, con sello de integridad criptográfica HMAC-SHA256.",
              style: TextStyle(fontSize: 12, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Paciente: $_patientName (RUT: $_patientRut)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  const Text("Cumplimiento: 100% (Óptima)", style: TextStyle(fontSize: 12, color: Color(0xFF047857), fontWeight: FontWeight.w600)),
                  Text("Régimen: ${_routine.regimeType == CircadianRegimeType.hospital ? 'Hospitalario / ELEAM' : 'Domicilio'}", style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final report = await PdfExportService.generateClinicalSummaryText(
                patientName: _patientName,
                patientRut: _patientRut,
                adherencePercentage: 1.0,
                totalDoses: 3,
                onTimeDoses: 3,
              );
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (previewCtx) => AlertDialog(
                    title: const Text("Previsualización de Informe"),
                    content: SingleChildScrollView(child: Text(report, style: const TextStyle(fontFamily: 'monospace', fontSize: 11))),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(previewCtx), child: const Text("CERRAR")),
                    ],
                  ),
                );
              }
            },
            child: const Text("VER TEXTO", style: TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text("COMPARTIR / WHATSAPP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            onPressed: () async {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Generando documento PDF certificado con firma HMAC...")),
              );
              try {
                await PdfExportService.exportAndShareToWhatsApp(
                  patientName: _patientName,
                  patientRut: _patientRut,
                  adherencePercentage: 1.0,
                  totalDoses: 3,
                  onTimeDoses: 3,
                  routine: _routine,
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(backgroundColor: Colors.red, content: Text("Error al generar PDF: $e")),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _openMedicineBoxScanner() {
    showDialog(
      context: context,
      builder: (ctx) => MedicineBoxScannerDialog(
        onStockUpdated: _handleBoxStockUpdated,
      ),
    );
  }

  void _handleBoxStockUpdated(MedicineBoxScanResult result) {
    final drug = result.detectedDrugName?.toLowerCase() ?? '';
    final units = result.detectedUnits ?? 30;

    setState(() {
      if (drug.contains('losart')) {
        _losartanStock += units;
        LocalStorageService.instance.setStock('losartan', _losartanStock);
      } else if (drug.contains('eutirox') || drug.contains('levotiroxina')) {
        _eutiroxStock += units;
        LocalStorageService.instance.setStock('eutirox', _eutiroxStock);
      } else if (drug.contains('atorvastatina')) {
        _atorvastatinaStock += units;
        LocalStorageService.instance.setStock('atorvastatina', _atorvastatinaStock);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F172A),
        content: Text(
          '📦 Botiquín actualizado: +$units un. de ${result.detectedDrugName ?? "fármaco"} (Lote: ${result.detectedLotNumber ?? "N/A"}, Vence: ${result.detectedExpirationDate ?? "N/A"})',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildMedCard({
    required String name,
    required String dose,
    required String schedule,
    required Color pillColor,
    required String shapeType,
    required String imprint,
    required bool hasScoreLine,
    required String physicalDescription,
    required String stock,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          PhysicalPillWidget(
            size: 38,
            shapeType: shapeType,
            pillColor: pillColor,
            imprint: imprint,
            hasScoreLine: hasScoreLine,
            medicationName: name,
            dosage: dose,
            physicalDescription: physicalDescription,
            enableMagnifier: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text("$dose • $schedule", style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
              ],
            ),
          ),
          Text(stock, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF047857))),
        ],
      ),
    );
  }

  Widget _buildEscalationAlertBanner(DoseOmissionAlert alert) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEF4444), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚠️ ¡ALERTA DE DOSIS OMITIDA!',
                      style: TextStyle(
                        color: Color(0xFF991B1B),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${alert.patientName} lleva ${alert.minutesOverdue} min sin confirmar su toma',
                      style: const TextStyle(
                        color: Color(0xFF7F1D1D),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${alert.minutesOverdue}m',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Dosis programada: ${alert.drugName} (${alert.dosage}) a las ${alert.scheduledTimeStr}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Transcurrieron más de 45 min sin confirmación. Se ha activado el protocolo de escalada clínica.',
            style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Avisar WhatsApp', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () => _shareWhatsAppAlert(alert),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('Supervisar Toma', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () => _markDoseSupervised(alert),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _shareWhatsAppAlert(DoseOmissionAlert alert) {
    final message = DoseOmissionService.instance.generateWhatsAppAlertMessage(alert);
    Share.share(message, subject: 'Alerta Médica de Adherencia - ${alert.patientName}');
  }

  void _markDoseSupervised(DoseOmissionAlert alert) async {
    await DoseOmissionService.instance.markDoseAsAdministeredByCaregiver(alert);
    _loadPersistedData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F172A),
          content: Text(
            '✅ Dosis de ${alert.drugName} registrada como supervisada por el cuidador.',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }
}

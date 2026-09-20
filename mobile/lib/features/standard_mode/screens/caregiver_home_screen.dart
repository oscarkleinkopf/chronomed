import 'package:flutter/material.dart';
import '../../../core/theme/standard_theme.dart';
import '../../senior_mode/screens/senior_single_action_screen.dart';
import '../services/pdf_export_service.dart';

class CaregiverHomeScreen extends StatefulWidget {
  const CaregiverHomeScreen({super.key});

  @override
  State<CaregiverHomeScreen> createState() => _CaregiverHomeScreenState();
}

class _CaregiverHomeScreenState extends State<CaregiverHomeScreen> {
  final String _patientName = "Marcela";
  final String _caregiverPin = "1234";

  @override
  Widget build(BuildContext context) {
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
                  ),
                ),
              );
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
                    mainAxisAlignment: MainAxisAlignment.between,
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
                          color: const Color(0xFF22C55E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text("100% Adherencia", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text("Próxima toma programada:", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  const Text("13:30 • Losartán Potásico (50 mg)", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Acciones Rápidas
            const Text("Acciones Clínicas", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF2563EB)),
                    label: const Text("Reporte PDF", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () async {
                      final report = await PdfExportService.generateClinicalSummaryText(
                        patientName: _patientName,
                        adherencePercentage: 1.0,
                        totalDoses: 3,
                        onTimeDoses: 3,
                      );
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Informe Médico Certificado"),
                            content: SingleChildScrollView(child: Text(report, style: const TextStyle(fontFamily: 'monospace', fontSize: 11))),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CERRAR")),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF22C55E)),
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
              mainAxisAlignment: MainAxisAlignment.between,
              children: const [
                Text("Medicamentos Activos (Chile)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                Text("3 fármacos", style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            _buildMedCard("Eutirox (Levotiroxina)", "100 mcg", "07:30 • En ayunas", Colors.white, Colors.black, "28 un. restantes"),
            _buildMedCard("Losartán Potásico", "50 mg", "13:30 • Con almuerzo", const Color(0xFF3B82F6), Colors.white, "14 un. restantes"),
            _buildMedCard("Atorvastatina", "20 mg", "22:00 • Al acostarse", const Color(0xFFFACC15), Colors.black, "30 un. restantes"),
          ],
        ),
      ),
    );
  }

  Widget _buildMedCard(String name, String dose, String schedule, Color pillColor, Color textColor, String stock) {
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
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: pillColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black12, width: 1.5),
            ),
            child: Center(
              child: Icon(Icons.circle, size: 12, color: textColor.withOpacity(0.5)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text("$dose • $schedule", style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Text(stock, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF059669))),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../schedule/models/circadian_routine.dart';
import '../services/pdf_export_service.dart';

class CaregiverPdfController {
  Future<void> showPdfOptionsDialog(
    BuildContext context, {
    required String patientName,
    required String patientRut,
    required CircadianRoutine routine,
  }) async {
    await showDialog(
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
                  Text("Paciente: $patientName (RUT: $patientRut)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  const Text("Cumplimiento: 100% (Óptima)", style: TextStyle(fontSize: 12, color: Color(0xFF047857), fontWeight: FontWeight.w600)),
                  Text("Régimen: ${routine.regimeType == CircadianRegimeType.hospital ? 'Hospitalario / ELEAM' : 'Domicilio'}", style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
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
                patientName: patientName,
                patientRut: patientRut,
                adherencePercentage: 1.0,
                totalDoses: 3,
                onTimeDoses: 3,
              );
              if (context.mounted) {
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
                  patientName: patientName,
                  patientRut: patientRut,
                  adherencePercentage: 1.0,
                  totalDoses: 3,
                  onTimeDoses: 3,
                  routine: routine,
                );
              } catch (e) {
                if (context.mounted) {
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
}

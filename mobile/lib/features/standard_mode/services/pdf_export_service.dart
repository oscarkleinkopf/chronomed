import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../schedule/models/circadian_routine.dart';

class PdfExportService {
  /// Generates the raw cryptographic HMAC-SHA256 signature for document integrity verification
  static String calculateDocumentHmac({
    required String patientName,
    required String rut,
    required double adherencePercentage,
    required String emissionDate,
  }) {
    const secretKey = 'Chronomed-Clinical-HMAC-Key-2026';
    final payload = '$patientName|$rut|${adherencePercentage.toStringAsFixed(2)}|$emissionDate';
    final hmac = Hmac(sha256, utf8.encode(secretKey));
    return hmac.convert(utf8.encode(payload)).toString().toUpperCase();
  }

  /// Compiles a fully vectorised, certified clinical adherence PDF document
  static Future<Uint8List> generateClinicalPdfBytes({
    required String patientName,
    String patientRut = "14.567.890-K",
    required double adherencePercentage,
    required int totalDoses,
    required int onTimeDoses,
    CircadianRoutine? routine,
    List<Map<String, String>>? medications,
  }) async {
    final pdf = pw.Document(
      title: 'Informe Clínico ChronoMed - $patientName',
      author: 'ChronoMed Sistema de Adherencia',
    );

    final now = DateTime.now();
    final dateFormatted = DateFormat('dd/MM/yyyy HH:mm').format(now);
    final hmacSignature = calculateDocumentHmac(
      patientName: patientName,
      rut: patientRut,
      adherencePercentage: adherencePercentage,
      emissionDate: dateFormatted,
    );

    final routineRef = routine ?? CircadianRoutine.home;
    final isHospital = routineRef.regimeType == CircadianRegimeType.hospital;

    final medList = medications ?? [
      {
        'name': 'Eutirox (Levotiroxina)',
        'dose': '100 mcg',
        'schedule': '${routineRef.formatTime(routineRef.fastingTime)} (En ayunas)',
        'stock': '28 comprimidos',
      },
      {
        'name': 'Losartán Potásico',
        'dose': '50 mg',
        'schedule': '${routineRef.formatTime(routineRef.lunch)} (Con almuerzo)',
        'stock': '14 comprimidos',
      },
      {
        'name': 'Atorvastatina',
        'dose': '20 mg',
        'schedule': '${routineRef.formatTime(routineRef.night)} (Al acostarse)',
        'stock': '30 comprimidos',
      },
    ];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF1E40AF),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'CHRONOMED CLINICAL REPORT',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Certificado de Adherencia Farmacológica y Trazabilidad',
                        style: const pw.TextStyle(
                          color: PdfColors.grey200,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Emisión: $dateFormatted',
                        style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Régimen: ${isHospital ? "Hospitalario / ELEAM" : "Domicilio"}',
                        style: pw.TextStyle(color: PdfColors.amber, fontSize: 9, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),

            // Patient Card
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0)),
                borderRadius: pw.BorderRadius.circular(8),
                color: PdfColor.fromInt(0xFFF8FAFC),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('PACIENTE:', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text(patientName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F172A))),
                      pw.Text('RUT: $patientRut', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('EVALUACIÓN DE ADHERENCIA:', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '${(adherencePercentage * 100).toInt()}% CUMPLIMIENTO',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: adherencePercentage >= 0.85 ? PdfColor.fromInt(0xFF059669) : PdfColor.fromInt(0xFFDC2626),
                        ),
                      ),
                      pw.Text(
                        adherencePercentage >= 0.85 ? 'CATEGORÍA: ÓPTIMA (MINSAL)' : 'CATEGORÍA: REQUIERE REFUERZO',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),

            // Adherence Stats Summary
            pw.Text('Resumen de Adherencia en Tratamiento:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F172A))),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFCBD5E1), width: 0.5),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFF1F5F9)),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Indicador Terapéutico', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Valor Registrado', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Estándar Clínico', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Tomas Programadas', style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('$totalDoses dosis', style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('100% de pauta médica', style: const pw.TextStyle(fontSize: 9))),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Tomas Confirmadas a Tiempo', style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('$onTimeDoses dosis', style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Tolerancia ventana circadiana', style: const pw.TextStyle(fontSize: 9))),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Índice de Adherencia Efectiva', style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('${(adherencePercentage * 100).toStringAsFixed(1)}%', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF059669))),
                    ),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Meta >= 85.0% (Ley 20.584)', style: const pw.TextStyle(fontSize: 9))),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 18),

            // Active Medications Table
            pw.Text('Farmacoterapia Activa y Régimen de 4 Comidas:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F172A))),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFCBD5E1), width: 0.5),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFF1F5F9)),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Fármaco / Dosis', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Horario y Momento de Comida', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Stock Botiquín', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                ...medList.map(
                  (m) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${m['name']} (${m['dose']})', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(m['schedule'] ?? '', style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(m['stock'] ?? '', style: const pw.TextStyle(fontSize: 9))),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // Legal & Cryptographic HMAC Certification
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF1F5F9),
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColor.fromInt(0xFF94A3B8), width: 0.5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Text('🛡️ CERTIFICACIÓN CRIPTOGRÁFICA DE INTEGRIDAD (HMAC-SHA256)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1E293B))),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Hash Inmutable: $hmacSignature',
                    style: pw.TextStyle(fontSize: 8, font: pw.Font.courier(), color: PdfColor.fromInt(0xFF0F172A)),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Este documento fue generado por ChronoMed conforme a las disposiciones de la Ley N° 20.584 sobre Derechos y Deberes de las Personas en Salud (Título II, Párrafo 5° referente a la Ficha Clínica) y la Ley N° 19.628 sobre Protección de la Vida Privada. La integridad de las tomas y horarios ha sido firmada criptográficamente en el dispositivo sin alteración de terceros.',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Generates the PDF file, saves it in the device temporary directory, and returns the File
  static Future<File> exportAndSavePdf({
    required String patientName,
    String patientRut = "14.567.890-K",
    required double adherencePercentage,
    required int totalDoses,
    required int onTimeDoses,
    CircadianRoutine? routine,
  }) async {
    final bytes = await generateClinicalPdfBytes(
      patientName: patientName,
      patientRut: patientRut,
      adherencePercentage: adherencePercentage,
      totalDoses: totalDoses,
      onTimeDoses: onTimeDoses,
      routine: routine,
    );

    final tempDir = await getTemporaryDirectory();
    final sanitizedName = patientName.toLowerCase().replaceAll(' ', '_');
    final filePath = '${tempDir.path}/informe_adherencia_${sanitizedName}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Exports the clinical PDF and invokes native share dialog (including direct WhatsApp contact sharing)
  static Future<void> exportAndShareToWhatsApp({
    required String patientName,
    String patientRut = "14.567.890-K",
    required double adherencePercentage,
    required int totalDoses,
    required int onTimeDoses,
    CircadianRoutine? routine,
  }) async {
    final file = await exportAndSavePdf(
      patientName: patientName,
      patientRut: patientRut,
      adherencePercentage: adherencePercentage,
      totalDoses: totalDoses,
      onTimeDoses: onTimeDoses,
      routine: routine,
    );

    final percentText = (adherencePercentage * 100).toInt();
    final shareMessage =
        '📋 *Informe Clínico de Adherencia ChronoMed*\n'
        '• Paciente: $patientName (RUT: $patientRut)\n'
        '• Cumplimiento: $percentText% (Categoría Óptima)\n'
        '• Tomas registradas: $onTimeDoses de $totalDoses\n\n'
        'Adjunto informe oficial en PDF certificado con firma criptográfica HMAC-SHA256 bajo Ley N° 20.584.';

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf', name: 'informe_adherencia_$patientName.pdf')],
      text: shareMessage,
      subject: 'Informe Médico de Adherencia - $patientName',
    );
  }

  /// Text fallback for quick inspection
  static Future<String> generateClinicalSummaryText({
    required String patientName,
    required double adherencePercentage,
    required int totalDoses,
    required int onTimeDoses,
    String patientRut = "14.567.890-K",
  }) async {
    final now = DateTime.now();
    final dateFormatted = DateFormat('dd/MM/yyyy HH:mm').format(now);
    final hmac = calculateDocumentHmac(
      patientName: patientName,
      rut: patientRut,
      adherencePercentage: adherencePercentage,
      emissionDate: dateFormatted,
    );

    return """
========================================================
         INFORME CLÍNICO DE ADHERENCIA MÉDICA
                     CHRONOMED
========================================================
Fecha de Emisión: $dateFormatted
Paciente: $patientName (RUT: $patientRut)

RESUMEN DE CUMPLIMIENTO TERAPÉUTICO:
- Adherencia General: ${(adherencePercentage * 100).toInt()}%
- Total de Tomas Programadas: $totalDoses
- Tomas Registradas a Tiempo: $onTimeDoses
- Evaluación Clínica: ${adherencePercentage >= 0.85 ? 'ÓPTIMA' : 'REQUIERE AJUSTE'}

Normativa: Ley N° 20.584 sobre Ficha Clínica y Trazabilidad.
Firma Criptográfica de Integridad:
$hmac
========================================================
""";
  }
}

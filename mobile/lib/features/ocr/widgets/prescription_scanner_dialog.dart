import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/prescription_scan_result.dart';
import '../services/prescription_parser_service.dart';
import '../services/drug_interaction_service.dart';

class PrescriptionScannerDialog extends StatefulWidget {
  final List<String> activeMedications;
  final Function(PrescriptionScanResult) onPrescriptionAccepted;

  const PrescriptionScannerDialog({
    super.key,
    required this.activeMedications,
    required this.onPrescriptionAccepted,
  });

  @override
  State<PrescriptionScannerDialog> createState() => _PrescriptionScannerDialogState();
}

class _PrescriptionScannerDialogState extends State<PrescriptionScannerDialog> {
  final PrescriptionParserService _parserService = PrescriptionParserService();
  final DrugInteractionService _interactionService = DrugInteractionService.instance;
  final TextEditingController _textController = TextEditingController();

  PrescriptionScanResult? _scanResult;
  DrugInteractionResult? _interactionResult;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Ejemplo de receta médica chilena habitual
    _textController.text = '''DR. ALEJANDRO SILVA - MEDICINA GENERAL
RP: PARACETAMOL 500 mg
Tomar 1 comprimido cada 8 horas por 5 días con alimentos en caso de dolor o fiebre.''';
    _analyzeText(_textController.text);
  }

  @override
  void dispose() {
    _parserService.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _analyzeText(String text) {
    setState(() => _isProcessing = true);

    final result = _parserService.parseRawText(text);
    DrugInteractionResult? interaction;

    if (result.detectedDrugName != null) {
      interaction = _interactionService.evaluateCandidate(
        result.detectedDrugName!,
        widget.activeMedications,
      );
    }

    setState(() {
      _scanResult = result;
      _interactionResult = interaction;
      _isProcessing = false;
    });

    // Haptic feedback diferenciado según resultado de interacción
    if (interaction != null) {
      if (interaction.isBlocking) {
        // Vibración fuerte para contraindicación bloqueante
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 150), () {
          HapticFeedback.heavyImpact();
        });
      } else if (interaction.severity == InteractionSeverity.majorWarning) {
        // Vibración media para advertencia mayor
        HapticFeedback.mediumImpact();
      } else {
        // Pulso ligero para escaneo seguro
        HapticFeedback.lightImpact();
      }
    }
  }

  void _setPreset(String text) {
    _textController.text = text;
    _analyzeText(text);
  }

  @override
  Widget build(BuildContext context) {
    final canAccept = _scanResult != null &&
        _scanResult!.detectedDrugName != null &&
        !(_interactionResult?.isBlocking ?? false);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.document_scanner_rounded, color: Color(0xFF0284C7), size: 26),
                      SizedBox(width: 8),
                      Text(
                        'Escáner de Receta Médica',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'OCR on-device y cruce automático de contraindicaciones clínicas:',
                style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 12),

              // Presets para demostración y validación rápida
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  ActionChip(
                    label: const Text('Paracetamol (Seguro)', style: TextStyle(fontSize: 11)),
                    onPressed: () => _setPreset('RP: PARACETAMOL 500 mg CADA 8 HORAS'),
                  ),
                  ActionChip(
                    label: const Text('Ibuprofeno (Alerta)', style: TextStyle(fontSize: 11, color: Color(0xFFDC2626))),
                    onPressed: () => _setPreset('RP: IBUPROFENO 600 mg CADA 8 HORAS'),
                  ),
                  ActionChip(
                    label: const Text('Claritromicina (Crítica)', style: TextStyle(fontSize: 11, color: Color(0xFFDC2626))),
                    onPressed: () => _setPreset('RP: CLARITROMICINA 500 mg CADA 12 HORAS'),
                  ),
                  ActionChip(
                    label: const Text('Eutirox (Ayunas)', style: TextStyle(fontSize: 11, color: Color(0xFFD97706))),
                    onPressed: () => _setPreset('RP: EUTIROX 100 mcg EN AYUNAS ANTES DEL DESAYUNO'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Caja de texto OCR
              TextField(
                controller: _textController,
                maxLines: 4,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Texto extraído o escaneado de la receta',
                  labelStyle: const TextStyle(color: Color(0xFF475569)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0284C7)),
                    tooltip: 'Reanalizar texto',
                    onPressed: () => _analyzeText(_textController.text),
                  ),
                ),
                onChanged: _analyzeText,
              ),
              const SizedBox(height: 14),

              if (_isProcessing)
                const Center(child: CircularProgressIndicator())
              else if (_scanResult != null) ...[
                _buildParsedDetailsCard(_scanResult!),
                const SizedBox(height: 12),
                if (_interactionResult != null) _buildInteractionAlertCard(_interactionResult!),
              ],

              const SizedBox(height: 20),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCELAR'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: canAccept ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: canAccept
                          ? () {
                              widget.onPrescriptionAccepted(_scanResult!);
                              Navigator.pop(context);
                            }
                          : null,
                      child: const Text('INCORPORAR AL TRATAMIENTO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParsedDetailsCard(PrescriptionScanResult result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                result.detectedDrugName ?? 'Fármaco No Reconocido',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              if (result.detectedDosage != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    result.detectedDosage!,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                'Frecuencia: Cada ${result.detectedFrequencyHours ?? 8} horas',
                style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.restaurant_rounded, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                result.detectedMealRelation == 'FASTING'
                    ? 'En ayunas'
                    : result.detectedMealRelation == 'WITH_MEAL'
                        ? 'Con alimentos'
                        : 'Horario normal',
                style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionAlertCard(DrugInteractionResult interaction) {
    Color bg;
    Color border;
    Color titleColor;
    IconData icon;

    switch (interaction.severity) {
      case InteractionSeverity.criticalContraindication:
        bg = const Color(0xFFFEF2F2);
        border = const Color(0xFFFCA5A5);
        titleColor = const Color(0xFFB91C1C);
        icon = Icons.dangerous_rounded;
        break;
      case InteractionSeverity.majorWarning:
        bg = const Color(0xFFFFFBEB);
        border = const Color(0xFFFCD34D);
        titleColor = const Color(0xFFB45309);
        icon = Icons.warning_amber_rounded;
        break;
      case InteractionSeverity.foodRestriction:
        bg = const Color(0xFFF0FDF4);
        border = const Color(0xFF86EFAC);
        titleColor = const Color(0xFF15803D);
        icon = Icons.info_outline_rounded;
        break;
      case InteractionSeverity.none:
        bg = const Color(0xFFF0FDF4);
        border = const Color(0xFF86EFAC);
        titleColor = const Color(0xFF15803D);
        icon = Icons.check_circle_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: titleColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  interaction.title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: titleColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            interaction.clinicalRisk,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          Text(
            interaction.recommendation,
            style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }
}

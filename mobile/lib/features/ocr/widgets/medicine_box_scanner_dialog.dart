import 'package:flutter/material.dart';
import '../models/medicine_box_scan_result.dart';
import '../services/medicine_box_scanner_service.dart';

class MedicineBoxScannerDialog extends StatefulWidget {
  final Function(MedicineBoxScanResult) onStockUpdated;

  const MedicineBoxScannerDialog({
    super.key,
    required this.onStockUpdated,
  });

  @override
  State<MedicineBoxScannerDialog> createState() => _MedicineBoxScannerDialogState();
}

class _MedicineBoxScannerDialogState extends State<MedicineBoxScannerDialog> {
  final MedicineBoxScannerService _scannerService = MedicineBoxScannerService();
  final TextEditingController _textController = TextEditingController();
  MedicineBoxScanResult? _scanResult;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Default sample Chilean box text for instant trial
    _textController.text = '''LABORATORIO CHILE
LOSARTAN POTASICO 50 mg
30 comprimidos recubiertos
LOTE: 24A09
VENCE: 12/2028''';
    _analyzeText(_textController.text);
  }

  @override
  void dispose() {
    _scannerService.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _analyzeText(String text) {
    setState(() {
      _isProcessing = true;
    });

    final result = _scannerService.parseRawText(text);

    setState(() {
      _scanResult = result;
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.inventory_2_rounded, color: Color(0xFF2563EB), size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Escaneo de Botiquín',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  IconButton(
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF334155)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Reconocimiento OCR on-device para cajas físicas y blísteres de fármacos (ISP Chile):',
                style: TextStyle(fontSize: 12, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _textController,
                maxLines: 4,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Texto extraído o escaneado de la caja',
                  labelStyle: const TextStyle(color: Color(0xFF334155)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2563EB)),
                    tooltip: 'Reanalizar texto',
                    onPressed: () => _analyzeText(_textController.text),
                  ),
                ),
                onChanged: _analyzeText,
              ),
              const SizedBox(height: 16),
              if (_isProcessing)
                const Center(child: CircularProgressIndicator())
              else if (_scanResult != null)
                _buildScanResultCard(_scanResult!),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCELAR', style: TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _scanResult != null && _scanResult!.detectedDrugName != null
                          ? () {
                              widget.onStockUpdated(_scanResult!);
                              Navigator.pop(context);
                            }
                          : null,
                      child: const Text('INGRESAR STOCK', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildScanResultCard(MedicineBoxScanResult result) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.detectedDrugName ?? 'Fármaco No Identificado',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      result.detectedDosage != null ? 'Concentración: ${result.detectedDosage}' : 'Dosis: No especificada',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                  ],
                ),
              ),
              if (result.detectedUnits != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '+${result.detectedUnits} un.',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                  ),
                ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFCBD5E1)),
          // Lot & Expiration status row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                result.detectedLotNumber != null ? 'Lote: ${result.detectedLotNumber}' : 'Lote: No detectado',
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFF334155)),
              ),
              Text(
                result.detectedExpirationDate != null ? 'Vence: ${result.detectedExpirationDate}' : 'Vencimiento: ?',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Expiration risk badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: result.statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: result.statusColor, width: 1.5),
            ),
            child: Row(
              children: [
                Text(result.statusEmoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: result.statusColor,
                    ),
                  ),
                ),
                if (result.daysRemaining != null)
                  Text(
                    result.daysRemaining! >= 0 ? '${result.daysRemaining} días' : 'Expiró',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: result.statusColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

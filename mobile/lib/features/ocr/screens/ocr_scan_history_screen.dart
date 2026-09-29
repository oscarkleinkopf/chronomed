import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ocr_scan_history_entry.dart';
import '../../../core/services/ocr_history_service.dart';

class OcrScanHistoryScreen extends StatefulWidget {
  const OcrScanHistoryScreen({super.key});

  @override
  State<OcrScanHistoryScreen> createState() => _OcrScanHistoryScreenState();
}

class _OcrScanHistoryScreenState extends State<OcrScanHistoryScreen> {
  int _selectedFilterIndex = 0; // 0: Todos, 1: Cajas, 2: Recetas, 3: Con Alertas

  List<OcrScanHistoryEntry> _getFilteredEntries() {
    final service = OcrHistoryService.instance;
    switch (_selectedFilterIndex) {
      case 1:
        return service.getEntries(filterType: OcrScanType.medicineBox);
      case 2:
        return service.getEntries(filterType: OcrScanType.prescription);
      case 3:
        return service.getEntries(onlyWithInteractions: true);
      default:
        return service.allEntries;
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _getFilteredEntries();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Historial de Escaneos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            Text(
              'Registro y Trazabilidad de Cajas y Recetas',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(0, 'Todos (${OcrHistoryService.instance.allEntries.length})'),
                  const SizedBox(width: 8),
                  _buildFilterChip(1, '📦 Cajas'),
                  const SizedBox(width: 8),
                  _buildFilterChip(2, '📋 Recetas'),
                  const SizedBox(width: 8),
                  _buildFilterChip(3, '⚠️ Con Interacciones'),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Entries list
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.document_scanner_outlined, size: 56, color: Color(0xFF94A3B8)),
                        SizedBox(height: 12),
                        Text(
                          'No hay escaneos en esta categoría',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Los escaneos de cajas y recetas aparecerán aquí automáticamente.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: entries.length,
                    itemBuilder: (ctx, index) {
                      final entry = entries[index];
                      return _buildHistoryCard(entry);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFFEFF6FF),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF475569),
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
      ),
      onSelected: (_) => setState(() => _selectedFilterIndex = index),
    );
  }

  Widget _buildHistoryCard(OcrScanHistoryEntry entry) {
    final isBox = entry.scanType == OcrScanType.medicineBox;
    final dateFormatted = DateFormat('dd/MM/yyyy • HH:mm').format(entry.scannedAt);
    final hasInteractions = entry.interactionsDetected.isNotEmpty;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: hasInteractions ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
          width: hasInteractions ? 1.5 : 1,
        ),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Type icon + Type label + Date + Delete
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isBox ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDF4),
                        shape: BoxShape.circle,
                      ),
                      child: Text(isBox ? '📦' : '📋', style: const TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBox ? 'Caja de Medicamento' : 'Receta Médica',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          dateFormatted,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: entry.wasAccepted ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        entry.wasAccepted ? 'Incorporado ✓' : 'Descartado ✗',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: entry.wasAccepted ? const Color(0xFF166534) : const Color(0xFF991B1B),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
                      tooltip: 'Eliminar del historial',
                      onPressed: () async {
                        await OcrHistoryService.instance.deleteEntry(entry.id);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 16),

            // Drug details
            Text(
              entry.medicineName ?? 'Fármaco no identificado',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            if (entry.dosage != null && entry.dosage!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Dosis: ${entry.dosage}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
              ),
            ],
            const SizedBox(height: 8),

            // Badges
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (entry.isBioequivalent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: const Text(
                      '⭐ BIOEQUIVALENTE ISP',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                    ),
                  ),
                if (entry.ispRegister != null && entry.ispRegister!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Text(
                      'Reg. ISP: ${entry.ispRegister}',
                      style: const TextStyle(fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                  ),
              ],
            ),

            // Interactions warnings
            if (hasInteractions) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFDC2626)),
                        SizedBox(width: 6),
                        Text(
                          'Interacciones Clínicas Detectadas:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...entry.interactionsDetected.map(
                      (inter) => Padding(
                        padding: const EdgeInsets.only(left: 6, top: 2),
                        child: Text(
                          '• $inter',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF7F1D1D)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Expandable raw OCR text
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: const Text(
                  'Ver texto OCR crudo',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      entry.extractedText.isEmpty ? '(Sin texto detectado)' : entry.extractedText,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

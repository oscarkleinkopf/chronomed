import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/storage/local_storage_service.dart';
import '../models/vital_sign_entry.dart';
import 'record_vital_signs_dialog.dart';

class VitalSignsHistorySheet extends StatefulWidget {
  const VitalSignsHistorySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const VitalSignsHistorySheet(),
    );
  }

  @override
  State<VitalSignsHistorySheet> createState() => _VitalSignsHistorySheetState();
}

class _VitalSignsHistorySheetState extends State<VitalSignsHistorySheet> {
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  void _reload() {
    setState(() {});
  }

  Future<void> _deleteEntry(VitalSignEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar registro?'),
        content: Text('Se eliminará la medición del ${_dateFormat.format(entry.timestamp)}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await LocalStorageService.instance.deleteVitalSign(entry.id);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = LocalStorageService.instance.activePatient;
    final vitals = patient.vitalSigns;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.favorite_rounded, color: Color(0xFF2563EB), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Historial de Signos Vitales',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          '${patient.name} (${vitals.length} mediciones)',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nuevo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: () async {
                    final res = await RecordVitalSignsDialog.show(context);
                    if (res == true) _reload();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          Expanded(
            child: vitals.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.monitor_heart_outlined, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        const Text(
                          'No hay registros de signos vitales aún',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Registra la presión arterial o glicemia para seguimiento.',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: vitals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = vitals[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF64748B)),
                                    const SizedBox(width: 6),
                                    Text(
                                      _dateFormat.format(item.timestamp),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                                  onPressed: () => _deleteEntry(item),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (item.hasBloodPressure)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: item.bloodPressureColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: item.bloodPressureColor),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('🩺 ', style: TextStyle(fontSize: 12)),
                                        Text(
                                          'PA: ${item.systolic}/${item.diastolic} mmHg',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: item.bloodPressureColor),
                                        ),
                                        const SizedBox(width: 4),
                                        Text('(${item.bloodPressureLabel})', style: TextStyle(fontSize: 11, color: item.bloodPressureColor)),
                                      ],
                                    ),
                                  ),
                                if (item.hasHeartRate)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFF87171)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('❤️ ', style: TextStyle(fontSize: 12)),
                                        Text(
                                          'Pulso: ${item.heartRate} bpm',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFDC2626)),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (item.hasGlucose)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: item.glucoseColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: item.glucoseColor),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('🩸 ', style: TextStyle(fontSize: 12)),
                                        Text(
                                          'Glicemia: ${item.bloodGlucose} mg/dL',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: item.glucoseColor),
                                        ),
                                        const SizedBox(width: 4),
                                        Text('(${item.glucoseLabel})', style: TextStyle(fontSize: 11, color: item.glucoseColor)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            if (item.notes != null && item.notes!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Nota: ${item.notes}',
                                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

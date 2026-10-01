import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/storage/local_storage_service.dart';
import '../models/vital_sign_entry.dart';
import 'record_vital_signs_dialog.dart';
import 'vital_signs_history_sheet.dart';

class VitalSignsCard extends StatelessWidget {
  final VoidCallback? onUpdated;

  const VitalSignsCard({
    super.key,
    this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final latest = LocalStorageService.instance.latestVitalSign;
    final totalCount = LocalStorageService.instance.vitalSigns.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.monitor_heart_rounded, color: Color(0xFF2563EB), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Signos Vitales (MINSAL/AHA)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF2563EB)),
                label: const Text('Registrar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB))),
                onPressed: () async {
                  final saved = await RecordVitalSignsDialog.show(context);
                  if (saved == true) onUpdated?.call();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (latest == null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Sin registros recientes de presión arterial o glicemia para este paciente.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      final saved = await RecordVitalSignsDialog.show(context);
                      if (saved == true) onUpdated?.call();
                    },
                    child: const Text('Iniciar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                if (latest.hasBloodPressure)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: latest.bloodPressureColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: latest.bloodPressureColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text('🩺 ', style: TextStyle(fontSize: 12)),
                              Text('Presión Arterial', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${latest.systolic}/${latest.diastolic}',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: latest.bloodPressureColor),
                          ),
                          Text(
                            'mmHg • ${latest.bloodPressureLabel}',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: latest.bloodPressureColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (latest.hasBloodPressure && (latest.hasGlucose || latest.hasHeartRate)) const SizedBox(width: 8),
                if (latest.hasGlucose)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: latest.glucoseColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: latest.glucoseColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text('🩸 ', style: TextStyle(fontSize: 12)),
                              Text('Glicemia Capilar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${latest.bloodGlucose?.toStringAsFixed(latest.bloodGlucose!.truncateToDouble() == latest.bloodGlucose ? 0 : 1)}',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: latest.glucoseColor),
                          ),
                          Text(
                            'mg/dL • ${latest.glucoseLabel}',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: latest.glucoseColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  )
                else if (latest.hasHeartRate)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text('❤️ ', style: TextStyle(fontSize: 12)),
                              Text('Pulso Cardíaco', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${latest.heartRate} lpm',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                          ),
                          const Text(
                            'Frecuencia en reposo',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFFDC2626)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Último control: ${DateFormat('dd/MM HH:mm').format(latest.timestamp)}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                InkWell(
                  onTap: () async {
                    await VitalSignsHistorySheet.show(context);
                    onUpdated?.call();
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Ver historial ($totalCount) >',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

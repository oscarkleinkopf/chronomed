import 'package:flutter/material.dart';
import '../../senior_mode/widgets/physical_pill_widget.dart';

class ActiveMedicationCard extends StatelessWidget {
  final String name;
  final String dose;
  final String schedule;
  final Color pillColor;
  final String shapeType;
  final String imprint;
  final bool hasScoreLine;
  final String physicalDescription;
  final String stock;
  final bool isBioequivalent;
  final String? ispRegister;
  final String? clinicalPrecaution;

  const ActiveMedicationCard({
    super.key,
    required this.name,
    required this.dose,
    required this.schedule,
    required this.pillColor,
    required this.shapeType,
    required this.imprint,
    required this.hasScoreLine,
    required this.physicalDescription,
    required this.stock,
    this.isBioequivalent = false,
    this.ispRegister,
    this.clinicalPrecaution,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          if (isBioequivalent || (ispRegister != null && ispRegister!.isNotEmpty) || clinicalPrecaution != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (isBioequivalent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFF59E0B), width: 0.8),
                    ),
                    child: const Text(
                      '⭐ BIOEQUIVALENTE (ISP)',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                    ),
                  ),
                if (ispRegister != null && ispRegister!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
                    ),
                    child: Text(
                      'Reg. ISP: $ispRegister',
                      style: const TextStyle(fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                  ),
                if (clinicalPrecaution != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBFDBFE), width: 0.8),
                    ),
                    child: Text(
                      clinicalPrecaution!,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8)),
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

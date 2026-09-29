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
}

import 'package:flutter/material.dart';
import '../../schedule/models/circadian_routine.dart';

class CircadianRoutineCard extends StatelessWidget {
  final CircadianRoutine routine;
  final bool isHospital;
  final String fastingTime;
  final ValueChanged<CircadianRoutine> onUpdateRoutine;
  final VoidCallback onShowCustomRoutineDialog;

  const CircadianRoutineCard({
    super.key,
    required this.routine,
    required this.isHospital,
    required this.fastingTime,
    required this.onUpdateRoutine,
    required this.onShowCustomRoutineDialog,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isHospital ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0), width: isHospital ? 2 : 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
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
                  const Icon(Icons.schedule_rounded, color: Color(0xFF2563EB), size: 20),
                  const SizedBox(width: 8),
                  const Text("Régimen de 4 Comidas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isHospital ? const Color(0xFFDBEAFE) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isHospital ? "🏥 Hospital / ELEAM" : "🏠 Domicilio",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isHospital ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text("🏠 Hogar", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  selected: routine.regimeType == CircadianRegimeType.home,
                  onSelected: (selected) {
                    if (selected) {
                      onUpdateRoutine(CircadianRoutine.home);
                    }
                  },
                  selectedColor: const Color(0xFF2563EB),
                  labelStyle: TextStyle(color: routine.regimeType == CircadianRegimeType.home ? Colors.white : const Color(0xFF334155)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text("🏥 Hospital", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  selected: routine.regimeType == CircadianRegimeType.hospital,
                  onSelected: (selected) {
                    if (selected) {
                      onUpdateRoutine(CircadianRoutine.hospital);
                    }
                  },
                  selectedColor: const Color(0xFF2563EB),
                  labelStyle: TextStyle(color: routine.regimeType == CircadianRegimeType.hospital ? Colors.white : const Color(0xFF334155)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text("⚙️ Ajustar", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  selected: routine.regimeType == CircadianRegimeType.custom,
                  onSelected: (selected) => onShowCustomRoutineDialog(),
                  selectedColor: const Color(0xFF2563EB),
                  labelStyle: TextStyle(color: routine.regimeType == CircadianRegimeType.custom ? Colors.white : const Color(0xFF334155)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSlotItem("☀️", "Desayuno", routine.formatTime(routine.breakfast)),
                _buildSlotItem("🍲", "Almuerzo", routine.formatTime(routine.lunch)),
                _buildSlotItem("☕", "Once", routine.formatTime(routine.afternoon)),
                _buildSlotItem("🌙", "Noche", routine.formatTime(routine.night)),
              ],
            ),
          ),
          if (isHospital) ...[
            const SizedBox(height: 8),
            Text(
              "ℹ️ Régimen hospitalario: tomas adelantadas (Desayuno 07:00, Ayunas $fastingTime).",
              style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSlotItem(String emoji, String title, String time) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
        Text(time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF2563EB))),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/senior_theme.dart';

class OverdoseGuardButton extends StatelessWidget {
  final bool isTaken;
  final String nextDoseTime;
  final VoidCallback onConfirm;

  const OverdoseGuardButton({
    super.key,
    required this.isTaken,
    required this.nextDoseTime,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    if (isTaken) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: SeniorTheme.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: SeniorTheme.successGreen, width: 3),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle_rounded, color: SeniorTheme.successGreen, size: 64),
            const SizedBox(height: 12),
            const Text('¡Listo! Dosis Tomada', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: SeniorTheme.successGreen)),
            const SizedBox(height: 8),
            Text('Tu siguiente toma es a las $nextDoseTime', style: const TextStyle(fontSize: 20, color: SeniorTheme.textPrimary)),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 96,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: SeniorTheme.successGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        onPressed: () {
          HapticFeedback.heavyImpact();
          onConfirm();
        },
        icon: const Icon(Icons.check_rounded, size: 48, color: Colors.black),
        label: const Text('YA ME LA TOMÉ', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black)),
      ),
    );
  }
}

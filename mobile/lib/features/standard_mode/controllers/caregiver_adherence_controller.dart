import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/dose_omission_model.dart';
import '../services/dose_omission_service.dart';
import '../../schedule/models/circadian_routine.dart';

class CaregiverAdherenceController {
  DoseOmissionAlert? getActiveAlert(CircadianRoutine routine) {
    return DoseOmissionService.instance.getActiveEscalatedAlert(routine: routine);
  }

  void shareWhatsAppAlert(DoseOmissionAlert alert) {
    final message = DoseOmissionService.instance.generateWhatsAppAlertMessage(alert);
    Share.share(message, subject: 'Alerta Médica de Adherencia - ${alert.patientName}');
  }

  Future<void> markDoseSupervised(BuildContext context, DoseOmissionAlert alert, VoidCallback onMarked) async {
    await DoseOmissionService.instance.markDoseAsAdministeredByCaregiver(alert);
    onMarked();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F172A),
          content: Text(
            '✅ Dosis de ${alert.drugName} registrada como supervisada por el cuidador.',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }
}

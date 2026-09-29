import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/sync/local_p2p_sync_service.dart';
import '../widgets/p2p_sync_dialog.dart';

class CaregiverP2PController extends ChangeNotifier {
  StreamSubscription? _p2pSubscription;

  void startReceiver(BuildContext context, VoidCallback onDataReceived) {
    LocalP2pSyncService.instance.startReceiverServer();
    _p2pSubscription = LocalP2pSyncService.instance.intakeStream.listen((payload) {
      onDataReceived();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF047857),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.wifi_tethering_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '📡 Dosis sincronizada por Wi-Fi Local: ${payload.medicationName} (${payload.timeSlot.label})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });
  }

  void stopReceiver() {
    _p2pSubscription?.cancel();
  }

  void openSyncConfig(BuildContext context, VoidCallback onConfigSaved) {
    showDialog(
      context: context,
      builder: (ctx) => P2pSyncDialog(
        onConfigSaved: onConfigSaved,
      ),
    );
  }
}

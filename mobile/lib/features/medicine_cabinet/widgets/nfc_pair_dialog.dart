import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/services/nfc_medication_service.dart';
import '../models/medicine_cabinet_item.dart';

class NfcPairDialog extends StatefulWidget {
  final MedicineCabinetItem medicine;

  const NfcPairDialog({
    super.key,
    required this.medicine,
  });

  @override
  State<NfcPairDialog> createState() => _NfcPairDialogState();
}

class _NfcPairDialogState extends State<NfcPairDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  bool _isProcessing = false;
  String? _scannedTagId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.15).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    NfcMedicationService.instance.startListening();
  }

  @override
  void dispose() {
    _animController.dispose();
    NfcMedicationService.instance.stopListening();
    super.dispose();
  }

  Future<void> _handleTagScanned(String tagId) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _scannedTagId = tagId;
    });

    try {
      await NfcMedicationService.instance.pairTagToMedicine(
        medicineId: widget.medicine.id,
        tagId: tagId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Tag NFC "$tagId" vinculado con éxito a ${widget.medicine.name}!'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Error al vincular tag: $e';
      });
    }
  }

  Future<void> _unlinkTag() async {
    setState(() => _isProcessing = true);
    await NfcMedicationService.instance.unpairTagFromMedicine(widget.medicine.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tag NFC desvinculado de ${widget.medicine.name}.'),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop(true);
  }

  void _simulateNfcDetection() {
    // Genera un UID estándar NTAG213/215 (7 bytes en formato hex colon)
    final rand = Random();
    final bytes = List.generate(7, (_) => rand.nextInt(256).toRadixString(16).padLeft(2, '0').toUpperCase());
    final mockUid = bytes.join(':');
    _handleTagScanned(mockUid);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2563EB);
    const textDarkColor = Color(0xFF0F172A);
    const textMutedColor = Color(0xFF64748B);

    final hasExistingTag = widget.medicine.hasNfcTag;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.nfc_rounded, color: primaryColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vincular Pastillero NFC',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textDarkColor,
                        ),
                      ),
                      Text(
                        '${widget.medicine.name} (${widget.medicine.dosage})',
                        style: const TextStyle(fontSize: 13, color: textMutedColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Animated NFC Wave Icon
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withOpacity(0.08),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.35),
                        width: 2.5,
                      ),
                    ),
                    child: Center(
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: primaryColor)
                          : const Icon(
                              Icons.contactless_rounded,
                              size: 52,
                              color: primaryColor,
                            ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Instructions
            const Text(
              'Acerca la caja física o el pastillero a la parte trasera del teléfono',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textDarkColor,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Compatible con stickers NTAG213 y NTAG215 estándar.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: textMutedColor),
            ),

            if (hasExistingTag) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Tag actual: ${widget.medicine.nfcTagId}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textDarkColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
              ),
            ],

            const SizedBox(height: 24),

            // Action Buttons
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _simulateNfcDetection,
                  icon: const Icon(Icons.touch_app_rounded, size: 16),
                  label: const Text('Simular Contacto NFC (Probar)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: const BorderSide(color: primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (hasExistingTag) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _isProcessing ? null : _unlinkTag,
                    icon: const Icon(Icons.link_off_rounded, size: 16, color: Color(0xFFDC2626)),
                    label: const Text('Desvincular Tag Actual', style: TextStyle(color: Color(0xFFDC2626))),
                  ),
                ],
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar', style: TextStyle(color: textMutedColor)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

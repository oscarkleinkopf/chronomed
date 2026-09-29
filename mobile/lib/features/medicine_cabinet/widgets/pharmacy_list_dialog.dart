import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/storage/local_storage_service.dart';
import '../models/medicine_cabinet_item.dart';
import '../../ocr/models/medicine_box_scan_result.dart';

void showPharmacyListDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => const PharmacyListDialog(),
  );
}

class PharmacyListDialog extends StatelessWidget {
  const PharmacyListDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = LocalStorageService.instance;
    final allItems = storage.getCabinetItems();
    final patientName = storage.patientName;
    final patientRut = storage.patientRut;

    // Filtrar fármacos con stock bajo (<= 5) o por vencer / vencidos
    final neededItems = allItems.where((item) {
      final isLowStock = item.stockUnits <= 5;
      final isExpiring = item.expirationStatus == BoxExpirationStatus.expired ||
          item.expirationStatus == BoxExpirationStatus.expiringSoon;
      return isLowStock || isExpiring;
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Text('📋', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 8),
                    Text(
                      'Lista para Farmacia',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text(
              'Paciente: $patientName ($patientRut)',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const Divider(height: 20),

            // Content
            Expanded(
              child: neededItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check_circle_outline_rounded, size: 48, color: Color(0xFF16A34A)),
                          SizedBox(height: 12),
                          Text(
                            '¡Botiquín al día!',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'No hay medicamentos con stock bajo ni próximos a vencer.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: neededItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 12),
                      itemBuilder: (ctx, index) {
                        final item = neededItems[index];
                        final isZero = item.stockUnits == 0;
                        final isLow = item.stockUnits <= 5 && !isZero;
                        final isExpired = item.expirationStatus == BoxExpirationStatus.expired;
                        final isExpiringSoon = item.expirationStatus == BoxExpirationStatus.expiringSoon;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isZero
                                      ? const Color(0xFFFEE2E2)
                                      : isLow
                                          ? const Color(0xFFFEF3C7)
                                          : const Color(0xFFEFF6FF),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  isZero
                                      ? '⛔'
                                      : isLow
                                          ? '⚠️'
                                          : '💊',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item.name} ${item.dosage}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 2,
                                      children: [
                                        if (isZero)
                                          const Text(
                                            'AGOTADO (0 un.)',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                          )
                                        else if (isLow)
                                          Text(
                                            'Quedan solo ${item.stockUnits} un.',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                                          ),
                                        if (isExpired)
                                          const Text(
                                            '• VENCIDO',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                          )
                                        else if (isExpiringSoon)
                                          Text(
                                            '• Vence: ${item.expirationDate}',
                                            style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                                          ),
                                        if (item.isBioequivalent)
                                          const Text(
                                            '• Bioequivalente ⭐',
                                            style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                                          ),
                                      ],
                                    ),
                                    if (item.ispRegister != null && item.ispRegister!.isNotEmpty)
                                      Text(
                                        'Reg. ISP: ${item.ispRegister}',
                                        style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF64748B)),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CERRAR'),
                  ),
                ),
                if (neededItems.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44),
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text(
                        'ENVIAR WHATSAPP',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: () {
                        _sharePharmacyList(context, neededItems, patientName, patientRut);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _sharePharmacyList(
    BuildContext context,
    List<MedicineCabinetItem> items,
    String patientName,
    String patientRut,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('📋 *LISTA DE REPOSICIÓN DE MEDICAMENTOS*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('👤 Paciente: $patientName (RUT: $patientRut)');
    buffer.writeln('📅 Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    for (final item in items) {
      final isZero = item.stockUnits == 0;
      final statusStr = isZero ? '⚠️ AGOTADO (0 un.)' : '⚠️ Quedan: ${item.stockUnits} un.';
      final bioStr = item.isBioequivalent ? ' [Bioequivalente ⭐]' : '';
      final ispStr = item.ispRegister != null ? ' (Reg. ISP: ${item.ispRegister})' : '';

      buffer.writeln('• *${item.name}* ${item.dosage}$bioStr');
      buffer.writeln('   $statusStr$ispStr');
      if (item.expirationDate != null) {
        buffer.writeln('   Vencimiento actual: ${item.expirationDate}');
      }
      buffer.writeln('');
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('Generado automáticamente por ChronoMed');

    Share.share(buffer.toString());
  }
}

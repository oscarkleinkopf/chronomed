import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/medicine_cabinet_item.dart';
import '../../senior_mode/widgets/physical_pill_widget.dart';
import '../../ocr/models/medicine_box_scan_result.dart';

class MedicineCabinetCard extends StatelessWidget {
  final MedicineCabinetItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(int) onUpdateStock;
  final VoidCallback? onPairNfc;

  const MedicineCabinetCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onUpdateStock,
    this.onPairNfc,
  });

  @override
  Widget build(BuildContext context) {
    final isLowStock = item.stockUnits <= 5;
    final isZeroStock = item.stockUnits == 0;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isZeroStock
              ? const Color(0xFFFCA5A5) // Red border
              : isLowStock
                  ? const Color(0xFFFDE68A) // Yellow border
                  : const Color(0xFFE2E8F0), // Normal slate
          width: isLowStock || isZeroStock ? 1.5 : 1,
        ),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pastilla física fotorrealista con lupa interactiva
                PhysicalPillWidget(
                  size: 52,
                  shapeType: item.shapeType,
                  pillColor: item.pillColor,
                  imprint: item.imprint,
                  hasScoreLine: item.hasScoreLine,
                  medicationName: item.name,
                  dosage: item.dosage,
                  physicalDescription: item.physicalDescription,
                  enableMagnifier: true,
                ),
                const SizedBox(width: 14),

                // Datos principales
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          // Menú de opciones
                            PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
                            onSelected: (value) {
                              if (value == 'edit') {
                                onEdit();
                              } else if (value == 'nfc') {
                                onPairNfc?.call();
                              } else if (value == 'delete') {
                                _confirmDelete(context);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_rounded, size: 18, color: Color(0xFF2563EB)),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text('Editar datos', overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'nfc',
                                child: Row(
                                  children: [
                                    const Icon(Icons.nfc_rounded, size: 18, color: Color(0xFF16A34A)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.hasNfcTag ? 'Gestionar Tag NFC' : 'Vincular Tag NFC',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Eliminar del botiquín',
                                        style: TextStyle(color: Color(0xFFDC2626)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (item.dosage.isNotEmpty)
                        Text(
                          'Concentración: ${item.dosage}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      const SizedBox(height: 6),

                      // Badges chilenos: ISP y Bioequivalencia
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (item.isBioequivalent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFF59E0B)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '⭐ BIOEQUIVALENTE (ISP)',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                                  ),
                                ],
                              ),
                            ),
                          if (item.ispRegister != null && item.ispRegister!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Text(
                                'Reg. ISP: ${item.ispRegister}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Chips de Lote y Vencimiento
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (item.expirationDate != null && item.expirationDate!.isNotEmpty)
                  _buildExpirationBadge(item),
                if (item.lotNumber != null && item.lotNumber!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      'Lote: ${item.lotNumber}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ),
                if (item.hasNfcTag)
                  InkWell(
                    onTap: onPairNfc,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.nfc_rounded, size: 12, color: Color(0xFF16A34A)),
                          const SizedBox(width: 4),
                          Text(
                            'NFC: ${item.nfcTagId}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF166534),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  InkWell(
                    onTap: onPairNfc,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.nfc_rounded, size: 12, color: Color(0xFF64748B)),
                          SizedBox(width: 4),
                          Text(
                            '+ Tag NFC',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 20),

            // Control de Stock
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${item.stockUnits} unidades',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isZeroStock
                                ? const Color(0xFFDC2626)
                                : isLowStock
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF0F172A),
                          ),
                        ),
                        if (isZeroStock) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('AGOTADO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                          ),
                        ] else if (isLowStock) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('STOCK BAJO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                          ),
                        ],
                      ],
                    ),
                    const Text('Disponibles en botiquín', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),

                // Botones +/- (48dp mínimo accesibilidad)
                Row(
                  children: [
                    IconButton.filledTonal(
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      icon: const Icon(Icons.remove, size: 20),
                      onPressed: item.stockUnits > 0 ? () {
                        HapticFeedback.lightImpact();
                        onUpdateStock(item.stockUnits - 1);
                      } : null,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        foregroundColor: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        onUpdateStock(item.stockUnits + 1);
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFEFF6FF),
                        foregroundColor: const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpirationBadge(MedicineCabinetItem item) {
    Color bg = const Color(0xFFF0FDF4);
    Color border = const Color(0xFFBBF7D0);
    Color text = const Color(0xFF166534);
    String icon = '✅';

    if (item.expirationStatus == BoxExpirationStatus.expired) {
      bg = const Color(0xFFFEF2F2);
      border = const Color(0xFFFECACA);
      text = const Color(0xFF991B1B);
      icon = '⛔';
    } else if (item.expirationStatus == BoxExpirationStatus.expiringSoon) {
      bg = const Color(0xFFFFFBEB);
      border = const Color(0xFFFDE68A);
      text = const Color(0xFF92400E);
      icon = '⚠️';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            'Vence: ${item.expirationDate}',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: text),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar fármaco?'),
        content: Text('¿Deseas remover "${item.name}" del botiquín? Esta acción se guardará localmente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
  }
}

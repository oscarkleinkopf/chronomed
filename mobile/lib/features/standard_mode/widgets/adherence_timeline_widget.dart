import 'package:flutter/material.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../senior_mode/models/senior_intake_item.dart';

class AdherenceTimelineWidget extends StatelessWidget {
  final VoidCallback? onTapDetails;

  const AdherenceTimelineWidget({
    super.key,
    this.onTapDetails,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Encuentra el lunes de la semana actual (1 = Monday, 7 = Sunday)
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final daysOfWeek = List.generate(7, (i) => DateTime(monday.year, monday.month, monday.day + i));

    final dayLabels = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa', 'Do'];

    int totalPastSlots = 0;
    int totalTakenSlots = 0;

    final List<Map<String, dynamic>> weekData = [];

    for (int i = 0; i < 7; i++) {
      final date = daysOfWeek[i];
      final isFuture = DateTime(date.year, date.month, date.day).isAfter(DateTime(now.year, now.month, now.day));
      final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

      int taken = 0;
      for (final slot in SeniorTimeSlot.values) {
        if (LocalStorageService.instance.isSlotTakenToday(slot, date)) {
          taken++;
        }
      }

      if (!isFuture) {
        totalPastSlots += 4;
        totalTakenSlots += taken;
      }

      weekData.add({
        'label': dayLabels[i],
        'dayNumber': date.day,
        'taken': taken,
        'isFuture': isFuture,
        'isToday': isToday,
      });
    }

    final int weeklyPercentage = totalPastSlots > 0 ? ((totalTakenSlots / totalPastSlots) * 100).round() : 100;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.calendar_month_rounded, color: Color(0xFF2563EB), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Adherencia Semanal',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: weeklyPercentage >= 80
                      ? const Color(0xFFDCFCE7)
                      : weeklyPercentage >= 50
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$weeklyPercentage% semanal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: weeklyPercentage >= 80
                        ? const Color(0xFF166534)
                        : weeklyPercentage >= 50
                            ? const Color(0xFF92400E)
                            : const Color(0xFF991B1B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Fila de 7 días
          LayoutBuilder(
            builder: (context, constraints) {
              final double dayWidth = (constraints.maxWidth - (6 * 6)) / 7;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: weekData.map((data) {
                  final bool isFuture = data['isFuture'] as bool;
                  final bool isToday = data['isToday'] as bool;
                  final int taken = data['taken'] as int;
                  final String label = data['label'] as String;
                  final int dayNumber = data['dayNumber'] as int;

                  Color circleColor;
                  Color iconColor;
                  IconData icon;

                  if (isFuture) {
                    circleColor = const Color(0xFFF1F5F9);
                    iconColor = const Color(0xFF94A3B8);
                    icon = Icons.remove;
                  } else if (taken == 4) {
                    circleColor = const Color(0xFF22C55E);
                    iconColor = Colors.white;
                    icon = Icons.check;
                  } else if (taken > 0) {
                    circleColor = const Color(0xFFFACC15);
                    iconColor = const Color(0xFF854D0E);
                    icon = Icons.access_time_rounded;
                  } else {
                    circleColor = const Color(0xFFEF4444);
                    iconColor = Colors.white;
                    icon = Icons.close;
                  }

                  return SizedBox(
                    width: dayWidth,
                    child: Column(
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                            color: isToday ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 10,
                            color: isToday ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: circleColor,
                            border: isToday
                                ? Border.all(color: const Color(0xFF2563EB), width: 2.5)
                                : null,
                            boxShadow: isToday
                                ? [
                                    const BoxShadow(
                                      color: Color(0x332563EB),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                          child: Icon(
                            icon,
                            size: 16,
                            color: iconColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isFuture ? '-' : '$taken/4',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isFuture
                                ? const Color(0xFF94A3B8)
                                : taken == 4
                                    ? const Color(0xFF166534)
                                    : taken > 0
                                        ? const Color(0xFF854D0E)
                                        : const Color(0xFF991B1B),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 10),
          const Divider(height: 12),
          // Leyenda explicativa
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _LegendItem(color: Color(0xFF22C55E), text: 'Completo (4/4)'),
              _LegendItem(color: Color(0xFFFACC15), text: 'Parcial'),
              _LegendItem(color: Color(0xFFEF4444), text: 'Omitido'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}

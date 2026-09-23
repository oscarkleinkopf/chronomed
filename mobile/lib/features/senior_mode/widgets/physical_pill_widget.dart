import 'package:flutter/material.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/theme/senior_theme.dart';

class PhysicalPillWidget extends StatelessWidget {
  final double size;
  final String shapeType; // 'round', 'small_round', 'oblong'
  final Color pillColor;
  final String imprint;
  final bool hasScoreLine;
  final String? imagePath;
  final String medicationName;
  final String dosage;
  final String physicalDescription;
  final bool enableMagnifier;

  const PhysicalPillWidget({
    super.key,
    this.size = 120,
    this.shapeType = 'round',
    this.pillColor = const Color(0xFF3B82F6),
    this.imprint = '',
    this.hasScoreLine = false,
    this.imagePath,
    this.medicationName = 'Medicamento',
    this.dosage = '',
    this.physicalDescription = '',
    this.enableMagnifier = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget pillCore = CustomPaint(
      size: Size(size, size),
      painter: _PhotorealisticPillPainter(
        shapeType: shapeType,
        pillColor: pillColor,
        imprint: imprint,
        hasScoreLine: hasScoreLine,
      ),
    );

    final semanticLabel = physicalDescription.isNotEmpty
        ? 'Pastilla física de $medicationName: $physicalDescription. Toca para abrir la lupa.'
        : 'Pastilla física de $medicationName ($dosage). Toca para abrir la lupa.';

    return Semantics(
      button: enableMagnifier,
      label: semanticLabel,
      hint: enableMagnifier ? 'Toca dos veces para ver la pastilla en tamaño gigante' : null,
      child: GestureDetector(
        onTap: enableMagnifier ? () => _showMagnifierDialog(context) : null,
        child: Container(
          width: size + 20,
          height: size + 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            boxShadow: [
              BoxShadow(
                color: pillColor.withOpacity(0.35),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: pillCore,
        ),
      ),
    );
  }

  void _showMagnifierDialog(BuildContext context) {
    final ttsText = physicalDescription.isNotEmpty
        ? '$medicationName. $physicalDescription.'
        : '$medicationName $dosage.';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: SeniorTheme.accentYellow, width: 2),
        ),
        title: Row(
          children: [
            const Icon(Icons.zoom_in_rounded, color: SeniorTheme.accentYellow, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Lupa: $medicationName',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 220,
                height: 220,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF334155), width: 1.5),
                ),
                child: CustomPaint(
                  size: const Size(180, 180),
                  painter: _PhotorealisticPillPainter(
                    shapeType: shapeType,
                    pillColor: pillColor,
                    imprint: imprint,
                    hasScoreLine: hasScoreLine,
                    isMagnified: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                medicationName,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                dosage,
                style: const TextStyle(color: SeniorTheme.accentYellow, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF475569)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVisualFeatureRow(Icons.palette_outlined, 'Color Real', _getColorName(pillColor)),
                    const SizedBox(height: 6),
                    _buildVisualFeatureRow(Icons.crop_free_outlined, 'Forma', _getShapeDescription(shapeType)),
                    if (hasScoreLine || imprint.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _buildVisualFeatureRow(
                        Icons.fingerprint_rounded,
                        'Grabado / Marca',
                        hasScoreLine ? 'Ranura divisoria con número "$imprint"' : 'Grabado "$imprint"',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF334155),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.volume_up_rounded, color: SeniorTheme.accentYellow),
                label: const Text('Escuchar Descripción Física', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => TtsService().speak(ttsText),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: SeniorTheme.accentYellow,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ENTENDIDO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualFeatureRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: SeniorTheme.accentYellow),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  String _getColorName(Color color) {
    if (color == const Color(0xFF3B82F6) || color == const Color(0xFF60A5FA)) return 'Azul cielo';
    if (color == Colors.white || color == const Color(0xFFF8FAFC)) return 'Blanco tiza / perla';
    if (color == const Color(0xFFFACC15) || color == const Color(0xFFFEF08A)) return 'Amarillo pálido';
    return 'Color farmacéutico';
  }

  String _getShapeDescription(String shape) {
    switch (shape) {
      case 'round':
        return 'Redonda con ranura central';
      case 'small_round':
        return 'Redonda pequeña y plana';
      case 'oblong':
      case 'oval':
        return 'Ovalada alargada (cápsula sólida)';
      default:
        return 'Comprimido estándar';
    }
  }
}

class _PhotorealisticPillPainter extends CustomPainter {
  final String shapeType;
  final Color pillColor;
  final String imprint;
  final bool hasScoreLine;
  final bool isMagnified;

  _PhotorealisticPillPainter({
    required this.shapeType,
    required this.pillColor,
    required this.imprint,
    required this.hasScoreLine,
    this.isMagnified = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width * (shapeType == 'small_round' ? 0.35 : 0.45);

    final isOblong = shapeType == 'oblong' || shapeType == 'oval';

    // 1. Sombra de volumen
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    if (isOblong) {
      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center.translate(0, 4), width: size.width * 0.9, height: size.height * 0.55),
        Radius.circular(size.height * 0.28),
      );
      canvas.drawRRect(rrect, shadowPaint);
    } else {
      canvas.drawCircle(center.translate(0, 4), radius, shadowPaint);
    }

    // 2. Cuerpo base con degradado 3D (Luz desde arriba a la izquierda)
    final lightColor = Color.lerp(pillColor, Colors.white, 0.45)!;
    final darkColor = Color.lerp(pillColor, Colors.black, 0.28)!;

    final gradient = RadialGradient(
      center: const Alignment(-0.35, -0.35),
      radius: 0.85,
      colors: [lightColor, pillColor, darkColor],
      stops: const [0.0, 0.65, 1.0],
    );

    final bodyPaint = Paint()
      ..shader = gradient.createShader(Rect.fromCenter(center: center, width: radius * 2, height: radius * 2));

    if (isOblong) {
      final bodyRRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: size.width * 0.88, height: size.height * 0.52),
        Radius.circular(size.height * 0.26),
      );
      canvas.drawRRect(bodyRRect, bodyPaint);

      // Borde exterior
      final borderPaint = Paint()
        ..color = darkColor
        ..style = PaintingStyle.stroke
        ..width = 1.5;
      canvas.drawRRect(bodyRRect, borderPaint);
    } else {
      canvas.drawCircle(center, radius, bodyPaint);

      // Borde exterior
      final borderPaint = Paint()
        ..color = darkColor
        ..style = PaintingStyle.stroke
        ..width = 1.5;
      canvas.drawCircle(center, radius, borderPaint);
    }

    // 3. Ranura central de división (score line)
    if (hasScoreLine) {
      final grooveLength = radius * 1.55;
      final lineDarkPaint = Paint()
        ..color = darkColor.withOpacity(0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isMagnified ? 3.0 : 2.0
        ..strokeCap = StrokeCap.round;

      final lineLightPaint = Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isMagnified ? 1.5 : 1.0
        ..strokeCap = StrokeCap.round;

      // Línea oscura hundida
      canvas.drawLine(
        Offset(center.dx, center.dy - grooveLength / 2),
        Offset(center.dx, center.dy + grooveLength / 2),
        lineDarkPaint,
      );

      // Resalte de luz reflejada justo a la derecha de la ranura
      canvas.drawLine(
        Offset(center.dx + 1.2, center.dy - grooveLength / 2 + 1),
        Offset(center.dx + 1.2, center.dy + grooveLength / 2 - 1),
        lineLightPaint,
      );
    }

    // 4. Grabado de troquelado (imprint)
    if (imprint.isNotEmpty) {
      final textSpan = TextSpan(
        text: imprint,
        style: TextStyle(
          color: darkColor.withOpacity(0.85),
          fontSize: (isMagnified ? 24 : 14) * (shapeType == 'small_round' ? 0.75 : 1.0),
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
          shadows: [
            Shadow(
              color: Colors.white.withOpacity(0.4),
              offset: const Offset(0.5, 0.5),
              blurRadius: 0.5,
            ),
          ],
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      // Si tiene ranura, desplaza el número a un cuadrante visible
      final textOffset = hasScoreLine
          ? Offset(center.dx + (radius * 0.28), center.dy - (textPainter.height / 2))
          : Offset(center.dx - (textPainter.width / 2), center.dy - (textPainter.height / 2));

      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant _PhotorealisticPillPainter oldDelegate) {
    return oldDelegate.pillColor != pillColor ||
        oldDelegate.shapeType != shapeType ||
        oldDelegate.imprint != imprint ||
        oldDelegate.hasScoreLine != hasScoreLine ||
        oldDelegate.isMagnified != isMagnified;
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MangroveScenePainter extends CustomPainter {
  MangroveScenePainter({required this.phase, required this.compact});
  final double phase;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizon = h * 0.61;
    final waterTop = horizon;

    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFFB8DED6), Color(0xFFEAF0D8)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    final sunCenter = Offset(w * 0.83, h * 0.18);
    canvas.drawCircle(
      sunCenter,
      h * 0.105,
      Paint()..color = const Color(0xFFFFF4C8).withValues(alpha: 0.32),
    );
    canvas.drawCircle(sunCenter, h * 0.066, Paint()..color = const Color(0xFFFFF5D2));

    _drawCloud(
      canvas,
      Offset(w * (0.16 + 0.025 * math.sin(phase * math.pi * 2)), h * 0.17),
      w * 0.15,
      h * 0.055,
    );
    _drawCloud(
      canvas,
      Offset(w * (0.53 - 0.02 * math.sin(phase * math.pi * 2)), h * 0.11),
      w * 0.11,
      h * 0.042,
    );

    final farLand = Path()
      ..moveTo(0, h * 0.52)
      ..quadraticBezierTo(w * 0.18, h * 0.45, w * 0.35, h * 0.53)
      ..quadraticBezierTo(w * 0.63, h * 0.47, w * 0.78, h * 0.52)
      ..quadraticBezierTo(w * 0.91, h * 0.47, w, h * 0.51)
      ..lineTo(w, waterTop + 2)
      ..lineTo(0, waterTop + 2)
      ..close();
    canvas.drawPath(farLand, Paint()..color = const Color(0xFF719D78));

    for (int i = 0; i < 19; i++) {
      final x = w * i / 18;
      final y = h * (0.47 + 0.025 * math.sin(i * 1.9));
      final r = h * (0.035 + (i % 3) * 0.006);
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = i.isEven ? const Color(0xFF3D7655) : const Color(0xFF558B61),
      );
    }

    final waterPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFF69B6B2), Color(0xFF327D82), Color(0xFF205D67)],
      ).createShader(Rect.fromLTWH(0, waterTop, w, h - waterTop));
    canvas.drawRect(Rect.fromLTWH(0, waterTop, w, h - waterTop), waterPaint);

    // Distant water reflections.
    final reflection = Paint()..strokeCap = StrokeCap.round;
    for (int i = 0; i < 15; i++) {
      final x = w * ((i * 0.137 + phase * 0.09) % 1.15) - w * 0.05;
      final y = waterTop + h * (0.045 + (i % 5) * 0.044);
      reflection
        ..color = const Color(0xFFD4F0D9).withValues(alpha: 0.2 + (i % 3) * 0.06)
        ..strokeWidth = 1.2 + (i % 3) * 0.45;
      canvas.drawLine(Offset(x, y), Offset(x + w * (0.035 + (i % 2) * 0.025), y), reflection);
    }

    _drawMangrove(canvas, w * 0.18, h * 0.47, h * 0.25, w * 0.13,
        seed: 3, waterTop: waterTop, phase: phase);
    _drawMangrove(canvas, w * 0.57, h * 0.43, h * 0.39, w * 0.19,
        seed: 8, waterTop: waterTop, phase: phase);
    _drawMangrove(canvas, w * 0.9, h * 0.5, h * 0.22, w * 0.13,
        seed: 5, waterTop: waterTop, phase: phase);

    // Small school of fish in the shallow water.
    _drawFish(
      canvas,
      Offset(w * (0.73 + 0.02 * math.sin(phase * math.pi * 2)), h * 0.75),
      h * 0.028,
      const Color(0xFFFFD990),
    );
    _drawFish(
      canvas,
      Offset(w * (0.82 + 0.018 * math.sin(phase * math.pi * 2 + 1)), h * 0.80),
      h * 0.019,
      const Color(0xFFE3F0D8),
    );
    _drawFish(
      canvas,
      Offset(w * (0.3 + 0.015 * math.sin(phase * math.pi * 2 + 2)), h * 0.83),
      h * 0.017,
      const Color(0xFFFFD990),
    );

    // A seedling near the edge of the water.
    final sx = w * 0.885;
    final sy = h * 0.91;
    final stem = Paint()
      ..color = const Color(0xFF3D6740)
      ..strokeWidth = math.max(1.8, w * 0.006).toDouble()
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(sx, sy), Offset(sx + w * 0.005, sy - h * 0.085), stem);
    _drawLeaf(canvas, Offset(sx - w * 0.015, sy - h * 0.06), w * 0.022, h * 0.012, -0.5,
        const Color(0xFFB5D66F));
    _drawLeaf(canvas, Offset(sx + w * 0.018, sy - h * 0.078), w * 0.022, h * 0.012, 0.45,
        const Color(0xFF91C567));

    // Small shoreline grasses.
    final grassPaint = Paint()
      ..color = const Color(0xFF3D744A)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 10; i++) {
      final gx = w * (0.02 + i * 0.025);
      final gy = waterTop + h * 0.018;
      canvas.drawLine(
          Offset(gx, gy), Offset(gx - w * 0.006, gy - h * (0.025 + (i % 3) * 0.008)), grassPaint);
      canvas.drawLine(
          Offset(gx, gy), Offset(gx + w * 0.007, gy - h * (0.021 + (i % 2) * 0.009)), grassPaint);
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double width, double height) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.56);
    canvas.drawOval(Rect.fromCenter(center: center, width: width, height: height), paint);
    canvas.drawCircle(center.translate(-width * 0.18, -height * 0.1), height * 0.58, paint);
    canvas.drawCircle(center.translate(width * 0.06, -height * 0.24), height * 0.72, paint);
    canvas.drawCircle(center.translate(width * 0.25, -height * 0.02), height * 0.48, paint);
  }

  void _drawMangrove(Canvas canvas, double x, double crownY, double trunkH, double crownW,
      {required int seed, required double waterTop, required double phase}) {
    final trunkBottom = waterTop + 1;
    final trunkTop = crownY + trunkH * 0.16;
    final sway = math.sin(phase * math.pi * 2 + seed) * crownW * 0.018;
    final trunk = Paint()
      ..color = const Color(0xFF695744)
      ..style = PaintingStyle.stroke
      ..strokeWidth = crownW * 0.15
      ..strokeCap = StrokeCap.round;
    final trunkPath = Path()
      ..moveTo(x, trunkBottom)
      ..cubicTo(x - crownW * 0.08, trunkBottom - trunkH * 0.38, x + sway,
          trunkTop + trunkH * 0.22, x + sway * 0.55, trunkTop);
    canvas.drawPath(trunkPath, trunk);

    final branch = Paint()
      ..color = const Color(0xFF765F48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = crownW * 0.055
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x + sway * 0.5, trunkTop + trunkH * 0.17),
        Offset(x - crownW * 0.34 + sway, crownY + trunkH * 0.03), branch);
    canvas.drawLine(Offset(x + sway * 0.5, trunkTop + trunkH * 0.11),
        Offset(x + crownW * 0.35 + sway, crownY + trunkH * 0.08), branch);

    final rootPaint = Paint()
      ..color = const Color(0xFF745F4C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.6, crownW * 0.027).toDouble()
      ..strokeCap = StrokeCap.round;
    for (int i = -3; i <= 3; i++) {
      final start = Offset(
          x + i * crownW * 0.025, waterTop - trunkH * (0.12 + (i.abs() % 2) * 0.02));
      final end = Offset(
          x + i * crownW * 0.23, waterTop + trunkH * (0.24 + (i.abs() % 3) * 0.025));
      final control = Offset((start.dx + end.dx) / 2 + (i.isNegative ? -1 : 1) * crownW * 0.055,
          waterTop + trunkH * 0.04);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
      canvas.drawPath(path, rootPaint);
    }

    final leafColors = <Color>[
      const Color(0xFF235D3E),
      const Color(0xFF2F7148),
      const Color(0xFF438453),
      const Color(0xFF5A965C),
      const Color(0xFF36754B),
    ];
    final random = math.Random(seed);
    final crownCenter = Offset(x + sway, crownY + trunkH * 0.015);
    for (int i = 0; i < 31; i++) {
      final dx = (random.nextDouble() * 2 - 1) * crownW * 0.55;
      final dy = (random.nextDouble() * 2 - 1) * trunkH * 0.19;
      final radius = crownW * (0.12 + random.nextDouble() * 0.12);
      final center = crownCenter.translate(dx, dy);
      canvas.drawCircle(center, radius, Paint()..color = leafColors[i % leafColors.length]);
      if (i % 4 == 0) {
        canvas.drawCircle(center.translate(-radius * 0.2, -radius * 0.18), radius * 0.48,
            Paint()..color = const Color(0xFF75A962).withValues(alpha: 0.5));
      }
    }

    // Floating prop roots are drawn in front of the waterline.
    final knees = Paint()
      ..color = const Color(0xFF826A50)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 5; i++) {
      final rx = x - crownW * 0.27 + crownW * i * 0.13;
      final ry = waterTop + trunkH * (0.08 + (i % 2) * 0.04);
      canvas.drawLine(Offset(rx, ry), Offset(rx + crownW * 0.015, ry - trunkH * 0.07), knees);
    }
  }

  void _drawLeaf(
      Canvas canvas, Offset center, double width, double height, double rotation, Color color) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final path = Path()
      ..moveTo(-width / 2, 0)
      ..quadraticBezierTo(0, -height * 1.35, width / 2, 0)
      ..quadraticBezierTo(0, height * 1.1, -width / 2, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.restore();
  }

  void _drawFish(Canvas canvas, Offset center, double height, Color color) {
    final bodyPaint = Paint()..color = color.withValues(alpha: 0.92);
    canvas.drawOval(
        Rect.fromCenter(center: center, width: height * 2.0, height: height), bodyPaint);
    final tail = Path()
      ..moveTo(center.dx - height * 0.8, center.dy)
      ..lineTo(center.dx - height * 1.55, center.dy - height * 0.7)
      ..lineTo(center.dx - height * 1.55, center.dy + height * 0.7)
      ..close();
    canvas.drawPath(tail, bodyPaint);
    canvas.drawCircle(
      Offset(center.dx + height * 0.55, center.dy - height * 0.1),
      math.max(0.8, height * 0.09).toDouble(),
      Paint()..color = AppColors.forestDeep,
    );
  }

  @override
  bool shouldRepaint(covariant MangroveScenePainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.compact != compact;
}

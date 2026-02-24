import 'dart:math' as math;
import 'package:flutter/material.dart';

class WaveformPainter extends CustomPainter {
  WaveformPainter({
    required this.progress,
    required this.color,
    this.lineCount = 40,
  });

  final double progress;
  final Color color;
  final int lineCount;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final spacing = size.width / lineCount;
    final centerY = size.height / 2;
    final maxAmplitude = size.height * 0.4;

    for (int i = 0; i < lineCount; i++) {
      final x = spacing * i + spacing / 2;
      final normalizedX = i / lineCount;

      // Subtle sine wave pattern that shifts with progress
      final wave1 = math.sin((normalizedX * math.pi * 3) + (progress * math.pi * 2));
      final wave2 = math.sin((normalizedX * math.pi * 5) + (progress * math.pi * 4)) * 0.3;

      // Fade edges
      final edgeFade = math.sin(normalizedX * math.pi);

      final amplitude = (wave1 + wave2).abs() * maxAmplitude * edgeFade;

      canvas.drawLine(
        Offset(x, centerY - amplitude / 2),
        Offset(x, centerY + amplitude / 2),
        paint..color = color.withValues(alpha: 0.3 + (0.7 * edgeFade * (wave1.abs()))),
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

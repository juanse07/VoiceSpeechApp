import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/score_utils.dart';

class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.score,
    this.size = 120,
    this.strokeWidth = 6,
    this.label,
    this.showLabel = true,
  });

  final double score;
  final double size;
  final double strokeWidth;
  final String? label;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _ScoreRingPainter(
              score: score,
              strokeWidth: strokeWidth,
              color: ScoreUtils.colorForScore(score),
              trackColor: AppColors.border,
            ),
            child: Center(
              child: Text(
                score.round().toString(),
                style: size > 80
                    ? AppTypography.scoreLarge
                    : AppTypography.scoreMedium,
              ),
            ),
          ),
        ),
        if (showLabel && label != null) ...[
          const SizedBox(height: 8),
          Text(
            label!,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  _ScoreRingPainter({
    required this.score,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
  });

  final double score;
  final double strokeWidth;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (score / 100) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter oldDelegate) =>
      oldDelegate.score != score || oldDelegate.color != color;
}

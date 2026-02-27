import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/score_utils.dart';

const _descriptions = {
  'Accuracy': 'How closely your pronunciation matches a native speaker, scored at the phoneme level.',
  'Fluency': 'How smoothly you speak — measures natural pauses and flow between words.',
  'Complete': 'The percentage of reference words you actually pronounced.',
  'Prosody': 'How natural your speech sounds — rhythm, stress, intonation, and speaking speed.',
};

class ScoreBreakdown extends StatelessWidget {
  const ScoreBreakdown({
    super.key,
    required this.accuracy,
    required this.fluency,
    required this.completeness,
    required this.prosody,
  });

  final double accuracy;
  final double fluency;
  final double completeness;
  final double prosody;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ScoreItem(label: 'Accuracy', score: accuracy),
        _divider(),
        _ScoreItem(label: 'Fluency', score: fluency),
        _divider(),
        _ScoreItem(label: 'Complete', score: completeness),
        _divider(),
        _ScoreItem(label: 'Prosody', score: prosody),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.borderLight,
    );
  }
}

class _ScoreItem extends StatelessWidget {
  const _ScoreItem({required this.label, required this.score});

  final String label;
  final double score;

  void _showInfo(BuildContext context) {
    final description = _descriptions[label] ?? '';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label, style: AppTypography.titleMedium),
        content: Text(description, style: AppTypography.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            score.round().toString(),
            style: AppTypography.scoreMedium.copyWith(
              color: ScoreUtils.colorForScore(score),
            ),
          ),
          const SizedBox(height: AppConstants.spacing4),
          GestureDetector(
            onTap: () => _showInfo(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  Icons.info_outline_rounded,
                  size: 12,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

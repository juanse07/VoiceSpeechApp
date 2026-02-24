import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/score_utils.dart';
import '../../domain/entities/word_detail.dart';

class PhonemeBottomSheet extends StatelessWidget {
  const PhonemeBottomSheet({super.key, required this.word});

  final WordDetail word;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacing24,
        0,
        AppConstants.spacing24,
        AppConstants.spacing32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Word header
          Row(
            children: [
              Text(word.word, style: AppTypography.headlineLarge),
              const SizedBox(width: AppConstants.spacing12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacing8,
                  vertical: AppConstants.spacing4,
                ),
                decoration: BoxDecoration(
                  color: ScoreUtils.colorForScore(word.accuracyScore)
                      .withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: Text(
                  '${word.accuracyScore.round()}',
                  style: AppTypography.monoMedium.copyWith(
                    color: ScoreUtils.colorForScore(word.accuracyScore),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          if (word.errorType != 'None') ...[
            const SizedBox(height: AppConstants.spacing8),
            Text(
              ScoreUtils.errorTypeLabel(word.errorType),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.scorePoor,
              ),
            ),
          ],

          const SizedBox(height: AppConstants.spacing24),

          // Phoneme breakdown
          Text(
            'Phoneme Breakdown',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: AppConstants.spacing12),

          if (word.phonemes.isEmpty)
            Text(
              'No phoneme data available.',
              style: AppTypography.bodySmall,
            )
          else
            Wrap(
              spacing: AppConstants.spacing8,
              runSpacing: AppConstants.spacing8,
              children: word.phonemes.map((phoneme) {
                final color = ScoreUtils.colorForScore(phoneme.accuracyScore);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacing12,
                    vertical: AppConstants.spacing8,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                    border: Border.all(
                      color: color.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        phoneme.phoneme,
                        style: AppTypography.monoLarge.copyWith(color: color),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${phoneme.accuracyScore.round()}',
                        style: AppTypography.monoSmall.copyWith(
                          color: color.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: AppConstants.spacing24),

          // Hint
          if (word.phonemes.any((p) => p.accuracyScore < 80))
            Container(
              padding: const EdgeInsets.all(AppConstants.spacing16),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusMedium),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: AppConstants.spacing12),
                  Expanded(
                    child: Text(
                      _buildHint(),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _buildHint() {
    final weakPhonemes = word.phonemes
        .where((p) => p.accuracyScore < 80)
        .map((p) => '/${p.phoneme}/')
        .toList();

    if (weakPhonemes.isEmpty) return 'This word was pronounced well.';

    return 'Focus on the ${weakPhonemes.join(', ')} sound${weakPhonemes.length > 1 ? 's' : ''}. '
        'Try slowing down and emphasizing ${weakPhonemes.length > 1 ? 'these sounds' : 'this sound'} '
        'when you practice.';
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/score_utils.dart';
import '../../domain/entities/word_detail.dart';

class PhonemeBottomSheet extends StatelessWidget {
  const PhonemeBottomSheet({super.key, required this.word});

  final WordDetail word;

  Color _errorTypeBadgeColor(String errorType) {
    switch (errorType) {
      case 'Omission':
        return AppColors.errorOmission;
      case 'Insertion':
        return AppColors.errorInsertion;
      case 'Mispronunciation':
        return AppColors.errorMispronunciation;
      default:
        return AppColors.scoreGood;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSyllables = word.syllables.isNotEmpty;
    final prosody = word.prosodyFeedback;
    final hasProsodyIssues = prosody != null && prosody.hasAnyError;

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
              Expanded(
                child: Text(word.word, style: AppTypography.headlineLarge),
              ),
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
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacing8,
                vertical: AppConstants.spacing4,
              ),
              decoration: BoxDecoration(
                color: _errorTypeBadgeColor(word.errorType)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              ),
              child: Text(
                ScoreUtils.errorTypeLabel(word.errorType),
                style: AppTypography.labelMedium.copyWith(
                  color: _errorTypeBadgeColor(word.errorType),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          if (hasProsodyIssues) ...[
            const SizedBox(height: AppConstants.spacing12),
            _ProsodySection(prosody: prosody),
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
                return _ScoreChip(
                  label: phoneme.phoneme,
                  score: phoneme.accuracyScore,
                  color: color,
                  mono: true,
                  spokenPhoneme: phoneme.accuracyScore < 80
                      ? phoneme.topSpoken?.phoneme
                      : null,
                );
              }).toList(),
            ),

          if (hasSyllables) ...[
            const SizedBox(height: AppConstants.spacing24),
            Text(
              'Syllable Scores',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: AppConstants.spacing12),
            Wrap(
              spacing: AppConstants.spacing8,
              runSpacing: AppConstants.spacing8,
              children: word.syllables.map((syllable) {
                final color = ScoreUtils.colorForScore(syllable.accuracyScore);
                return _ScoreChip(
                  label: syllable.syllable,
                  score: syllable.accuracyScore,
                  color: color,
                  mono: false,
                );
              }).toList(),
            ),
          ],

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

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({
    required this.label,
    required this.score,
    required this.color,
    required this.mono,
    this.spokenPhoneme,
  });

  final String label;
  final double score;
  final Color color;
  final bool mono;
  final String? spokenPhoneme; // what the user actually said

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacing12,
        vertical: AppConstants.spacing8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: mono
                ? AppTypography.monoLarge.copyWith(color: color)
                : AppTypography.bodyMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
          ),
          const SizedBox(height: 2),
          Text(
            '${score.round()}',
            style: AppTypography.monoSmall.copyWith(
              color: color.withValues(alpha: 0.8),
            ),
          ),
          if (spokenPhoneme != null) ...[
            const SizedBox(height: 3),
            Text(
              '→ /$spokenPhoneme/',
              style: AppTypography.monoSmall.copyWith(
                color: AppColors.textTertiary,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProsodySection extends StatelessWidget {
  const _ProsodySection({required this.prosody});

  final ProsodyFeedback? prosody;

  @override
  Widget build(BuildContext context) {
    if (prosody == null) return const SizedBox.shrink();
    final breakErrors = prosody!.breakInfo.errorTypes
        .where((e) => e != 'None' && e.isNotEmpty)
        .toList();
    final intonationErrors = prosody!.intonation.errorTypes
        .where((e) => e != 'None' && e.isNotEmpty)
        .toList();

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing12),
      decoration: BoxDecoration(
        color: AppColors.prosodyWarning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(
          color: AppColors.prosodyWarning.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.graphic_eq_rounded,
                size: 14,
                color: AppColors.prosodyWarning,
              ),
              const SizedBox(width: AppConstants.spacing4),
              Text(
                'Prosody Feedback',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.prosodyWarning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (breakErrors.isNotEmpty ||
              prosody!.breakInfo.hasUnexpectedBreak ||
              prosody!.breakInfo.hasMissingBreak) ...[
            const SizedBox(height: AppConstants.spacing8),
            _ProsodyRow(
              icon: Icons.pause_circle_outline_rounded,
              label: 'Break',
              values: [
                ...breakErrors,
                if (prosody!.breakInfo.unexpectedBreakConfidence > 0 &&
                    prosody!.breakInfo.unexpectedBreakConfidence < 0.75)
                  'unexpected ${(prosody!.breakInfo.unexpectedBreakConfidence * 100).round()}%',
                if (prosody!.breakInfo.missingBreakConfidence > 0 &&
                    prosody!.breakInfo.missingBreakConfidence < 0.75)
                  'missing ${(prosody!.breakInfo.missingBreakConfidence * 100).round()}%',
              ],
            ),
          ],
          if (intonationErrors.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spacing4),
            _ProsodyRow(
              icon: Icons.show_chart_rounded,
              label: 'Intonation',
              values: intonationErrors,
            ),
          ],
          if (prosody!.intonation.monotoneConfidence > 0.5) ...[
            const SizedBox(height: AppConstants.spacing4),
            _ProsodyRow(
              icon: Icons.linear_scale_rounded,
              label: 'Monotone',
              values: [
                '${(prosody!.intonation.monotoneConfidence * 100).round()}%'
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProsodyRow extends StatelessWidget {
  const _ProsodyRow({
    required this.icon,
    required this.label,
    required this.values,
  });

  final IconData icon;
  final String label;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: AppConstants.spacing4),
        Text(
          '$label: ',
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            values.join(', '),
            style: AppTypography.bodySmall,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/score_utils.dart';
import '../../domain/entities/word_detail.dart';

class WordAnalysisView extends StatelessWidget {
  const WordAnalysisView({
    super.key,
    required this.words,
    required this.onWordTap,
  });

  final List<WordDetail> words;
  final ValueChanged<WordDetail> onWordTap;

  Color _badgeColor(String errorType) {
    switch (errorType) {
      case 'Omission':
        return AppColors.errorOmission;
      case 'Insertion':
        return AppColors.errorInsertion;
      case 'Mispronunciation':
        return AppColors.errorMispronunciation;
      default:
        return Colors.transparent;
    }
  }

  String _badgeLabel(String errorType) {
    switch (errorType) {
      case 'Omission':
        return 'skip';
      case 'Insertion':
        return 'extra';
      case 'Mispronunciation':
        return 'mis';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 12,
      children: words.map((word) {
        final underlineColor = ScoreUtils.wordUnderlineColor(
          word.accuracyScore,
          word.errorType,
        );
        final hasError = word.errorType != 'None';
        final badgeColor = _badgeColor(word.errorType);

        return GestureDetector(
          onTap: () => onWordTap(word),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 2, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: underlineColor,
                          width: word.isCorrect ? 1.5 : 2.5,
                        ),
                      ),
                    ),
                    child: Text(
                      word.word,
                      style: AppTypography.bodyLarge.copyWith(
                        color: word.errorType == 'Omission'
                            ? AppColors.textTertiary
                            : word.errorType == 'Insertion'
                                ? AppColors.errorInsertion
                                : AppColors.textPrimary,
                        decoration: word.errorType == 'Omission'
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: AppColors.errorOmission,
                      ),
                    ),
                  ),
                  if (hasError)
                    Positioned(
                      top: -8,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _badgeLabel(word.errorType),
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (hasError) ...[
                const SizedBox(height: 3),
                Text(
                  ScoreUtils.errorTypeLabel(word.errorType),
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 10,
                    color: badgeColor,
                    height: 1.2,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 8,
      children: words.map((word) {
        final underlineColor = ScoreUtils.wordUnderlineColor(
          word.accuracyScore,
          word.errorType,
        );

        return GestureDetector(
          onTap: () => onWordTap(word),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
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
                    : AppColors.textPrimary,
                decoration: word.errorType == 'Omission'
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

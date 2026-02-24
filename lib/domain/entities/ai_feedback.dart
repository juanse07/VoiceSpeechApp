import 'package:equatable/equatable.dart';

class AiFeedback extends Equatable {
  const AiFeedback({
    required this.summaryFeedback,
    required this.topIssues,
    required this.targetSounds,
    required this.stressPatternAdvice,
    required this.fluencyAdvice,
    required this.practiceExercises,
    required this.nativeLikeRewrite,
  });

  final String summaryFeedback;
  final List<String> topIssues;
  final List<String> targetSounds;
  final String stressPatternAdvice;
  final String fluencyAdvice;
  final List<String> practiceExercises;
  final String nativeLikeRewrite;

  factory AiFeedback.empty() => const AiFeedback(
        summaryFeedback: '',
        topIssues: [],
        targetSounds: [],
        stressPatternAdvice: '',
        fluencyAdvice: '',
        practiceExercises: [],
        nativeLikeRewrite: '',
      );

  @override
  List<Object?> get props => [
        summaryFeedback,
        topIssues,
        targetSounds,
        stressPatternAdvice,
        fluencyAdvice,
        practiceExercises,
        nativeLikeRewrite,
      ];
}

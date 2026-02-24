import 'package:equatable/equatable.dart';

class PhonemeDetail extends Equatable {
  const PhonemeDetail({
    required this.phoneme,
    required this.accuracyScore,
    this.offsetMs = 0,
    this.durationMs = 0,
  });

  final String phoneme;
  final double accuracyScore;
  final int offsetMs;
  final int durationMs;

  @override
  List<Object?> get props => [phoneme, accuracyScore, offsetMs, durationMs];
}

class WordDetail extends Equatable {
  const WordDetail({
    required this.word,
    required this.accuracyScore,
    required this.errorType,
    required this.phonemes,
    this.offsetMs = 0,
    this.durationMs = 0,
  });

  final String word;
  final double accuracyScore;
  final String errorType; // None, Omission, Insertion, Mispronunciation
  final List<PhonemeDetail> phonemes;
  final int offsetMs;
  final int durationMs;

  bool get isCorrect => errorType == 'None' && accuracyScore >= 80;
  bool get needsWork =>
      errorType == 'Mispronunciation' ||
      (errorType == 'None' && accuracyScore >= 60 && accuracyScore < 80);
  bool get isIncorrect =>
      errorType == 'Omission' ||
      errorType == 'Insertion' ||
      accuracyScore < 60;

  @override
  List<Object?> get props =>
      [word, accuracyScore, errorType, phonemes, offsetMs, durationMs];
}

import 'package:equatable/equatable.dart';

class NBestPhoneme extends Equatable {
  const NBestPhoneme({required this.phoneme, required this.score});

  final String phoneme;
  final double score;

  @override
  List<Object?> get props => [phoneme, score];
}

class PhonemeDetail extends Equatable {
  const PhonemeDetail({
    required this.phoneme,
    required this.accuracyScore,
    this.nBestPhonemes = const [],
    this.offsetMs = 0,
    this.durationMs = 0,
  });

  final String phoneme;
  final double accuracyScore;
  final List<NBestPhoneme> nBestPhonemes;
  final int offsetMs;
  final int durationMs;

  /// The top alternative phoneme that was actually spoken (if different from expected).
  NBestPhoneme? get topSpoken {
    if (nBestPhonemes.isEmpty) return null;
    final top = nBestPhonemes.first;
    return top.phoneme != phoneme ? top : null;
  }

  @override
  List<Object?> get props =>
      [phoneme, accuracyScore, nBestPhonemes, offsetMs, durationMs];
}

class SyllableDetail extends Equatable {
  const SyllableDetail({
    required this.syllable,
    required this.accuracyScore,
    this.offsetMs = 0,
    this.durationMs = 0,
  });

  final String syllable;
  final double accuracyScore;
  final int offsetMs;
  final int durationMs;

  @override
  List<Object?> get props => [syllable, accuracyScore, offsetMs, durationMs];
}

class ProsodyBreak extends Equatable {
  const ProsodyBreak({
    required this.errorTypes,
    this.breakLength = 0,
    this.unexpectedBreakConfidence = 0.0,
    this.missingBreakConfidence = 0.0,
  });

  final List<String> errorTypes;
  final int breakLength;
  final double unexpectedBreakConfidence;
  final double missingBreakConfidence;

  static const double _threshold = 0.75;

  bool get hasError => errorTypes.any((e) => e != 'None' && e.isNotEmpty);
  bool get hasUnexpectedBreak => unexpectedBreakConfidence >= _threshold;
  bool get hasMissingBreak => missingBreakConfidence >= _threshold;

  @override
  List<Object?> get props => [
        errorTypes,
        breakLength,
        unexpectedBreakConfidence,
        missingBreakConfidence,
      ];
}

class ProsodyIntonation extends Equatable {
  const ProsodyIntonation({
    required this.errorTypes,
    this.monotoneConfidence = 0.0,
  });

  final List<String> errorTypes;
  final double monotoneConfidence;

  bool get hasError => errorTypes.any((e) => e != 'None' && e.isNotEmpty);

  @override
  List<Object?> get props => [errorTypes, monotoneConfidence];
}

class ProsodyFeedback extends Equatable {
  const ProsodyFeedback({
    required this.breakInfo,
    required this.intonation,
  });

  final ProsodyBreak breakInfo;
  final ProsodyIntonation intonation;

  bool get hasAnyError => breakInfo.hasError || intonation.hasError;

  @override
  List<Object?> get props => [breakInfo, intonation];
}

class WordDetail extends Equatable {
  const WordDetail({
    required this.word,
    required this.accuracyScore,
    required this.errorType,
    required this.phonemes,
    this.syllables = const [],
    this.prosodyFeedback,
    this.offsetMs = 0,
    this.durationMs = 0,
  });

  final String word;
  final double accuracyScore;
  final String errorType; // None, Omission, Insertion, Mispronunciation
  final List<PhonemeDetail> phonemes;
  final List<SyllableDetail> syllables;
  final ProsodyFeedback? prosodyFeedback;
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
  List<Object?> get props => [
        word,
        accuracyScore,
        errorType,
        phonemes,
        syllables,
        prosodyFeedback,
        offsetMs,
        durationMs,
      ];
}

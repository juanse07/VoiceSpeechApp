import 'package:equatable/equatable.dart';
import 'word_detail.dart';

class PronunciationAssessment extends Equatable {
  const PronunciationAssessment({
    required this.overallScore,
    required this.accuracyScore,
    required this.fluencyScore,
    required this.completenessScore,
    required this.prosodyScore,
    required this.recognizedText,
    required this.words,
    required this.audioFilePath,
    required this.referenceText,
    required this.durationMs,
    this.pronScore = 0.0,
  });

  final double overallScore;
  final double accuracyScore;
  final double fluencyScore;
  final double completenessScore;
  final double prosodyScore;
  final double pronScore;
  final String recognizedText;
  final List<WordDetail> words;
  final String audioFilePath;
  final String referenceText;
  final int durationMs;

  /// Spoken words per minute, derived from word count and session duration.
  double get wordsPerMinute {
    if (durationMs <= 0 || words.isEmpty) return 0;
    final spoken = words.where((w) => w.errorType != 'Omission').length;
    return spoken / (durationMs / 60000.0);
  }

  @override
  List<Object?> get props => [
        overallScore,
        accuracyScore,
        fluencyScore,
        completenessScore,
        prosodyScore,
        pronScore,
        recognizedText,
        words,
        audioFilePath,
        referenceText,
        durationMs,
      ];
}

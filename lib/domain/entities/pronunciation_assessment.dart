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
  });

  final double overallScore;
  final double accuracyScore;
  final double fluencyScore;
  final double completenessScore;
  final double prosodyScore;
  final String recognizedText;
  final List<WordDetail> words;
  final String audioFilePath;
  final String referenceText;
  final int durationMs;

  @override
  List<Object?> get props => [
        overallScore,
        accuracyScore,
        fluencyScore,
        completenessScore,
        prosodyScore,
        recognizedText,
        words,
        audioFilePath,
        referenceText,
        durationMs,
      ];
}

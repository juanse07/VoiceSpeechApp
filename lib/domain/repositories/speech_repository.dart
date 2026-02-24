import '../entities/pronunciation_assessment.dart';

abstract class SpeechRepository {
  /// Assess pronunciation of [audioFilePath] against [referenceText].
  Future<PronunciationAssessment> assessPronunciation({
    required String audioFilePath,
    required String referenceText,
    required String language,
  });

  /// Transcribe speech from [audioFilePath] without reference text (free speech).
  Future<PronunciationAssessment> transcribeAndAssess({
    required String audioFilePath,
    required String language,
  });
}

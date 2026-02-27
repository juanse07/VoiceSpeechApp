import '../../domain/entities/pronunciation_assessment.dart';

/// Common interface for all speech assessment backends.
abstract class SpeechAssessmentService {
  Future<PronunciationAssessment> assessPronunciation({
    required String audioFilePath,
    required String referenceText,
    required String language,
  });

  Future<PronunciationAssessment> transcribeAndAssess({
    required String audioFilePath,
    required String language,
  });
}

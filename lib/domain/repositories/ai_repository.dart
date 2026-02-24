import '../entities/ai_feedback.dart';
import '../entities/pronunciation_assessment.dart';

abstract class AiRepository {
  /// Get AI coaching feedback for a pronunciation assessment.
  Future<AiFeedback> getFeedback({
    required PronunciationAssessment assessment,
    String? userNativeLanguage,
  });
}

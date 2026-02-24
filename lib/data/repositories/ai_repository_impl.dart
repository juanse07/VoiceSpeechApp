import '../../domain/entities/ai_feedback.dart';
import '../../domain/entities/pronunciation_assessment.dart';
import '../../domain/repositories/ai_repository.dart';
import '../services/groq_service.dart';

class AiRepositoryImpl implements AiRepository {
  AiRepositoryImpl({required this.groqService});

  final GroqService groqService;

  @override
  Future<AiFeedback> getFeedback({
    required PronunciationAssessment assessment,
    String? userNativeLanguage,
  }) {
    return groqService.getFeedback(
      assessment: assessment,
      userNativeLanguage: userNativeLanguage,
    );
  }
}

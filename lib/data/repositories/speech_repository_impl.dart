import '../../domain/entities/pronunciation_assessment.dart';
import '../../domain/repositories/speech_repository.dart';
import '../services/azure_speech_service.dart';

class SpeechRepositoryImpl implements SpeechRepository {
  SpeechRepositoryImpl({required this.speechService});

  final AzureSpeechService speechService;

  @override
  Future<PronunciationAssessment> assessPronunciation({
    required String audioFilePath,
    required String referenceText,
    required String language,
  }) {
    return speechService.assessPronunciation(
      audioFilePath: audioFilePath,
      referenceText: referenceText,
      language: language,
    );
  }

  @override
  Future<PronunciationAssessment> transcribeAndAssess({
    required String audioFilePath,
    required String language,
  }) {
    return speechService.transcribeAndAssess(
      audioFilePath: audioFilePath,
      language: language,
    );
  }
}

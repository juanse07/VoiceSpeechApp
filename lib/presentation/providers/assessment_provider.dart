import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../../data/repositories/speech_repository_impl.dart';
import '../../data/services/audio_service.dart';
import '../../data/services/azure_speech_service.dart';
import '../../data/services/groq_service.dart';
import '../../domain/entities/ai_feedback.dart';
import '../../domain/entities/pronunciation_assessment.dart';
import '../../domain/entities/session.dart';
import 'settings_provider.dart';

enum AssessmentPhase { idle, recording, processing, done, error }

class AssessmentState {
  const AssessmentState({
    this.phase = AssessmentPhase.idle,
    this.assessment,
    this.aiFeedback,
    this.errorMessage,
    this.recordingDuration = Duration.zero,
    this.isLoadingFeedback = false,
  });

  final AssessmentPhase phase;
  final PronunciationAssessment? assessment;
  final AiFeedback? aiFeedback;
  final String? errorMessage;
  final Duration recordingDuration;
  final bool isLoadingFeedback;

  AssessmentState copyWith({
    AssessmentPhase? phase,
    PronunciationAssessment? assessment,
    AiFeedback? aiFeedback,
    String? errorMessage,
    Duration? recordingDuration,
    bool? isLoadingFeedback,
  }) {
    return AssessmentState(
      phase: phase ?? this.phase,
      assessment: assessment ?? this.assessment,
      aiFeedback: aiFeedback ?? this.aiFeedback,
      errorMessage: errorMessage ?? this.errorMessage,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      isLoadingFeedback: isLoadingFeedback ?? this.isLoadingFeedback,
    );
  }
}

class AssessmentNotifier extends StateNotifier<AssessmentState> {
  AssessmentNotifier(this._ref) : super(const AssessmentState()) {
    _audioService.initialize();
  }

  final Ref _ref;
  final AudioService _audioService = AudioService();
  String? _recordingPath;

  AudioService get audioService => _audioService;

  Future<void> startRecording() async {
    try {
      _recordingPath = await _audioService.startRecording();
      state = state.copyWith(
        phase: AssessmentPhase.recording,
        errorMessage: null,
        assessment: null,
        aiFeedback: null,
      );
    } catch (e) {
      state = state.copyWith(
        phase: AssessmentPhase.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> stopAndAssess({required String referenceText}) async {
    try {
      final filePath = await _audioService.stopRecording();
      state = state.copyWith(phase: AssessmentPhase.processing);

      final settings = _ref.read(settingsProvider);
      final speechService = AzureSpeechService(
        subscriptionKey: settings.azureKey,
        region: settings.azureRegion,
      );
      final repo = SpeechRepositoryImpl(speechService: speechService);

      final assessment = await repo.assessPronunciation(
        audioFilePath: filePath,
        referenceText: referenceText,
        language: settings.language,
      );

      state = state.copyWith(
        phase: AssessmentPhase.done,
        assessment: assessment,
      );

      // Save to history
      _saveSession(assessment, SessionMode.text);

      // Fetch AI feedback in background
      _fetchAiFeedback(assessment);
    } catch (e) {
      state = state.copyWith(
        phase: AssessmentPhase.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> stopAndAssessFreeSpeech() async {
    try {
      final filePath = await _audioService.stopRecording();
      state = state.copyWith(phase: AssessmentPhase.processing);

      final settings = _ref.read(settingsProvider);
      final speechService = AzureSpeechService(
        subscriptionKey: settings.azureKey,
        region: settings.azureRegion,
      );
      final repo = SpeechRepositoryImpl(speechService: speechService);

      final assessment = await repo.transcribeAndAssess(
        audioFilePath: filePath,
        language: settings.language,
      );

      state = state.copyWith(
        phase: AssessmentPhase.done,
        assessment: assessment,
      );

      _saveSession(assessment, SessionMode.freeSpeech);
      _fetchAiFeedback(assessment);
    } catch (e) {
      state = state.copyWith(
        phase: AssessmentPhase.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _fetchAiFeedback(PronunciationAssessment assessment) async {
    final settings = _ref.read(settingsProvider);
    if (!settings.isGroqConfigured) return;

    state = state.copyWith(isLoadingFeedback: true);

    try {
      final groqService = GroqService(apiKey: settings.groqKey);
      final repo = AiRepositoryImpl(groqService: groqService);
      final feedback = await repo.getFeedback(assessment: assessment);

      state = state.copyWith(
        aiFeedback: feedback,
        isLoadingFeedback: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingFeedback: false);
    }
  }

  Future<void> _saveSession(
      PronunciationAssessment assessment, SessionMode mode) async {
    final repo = HistoryRepositoryImpl();
    final session = Session(
      id: const Uuid().v4(),
      mode: mode,
      overallScore: assessment.overallScore,
      accuracyScore: assessment.accuracyScore,
      fluencyScore: assessment.fluencyScore,
      completenessScore: assessment.completenessScore,
      prosodyScore: assessment.prosodyScore,
      referenceText: assessment.referenceText,
      recognizedText: assessment.recognizedText,
      audioFilePath: assessment.audioFilePath,
      durationMs: assessment.durationMs,
      createdAt: DateTime.now(),
    );
    await repo.saveSession(session);
  }

  void reset() {
    state = const AssessmentState();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}

final assessmentProvider =
    StateNotifierProvider<AssessmentNotifier, AssessmentState>((ref) {
  return AssessmentNotifier(ref);
});

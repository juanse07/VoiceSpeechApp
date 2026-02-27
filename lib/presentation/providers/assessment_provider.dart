import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../../data/repositories/speech_repository_impl.dart';
import '../../data/services/audio_service.dart';
import '../../data/services/azure_speech_service.dart';
import '../../data/services/azure_tts_service.dart';
import '../../data/services/speech_assessment_service.dart';
import '../../data/services/speech_super_service.dart';
import '../../data/services/ai_chat_service.dart';
import '../../domain/entities/ai_feedback.dart';
import '../../domain/entities/pronunciation_assessment.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/word_error.dart';
import 'settings_provider.dart';

enum AssessmentPhase { idle, recording, processing, done, error }

class AssessmentState {
  const AssessmentState({
    this.phase = AssessmentPhase.idle,
    this.assessment,
    this.aiFeedback,
    this.errorMessage,
    this.aiFeedbackError,
    this.recordingDuration = Duration.zero,
    this.isLoadingFeedback = false,
    this.isLoadingTts = false,
    this.ttsAudioPath,
  });

  final AssessmentPhase phase;
  final PronunciationAssessment? assessment;
  final AiFeedback? aiFeedback;
  final String? errorMessage;
  final String? aiFeedbackError;
  final Duration recordingDuration;
  final bool isLoadingFeedback;
  final bool isLoadingTts;
  final String? ttsAudioPath;

  AssessmentState copyWith({
    AssessmentPhase? phase,
    PronunciationAssessment? assessment,
    AiFeedback? aiFeedback,
    String? errorMessage,
    String? aiFeedbackError,
    Duration? recordingDuration,
    bool? isLoadingFeedback,
    bool? isLoadingTts,
    String? ttsAudioPath,
  }) {
    return AssessmentState(
      phase: phase ?? this.phase,
      assessment: assessment ?? this.assessment,
      aiFeedback: aiFeedback ?? this.aiFeedback,
      errorMessage: errorMessage ?? this.errorMessage,
      aiFeedbackError: aiFeedbackError ?? this.aiFeedbackError,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      isLoadingFeedback: isLoadingFeedback ?? this.isLoadingFeedback,
      isLoadingTts: isLoadingTts ?? this.isLoadingTts,
      ttsAudioPath: ttsAudioPath ?? this.ttsAudioPath,
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
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  AudioService get audioService => _audioService;

  Future<void> startRecording() async {
    try {
      _recordingPath = await _audioService.startRecording();
      _recordingSeconds = 0;
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingSeconds++;
        state = state.copyWith(
          recordingDuration: Duration(seconds: _recordingSeconds),
        );
        if (_recordingSeconds >= AppConstants.maxRecordingDurationSeconds) {
          stopAndAssessFreeSpeech();
        }
      });
      state = state.copyWith(
        phase: AssessmentPhase.recording,
        recordingDuration: Duration.zero,
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
      final repo = SpeechRepositoryImpl(speechService: _buildSpeechService(settings));

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
    _recordingTimer?.cancel();
    _recordingTimer = null;
    try {
      final filePath = await _audioService.stopRecording();
      state = state.copyWith(phase: AssessmentPhase.processing);

      final settings = _ref.read(settingsProvider);
      final repo = SpeechRepositoryImpl(speechService: _buildSpeechService(settings));

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

  Future<void> synthesizeReference() async {
    final assessment = state.assessment;
    if (assessment == null || assessment.referenceText.isEmpty) return;

    final settings = _ref.read(settingsProvider);
    if (!settings.isAzureConfigured) return;

    state = state.copyWith(isLoadingTts: true);
    try {
      final ttsService = AzureTtsService(
        subscriptionKey: settings.azureKey,
        region: settings.azureRegion,
      );
      final path = await ttsService.synthesize(
        text: assessment.referenceText,
        language: settings.language,
      );
      state = state.copyWith(isLoadingTts: false, ttsAudioPath: path);
    } catch (_) {
      state = state.copyWith(isLoadingTts: false);
    }
  }

  SpeechAssessmentService _buildSpeechService(AppSettings settings) {
    if (settings.speechApiProvider == SpeechApiProvider.speechsuper) {
      return SpeechSuperService(
        appKey: settings.speechSuperAppKey,
        secretKey: settings.speechSuperSecretKey,
      );
    }
    return AzureSpeechService(
      subscriptionKey: settings.azureKey,
      region: settings.azureRegion,
    );
  }

  Future<void> _fetchAiFeedback(PronunciationAssessment assessment) async {
    final settings = _ref.read(settingsProvider);
    if (!settings.isAzureFoundryConfigured) return;

    state = state.copyWith(isLoadingFeedback: true);

    try {
      final aiService = AiChatService(
        endpoint: settings.azureFoundryEndpoint,
        apiKey: settings.azureFoundryKey,
        model: settings.azureFoundryModel,
      );
      final repo = AiRepositoryImpl(aiChatService: aiService);
      final feedback = await repo.getFeedback(assessment: assessment);

      state = state.copyWith(
        aiFeedback: feedback,
        isLoadingFeedback: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingFeedback: false,
        aiFeedbackError: e.toString(),
      );
    }
  }

  Future<void> _saveSession(
      PronunciationAssessment assessment, SessionMode mode) async {
    final wordErrors = assessment.words
        .where((w) => w.errorType != 'None' || w.accuracyScore < 70)
        .take(20)
        .map((w) => WordError(
              word: w.word,
              errorType: w.errorType,
              weakPhonemes: w.phonemes
                  .where((p) => p.accuracyScore < 80)
                  .map((p) => p.phoneme)
                  .toList(),
              accuracyScore: w.accuracyScore,
            ))
        .toList();

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
      wordErrors: wordErrors,
      wordsPerMinute: assessment.wordsPerMinute,
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

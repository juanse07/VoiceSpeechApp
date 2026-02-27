import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/pattern_analyzer.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../../data/services/ai_chat_service.dart';
import '../../domain/entities/pattern_data.dart';
import 'settings_provider.dart';

class PatternState {
  const PatternState({
    this.isLoading = false,
    this.patternData,
    this.summary,
    this.isLoadingSummary = false,
    this.errorMessage,
  });

  final bool isLoading;
  final PatternData? patternData;
  final PatternSummary? summary;
  final bool isLoadingSummary;
  final String? errorMessage;

  PatternState copyWith({
    bool? isLoading,
    PatternData? patternData,
    PatternSummary? summary,
    bool? isLoadingSummary,
    String? errorMessage,
  }) {
    return PatternState(
      isLoading: isLoading ?? this.isLoading,
      patternData: patternData ?? this.patternData,
      summary: summary ?? this.summary,
      isLoadingSummary: isLoadingSummary ?? this.isLoadingSummary,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class PatternNotifier extends StateNotifier<PatternState> {
  PatternNotifier(this._ref) : super(const PatternState());

  final Ref _ref;

  Future<void> loadPatterns() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = HistoryRepositoryImpl();
      final sessions = await repo.getAllSessions();
      if (sessions.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }
      final data = PatternAnalyzer.analyze(sessions);
      state = state.copyWith(isLoading: false, patternData: data);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> generateSummary() async {
    final data = state.patternData;
    if (data == null) return;

    final settings = _ref.read(settingsProvider);
    if (!settings.isAzureFoundryConfigured) return;

    state = state.copyWith(isLoadingSummary: true);

    try {
      final aiService = AiChatService(
        endpoint: settings.azureFoundryEndpoint,
        apiKey: settings.azureFoundryKey,
        model: settings.azureFoundryModel,
      );

      final prompt = _buildPrompt(data);
      final raw = await aiService.chat([
        {
          'role': 'system',
          'content':
              'You are a professional pronunciation coach. Give concise, actionable coaching advice in plain English. '
                  'No emojis, no bullet headers, no markdown. Write 3-5 sentences maximum.',
        },
        {'role': 'user', 'content': prompt},
      ]);

      state = state.copyWith(
        isLoadingSummary: false,
        summary: PatternSummary(
          summary: raw.trim(),
          generatedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingSummary: false,
        errorMessage: e.toString(),
      );
    }
  }

  String _buildPrompt(PatternData data) {
    final sb = StringBuffer();
    sb.writeln('Pronunciation coaching data from ${data.sessionCount} sessions:');

    if (data.topMispronounced.isNotEmpty) {
      final words = data.topMispronounced
          .take(5)
          .map((e) => '${e.key}(${e.value}x)')
          .join(', ');
      sb.writeln('Most mispronounced words: $words');
    }

    if (data.topWeakPhonemes.isNotEmpty) {
      final phonemes = data.topWeakPhonemes
          .take(5)
          .map((e) => '${e.key}(${e.value}x)')
          .join(', ');
      sb.writeln('Weakest phonemes: $phonemes');
    }

    final counts = data.errorTypeCounts;
    sb.writeln(
        'Error breakdown — Mispronunciations: ${counts['Mispronunciation']}, '
        'Omissions: ${counts['Omission']}, Insertions: ${counts['Insertion']}');

    if (data.overallScoreTrend.length >= 2) {
      final first = data.overallScoreTrend.first.toStringAsFixed(1);
      final last = data.overallScoreTrend.last.toStringAsFixed(1);
      sb.writeln('Score trend: $first → $last');
    }

    if (data.sessionCount >= 6) {
      final wpm = data.wpmTrend.toStringAsFixed(1);
      sb.writeln('Speed change: ${wpm.startsWith('-') ? '' : '+'}$wpm WPM');
    }

    sb.writeln('\nProvide specific coaching advice based on these patterns.');
    return sb.toString();
  }
}

final patternProvider =
    StateNotifierProvider<PatternNotifier, PatternState>((ref) {
  return PatternNotifier(ref);
});

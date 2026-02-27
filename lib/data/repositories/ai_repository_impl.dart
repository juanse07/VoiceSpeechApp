import 'dart:convert';
import '../../domain/entities/ai_feedback.dart';
import '../../domain/entities/pronunciation_assessment.dart';
import '../../domain/repositories/ai_repository.dart';
import '../services/ai_chat_service.dart';

class AiRepositoryImpl implements AiRepository {
  AiRepositoryImpl({required this.aiChatService});

  final AiChatService aiChatService;

  @override
  Future<AiFeedback> getFeedback({
    required PronunciationAssessment assessment,
    String? userNativeLanguage,
  }) async {
    final wordErrors = assessment.words
        .where((w) => w.errorType != 'None' || w.accuracyScore < 80)
        .map((w) => {
              'word': w.word,
              'accuracy': w.accuracyScore,
              'error_type': w.errorType,
              'phonemes': w.phonemes
                  .where((p) => p.accuracyScore < 80)
                  .map((p) => {'phoneme': p.phoneme, 'accuracy': p.accuracyScore})
                  .toList(),
            })
        .toList();

    final payload = {
      'transcript': assessment.recognizedText,
      'pronunciation_scores': {
        'overall': assessment.overallScore,
        'accuracy': assessment.accuracyScore,
        'fluency': assessment.fluencyScore,
        'completeness': assessment.completenessScore,
        'prosody': assessment.prosodyScore,
      },
      'word_errors': wordErrors,
      'fluency_score': assessment.fluencyScore,
      'prosody_score': assessment.prosodyScore,
      if (userNativeLanguage != null)
        'user_native_language': userNativeLanguage,
    };

    const systemPrompt =
        'You are a professional pronunciation coach. Analyze the pronunciation assessment data and return structured JSON feedback.\n\n'
        'Be direct, professional, and coaching-focused. No emojis. No fluff. No exaggerated enthusiasm.\n\n'
        'Return ONLY valid JSON with this exact structure:\n'
        '{\n'
        '  "summary_feedback": "2-3 sentence overall assessment",\n'
        '  "top_issues": ["issue 1", "issue 2", "issue 3"],\n'
        '  "target_sounds": ["sound 1", "sound 2"],\n'
        '  "stress_pattern_advice": "advice on stress and rhythm",\n'
        '  "fluency_advice": "advice on pacing and flow",\n'
        '  "practice_exercises": ["exercise 1", "exercise 2", "exercise 3"],\n'
        '  "native_like_rewrite": "how a native speaker would naturally say key phrases"\n'
        '}';

    final raw = await aiChatService.chat([
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': jsonEncode(payload)},
    ]);

    final parsed = parseAiFeedbackJson(raw);
    return _parseFeedback(parsed);
  }

  AiFeedback _parseFeedback(Map<String, dynamic> raw) {
    // Unwrap if model wrapped everything under a single key (e.g. {"feedback": {...}})
    Map<String, dynamic> data = raw;
    if (raw.length == 1) {
      final only = raw.values.first;
      if (only is Map<String, dynamic>) data = only;
    }

    return AiFeedback(
      summaryFeedback: _str(data, ['summary_feedback', 'summaryFeedback', 'summary', 'overall_feedback', 'overall']),
      topIssues: _toStringList(data['top_issues'] ?? data['topIssues'] ?? data['issues'] ?? data['key_issues']),
      targetSounds: _toStringList(data['target_sounds'] ?? data['targetSounds'] ?? data['sounds'] ?? data['phonemes_to_practice']),
      stressPatternAdvice: _str(data, ['stress_pattern_advice', 'stressPatternAdvice', 'stress_advice', 'stress_and_rhythm', 'rhythm_advice']),
      fluencyAdvice: _str(data, ['fluency_advice', 'fluencyAdvice', 'fluency', 'pacing_advice']),
      practiceExercises: _toStringList(data['practice_exercises'] ?? data['practiceExercises'] ?? data['exercises'] ?? data['recommendations']),
      nativeLikeRewrite: _str(data, ['native_like_rewrite', 'nativeLikeRewrite', 'rewrite', 'native_rewrite', 'natural_phrasing']),
    );
  }

  String _str(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v is String && v.isNotEmpty) return v;
    }
    return '';
  }

  List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }
}

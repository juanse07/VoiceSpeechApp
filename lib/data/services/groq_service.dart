import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/ai_feedback.dart';
import '../../domain/entities/pronunciation_assessment.dart';

class GroqService {
  GroqService({required this.apiKey, Dio? dio}) : _dio = dio ?? Dio();

  final String apiKey;
  final Dio _dio;

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

    final systemPrompt = '''You are a professional pronunciation coach. Analyze the pronunciation assessment data and return structured JSON feedback.

Be direct, professional, and coaching-focused. No emojis. No fluff. No exaggerated enthusiasm.

Return ONLY valid JSON with this exact structure:
{
  "summary_feedback": "2-3 sentence overall assessment",
  "top_issues": ["issue 1", "issue 2", "issue 3"],
  "target_sounds": ["sound 1", "sound 2"],
  "stress_pattern_advice": "advice on stress and rhythm",
  "fluency_advice": "advice on pacing and flow",
  "practice_exercises": ["exercise 1", "exercise 2", "exercise 3"],
  "native_like_rewrite": "how a native speaker would naturally say key phrases"
}''';

    final response = await _dio.post<Map<String, dynamic>>(
      AppConstants.groqEndpoint,
      data: {
        'model': AppConstants.groqModel,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {
            'role': 'user',
            'content': jsonEncode(payload),
          },
        ],
        'temperature': 0.3,
        'max_tokens': 1024,
        'response_format': {'type': 'json_object'},
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      ),
    );

    final content = response.data?['choices']?[0]?['message']?['content'];
    if (content == null) {
      throw Exception('No response from Groq API.');
    }

    final parsed = jsonDecode(content as String) as Map<String, dynamic>;
    return _parseFeedback(parsed);
  }

  AiFeedback _parseFeedback(Map<String, dynamic> data) {
    return AiFeedback(
      summaryFeedback: data['summary_feedback'] as String? ?? '',
      topIssues: _toStringList(data['top_issues']),
      targetSounds: _toStringList(data['target_sounds']),
      stressPatternAdvice: data['stress_pattern_advice'] as String? ?? '',
      fluencyAdvice: data['fluency_advice'] as String? ?? '',
      practiceExercises: _toStringList(data['practice_exercises']),
      nativeLikeRewrite: data['native_like_rewrite'] as String? ?? '',
    );
  }

  List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }
}

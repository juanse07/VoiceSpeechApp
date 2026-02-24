import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../domain/entities/pronunciation_assessment.dart';
import '../../domain/entities/word_detail.dart';

class AzureSpeechService {
  AzureSpeechService({
    required this.subscriptionKey,
    required this.region,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final String subscriptionKey;
  final String region;
  final Dio _dio;

  String get _baseUrl =>
      'https://$region.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1';

  /// Assess pronunciation with reference text (Text Mode).
  Future<PronunciationAssessment> assessPronunciation({
    required String audioFilePath,
    required String referenceText,
    required String language,
  }) async {
    final pronunciationConfig = {
      'ReferenceText': referenceText,
      'GradingSystem': 'HundredMark',
      'Granularity': 'Phoneme',
      'EnableMiscue': true,
      'EnableProsodyAssessment': true,
    };

    final configBase64 =
        base64Encode(utf8.encode(jsonEncode(pronunciationConfig)));

    final audioBytes = await File(audioFilePath).readAsBytes();

    final response = await _dio.post<Map<String, dynamic>>(
      '$_baseUrl?language=$language&format=detailed',
      data: Stream.fromIterable([audioBytes]),
      options: Options(
        headers: {
          'Ocp-Apim-Subscription-Key': subscriptionKey,
          'Content-Type': 'audio/wav; codecs=audio/pcm; samplerate=16000',
          'Pronunciation-Assessment': configBase64,
          'Accept': 'application/json',
        },
        responseType: ResponseType.json,
      ),
    );

    return _parseAssessmentResponse(
      response.data!,
      audioFilePath,
      referenceText,
    );
  }

  /// Free speech mode — transcribe and assess without reference text.
  Future<PronunciationAssessment> transcribeAndAssess({
    required String audioFilePath,
    required String language,
  }) async {
    // First pass: transcribe to get text
    final audioBytes = await File(audioFilePath).readAsBytes();

    final transcribeResponse = await _dio.post<Map<String, dynamic>>(
      '$_baseUrl?language=$language&format=detailed',
      data: Stream.fromIterable([audioBytes]),
      options: Options(
        headers: {
          'Ocp-Apim-Subscription-Key': subscriptionKey,
          'Content-Type': 'audio/wav; codecs=audio/pcm; samplerate=16000',
          'Accept': 'application/json',
        },
        responseType: ResponseType.json,
      ),
    );

    final transcribedText =
        transcribeResponse.data?['DisplayText'] as String? ?? '';

    if (transcribedText.isEmpty) {
      throw Exception('No speech detected. Please try again.');
    }

    // Second pass: assess pronunciation against transcribed text
    return assessPronunciation(
      audioFilePath: audioFilePath,
      referenceText: transcribedText,
      language: language,
    );
  }

  PronunciationAssessment _parseAssessmentResponse(
    Map<String, dynamic> data,
    String audioFilePath,
    String referenceText,
  ) {
    final nBest = (data['NBest'] as List?)?.first as Map<String, dynamic>?;
    if (nBest == null) {
      throw Exception('No assessment data returned from Azure.');
    }

    final pa =
        nBest['PronunciationAssessment'] as Map<String, dynamic>? ?? {};

    final wordsJson = nBest['Words'] as List? ?? [];
    final words = wordsJson.map((w) {
      final wMap = w as Map<String, dynamic>;
      final wPa =
          wMap['PronunciationAssessment'] as Map<String, dynamic>? ?? {};
      final phonemesJson = wMap['Phonemes'] as List? ?? [];

      final phonemes = phonemesJson.map((p) {
        final pMap = p as Map<String, dynamic>;
        final pPa =
            pMap['PronunciationAssessment'] as Map<String, dynamic>? ?? {};
        return PhonemeDetail(
          phoneme: pMap['Phoneme'] as String? ?? '',
          accuracyScore: (pPa['AccuracyScore'] as num?)?.toDouble() ?? 0,
          offsetMs:
              ((pMap['Offset'] as num?)?.toInt() ?? 0) ~/ 10000, // ticks to ms
          durationMs:
              ((pMap['Duration'] as num?)?.toInt() ?? 0) ~/ 10000,
        );
      }).toList();

      return WordDetail(
        word: wMap['Word'] as String? ?? '',
        accuracyScore: (wPa['AccuracyScore'] as num?)?.toDouble() ?? 0,
        errorType: wPa['ErrorType'] as String? ?? 'None',
        phonemes: phonemes,
        offsetMs: ((wMap['Offset'] as num?)?.toInt() ?? 0) ~/ 10000,
        durationMs: ((wMap['Duration'] as num?)?.toInt() ?? 0) ~/ 10000,
      );
    }).toList();

    final accuracy = (pa['AccuracyScore'] as num?)?.toDouble() ?? 0;
    final fluency = (pa['FluencyScore'] as num?)?.toDouble() ?? 0;
    final completeness = (pa['CompletenessScore'] as num?)?.toDouble() ?? 0;
    final prosody = (pa['ProsodyScore'] as num?)?.toDouble() ?? 0;
    final overall = (accuracy + fluency + completeness + prosody) / 4;

    final displayText = data['DisplayText'] as String? ?? referenceText;
    final durationTicks = (data['Duration'] as num?)?.toInt() ?? 0;

    return PronunciationAssessment(
      overallScore: overall,
      accuracyScore: accuracy,
      fluencyScore: fluency,
      completenessScore: completeness,
      prosodyScore: prosody,
      recognizedText: displayText,
      words: words,
      audioFilePath: audioFilePath,
      referenceText: referenceText,
      durationMs: durationTicks ~/ 10000,
    );
  }
}

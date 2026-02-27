import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../../domain/entities/pronunciation_assessment.dart';
import '../../domain/entities/word_detail.dart';
import 'speech_assessment_service.dart';

/// SpeechSuper pronunciation assessment service.
///
/// TODO: Fill in [_coreTypeSentence] and [_coreTypeFree] once you confirm
/// the exact coreType strings from your SpeechSuper API docs.
///
/// TODO: Verify the signature algorithm and request format in [_post] against
/// the official API documentation before going live.
class SpeechSuperService implements SpeechAssessmentService {
  SpeechSuperService({
    required this.appKey,
    required this.secretKey,
  });

  final String appKey;
  final String secretKey;

  // TODO: Confirm base URL from your API docs (may differ by region/plan)
  static const _baseUrl = 'https://api.speechsuper.com';

  // TODO: Confirm coreType strings from API docs
  static const _coreTypeSentence = 'sent.eval.promax';
  static const _coreTypeFree = 'speak.eval.pro';

  /// Builds HMAC-SHA1 signature.
  /// TODO: Verify exact input string format against API docs.
  String _buildSig(String timestamp) {
    final key = utf8.encode(secretKey);
    final message = utf8.encode(appKey + timestamp);
    final hmac = Hmac(sha1, key);
    return base64Encode(hmac.convert(message).bytes);
  }

  Future<Map<String, dynamic>> _post({
    required String coreType,
    required Uint8List audioBytes,
    required Map<String, dynamic> params,
  }) async {
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final sig = _buildSig(timestamp);

    // TODO: Verify multipart field names and structure against API docs
    final boundary = '----SpeechSuperBoundary';
    final paramsJson = jsonEncode({
      'appkey': appKey,
      'request_id': DateTime.now().millisecondsSinceEpoch.toString(),
      'params': params,
    });

    final bodyParts = StringBuffer();
    bodyParts.write('--$boundary\r\n');
    bodyParts.write('Content-Disposition: form-data; name="text"\r\n\r\n');
    bodyParts.write('$paramsJson\r\n');
    bodyParts.write('--$boundary\r\n');
    bodyParts.write(
        'Content-Disposition: form-data; name="audio"; filename="audio.wav"\r\n');
    bodyParts.write('Content-Type: audio/wav\r\n\r\n');

    final bodyPrefix = utf8.encode(bodyParts.toString());
    final bodySuffix = utf8.encode('\r\n--$boundary--\r\n');

    final fullBody = Uint8List(
        bodyPrefix.length + audioBytes.length + bodySuffix.length);
    fullBody.setRange(0, bodyPrefix.length, bodyPrefix);
    fullBody.setRange(
        bodyPrefix.length, bodyPrefix.length + audioBytes.length, audioBytes);
    fullBody.setRange(
        bodyPrefix.length + audioBytes.length, fullBody.length, bodySuffix);

    final uri = Uri.parse('$_baseUrl/$coreType');
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      // TODO: Verify header names against API docs
      request.headers.set('Content-Type', 'multipart/form-data; boundary=$boundary');
      request.headers.set('appkey', appKey);
      request.headers.set('timestamp', timestamp);
      request.headers.set('sig', sig);
      request.contentLength = fullBody.length;
      request.add(fullBody);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      return jsonDecode(body) as Map<String, dynamic>;
    } finally {
      client.close();
    }
  }

  @override
  Future<PronunciationAssessment> assessPronunciation({
    required String audioFilePath,
    required String referenceText,
    required String language,
  }) async {
    final audioBytes = await File(audioFilePath).readAsBytes();

    // TODO: Confirm param field names from API docs
    final data = await _post(
      coreType: _coreTypeSentence,
      audioBytes: audioBytes,
      params: {
        'coreType': _coreTypeSentence,
        'refText': referenceText,
        'audioType': 'wav',
        'audioSampleRate': 16000,
        'language': language,
      },
    );

    return _parseResponse(data, audioFilePath, referenceText);
  }

  @override
  Future<PronunciationAssessment> transcribeAndAssess({
    required String audioFilePath,
    required String language,
  }) async {
    final audioBytes = await File(audioFilePath).readAsBytes();

    // TODO: Confirm param field names from API docs
    final data = await _post(
      coreType: _coreTypeFree,
      audioBytes: audioBytes,
      params: {
        'coreType': _coreTypeFree,
        'audioType': 'wav',
        'audioSampleRate': 16000,
        'language': language,
      },
    );

    return _parseResponse(data, audioFilePath, '');
  }

  PronunciationAssessment _parseResponse(
    Map<String, dynamic> data,
    String audioFilePath,
    String referenceText,
  ) {
    // TODO: Map SpeechSuper response fields to PronunciationAssessment.
    // Adjust field names below once you have the actual API response schema.
    //
    // Typical SpeechSuper response structure (verify against docs):
    // {
    //   "status": 0,
    //   "requestId": "...",
    //   "result": {
    //     "pronunciation": { "score": 85.5 },
    //     "fluency":       { "score": 78.2 },
    //     "integrity":     { "score": 92.1 },
    //     "rhythm":        { "score": 80.0 },
    //     "overall":       { "score": 84.0 },
    //     "transcript":    "hello world",
    //     "words": [
    //       {
    //         "text": "hello",
    //         "pronunciation": { "score": 90.0 },
    //         "errorType": "None",
    //         "phonemes": [ { "text": "HH", "pronunciation": { "score": 95.0 } } ]
    //       }
    //     ]
    //   }
    // }

    final status = data['status'] as int? ?? -1;
    if (status != 0) {
      throw Exception(
          'SpeechSuper error ${data['status']}: ${data['message'] ?? 'Unknown error'}');
    }

    final result = data['result'] as Map<String, dynamic>? ?? {};

    // TODO: Adjust these field paths to match actual API response
    double scoreFor(String key) {
      final node = result[key] as Map<String, dynamic>?;
      return (node?['score'] as num?)?.toDouble() ?? 0.0;
    }

    final accuracy = scoreFor('pronunciation');
    final fluency = scoreFor('fluency');
    final completeness = scoreFor('integrity');
    final prosody = scoreFor('rhythm');
    final overall = scoreFor('overall');
    final transcript = result['transcript'] as String? ?? referenceText;

    // TODO: Parse words/phonemes once response schema is confirmed
    final words = _parseWords(result['words'] as List? ?? []);

    return PronunciationAssessment(
      overallScore: overall > 0
          ? overall
          : [accuracy, fluency, completeness, prosody]
              .where((s) => s > 0)
              .fold(0.0, (a, b) => a + b) /
              [accuracy, fluency, completeness, prosody]
                  .where((s) => s > 0)
                  .length
                  .clamp(1, 4),
      accuracyScore: accuracy,
      fluencyScore: fluency,
      completenessScore: completeness,
      prosodyScore: prosody,
      pronScore: overall,
      recognizedText: transcript,
      words: words,
      audioFilePath: audioFilePath,
      referenceText: referenceText,
      durationMs: 0, // TODO: map duration if API provides it
    );
  }

  List<WordDetail> _parseWords(List<dynamic> rawWords) {
    // TODO: Adjust field paths once API response schema is confirmed
    return rawWords.map((w) {
      final wMap = w as Map<String, dynamic>;
      final wPron = wMap['pronunciation'] as Map<String, dynamic>?;
      final accuracyScore = (wPron?['score'] as num?)?.toDouble() ?? 0.0;

      final phonemes = ((wMap['phonemes'] as List?) ?? []).map((p) {
        final pMap = p as Map<String, dynamic>;
        final pPron = pMap['pronunciation'] as Map<String, dynamic>?;
        return PhonemeDetail(
          phoneme: pMap['text'] as String? ?? '',
          accuracyScore: (pPron?['score'] as num?)?.toDouble() ?? 0.0,
          offsetMs: 0,
          durationMs: 0,
        );
      }).toList();

      return WordDetail(
        word: wMap['text'] as String? ?? '',
        accuracyScore: accuracyScore,
        errorType: wMap['errorType'] as String? ?? 'None',
        phonemes: phonemes,
        syllables: [],
        prosodyFeedback: null,
        offsetMs: 0,
        durationMs: 0,
      );
    }).toList();
  }
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../../domain/entities/pronunciation_assessment.dart';
import '../../domain/entities/word_detail.dart';
import 'speech_assessment_service.dart';

class AzureSpeechService implements SpeechAssessmentService {
  AzureSpeechService({
    required this.subscriptionKey,
    required this.region,
  });

  final String subscriptionKey;
  final String region;

  static const int _chunkSeconds = 30;
  static const int _sampleRate = 16000;
  static const int _bytesPerSample = 2;
  static const int _channels = 1;
  static const int _bytesPerSecond = _sampleRate * _bytesPerSample * _channels;

  String get _baseUrl =>
      'https://$region.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1';

  Future<Map<String, dynamic>> _post({
    required String url,
    required List<int> audioBytes,
    required Map<String, String> headers,
  }) async {
    final uri = Uri.parse(url);
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      headers.forEach((key, value) => request.headers.set(key, value));
      request.contentLength = audioBytes.length;
      request.add(audioBytes);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (body.isEmpty) {
        throw Exception('Azure returned empty response (HTTP ${response.statusCode})');
      }
      return jsonDecode(body) as Map<String, dynamic>;
    } finally {
      client.close();
    }
  }

  List<Uint8List> _splitWav(Uint8List wavBytes) {
    const int headerSize = 44;
    final int chunkDataSize = _chunkSeconds * _bytesPerSecond;
    if (wavBytes.length <= headerSize) return [wavBytes];

    final audioData = wavBytes.sublist(headerSize);
    final List<Uint8List> chunks = [];
    int offset = 0;

    while (offset < audioData.length) {
      final int end = (offset + chunkDataSize).clamp(0, audioData.length);
      if (end <= offset) break;
      chunks.add(_buildWav(audioData.sublist(offset, end)));
      offset = end;
    }

    return chunks.isEmpty ? [wavBytes] : chunks;
  }

  Uint8List _buildWav(Uint8List audioData) {
    const int byteRate = _bytesPerSecond;
    const int blockAlign = _channels * _bytesPerSample;
    final int dataSize = audioData.length;

    final header = ByteData(44);
    // RIFF
    header.setUint8(0, 0x52); header.setUint8(1, 0x49);
    header.setUint8(2, 0x46); header.setUint8(3, 0x46);
    header.setUint32(4, dataSize + 36, Endian.little);
    // WAVE
    header.setUint8(8, 0x57); header.setUint8(9, 0x41);
    header.setUint8(10, 0x56); header.setUint8(11, 0x45);
    // fmt
    header.setUint8(12, 0x66); header.setUint8(13, 0x6D);
    header.setUint8(14, 0x74); header.setUint8(15, 0x20);
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little); // PCM
    header.setUint16(22, _channels, Endian.little);
    header.setUint32(24, _sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, 16, Endian.little); // bits per sample
    // data
    header.setUint8(36, 0x64); header.setUint8(37, 0x61);
    header.setUint8(38, 0x74); header.setUint8(39, 0x61);
    header.setUint32(40, dataSize, Endian.little);

    final result = Uint8List(44 + dataSize);
    result.setRange(0, 44, header.buffer.asUint8List());
    result.setRange(44, 44 + dataSize, audioData);
    return result;
  }

  @override
  Future<PronunciationAssessment> assessPronunciation({
    required String audioFilePath,
    required String referenceText,
    required String language,
  }) async {
    final audioBytes = await File(audioFilePath).readAsBytes();
    return _assessBytes(
      audioBytes: audioBytes,
      referenceText: referenceText,
      language: language,
      audioFilePath: audioFilePath,
    );
  }

  Future<PronunciationAssessment> _assessBytes({
    required Uint8List audioBytes,
    required String referenceText,
    required String language,
    required String audioFilePath,
  }) async {
    final config = {
      'ReferenceText': referenceText,
      'GradingSystem': 'HundredMark',
      'Granularity': 'Phoneme',
      'Dimension': 'Comprehensive',
      'EnableMiscue': 'True',
      'EnableProsodyAssessment': 'True',
      'PhonemeAlphabet': 'IPA',
      'NBestPhonemeCount': 5,
    };
    final configBase64 = base64Encode(utf8.encode(jsonEncode(config)));

    final data = await _post(
      url: '$_baseUrl?language=$language&format=detailed',
      audioBytes: audioBytes,
      headers: {
        'Ocp-Apim-Subscription-Key': subscriptionKey,
        'Content-Type': 'audio/wav; codecs=audio/pcm; samplerate=16000',
        'Pronunciation-Assessment': configBase64,
        'Accept': 'application/json',
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
    final chunks = _splitWav(audioBytes);
    final results = <PronunciationAssessment>[];
    int chunkOffsetMs = 0;

    for (final chunk in chunks) {
      final transcribeData = await _post(
        url: '$_baseUrl?language=$language&format=detailed',
        audioBytes: chunk,
        headers: {
          'Ocp-Apim-Subscription-Key': subscriptionKey,
          'Content-Type': 'audio/wav; codecs=audio/pcm; samplerate=16000',
          'Accept': 'application/json',
        },
      );

      final transcribedText = transcribeData['DisplayText'] as String? ?? '';
      if (transcribedText.isEmpty) {
        chunkOffsetMs += _chunkSeconds * 1000;
        continue;
      }

      final assessment = await _assessBytes(
        audioBytes: chunk,
        referenceText: transcribedText,
        language: language,
        audioFilePath: audioFilePath,
      );

      final adjustedWords = assessment.words.map((w) => WordDetail(
            word: w.word,
            accuracyScore: w.accuracyScore,
            errorType: w.errorType,
            phonemes: w.phonemes,
            syllables: w.syllables,
            prosodyFeedback: w.prosodyFeedback,
            offsetMs: w.offsetMs + chunkOffsetMs,
            durationMs: w.durationMs,
          )).toList();

      results.add(PronunciationAssessment(
        overallScore: assessment.overallScore,
        accuracyScore: assessment.accuracyScore,
        fluencyScore: assessment.fluencyScore,
        completenessScore: assessment.completenessScore,
        prosodyScore: assessment.prosodyScore,
        pronScore: assessment.pronScore,
        recognizedText: assessment.recognizedText,
        words: adjustedWords,
        audioFilePath: audioFilePath,
        referenceText: assessment.referenceText,
        durationMs: assessment.durationMs,
      ));

      chunkOffsetMs += _chunkSeconds * 1000;
    }

    if (results.isEmpty) {
      throw Exception('No speech detected. Please try again.');
    }

    return _aggregate(results, audioFilePath);
  }

  PronunciationAssessment _aggregate(
    List<PronunciationAssessment> results,
    String audioFilePath,
  ) {
    if (results.length == 1) return results.first;

    final totalWords = results.fold<int>(0, (s, r) => s + r.words.length);
    final allWords = <WordDetail>[];
    final textParts = <String>[];
    double accuracy = 0, fluency = 0, completeness = 0, prosody = 0, pronScore = 0;
    int totalDuration = 0;

    for (final r in results) {
      final w = totalWords > 0 ? r.words.length / totalWords : 1.0 / results.length;
      accuracy += r.accuracyScore * w;
      fluency += r.fluencyScore * w;
      completeness += r.completenessScore * w;
      prosody += r.prosodyScore * w;
      pronScore += r.pronScore * w;
      allWords.addAll(r.words);
      textParts.add(r.recognizedText);
      totalDuration += r.durationMs;
    }

    final effectivePronScore = pronScore > 0 ? pronScore : null;
    final scores = [accuracy, fluency, completeness, prosody].where((s) => s > 0).toList();
    final computedOverall = scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;
    final overall = effectivePronScore ?? computedOverall;

    return PronunciationAssessment(
      overallScore: overall,
      accuracyScore: accuracy,
      fluencyScore: fluency,
      completenessScore: completeness,
      prosodyScore: prosody,
      pronScore: pronScore,
      recognizedText: textParts.join(' '),
      words: allWords,
      audioFilePath: audioFilePath,
      referenceText: textParts.join(' '),
      durationMs: totalDuration,
    );
  }

  ProsodyFeedback? _parseProsodyFeedback(Map<String, dynamic> wMap) {
    final feedback = wMap['Feedback'] as Map<String, dynamic>?;
    if (feedback == null) return null;

    final prosody = feedback['Prosody'] as Map<String, dynamic>?;
    if (prosody == null) return null;

    final breakMap = prosody['Break'] as Map<String, dynamic>?;
    final intonationMap = prosody['Intonation'] as Map<String, dynamic>?;

    final breakErrorTypes = ((breakMap?['ErrorTypes'] as List?) ?? [])
        .map((e) => e as String)
        .toList();
    final breakLength = (breakMap?['BreakLength'] as num?)?.toInt() ?? 0;
    final unexpectedBreak = breakMap?['UnexpectedBreak'] as Map<String, dynamic>?;
    final missingBreak = breakMap?['MissingBreak'] as Map<String, dynamic>?;
    final unexpectedConf = (unexpectedBreak?['Confidence'] as num?)?.toDouble() ?? 0.0;
    final missingConf = (missingBreak?['Confidence'] as num?)?.toDouble() ?? 0.0;

    final intonationErrorTypes = ((intonationMap?['ErrorTypes'] as List?) ?? [])
        .map((e) => e as String)
        .toList();
    final monotone = intonationMap?['Monotone'] as Map<String, dynamic>?;
    final monotoneConfidence = (monotone?['Confidence'] as num?)?.toDouble() ?? 0.0;

    return ProsodyFeedback(
      breakInfo: ProsodyBreak(
        errorTypes: breakErrorTypes,
        breakLength: breakLength,
        unexpectedBreakConfidence: unexpectedConf,
        missingBreakConfidence: missingConf,
      ),
      intonation: ProsodyIntonation(
        errorTypes: intonationErrorTypes,
        monotoneConfidence: monotoneConfidence,
      ),
    );
  }

  PronunciationAssessment _parseResponse(
    Map<String, dynamic> data,
    String audioFilePath,
    String referenceText,
  ) {
    final nBest = (data['NBest'] as List?)?.first as Map<String, dynamic>?;
    if (nBest == null) throw Exception('No assessment data returned from Azure.');

    final pa = nBest['PronunciationAssessment'] as Map<String, dynamic>?;

    final words = ((nBest['Words'] as List?) ?? []).map((w) {
      final wMap = w as Map<String, dynamic>;
      final wPa = wMap['PronunciationAssessment'] as Map<String, dynamic>?;

      final phonemes = ((wMap['Phonemes'] as List?) ?? []).map((p) {
        final pMap = p as Map<String, dynamic>;
        final pPa = pMap['PronunciationAssessment'] as Map<String, dynamic>?;
        final nBest = ((pPa?['NBestPhonemes'] as List?) ?? []).map((n) {
          final nMap = n as Map<String, dynamic>;
          return NBestPhoneme(
            phoneme: nMap['Phoneme'] as String? ?? '',
            score: (nMap['Score'] as num?)?.toDouble() ?? 0,
          );
        }).toList();
        return PhonemeDetail(
          phoneme: pMap['Phoneme'] as String? ?? '',
          accuracyScore: (pPa?['AccuracyScore'] as num? ?? pMap['AccuracyScore'] as num?)?.toDouble() ?? 0,
          nBestPhonemes: nBest,
          offsetMs: ((pMap['Offset'] as num?)?.toInt() ?? 0) ~/ 10000,
          durationMs: ((pMap['Duration'] as num?)?.toInt() ?? 0) ~/ 10000,
        );
      }).toList();

      final syllables = ((wMap['Syllables'] as List?) ?? []).map((s) {
        final sMap = s as Map<String, dynamic>;
        final sPa = sMap['PronunciationAssessment'] as Map<String, dynamic>?;
        return SyllableDetail(
          syllable: sMap['Syllable'] as String? ?? '',
          accuracyScore: (sPa?['AccuracyScore'] as num? ?? sMap['AccuracyScore'] as num?)?.toDouble() ?? 0,
          offsetMs: ((sMap['Offset'] as num?)?.toInt() ?? 0) ~/ 10000,
          durationMs: ((sMap['Duration'] as num?)?.toInt() ?? 0) ~/ 10000,
        );
      }).toList();

      final prosodyFeedback = _parseProsodyFeedback(wMap);

      return WordDetail(
        word: wMap['Word'] as String? ?? '',
        accuracyScore: (wPa?['AccuracyScore'] as num? ?? wMap['AccuracyScore'] as num?)?.toDouble() ?? 0,
        errorType: wPa?['ErrorType'] as String? ?? wMap['ErrorType'] as String? ?? 'None',
        phonemes: phonemes,
        syllables: syllables,
        prosodyFeedback: prosodyFeedback,
        offsetMs: ((wMap['Offset'] as num?)?.toInt() ?? 0) ~/ 10000,
        durationMs: ((wMap['Duration'] as num?)?.toInt() ?? 0) ~/ 10000,
      );
    }).toList();

    final accuracy = (pa?['AccuracyScore'] as num? ?? nBest['AccuracyScore'] as num?)?.toDouble() ?? 0;
    final fluency = (pa?['FluencyScore'] as num? ?? nBest['FluencyScore'] as num?)?.toDouble() ?? 0;
    final completeness = (pa?['CompletenessScore'] as num? ?? nBest['CompletenessScore'] as num?)?.toDouble() ?? 0;
    final prosody = (pa?['ProsodyScore'] as num? ?? nBest['ProsodyScore'] as num?)?.toDouble() ?? 0;
    final pronScore = (pa?['PronScore'] as num? ?? nBest['PronScore'] as num?)?.toDouble() ?? 0;

    final effectivePronScore = pronScore > 0 ? pronScore : null;
    final scores = [accuracy, fluency, completeness, prosody].where((s) => s > 0).toList();
    final computedOverall = scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;
    final overall = effectivePronScore ?? computedOverall;

    return PronunciationAssessment(
      overallScore: overall,
      accuracyScore: accuracy,
      fluencyScore: fluency,
      completenessScore: completeness,
      prosodyScore: prosody,
      pronScore: pronScore,
      recognizedText: data['DisplayText'] as String? ?? referenceText,
      words: words,
      audioFilePath: audioFilePath,
      referenceText: referenceText,
      durationMs: ((data['Duration'] as num?)?.toInt() ?? 0) ~/ 10000,
    );
  }
}

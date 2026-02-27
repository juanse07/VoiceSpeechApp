import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class AzureTtsService {
  AzureTtsService({required this.subscriptionKey, required this.region});

  final String subscriptionKey;
  final String region;

  String get _endpoint =>
      'https://$region.tts.speech.microsoft.com/cognitiveservices/v1';

  static const _voices = {
    'en-US': 'en-US-JennyNeural',
    'en-GB': 'en-GB-SoniaNeural',
    'es-ES': 'es-ES-ElviraNeural',
    'es-MX': 'es-MX-DaliaNeural',
    'fr-FR': 'fr-FR-DeniseNeural',
    'de-DE': 'de-DE-KatjaNeural',
    'it-IT': 'it-IT-ElsaNeural',
    'pt-BR': 'pt-BR-FranciscaNeural',
    'zh-CN': 'zh-CN-XiaoxiaoNeural',
    'ja-JP': 'ja-JP-NanamiNeural',
    'ko-KR': 'ko-KR-SunHiNeural',
  };

  /// Synthesizes [text] using Azure Neural TTS and saves it to a temp file.
  /// Returns the path to the generated audio file (WAV).
  Future<String> synthesize({
    required String text,
    required String language,
  }) async {
    final voice = _voices[language] ?? _voices['en-US']!;
    final ssml = '''
<speak version="1.0" xml:lang="$language">
  <voice name="$voice">$text</voice>
</speak>''';

    final uri = Uri.parse(_endpoint);
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      request.headers.set('Ocp-Apim-Subscription-Key', subscriptionKey);
      request.headers.set('Content-Type', 'application/ssml+xml');
      request.headers.set(
          'X-Microsoft-OutputFormat', 'riff-16khz-16bit-mono-pcm');
      request.headers.set('User-Agent', 'VoiceSpeechApp');

      final bodyBytes = ssml.codeUnits;
      request.contentLength = bodyBytes.length;
      request.add(bodyBytes);

      final response = await request.close();
      if (response.statusCode != 200) {
        final body = await response.transform(
            const SystemEncoding().decoder).join();
        throw Exception('TTS error ${response.statusCode}: $body');
      }

      final chunks = <List<int>>[];
      await for (final chunk in response) {
        chunks.add(chunk);
      }
      final bytes = Uint8List.fromList(chunks.expand((c) => c).toList());

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/tts_${const Uuid().v4().substring(0, 8)}.wav';
      await File(path).writeAsBytes(bytes);
      return path;
    } finally {
      client.close();
    }
  }
}

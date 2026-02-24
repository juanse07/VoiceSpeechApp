abstract final class AppConstants {
  // Azure Speech
  static const String azureSttEndpointTemplate =
      'https://{region}.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1';
  static const String azurePronunciationEndpointTemplate =
      'https://{region}.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1';
  static const int audioSampleRate = 16000;
  static const int audioBitDepth = 16;
  static const int audioChannels = 1;

  // Groq
  static const String groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const String groqModel = 'openai/oss-120b';

  // Audio
  static const int maxRecordingDurationSeconds = 300; // 5 minutes
  static const String audioFileExtension = '.wav';

  // UI
  static const double maxContentWidth = 600;
  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing32 = 32;
  static const double spacing40 = 40;
  static const double spacing48 = 48;
  static const double spacing64 = 64;
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;

  // Secure Storage Keys
  static const String keyAzureSubscription = 'azure_subscription_key';
  static const String keyAzureRegion = 'azure_region';
  static const String keyGroqApiKey = 'groq_api_key';
  static const String keyLanguage = 'language_code';
}

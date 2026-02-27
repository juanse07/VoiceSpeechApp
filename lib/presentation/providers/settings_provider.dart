import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';

enum SpeechApiProvider { azure, speechsuper }

class AppSettings {
  const AppSettings({
    this.azureKey = '',
    this.azureRegion = 'eastus',
    this.language = 'en-US',
    this.speechSuperAppKey = '',
    this.speechSuperSecretKey = '',
    this.speechApiProvider = SpeechApiProvider.azure,
    this.azureFoundryEndpoint = '',
    this.azureFoundryKey = '',
    this.azureFoundryModel = AppConstants.defaultAiModel,
  });

  final String azureKey;
  final String azureRegion;
  final String language;
  final String speechSuperAppKey;
  final String speechSuperSecretKey;
  final SpeechApiProvider speechApiProvider;
  final String azureFoundryEndpoint;
  final String azureFoundryKey;
  final String azureFoundryModel;

  bool get isAzureConfigured => azureKey.isNotEmpty && azureRegion.isNotEmpty;
  bool get isSpeechSuperConfigured =>
      speechSuperAppKey.isNotEmpty && speechSuperSecretKey.isNotEmpty;
  bool get isAzureFoundryConfigured =>
      azureFoundryEndpoint.isNotEmpty && azureFoundryKey.isNotEmpty;

  bool get isActiveSpeechProviderConfigured =>
      speechApiProvider == SpeechApiProvider.azure
          ? isAzureConfigured
          : isSpeechSuperConfigured;

  AppSettings copyWith({
    String? azureKey,
    String? azureRegion,
    String? language,
    String? speechSuperAppKey,
    String? speechSuperSecretKey,
    SpeechApiProvider? speechApiProvider,
    String? azureFoundryEndpoint,
    String? azureFoundryKey,
    String? azureFoundryModel,
  }) {
    return AppSettings(
      azureKey: azureKey ?? this.azureKey,
      azureRegion: azureRegion ?? this.azureRegion,
      language: language ?? this.language,
      speechSuperAppKey: speechSuperAppKey ?? this.speechSuperAppKey,
      speechSuperSecretKey: speechSuperSecretKey ?? this.speechSuperSecretKey,
      speechApiProvider: speechApiProvider ?? this.speechApiProvider,
      azureFoundryEndpoint: azureFoundryEndpoint ?? this.azureFoundryEndpoint,
      azureFoundryKey: azureFoundryKey ?? this.azureFoundryKey,
      azureFoundryModel: azureFoundryModel ?? this.azureFoundryModel,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  final _storage = const FlutterSecureStorage();

  Future<void> _load() async {
    final azureKey =
        await _storage.read(key: AppConstants.keyAzureSubscription) ?? '';
    final azureRegion =
        await _storage.read(key: AppConstants.keyAzureRegion) ?? 'eastus';
    final language =
        await _storage.read(key: AppConstants.keyLanguage) ?? 'en-US';
    final speechSuperAppKey =
        await _storage.read(key: AppConstants.keySpeechSuperAppKey) ?? '';
    final speechSuperSecretKey =
        await _storage.read(key: AppConstants.keySpeechSuperSecretKey) ?? '';
    final providerStr =
        await _storage.read(key: AppConstants.keySpeechApiProvider) ?? 'azure';
    final provider = providerStr == 'speechsuper'
        ? SpeechApiProvider.speechsuper
        : SpeechApiProvider.azure;
    final azureFoundryEndpoint =
        await _storage.read(key: AppConstants.keyAzureFoundryEndpoint) ?? '';
    final azureFoundryKey =
        await _storage.read(key: AppConstants.keyAzureFoundryKey) ?? '';
    final azureFoundryModel =
        await _storage.read(key: AppConstants.keyAzureFoundryModel) ??
            AppConstants.defaultAiModel;

    state = AppSettings(
      azureKey: azureKey,
      azureRegion: azureRegion,
      language: language,
      speechSuperAppKey: speechSuperAppKey,
      speechSuperSecretKey: speechSuperSecretKey,
      speechApiProvider: provider,
      azureFoundryEndpoint: azureFoundryEndpoint,
      azureFoundryKey: azureFoundryKey,
      azureFoundryModel: azureFoundryModel,
    );
  }

  Future<void> updateAzureKey(String key) async {
    await _storage.write(key: AppConstants.keyAzureSubscription, value: key);
    state = state.copyWith(azureKey: key);
  }

  Future<void> updateAzureRegion(String region) async {
    await _storage.write(key: AppConstants.keyAzureRegion, value: region);
    state = state.copyWith(azureRegion: region);
  }

  Future<void> updateLanguage(String language) async {
    await _storage.write(key: AppConstants.keyLanguage, value: language);
    state = state.copyWith(language: language);
  }

  Future<void> updateSpeechSuperAppKey(String key) async {
    await _storage.write(key: AppConstants.keySpeechSuperAppKey, value: key);
    state = state.copyWith(speechSuperAppKey: key);
  }

  Future<void> updateSpeechSuperSecretKey(String key) async {
    await _storage.write(
        key: AppConstants.keySpeechSuperSecretKey, value: key);
    state = state.copyWith(speechSuperSecretKey: key);
  }

  Future<void> updateSpeechApiProvider(SpeechApiProvider provider) async {
    await _storage.write(
      key: AppConstants.keySpeechApiProvider,
      value: provider == SpeechApiProvider.speechsuper ? 'speechsuper' : 'azure',
    );
    state = state.copyWith(speechApiProvider: provider);
  }

  Future<void> updateAzureFoundryEndpoint(String endpoint) async {
    await _storage.write(
        key: AppConstants.keyAzureFoundryEndpoint, value: endpoint);
    state = state.copyWith(azureFoundryEndpoint: endpoint);
  }

  Future<void> updateAzureFoundryKey(String key) async {
    await _storage.write(key: AppConstants.keyAzureFoundryKey, value: key);
    state = state.copyWith(azureFoundryKey: key);
  }

  Future<void> updateAzureFoundryModel(String model) async {
    await _storage.write(key: AppConstants.keyAzureFoundryModel, value: model);
    state = state.copyWith(azureFoundryModel: model);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

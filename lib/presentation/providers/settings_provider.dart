import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';

class AppSettings {
  const AppSettings({
    this.azureKey = '',
    this.azureRegion = 'eastus',
    this.groqKey = '',
    this.language = 'en-US',
  });

  final String azureKey;
  final String azureRegion;
  final String groqKey;
  final String language;

  bool get isAzureConfigured => azureKey.isNotEmpty && azureRegion.isNotEmpty;
  bool get isGroqConfigured => groqKey.isNotEmpty;

  AppSettings copyWith({
    String? azureKey,
    String? azureRegion,
    String? groqKey,
    String? language,
  }) {
    return AppSettings(
      azureKey: azureKey ?? this.azureKey,
      azureRegion: azureRegion ?? this.azureRegion,
      groqKey: groqKey ?? this.groqKey,
      language: language ?? this.language,
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
    final groqKey =
        await _storage.read(key: AppConstants.keyGroqApiKey) ?? '';
    final language =
        await _storage.read(key: AppConstants.keyLanguage) ?? 'en-US';

    state = AppSettings(
      azureKey: azureKey,
      azureRegion: azureRegion,
      groqKey: groqKey,
      language: language,
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

  Future<void> updateGroqKey(String key) async {
    await _storage.write(key: AppConstants.keyGroqApiKey, value: key);
    state = state.copyWith(groqKey: key);
  }

  Future<void> updateLanguage(String language) async {
    await _storage.write(key: AppConstants.keyLanguage, value: language);
    state = state.copyWith(language: language);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

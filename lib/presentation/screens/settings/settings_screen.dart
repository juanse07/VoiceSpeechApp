import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _azureKeyController;
  late TextEditingController _ssAppKeyController;
  late TextEditingController _ssSecretKeyController;
  late TextEditingController _foundryEndpointController;
  late TextEditingController _foundryKeyController;
  late TextEditingController _foundryModelController;
  bool _showAzureKey = false;
  bool _showSsAppKey = false;
  bool _showSsSecretKey = false;
  bool _showFoundryKey = false;

  static const _regions = [
    'eastus',
    'eastus2',
    'westus',
    'westus2',
    'westus3',
    'centralus',
    'northcentralus',
    'southcentralus',
    'westeurope',
    'northeurope',
    'uksouth',
    'southeastasia',
    'eastasia',
    'japaneast',
    'australiaeast',
    'canadacentral',
    'brazilsouth',
    'koreacentral',
    'centralindia',
    'francecentral',
  ];

  static const _languages = [
    ('en-US', 'English (US)'),
    ('en-GB', 'English (UK)'),
    ('es-ES', 'Spanish (Spain)'),
    ('es-MX', 'Spanish (Mexico)'),
    ('fr-FR', 'French (France)'),
    ('de-DE', 'German'),
    ('it-IT', 'Italian'),
    ('pt-BR', 'Portuguese (Brazil)'),
    ('zh-CN', 'Chinese (Mandarin)'),
    ('ja-JP', 'Japanese'),
    ('ko-KR', 'Korean'),
  ];

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _azureKeyController = TextEditingController(text: settings.azureKey);
    _ssAppKeyController =
        TextEditingController(text: settings.speechSuperAppKey);
    _ssSecretKeyController =
        TextEditingController(text: settings.speechSuperSecretKey);
    _foundryEndpointController =
        TextEditingController(text: settings.azureFoundryEndpoint);
    _foundryKeyController =
        TextEditingController(text: settings.azureFoundryKey);
    _foundryModelController =
        TextEditingController(text: settings.azureFoundryModel);
  }

  @override
  void dispose() {
    _azureKeyController.dispose();
    _ssAppKeyController.dispose();
    _ssSecretKeyController.dispose();
    _foundryEndpointController.dispose();
    _foundryKeyController.dispose();
    _foundryModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacing24),
        children: [
          // ── Speech Engine Selector ──────────────────────────────
          Text('Speech Engine', style: AppTypography.titleLarge),
          const SizedBox(height: AppConstants.spacing12),
          _ProviderToggle(
            selected: settings.speechApiProvider,
            onChanged: (p) => notifier.updateSpeechApiProvider(p),
          ),
          const SizedBox(height: AppConstants.spacing40),

          // ── Azure Speech Service ────────────────────────────────
          Text('Azure Speech Service', style: AppTypography.titleLarge),
          const SizedBox(height: AppConstants.spacing4),
          Text(
            'Required when Azure is selected as speech engine.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppConstants.spacing16),

          Text('Subscription Key', style: AppTypography.labelMedium),
          const SizedBox(height: AppConstants.spacing8),
          TextField(
            controller: _azureKeyController,
            obscureText: !_showAzureKey,
            onChanged: (v) => notifier.updateAzureKey(v.trim()),
            decoration: InputDecoration(
              hintText: 'Enter your Azure Speech key',
              suffixIcon: IconButton(
                icon: Icon(
                  _showAzureKey ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
                onPressed: () =>
                    setState(() => _showAzureKey = !_showAzureKey),
              ),
            ),
          ),

          const SizedBox(height: AppConstants.spacing16),

          Text('Region', style: AppTypography.labelMedium),
          const SizedBox(height: AppConstants.spacing8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: settings.azureRegion,
                isExpanded: true,
                style: AppTypography.bodyMedium,
                items: _regions
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) notifier.updateAzureRegion(v);
                },
              ),
            ),
          ),

          const SizedBox(height: AppConstants.spacing12),
          Text(
            'Get a free key at portal.azure.com — 5 free hours/month.',
            style: AppTypography.bodySmall,
          ),

          const SizedBox(height: AppConstants.spacing40),

          // ── SpeechSuper ─────────────────────────────────────────
          Text('SpeechSuper', style: AppTypography.titleLarge),
          const SizedBox(height: AppConstants.spacing4),
          Text(
            'Required when SpeechSuper is selected as speech engine.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppConstants.spacing16),

          Text('App Key', style: AppTypography.labelMedium),
          const SizedBox(height: AppConstants.spacing8),
          TextField(
            controller: _ssAppKeyController,
            obscureText: !_showSsAppKey,
            onChanged: (v) => notifier.updateSpeechSuperAppKey(v.trim()),
            decoration: InputDecoration(
              hintText: 'Enter your SpeechSuper App Key',
              suffixIcon: IconButton(
                icon: Icon(
                  _showSsAppKey ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
                onPressed: () =>
                    setState(() => _showSsAppKey = !_showSsAppKey),
              ),
            ),
          ),

          const SizedBox(height: AppConstants.spacing16),

          Text('Secret Key', style: AppTypography.labelMedium),
          const SizedBox(height: AppConstants.spacing8),
          TextField(
            controller: _ssSecretKeyController,
            obscureText: !_showSsSecretKey,
            onChanged: (v) => notifier.updateSpeechSuperSecretKey(v.trim()),
            decoration: InputDecoration(
              hintText: 'Enter your SpeechSuper Secret Key',
              suffixIcon: IconButton(
                icon: Icon(
                  _showSsSecretKey ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
                onPressed: () =>
                    setState(() => _showSsSecretKey = !_showSsSecretKey),
              ),
            ),
          ),

          const SizedBox(height: AppConstants.spacing12),
          Text(
            'Get keys at speechsuper.com.',
            style: AppTypography.bodySmall,
          ),

          const SizedBox(height: AppConstants.spacing40),

          // ── Language ────────────────────────────────────────────
          Text('Language', style: AppTypography.titleLarge),
          const SizedBox(height: AppConstants.spacing8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: settings.language,
                isExpanded: true,
                style: AppTypography.bodyMedium,
                items: _languages
                    .map((l) => DropdownMenuItem(
                          value: l.$1,
                          child: Text(l.$2),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) notifier.updateLanguage(v);
                },
              ),
            ),
          ),

          const SizedBox(height: AppConstants.spacing40),

          // ── Azure AI Foundry ─────────────────────────────────────
          Text('Azure AI Foundry', style: AppTypography.titleLarge),
          const SizedBox(height: AppConstants.spacing4),
          Text(
            'Optional. Enables AI coaching feedback (Phi-3) after assessment and pattern insights.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppConstants.spacing16),

          Text('Endpoint URL', style: AppTypography.labelMedium),
          const SizedBox(height: AppConstants.spacing8),
          TextField(
            controller: _foundryEndpointController,
            autocorrect: false,
            textCapitalization: TextCapitalization.none,
            onChanged: (v) => notifier.updateAzureFoundryEndpoint(v.trim()),
            decoration: const InputDecoration(
              hintText: 'https://api.groq.com/openai/v1/chat/completions',
            ),
          ),

          const SizedBox(height: AppConstants.spacing16),

          Text('API Key', style: AppTypography.labelMedium),
          const SizedBox(height: AppConstants.spacing8),
          TextField(
            controller: _foundryKeyController,
            obscureText: !_showFoundryKey,
            onChanged: (v) => notifier.updateAzureFoundryKey(v.trim()),
            decoration: InputDecoration(
              hintText: 'Enter your Azure AI Foundry key',
              suffixIcon: IconButton(
                icon: Icon(
                  _showFoundryKey ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
                onPressed: () =>
                    setState(() => _showFoundryKey = !_showFoundryKey),
              ),
            ),
          ),

          const SizedBox(height: AppConstants.spacing16),

          Text('Model', style: AppTypography.labelMedium),
          const SizedBox(height: AppConstants.spacing8),
          TextField(
            controller: _foundryModelController,
            autocorrect: false,
            textCapitalization: TextCapitalization.none,
            onChanged: (v) => notifier.updateAzureFoundryModel(v.trim()),
            decoration: const InputDecoration(
              hintText: 'llama-3.3-70b-versatile',
            ),
          ),

          const SizedBox(height: AppConstants.spacing12),
          Text(
            'Works with Groq (free tier), GitHub Models, Azure AI Foundry, or any OpenAI-compatible endpoint.',
            style: AppTypography.bodySmall,
          ),

          const SizedBox(height: AppConstants.spacing48),

          // ── Status ──────────────────────────────────────────────
          _StatusIndicator(
            label: 'Azure Speech',
            isConfigured: settings.isAzureConfigured,
            isActive: settings.speechApiProvider == SpeechApiProvider.azure,
          ),
          const SizedBox(height: AppConstants.spacing8),
          _StatusIndicator(
            label: 'SpeechSuper',
            isConfigured: settings.isSpeechSuperConfigured,
            isActive:
                settings.speechApiProvider == SpeechApiProvider.speechsuper,
          ),
          const SizedBox(height: AppConstants.spacing8),
          _StatusIndicator(
            label: 'Azure AI Foundry',
            isConfigured: settings.isAzureFoundryConfigured,
            isActive: false,
          ),

          const SizedBox(height: AppConstants.spacing48),
        ],
      ),
    );
  }
}

class _ProviderToggle extends StatelessWidget {
  const _ProviderToggle({
    required this.selected,
    required this.onChanged,
  });

  final SpeechApiProvider selected;
  final ValueChanged<SpeechApiProvider> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ToggleChip(
          label: 'Azure',
          selected: selected == SpeechApiProvider.azure,
          onTap: () => onChanged(SpeechApiProvider.azure),
        ),
        const SizedBox(width: AppConstants.spacing8),
        _ToggleChip(
          label: 'SpeechSuper',
          selected: selected == SpeechApiProvider.speechsuper,
          onTap: () => onChanged(SpeechApiProvider.speechsuper),
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacing16,
          vertical: AppConstants.spacing8,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: selected ? AppColors.white : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({
    required this.label,
    required this.isConfigured,
    required this.isActive,
  });

  final String label;
  final bool isConfigured;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isConfigured ? AppColors.scoreGood : AppColors.textTertiary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppConstants.spacing8),
        Text(
          '$label — ${isConfigured ? 'Connected' : 'Not configured'}',
          style: AppTypography.bodySmall.copyWith(
            color: isConfigured
                ? AppColors.scoreGood
                : AppColors.textTertiary,
          ),
        ),
        if (isActive) ...[
          const SizedBox(width: AppConstants.spacing8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Active',
              style: AppTypography.labelMedium.copyWith(
                fontSize: 10,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

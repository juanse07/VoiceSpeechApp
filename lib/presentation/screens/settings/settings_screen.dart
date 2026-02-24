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
  late TextEditingController _groqKeyController;
  bool _showAzureKey = false;
  bool _showGroqKey = false;

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
    _groqKeyController = TextEditingController(text: settings.groqKey);
  }

  @override
  void dispose() {
    _azureKeyController.dispose();
    _groqKeyController.dispose();
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
          // Azure Section
          Text('Azure Speech Service', style: AppTypography.titleLarge),
          const SizedBox(height: AppConstants.spacing4),
          Text(
            'Required for pronunciation assessment.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppConstants.spacing16),

          // API Key
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

          // Region
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

          const SizedBox(height: AppConstants.spacing16),

          // Language
          Text('Language', style: AppTypography.labelMedium),
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

          const SizedBox(height: AppConstants.spacing12),

          Text(
            'Get a free key at portal.azure.com — 5 free hours/month.',
            style: AppTypography.bodySmall,
          ),

          const SizedBox(height: AppConstants.spacing40),

          // Groq Section
          Text('Groq AI Feedback', style: AppTypography.titleLarge),
          const SizedBox(height: AppConstants.spacing4),
          Text(
            'Optional. Enables AI coaching feedback after assessment.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppConstants.spacing16),

          Text('API Key', style: AppTypography.labelMedium),
          const SizedBox(height: AppConstants.spacing8),
          TextField(
            controller: _groqKeyController,
            obscureText: !_showGroqKey,
            onChanged: (v) => notifier.updateGroqKey(v.trim()),
            decoration: InputDecoration(
              hintText: 'Enter your Groq API key',
              suffixIcon: IconButton(
                icon: Icon(
                  _showGroqKey ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
                onPressed: () =>
                    setState(() => _showGroqKey = !_showGroqKey),
              ),
            ),
          ),

          const SizedBox(height: AppConstants.spacing12),
          Text(
            'Get a free key at console.groq.com.',
            style: AppTypography.bodySmall,
          ),

          const SizedBox(height: AppConstants.spacing48),

          // Status
          _StatusIndicator(
            label: 'Azure Speech',
            isConfigured: settings.isAzureConfigured,
          ),
          const SizedBox(height: AppConstants.spacing8),
          _StatusIndicator(
            label: 'Groq AI',
            isConfigured: settings.isGroqConfigured,
          ),

          const SizedBox(height: AppConstants.spacing48),
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({
    required this.label,
    required this.isConfigured,
  });

  final String label;
  final bool isConfigured;

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
      ],
    );
  }
}

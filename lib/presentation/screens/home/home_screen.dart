import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/settings_provider.dart';
import '../text_mode/text_mode_screen.dart';
import '../free_speech/free_speech_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacing24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppConstants.spacing48),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pronounce', style: AppTypography.displayMedium),
                  Row(
                    children: [
                      _IconButton(
                        icon: Icons.history,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HistoryScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacing8),
                      _IconButton(
                        icon: Icons.settings_outlined,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.spacing8),
              Text(
                'Practice your pronunciation with precision.',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              // Config warning
              if (!settings.isAzureConfigured) ...[
                const SizedBox(height: AppConstants.spacing24),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(AppConstants.spacing16),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.08),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusMedium),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.key,
                          size: 18,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: AppConstants.spacing12),
                        Expanded(
                          child: Text(
                            'Add your Azure Speech key to get started.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const Spacer(),

              // Mode cards
              _ModeCard(
                title: 'Text Mode',
                description:
                    'Paste or type text, then read it aloud. Get word-by-word feedback.',
                isPrimary: true,
                onTap: settings.isAzureConfigured
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TextModeScreen(),
                          ),
                        )
                    : null,
              ),

              const SizedBox(height: AppConstants.spacing16),

              _ModeCard(
                title: 'Free Speech',
                description:
                    'Speak freely. Get transcription and pronunciation analysis.',
                isPrimary: false,
                onTap: settings.isAzureConfigured
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FreeSpeechScreen(),
                          ),
                        )
                    : null,
              ),

              const SizedBox(height: AppConstants.spacing64),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        ),
        child: Icon(icon, size: 20, color: AppColors.textSecondary),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.description,
    required this.isPrimary,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool isPrimary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: onTap != null ? 1.0 : 0.4,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppConstants.spacing24),
          decoration: BoxDecoration(
            color: isPrimary ? AppColors.black : AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            border: isPrimary
                ? null
                : Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.headlineLarge.copyWith(
                  color: isPrimary ? AppColors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppConstants.spacing8),
              Text(
                description,
                style: AppTypography.bodyMedium.copyWith(
                  color: isPrimary
                      ? AppColors.white.withValues(alpha: 0.7)
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.spacing16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacing16,
                  vertical: AppConstants.spacing8,
                ),
                decoration: BoxDecoration(
                  color: isPrimary
                      ? AppColors.accent
                      : AppColors.surfaceAlt,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: Text(
                  'Start',
                  style: AppTypography.labelLarge.copyWith(
                    color: isPrimary
                        ? AppColors.white
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

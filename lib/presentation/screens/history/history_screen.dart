import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/score_utils.dart';
import '../../../domain/entities/session.dart';
import '../../providers/history_provider.dart';
import '../patterns/patterns_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          historyAsync.maybeWhen(
            data: (sessions) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (sessions.length >= 3)
                    IconButton(
                      icon: const Icon(Icons.insights_rounded, size: 22),
                      tooltip: 'Insights',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PatternsScreen(),
                        ),
                      ),
                    ),
                  if (sessions.isNotEmpty)
                    TextButton(
                      onPressed: () => _confirmClear(context, ref),
                      child: Text(
                        'Clear',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accent,
          ),
        ),
        error: (e, _) => Center(
          child: Text(
            'Failed to load history.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No sessions yet.',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacing8),
                  Text(
                    'Complete a pronunciation exercise to see it here.',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              vertical: AppConstants.spacing16,
            ),
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              indent: AppConstants.spacing24,
              endIndent: AppConstants.spacing24,
            ),
            itemBuilder: (context, index) {
              final session = sessions[index];
              return _SessionTile(
                session: session,
                onDismissed: () =>
                    ref.read(historyProvider.notifier).deleteSession(session.id),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear History', style: AppTypography.titleLarge),
        content: Text(
          'This will delete all session records. This cannot be undone.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(historyProvider.notifier).clearAll();
              Navigator.pop(ctx);
            },
            child: Text(
              'Clear',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.scorePoor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.onDismissed,
  });

  final Session session;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy  HH:mm');

    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppConstants.spacing24),
        color: AppColors.scorePoor.withValues(alpha: 0.1),
        child: const Icon(Icons.delete_outline,
            color: AppColors.scorePoor, size: 20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacing24,
          vertical: AppConstants.spacing16,
        ),
        child: Row(
          children: [
            // Score
            SizedBox(
              width: 48,
              child: Text(
                session.overallScore.round().toString(),
                style: AppTypography.scoreMedium.copyWith(
                  color: ScoreUtils.colorForScore(session.overallScore),
                  fontSize: 22,
                ),
              ),
            ),

            const SizedBox(width: AppConstants.spacing16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.mode == SessionMode.text
                        ? 'Text Mode'
                        : 'Free Speech',
                    style: AppTypography.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _truncate(
                      session.referenceText.isNotEmpty
                          ? session.referenceText
                          : session.recognizedText,
                      60,
                    ),
                    style: AppTypography.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppConstants.spacing12),

            // Meta
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  dateFormat.format(session.createdAt),
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  session.formattedDuration,
                  style: AppTypography.monoSmall.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _truncate(String text, int maxLen) {
    if (text.length <= maxLen) return text;
    return '${text.substring(0, maxLen)}...';
  }
}

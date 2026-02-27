import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/pattern_data.dart';
import '../../providers/pattern_provider.dart';
import '../../providers/settings_provider.dart';

class PatternsScreen extends ConsumerStatefulWidget {
  const PatternsScreen({super.key});

  @override
  ConsumerState<PatternsScreen> createState() => _PatternsScreenState();
}

class _PatternsScreenState extends ConsumerState<PatternsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(patternProvider.notifier).loadPatterns();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patternProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accent,
              ),
            )
          : state.patternData == null
              ? Center(
                  child: Text(
                    'No data available.',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                )
              : _PatternsBody(
                  data: state.patternData!,
                  state: state,
                  isAzureFoundryConfigured: settings.isAzureFoundryConfigured,
                  onGenerateSummary: () =>
                      ref.read(patternProvider.notifier).generateSummary(),
                ),
    );
  }
}

class _PatternsBody extends StatelessWidget {
  const _PatternsBody({
    required this.data,
    required this.state,
    required this.isAzureFoundryConfigured,
    required this.onGenerateSummary,
  });

  final PatternData data;
  final PatternState state;
  final bool isAzureFoundryConfigured;
  final VoidCallback onGenerateSummary;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.spacing24),
      children: [
        // Score Trend (≥3 sessions)
        if (data.overallScoreTrend.length >= 3) ...[
          Text('Score Trend', style: AppTypography.titleLarge),
          const SizedBox(height: AppConstants.spacing12),
          _ScoreTrendChart(scores: data.overallScoreTrend),
          const SizedBox(height: AppConstants.spacing32),
        ],

        // Error Distribution
        if (data.errorTypeCounts.values.any((v) => v > 0)) ...[
          Text('Error Distribution', style: AppTypography.titleLarge),
          const SizedBox(height: AppConstants.spacing12),
          _ErrorPieChart(counts: data.errorTypeCounts),
          const SizedBox(height: AppConstants.spacing32),
        ],

        // Top Weak Phonemes
        if (data.topWeakPhonemes.isNotEmpty) ...[
          Text('Weak Phonemes', style: AppTypography.titleLarge),
          const SizedBox(height: AppConstants.spacing12),
          _PhonemeBarChart(phonemes: data.topWeakPhonemes.take(8).toList()),
          const SizedBox(height: AppConstants.spacing32),
        ],

        // Top Mispronounced Words
        if (data.topMispronounced.isNotEmpty) ...[
          Text('Mispronounced Words', style: AppTypography.titleLarge),
          const SizedBox(height: AppConstants.spacing12),
          _WordChips(words: data.topMispronounced),
          const SizedBox(height: AppConstants.spacing32),
        ],

        // WPM Trend (≥6 sessions)
        if (data.sessionCount >= 6) ...[
          _WpmTrendChip(wpmTrend: data.wpmTrend),
          const SizedBox(height: AppConstants.spacing32),
        ],

        // AI Coaching Card
        _PatternSummaryCard(
          state: state,
          isAzureFoundryConfigured: isAzureFoundryConfigured,
          onGenerate: onGenerateSummary,
        ),

        const SizedBox(height: AppConstants.spacing48),
      ],
    );
  }
}

// ── Score Trend Chart ─────────────────────────────────────────────────────────

class _ScoreTrendChart extends StatelessWidget {
  const _ScoreTrendChart({required this.scores});

  final List<double> scores;

  @override
  Widget build(BuildContext context) {
    final spots = scores
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.borderLight,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 25,
                reservedSize: 32,
                getTitlesWidget: (val, _) => Text(
                  val.toInt().toString(),
                  style: AppTypography.monoSmall
                      .copyWith(color: AppColors.textTertiary, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (scores.length / 4).ceilToDouble().clamp(1, double.infinity),
                getTitlesWidget: (val, _) => Text(
                  '#${val.toInt() + 1}',
                  style: AppTypography.monoSmall
                      .copyWith(color: AppColors.textTertiary, fontSize: 10),
                ),
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.accent,
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 3,
                  color: AppColors.accent,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.accent.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error Pie Chart ───────────────────────────────────────────────────────────

class _ErrorPieChart extends StatelessWidget {
  const _ErrorPieChart({required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    const colorMap = {
      'Mispronunciation': AppColors.errorMispronunciation,
      'Omission': AppColors.errorOmission,
      'Insertion': AppColors.errorInsertion,
    };

    final sections = counts.entries
        .where((e) => e.value > 0)
        .map(
          (e) => PieChartSectionData(
            value: e.value.toDouble(),
            color: colorMap[e.key] ?? AppColors.textTertiary,
            title: '${(e.value / total * 100).round()}%',
            titleStyle: AppTypography.monoSmall.copyWith(
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            radius: 60,
          ),
        )
        .toList();

    return SizedBox(
      height: 160,
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 2,
                centerSpaceRadius: 28,
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spacing24),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: counts.entries.map((e) {
              final color = colorMap[e.key] ?? AppColors.textTertiary;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${e.key} (${e.value})',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Phoneme Bar Chart ─────────────────────────────────────────────────────────

class _PhonemeBarChart extends StatelessWidget {
  const _PhonemeBarChart({required this.phonemes});

  final List<MapEntry<String, int>> phonemes;

  @override
  Widget build(BuildContext context) {
    final maxVal =
        phonemes.isEmpty ? 1 : phonemes.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: phonemes.length * 32.0,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.start,
          maxY: maxVal.toDouble() * 1.2,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx < 0 || idx >= phonemes.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      phonemes[idx].key,
                      style: AppTypography.monoSmall.copyWith(fontSize: 11),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            bottomTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: phonemes.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value.toDouble(),
                  color: AppColors.accent,
                  width: 18,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            );
          }).toList(),
        ),
        swapAnimationDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

// ── Word Chips ────────────────────────────────────────────────────────────────

class _WordChips extends StatelessWidget {
  const _WordChips({required this.words});

  final List<MapEntry<String, int>> words;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppConstants.spacing8,
      runSpacing: AppConstants.spacing8,
      children: words.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacing12,
            vertical: AppConstants.spacing4,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.key, style: AppTypography.bodyMedium),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.errorMispronunciation.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${e.value}x',
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 10,
                    color: AppColors.errorMispronunciation,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── WPM Trend Chip ────────────────────────────────────────────────────────────

class _WpmTrendChip extends StatelessWidget {
  const _WpmTrendChip({required this.wpmTrend});

  final double wpmTrend;

  @override
  Widget build(BuildContext context) {
    final isPositive = wpmTrend >= 0;
    final sign = isPositive ? '+' : '';
    final color = isPositive ? AppColors.scoreGood : AppColors.scorePoor;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacing16,
        vertical: AppConstants.spacing12,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 16,
            color: color,
          ),
          const SizedBox(width: AppConstants.spacing8),
          Text(
            'Speed: $sign${wpmTrend.toStringAsFixed(1)} WPM over last 3 sessions',
            style: AppTypography.bodyMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

// ── AI Coaching Card ──────────────────────────────────────────────────────────

class _PatternSummaryCard extends StatelessWidget {
  const _PatternSummaryCard({
    required this.state,
    required this.isAzureFoundryConfigured,
    required this.onGenerate,
  });

  final PatternState state;
  final bool isAzureFoundryConfigured;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing20),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AI Coaching', style: AppTypography.titleLarge),
          const SizedBox(height: AppConstants.spacing12),

          if (state.summary != null) ...[
            Text(
              state.summary!.summary,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppConstants.spacing12),
          ],

          if (state.isLoadingSummary)
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                ),
                SizedBox(width: AppConstants.spacing12),
                Text('Generating coaching tips...'),
              ],
            )
          else ...[
            if (!isAzureFoundryConfigured)
              Text(
                'Configure Azure AI Foundry in Settings to generate coaching tips.',
                style: AppTypography.bodySmall,
              )
            else
              TextButton.icon(
                onPressed: onGenerate,
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: Text(
                  state.summary == null
                      ? 'Generate coaching tips'
                      : 'Regenerate',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  padding: EdgeInsets.zero,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

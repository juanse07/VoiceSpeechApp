import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/score_ring.dart';
import '../../../core/widgets/minimal_audio_player.dart';
import '../../../core/utils/score_utils.dart';
import '../../../domain/entities/word_detail.dart';
import '../../providers/assessment_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/word_analysis_view.dart';
import '../../widgets/phoneme_bottom_sheet.dart';
import '../../widgets/score_breakdown.dart';
import '../../widgets/ai_feedback_card.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  final AudioPlayer _ttsPlayer = AudioPlayer();
  bool _isTtsPlaying = false;

  @override
  void initState() {
    super.initState();
    _initAudio();
    _ttsPlayer.playingStream.listen((playing) {
      if (mounted) setState(() => _isTtsPlaying = playing);
    });
  }

  @override
  void dispose() {
    _ttsPlayer.dispose();
    super.dispose();
  }

  Future<void> _initAudio() async {
    final assessment = ref.read(assessmentProvider).assessment;
    if (assessment == null) return;

    final audioService = ref.read(assessmentProvider.notifier).audioService;
    await audioService.loadAudio(assessment.audioFilePath);

    audioService.playbackPosition.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    audioService.playbackDuration.listen((dur) {
      if (mounted && dur != null) setState(() => _duration = dur);
    });
    audioService.isPlayingStream.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });
  }

  void _onPlayPause() {
    final audioService = ref.read(assessmentProvider.notifier).audioService;
    if (_isPlaying) {
      audioService.pause();
    } else {
      audioService.play();
    }
  }

  void _onSeek(Duration position) {
    ref.read(assessmentProvider.notifier).audioService.seekTo(position);
  }

  Future<void> _onListenToReference() async {
    final state = ref.read(assessmentProvider);
    if (state.ttsAudioPath != null) {
      // Already synthesized — play/pause toggle
      if (_isTtsPlaying) {
        await _ttsPlayer.pause();
      } else {
        await _ttsPlayer.seek(Duration.zero);
        await _ttsPlayer.play();
      }
      return;
    }
    // Synthesize then play
    await ref.read(assessmentProvider.notifier).synthesizeReference();
    final path = ref.read(assessmentProvider).ttsAudioPath;
    if (path != null && mounted) {
      await _ttsPlayer.setFilePath(path);
      await _ttsPlayer.play();
    }
  }

  void _showPhonemeSheet(WordDetail word) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          child: PhonemeBottomSheet(word: word),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentProvider);
    final assessment = state.assessment;

    if (assessment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Results')),
        body: const Center(child: Text('No assessment data.')),
      );
    }

    final wpm = assessment.wordsPerMinute;
    final isLoadingTts = state.isLoadingTts;
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        leading: IconButton(
          icon: const Icon(Icons.close, size: 20),
          onPressed: () {
            ref.read(assessmentProvider.notifier).reset();
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacing24,
          vertical: AppConstants.spacing16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall score
            Center(
              child: ScoreRing(
                score: assessment.overallScore,
                size: 140,
                strokeWidth: 8,
                label: ScoreUtils.scoreLabel(assessment.overallScore),
              ),
            ),

            const SizedBox(height: AppConstants.spacing16),

            // WPM chip
            if (wpm > 0)
              Center(
                child: _WpmChip(wpm: wpm),
              ),

            const SizedBox(height: AppConstants.spacing24),

            // Breakdown row
            ScoreBreakdown(
              accuracy: assessment.accuracyScore,
              fluency: assessment.fluencyScore,
              completeness: assessment.completenessScore,
              prosody: assessment.prosodyScore,
            ),

            const SizedBox(height: AppConstants.spacing24),

            // Listen to reference button
            if (assessment.referenceText.isNotEmpty)
              _ListenButton(
                isLoading: isLoadingTts,
                isPlaying: _isTtsPlaying,
                hasTts: state.ttsAudioPath != null,
                onTap: _onListenToReference,
              ),

            const SizedBox(height: AppConstants.spacing24),

            // Audio player
            MinimalAudioPlayer(
              isPlaying: _isPlaying,
              position: _position,
              duration: _duration,
              onPlayPause: _onPlayPause,
              onSeek: _onSeek,
            ),

            const SizedBox(height: AppConstants.spacing32),

            // Word analysis
            Text('Word Analysis', style: AppTypography.titleLarge),
            const SizedBox(height: AppConstants.spacing4),
            Text(
              'Tap any word for phoneme details.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppConstants.spacing16),

            WordAnalysisView(
              words: assessment.words,
              onWordTap: _showPhonemeSheet,
            ),

            const SizedBox(height: AppConstants.spacing32),

            // AI Feedback — collapsible
            _AiFeedbackSection(state: state, isConfigured: settings.isAzureFoundryConfigured),

            const SizedBox(height: AppConstants.spacing48),
          ],
        ),
      ),
    );
  }
}

class _AiFeedbackSection extends StatefulWidget {
  const _AiFeedbackSection({required this.state, required this.isConfigured});

  final AssessmentState state;
  final bool isConfigured;

  @override
  State<_AiFeedbackSection> createState() => _AiFeedbackSectionState();
}

class _AiFeedbackSectionState extends State<_AiFeedbackSection> {
  bool _expanded = false;

  @override
  void didUpdateWidget(_AiFeedbackSection old) {
    super.didUpdateWidget(old);
    // Auto-expand when feedback arrives
    if (widget.state.aiFeedback != null && old.state.aiFeedback == null) {
      setState(() => _expanded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    Widget? body;
    if (state.isLoadingFeedback) {
      body = const Center(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.spacing24),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
          ),
        ),
      );
    } else if (state.aiFeedback != null) {
      body = AiFeedbackCard(feedback: state.aiFeedback!);
    } else if (state.aiFeedbackError != null) {
      body = Container(
        padding: const EdgeInsets.all(AppConstants.spacing16),
        decoration: BoxDecoration(
          color: AppColors.scorePoor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(color: AppColors.scorePoor.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI request failed', style: AppTypography.labelLarge.copyWith(color: AppColors.scorePoor)),
            const SizedBox(height: 4),
            Text(state.aiFeedbackError!, style: AppTypography.bodySmall),
          ],
        ),
      );
    } else if (!widget.isConfigured) {
      body = _AiNotConfiguredCard();
    }

    if (body == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Text('AI Feedback', style: AppTypography.titleLarge),
              if (state.isLoadingFeedback) ...[
                const SizedBox(width: AppConstants.spacing8),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.accent),
                ),
              ],
              const Spacer(),
              Icon(
                _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 20,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: AppConstants.spacing16),
          body,
        ],
      ],
    );
  }
}

class _AiNotConfiguredCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, size: 16, color: AppColors.accent),
          const SizedBox(width: AppConstants.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Feedback',
                  style: AppTypography.labelLarge.copyWith(color: AppColors.accent),
                ),
                const SizedBox(height: 2),
                Text(
                  'Add an AI endpoint in Settings to get personalized coaching after each session.',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WpmChip extends StatelessWidget {
  const _WpmChip({required this.wpm});

  final double wpm;

  Color get _color {
    if (wpm < 80) return AppColors.scorePoor;
    if (wpm < 120) return AppColors.scoreOk;
    if (wpm <= 180) return AppColors.scoreGood;
    return AppColors.scoreOk; // too fast
  }

  String get _label {
    if (wpm < 80) return 'Too slow';
    if (wpm < 120) return 'Slow';
    if (wpm <= 160) return 'Natural';
    if (wpm <= 180) return 'Fast';
    return 'Too fast';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacing12,
        vertical: AppConstants.spacing4,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${wpm.round()} WPM',
            style: AppTypography.labelMedium.copyWith(
              color: _color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '· $_label',
            style: AppTypography.labelMedium.copyWith(
              color: _color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListenButton extends StatelessWidget {
  const _ListenButton({
    required this.isLoading,
    required this.isPlaying,
    required this.hasTts,
    required this.onTap,
  });

  final bool isLoading;
  final bool isPlaying;
  final bool hasTts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacing16,
          vertical: AppConstants.spacing12,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              )
            else
              Icon(
                isPlaying
                    ? Icons.pause_circle_outline_rounded
                    : Icons.volume_up_rounded,
                size: 18,
                color: AppColors.accent,
              ),
            const SizedBox(width: AppConstants.spacing8),
            Text(
              isLoading
                  ? 'Generating...'
                  : isPlaying
                      ? 'Pause reference'
                      : hasTts
                          ? 'Play reference again'
                          : 'Listen to reference',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

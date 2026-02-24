import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/score_ring.dart';
import '../../../core/widgets/minimal_audio_player.dart';
import '../../../core/utils/score_utils.dart';
import '../../../domain/entities/word_detail.dart';
import '../../providers/assessment_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _initAudio();
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

  void _showPhonemeSheet(WordDetail word) {
    showModalBottomSheet(
      context: context,
      builder: (_) => PhonemeBottomSheet(word: word),
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

            const SizedBox(height: AppConstants.spacing32),

            // Breakdown row
            ScoreBreakdown(
              accuracy: assessment.accuracyScore,
              fluency: assessment.fluencyScore,
              completeness: assessment.completenessScore,
              prosody: assessment.prosodyScore,
            ),

            const SizedBox(height: AppConstants.spacing32),

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

            // AI Feedback
            if (state.isLoadingFeedback) ...[
              Text('AI Feedback', style: AppTypography.titleLarge),
              const SizedBox(height: AppConstants.spacing16),
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppConstants.spacing24),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
            ] else if (state.aiFeedback != null) ...[
              Text('AI Feedback', style: AppTypography.titleLarge),
              const SizedBox(height: AppConstants.spacing16),
              AiFeedbackCard(feedback: state.aiFeedback!),
            ],

            const SizedBox(height: AppConstants.spacing48),
          ],
        ),
      ),
    );
  }
}

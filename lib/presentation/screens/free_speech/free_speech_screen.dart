import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../providers/assessment_provider.dart';
import '../../widgets/waveform_painter.dart';
import '../result/result_screen.dart';

class FreeSpeechScreen extends ConsumerStatefulWidget {
  const FreeSpeechScreen({super.key});

  @override
  ConsumerState<FreeSpeechScreen> createState() => _FreeSpeechScreenState();
}

class _FreeSpeechScreenState extends ConsumerState<FreeSpeechScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assessmentState = ref.watch(assessmentProvider);
    final notifier = ref.read(assessmentProvider.notifier);
    final isRecording = assessmentState.phase == AssessmentPhase.recording;
    final isProcessing = assessmentState.phase == AssessmentPhase.processing;

    if (isRecording && !_waveController.isAnimating) {
      _waveController.repeat();
    } else if (!isRecording && _waveController.isAnimating) {
      _waveController.stop();
    }

    // Navigate to results
    ref.listen<AssessmentState>(assessmentProvider, (prev, next) {
      if (prev?.phase != AssessmentPhase.done &&
          next.phase == AssessmentPhase.done &&
          next.assessment != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ResultScreen()),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Free Speech'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: isRecording || isProcessing
              ? null
              : () {
                  notifier.reset();
                  Navigator.pop(context);
                },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Waveform area
            if (isRecording)
              SizedBox(
                height: 80,
                width: double.infinity,
                child: AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: WaveformPainter(
                        progress: _waveController.value,
                        color: AppColors.accent,
                        lineCount: 40,
                      ),
                    );
                  },
                ),
              )
            else
              const SizedBox(height: 80),

            const SizedBox(height: AppConstants.spacing40),

            // Mic button
            GestureDetector(
              onTap: () {
                if (isProcessing) return;
                if (isRecording) {
                  notifier.stopAndAssessFreeSpeech();
                } else {
                  notifier.startRecording();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isRecording ? 88 : 80,
                height: isRecording ? 88 : 80,
                decoration: BoxDecoration(
                  color: isRecording
                      ? AppColors.scorePoor
                      : isProcessing
                          ? AppColors.textTertiary
                          : AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isProcessing
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.white,
                          ),
                        )
                      : Icon(
                          isRecording ? Icons.stop : Icons.mic,
                          color: AppColors.white,
                          size: 32,
                        ),
                ),
              ),
            ),

            const SizedBox(height: AppConstants.spacing24),

            // Countdown timer
            if (isRecording) ...[
              Builder(builder: (context) {
                final elapsed = assessmentState.recordingDuration.inSeconds;
                final remaining = AppConstants.maxRecordingDurationSeconds - elapsed;
                final isWarning = remaining <= 10;
                return Text(
                  '${remaining}s',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isWarning ? AppColors.scorePoor : AppColors.textSecondary,
                    fontWeight: isWarning ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }),
              const SizedBox(height: AppConstants.spacing8),
            ],

            // Status text
            Text(
              isProcessing
                  ? 'Analyzing your speech...'
                  : isRecording
                      ? 'Listening. Tap to stop.'
                      : 'Tap to start speaking.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            if (assessmentState.errorMessage != null) ...[
              const SizedBox(height: AppConstants.spacing24),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacing24,
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppConstants.spacing16),
                  decoration: BoxDecoration(
                    color: AppColors.scorePoor.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMedium),
                  ),
                  child: Text(
                    assessmentState.errorMessage!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.scorePoor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],

            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/assessment_provider.dart';
import '../result/result_screen.dart';

class TextModeScreen extends ConsumerStatefulWidget {
  const TextModeScreen({super.key});

  @override
  ConsumerState<TextModeScreen> createState() => _TextModeScreenState();
}

class _TextModeScreenState extends ConsumerState<TextModeScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  static const _sampleTexts = [
    _SampleText(
      title: 'The North Wind',
      text:
          'The North Wind and the Sun were disputing which was the stronger, when a traveler came along wrapped in a warm cloak. They agreed that the one who first succeeded in making the traveler take his cloak off should be considered stronger than the other.',
    ),
    _SampleText(
      title: 'Technology',
      text:
          'Artificial intelligence has transformed the way we interact with technology. From voice assistants that understand natural language to recommendation systems that predict our preferences, machine learning algorithms are embedded in our daily lives.',
    ),
    _SampleText(
      title: 'Quick Practice',
      text:
          'She sells seashells by the seashore. The shells she sells are seashells, I am sure. So if she sells seashells on the seashore, then I am sure she sells seashore shells.',
    ),
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSampleTap(_SampleText sample) {
    _textController.text = sample.text;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final assessmentState = ref.watch(assessmentProvider);
    final notifier = ref.read(assessmentProvider.notifier);
    final isRecording = assessmentState.phase == AssessmentPhase.recording;
    final isProcessing = assessmentState.phase == AssessmentPhase.processing;
    final hasText = _textController.text.trim().isNotEmpty;

    // Navigate to results when done
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
        title: const Text('Text Mode'),
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppConstants.spacing24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reference Text', style: AppTypography.titleLarge),
                  const SizedBox(height: AppConstants.spacing4),
                  Text(
                    'Enter the text you want to practice reading.',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: AppConstants.spacing16),

                  // Text area
                  TextField(
                    controller: _textController,
                    maxLines: 8,
                    enabled: !isRecording && !isProcessing,
                    onChanged: (_) => setState(() {}),
                    style: AppTypography.bodyLarge.copyWith(height: 1.8),
                    decoration: const InputDecoration(
                      hintText:
                          'Paste or type the text you want to read aloud...',
                      alignLabelWithHint: true,
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacing12),

                  // Word count
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_wordCount()} words',
                      style: AppTypography.monoSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacing20),

                  // Samples
                  Text('Samples', style: AppTypography.labelMedium),
                  const SizedBox(height: AppConstants.spacing8),
                  Wrap(
                    spacing: AppConstants.spacing8,
                    runSpacing: AppConstants.spacing8,
                    children: _sampleTexts.map((s) {
                      return GestureDetector(
                        onTap: isRecording || isProcessing
                            ? null
                            : () => _onSampleTap(s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.spacing12,
                            vertical: AppConstants.spacing8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(
                                AppConstants.radiusSmall),
                          ),
                          child: Text(s.title, style: AppTypography.labelMedium),
                        ),
                      );
                    }).toList(),
                  ),

                  // Error message
                  if (assessmentState.errorMessage != null) ...[
                    const SizedBox(height: AppConstants.spacing24),
                    Container(
                      padding: const EdgeInsets.all(AppConstants.spacing16),
                      decoration: BoxDecoration(
                        color: AppColors.scorePoor.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusMedium),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              size: 18, color: AppColors.scorePoor),
                          const SizedBox(width: AppConstants.spacing12),
                          Expanded(
                            child: Text(
                              assessmentState.errorMessage!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.scorePoor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom bar
          Container(
            padding: const EdgeInsets.all(AppConstants.spacing24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.borderLight),
              ),
            ),
            child: SafeArea(
              top: false,
              child: _buildBottomAction(
                isRecording: isRecording,
                isProcessing: isProcessing,
                hasText: hasText,
                notifier: notifier,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction({
    required bool isRecording,
    required bool isProcessing,
    required bool hasText,
    required AssessmentNotifier notifier,
  }) {
    if (isProcessing) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.textTertiary,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: AppConstants.spacing12),
              Text('Analyzing...', style: AppTypography.labelLarge),
            ],
          ),
        ),
      );
    }

    if (isRecording) {
      return SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Read the text aloud now.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.spacing12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => notifier.stopAndAssess(
                  referenceText: _textController.text.trim(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.scorePoor,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacing8),
                    Text('Stop Recording',
                        style: AppTypography.labelLarge
                            .copyWith(color: AppColors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: hasText ? () => notifier.startRecording() : null,
        child: Text('Start Reading',
            style: AppTypography.labelLarge.copyWith(color: AppColors.white)),
      ),
    );
  }

  int _wordCount() {
    final text = _textController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }
}

class _SampleText {
  const _SampleText({required this.title, required this.text});
  final String title;
  final String text;
}

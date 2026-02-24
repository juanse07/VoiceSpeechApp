import 'package:equatable/equatable.dart';

enum SessionMode { text, freeSpeech }

class Session extends Equatable {
  const Session({
    required this.id,
    required this.mode,
    required this.overallScore,
    required this.referenceText,
    required this.recognizedText,
    required this.audioFilePath,
    required this.durationMs,
    required this.createdAt,
    this.accuracyScore = 0,
    this.fluencyScore = 0,
    this.completenessScore = 0,
    this.prosodyScore = 0,
  });

  final String id;
  final SessionMode mode;
  final double overallScore;
  final double accuracyScore;
  final double fluencyScore;
  final double completenessScore;
  final double prosodyScore;
  final String referenceText;
  final String recognizedText;
  final String audioFilePath;
  final int durationMs;
  final DateTime createdAt;

  String get formattedDuration {
    final seconds = (durationMs / 1000).round();
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  List<Object?> get props => [id, mode, overallScore, createdAt];
}

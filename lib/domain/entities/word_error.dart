import 'package:equatable/equatable.dart';

class WordError extends Equatable {
  const WordError({
    required this.word,
    required this.errorType,
    required this.weakPhonemes,
    required this.accuracyScore,
  });

  final String word;
  final String errorType; // Mispronunciation, Omission, Insertion
  final List<String> weakPhonemes; // phonemes with accuracy < 80
  final double accuracyScore;

  Map<String, dynamic> toJson() => {
        'word': word,
        'errorType': errorType,
        'weakPhonemes': weakPhonemes,
        'accuracyScore': accuracyScore,
      };

  factory WordError.fromJson(Map<String, dynamic> j) => WordError(
        word: j['word'] as String,
        errorType: j['errorType'] as String,
        weakPhonemes: (j['weakPhonemes'] as List<dynamic>)
            .map((e) => e as String)
            .toList(),
        accuracyScore: (j['accuracyScore'] as num).toDouble(),
      );

  @override
  List<Object?> get props => [word, errorType, weakPhonemes, accuracyScore];
}

import '../../domain/entities/pattern_data.dart';
import '../../domain/entities/session.dart';

class PatternAnalyzer {
  static PatternData analyze(List<Session> sessions) {
    // Sessions are expected in chronological order (oldest first) for trends.
    // getAllSessions returns newest-first, so we reverse.
    final chronological = sessions.reversed.toList();

    // --- Top mispronounced words ---
    final mispronounceCount = <String, int>{};
    for (final s in chronological) {
      for (final e in s.wordErrors) {
        if (e.errorType == 'Mispronunciation') {
          mispronounceCount[e.word.toLowerCase()] =
              (mispronounceCount[e.word.toLowerCase()] ?? 0) + 1;
        }
      }
    }
    final topMispronounced = mispronounceCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topMisp = topMispronounced.take(10).toList();

    // --- Top weak phonemes ---
    final phonemeCount = <String, int>{};
    for (final s in chronological) {
      for (final e in s.wordErrors) {
        for (final p in e.weakPhonemes) {
          phonemeCount[p] = (phonemeCount[p] ?? 0) + 1;
        }
      }
    }
    final topPhonemes = phonemeCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topWeak = topPhonemes.take(10).toList();

    // --- Error type counts ---
    final errorTypeCounts = <String, int>{
      'Mispronunciation': 0,
      'Omission': 0,
      'Insertion': 0,
    };
    for (final s in chronological) {
      for (final e in s.wordErrors) {
        if (errorTypeCounts.containsKey(e.errorType)) {
          errorTypeCounts[e.errorType] = errorTypeCounts[e.errorType]! + 1;
        }
      }
    }

    // --- Overall score trend ---
    final overallScoreTrend =
        chronological.map((s) => s.overallScore).toList();

    // --- WPM trend ---
    double wpmTrend = 0;
    if (chronological.length >= 6) {
      final firstThree = chronological.take(3).toList();
      final lastThree =
          chronological.skip(chronological.length - 3).toList();
      final avgFirst =
          firstThree.map((s) => s.wordsPerMinute).reduce((a, b) => a + b) / 3;
      final avgLast =
          lastThree.map((s) => s.wordsPerMinute).reduce((a, b) => a + b) / 3;
      wpmTrend = avgLast - avgFirst;
    }

    return PatternData(
      topMispronounced: topMisp,
      topWeakPhonemes: topWeak,
      errorTypeCounts: errorTypeCounts,
      overallScoreTrend: overallScoreTrend,
      wpmTrend: wpmTrend,
      sessionCount: sessions.length,
    );
  }
}

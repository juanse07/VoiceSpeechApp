class PatternData {
  const PatternData({
    required this.topMispronounced,
    required this.topWeakPhonemes,
    required this.errorTypeCounts,
    required this.overallScoreTrend,
    required this.wpmTrend,
    required this.sessionCount,
  });

  /// Top mispronounced words with their occurrence counts.
  final List<MapEntry<String, int>> topMispronounced;

  /// Top weak phonemes with their occurrence counts.
  final List<MapEntry<String, int>> topWeakPhonemes;

  /// Count of each error type across all sessions.
  final Map<String, int> errorTypeCounts;

  /// Overall score for each session in chronological order.
  final List<double> overallScoreTrend;

  /// avg(last-3 wpm) - avg(first-3 wpm); 0 if < 6 sessions.
  final double wpmTrend;

  final int sessionCount;
}

class PatternSummary {
  const PatternSummary({
    required this.summary,
    required this.generatedAt,
  });

  final String summary;
  final DateTime generatedAt;
}

/// Corrects common OCR digit confusions using pairwise likelihood and confidence.
class DigitConfusionCorrector {
  /// STC card fonts often print 6 with a closed bottom loop, so OCR reads it as 5.
  static const fiveSixPair = {'5', '6'};

  static const _confusableGroups = <List<String>>[
    ['0', '8', '9', 'O', 'D', 'Q'],
    ['5', '6', 'S', 'G', 'b'],
    ['1', 'I', 'L', '|', '!'],
    ['2', 'Z'],
    ['3', '8'],
    ['4', '9'],
    ['6', '8', '0'],
    ['8', '6', '5', '9', 'B'],
    ['9', '8', '0', '4'],
  ];

  static final _digitOnly = RegExp(r'^\d$');

  /// Normalize a raw OCR character to a digit when possible.
  static String? normalizeChar(String raw) {
    if (raw.isEmpty) return null;
    final ch = raw.toUpperCase();

    if (_digitOnly.hasMatch(ch)) return ch;

    switch (ch) {
      case 'O':
      case 'Q':
      case 'D':
        return '0';
      case 'I':
      case 'L':
      case '|':
      case '!':
        return '1';
      case 'Z':
        return '2';
      case 'S':
        return '5';
      case 'G':
      case 'b':
        return '6';
      case 'B':
        return '8';
      default:
        return null;
    }
  }

  /// When OCR picked 5 but 6 had meaningful support, prefer 6.
  ///
  /// Closed-loop 6 glyphs on recharge cards are systematically misread as 5.
  static String correctFiveSixSequence(
    String value,
    List<Map<String, double>> positionVotes,
  ) {
    if (value.isEmpty || positionVotes.length != value.length) return value;

    final chars = value.split('');
    for (var i = 0; i < chars.length; i++) {
      if (chars[i] != '5') continue;

      final votes = positionVotes[i];
      final weight5 = votes['5'] ?? 0;
      final weight6 = votes['6'] ?? 0;
      if (weight6 <= 0) continue;

      final total = weight5 + weight6;
      final sixShare = total <= 0 ? 0.0 : weight6 / total;

      if (sixShare >= 0.38 || weight6 >= weight5 * 0.72) {
        chars[i] = '6';
      }
    }

    return chars.join();
  }

  static List<String> confusableDigits(String digit) {
    for (final group in _confusableGroups) {
      if (group.contains(digit)) {
        return group.where(_digitOnly.hasMatch).toList();
      }
    }
    return [digit];
  }

  /// Pick the best digit for a position using weighted votes and confusions.
  static String resolveDigit({
    required Map<String, double> weightedVotes,
    required double topConfidence,
  }) {
    if (weightedVotes.isEmpty) return '';

    final normalizedVotes = <String, double>{};
    for (final entry in weightedVotes.entries) {
      final digit = normalizeChar(entry.key);
      if (digit == null) continue;
      normalizedVotes[digit] = (normalizedVotes[digit] ?? 0) + entry.value;
    }

    if (normalizedVotes.isEmpty) return '';

    final expandedVotes = _expandConfusionVotes(normalizedVotes);
    final sorted = expandedVotes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    var winner = sorted.first.key;

    if (sorted.length > 1 && topConfidence < 0.90) {
      final runnerUp = sorted[1].key;
      winner = _resolveAmbiguousPair(
        primary: winner,
        secondary: runnerUp,
        primaryWeight: sorted.first.value,
        secondaryWeight: sorted[1].value,
      );
    }

    return winner;
  }

  /// Majority pick at [position] when top digits are confusable.
  static String pickByConfusionPlurality(
    List<String> candidates,
    int position,
  ) {
    if (candidates.isEmpty) return '';

    final counts = <String, int>{};
    for (final candidate in candidates) {
      if (position >= candidate.length) continue;
      final digit = candidate[position];
      for (final confusable in confusableDigits(digit)) {
        counts[confusable] = (counts[confusable] ?? 0) + 1;
      }
    }

    if (counts.isEmpty) return candidates.first[position];

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  static Map<String, double> _expandConfusionVotes(
    Map<String, double> votes,
  ) {
    final expanded = Map<String, double>.from(votes);

    for (final entry in votes.entries) {
      final digit = entry.key;
      final weight = entry.value;
      if (weight >= 0.82) continue;

      if (fiveSixPair.contains(digit)) {
        final other = digit == '5' ? '6' : '5';
        expanded[other] = (expanded[other] ?? 0) + weight * 0.48;
        continue;
      }

      for (final confusable in confusableDigits(digit)) {
        if (confusable == digit) continue;
        expanded[confusable] = (expanded[confusable] ?? 0) + weight * 0.22;
      }
    }

    return expanded;
  }

  static String _resolveAmbiguousPair({
    required String primary,
    required String secondary,
    required double primaryWeight,
    required double secondaryWeight,
  }) {
    if (primary == secondary) return primary;

    final margin = primaryWeight - secondaryWeight;
    if (margin > 0.28) return primary;

    if (fiveSixPair.contains(primary) && fiveSixPair.contains(secondary)) {
      return _resolveFiveSixPair(
        primary: primary,
        secondary: secondary,
        margin: margin,
      );
    }

    for (final group in _confusableGroups) {
      if (group.contains(primary) && group.contains(secondary)) {
        return _preferInConfusionGroup(primary, secondary, margin);
      }
    }

    return primary;
  }

  /// Prefer 6 in close 5/6 calls — closed-loop 6 is often read as 5.
  static String _resolveFiveSixPair({
    required String primary,
    required String secondary,
    required double margin,
  }) {
    if (margin > 0.42) return primary;
    if (primary == '6' || secondary == '6') return '6';
    return primary;
  }

  static String _preferInConfusionGroup(
    String primary,
    String secondary,
    double margin,
  ) {
    const preferences = <String, String>{
      '0_8': '8',
      '8_0': '0',
      '0_9': '9',
      '9_0': '0',
      '8_9': '9',
      '9_8': '8',
      '8_6': '6',
      '6_8': '8',
      '5_6': '6',
      '6_5': '6',
      '5_9': '5',
      '9_5': '9',
      '6_0': '6',
      '0_6': '0',
      '3_8': '8',
      '8_3': '3',
      '4_9': '9',
      '9_4': '4',
    };

    final key = '${primary}_$secondary';
    if (margin.abs() < 0.22 && preferences.containsKey(key)) {
      return preferences[key]!;
    }

    return primary;
  }
}

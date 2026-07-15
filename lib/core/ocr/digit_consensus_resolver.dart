import 'package:qrscanner/core/ocr/digit_confusion_corrector.dart';
import 'package:qrscanner/core/ocr/models/ocr_models.dart';

/// Merges multiple OCR passes into one high-confidence digit sequence.
class DigitConsensusResolver {
  const DigitConsensusResolver();

  String? resolve({
    required List<OcrDigitSequence> sequences,
    required List<int> expectedLengths,
    required int preferredLength,
  }) {
    if (sequences.isEmpty) return null;

    final filtered = sequences
        .where((sequence) => expectedLengths.contains(sequence.value.length))
        .toList();

    final candidates = filtered.isNotEmpty ? filtered : sequences;
    if (candidates.isEmpty) return null;

    final unanimous = _findUnanimousAgreement(
      candidates,
      preferredLength: preferredLength,
    );
    if (unanimous != null) return unanimous;

    final targetLength = _pickTargetLength(
      candidates,
      expectedLengths: expectedLengths,
      preferredLength: preferredLength,
    );
    if (targetLength == null) {
      return _pickBestWholeCandidate(candidates, expectedLengths: expectedLengths);
    }

    final majority = _majorityVotePerPosition(candidates, targetLength);
    if (majority != null && expectedLengths.contains(majority.value.length)) {
      return majority.value;
    }

    final merged = _positionWiseMerge(
      candidates,
      targetLength: targetLength,
      expectedLengths: expectedLengths,
    );
    if (merged == null) return null;
    return merged.value;
  }

  String? _findUnanimousAgreement(
    List<OcrDigitSequence> candidates, {
    required int preferredLength,
  }) {
    final frequency = <String, int>{};
    for (final candidate in candidates) {
      if (candidate.value.length != preferredLength) continue;
      frequency[candidate.value] = (frequency[candidate.value] ?? 0) + 1;
    }

    String? winner;
    var bestCount = 0;
    for (final entry in frequency.entries) {
      if (entry.value > bestCount) {
        bestCount = entry.value;
        winner = entry.key;
      }
    }

    if (winner != null && bestCount >= 2) return winner;
    return null;
  }

  int? _pickTargetLength(
    List<OcrDigitSequence> candidates, {
    required List<int> expectedLengths,
    required int preferredLength,
  }) {
    if (candidates.any((c) => c.value.length == preferredLength)) {
      return preferredLength;
    }

    for (final length in expectedLengths) {
      if (candidates.any((c) => c.value.length == length)) {
        return length;
      }
    }

    return candidates
        .map((c) => c.value.length)
        .fold<int>(0, (a, b) => a > b ? a : b);
  }

  ({String value, List<Map<String, double>> positionVotes})? _majorityVotePerPosition(
    List<OcrDigitSequence> candidates,
    int targetLength,
  ) {
    final aligned = candidates
        .where((candidate) => candidate.value.length == targetLength)
        .toList();
    if (aligned.isEmpty) return null;

    final digits = <String>[];
    final positionVotes = <Map<String, double>>[];

    for (var position = 0; position < targetLength; position++) {
      final votes = <String, double>{};

      for (final sequence in aligned) {
        final weight = _sourceWeight(sequence.sourceLabel);
        final observation = position < sequence.digits.length
            ? sequence.digits[position]
            : DigitObservation(
                digit: sequence.value[position],
                confidence: sequence.averageConfidence,
                position: position,
              );

        final confidence = observation.confidence <= 0
            ? 0.58
            : observation.confidence;

        votes[observation.digit] =
            (votes[observation.digit] ?? 0) + confidence * weight;
      }

      if (votes.isEmpty) return null;

      final sorted = votes.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      var digit = DigitConfusionCorrector.resolveDigit(
        weightedVotes: votes,
        topConfidence: sorted.first.value / aligned.length,
      );

      if (sorted.length > 1) {
        final margin = sorted.first.value - sorted[1].value;
        if (margin < sorted.first.value * 0.18) {
          digit = DigitConfusionCorrector.pickByConfusionPlurality(
            aligned.map((s) => s.value).toList(),
            position,
          );
        }
      }

      digits.add(digit);
      positionVotes.add(Map<String, double>.from(votes));
    }

    final joined = digits.join();
    final corrected = DigitConfusionCorrector.correctFiveSixSequence(
      joined,
      positionVotes,
    );

    return (value: corrected, positionVotes: positionVotes);
  }

  ({String value, List<Map<String, double>> positionVotes})? _positionWiseMerge(
    List<OcrDigitSequence> candidates, {
    required int targetLength,
    required List<int> expectedLengths,
  }) {
    final mergedDigits = <String>[];
    final positionVotes = <Map<String, double>>[];
    var totalConfidence = 0.0;

    for (var position = 0; position < targetLength; position++) {
      final votes = <String, double>{};
      var positionConfidence = 0.0;
      var voteCount = 0;

      for (final sequence in candidates) {
        if (position >= sequence.value.length) continue;

        final observation = position < sequence.digits.length
            ? sequence.digits[position]
            : DigitObservation(
                digit: sequence.value[position],
                confidence: sequence.averageConfidence,
                position: position,
              );

        final weight = (observation.confidence <= 0 ? 0.55 : observation.confidence) *
            _sourceWeight(sequence.sourceLabel);

        votes[observation.digit] = (votes[observation.digit] ?? 0) + weight;
        positionConfidence += observation.confidence <= 0 ? 0.55 : observation.confidence;
        voteCount++;
      }

      if (votes.isEmpty) continue;

      final digit = DigitConfusionCorrector.resolveDigit(
        weightedVotes: votes,
        topConfidence: voteCount == 0 ? 0 : positionConfidence / voteCount,
      );

      if (digit.isEmpty) continue;
      mergedDigits.add(digit);
      positionVotes.add(Map<String, double>.from(votes));
      totalConfidence += positionConfidence / voteCount;
    }

    if (mergedDigits.isEmpty) return null;

    var merged = mergedDigits.join();
    if (!expectedLengths.contains(merged.length)) {
      final fallback = _pickBestWholeCandidate(candidates, expectedLengths: expectedLengths);
      return fallback == null ? null : (value: fallback, positionVotes: positionVotes);
    }

    final avgConfidence = totalConfidence / mergedDigits.length;
    if (avgConfidence < 0.40) {
      final fallback = _pickBestWholeCandidate(candidates, expectedLengths: expectedLengths);
      return fallback == null ? null : (value: fallback, positionVotes: positionVotes);
    }

    merged = DigitConfusionCorrector.correctFiveSixSequence(merged, positionVotes);
    return (value: merged, positionVotes: positionVotes);
  }

  double _sourceWeight(String sourceLabel) {
    if (sourceLabel.contains('_v1') ||
        sourceLabel.contains('_v2') ||
        sourceLabel.contains('_v3')) {
      return 1.18;
    }
    if (sourceLabel.contains('_refined')) {
      return 1.25;
    }
    return 1.0;
  }

  String? _pickBestWholeCandidate(
    List<OcrDigitSequence> candidates, {
    required List<int> expectedLengths,
  }) {
    final scored = candidates
        .where((c) => expectedLengths.contains(c.value.length))
        .toList();
    if (scored.isEmpty) return null;

    scored.sort((a, b) {
      final scoreA = _wholeCandidateScore(a, expectedLengths);
      final scoreB = _wholeCandidateScore(b, expectedLengths);
      return scoreB.compareTo(scoreA);
    });

    return scored.first.value;
  }

  int _wholeCandidateScore(
    OcrDigitSequence candidate,
    List<int> expectedLengths,
  ) {
    var score = (candidate.averageConfidence * 100).round();
    if (expectedLengths.contains(candidate.value.length)) {
      score += 200;
      score += (expectedLengths.length -
              expectedLengths.indexOf(candidate.value.length)) *
          25;
    }
    return score + candidate.value.split('').toSet().length * 4;
  }
}

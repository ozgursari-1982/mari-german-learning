import '../models/vocabulary_word.dart';

/// Service for implementing spaced repetition using SM-2 algorithm
/// Based on SuperMemo 2 algorithm for optimal learning intervals
class SpacedRepetitionService {
  /// Calculate next review date based on SM-2 algorithm
  ///
  /// Parameters:
  /// - reviewCount: Number of times reviewed
  /// - easinessFactor: Current easiness factor (1.3 - 2.5)
  /// - wasCorrect: Whether the answer was correct
  ///
  /// Returns: Updated word with new review schedule
  VocabularyWord calculateNextReview({
    required VocabularyWord word,
    required bool wasCorrect,
  }) {
    final now = DateTime.now();
    int newReviewCount = word.reviewCount + 1;
    double newEasinessFactor = word.easinessFactor;
    int newConsecutiveCorrect = word.consecutiveCorrect;
    LearningStatus newStatus = word.status;
    DateTime nextReview;

    if (wasCorrect) {
      newConsecutiveCorrect++;

      // Update easiness factor (SM-2 formula)
      // EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
      // where q = quality (5 for correct answer)
      newEasinessFactor = word.easinessFactor + 0.1;
      newEasinessFactor = newEasinessFactor.clamp(1.3, 2.5);

      // Calculate interval based on consecutive correct answers
      int intervalDays;
      if (newConsecutiveCorrect == 1) {
        intervalDays = 1; // First correct: review tomorrow
        newStatus = LearningStatus.learning;
      } else if (newConsecutiveCorrect == 2) {
        intervalDays = 3; // Second correct: review in 3 days
        newStatus = LearningStatus.learning;
      } else if (newConsecutiveCorrect == 3) {
        intervalDays = 7; // Third correct: review in 1 week
        newStatus = LearningStatus.learned;
      } else {
        // After 3rd correct, use SM-2 formula
        // I(n) = I(n-1) * EF
        final previousInterval = _calculatePreviousInterval(
          newConsecutiveCorrect - 1,
        );
        intervalDays = (previousInterval * newEasinessFactor).round();

        if (newConsecutiveCorrect >= 5) {
          newStatus = LearningStatus.mastered;
        }
      }

      nextReview = now.add(Duration(days: intervalDays));
    } else {
      // Wrong answer: reset progress
      newConsecutiveCorrect = 0;
      newStatus = LearningStatus.learning;

      // Decrease easiness factor
      newEasinessFactor = word.easinessFactor - 0.2;
      newEasinessFactor = newEasinessFactor.clamp(1.3, 2.5);

      // Review again in 10 minutes
      nextReview = now.add(const Duration(minutes: 10));
    }

    return word.copyWith(
      lastReviewedAt: now,
      nextReviewAt: nextReview,
      reviewCount: newReviewCount,
      easinessFactor: newEasinessFactor,
      consecutiveCorrect: newConsecutiveCorrect,
      status: newStatus,
    );
  }

  /// Calculate interval for a given repetition number
  int _calculatePreviousInterval(int repetition) {
    if (repetition <= 1) return 1;
    if (repetition == 2) return 3;
    if (repetition == 3) return 7;

    // For repetitions > 3, use exponential growth
    return (7 * (repetition - 2)).round();
  }

  /// Get words that are due for review
  List<VocabularyWord> getDueWords(List<VocabularyWord> allWords) {
    final now = DateTime.now();
    return allWords.where((word) {
      return word.nextReviewAt.isBefore(now) ||
          word.nextReviewAt.isAtSameMomentAs(now);
    }).toList();
  }

  /// Get words by learning status
  List<VocabularyWord> getWordsByStatus(
    List<VocabularyWord> allWords,
    LearningStatus status,
  ) {
    return allWords.where((word) => word.status == status).toList();
  }

  /// Get statistics about learning progress
  Map<String, dynamic> getStatistics(List<VocabularyWord> allWords) {
    final total = allWords.length;
    final newWords = allWords
        .where((w) => w.status == LearningStatus.new_word)
        .length;
    final learning = allWords
        .where((w) => w.status == LearningStatus.learning)
        .length;
    final learned = allWords
        .where((w) => w.status == LearningStatus.learned)
        .length;
    final mastered = allWords
        .where((w) => w.status == LearningStatus.mastered)
        .length;
    final dueToday = getDueWords(allWords).length;

    return {
      'total': total,
      'new': newWords,
      'learning': learning,
      'learned': learned,
      'mastered': mastered,
      'dueToday': dueToday,
      'masteredPercentage': total > 0 ? (mastered / total * 100).round() : 0,
    };
  }

  /// Recommend daily study limit
  int getRecommendedDailyLimit(List<VocabularyWord> allWords) {
    final stats = getStatistics(allWords);
    final dueToday = stats['dueToday'] as int;

    // Recommend 10 new words + all due reviews
    // But cap at 30 total to avoid overwhelming
    final recommended = (10 + dueToday).clamp(5, 30);
    return recommended;
  }
}

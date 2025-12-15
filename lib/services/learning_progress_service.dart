import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/learning_progress_model.dart';
import '../models/vocabulary_word.dart';

/// Service for tracking and managing user's learning progress
class LearningProgressService {
  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  LearningProgressService(this.userId);

  /// Get user's current learning progress
  Future<LearningProgress> getProgress() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc('current')
          .get();

      if (doc.exists) {
        return LearningProgress.fromMap(doc.data()!);
      } else {
        // Create initial progress
        final initialProgress = LearningProgress(
          userId: userId,
          overallProgress: 0,
          currentLevel: 'A1',
          topicProgress: {},
          strongAreas: [],
          weakAreas: [],
          recommendedTopics: ['Artikel', 'Perfekt', 'Akkusativ'],
          lastUpdated: DateTime.now(),
          studyStreak: {},
        );
        await _saveProgress(initialProgress);
        return initialProgress;
      }
    } catch (e) {
      print('Error getting progress: $e');
      rethrow;
    }
  }

  /// Update progress after quiz completion
  Future<void> updateProgressFromQuiz({
    required String topic,
    required int totalQuestions,
    required int correctAnswers,
    required String category,
  }) async {
    try {
      final progress = await getProgress();
      final accuracy = (correctAnswers / totalQuestions) * 100;

      // Update topic progress
      final currentTopicProgress = progress.topicProgress[topic];
      final updatedTopicProgress =
          currentTopicProgress?.copyWith(
            correctAnswers:
                (currentTopicProgress.correctAnswers) + correctAnswers,
            totalAttempts:
                (currentTopicProgress.totalAttempts) + totalQuestions,
            lastPracticed: DateTime.now(),
            progress: _calculateTopicProgress(
              currentTopicProgress.correctAnswers + correctAnswers,
              currentTopicProgress.totalAttempts + totalQuestions,
            ),
          ) ??
          TopicProgress(
            topicName: topic,
            progress: accuracy.round(),
            correctAnswers: correctAnswers,
            totalAttempts: totalQuestions,
            lastPracticed: DateTime.now(),
            category: category,
          );

      final newTopicProgress = Map<String, TopicProgress>.from(
        progress.topicProgress,
      );
      newTopicProgress[topic] = updatedTopicProgress;

      // Calculate overall progress
      final overallProgress = _calculateOverallProgress(newTopicProgress);

      // Determine strong and weak areas
      final strongAreas = <String>[];
      final weakAreas = <String>[];
      newTopicProgress.forEach((key, value) {
        if (value.progress >= 70) {
          strongAreas.add(key);
        } else if (value.progress < 50) {
          weakAreas.add(key);
        }
      });

      // Update quiz stats
      final newQuizzesTaken = progress.quizzesTaken + 1;
      final newAverageScore =
          ((progress.averageQuizScore * progress.quizzesTaken) + accuracy) /
          newQuizzesTaken;

      final updatedProgress = progress.copyWith(
        topicProgress: newTopicProgress,
        overallProgress: overallProgress,
        strongAreas: strongAreas,
        weakAreas: weakAreas,
        lastUpdated: DateTime.now(),
        quizzesTaken: newQuizzesTaken,
        averageQuizScore: newAverageScore,
      );

      await _saveProgress(updatedProgress);

      // Record study session
      await _recordStudySession(
        topic: topic,
        questionsAnswered: totalQuestions,
        correctAnswers: correctAnswers,
        activityType: 'quiz',
      );
    } catch (e) {
      print('Error updating progress from quiz: $e');
    }
  }

  /// Update progress from vocabulary practice
  Future<void> updateProgressFromVocabulary(List<VocabularyWord> words) async {
    try {
      final progress = await getProgress();

      // Count mastered words
      final masteredCount = words
          .where((w) => w.status == LearningStatus.mastered)
          .length;

      final updatedProgress = progress.copyWith(
        vocabularyMastered: masteredCount,
        lastUpdated: DateTime.now(),
      );

      await _saveProgress(updatedProgress);
    } catch (e) {
      print('Error updating progress from vocabulary: $e');
    }
  }

  /// Record a study session
  Future<void> _recordStudySession({
    required String topic,
    required int questionsAnswered,
    required int correctAnswers,
    required String activityType,
  }) async {
    try {
      final session = StudySession(
        userId: userId,
        date: DateTime.now(),
        topic: topic,
        duration: 0, // TODO: Track actual duration
        questionsAnswered: questionsAnswered,
        correctAnswers: correctAnswers,
        activityType: activityType,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('study_sessions')
          .add(session.toMap());
    } catch (e) {
      print('Error recording study session: $e');
    }
  }

  /// Get study history for the last N days
  Future<List<StudySession>> getStudyHistory({int days = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('study_sessions')
          .where('date', isGreaterThan: Timestamp.fromDate(cutoffDate))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => StudySession.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting study history: $e');
      return [];
    }
  }

  /// Calculate topic progress based on accuracy
  int _calculateTopicProgress(int correct, int total) {
    if (total == 0) return 0;
    final accuracy = (correct / total) * 100;
    return accuracy.round().clamp(0, 100);
  }

  /// Calculate overall progress towards B2 based on realistic curriculum
  /// B2 requires mastery of: A1 (6 themes) + A2 (6 themes) + B1 (6 themes) + B2 (6 themes) = ~24 themes
  /// Plus ~40-50 main grammar topics across all levels
  int _calculateOverallProgress(Map<String, TopicProgress> topicProgress) {
    if (topicProgress.isEmpty) return 0;

    // B2 curriculum requires mastery of many topics
    // Realistic estimation: ~50 main topics need to be studied for B2
    const int totalB2RequiredTopics = 50;

    // Count topics with good progress (>= 60% accuracy)
    int masteredTopics = 0;
    int learningTopics = 0;
    double totalAccuracy = 0;

    topicProgress.forEach((key, value) {
      totalAccuracy += value.progress;
      if (value.progress >= 70) {
        masteredTopics++;
      } else if (value.progress >= 40) {
        learningTopics++;
      }
    });

    // Calculate weighted progress
    // - Mastered topics count as 1.0
    // - Learning topics count as 0.5
    // - Average accuracy also contributes

    final topicCoverage =
        (masteredTopics + (learningTopics * 0.5)) / totalB2RequiredTopics;
    final avgAccuracy = topicProgress.isEmpty
        ? 0
        : totalAccuracy / topicProgress.length;

    // Combine: 60% topic coverage + 40% average accuracy
    final progress = (topicCoverage * 100 * 0.6) + (avgAccuracy * 0.4);

    return progress.round().clamp(0, 100);
  }

  /// Save progress to Firestore
  Future<void> _saveProgress(LearningProgress progress) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc('current')
          .set(progress.toMap());
    } catch (e) {
      print('Error saving progress: $e');
      rethrow;
    }
  }

  /// Get recommended study topics based on weak areas
  Future<List<String>> getRecommendedTopics() async {
    try {
      final progress = await getProgress();

      // Prioritize weak areas
      if (progress.weakAreas.isNotEmpty) {
        return progress.weakAreas.take(3).toList();
      }

      // If no weak areas, suggest new topics
      return progress.recommendedTopics.take(3).toList();
    } catch (e) {
      print('Error getting recommended topics: $e');
      return ['Artikel', 'Perfekt', 'Akkusativ'];
    }
  }

  /// Determine current CEFR level based on progress and topics studied
  String _determineLevel(int overallProgress, int topicsStudied) {
    // More realistic level determination
    // A1: 0-10 topics covered
    // A2: 11-20 topics covered
    // B1: 21-35 topics covered
    // B2: 36-50 topics covered
    // C1: 51+ topics covered

    if (topicsStudied >= 50 && overallProgress >= 75) return 'C1';
    if (topicsStudied >= 36 && overallProgress >= 60) return 'B2';
    if (topicsStudied >= 21 && overallProgress >= 50) return 'B1';
    if (topicsStudied >= 11 && overallProgress >= 40) return 'A2';
    return 'A1';
  }

  /// Get progress statistics for display
  Future<Map<String, dynamic>> getProgressStats() async {
    try {
      final progress = await getProgress();
      final sessions = await getStudyHistory(days: 7);

      // Calculate realistic B2 progress
      final topicsStudied = progress.topicProgress.length;
      final currentLevel = _determineLevel(
        progress.overallProgress,
        topicsStudied,
      );

      return {
        'overallProgress': progress.overallProgress,
        'currentLevel': currentLevel,
        'targetLevel': 'B2',
        'progressToB2': _calculateProgressToB2(
          progress.overallProgress,
          topicsStudied,
        ),
        'strongAreas': progress.strongAreas,
        'weakAreas': progress.weakAreas,
        'recommendedTopics': progress.recommendedTopics,
        'totalStudyDays': progress.totalStudyDays,
        'vocabularyMastered': progress.vocabularyMastered,
        'quizzesTaken': progress.quizzesTaken,
        'averageQuizScore': progress.averageQuizScore,
        'studySessionsThisWeek': sessions.length,
        'topicProgress': progress.topicProgress,
        'topicsStudied': topicsStudied,
        'topicsRemaining': (50 - topicsStudied).clamp(0, 50), // B2 = ~50 topics
      };
    } catch (e) {
      print('Error getting progress stats: $e');
      return {};
    }
  }

  /// Calculate realistic progress percentage towards B2
  /// B2 requires ~50 topics mastered with >60% accuracy + all skill areas
  int _calculateProgressToB2(int currentProgress, int topicsStudied) {
    // B2 requirements:
    // - At least 36 topics studied
    // - At least 60% average accuracy
    // - Coverage of grammar, vocabulary, reading, writing topics

    const int requiredTopics = 36;
    const int requiredAccuracy = 60;

    // Topic coverage: 50%
    final topicScore = (topicsStudied / requiredTopics * 50).clamp(0.0, 50.0);

    // Accuracy score: 50%
    final accuracyScore = (currentProgress / requiredAccuracy * 50).clamp(
      0.0,
      50.0,
    );

    return (topicScore + accuracyScore).round().clamp(0, 100);
  }
}

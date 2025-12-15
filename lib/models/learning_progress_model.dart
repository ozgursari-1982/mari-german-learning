import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for tracking user's learning progress
class LearningProgress {
  final String userId;
  final int overallProgress; // 0-100, progress towards B2
  final String currentLevel; // A1, A2, B1, B2, C1, C2
  final Map<String, TopicProgress> topicProgress; // Topic -> Progress
  final List<String> strongAreas; // Topics user is good at
  final List<String> weakAreas; // Topics user needs to improve
  final List<String> recommendedTopics; // AI recommended topics to study
  final DateTime lastUpdated;
  final Map<String, int> studyStreak; // Days studied per topic
  final int totalStudyDays;
  final int vocabularyMastered;
  final int quizzesTaken;
  final double averageQuizScore;

  LearningProgress({
    required this.userId,
    required this.overallProgress,
    required this.currentLevel,
    required this.topicProgress,
    required this.strongAreas,
    required this.weakAreas,
    required this.recommendedTopics,
    required this.lastUpdated,
    required this.studyStreak,
    this.totalStudyDays = 0,
    this.vocabularyMastered = 0,
    this.quizzesTaken = 0,
    this.averageQuizScore = 0.0,
  });

  factory LearningProgress.fromMap(Map<String, dynamic> map) {
    final topicProgressMap = <String, TopicProgress>{};
    if (map['topicProgress'] != null) {
      (map['topicProgress'] as Map<String, dynamic>).forEach((key, value) {
        topicProgressMap[key] = TopicProgress.fromMap(value);
      });
    }

    return LearningProgress(
      userId: map['userId'] ?? '',
      overallProgress: map['overallProgress'] ?? 0,
      currentLevel: map['currentLevel'] ?? 'A1',
      topicProgress: topicProgressMap,
      strongAreas: List<String>.from(map['strongAreas'] ?? []),
      weakAreas: List<String>.from(map['weakAreas'] ?? []),
      recommendedTopics: List<String>.from(map['recommendedTopics'] ?? []),
      lastUpdated:
          (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      studyStreak: Map<String, int>.from(map['studyStreak'] ?? {}),
      totalStudyDays: map['totalStudyDays'] ?? 0,
      vocabularyMastered: map['vocabularyMastered'] ?? 0,
      quizzesTaken: map['quizzesTaken'] ?? 0,
      averageQuizScore: (map['averageQuizScore'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    final topicProgressMap = <String, dynamic>{};
    topicProgress.forEach((key, value) {
      topicProgressMap[key] = value.toMap();
    });

    return {
      'userId': userId,
      'overallProgress': overallProgress,
      'currentLevel': currentLevel,
      'topicProgress': topicProgressMap,
      'strongAreas': strongAreas,
      'weakAreas': weakAreas,
      'recommendedTopics': recommendedTopics,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'studyStreak': studyStreak,
      'totalStudyDays': totalStudyDays,
      'vocabularyMastered': vocabularyMastered,
      'quizzesTaken': quizzesTaken,
      'averageQuizScore': averageQuizScore,
    };
  }

  LearningProgress copyWith({
    int? overallProgress,
    String? currentLevel,
    Map<String, TopicProgress>? topicProgress,
    List<String>? strongAreas,
    List<String>? weakAreas,
    List<String>? recommendedTopics,
    DateTime? lastUpdated,
    Map<String, int>? studyStreak,
    int? totalStudyDays,
    int? vocabularyMastered,
    int? quizzesTaken,
    double? averageQuizScore,
  }) {
    return LearningProgress(
      userId: userId,
      overallProgress: overallProgress ?? this.overallProgress,
      currentLevel: currentLevel ?? this.currentLevel,
      topicProgress: topicProgress ?? this.topicProgress,
      strongAreas: strongAreas ?? this.strongAreas,
      weakAreas: weakAreas ?? this.weakAreas,
      recommendedTopics: recommendedTopics ?? this.recommendedTopics,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      studyStreak: studyStreak ?? this.studyStreak,
      totalStudyDays: totalStudyDays ?? this.totalStudyDays,
      vocabularyMastered: vocabularyMastered ?? this.vocabularyMastered,
      quizzesTaken: quizzesTaken ?? this.quizzesTaken,
      averageQuizScore: averageQuizScore ?? this.averageQuizScore,
    );
  }
}

/// Progress for a specific topic (e.g., "Perfekt", "Artikel", "Akkusativ")
class TopicProgress {
  final String topicName;
  final int progress; // 0-100
  final int correctAnswers;
  final int totalAttempts;
  final DateTime lastPracticed;
  final String category; // Grammar, Vocabulary, Speaking, etc.

  TopicProgress({
    required this.topicName,
    required this.progress,
    required this.correctAnswers,
    required this.totalAttempts,
    required this.lastPracticed,
    required this.category,
  });

  double get accuracy =>
      totalAttempts > 0 ? (correctAnswers / totalAttempts) * 100 : 0;

  factory TopicProgress.fromMap(Map<String, dynamic> map) {
    return TopicProgress(
      topicName: map['topicName'] ?? '',
      progress: map['progress'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      totalAttempts: map['totalAttempts'] ?? 0,
      lastPracticed:
          (map['lastPracticed'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: map['category'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'topicName': topicName,
      'progress': progress,
      'correctAnswers': correctAnswers,
      'totalAttempts': totalAttempts,
      'lastPracticed': Timestamp.fromDate(lastPracticed),
      'category': category,
    };
  }

  TopicProgress copyWith({
    int? progress,
    int? correctAnswers,
    int? totalAttempts,
    DateTime? lastPracticed,
  }) {
    return TopicProgress(
      topicName: topicName,
      progress: progress ?? this.progress,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      lastPracticed: lastPracticed ?? this.lastPracticed,
      category: category,
    );
  }
}

/// Study session record
class StudySession {
  final String userId;
  final DateTime date;
  final String topic;
  final int duration; // in minutes
  final int questionsAnswered;
  final int correctAnswers;
  final String activityType; // quiz, flashcard, writing, etc.

  StudySession({
    required this.userId,
    required this.date,
    required this.topic,
    required this.duration,
    required this.questionsAnswered,
    required this.correctAnswers,
    required this.activityType,
  });

  factory StudySession.fromMap(Map<String, dynamic> map) {
    return StudySession(
      userId: map['userId'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      topic: map['topic'] ?? '',
      duration: map['duration'] ?? 0,
      questionsAnswered: map['questionsAnswered'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      activityType: map['activityType'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'topic': topic,
      'duration': duration,
      'questionsAnswered': questionsAnswered,
      'correctAnswers': correctAnswers,
      'activityType': activityType,
    };
  }
}

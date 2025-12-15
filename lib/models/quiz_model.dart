enum QuestionType {
  multipleChoice,
  fillInBlanks,
  trueFalse,
  writing,
  matching,
  ordering,
}

class Quiz {
  final String id;
  final String title;
  final String topic;
  final String level;
  final List<Question> questions;
  final DateTime createdAt;

  Quiz({
    required this.id,
    required this.title,
    required this.topic,
    required this.level,
    required this.questions,
    required this.createdAt,
  });
}

class Question {
  final String id;
  final QuestionType type;
  final String questionText;
  final String? questionTextTurkish; // NEW: Turkish translation
  final List<String>? options;
  final Map<String, String>? matchingPairs; // For matching questions
  final String correctAnswer;
  final String? explanation;
  final int points;

  Question({
    required this.id,
    required this.type,
    required this.questionText,
    this.questionTextTurkish, // NEW
    this.options,
    this.matchingPairs,
    required this.correctAnswer,
    this.explanation,
    this.points = 10,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    QuestionType qType;
    switch (json['type']) {
      case 'multipleChoice':
        qType = QuestionType.multipleChoice;
        break;
      case 'fillInBlanks':
        qType = QuestionType.fillInBlanks;
        break;
      case 'trueFalse':
        qType = QuestionType.trueFalse;
        break;
      case 'writing':
        qType = QuestionType.writing;
        break;
      case 'matching':
        qType = QuestionType.matching;
        break;
      case 'ordering':
        qType = QuestionType.ordering;
        break;
      default:
        qType = QuestionType.multipleChoice;
    }

    return Question(
      id:
          DateTime.now().millisecondsSinceEpoch.toString() +
          (json['questionText']?.hashCode.toString() ?? ''),
      type: qType,
      questionText: json['questionText'] ?? '',
      questionTextTurkish: json['questionTextTurkish'], // NEW
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : null,
      matchingPairs: json['matchingPairs'] != null
          ? Map<String, String>.from(json['matchingPairs'])
          : null,
      correctAnswer: json['correctAnswer'] ?? '',
      explanation: json['explanation'],
      points: json['points'] ?? 10,
    );
  }
}

class QuizFeedback {
  final String overallComment;
  final List<String> weakTopics;
  final List<String> strongTopics;
  final List<MistakeAnalysis> mistakeAnalyses;
  final List<AnswerDetail> answerDetails; // NEW: Tüm cevapların detayı
  final String studyRecommendation;

  QuizFeedback({
    required this.overallComment,
    required this.weakTopics,
    required this.strongTopics,
    required this.mistakeAnalyses,
    this.answerDetails = const [], // NEW
    required this.studyRecommendation,
  });

  factory QuizFeedback.fromJson(Map<String, dynamic> json) {
    return QuizFeedback(
      overallComment: json['overallComment'] ?? '',
      weakTopics: List<String>.from(json['weakTopics'] ?? []),
      strongTopics: List<String>.from(json['strongTopics'] ?? []),
      mistakeAnalyses:
          (json['mistakeAnalyses'] as List?)
              ?.map((e) => MistakeAnalysis.fromJson(e))
              .toList() ??
          [],
      answerDetails: // NEW
          (json['answerDetails'] as List?)
              ?.map((e) => AnswerDetail.fromJson(e))
              .toList() ??
          [],
      studyRecommendation: json['studyRecommendation'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'overallComment': overallComment,
      'weakTopics': weakTopics,
      'strongTopics': strongTopics,
      'mistakeAnalyses': mistakeAnalyses.map((e) => e.toMap()).toList(),
      'answerDetails': answerDetails.map((e) => e.toMap()).toList(), // NEW
      'studyRecommendation': studyRecommendation,
    };
  }
}

class MistakeAnalysis {
  final String questionId;
  final String topic;
  final String explanation;
  final String correctUsage;
  final bool partiallyCorrect; // NEW: Küçük hata varsa true
  final String minorIssues; // NEW: Küçük hataların açıklaması
  final String correctedAnswer; // NEW: Düzeltilmiş cevap

  MistakeAnalysis({
    required this.questionId,
    required this.topic,
    required this.explanation,
    required this.correctUsage,
    this.partiallyCorrect = false, // NEW
    this.minorIssues = '', // NEW
    this.correctedAnswer = '', // NEW
  });

  factory MistakeAnalysis.fromJson(Map<String, dynamic> json) {
    return MistakeAnalysis(
      questionId: json['questionId'] ?? '',
      topic: json['topic'] ?? '',
      explanation: json['explanation'] ?? '',
      correctUsage: json['correctUsage'] ?? '',
      partiallyCorrect: json['partiallyCorrect'] ?? false, // NEW
      minorIssues: json['minorIssues'] ?? '', // NEW
      correctedAnswer: json['correctedAnswer'] ?? '', // NEW
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'topic': topic,
      'explanation': explanation,
      'correctUsage': correctUsage,
      'partiallyCorrect': partiallyCorrect, // NEW
      'minorIssues': minorIssues, // NEW
      'correctedAnswer': correctedAnswer, // NEW
    };
  }
}

// NEW: Her cevabın detaylı analizi
class AnswerDetail {
  final String questionId;
  final String questionText;
  final String userAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final bool partiallyCorrect;
  final String minorIssues;
  final String explanation;
  final String topic;

  AnswerDetail({
    required this.questionId,
    required this.questionText,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    this.partiallyCorrect = false,
    this.minorIssues = '',
    required this.explanation,
    required this.topic,
  });

  factory AnswerDetail.fromJson(Map<String, dynamic> json) {
    return AnswerDetail(
      questionId: json['questionId'] ?? '',
      questionText: json['questionText'] ?? '',
      userAnswer: json['userAnswer'] ?? '',
      correctAnswer: json['correctAnswer'] ?? '',
      isCorrect: json['isCorrect'] ?? false,
      partiallyCorrect: json['partiallyCorrect'] ?? false,
      minorIssues: json['minorIssues'] ?? '',
      explanation: json['explanation'] ?? '',
      topic: json['topic'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'questionText': questionText,
      'userAnswer': userAnswer,
      'correctAnswer': correctAnswer,
      'isCorrect': isCorrect,
      'partiallyCorrect': partiallyCorrect,
      'minorIssues': minorIssues,
      'explanation': explanation,
      'topic': topic,
    };
  }
}

class Lesson {
  final String title;
  final String explanation;
  final List<Map<String, String>> examples;
  final List<String> tips;

  Lesson({
    required this.title,
    required this.explanation,
    required this.examples,
    required this.tips,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      title: json['title'] ?? '',
      explanation: json['explanation'] ?? '',
      examples:
          (json['examples'] as List?)
              ?.map((e) => Map<String, String>.from(e))
              .toList() ??
          [],
      tips: List<String>.from(json['tips'] ?? []),
    );
  }
}

class QuizResult {
  final String id;
  final String quizId;
  final String quizTitle;
  final String quizTopic;
  final String quizLevel;
  final int score;
  final int totalPoints;
  final DateTime date;
  final QuizFeedback feedback;

  QuizResult({
    required this.id,
    required this.quizId,
    required this.quizTitle,
    required this.quizTopic,
    required this.quizLevel,
    required this.score,
    required this.totalPoints,
    required this.date,
    required this.feedback,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quizId': quizId,
      'quizTitle': quizTitle,
      'quizTopic': quizTopic,
      'quizLevel': quizLevel,
      'score': score,
      'totalPoints': totalPoints,
      'date': date.toIso8601String(),
      'feedback': feedback.toMap(),
    };
  }

  factory QuizResult.fromMap(Map<String, dynamic> map) {
    return QuizResult(
      id: map['id'] ?? '',
      quizId: map['quizId'] ?? '',
      quizTitle: map['quizTitle'] ?? '',
      quizTopic: map['quizTopic'] ?? '',
      quizLevel: map['quizLevel'] ?? '',
      score: map['score'] ?? 0,
      totalPoints: map['totalPoints'] ?? 0,
      date: DateTime.parse(map['date']),
      feedback: QuizFeedback.fromJson(map['feedback']),
    );
  }
}

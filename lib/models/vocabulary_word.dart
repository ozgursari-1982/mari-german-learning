import 'package:cloud_firestore/cloud_firestore.dart';

/// Learning status of a vocabulary word
enum LearningStatus {
  new_word, // Yeni görüldü
  learning, // Öğreniliyor
  learned, // Öğrenildi
  mastered, // Ustalaşıldı
}

/// Model for vocabulary words with spaced repetition support
class VocabularyWord {
  final String id;
  final String userId;
  final String german;
  final String article; // der, die, das
  final String plural;
  final String translation;
  final String exampleSentence;
  final String professionalContext;
  final String languageLevel; // A1, A2, B1, B2, C1, C2
  final String category; // Business, Technical, Medical, etc.

  // Learning tracking
  final DateTime firstSeenAt;
  final DateTime lastReviewedAt;
  final DateTime nextReviewAt;
  final int reviewCount;
  final double easinessFactor; // SM-2 algorithm (1.3 - 2.5)
  final int consecutiveCorrect;
  final LearningStatus status;

  // Source document
  final String? sourceDocumentId;
  final String? sourceCategory;
  final String? sourceTopic; // Konu başlığı (ör: Berufliche Einstiege)

  VocabularyWord({
    required this.id,
    required this.userId,
    required this.german,
    this.article = '',
    this.plural = '',
    required this.translation,
    this.exampleSentence = '',
    this.professionalContext = '',
    this.languageLevel = 'B1',
    this.category = '',
    required this.firstSeenAt,
    required this.lastReviewedAt,
    required this.nextReviewAt,
    this.reviewCount = 0,
    this.easinessFactor = 2.5,
    this.consecutiveCorrect = 0,
    this.status = LearningStatus.new_word,
    this.sourceDocumentId,
    this.sourceCategory,
    this.sourceTopic,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'german': german,
      'article': article,
      'plural': plural,
      'translation': translation,
      'exampleSentence': exampleSentence,
      'professionalContext': professionalContext,
      'languageLevel': languageLevel,
      'category': category,
      'firstSeenAt': Timestamp.fromDate(firstSeenAt),
      'lastReviewedAt': Timestamp.fromDate(lastReviewedAt),
      'nextReviewAt': Timestamp.fromDate(nextReviewAt),
      'reviewCount': reviewCount,
      'easinessFactor': easinessFactor,
      'consecutiveCorrect': consecutiveCorrect,
      'status': status.toString().split('.').last,
      'sourceDocumentId': sourceDocumentId,
      'sourceCategory': sourceCategory,
      'sourceTopic': sourceTopic,
    };
  }

  factory VocabularyWord.fromMap(Map<String, dynamic> map) {
    return VocabularyWord(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      german: map['german'] ?? '',
      article: map['article'] ?? '',
      plural: map['plural'] ?? '',
      translation: map['translation'] ?? '',
      exampleSentence: map['exampleSentence'] ?? '',
      professionalContext: map['professionalContext'] ?? '',
      languageLevel: map['languageLevel'] ?? 'B1',
      category: map['category'] ?? '',
      firstSeenAt: (map['firstSeenAt'] as Timestamp).toDate(),
      lastReviewedAt: (map['lastReviewedAt'] as Timestamp).toDate(),
      nextReviewAt: (map['nextReviewAt'] as Timestamp).toDate(),
      reviewCount: map['reviewCount'] ?? 0,
      easinessFactor: (map['easinessFactor'] ?? 2.5).toDouble(),
      consecutiveCorrect: map['consecutiveCorrect'] ?? 0,
      status: _parseStatus(map['status']),
      sourceDocumentId: map['sourceDocumentId'],
      sourceCategory: map['sourceCategory'],
      sourceTopic: map['sourceTopic'],
    );
  }

  static LearningStatus _parseStatus(String? status) {
    switch (status) {
      case 'new_word':
        return LearningStatus.new_word;
      case 'learning':
        return LearningStatus.learning;
      case 'learned':
        return LearningStatus.learned;
      case 'mastered':
        return LearningStatus.mastered;
      default:
        return LearningStatus.new_word;
    }
  }

  /// Create a copy with updated fields
  VocabularyWord copyWith({
    DateTime? lastReviewedAt,
    DateTime? nextReviewAt,
    int? reviewCount,
    double? easinessFactor,
    int? consecutiveCorrect,
    LearningStatus? status,
  }) {
    return VocabularyWord(
      id: id,
      userId: userId,
      german: german,
      article: article,
      plural: plural,
      translation: translation,
      exampleSentence: exampleSentence,
      professionalContext: professionalContext,
      languageLevel: languageLevel,
      category: category,
      firstSeenAt: firstSeenAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      reviewCount: reviewCount ?? this.reviewCount,
      easinessFactor: easinessFactor ?? this.easinessFactor,
      consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
      status: status ?? this.status,
      sourceDocumentId: sourceDocumentId,
      sourceCategory: sourceCategory,
      sourceTopic: sourceTopic,
    );
  }
}

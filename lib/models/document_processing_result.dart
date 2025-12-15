import 'package:cloud_firestore/cloud_firestore.dart';
import 'document_analysis_model.dart';
import 'quiz_model.dart';

/// Result of document processing with all generated content
class DocumentProcessingResult {
  final DocumentType processedType;
  final Map<String, dynamic>? exerciseSolution; // Alıştırma çözümü
  final Lesson? exerciseTheoryLesson; // Alıştırma için konu anlatımı
  final Map<String, dynamic>? dialogueActivity; // Diyalog aktivitesi
  final Lesson? dialogueTheoryLesson; // Diyalog için konu anlatımı
  final Lesson? theoryLesson; // Konu anlatımı için ders
  final Lesson? grammarLesson; // Gramer ders anlatımı
  final List<String> savedVocabularyIds; // Kaydedilen kelimeler
  final Lesson? vocabularyTheoryLesson; // Kelimeler için konu anlatımı
  final Map<String, dynamic>? mixedContentResults; // Mixed içerik sonuçları
  final Map<String, dynamic>? grammarExplanation; // Enhanced gramer açıklaması
  final bool isComplete;
  final List<String> errors;
  final DateTime processedAt;

  DocumentProcessingResult({
    required this.processedType,
    this.exerciseSolution,
    this.exerciseTheoryLesson,
    this.dialogueActivity,
    this.dialogueTheoryLesson,
    this.theoryLesson,
    this.grammarLesson,
    this.savedVocabularyIds = const [],
    this.vocabularyTheoryLesson,
    this.mixedContentResults,
    this.grammarExplanation,
    this.isComplete = false,
    this.errors = const [],
    required this.processedAt,
  });

  factory DocumentProcessingResult.fromMap(Map<String, dynamic> map) {
    return DocumentProcessingResult(
      processedType: _parseDocumentType(map['processedType']),
      exerciseSolution: map['exerciseSolution'] as Map<String, dynamic>?,
      exerciseTheoryLesson: map['exerciseTheoryLesson'] != null
          ? Lesson.fromJson(map['exerciseTheoryLesson'] as Map<String, dynamic>)
          : null,
      dialogueActivity: map['dialogueActivity'] as Map<String, dynamic>?,
      dialogueTheoryLesson: map['dialogueTheoryLesson'] != null
          ? Lesson.fromJson(map['dialogueTheoryLesson'] as Map<String, dynamic>)
          : null,
      theoryLesson: map['theoryLesson'] != null
          ? Lesson.fromJson(map['theoryLesson'] as Map<String, dynamic>)
          : null,
      grammarLesson: map['grammarLesson'] != null
          ? Lesson.fromJson(map['grammarLesson'] as Map<String, dynamic>)
          : null,
      savedVocabularyIds: List<String>.from(map['savedVocabularyIds'] ?? []),
      vocabularyTheoryLesson: map['vocabularyTheoryLesson'] != null
          ? Lesson.fromJson(
              map['vocabularyTheoryLesson'] as Map<String, dynamic>,
            )
          : null,
      mixedContentResults: map['mixedContentResults'] as Map<String, dynamic>?,
      grammarExplanation: map['grammarExplanation'] as Map<String, dynamic>?,
      isComplete: map['isComplete'] ?? false,
      errors: List<String>.from(map['errors'] ?? []),
      processedAt:
          (map['processedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'processedType': processedType.toString().split('.').last,
      'exerciseSolution': exerciseSolution,
      'exerciseTheoryLesson': exerciseTheoryLesson?.toJson(),
      'dialogueActivity': dialogueActivity,
      'dialogueTheoryLesson': dialogueTheoryLesson?.toJson(),
      'theoryLesson': theoryLesson?.toJson(),
      'grammarLesson': grammarLesson?.toJson(),
      'savedVocabularyIds': savedVocabularyIds,
      'vocabularyTheoryLesson': vocabularyTheoryLesson?.toJson(),
      'mixedContentResults': mixedContentResults,
      'grammarExplanation': grammarExplanation,
      'isComplete': isComplete,
      'errors': errors,
      'processedAt': Timestamp.fromDate(processedAt),
    };
  }

  /// Create a copy of this result with updated fields
  DocumentProcessingResult copyWith({
    DocumentType? processedType,
    Map<String, dynamic>? exerciseSolution,
    Lesson? exerciseTheoryLesson,
    Map<String, dynamic>? dialogueActivity,
    Lesson? dialogueTheoryLesson,
    Lesson? theoryLesson,
    Lesson? grammarLesson,
    List<String>? savedVocabularyIds,
    Lesson? vocabularyTheoryLesson,
    Map<String, dynamic>? mixedContentResults,
    Map<String, dynamic>? grammarExplanation,
    bool? isComplete,
    List<String>? errors,
    DateTime? processedAt,
  }) {
    return DocumentProcessingResult(
      processedType: processedType ?? this.processedType,
      exerciseSolution: exerciseSolution ?? this.exerciseSolution,
      exerciseTheoryLesson: exerciseTheoryLesson ?? this.exerciseTheoryLesson,
      dialogueActivity: dialogueActivity ?? this.dialogueActivity,
      dialogueTheoryLesson: dialogueTheoryLesson ?? this.dialogueTheoryLesson,
      theoryLesson: theoryLesson ?? this.theoryLesson,
      grammarLesson: grammarLesson ?? this.grammarLesson,
      savedVocabularyIds: savedVocabularyIds ?? this.savedVocabularyIds,
      vocabularyTheoryLesson:
          vocabularyTheoryLesson ?? this.vocabularyTheoryLesson,
      mixedContentResults: mixedContentResults ?? this.mixedContentResults,
      grammarExplanation: grammarExplanation ?? this.grammarExplanation,
      isComplete: isComplete ?? this.isComplete,
      errors: errors ?? this.errors,
      processedAt: processedAt ?? this.processedAt,
    );
  }

  static DocumentType _parseDocumentType(String? type) {
    switch (type?.toLowerCase()) {
      case 'vocabulary':
        return DocumentType.vocabulary;
      case 'grammar':
        return DocumentType.grammar;
      case 'professionaltext':
        return DocumentType.professionalText;
      case 'exercise':
      case 'practice':
        return DocumentType.exercise;
      case 'dialogue':
        return DocumentType.dialogue;
      case 'mixed':
      case 'theory': // Map theory to mixed
      case 'pdfgeneral': // Map pdfgeneral to mixed
        return DocumentType.mixed;
      default:
        return DocumentType.unknown;
    }
  }
}

extension LessonExtension on Lesson {
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'explanation': explanation,
      'examples': examples,
      'tips': tips,
    };
  }

  static Lesson fromJson(Map<String, dynamic> json) {
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

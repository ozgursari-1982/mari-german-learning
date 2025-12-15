/// Document type enumeration for intelligent analysis
enum DocumentType {
  vocabulary, // Wortschatz/Kelime listeleri
  grammar, // Gramer dersleri
  professionalText, // Mesleki metinler (Berufsprache)
  exercise, // Alıştırmalar
  dialogue, // Diyaloglar
  mixed, // Karışık içerik
  unknown, // Belirlenemedi
}

/// Language level enumeration (CEFR)
enum LanguageLevel { a1, a2, b1, b2, c1, c2, unknown }

/// Enhanced document analysis with intelligent type detection
class EnhancedDocumentAnalysis {
  final DocumentType documentType;
  final LanguageLevel languageLevel;
  final String mainTopic;
  final String mainTheme;
  final List<String> categories;
  final List<EnhancedVocabularyItem> vocabulary;
  final List<GrammarRule> grammarRules;
  final String extractedText;
  final List<String> keyTopics;
  final String professionalContext;
  final bool isBerufsprache;
  final double confidence; // 0-1, analiz güvenilirliği
  final SimpleCategorySuggestion? categorySuggestion;
  final List<ContentSection> contentStructure;
  final List<ImageDescription> imageDescriptions;
  final ActivityInstructions? activityInstructions;
  final bool hasVisualElements;

  EnhancedDocumentAnalysis({
    required this.documentType,
    required this.languageLevel,
    required this.mainTopic,
    required this.mainTheme,
    required this.categories,
    required this.vocabulary,
    required this.grammarRules,
    required this.extractedText,
    required this.keyTopics,
    required this.professionalContext,
    required this.isBerufsprache,
    required this.confidence,
    this.categorySuggestion,
    this.contentStructure = const [],
    this.imageDescriptions = const [],
    this.activityInstructions,
    this.hasVisualElements = false,
  });

  factory EnhancedDocumentAnalysis.fromJson(Map<String, dynamic> json) {
    return EnhancedDocumentAnalysis(
      documentType: _parseDocumentType(json['documentType']),
      languageLevel: _parseLanguageLevel(json['languageLevel']),
      mainTopic: json['mainTopic'] ?? '',
      mainTheme: json['mainTheme'] ?? '',
      categories: List<String>.from(json['categories'] ?? []),
      vocabulary:
          (json['vocabulary'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((v) => EnhancedVocabularyItem.fromJson(v))
              .toList() ??
          [],
      grammarRules:
          (json['grammarRules'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((g) => GrammarRule.fromJson(g))
              .toList() ??
          [],
      extractedText: json['extractedText'] ?? '',
      keyTopics: List<String>.from(json['keyTopics'] ?? []),
      professionalContext: json['professionalContext'] ?? '',
      isBerufsprache: json['isBerufsprache'] ?? false,
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      categorySuggestion: json['categorySuggestion'] != null
          ? SimpleCategorySuggestion.fromJson(json['categorySuggestion'])
          : null,
      contentStructure:
          (json['contentStructure'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((s) => ContentSection.fromJson(s))
              .toList() ??
          [],
      imageDescriptions:
          (json['imageDescriptions'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((i) => ImageDescription.fromJson(i))
              .toList() ??
          [],
      activityInstructions: json['activityInstructions'] != null
          ? ActivityInstructions.fromJson(json['activityInstructions'])
          : null,
      hasVisualElements: json['hasVisualElements'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'documentType': documentType.toString().split('.').last,
      'languageLevel': languageLevel.toString().split('.').last,
      'mainTopic': mainTopic,
      'mainTheme': mainTheme,
      'categories': categories,
      'vocabulary': vocabulary.map((v) => v.toJson()).toList(),
      'grammarRules': grammarRules.map((g) => g.toJson()).toList(),
      'extractedText': extractedText,
      'keyTopics': keyTopics,
      'professionalContext': professionalContext,
      'isBerufsprache': isBerufsprache,
      'confidence': confidence,
      'categorySuggestion': categorySuggestion?.toJson(),
      'contentStructure': contentStructure.map((s) => s.toJson()).toList(),
      'imageDescriptions': imageDescriptions.map((i) => i.toJson()).toList(),
      'activityInstructions': activityInstructions?.toJson(),
      'hasVisualElements': hasVisualElements,
    };
  }

  static DocumentType _parseDocumentType(String? type) {
    switch (type?.toLowerCase()) {
      case 'vocabulary':
      case 'wortschatz':
        return DocumentType.vocabulary;
      case 'grammar':
      case 'grammatik':
        return DocumentType.grammar;
      case 'professional':
      case 'berufsprache':
      case 'professionaltext':
        return DocumentType.professionalText;
      case 'exercise':
      case 'übung':
        return DocumentType.exercise;
      case 'dialogue':
      case 'dialog':
        return DocumentType.dialogue;
      case 'mixed':
        return DocumentType.mixed;
      case 'pdf_general':
      case 'pdfgeneral':
        return DocumentType
            .mixed; // Map pdf_general to mixed for now or add new enum value if needed
      default:
        return DocumentType.unknown;
    }
  }

  static LanguageLevel _parseLanguageLevel(String? level) {
    switch (level?.toLowerCase()) {
      case 'a1':
        return LanguageLevel.a1;
      case 'a2':
        return LanguageLevel.a2;
      case 'b1':
        return LanguageLevel.b1;
      case 'b2':
        return LanguageLevel.b2;
      case 'c1':
        return LanguageLevel.c1;
      case 'c2':
        return LanguageLevel.c2;
      default:
        return LanguageLevel.unknown;
    }
  }
}

class ContentSection {
  final String title;
  final String type; // grammar, exercise, vocabulary, text
  final String description;

  ContentSection({
    required this.title,
    required this.type,
    required this.description,
  });

  factory ContentSection.fromJson(Map<String, dynamic> json) {
    return ContentSection(
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'type': type, 'description': description};
  }
}

/// Enhanced vocabulary item with professional context
class EnhancedVocabularyItem {
  final String german;
  final String translation;
  final String article; // der, die, das
  final String plural;
  final String exampleSentence;
  final String professionalContext; // Hangi mesleki bağlamda kullanılır

  EnhancedVocabularyItem({
    required this.german,
    required this.translation,
    this.article = '',
    this.plural = '',
    this.exampleSentence = '',
    this.professionalContext = '',
  });

  factory EnhancedVocabularyItem.fromJson(Map<String, dynamic> json) {
    return EnhancedVocabularyItem(
      german: json['german'] ?? '',
      translation: json['translation'] ?? '',
      article: json['article'] ?? '',
      plural: json['plural'] ?? '',
      exampleSentence: json['exampleSentence'] ?? '',
      professionalContext: json['professionalContext'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'german': german,
      'translation': translation,
      'article': article,
      'plural': plural,
      'exampleSentence': exampleSentence,
      'professionalContext': professionalContext,
    };
  }
}

/// Grammar rule extracted from document
class GrammarRule {
  final String rule;
  final String explanation;
  final List<String> examples;

  GrammarRule({
    required this.rule,
    required this.explanation,
    required this.examples,
  });

  factory GrammarRule.fromJson(Map<String, dynamic> json) {
    return GrammarRule(
      rule: json['rule'] ?? '',
      explanation: json['explanation'] ?? '',
      examples: List<String>.from(json['examples'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {'rule': rule, 'explanation': explanation, 'examples': examples};
  }
}

/// AI's category suggestion for document
class SimpleCategorySuggestion {
  final String mainCategory;
  final String subCategory;
  final String reason;

  SimpleCategorySuggestion({
    required this.mainCategory,
    required this.subCategory,
    required this.reason,
  });

  factory SimpleCategorySuggestion.fromJson(Map<String, dynamic> json) {
    return SimpleCategorySuggestion(
      mainCategory: json['mainCategory'] ?? '',
      subCategory: json['subCategory'] ?? '',
      reason: json['reason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mainCategory': mainCategory,
      'subCategory': subCategory,
      'reason': reason,
    };
  }
}

class StudyMaterialAnalysis {
  final String primaryCategory;
  final String subCategory;
  final String extractedText;
  final List<String> mainTopics;
  final List<String> grammarStructures;
  final String vocabularyLevel;
  final List<VocabularyItem> keyVocabulary;
  final String learningFocus;
  final int difficultyRating;
  final String recommendations;

  StudyMaterialAnalysis({
    required this.primaryCategory,
    required this.subCategory,
    required this.extractedText,
    required this.mainTopics,
    required this.grammarStructures,
    required this.vocabularyLevel,
    required this.keyVocabulary,
    required this.learningFocus,
    required this.difficultyRating,
    required this.recommendations,
  });
}

class VocabularyItem {
  final String german;
  final String turkish;
  final String example;

  VocabularyItem({
    required this.german,
    required this.turkish,
    required this.example,
  });
}

/// Image description for visual learning materials
class ImageDescription {
  final int imageNumber;
  final String description;
  final List<ImageVocabularyWord> relevantVocabulary;
  final String profession;
  final String activity;

  ImageDescription({
    required this.imageNumber,
    required this.description,
    required this.relevantVocabulary,
    this.profession = '',
    this.activity = '',
  });

  factory ImageDescription.fromJson(Map<String, dynamic> json) {
    // Parse relevantVocabulary - can be either array of strings or array of objects
    List<ImageVocabularyWord> vocabulary = [];
    if (json['relevantVocabulary'] != null) {
      final vocabList = json['relevantVocabulary'] as List;
      for (var item in vocabList) {
        if (item is Map<String, dynamic>) {
          vocabulary.add(ImageVocabularyWord.fromJson(item));
        } else if (item is String) {
          // Backward compatibility: if it's just a string, use it as german word
          vocabulary.add(ImageVocabularyWord(german: item, turkish: ''));
        }
      }
    }

    return ImageDescription(
      imageNumber: json['imageNumber'] ?? 0,
      description: json['description'] ?? '',
      relevantVocabulary: vocabulary,
      profession: json['profession'] ?? '',
      activity: json['activity'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageNumber': imageNumber,
      'description': description,
      'relevantVocabulary': relevantVocabulary.map((v) => v.toJson()).toList(),
      'profession': profession,
      'activity': activity,
    };
  }
}

/// Vocabulary word for image descriptions
class ImageVocabularyWord {
  final String german;
  final String turkish;

  ImageVocabularyWord({required this.german, required this.turkish});

  factory ImageVocabularyWord.fromJson(Map<String, dynamic> json) {
    return ImageVocabularyWord(
      german: json['german'] ?? '',
      turkish: json['turkish'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'german': german, 'turkish': turkish};
  }
}

/// Activity instructions for dialogue and exercise activities
class ActivityInstructions {
  final String german;
  final String turkish;
  final String activityType;

  ActivityInstructions({
    required this.german,
    required this.turkish,
    required this.activityType,
  });

  factory ActivityInstructions.fromJson(Map<String, dynamic> json) {
    return ActivityInstructions(
      german: json['german'] ?? '',
      turkish: json['turkish'] ?? '',
      activityType: json['activityType'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'german': german, 'turkish': turkish, 'activityType': activityType};
  }
}

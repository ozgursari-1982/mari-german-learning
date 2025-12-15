import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/document_analysis_model.dart';
import '../models/document_processing_result.dart';
import '../models/quiz_model.dart';
import 'gemini_ai_service.dart';
import 'vocabulary_service.dart';

/// Service for processing documents based on user-selected content type
/// Automatically generates content with theory lessons, grammar explanations, and examples
class DocumentProcessingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GeminiAIService _aiService = GeminiAIService();
  final String userId;

  DocumentProcessingService(this.userId);

  /// Process document based on user-selected content type
  /// Automatically generates appropriate content with theory + grammar + examples
  Future<DocumentProcessingResult> processDocument({
    required EnhancedDocumentAnalysis analysis,
    required DocumentType userSelectedType,
    required String documentId,
    required String extractedText,
    String? categoryId, // Yeni parametre
    List<ImageDescription>? imageDescriptions,
  }) async {
    final errors = <String>[];
    final processedAt = DateTime.now();

    try {
      switch (userSelectedType) {
        case DocumentType.vocabulary:
          return await _processVocabulary(
            analysis,
            documentId,
            extractedText,
            categoryId,
            errors,
            processedAt,
          );

        case DocumentType.exercise:
          return await _processPractice(
            analysis,
            documentId,
            extractedText,
            errors,
            processedAt,
          );

        case DocumentType.grammar:
          return await _processGrammar(
            analysis,
            documentId,
            extractedText,
            errors,
            processedAt,
          );

        case DocumentType.dialogue:
          return await _processDialogue(
            analysis,
            documentId,
            extractedText,
            imageDescriptions,
            errors,
            processedAt,
          );

        case DocumentType.mixed:
          return await _processMixed(
            analysis,
            documentId,
            extractedText,
            categoryId,
            imageDescriptions,
            errors,
            processedAt,
          );

        default:
          return DocumentProcessingResult(
            processedType: userSelectedType,
            errors: [
              'Desteklenmeyen içerik tipi: ${userSelectedType.toString()}',
            ],
            processedAt: processedAt,
          );
      }
    } catch (e) {
      print('Error processing document: $e');
      return DocumentProcessingResult(
        processedType: userSelectedType,
        errors: ['İşlem sırasında hata oluştu: $e'],
        processedAt: processedAt,
      );
    }
  }

  /// Process vocabulary document - save words and generate theory lesson
  Future<DocumentProcessingResult> _processVocabulary(
    EnhancedDocumentAnalysis analysis,
    String documentId,
    String extractedText,
    String? categoryId,
    List<String> errors,
    DateTime processedAt,
  ) async {
    try {
      final vocabService = VocabularyService(userId);
      final savedIds = await vocabService.saveVocabularyFromAnalysis(
        analysis: analysis,
        documentId: documentId,
        topic: analysis.mainTopic,
        categoryId: categoryId,
      );

      // Generate theory lesson about vocabulary usage
      Lesson? vocabularyTheoryLesson;
      try {
        vocabularyTheoryLesson = await _aiService.generateLesson(
          '${analysis.mainTopic} - Kelime Kullanımı',
        );
      } catch (e) {
        errors.add('Kelime konu anlatımı oluşturulurken hata: $e');
      }

      final result = DocumentProcessingResult(
        processedType: DocumentType.vocabulary,
        savedVocabularyIds: savedIds,
        vocabularyTheoryLesson: vocabularyTheoryLesson,
        isComplete: true,
        errors: errors,
        processedAt: processedAt,
      );

      await _saveProcessingResult(documentId, result);
      return result;
    } catch (e) {
      errors.add('Kelime işleme hatası: $e');
      return DocumentProcessingResult(
        processedType: DocumentType.vocabulary,
        errors: errors,
        processedAt: processedAt,
      );
    }
  }

  /// Process practice/exercise document - generate solution + theory lesson
  Future<DocumentProcessingResult> _processPractice(
    EnhancedDocumentAnalysis analysis,
    String documentId,
    String extractedText,
    List<String> errors,
    DateTime processedAt,
  ) async {
    try {
      // Generate exercise solution
      final exerciseSolution = await _aiService.generateExerciseSolution(
        extractedText: extractedText,
        mainTopic: analysis.mainTopic,
        languageLevel: analysis.languageLevel
            .toString()
            .split('.')
            .last
            .toUpperCase(),
      );

      // Generate theory lesson about the exercise topic
      Lesson? exerciseTheoryLesson;
      try {
        exerciseTheoryLesson = await _aiService.generateLesson(
          '${analysis.mainTopic} - Alıştırma Konusu',
        );
      } catch (e) {
        errors.add('Alıştırma konu anlatımı oluşturulurken hata: $e');
      }

      final result = DocumentProcessingResult(
        processedType: DocumentType.exercise,
        exerciseSolution: exerciseSolution,
        exerciseTheoryLesson: exerciseTheoryLesson,
        isComplete: true,
        errors: errors,
        processedAt: processedAt,
      );

      await _saveProcessingResult(documentId, result);
      return result;
    } catch (e) {
      errors.add('Alıştırma işleme hatası: $e');
      return DocumentProcessingResult(
        processedType: DocumentType.exercise,
        errors: errors,
        processedAt: processedAt,
      );
    }
  }

  /// Process grammar document - generate detailed grammar lesson
  Future<DocumentProcessingResult> _processGrammar(
    EnhancedDocumentAnalysis analysis,
    String documentId,
    String extractedText,
    List<String> errors,
    DateTime processedAt,
  ) async {
    try {
      // Generate detailed grammar lesson
      final grammarLesson = await _aiService.generateLesson(analysis.mainTopic);

      final result = DocumentProcessingResult(
        processedType: DocumentType.grammar,
        grammarLesson: grammarLesson,
        isComplete: true,
        errors: errors,
        processedAt: processedAt,
      );

      await _saveProcessingResult(documentId, result);
      return result;
    } catch (e) {
      errors.add('Gramer ders oluşturulurken hata: $e');
      return DocumentProcessingResult(
        processedType: DocumentType.grammar,
        errors: errors,
        processedAt: processedAt,
      );
    }
  }

  /// Process dialogue document - generate dialogue activity + theory lesson
  Future<DocumentProcessingResult> _processDialogue(
    EnhancedDocumentAnalysis analysis,
    String documentId,
    String extractedText,
    List<ImageDescription>? imageDescriptions,
    List<String> errors,
    DateTime processedAt,
  ) async {
    try {
      // Convert ImageDescription to Map for API
      List<Map<String, dynamic>>? imageDescs;
      if (imageDescriptions != null && imageDescriptions.isNotEmpty) {
        imageDescs = imageDescriptions
            .map(
              (img) => {
                'imageNumber': img.imageNumber,
                'description': img.description,
                'profession': img.profession,
                'activity': img.activity,
                'relevantVocabulary': img.relevantVocabulary
                    .map((v) => {'german': v.german, 'turkish': v.turkish})
                    .toList(),
              },
            )
            .toList();
      }

      // Generate dialogue activity
      final dialogueActivity = await _aiService.generateDialogueActivity(
        extractedText: extractedText,
        mainTopic: analysis.mainTopic,
        languageLevel: analysis.languageLevel
            .toString()
            .split('.')
            .last
            .toUpperCase(),
        imageDescriptions: imageDescs,
      );

      // Generate theory lesson about dialogue topic
      Lesson? dialogueTheoryLesson;
      try {
        dialogueTheoryLesson = await _aiService.generateLesson(
          '${analysis.mainTopic} - Diyalog Konusu',
        );
      } catch (e) {
        errors.add('Diyalog konu anlatımı oluşturulurken hata: $e');
      }

      final result = DocumentProcessingResult(
        processedType: DocumentType.dialogue,
        dialogueActivity: dialogueActivity,
        dialogueTheoryLesson: dialogueTheoryLesson,
        isComplete: true,
        errors: errors,
        processedAt: processedAt,
      );

      await _saveProcessingResult(documentId, result);
      return result;
    } catch (e) {
      errors.add('Diyalog işleme hatası: $e');
      return DocumentProcessingResult(
        processedType: DocumentType.dialogue,
        errors: errors,
        processedAt: processedAt,
      );
    }
  }

  /// Process mixed content document - process all content types
  Future<DocumentProcessingResult> _processMixed(
    EnhancedDocumentAnalysis analysis,
    String documentId,
    String extractedText,
    String? categoryId,
    List<ImageDescription>? imageDescriptions,
    List<String> errors,
    DateTime processedAt,
  ) async {
    try {
      final mixedResults = <String, dynamic>{};

      // Process each content type found in contentStructure
      for (var section in analysis.contentStructure) {
        try {
          if (section.type == 'exercise' || section.type == 'practice') {
            final solution = await _aiService.generateExerciseSolution(
              extractedText: extractedText,
              mainTopic: section.title,
              languageLevel: analysis.languageLevel
                  .toString()
                  .split('.')
                  .last
                  .toUpperCase(),
            );
            mixedResults['exercise'] = solution;
          } else if (section.type == 'dialogue') {
            List<Map<String, dynamic>>? imageDescs;
            if (imageDescriptions != null) {
              imageDescs = imageDescriptions
                  .map(
                    (img) => {
                      'imageNumber': img.imageNumber,
                      'description': img.description,
                      'profession': img.profession,
                      'activity': img.activity,
                      'relevantVocabulary': img.relevantVocabulary
                          .map(
                            (v) => {'german': v.german, 'turkish': v.turkish},
                          )
                          .toList(),
                    },
                  )
                  .toList();
            }
            final dialogue = await _aiService.generateDialogueActivity(
              extractedText: extractedText,
              mainTopic: section.title,
              languageLevel: analysis.languageLevel
                  .toString()
                  .split('.')
                  .last
                  .toUpperCase(),
              imageDescriptions: imageDescs,
            );
            mixedResults['dialogue'] = dialogue;
          } else if (section.type == 'grammar') {
            final grammar = await _aiService.generateLesson(section.title);
            mixedResults['grammar'] = {
              'title': grammar.title,
              'explanation': grammar.explanation,
              'examples': grammar.examples,
              'tips': grammar.tips,
            };
          } else if (section.type == 'theory') {
            final theory = await _aiService.generateLesson(section.title);
            mixedResults['theory'] = {
              'title': theory.title,
              'explanation': theory.explanation,
              'examples': theory.examples,
              'tips': theory.tips,
            };
          } else if (section.type == 'vocabulary') {
            final vocabService = VocabularyService(userId);
            final savedIds = await vocabService.saveVocabularyFromAnalysis(
              analysis: analysis,
              documentId: documentId,
              topic: analysis.mainTopic,
              categoryId: categoryId,
            );
            mixedResults['vocabulary'] = savedIds;
          }
        } catch (e) {
          errors.add('${section.type} işlenirken hata: $e');
        }
      }

      final result = DocumentProcessingResult(
        processedType: DocumentType.mixed,
        mixedContentResults: mixedResults,
        isComplete: true,
        errors: errors,
        processedAt: processedAt,
      );

      await _saveProcessingResult(documentId, result);
      return result;
    } catch (e) {
      errors.add('Karışık içerik işleme hatası: $e');
      return DocumentProcessingResult(
        processedType: DocumentType.mixed,
        errors: errors,
        processedAt: processedAt,
      );
    }
  }

  /// Save processing result to Firestore
  Future<void> _saveProcessingResult(
    String documentId,
    DocumentProcessingResult result,
  ) async {
    try {
      await _firestore.collection('study_documents').doc(documentId).update({
        'processingResults': result.toMap(),
      });
    } catch (e) {
      print('Error saving processing result: $e');
    }
  }

  /// Get processing result from Firestore
  Future<DocumentProcessingResult?> getProcessingResult(
    String documentId,
  ) async {
    try {
      final doc = await _firestore
          .collection('study_documents')
          .doc(documentId)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['processingResults'] != null) {
          return DocumentProcessingResult.fromMap(
            data['processingResults'] as Map<String, dynamic>,
          );
        }
      }
      return null;
    } catch (e) {
      print('Error getting processing result: $e');
      return null;
    }
  }

  /// Save special content (dialogue or exercise) to cache
  /// This is a public method for UI to save generated content
  Future<void> saveSpecialContent({
    required String documentId,
    required DocumentType contentType,
    required Map<String, dynamic> content,
  }) async {
    try {
      // Get existing result or create new one
      final existing = await getProcessingResult(documentId);

      DocumentProcessingResult result;
      if (existing != null) {
        // Update existing result
        result = existing.copyWith(
          dialogueActivity: contentType == DocumentType.dialogue
              ? content
              : existing.dialogueActivity,
          exerciseSolution: contentType == DocumentType.exercise
              ? content
              : existing.exerciseSolution,
          grammarExplanation: contentType == DocumentType.grammar
              ? content
              : existing.grammarExplanation,
        );
      } else {
        // Create new result
        result = DocumentProcessingResult(
          processedType: contentType,
          dialogueActivity: contentType == DocumentType.dialogue
              ? content
              : null,
          exerciseSolution: contentType == DocumentType.exercise
              ? content
              : null,
          grammarExplanation: contentType == DocumentType.grammar
              ? content
              : null,
          isComplete: false,
          processedAt: DateTime.now(),
        );
      }

      await _saveProcessingResult(documentId, result);
      print('✅ Special content saved to Firestore cache');
    } catch (e) {
      print('Error saving special content: $e');
      rethrow;
    }
  }
}

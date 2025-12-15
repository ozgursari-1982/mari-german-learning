import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/study_document.dart';
import '../models/quiz_model.dart';
import '../models/document_analysis_model.dart';

/// Service for managing study documents in Firestore
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId =
      'test_user'; // TODO: Get from auth - CHANGED to test_user

  /// Save a new study document with AI analysis
  Future<String> saveStudyDocument({
    required String fileUrl,
    required String fileType,
    required StudyMaterialAnalysis analysis,
    EnhancedDocumentAnalysis? enhancedAnalysis,
    String? levelId,
    String? themeId,
    String? topic,
    String? contentType,
    String? userSelectedType, // User's manual selection - PRIORITY!
  }) async {
    try {
      // Use AI-determined category
      final primaryCategory = analysis.primaryCategory;

      // Generate document ID
      final docId = _firestore.collection('study_documents').doc().id;

      // Create document
      final document = StudyDocument(
        id: docId,
        userId: userId,
        title: _generateTitle(analysis.mainTopics),
        fileUrl: fileUrl,
        fileType: fileType,
        uploadedAt: DateTime.now(),
        documentType: contentType ?? 'topic',
        extractedText: analysis.extractedText,
        mainTopics: analysis.mainTopics,
        grammarStructures: analysis.grammarStructures,
        vocabularyLevel: analysis.vocabularyLevel,
        difficultyRating: analysis.difficultyRating,
        learningFocus: analysis.learningFocus,
        recommendations: analysis.recommendations,
        primaryCategory: primaryCategory,
        subCategory: analysis.subCategory,
        tags: [...analysis.mainTopics, ...analysis.grammarStructures],
        levelId: levelId,
        themeId: themeId,
        topic: topic,
        contentType: contentType,
        userSelectedType: userSelectedType, // Save user's choice!
        analysisData: enhancedAnalysis?.toJson() ?? {},
      );

      // Save to Firestore
      await _firestore
          .collection('study_documents')
          .doc(docId)
          .set(document.toMap());

      print('Document saved with ID: $docId');
      return docId;
    } catch (e) {
      print('Error saving document: $e');
      rethrow;
    }
  }

  /// Get all documents for the current user
  Future<List<StudyDocument>> getAllDocuments() async {
    try {
      final snapshot = await _firestore
          .collection('study_documents')
          .where('userId', isEqualTo: userId)
          .get();

      final docs = snapshot.docs
          .map((doc) => StudyDocument.fromMap(doc.data()))
          .toList();

      // Sort client-side to avoid Firestore index requirements
      docs.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

      return docs;
    } catch (e) {
      print('Error getting documents: $e');
      return [];
    }
  }

  /// Get documents by category
  Future<List<StudyDocument>> getDocumentsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('study_documents')
          .where('userId', isEqualTo: userId)
          .where('primaryCategory', isEqualTo: category)
          .orderBy('uploadedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => StudyDocument.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting documents by category: $e');
      return [];
    }
  }

  /// Get documents by hierarchical category
  Future<List<StudyDocument>> getDocumentsByHierarchy({
    required String levelId,
    required String themeId,
    required String topic,
    required String contentType,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('study_documents')
          .where('userId', isEqualTo: userId)
          .where('levelId', isEqualTo: levelId)
          .where('themeId', isEqualTo: themeId)
          .where('topic', isEqualTo: topic)
          .where('contentType', isEqualTo: contentType)
          .get();

      final docs = snapshot.docs
          .map((doc) => StudyDocument.fromMap(doc.data()))
          .toList();

      // Sort client-side to avoid Firestore index requirements
      docs.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

      return docs;
    } catch (e) {
      print('Error getting documents by hierarchy: $e');
      return [];
    }
  }

  /// Get category counts
  Future<Map<String, int>> getCategoryCounts() async {
    try {
      final snapshot = await _firestore
          .collection('study_documents')
          .where('userId', isEqualTo: userId)
          .get();

      final counts = <String, int>{};
      for (final doc in snapshot.docs) {
        final category = doc.data()['primaryCategory'] as String? ?? 'Genel';
        counts[category] = (counts[category] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      print('Error getting category counts: $e');
      return {};
    }
  }

  /// Delete a document
  Future<void> deleteDocument(String documentId) async {
    try {
      await _firestore.collection('study_documents').doc(documentId).delete();
      print('Document deleted: $documentId');
    } catch (e) {
      print('Error deleting document: $e');
      rethrow;
    }
  }

  /// Determine primary category from grammar structures
  String _determinePrimaryCategory(List<String> grammarStructures) {
    // Priority order for categorization
    final categoryKeywords = {
      'Perfekt': ['perfekt', 'partizip', 'haben', 'sein'],
      'Akkusativ': ['akkusativ', 'wen', 'was'],
      'Dativ': ['dativ', 'wem'],
      'Präsens': ['präsens', 'present'],
      'Konjunktiv': ['konjunktiv', 'würde'],
      'Wortschatz': ['wortschatz', 'vocabulary', 'vokabeln'],
    };

    for (final structure in grammarStructures) {
      final lowerStructure = structure.toLowerCase();
      for (final entry in categoryKeywords.entries) {
        if (entry.value.any((keyword) => lowerStructure.contains(keyword))) {
          return entry.key;
        }
      }
    }

    return 'Genel'; // Default category
  }

  /// Generate a title from main topics
  String _generateTitle(List<String> mainTopics) {
    if (mainTopics.isEmpty) {
      return 'Ders Notu - ${DateTime.now().day}/${DateTime.now().month}';
    }
    return mainTopics.first;
  }

  // Delete a study document
  Future<void> deleteStudyDocument(String docId, String fileUrl) async {
    try {
      // 1. Delete from Firestore
      await _firestore.collection('study_documents').doc(docId).delete();

      // 2. Delete file from Storage
      if (fileUrl.isNotEmpty) {
        try {
          final ref = FirebaseStorage.instance.refFromURL(fileUrl);
          await ref.delete();
        } catch (e) {
          print('Error deleting file from storage: $e');
          // Continue even if storage delete fails
        }
      }
    } catch (e) {
      print('Error deleting document: $e');
      rethrow;
    }
  }

  /// Save quiz result
  Future<void> saveQuizResult(QuizResult result) async {
    try {
      await _firestore
          .collection('quiz_results')
          .doc(result.id)
          .set(result.toMap()..addAll({'userId': userId}));
    } catch (e) {
      print('Error saving quiz result: $e');
      rethrow;
    }
  }

  /// Get all quiz results for the current user
  Future<List<QuizResult>> getQuizResults() async {
    try {
      final snapshot = await _firestore
          .collection('quiz_results')
          .where('userId', isEqualTo: userId)
          .get();

      final results = snapshot.docs
          .map((doc) => QuizResult.fromMap(doc.data()))
          .toList();

      // Sort by date descending
      results.sort((a, b) => b.date.compareTo(a.date));

      return results;
    } catch (e) {
      print('Error getting quiz results: $e');
      return [];
    }
  }

  /// Get documents by their IDs
  Future<List<StudyDocument>> getDocumentsByIds(
    List<String> documentIds,
  ) async {
    if (documentIds.isEmpty) return [];

    try {
      final documents = <StudyDocument>[];

      // Firestore 'in' query limit is 10, so batch the requests
      for (var i = 0; i < documentIds.length; i += 10) {
        final batch = documentIds.skip(i).take(10).toList();
        final snapshot = await _firestore
            .collection('study_documents')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        documents.addAll(
          snapshot.docs
              .map((doc) => StudyDocument.fromMap(doc.data()))
              .toList(),
        );
      }

      return documents;
    } catch (e) {
      print('Error getting documents by IDs: $e');
      return [];
    }
  }

  /// Get aggregated vocabulary by hierarchical category
  Future<List<EnhancedVocabularyItem>> getVocabularyByHierarchy({
    String? levelId,
    String? themeId,
    String? topic,
  }) async {
    try {
      Query query = _firestore
          .collection('study_documents')
          .where('userId', isEqualTo: userId);

      if (levelId != null) {
        query = query.where('levelId', isEqualTo: levelId);
      }
      if (themeId != null) {
        query = query.where('themeId', isEqualTo: themeId);
      }
      if (topic != null) {
        query = query.where('topic', isEqualTo: topic);
      }

      final snapshot = await query.get();
      final Map<String, EnhancedVocabularyItem> uniqueVocab = {};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['analysisData'] != null &&
            data['analysisData']['vocabulary'] != null) {
          final vocabList = List<dynamic>.from(
            data['analysisData']['vocabulary'],
          );

          for (final v in vocabList) {
            // Create a unique key based on the German word to avoid duplicates
            final germanWord = v['german'].toString().trim();
            if (germanWord.isNotEmpty && !uniqueVocab.containsKey(germanWord)) {
              uniqueVocab[germanWord] = EnhancedVocabularyItem.fromJson(v);
            }
          }
        }
      }

      return uniqueVocab.values.toList();
    } catch (e) {
      print('Error getting vocabulary by hierarchy: $e');
      return [];
    }
  }
}

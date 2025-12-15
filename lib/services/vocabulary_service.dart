import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vocabulary_word.dart';
import '../models/document_analysis_model.dart';
import 'spaced_repetition_service.dart';

/// Service for managing vocabulary words with spaced repetition
class VocabularyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SpacedRepetitionService _spacedRepetition = SpacedRepetitionService();
  final String userId;

  VocabularyService(this.userId);

  /// Save vocabulary words from document analysis
  Future<List<String>> saveVocabularyFromAnalysis({
    required EnhancedDocumentAnalysis analysis,
    required String documentId,
    String? categoryId,
    String? topic, // Konu başlığı (örn: Berufliche Einstiege)
  }) async {
    try {
      final savedIds = <String>[];
      final now = DateTime.now();

      for (final vocabItem in analysis.vocabulary) {
        // Check if word already exists
        final existing = await _findExistingWord(vocabItem.german);

        if (existing != null) {
          // Word exists, just link to document
          print('Word already exists: ${vocabItem.german}');
          savedIds.add(existing.id);
          continue;
        }

        // Create new word
        final wordId = _firestore
            .collection('users')
            .doc(userId)
            .collection('vocabulary')
            .doc()
            .id;

        final word = VocabularyWord(
          id: wordId,
          userId: userId,
          german: vocabItem.german,
          article: vocabItem.article,
          plural: vocabItem.plural,
          translation: vocabItem.translation,
          exampleSentence: vocabItem.exampleSentence,
          professionalContext: vocabItem.professionalContext,
          languageLevel: analysis.languageLevel
              .toString()
              .split('.')
              .last
              .toUpperCase(),
          category: analysis.isBerufsprache ? 'Berufsprache' : 'General',
          firstSeenAt: now,
          lastReviewedAt: now,
          nextReviewAt: now, // Available for immediate review
          sourceDocumentId: documentId,
          sourceCategory: categoryId,
          sourceTopic: topic, // Konu başlığı kaydediliyor
        );

        await _firestore
            .collection('users')
            .doc(userId)
            .collection('vocabulary')
            .doc(wordId)
            .set(word.toMap());

        savedIds.add(wordId);
        print('Saved new word: ${word.german}');
      }

      return savedIds;
    } catch (e) {
      print('Error saving vocabulary: $e');
      return [];
    }
  }

  /// Find existing word by German text
  Future<VocabularyWord?> _findExistingWord(String german) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('vocabulary')
          .where('german', isEqualTo: german)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return VocabularyWord.fromMap(snapshot.docs.first.data());
    } catch (e) {
      print('Error finding word: $e');
      return null;
    }
  }

  /// Get all vocabulary words
  Future<List<VocabularyWord>> getAllWords() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('vocabulary')
          .get();

      return snapshot.docs
          .map((doc) => VocabularyWord.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting words: $e');
      return [];
    }
  }

  /// Get words due for review today
  Future<List<VocabularyWord>> getDueWords() async {
    try {
      final allWords = await getAllWords();
      return _spacedRepetition.getDueWords(allWords);
    } catch (e) {
      print('Error getting due words: $e');
      return [];
    }
  }

  /// Get words by learning status
  Future<List<VocabularyWord>> getWordsByStatus(LearningStatus status) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('vocabulary')
          .where('status', isEqualTo: status.toString().split('.').last)
          .get();

      return snapshot.docs
          .map((doc) => VocabularyWord.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting words by status: $e');
      return [];
    }
  }

  /// Get words from a specific document
  Future<List<VocabularyWord>> getWordsFromDocument(String documentId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('vocabulary')
          .where('sourceDocumentId', isEqualTo: documentId)
          .get();

      return snapshot.docs
          .map((doc) => VocabularyWord.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting words from document: $e');
      return [];
    }
  }

  /// Update word after review
  Future<void> updateWordAfterReview({
    required String wordId,
    required bool wasCorrect,
  }) async {
    try {
      // Get current word
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('vocabulary')
          .doc(wordId)
          .get();

      if (!doc.exists) {
        print('Word not found: $wordId');
        return;
      }

      final word = VocabularyWord.fromMap(doc.data()!);

      // Calculate next review using spaced repetition
      final updatedWord = _spacedRepetition.calculateNextReview(
        word: word,
        wasCorrect: wasCorrect,
      );

      // Save updated word
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('vocabulary')
          .doc(wordId)
          .update(updatedWord.toMap());

      print(
        'Updated word: ${word.german}, correct: $wasCorrect, next review: ${updatedWord.nextReviewAt}',
      );
    } catch (e) {
      print('Error updating word: $e');
      rethrow;
    }
  }

  /// Get learning statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final allWords = await getAllWords();
      return _spacedRepetition.getStatistics(allWords);
    } catch (e) {
      print('Error getting statistics: $e');
      return {
        'total': 0,
        'new': 0,
        'learning': 0,
        'learned': 0,
        'mastered': 0,
        'dueToday': 0,
        'masteredPercentage': 0,
      };
    }
  }

  /// Get recommended daily study limit
  Future<int> getRecommendedDailyLimit() async {
    try {
      final allWords = await getAllWords();
      return _spacedRepetition.getRecommendedDailyLimit(allWords);
    } catch (e) {
      print('Error getting daily limit: $e');
      return 20;
    }
  }

  /// Delete a word
  Future<void> deleteWord(String wordId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('vocabulary')
          .doc(wordId)
          .delete();
    } catch (e) {
      print('Error deleting word: $e');
      rethrow;
    }
  }

  /// Update a word directly (for marking as learned/review)
  Future<void> updateWord(VocabularyWord word) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('vocabulary')
          .doc(word.id)
          .update(word.toMap());
      print('Updated word: ${word.german} -> ${word.status}');
    } catch (e) {
      print('Error updating word: $e');
      rethrow;
    }
  }

  /// Mark word as learned by German text
  Future<void> markAsLearnedByText(String german) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('vocabulary')
          .where('german', isEqualTo: german)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        // Create VocabularyWord from Firestore data
        final word = VocabularyWord.fromMap(doc.data());

        // Update status
        final updatedWord = word.copyWith(
          status: LearningStatus.learned,
          nextReviewAt: DateTime.now().add(const Duration(days: 3)),
          reviewCount: word.reviewCount + 1,
        );

        await updateWord(updatedWord);
        print('Marked as learned by text: $german');
      } else {
        print('Word not found for marking as learned: $german');
      }
    } catch (e) {
      print('Error marking as learned by text: $e');
      rethrow;
    }
  }
}

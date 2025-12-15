import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_error_history.dart';
import '../models/ai_feedback_model.dart';

/// Service for personalizing learning experience based on user's error history
class PersonalizationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  PersonalizationService(this.userId);

  /// Save errors from AI feedback to user's error history
  Future<void> saveErrorsFromFeedback({
    required AIFeedback feedback,
    String? context,
  }) async {
    try {
      if (feedback.errors.isEmpty) return;

      final history = await getErrorHistory();
      final now = DateTime.now();

      // Add new errors
      final updatedErrors = List<ErrorRecord>.from(history.errors);
      final updatedFrequency = Map<String, int>.from(history.errorFrequency);
      final updatedLastErrorDate = Map<String, DateTime>.from(
        history.lastErrorDate,
      );

      for (final error in feedback.errors) {
        final errorRecord = ErrorRecord(
          id: '${DateTime.now().millisecondsSinceEpoch}_${error.rule}',
          rule: error.rule,
          errorType: error.errorType,
          errorText: error.errorText,
          correction: error.correction,
          date: now,
          context: context ?? feedback.originalText,
        );

        updatedErrors.add(errorRecord);

        // Update frequency
        updatedFrequency[error.rule] = (updatedFrequency[error.rule] ?? 0) + 1;

        // Update last error date
        updatedLastErrorDate[error.rule] = now;
      }

      // Keep only last 100 errors to avoid data bloat
      List<ErrorRecord> finalErrors = updatedErrors;
      if (finalErrors.length > 100) {
        finalErrors.sort((a, b) => b.date.compareTo(a.date));
        finalErrors = finalErrors.take(100).toList();
      }

      // Update weak areas (top 5 most frequent errors)
      final sorted = updatedFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topErrors = sorted.take(5).map((e) => e.key).toList();

      // Create updated history
      final updatedHistory = history.copyWith(
        errors: finalErrors,
        errorFrequency: updatedFrequency,
        lastErrorDate: updatedLastErrorDate,
        weakAreas: topErrors,
        lastUpdated: now,
      );

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('personalization')
          .doc('error_history')
          .set(updatedHistory.toMap());

      print('✅ Saved ${feedback.errors.length} errors to history');
    } catch (e) {
      print('❌ Error saving error history: $e');
      // Don't throw - this is not critical
    }
  }

  /// Get user's error history
  Future<UserErrorHistory> getErrorHistory() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('personalization')
          .doc('error_history')
          .get();

      if (doc.exists) {
        return UserErrorHistory.fromMap(doc.data()!);
      } else {
        return UserErrorHistory.empty(userId);
      }
    } catch (e) {
      print('Error getting error history: $e');
      return UserErrorHistory.empty(userId);
    }
  }

  /// Get recurring errors (appeared 3+ times)
  List<String> getRecurringErrors(UserErrorHistory history) {
    return history.errorFrequency.entries
        .where((e) => e.value >= 3)
        .map((e) => e.key)
        .toList();
  }

  /// Get weak areas (top N most frequent errors)
  List<String> getWeakAreas(UserErrorHistory history, {int topN = 5}) {
    return history.getTopErrors(topN);
  }

  /// Get personalized study recommendations
  Future<List<String>> getStudyRecommendations() async {
    try {
      final history = await getErrorHistory();
      final recurring = getRecurringErrors(history);
      final weakAreas = getWeakAreas(history, topN: 3);

      final recommendations = <String>[];

      if (recurring.isNotEmpty) {
        recommendations.add(
          '⚠️ Tekrarlayan hatalar: ${recurring.join(", ")} - Bu konulara özellikle dikkat etmelisin!',
        );
      }

      if (weakAreas.isNotEmpty) {
        recommendations.add(
          '📚 Zayıf alanların: ${weakAreas.join(", ")} - Bu konularda daha fazla pratik yap.',
        );
      }

      // Get recent errors
      final recentErrors = history.getRecentErrors(days: 7);
      if (recentErrors.isNotEmpty) {
        final recentRules = recentErrors
            .map((e) => e.rule)
            .toSet()
            .toList()
            .take(3)
            .toList();
        if (recentRules.isNotEmpty) {
          recommendations.add(
            '🔄 Son 7 günde hata yaptığın konular: ${recentRules.join(", ")}',
          );
        }
      }

      return recommendations;
    } catch (e) {
      print('Error getting recommendations: $e');
      return [];
    }
  }

  /// Get error statistics
  Future<Map<String, dynamic>> getErrorStatistics() async {
    try {
      final history = await getErrorHistory();
      final recentErrors = history.getRecentErrors(days: 30);

      return {
        'totalErrors': history.errors.length,
        'recentErrors': recentErrors.length,
        'uniqueRules': history.errorFrequency.keys.length,
        'mostFrequent': history.getTopErrors(5),
        'recurringErrors': getRecurringErrors(history),
        'weakAreas': getWeakAreas(history),
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {};
    }
  }

  /// Clear error history (for testing or reset)
  Future<void> clearErrorHistory() async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('personalization')
          .doc('error_history')
          .delete();
      print('✅ Error history cleared');
    } catch (e) {
      print('Error clearing history: $e');
      rethrow;
    }
  }
}

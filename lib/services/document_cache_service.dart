import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/document_analysis_model.dart';

/// Service for caching document analysis results to avoid redundant AI calls
class DocumentCacheService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cache analysis result for a document
  Future<void> cacheAnalysis({
    required String documentId,
    required DocumentAnalysis analysis,
    Duration ttl = const Duration(days: 30),
  }) async {
    try {
      final expiresAt = DateTime.now().add(ttl);

      await _firestore.collection('document_cache').doc(documentId).set({
        'documentId': documentId,
        'analysis': analysis.toJson(),
        'cachedAt': Timestamp.now(),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'version': 1, // For future schema changes
      });

      print('✅ Analysis cached for document: $documentId');
    } catch (e) {
      print('❌ Error caching analysis: $e');
      // Don't throw - caching failure shouldn't break the flow
    }
  }

  /// Get cached analysis if available and not expired
  Future<DocumentAnalysis?> getCachedAnalysis(String documentId) async {
    try {
      final doc = await _firestore
          .collection('document_cache')
          .doc(documentId)
          .get();

      if (!doc.exists) {
        print('ℹ️ No cache found for document: $documentId');
        return null;
      }

      final data = doc.data()!;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();

      // Check if cache is expired
      if (DateTime.now().isAfter(expiresAt)) {
        print('⏰ Cache expired for document: $documentId');
        await _deleteCachedAnalysis(documentId);
        return null;
      }

      print('✅ Cache hit for document: $documentId');
      return DocumentAnalysis.fromJson(data['analysis']);
    } catch (e) {
      print('❌ Error getting cached analysis: $e');
      return null;
    }
  }

  /// Delete cached analysis
  Future<void> _deleteCachedAnalysis(String documentId) async {
    try {
      await _firestore.collection('document_cache').doc(documentId).delete();
    } catch (e) {
      print('Error deleting cache: $e');
    }
  }

  /// Clear all expired cache entries
  Future<void> clearExpiredCache() async {
    try {
      final now = Timestamp.now();
      final snapshot = await _firestore
          .collection('document_cache')
          .where('expiresAt', isLessThan: now)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ Cleared ${snapshot.docs.length} expired cache entries');
    } catch (e) {
      print('Error clearing expired cache: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final snapshot = await _firestore.collection('document_cache').get();

      final now = DateTime.now();
      int validCount = 0;
      int expiredCount = 0;

      for (final doc in snapshot.docs) {
        final expiresAt = (doc.data()['expiresAt'] as Timestamp).toDate();
        if (now.isBefore(expiresAt)) {
          validCount++;
        } else {
          expiredCount++;
        }
      }

      return {
        'total': snapshot.docs.length,
        'valid': validCount,
        'expired': expiredCount,
      };
    } catch (e) {
      print('Error getting cache stats: $e');
      return {'total': 0, 'valid': 0, 'expired': 0};
    }
  }
}

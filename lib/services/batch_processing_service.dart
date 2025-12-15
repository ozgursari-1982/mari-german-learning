import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/document_analysis_model.dart';
import 'gemini_ai_service.dart';
import 'document_cache_service.dart';

/// Job status for batch processing
enum JobStatus { pending, processing, completed, failed }

/// Batch processing job
class BatchJob {
  final String id;
  final String userId;
  final List<String> documentIds;
  final List<File> files;
  final List<String> mimeTypes;
  JobStatus status;
  int processedCount;
  int totalCount;
  DateTime createdAt;
  DateTime? completedAt;
  String? error;
  Map<String, DocumentAnalysis> results;

  BatchJob({
    required this.id,
    required this.userId,
    required this.documentIds,
    required this.files,
    required this.mimeTypes,
    this.status = JobStatus.pending,
    this.processedCount = 0,
    int? totalCount,
    DateTime? createdAt,
    this.completedAt,
    this.error,
    Map<String, DocumentAnalysis>? results,
  }) : totalCount = totalCount ?? files.length,
       createdAt = createdAt ?? DateTime.now(),
       results = results ?? {};

  double get progress => totalCount > 0 ? processedCount / totalCount : 0;
}

/// Service for batch processing multiple documents
class BatchProcessingService {
  final GeminiAIService _aiService = GeminiAIService();
  final DocumentCacheService _cacheService = DocumentCacheService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, BatchJob> _activeJobs = {};
  final StreamController<BatchJob> _jobUpdatesController =
      StreamController.broadcast();

  Stream<BatchJob> get jobUpdates => _jobUpdatesController.stream;

  /// Create and start a batch processing job
  Future<String> createBatchJob({
    required String userId,
    required List<String> documentIds,
    required List<File> files,
    required List<String> mimeTypes,
  }) async {
    final jobId = DateTime.now().millisecondsSinceEpoch.toString();

    final job = BatchJob(
      id: jobId,
      userId: userId,
      documentIds: documentIds,
      files: files,
      mimeTypes: mimeTypes,
    );

    _activeJobs[jobId] = job;

    // Save job to Firestore
    await _saveJobToFirestore(job);

    // Start processing in background
    _processBatchJob(job);

    return jobId;
  }

  /// Process batch job
  Future<void> _processBatchJob(BatchJob job) async {
    try {
      job.status = JobStatus.processing;
      _notifyJobUpdate(job);
      await _saveJobToFirestore(job);

      for (int i = 0; i < job.files.length; i++) {
        try {
          final documentId = job.documentIds[i];
          final file = job.files[i];
          final mimeType = job.mimeTypes[i];

          // Check cache first
          final cached = await _cacheService.getCachedAnalysis(documentId);

          DocumentAnalysis analysis;
          if (cached != null) {
            print('📦 Using cached analysis for: $documentId');
            analysis = cached;
          } else {
            print('🔄 Analyzing document: $documentId');
            analysis = await _aiService.analyzeDocumentEnhanced(file, mimeType);

            // Cache the result
            await _cacheService.cacheAnalysis(
              documentId: documentId,
              analysis: analysis,
            );
          }

          job.results[documentId] = analysis;
          job.processedCount++;

          _notifyJobUpdate(job);
          await _saveJobToFirestore(job);

          // Rate limiting - wait between requests
          if (i < job.files.length - 1) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        } catch (e) {
          print('❌ Error processing document ${job.documentIds[i]}: $e');
          // Continue with next document
        }
      }

      job.status = JobStatus.completed;
      job.completedAt = DateTime.now();
      _notifyJobUpdate(job);
      await _saveJobToFirestore(job);

      print('✅ Batch job completed: ${job.id}');
    } catch (e) {
      job.status = JobStatus.failed;
      job.error = e.toString();
      _notifyJobUpdate(job);
      await _saveJobToFirestore(job);

      print('❌ Batch job failed: ${job.id} - $e');
    }
  }

  /// Get job status
  BatchJob? getJob(String jobId) {
    return _activeJobs[jobId];
  }

  /// Get job from Firestore
  Future<BatchJob?> getJobFromFirestore(String jobId) async {
    try {
      final doc = await _firestore.collection('batch_jobs').doc(jobId).get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return BatchJob(
        id: data['id'],
        userId: data['userId'],
        documentIds: List<String>.from(data['documentIds']),
        files: [], // Files not stored in Firestore
        mimeTypes: List<String>.from(data['mimeTypes']),
        status: JobStatus.values[data['status']],
        processedCount: data['processedCount'],
        totalCount: data['totalCount'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        completedAt: data['completedAt'] != null
            ? (data['completedAt'] as Timestamp).toDate()
            : null,
        error: data['error'],
      );
    } catch (e) {
      print('Error getting job from Firestore: $e');
      return null;
    }
  }

  /// Save job to Firestore
  Future<void> _saveJobToFirestore(BatchJob job) async {
    try {
      await _firestore.collection('batch_jobs').doc(job.id).set({
        'id': job.id,
        'userId': job.userId,
        'documentIds': job.documentIds,
        'mimeTypes': job.mimeTypes,
        'status': job.status.index,
        'processedCount': job.processedCount,
        'totalCount': job.totalCount,
        'createdAt': Timestamp.fromDate(job.createdAt),
        'completedAt': job.completedAt != null
            ? Timestamp.fromDate(job.completedAt!)
            : null,
        'error': job.error,
      });
    } catch (e) {
      print('Error saving job to Firestore: $e');
    }
  }

  /// Notify job update
  void _notifyJobUpdate(BatchJob job) {
    if (!_jobUpdatesController.isClosed) {
      _jobUpdatesController.add(job);
    }
  }

  /// Cancel job
  Future<void> cancelJob(String jobId) async {
    final job = _activeJobs[jobId];
    if (job != null) {
      job.status = JobStatus.failed;
      job.error = 'Cancelled by user';
      _notifyJobUpdate(job);
      await _saveJobToFirestore(job);
      _activeJobs.remove(jobId);
    }
  }

  /// Dispose
  void dispose() {
    _jobUpdatesController.close();
  }
}

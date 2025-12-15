import 'dart:io';
import 'dart:async';
import '../models/document_analysis_model.dart';
import 'gemini_ai_service.dart';

/// Chunk of document for incremental processing
class DocumentChunk {
  final int index;
  final String content;
  final int startPage;
  final int endPage;
  bool isProcessed;
  DocumentAnalysis? analysis;

  DocumentChunk({
    required this.index,
    required this.content,
    required this.startPage,
    required this.endPage,
    this.isProcessed = false,
    this.analysis,
  });
}

/// Service for incremental document analysis
class IncrementalAnalysisService {
  final GeminiAIService _aiService = GeminiAIService();
  final StreamController<Map<String, dynamic>> _progressController =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get progressStream => _progressController.stream;

  /// Analyze document incrementally (chunk by chunk)
  Future<DocumentAnalysis> analyzeIncrementally({
    required File file,
    required String mimeType,
    int chunkSize = 5, // Pages per chunk
    Function(double progress, DocumentChunk chunk)? onChunkComplete,
  }) async {
    try {
      // For now, we'll simulate chunking
      // In production, you'd split PDF pages or image sections

      final chunks = await _createChunks(file, mimeType, chunkSize);
      final results = <DocumentAnalysis>[];

      for (int i = 0; i < chunks.length; i++) {
        final chunk = chunks[i];

        _notifyProgress({
          'phase': 'analyzing',
          'currentChunk': i + 1,
          'totalChunks': chunks.length,
          'progress': (i / chunks.length) * 100,
          'message': 'Analyzing pages ${chunk.startPage}-${chunk.endPage}...',
        });

        // Analyze chunk
        final analysis = await _analyzeChunk(chunk, file, mimeType);
        chunk.analysis = analysis;
        chunk.isProcessed = true;
        results.add(analysis);

        // Notify chunk completion
        if (onChunkComplete != null) {
          onChunkComplete((i + 1) / chunks.length, chunk);
        }

        _notifyProgress({
          'phase': 'chunk_complete',
          'currentChunk': i + 1,
          'totalChunks': chunks.length,
          'progress': ((i + 1) / chunks.length) * 100,
          'message': 'Completed pages ${chunk.startPage}-${chunk.endPage}',
        });

        // Small delay between chunks to avoid rate limiting
        if (i < chunks.length - 1) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }

      _notifyProgress({
        'phase': 'merging',
        'progress': 95,
        'message': 'Merging results...',
      });

      // Merge all chunk results
      final mergedAnalysis = _mergeAnalyses(results);

      _notifyProgress({
        'phase': 'complete',
        'progress': 100,
        'message': 'Analysis complete!',
      });

      return mergedAnalysis;
    } catch (e) {
      _notifyProgress({
        'phase': 'error',
        'progress': 0,
        'message': 'Error: $e',
      });
      rethrow;
    }
  }

  /// Create chunks from document
  Future<List<DocumentChunk>> _createChunks(
    File file,
    String mimeType,
    int chunkSize,
  ) async {
    // For now, create a single chunk
    // In production, you'd split based on pages/size
    return [
      DocumentChunk(
        index: 0,
        content: 'Full document',
        startPage: 1,
        endPage: 1,
      ),
    ];
  }

  /// Analyze a single chunk
  Future<DocumentAnalysis> _analyzeChunk(
    DocumentChunk chunk,
    File file,
    String mimeType,
  ) async {
    // Use existing AI service
    return await _aiService.analyzeDocumentEnhanced(file, mimeType);
  }

  /// Merge multiple analyses into one
  DocumentAnalysis _mergeAnalyses(List<DocumentAnalysis> analyses) {
    if (analyses.isEmpty) {
      throw Exception('No analyses to merge');
    }

    if (analyses.length == 1) {
      return analyses.first;
    }

    // Merge vocabulary
    final allVocabulary = <VocabularyWord>[];
    final seenWords = <String>{};

    for (final analysis in analyses) {
      for (final word in analysis.vocabulary) {
        final key = '${word.german}_${word.article}';
        if (!seenWords.contains(key)) {
          allVocabulary.add(word);
          seenWords.add(key);
        }
      }
    }

    // Merge grammar rules
    final allGrammarRules = <GrammarRule>[];
    final seenRules = <String>{};

    for (final analysis in analyses) {
      for (final rule in analysis.grammarRules) {
        if (!seenRules.contains(rule.rule)) {
          allGrammarRules.add(rule);
          seenRules.add(rule.rule);
        }
      }
    }

    // Combine extracted text
    final combinedText = analyses
        .map((a) => a.extractedText)
        .where((t) => t.isNotEmpty)
        .join('\n\n');

    // Merge key topics
    final allTopics = <String>{};
    for (final analysis in analyses) {
      allTopics.addAll(analysis.keyTopics);
    }

    // Use first analysis as base
    final base = analyses.first;

    return DocumentAnalysis(
      documentType: base.documentType,
      languageLevel: base.languageLevel,
      mainTopic: base.mainTopic,
      mainTheme: base.mainTheme,
      categories: base.categories,
      vocabulary: allVocabulary,
      grammarRules: allGrammarRules,
      extractedText: combinedText,
      keyTopics: allTopics.toList(),
      professionalContext: base.professionalContext,
      isBerufsprache: base.isBerufsprache,
      confidence: analyses
          .map((a) => a.confidence)
          .reduce((a, b) => (a + b) / 2),
      categorySuggestion: base.categorySuggestion,
    );
  }

  /// Notify progress
  void _notifyProgress(Map<String, dynamic> progress) {
    if (!_progressController.isClosed) {
      _progressController.add(progress);
    }
  }

  /// Dispose
  void dispose() {
    _progressController.close();
  }
}

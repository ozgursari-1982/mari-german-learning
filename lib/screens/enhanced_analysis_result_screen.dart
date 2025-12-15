import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/document_analysis_model.dart';
import '../services/gemini_ai_service.dart';
import '../services/document_processing_service.dart';
import 'take_test_screen.dart';

/// Enhanced screen to display detailed AI analysis results
class EnhancedAnalysisResultScreen extends StatefulWidget {
  final EnhancedDocumentAnalysis analysis;
  final String? imageUrl;
  final String? documentId;
  final String?
  userSelectedType; // User's manual document type selection - PRIORITY!
  final String? userSelectedCategoryId; // User's selected category/theme ID

  const EnhancedAnalysisResultScreen({
    super.key,
    required this.analysis,
    this.imageUrl,
    this.documentId,
    this.userSelectedType, // Take user's choice!
    this.userSelectedCategoryId, // User's selected category/theme ID
  });

  @override
  State<EnhancedAnalysisResultScreen> createState() =>
      _EnhancedAnalysisResultScreenState();
}

class _EnhancedAnalysisResultScreenState
    extends State<EnhancedAnalysisResultScreen> {
  bool _showVocabulary = true;
  bool _showGrammar = true;
  bool _showContext = true;
  bool _isGeneratingQuiz = false;
  bool _isGeneratingSpecialContent = false;
  Map<String, dynamic>? _specialContent;
  final GeminiAIService _aiService = GeminiAIService();
  final DocumentProcessingService _processingService =
      DocumentProcessingService('default_user');

  @override
  void initState() {
    super.initState();
    // Load cached content if available
    _loadCachedContent();
    // Auto-save vocabulary if this is a vocabulary document
    _autoSaveVocabulary();
  }

  /// Automatically save vocabulary words to flashcard collection
  Future<void> _autoSaveVocabulary() async {
    final effectiveType = _getEffectiveDocumentType(); // USE USER'S CHOICE!

    print('🔍 _autoSaveVocabulary called');
    print('   documentId: ${widget.documentId}');
    print('   AI detected type: ${widget.analysis.documentType}');
    print('   User selected type: ${widget.userSelectedType}');
    print('   Effective type: $effectiveType');
    print('   vocabulary count: ${widget.analysis.vocabulary.length}');

    if (widget.documentId == null || effectiveType != DocumentType.vocabulary) {
      print(
        '⏭️ Skipping - not a vocabulary document (effective type: $effectiveType)',
      );
      return;
    }

    // Check if already processed
    try {
      print('📥 Checking for existing saved vocabulary...');
      final cachedResult = await _processingService.getProcessingResult(
        widget.documentId!,
      );

      // If already processed and has saved vocabulary, skip
      if (cachedResult != null && cachedResult.savedVocabularyIds.isNotEmpty) {
        print(
          '✅ Vocabulary already saved (${cachedResult.savedVocabularyIds.length} words)',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Bu belge zaten kaydedilmiş (${cachedResult.savedVocabularyIds.length} kelime)',
              ),
              backgroundColor: AppColors.info,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Save vocabulary
      print(
        '💾 Auto-saving ${widget.analysis.vocabulary.length} words to flashcards...',
      );

      if (widget.analysis.vocabulary.isEmpty) {
        print('⚠️ WARNING: analysis.vocabulary is EMPTY!');
        print('   AI did not extract any vocabulary from this document.');
        print('   Document type: ${widget.analysis.documentType}');
        print('   Main topic: ${widget.analysis.mainTopic}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '⚠️ Bu belgede kelime bulunamadı! AI analizi kelime ayıklayamadı.',
              ),
              backgroundColor: AppColors.warning,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }
      final result = await _processingService.processDocument(
        analysis: widget.analysis,
        userSelectedType: DocumentType.vocabulary,
        documentId: widget.documentId!,
        extractedText: widget.analysis.extractedText,
        categoryId: widget.userSelectedCategoryId,
      );
      print(
        '✅ ProcessDocument returned: ${result.savedVocabularyIds.length} words saved',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${result.savedVocabularyIds.length} kelime flashcard koleksiyonuna eklendi!',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Failed to auto-save vocabulary: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Kelimeler kaydedilemedi: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Get the effective document type - USER'S SELECTION TAKES PRIORITY!
  DocumentType _getEffectiveDocumentType() {
    if (widget.userSelectedType != null) {
      // Convert string to DocumentType
      switch (widget.userSelectedType!.toLowerCase()) {
        case 'vocabulary':
          return DocumentType.vocabulary;
        case 'grammar':
          return DocumentType.grammar;
        case 'dialogue':
          return DocumentType.dialogue;
        case 'practice':
        case 'exercise':
          return DocumentType.exercise;
        case 'theory':
          return DocumentType.mixed; // Theory → use mixed
        case 'pdfgeneral':
          return DocumentType.mixed; // PDF General → use mixed
        default:
          return widget.analysis.documentType; // Fallback to AI
      }
    }
    // No user selection, use AI's detection
    return widget.analysis.documentType;
  }

  /// Load previously generated content from Firestore cache
  Future<void> _loadCachedContent() async {
    final effectiveType = _getEffectiveDocumentType(); // USE USER'S CHOICE!

    // Only load cache for dialogue, exercise, and grammar types
    if (widget.documentId == null ||
        (effectiveType != DocumentType.dialogue &&
            effectiveType != DocumentType.exercise &&
            effectiveType != DocumentType.grammar)) {
      return;
    }

    try {
      final cachedResult = await _processingService.getProcessingResult(
        widget.documentId!,
      );

      if (cachedResult != null && mounted) {
        Map<String, dynamic>? content;

        if (effectiveType == DocumentType.dialogue) {
          content = cachedResult.dialogueActivity;
        } else if (effectiveType == DocumentType.exercise) {
          content = cachedResult.exerciseSolution;
        } else if (effectiveType == DocumentType.grammar) {
          content = cachedResult.grammarExplanation;
        }

        if (content != null) {
          setState(() => _specialContent = content);
          print('✅ Loaded cached content from Firestore - API call saved!');
        }
      }
    } catch (e) {
      print('Cache load failed (will generate fresh): $e');
    }
  }

  /// Save generated content to Firestore for future use
  Future<void> _saveContentToCache(Map<String, dynamic> content) async {
    if (widget.documentId == null) return;

    try {
      await _processingService.saveSpecialContent(
        documentId: widget.documentId!,
        contentType: widget.analysis.documentType,
        content: content,
      );
    } catch (e) {
      print('Failed to save cache: $e');
    }
  }

  Future<void> _generateQuiz() async {
    setState(() => _isGeneratingQuiz = true);
    try {
      final quiz = await _aiService.generateQuizFromContext(
        sourceTexts: [widget.analysis.extractedText],
        level: widget.analysis.languageLevel.toString().split('.').last,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TakeTestScreen(quiz: quiz)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test oluşturulurken hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingQuiz = false);
      }
    }
  }

  Future<void> _generateSpecialContent() async {
    setState(() => _isGeneratingSpecialContent = true);
    try {
      Map<String, dynamic> content;
      final effectiveType = _getEffectiveDocumentType(); // USE USER'S CHOICE!

      if (effectiveType == DocumentType.dialogue) {
        // Convert image descriptions to Map format
        List<Map<String, dynamic>>? imageDescs;
        if (widget.analysis.imageDescriptions.isNotEmpty) {
          imageDescs = widget.analysis.imageDescriptions
              .map((img) => img.toJson())
              .toList();
        }

        content = await _aiService.generateDialogueActivity(
          extractedText: widget.analysis.extractedText,
          mainTopic: widget.analysis.mainTopic,
          languageLevel: widget.analysis.languageLevel
              .toString()
              .split('.')
              .last,
          imageDescriptions: imageDescs,
        );
      } else if (effectiveType == DocumentType.exercise) {
        content = await _aiService.generateExerciseSolution(
          extractedText: widget.analysis.extractedText,
          mainTopic: widget.analysis.mainTopic,
          languageLevel: widget.analysis.languageLevel
              .toString()
              .split('.')
              .last,
        );
      } else if (effectiveType == DocumentType.grammar) {
        // Convert image descriptions to Map format for visual schemas/tables
        List<Map<String, dynamic>>? imageDescs;
        if (widget.analysis.imageDescriptions.isNotEmpty) {
          imageDescs = widget.analysis.imageDescriptions
              .map((img) => img.toJson())
              .toList();
        }

        content = await _aiService.generateEnhancedGrammarExplanation(
          extractedText: widget.analysis.extractedText,
          mainTopic: widget.analysis.mainTopic,
          languageLevel: widget.analysis.languageLevel
              .toString()
              .split('.')
              .last,
          imageDescriptions: imageDescs,
        );
      } else {
        throw Exception('Bu belge tipi için özel içerik oluşturulamaz');
      }

      if (mounted) {
        setState(() => _specialContent = content);
        // Save to cache for future use - API tasarrufu!
        await _saveContentToCache(content);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İçerik oluşturulurken hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingSpecialContent = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get effective document type at the start - USER'S CHOICE PRIORITY!
    final effectiveType = _getEffectiveDocumentType();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Detaylı Analiz'),
        backgroundColor: AppColors.backgroundCard,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAnalysisInfo(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document Overview
            _buildOverviewCard(),
            const SizedBox(height: 16),

            // Content Structure
            _buildContentStructureCard(),
            const SizedBox(height: 16),

            // Main Theme
            _buildThemeCard(),
            const SizedBox(height: 16),

            // Image Descriptions
            if (widget.analysis.imageDescriptions.isNotEmpty)
              _buildImageDescriptionsCard(),
            if (widget.analysis.imageDescriptions.isNotEmpty)
              const SizedBox(height: 16),

            // Vocabulary Section
            _buildExpandableSection(
              title: 'Kelime Dağarcığı',
              icon: Icons.book,
              color: AppColors.accentBright,
              isExpanded: _showVocabulary,
              onToggle: () =>
                  setState(() => _showVocabulary = !_showVocabulary),
              child: _buildVocabularyList(),
            ),
            const SizedBox(height: 16),

            // Grammar Section
            _buildExpandableSection(
              title: 'Dilbilgisi Kuralları',
              icon: Icons.rule,
              color: AppColors.warning,
              isExpanded: _showGrammar,
              onToggle: () => setState(() => _showGrammar = !_showGrammar),
              child: _buildGrammarList(),
            ),
            const SizedBox(height: 16),

            // Professional Context
            if (widget.analysis.professionalContext.isNotEmpty)
              _buildExpandableSection(
                title: 'Profesyonel Bağlam',
                icon: Icons.work,
                color: AppColors.info,
                isExpanded: _showContext,
                onToggle: () => setState(() => _showContext = !_showContext),
                child: _buildContextCard(),
              ),

            const SizedBox(height: 24),

            // Special Content for Dialogue, Exercise, and Grammar types
            // USE USER'S SELECTION!
            if (effectiveType == DocumentType.dialogue ||
                effectiveType == DocumentType.exercise ||
                effectiveType == DocumentType.grammar) ...[
              if (_specialContent == null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isGeneratingSpecialContent
                        ? null
                        : _generateSpecialContent,
                    icon: _isGeneratingSpecialContent
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.backgroundDark,
                            ),
                          )
                        : Icon(
                            effectiveType == DocumentType.dialogue
                                ? Icons.chat
                                : effectiveType == DocumentType.grammar
                                ? Icons.psychology
                                : Icons.lightbulb,
                          ),
                    label: Text(
                      _isGeneratingSpecialContent
                          ? 'İçerik Hazırlanıyor...'
                          : effectiveType == DocumentType.dialogue
                          ? 'Diyalog Aktivitesi Oluştur'
                          : effectiveType == DocumentType.grammar
                          ? 'Gramer Anlatımı Oluştur'
                          : 'Alıştırma Çözümü Oluştur',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: effectiveType == DocumentType.grammar
                          ? AppColors.warning
                          : AppColors.info,
                      foregroundColor: AppColors.backgroundDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )
              else
                _buildSpecialContentCard(),
              const SizedBox(height: 16),
            ],

            // Standard Analysis Display
            _buildStandardAnalysisCard(),
            const SizedBox(height: 16),

            // Create Quiz Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGeneratingQuiz ? null : _generateQuiz,
                icon: _isGeneratingQuiz
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.backgroundDark,
                        ),
                      )
                    : const Icon(Icons.quiz),
                label: Text(
                  _isGeneratingQuiz
                      ? 'Test Hazırlanıyor...'
                      : 'Bu Dökümandan Test Oluştur',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBright,
                  foregroundColor: AppColors.backgroundDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Card(
      color: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentBright.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getDocumentTypeIcon(),
                    color: AppColors.accentBright,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDocumentTypeName(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.analysis.languageLevel
                                  .toString()
                                  .split('.')
                                  .last,
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (widget.analysis.categories.isNotEmpty)
                            Expanded(
                              child: Text(
                                widget.analysis.categories.first,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard() {
    return Card(
      color: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.topic,
                  color: AppColors.accentBright,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Ana Tema',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.analysis.mainTheme,
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            if (widget.analysis.mainTopic.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                widget.analysis.mainTopic,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required Color color,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Card(
      color: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: child,
            ),
        ],
      ),
    );
  }

  Widget _buildVocabularyList() {
    if (widget.analysis.vocabulary.isEmpty) {
      return const Text(
        'Kelime bulunamadı',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    return Column(
      children: widget.analysis.vocabulary.map((vocab) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.accentBright.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (vocab.article.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentBright.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        vocab.article,
                        style: const TextStyle(
                          color: AppColors.accentBright,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vocab.german,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                vocab.translation,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              if (vocab.plural.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Çoğul: ${vocab.plural}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary.withOpacity(0.8),
                  ),
                ),
              ],
              if (vocab.exampleSentence.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    vocab.exampleSentence,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              if (vocab.professionalContext.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: vocab.professionalContext.split(',').map((context) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        context.trim(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.warning,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGrammarList() {
    if (widget.analysis.grammarRules.isEmpty) {
      return const Text(
        'Dilbilgisi kuralı bulunamadı',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    return Column(
      children: widget.analysis.grammarRules.map((rule) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.warning.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rule.rule,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (rule.explanation.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  rule.explanation,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
              if (rule.examples.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...rule.examples.map((example) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 16,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            example,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContextCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        widget.analysis.professionalContext,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.textPrimary,
          height: 1.6,
        ),
      ),
    );
  }

  IconData _getDocumentTypeIcon() {
    switch (widget.analysis.documentType) {
      case DocumentType.dialogue:
        return Icons.chat_bubble_outline;
      case DocumentType.professionalText:
        return Icons.article;
      case DocumentType.exercise:
        return Icons.fitness_center;
      case DocumentType.vocabulary:
        return Icons.book;
      case DocumentType.grammar:
        return Icons.rule;
      default:
        return Icons.description;
    }
  }

  String _getDocumentTypeName() {
    switch (widget.analysis.documentType) {
      case DocumentType.dialogue:
        return 'Diyalog';
      case DocumentType.professionalText:
        return 'Mesleki Metin';
      case DocumentType.exercise:
        return 'Alıştırma';
      case DocumentType.vocabulary:
        return 'Kelime Listesi';
      case DocumentType.grammar:
        return 'Dilbilgisi';
      default:
        return 'Belge';
    }
  }

  void _showAnalysisInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Analiz Bilgisi',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Belge Tipi', _getDocumentTypeName()),
            _buildInfoRow(
              'Dil Seviyesi',
              widget.analysis.languageLevel.toString().split('.').last,
            ),
            _buildInfoRow(
              'Kelime Sayısı',
              '${widget.analysis.vocabulary.length}',
            ),
            _buildInfoRow(
              'Dilbilgisi Kuralı',
              '${widget.analysis.grammarRules.length}',
            ),
            _buildInfoRow('Kategoriler', widget.analysis.categories.join(', ')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentStructureCard() {
    if (widget.analysis.contentStructure.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'İçerik Yapısı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...widget.analysis.contentStructure.map((section) {
              IconData icon;
              switch (section.type.toLowerCase()) {
                case 'grammar':
                  icon = Icons.spellcheck;
                  break;
                case 'exercise':
                  icon = Icons.edit_note;
                  break;
                case 'vocabulary':
                  icon = Icons.list_alt;
                  break;
                default:
                  icon = Icons.article;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: AppColors.accentBright, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            section.description,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardAnalysisCard() {
    return Card(
      color: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: AppColors.accentBright, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Standart Analiz',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Bu döküman ${_getDocumentTypeName()} olarak sınıflandırıldı. '
              'Yukarıdaki bölümlerde kelime dağarcığı, dilbilgisi kuralları ve diğer detayları inceleyebilirsiniz.',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialContentCard() {
    if (_specialContent == null) return const SizedBox.shrink();

    final isDialogue = widget.analysis.documentType == DocumentType.dialogue;
    final isGrammar = widget.analysis.documentType == DocumentType.grammar;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.backgroundCard,
            AppColors.backgroundCard.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGrammar
              ? AppColors.warning.withOpacity(0.3)
              : AppColors.info.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isDialogue
                          ? Icons.chat
                          : isGrammar
                          ? Icons.psychology
                          : Icons.lightbulb,
                      color: isGrammar ? AppColors.warning : AppColors.info,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isDialogue
                          ? 'Diyalog Aktivitesi'
                          : isGrammar
                          ? 'Gramer Anlatımı'
                          : 'Alıştırma Çözümü',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => setState(() => _specialContent = null),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (isDialogue)
              _buildDialogueContent()
            else if (isGrammar)
              _buildGrammarContent()
            else
              _buildExerciseContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogueContent() {
    final content = _specialContent!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Activity Description
        if (content['activityDescription'] != null) ...[
          _buildSectionTitle('Aktivite Açıklaması', Icons.info_outline),
          const SizedBox(height: 8),
          Text(
            content['activityDescription'],
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Learning Objectives
        if (content['learningObjectives'] != null &&
            (content['learningObjectives'] as List).isNotEmpty) ...[
          _buildSectionTitle('Öğrenme Hedefleri', Icons.flag),
          const SizedBox(height: 8),
          ...(content['learningObjectives'] as List).map(
            (obj) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(color: AppColors.info, fontSize: 16),
                  ),
                  Expanded(
                    child: Text(
                      obj.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Key Vocabulary section removed - not needed

        // Example Dialogues
        if (content['exampleDialogues'] != null &&
            (content['exampleDialogues'] as List).isNotEmpty) ...[
          _buildSectionTitle('Örnek Diyaloglar', Icons.chat_bubble_outline),
          const SizedBox(height: 12),
          ...(content['exampleDialogues'] as List).map(
            (dialogue) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dialogue['title'] != null) ...[
                    Text(
                      dialogue['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentBright,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (dialogue['dialogue'] != null)
                    ...(dialogue['dialogue'] as List).map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${line['speaker']}: ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.info,
                                  fontSize: 14,
                                ),
                              ),
                              TextSpan(
                                text: line['text'],
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (dialogue['translation'] != null) ...[
                    const Divider(height: 24),
                    Text(
                      'Türkçe Çeviri:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dialogue['translation'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (dialogue['notes'] != null &&
                      dialogue['notes'].toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info, size: 16, color: AppColors.info),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dialogue['notes'],
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.info,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Grammar Points
        if (content['grammarPoints'] != null &&
            (content['grammarPoints'] as List).isNotEmpty) ...[
          _buildSectionTitle('Dilbilgisi Noktaları', Icons.rule),
          const SizedBox(height: 12),
          ...(content['grammarPoints'] as List).map(
            (point) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    point['point'] ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                    ),
                  ),
                  if (point['explanation'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      point['explanation'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (point['examples'] != null &&
                      (point['examples'] as List).isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ...(point['examples'] as List).map(
                      (ex) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $ex',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Practice Prompts
        if (content['practicePrompts'] != null &&
            (content['practicePrompts'] as List).isNotEmpty) ...[
          _buildSectionTitle('Pratik Önerileri', Icons.fitness_center),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: (content['practicePrompts'] as List)
                  .map(
                    (prompt) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 20,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              prompt.toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Cultural Notes
        if (content['culturalNotes'] != null &&
            content['culturalNotes'].toString().isNotEmpty) ...[
          _buildSectionTitle('Kültürel Notlar', Icons.public),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.info.withOpacity(0.1),
                  AppColors.accentBright.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              content['culturalNotes'],
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Completed Examples
        if (content['completedExamples'] != null &&
            content['completedExamples'].toString().isNotEmpty) ...[
          _buildSectionTitle('Tamamlanmış Örnekler', Icons.done_all),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              content['completedExamples'],
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExerciseContent() {
    final content = _specialContent!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Exercise Description
        if (content['exerciseDescription'] != null) ...[
          _buildSectionTitle('Alıştırma Açıklaması', Icons.info_outline),
          const SizedBox(height: 8),
          Text(
            content['exerciseDescription'],
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Solutions
        if (content['solutions'] != null &&
            (content['solutions'] as List).isNotEmpty) ...[
          _buildSectionTitle('Çözümler', Icons.check_circle_outline),
          const SizedBox(height: 12),
          ...(content['solutions'] as List).asMap().entries.map((entry) {
            final solution = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Soru ${solution['questionNumber'] ?? entry.key + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (solution['question'] != null) ...[
                    Text(
                      solution['question'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check,
                          color: AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Doğru Cevap: ${solution['correctAnswer'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (solution['explanation'] != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: AppColors.info,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Neden bu cevap doğru?',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.info,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            solution['explanation'],
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (solution['grammarRule'] != null &&
                      solution['grammarRule'].toString().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '📚 Kural: ${solution['grammarRule']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  if (solution['additionalNotes'] != null &&
                      solution['additionalNotes'].toString().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accentBright.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.tips_and_updates,
                            size: 16,
                            color: AppColors.accentBright,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              solution['additionalNotes'],
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
        ],

        // Overall Explanation
        if (content['overallExplanation'] != null &&
            content['overallExplanation'].toString().isNotEmpty) ...[
          _buildSectionTitle('Genel Değerlendirme', Icons.assessment),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.info.withOpacity(0.1),
                  AppColors.accentBright.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              content['overallExplanation'],
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Completed Version
        if (content['completedVersion'] != null &&
            content['completedVersion'].toString().isNotEmpty) ...[
          _buildSectionTitle('Tamamlanmış Versiyon', Icons.done_all),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Text(
              content['completedVersion'],
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accentBright, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildImageDescriptionsCard() {
    return Card(
      color: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.image, color: AppColors.info, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Resimlerdeki İçerik',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...widget.analysis.imageDescriptions.map(
              (img) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Resim ${img.imageNumber}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Display bilingual description
                    _buildBilingualText(img.description),
                    if (img.profession.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.accentBright.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.work,
                              size: 18,
                              color: AppColors.accentBright,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Meslek: ${img.profession}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.accentBright,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (img.activity.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.play_arrow,
                            size: 18,
                            color: AppColors.accentBright,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Aktivite:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _buildBilingualText(
                                  img.activity,
                                  isActivity: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Vocabulary removed - not needed
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper to display bilingual text with language tags
  Widget _buildBilingualText(String text, {bool isActivity = false}) {
    final parts = text.split(' / ');
    final german = parts.isNotEmpty ? parts[0].trim() : text;
    final turkish = parts.length > 1 ? parts[1].trim() : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // German text
        if (german.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'DE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.info,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  german,
                  style: TextStyle(
                    fontSize: isActivity ? 13 : 15,
                    color: AppColors.textPrimary,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        // Turkish text
        if (turkish.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'TR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  turkish,
                  style: TextStyle(
                    fontSize: isActivity ? 13 : 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Build enhanced grammar content with fast, memorable learning approach
  Widget _buildGrammarContent() {
    if (_specialContent == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Summary
        if (_specialContent!['quickSummary'] != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates, color: AppColors.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _specialContent!['quickSummary'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),

        // Visual Schema / Table
        if (_specialContent!['visualSchema'] != null &&
            _specialContent!['visualSchema'].toString().isNotEmpty)
          _buildVisualSchema(),

        // Comparison Table
        if (_specialContent!['comparisonTable'] != null)
          _buildComparisonTable(),

        // Core Rules
        if (_specialContent!['coreRules'] != null &&
            (_specialContent!['coreRules'] as List).isNotEmpty)
          _buildCoreRules(),

        // Example Patterns
        if (_specialContent!['examplePatterns'] != null &&
            (_specialContent!['examplePatterns'] as List).isNotEmpty)
          _buildExamplePatterns(),

        // Common Mistakes
        if (_specialContent!['commonMistakes'] != null &&
            (_specialContent!['commonMistakes'] as List).isNotEmpty)
          _buildCommonMistakes(),

        // Quick Tips
        if (_specialContent!['quickTips'] != null &&
            (_specialContent!['quickTips'] as List).isNotEmpty)
          _buildQuickTips(),

        // Memory Tricks
        if (_specialContent!['memoryTricks'] != null &&
            (_specialContent!['memoryTricks'] as List).isNotEmpty)
          _buildMemoryTricks(),

        // Practice Prompts
        if (_specialContent!['practicePrompts'] != null &&
            (_specialContent!['practicePrompts'] as List).isNotEmpty)
          _buildPracticePrompts(),
      ],
    );
  }

  Widget _buildVisualSchema() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schema, color: AppColors.info, size: 20),
              SizedBox(width: 8),
              Text(
                'Görsel Şema',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              _specialContent!['visualSchema'],
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    final table = _specialContent!['comparisonTable'] as Map<String, dynamic>;
    if (table['headers'] == null || (table['headers'] as List).isEmpty) {
      return const SizedBox.shrink();
    }

    final headers = table['headers'] as List;
    final rows = table['rows'] as List? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (table['title'] != null && table['title'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.table_chart,
                    color: AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    table['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Table(
                border: TableBorder.symmetric(
                  inside: BorderSide(color: AppColors.info.withOpacity(0.2)),
                ),
                children: [
                  // Header row
                  TableRow(
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.2),
                    ),
                    children: headers.map((header) {
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          header.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  // Data rows
                  ...rows.map((row) {
                    final rowData = row as List;
                    return TableRow(
                      children: rowData.map((cell) {
                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            cell.toString(),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoreRules() {
    final rules = _specialContent!['coreRules'] as List;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.rule_folder, color: AppColors.warning, size: 20),
              SizedBox(width: 8),
              Text(
                'Temel Kurallar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rules.asMap().entries.map((entry) {
            final index = entry.key;
            final rule = entry.value as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: AppColors.backgroundDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rule['rule'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (rule['explanation'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  rule['explanation'],
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            if (rule['pattern'] != null)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundDark.withOpacity(
                                    0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  rule['pattern'],
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    color: AppColors.accentBright,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildExamplePatterns() {
    final patterns = _specialContent!['examplePatterns'] as List;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pattern, color: AppColors.info, size: 20),
              SizedBox(width: 8),
              Text(
                'Örnek Kalıplar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...patterns.map((pattern) {
            final p = pattern as Map<String, dynamic>;
            final examples = p['examples'] as List? ?? [];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p['pattern'] != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundDark.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p['pattern'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentBright,
                        ),
                      ),
                    ),
                  ...examples.map(
                    (ex) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(color: AppColors.info),
                          ),
                          Expanded(
                            child: Text(
                              ex.toString(),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (p['translation'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '🇹🇷 ${p['translation']}',
                        style: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.8),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCommonMistakes() {
    final mistakes = _specialContent!['commonMistakes'] as List;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber, color: AppColors.error, size: 20),
              SizedBox(width: 8),
              Text(
                'Yaygın Hatalar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...mistakes.map((mistake) {
            final m = mistake as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('❌ ', style: TextStyle(fontSize: 18)),
                      Expanded(
                        child: Text(
                          m['mistake'] ?? '',
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (m['why'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 24),
                      child: Text(
                        'Neden yanlış: ${m['why']}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  if (m['correct'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          const Text('✅ ', style: TextStyle(fontSize: 18)),
                          Expanded(
                            child: Text(
                              m['correct'],
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (m['tip'] != null)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lightbulb,
                            size: 16,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              m['tip'],
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickTips() {
    final tips = _specialContent!['quickTips'] as List;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.info.withOpacity(0.2),
            AppColors.accentBright.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.tips_and_updates,
                color: AppColors.accentBright,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Hızlı İpuçları',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      tip.toString(),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryTricks() {
    final tricks = _specialContent!['memoryTricks'] as List;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warning.withOpacity(0.2),
            AppColors.success.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology, color: AppColors.success, size: 20),
              SizedBox(width: 8),
              Text(
                'Ezber Teknikleri',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tricks.map(
            (trick) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🧠 ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      trick.toString(),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticePrompts() {
    final prompts = _specialContent!['practicePrompts'] as List;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.fitness_center, color: AppColors.success, size: 20),
              SizedBox(width: 8),
              Text(
                'Pratik Yapın',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...prompts.map(
            (prompt) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      prompt.toString(),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

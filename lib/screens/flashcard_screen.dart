import 'package:flutter/material.dart';
import '../models/document_analysis_model.dart';
import '../services/vocabulary_service.dart';
import '../utils/app_colors.dart';

class FlashcardScreen extends StatefulWidget {
  final List<EnhancedVocabularyItem> vocabulary;
  final String title;

  const FlashcardScreen({
    super.key,
    required this.vocabulary,
    required this.title,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  final VocabularyService _vocabularyService = VocabularyService(
    'test_user',
  ); // TODO: Add user ID
  int _currentIndex = 0;
  bool _isFlipped = false;

  Future<void> _markAsLearned() async {
    final currentItem = widget.vocabulary[_currentIndex];

    // Immediate UI feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ "${currentItem.german}" öğrenildi!'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      // Find word by text and update status
      await _vocabularyService.markAsLearnedByText(currentItem.german);
    } catch (e) {
      print('Error marking word as learned: $e');
      // Don't show error to user to keep flow smooth, just log
    }

    // Auto-advance to next card
    if (_currentIndex < widget.vocabulary.length - 1) {
      setState(() {
        _currentIndex++;
        _isFlipped = false;
      });
    } else {
      // End of cards
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Tebrikler! Tüm kartları tamamladın.'),
            backgroundColor: AppColors.accentBright,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.vocabulary.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: AppColors.backgroundCard,
        ),
        body: Center(
          child: Text(
            'Bu kategoride henüz kelime yok.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ),
      );
    }

    final currentWord = widget.vocabulary[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.backgroundCard,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress Bar
          LinearProgressIndicator(
            value: (_currentIndex + 1) / widget.vocabulary.length,
            backgroundColor: AppColors.backgroundCard,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBright),
          ),

          // Counter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '${_currentIndex + 1} / ${widget.vocabulary.length}',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),

          // Flashcard
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isFlipped = !_isFlipped;
                  });
                },
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.all(32),
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: _isFlipped
                          ? AppColors.accentBright
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_isFlipped) ...[
                        // Front Side (German)
                        if (currentWord.article.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentBright.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              currentWord.article,
                              style: TextStyle(
                                color: AppColors.accentBright,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        SizedBox(height: 16),
                        Text(
                          currentWord.german,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (currentWord.plural.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Pl: ${currentWord.plural}',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        SizedBox(height: 32),
                        Text(
                          'Cevabı görmek için dokun',
                          style: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ] else ...[
                        // Back Side (Turkish & Context)
                        Text(
                          currentWord.translation,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.accentBright,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 24),
                        if (currentWord.exampleSentence.isNotEmpty)
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundDark,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              currentWord.exampleSentence,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        if (currentWord.professionalContext.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              'Bağlam: ${currentWord.professionalContext}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.info,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Navigation Buttons with center "Learned" button
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Previous button
                IconButton(
                  onPressed: _currentIndex > 0
                      ? () {
                          setState(() {
                            _currentIndex--;
                            _isFlipped = false;
                          });
                        }
                      : null,
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: _currentIndex > 0
                        ? AppColors.textPrimary
                        : Colors.grey,
                  ),
                  iconSize: 32,
                ),

                // Center "Learned" button (green check)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _markAsLearned,
                    icon: const Icon(Icons.check, color: Colors.white),
                    iconSize: 36,
                    tooltip: 'Öğrendim',
                  ),
                ),

                // Next button
                IconButton(
                  onPressed: _currentIndex < widget.vocabulary.length - 1
                      ? () {
                          setState(() {
                            _currentIndex++;
                            _isFlipped = false;
                          });
                        }
                      : null,
                  icon: Icon(
                    Icons.arrow_forward_ios,
                    color: _currentIndex < widget.vocabulary.length - 1
                        ? AppColors.textPrimary
                        : Colors.grey,
                  ),
                  iconSize: 32,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

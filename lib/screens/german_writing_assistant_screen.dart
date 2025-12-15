import 'package:flutter/material.dart';
import '../models/ai_feedback_model.dart';
import '../services/gemini_ai_service.dart';
import '../utils/app_colors.dart';

/// Screen for writing German text and getting AI feedback
class GermanWritingAssistantScreen extends StatefulWidget {
  const GermanWritingAssistantScreen({super.key});

  @override
  State<GermanWritingAssistantScreen> createState() =>
      _GermanWritingAssistantScreenState();
}

class _GermanWritingAssistantScreenState
    extends State<GermanWritingAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final GeminiAIService _aiService = GeminiAIService();

  AIFeedback? _feedback;
  bool _isChecking = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _checkText() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen kontrol edilecek bir metin yazın'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isChecking = true;
      _feedback = null;
    });

    try {
      final feedback = await _aiService.checkGermanText(_textController.text);
      setState(() {
        _feedback = feedback;
        _isChecking = false;
      });
    } catch (e) {
      setState(() => _isChecking = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _clearAll() {
    setState(() {
      _textController.clear();
      _feedback = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Almanca Yazma Asistanı'),
        backgroundColor: AppColors.backgroundCard,
        actions: [
          if (_textController.text.isNotEmpty || _feedback != null)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearAll,
              tooltip: 'Temizle',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Instructions card
                  Card(
                    color: AppColors.info.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.info.withOpacity(0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.info),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Almanca bir cümle veya paragraf yazın. AI asistanınız gramer hatalarını, kelime seçimlerini ve stil önerilerini kontrol edecek.',
                              style: TextStyle(
                                color: AppColors.info,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Text input
                  TextField(
                    controller: _textController,
                    maxLines: 8,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Almanca metninizi buraya yazın...\n\nÖrnek: Ich gehe zu Schule jeden Tag.',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: AppColors.backgroundCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.accentBright,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 16),

                  // Check button
                  ElevatedButton.icon(
                    onPressed: _isChecking ? null : _checkText,
                    icon: _isChecking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.check_circle),
                    label: Text(
                      _isChecking ? 'Kontrol Ediliyor...' : 'Kontrol Et',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBright,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Feedback section
                  if (_feedback != null) ...[_buildFeedbackSection(_feedback!)],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(AIFeedback feedback) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Score card
        Card(
          color: _getScoreColor(feedback.score).withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _getScoreColor(feedback.score).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      feedback.isCorrect ? Icons.check_circle : Icons.info,
                      color: _getScoreColor(feedback.score),
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${feedback.score}/100',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(feedback.score),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  feedback.isCorrect ? 'Mükemmel!' : 'Geliştirebilirsin!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _getScoreColor(feedback.score),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Corrected text (if there are errors)
        if (feedback.correctedText != null &&
            feedback.correctedText!.isNotEmpty) ...[
          _buildSectionCard(
            title: 'Düzeltilmiş Metin',
            icon: Icons.edit,
            color: AppColors.success,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                feedback.correctedText!,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Errors
        if (feedback.errors.isNotEmpty) ...[
          _buildSectionCard(
            title: 'Hatalar (${feedback.errors.length})',
            icon: Icons.error_outline,
            color: AppColors.error,
            child: Column(
              children: feedback.errors
                  .map((error) => _buildErrorCard(error))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Overall feedback
        _buildSectionCard(
          title: 'Genel Değerlendirme',
          icon: Icons.feedback,
          color: AppColors.info,
          child: Text(
            feedback.overallFeedback,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Suggestions
        if (feedback.suggestions.isNotEmpty) ...[
          _buildSectionCard(
            title: 'Öneriler',
            icon: Icons.lightbulb_outline,
            color: AppColors.warning,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: feedback.suggestions.map((suggestion) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Card(
      color: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(GrammarError error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _getErrorTypeText(error.errorType),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Error text and correction
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hatalı:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      error.errorText,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.error,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward,
                color: AppColors.textMuted,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Doğru:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      error.correction,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),

          // Rule
          if (error.rule.isNotEmpty) ...[
            Text(
              'Kural: ${error.rule}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.accentBright,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Explanation
          Text(
            error.explanation,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),

          // Examples
          if (error.examples.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Örnekler:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ...error.examples.map((example) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(color: AppColors.success),
                    ),
                    Expanded(
                      child: Text(
                        example,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
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
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return AppColors.success;
    if (score >= 70) return AppColors.accentBright;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  String _getErrorTypeText(String errorType) {
    switch (errorType) {
      case 'grammar':
        return 'GRAMER';
      case 'spelling':
        return 'YAZIM';
      case 'word_choice':
        return 'KELİME SEÇİMİ';
      case 'style':
        return 'STİL';
      default:
        return errorType.toUpperCase();
    }
  }
}

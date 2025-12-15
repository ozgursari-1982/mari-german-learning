import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/quiz_model.dart';
import '../services/gemini_ai_service.dart';
import 'take_test_screen.dart';
import 'lesson_screen.dart';

class TestResultDetailScreen extends StatefulWidget {
  final QuizResult result;

  const TestResultDetailScreen({super.key, required this.result});

  @override
  State<TestResultDetailScreen> createState() => _TestResultDetailScreenState();
}

class _TestResultDetailScreenState extends State<TestResultDetailScreen> {
  final GeminiAIService _aiService = GeminiAIService();

  Future<void> _teachTopic(String topic) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final lesson = await _aiService.generateLesson(topic);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LessonScreen(lesson: lesson)),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ders hazırlanırken hata: $e')));
    }
  }

  Future<void> _createPracticeTest() async {
    if (widget.result.feedback.weakTopics.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final weakTopicsStr = widget.result.feedback.weakTopics.join(', ');
      final newQuiz = await _aiService.generateQuiz(
        topic: "Pratik: $weakTopicsStr",
        level: widget.result.quizLevel,
        subTopics: widget.result.feedback.weakTopics,
      );

      if (!mounted) return;
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TakeTestScreen(quiz: newQuiz)),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (widget.result.score / widget.result.totalPoints * 100)
        .toInt();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text(
          'Test Sonucu Detayı',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _getScoreColor(percentage), width: 6),
                boxShadow: [
                  BoxShadow(
                    color: _getScoreColor(percentage).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(percentage),
                    ),
                  ),
                  Text(
                    'Başarı',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.result.quizTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Toplam Puan: ${widget.result.score} / ${widget.result.totalPoints}',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            _buildAICoachSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAICoachSection() {
    final feedback = widget.result.feedback;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology, color: AppColors.accentBright, size: 28),
              SizedBox(width: 12),
              Text(
                'AI Koçun Tavsiyeleri',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            feedback.overallComment,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          if (feedback.strongTopics.isNotEmpty) ...[
            const Text(
              'Başarılı Olduğun Konular:',
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: feedback.strongTopics.map((topic) {
                return Chip(
                  label: Text(topic),
                  backgroundColor: AppColors.success.withOpacity(0.1),
                  labelStyle: const TextStyle(color: AppColors.success),
                  side: const BorderSide(color: AppColors.success),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          if (feedback.weakTopics.isNotEmpty) ...[
            const Text(
              'Geliştirilmesi Gereken Konular:',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: feedback.weakTopics.map((topic) {
                return ActionChip(
                  label: Text(topic),
                  backgroundColor: AppColors.error.withOpacity(0.1),
                  labelStyle: const TextStyle(color: AppColors.error),
                  side: const BorderSide(color: AppColors.error),
                  avatar: const Icon(
                    Icons.school,
                    size: 16,
                    color: AppColors.error,
                  ),
                  onPressed: () => _teachTopic(topic),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createPracticeTest,
                icon: const Icon(Icons.fitness_center),
                label: const Text('Bu Konularda Pratik Yap'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMedium,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (feedback.mistakeAnalyses.isNotEmpty) ...[
            const Text(
              'Hata Analizi:',
              style: TextStyle(
                color: AppColors.accentBright,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ...feedback.mistakeAnalyses.map((mistake) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mistake.topic,
                      style: const TextStyle(
                        color: AppColors.accentBright,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mistake.explanation,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.success.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 16,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              mistake.correctUsage,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _teachTopic(mistake.topic),
                        icon: const Icon(
                          Icons.school,
                          size: 16,
                          color: AppColors.accentBright,
                        ),
                        label: const Text(
                          'Konuyu Çalıştır',
                          style: TextStyle(
                            color: AppColors.accentBright,
                            fontSize: 12,
                          ),
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

  Color _getScoreColor(int percentage) {
    if (percentage >= 80) return AppColors.success;
    if (percentage >= 60) return AppColors.warning;
    return AppColors.error;
  }
}

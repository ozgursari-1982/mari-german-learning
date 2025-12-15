import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/quiz_model.dart';

/// Detailed answer review screen showing all questions with explanations
class AnswerReviewScreen extends StatelessWidget {
  final Quiz quiz;
  final Map<String, dynamic> userAnswers;
  final QuizFeedback feedback;

  const AnswerReviewScreen({
    super.key,
    required this.quiz,
    required this.userAnswers,
    required this.feedback,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text(
          'Cevap Analizi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.backgroundCard,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: feedback.answerDetails.isNotEmpty
            ? feedback.answerDetails.length
            : quiz.questions.length,
        itemBuilder: (context, index) {
          if (feedback.answerDetails.isNotEmpty) {
            // Use AI-generated detailed analysis
            final detail = feedback.answerDetails[index];
            return _buildAnswerCard(
              questionNumber: index + 1,
              questionText: detail.questionText,
              userAnswer: detail.userAnswer,
              correctAnswer: detail.correctAnswer,
              isCorrect: detail.isCorrect,
              partiallyCorrect: detail.partiallyCorrect,
              minorIssues: detail.minorIssues,
              explanation: detail.explanation,
              topic: detail.topic,
            );
          } else {
            // Fallback if no AI details available
            final question = quiz.questions[index];
            final userAnswer = userAnswers[question.id] ?? 'Cevap verilmedi';
            final isCorrect = _checkAnswer(question, userAnswer);

            return _buildAnswerCard(
              questionNumber: index + 1,
              questionText: question.questionText,
              userAnswer: userAnswer.toString(),
              correctAnswer: question.correctAnswer,
              isCorrect: isCorrect,
              partiallyCorrect: false,
              minorIssues: '',
              explanation: question.explanation ?? 'Açıklama mevcut değil',
              topic: 'Konu belirtilmedi',
            );
          }
        },
      ),
    );
  }

  bool _checkAnswer(Question question, dynamic userAnswer) {
    if (userAnswer == null) return false;
    return _normalizeString(userAnswer.toString()) ==
        _normalizeString(question.correctAnswer);
  }

  String _normalizeString(String input) {
    return input.toLowerCase().trim().replaceAll(RegExp(r'[.,!?]'), '');
  }

  Widget _buildAnswerCard({
    required int questionNumber,
    required String questionText,
    required String userAnswer,
    required String correctAnswer,
    required bool isCorrect,
    required bool partiallyCorrect,
    required String minorIssues,
    required String explanation,
    required String topic,
  }) {
    // Determine status color and icon
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isCorrect) {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle;
      statusText = 'Doğru';
    } else if (partiallyCorrect) {
      statusColor = AppColors.warning;
      statusIcon = Icons.warning_amber;
      statusText = 'Doğru (Küçük Hatalar)';
    } else {
      statusColor = AppColors.error;
      statusIcon = Icons.cancel;
      statusText = 'Yanlış';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Question number + Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryMedium.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$questionNumber',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentBright,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  topic,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(statusIcon, color: statusColor, size: 28),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Question Text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              questionText,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // User Answer
          _buildAnswerRow(
            label: 'Senin Cevabın:',
            answer: userAnswer,
            color: isCorrect
                ? AppColors.success
                : (partiallyCorrect ? AppColors.warning : AppColors.error),
          ),
          const SizedBox(height: 12),

          // Correct Answer (only if wrong or partially correct)
          if (!isCorrect || partiallyCorrect) ...[
            _buildAnswerRow(
              label: 'Doğru Cevap:',
              answer: correctAnswer,
              color: AppColors.success,
            ),
            const SizedBox(height: 16),
          ],

          // Minor Issues (for partially correct answers)
          if (partiallyCorrect && minorIssues.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Küçük Hatalar:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          minorIssues,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Explanation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentBright.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.accentBright.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.school, color: AppColors.accentBright, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Açıklama:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentBright,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  explanation,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerRow({
    required String label,
    required String answer,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

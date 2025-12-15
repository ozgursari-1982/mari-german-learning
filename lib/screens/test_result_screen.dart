import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/quiz_model.dart';
import '../services/gemini_ai_service.dart';
import '../services/firestore_service.dart';
import '../services/learning_progress_service.dart';
import 'home_screen.dart';
import 'take_test_screen.dart';
import 'lesson_screen.dart';
import 'answer_review_screen.dart';

class TestResultScreen extends StatefulWidget {
  final Quiz quiz;
  final Map<String, dynamic> userAnswers;

  const TestResultScreen({
    super.key,
    required this.quiz,
    required this.userAnswers,
  });

  @override
  State<TestResultScreen> createState() => _TestResultScreenState();
}

class _TestResultScreenState extends State<TestResultScreen> {
  final GeminiAIService _aiService = GeminiAIService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoadingFeedback = true;
  QuizFeedback? _feedback;

  @override
  void initState() {
    super.initState();
    _generateFeedback();
  }

  int _calculateScore() {
    int score = 0;
    for (var question in widget.quiz.questions) {
      final userAnswer = widget.userAnswers[question.id];
      if (userAnswer == null) continue;

      if (_isAnswerCorrect(question, userAnswer)) {
        score += question.points;
      }
    }
    return score;
  }

  bool _isAnswerCorrect(Question question, dynamic userAnswer) {
    if (userAnswer == null) return false;

    switch (question.type) {
      case QuestionType.writing:
        return userAnswer.toString().length > 10;

      case QuestionType.matching:
        if (question.matchingPairs != null && userAnswer is Map) {
          bool allCorrect = true;
          question.matchingPairs!.forEach((key, value) {
            final userValue = userAnswer[key]?.toString() ?? '';
            // Normalize both values for comparison
            if (_normalizeString(userValue) != _normalizeString(value)) {
              allCorrect = false;
            }
          });
          return allCorrect;
        }
        return false;

      case QuestionType.ordering:
        if (userAnswer is List) {
          // Join user's answer with space
          final userSentence = userAnswer.join(' ');
          // correctAnswer might be comma-separated or space-separated
          final correctNormalized = _normalizeString(
            question.correctAnswer.replaceAll(',', ' ').replaceAll('  ', ' '),
          );
          return _normalizeString(userSentence) == correctNormalized;
        }
        return false;

      default:
        return _normalizeString(userAnswer.toString()) ==
            _normalizeString(question.correctAnswer);
    }
  }

  String _normalizeString(String input) {
    return input
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[.,!?;:\-]'), '') // Remove punctuation
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
  }

  Future<void> _generateFeedback() async {
    // Calculate correctness map using the robust logic
    final correctnessMap = <String, bool>{};
    for (var q in widget.quiz.questions) {
      correctnessMap[q.id] = _isAnswerCorrect(q, widget.userAnswers[q.id]);
    }

    final score = _calculateScore();
    final totalPoints = _getTotalPoints();
    final correctAnswers = correctnessMap.values.where((v) => v).length;

    // ✅ STEP 1: UPDATE PROGRESS FIRST (before AI feedback!)
    try {
      final progressService = LearningProgressService('test_user');
      await progressService.updateProgressFromQuiz(
        topic: widget.quiz.topic,
        totalQuestions: widget.quiz.questions.length,
        correctAnswers: correctAnswers,
        category: widget.quiz.level,
      );
      print(
        '✅ Progress updated: $correctAnswers/${widget.quiz.questions.length} correct',
      );
    } catch (e) {
      print('❌ Error updating progress: $e');
    }

    // ✅ STEP 2: Generate AI feedback
    QuizFeedback? feedback;
    try {
      feedback = await _aiService.generateQuizFeedback(
        quiz: widget.quiz,
        userAnswers: widget.userAnswers,
        correctnessMap: correctnessMap,
      );
      print('✅ AI feedback generated successfully');
    } catch (e) {
      print('❌ Error generating AI feedback: $e');
      // Create a basic fallback feedback
      feedback = QuizFeedback(
        overallComment:
            'Test tamamlandı! Skorunuz: ${(score / totalPoints * 100).toInt()}%',
        weakTopics: [],
        strongTopics: [],
        mistakeAnalyses: [],
        studyRecommendation: 'Daha fazla pratik yaparak gelişmeye devam edin!',
      );
    }

    // ✅ STEP 3: Save result to Firestore
    try {
      final result = QuizResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        quizId: widget.quiz.id,
        quizTitle: widget.quiz.title,
        quizTopic: widget.quiz.topic,
        quizLevel: widget.quiz.level,
        score: score,
        totalPoints: totalPoints,
        date: DateTime.now(),
        feedback: feedback,
      );
      await _firestoreService.saveQuizResult(result);
      print('✅ Quiz result saved to Firestore');
    } catch (e) {
      print('❌ Error saving quiz result: $e');
    }

    // ✅ STEP 4: Update UI
    if (mounted) {
      setState(() {
        _feedback = feedback;
        _isLoadingFeedback = false;
      });
    }
  }

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

  int _getTotalPoints() {
    return widget.quiz.questions.fold(0, (sum, q) => sum + q.points);
  }

  Future<void> _createPracticeTest() async {
    if (_feedback == null || _feedback!.weakTopics.isEmpty) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Create a new quiz focused on weak topics
      final weakTopicsStr = _feedback!.weakTopics.join(', ');
      final newQuiz = await _aiService.generateQuiz(
        topic: "Pratik: $weakTopicsStr",
        level: widget.quiz.level,
        subTopics: _feedback!.weakTopics,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Navigate to new test
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TakeTestScreen(quiz: newQuiz)),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = _calculateScore();
    final totalPoints = _getTotalPoints();
    final percentage = (score / totalPoints * 100).toInt();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              // Score Circle
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _getScoreColor(percentage),
                    width: 8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getScoreColor(percentage).withValues(alpha: 0.3),
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
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(percentage),
                      ),
                    ),
                    Text(
                      'Başarı Oranı',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Text(
                _getFeedbackMessage(percentage),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Toplam Puan: $score / $totalPoints',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 32),

              // AI Coach Section
              if (_isLoadingFeedback)
                const Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.accentBright),
                    SizedBox(height: 16),
                    Text(
                      'AI Koçun sonuçlarını analiz ediyor...',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                )
              else if (_feedback != null)
                _buildAICoachSection(),

              const SizedBox(height: 48),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.textSecondary),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Ana Sayfa'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _feedback != null
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AnswerReviewScreen(
                                    quiz: widget.quiz,
                                    userAnswers: widget.userAnswers,
                                    feedback: _feedback!,
                                  ),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentBright,
                        foregroundColor: AppColors.primaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cevapları İncele'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAICoachSection() {
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
            _feedback!.overallComment,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Strong Topics (Artı Yönlerin)
          if (_feedback!.strongTopics.isNotEmpty) ...[
            const Text(
              'Başarılı Olduğun Konular (Artı Yönlerin):',
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
              children: _feedback!.strongTopics.map((topic) {
                return Chip(
                  label: Text(topic),
                  backgroundColor: AppColors.success.withValues(alpha: 0.1),
                  labelStyle: const TextStyle(color: AppColors.success),
                  side: const BorderSide(color: AppColors.success),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Weak Topics
          if (_feedback!.weakTopics.isNotEmpty) ...[
            const Text(
              'Geliştirilmesi Gereken Konular (Eksiklerin):',
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
              children: _feedback!.weakTopics.map((topic) {
                return ActionChip(
                  label: Text(topic),
                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
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

          // Mistake Analysis
          if (_feedback!.mistakeAnalyses.isNotEmpty) ...[
            const Text(
              'Hata Analizi:',
              style: TextStyle(
                color: AppColors.accentBright,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ..._feedback!.mistakeAnalyses.map((mistake) {
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
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3),
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

  String _getFeedbackMessage(int percentage) {
    if (percentage >= 90) return 'Mükemmel! 🌟';
    if (percentage >= 80) return 'Harika İş! 👏';
    if (percentage >= 60) return 'İyi Gidiyorsun! 👍';
    if (percentage >= 40) return 'Biraz Daha Çalışmalısın 💪';
    return 'Pes Etmek Yok! 🚀';
  }
}

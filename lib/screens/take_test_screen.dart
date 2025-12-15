import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/quiz_model.dart';
import 'test_result_screen.dart';

class TakeTestScreen extends StatefulWidget {
  final Quiz quiz;

  const TakeTestScreen({super.key, required this.quiz});

  @override
  State<TakeTestScreen> createState() => _TakeTestScreenState();
}

class _TakeTestScreenState extends State<TakeTestScreen> {
  final PageController _pageController = PageController();
  int _currentQuestionIndex = 0;
  final Map<String, dynamic> _userAnswers = {}; // questionId -> answer

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishTest();
    }
  }

  void _finishTest() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TestResultScreen(quiz: widget.quiz, userAnswers: _userAnswers),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(widget.quiz.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / widget.quiz.questions.length,
            backgroundColor: AppColors.backgroundCard,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.accentBright,
            ),
          ),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe
        onPageChanged: (index) => setState(() => _currentQuestionIndex = index),
        itemCount: widget.quiz.questions.length,
        itemBuilder: (context, index) {
          return _buildQuestionCard(widget.quiz.questions[index]);
        },
      ),
    );
  }

  Widget _buildQuestionCard(Question question) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Type Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getQuestionTypeLabel(question.type),
              style: const TextStyle(
                color: AppColors.accentBright,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Question Text (GERMAN)
          Text(
            question.questionText,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          // Turkish Translation (small text below)
          if (question.questionTextTurkish != null &&
              question.questionTextTurkish!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              question.questionTextTurkish!,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 32),

          // Answer Area
          _buildAnswerArea(question),

          const SizedBox(height: 48),

          // Next Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _userAnswers.containsKey(question.id)
                  ? _nextQuestion
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBright,
                disabledBackgroundColor: AppColors.backgroundCard,
                foregroundColor: AppColors.primaryDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _currentQuestionIndex == widget.quiz.questions.length - 1
                    ? 'Sınavı Bitir'
                    : 'Sonraki Soru',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerArea(Question question) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        return _buildMultipleChoice(question);
      case QuestionType.trueFalse:
        return _buildTrueFalse(question);
      case QuestionType.fillInBlanks:
        return _buildFillInBlanks(question);
      case QuestionType.writing:
        return _buildWriting(question);
      case QuestionType.matching:
        return _buildMatching(question);
      case QuestionType.ordering:
        return _buildOrdering(question);
    }
  }

  Widget _buildMultipleChoice(Question question) {
    return Column(
      children: question.options!.map((option) {
        final isSelected = _userAnswers[question.id] == option;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => setState(() => _userAnswers[question.id] = option),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accentBright.withValues(alpha: 0.2)
                    : AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.accentBright
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accentBright
                            : AppColors.textSecondary,
                        width: 2,
                      ),
                      color: isSelected ? AppColors.accentBright : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: AppColors.primaryDark,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 16,
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrueFalse(Question question) {
    return Row(
      children: ['Richtig', 'Falsch'].map((option) {
        final isSelected = _userAnswers[question.id] == option;
        final isTrue = option == 'Richtig';
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: isTrue ? 8 : 0,
              left: isTrue ? 0 : 8,
            ),
            child: InkWell(
              onTap: () => setState(() => _userAnswers[question.id] = option),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isTrue
                            ? AppColors.success.withValues(alpha: 0.2)
                            : AppColors.error.withValues(alpha: 0.2))
                      : AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? (isTrue ? AppColors.success : AppColors.error)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isTrue ? Icons.check_circle : Icons.cancel,
                      size: 40,
                      color: isSelected
                          ? (isTrue ? AppColors.success : AppColors.error)
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      option,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFillInBlanks(Question question) {
    return TextField(
      onChanged: (value) => setState(() => _userAnswers[question.id] = value),
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
      decoration: InputDecoration(
        hintText: 'Cevabını buraya yaz...',
        hintStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.backgroundCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentBright, width: 2),
        ),
      ),
    );
  }

  Widget _buildWriting(Question question) {
    return TextField(
      onChanged: (value) => setState(() => _userAnswers[question.id] = value),
      maxLines: 8,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
      decoration: InputDecoration(
        hintText: 'Metnini buraya yaz...',
        hintStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.backgroundCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentBright, width: 2),
        ),
      ),
    );
  }

  Widget _buildMatching(Question question) {
    // Initialize if not exists
    if (_userAnswers[question.id] == null) {
      _userAnswers[question.id] = <String, String>{};
    }
    final Map<String, String> currentMatches =
        _userAnswers[question.id] as Map<String, String>;
    final pairs = question.matchingPairs ?? {};
    final leftItems = pairs.keys.toList();
    final rightItems = pairs.values.toList()..shuffle(); // Shuffle right side

    return Column(
      children: leftItems.map((left) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryMedium),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  left,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.arrow_right_alt, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: currentMatches[left],
                    hint: const Text(
                      'Seçiniz',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    dropdownColor: AppColors.backgroundCard,
                    isExpanded: true,
                    style: const TextStyle(color: AppColors.textPrimary),
                    items: rightItems.map((right) {
                      return DropdownMenuItem(value: right, child: Text(right));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        currentMatches[left] = value!;
                        _userAnswers[question.id] = currentMatches;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOrdering(Question question) {
    // Initialize if not exists
    if (_userAnswers[question.id] == null) {
      _userAnswers[question.id] = List<String>.from(question.options ?? []);
    }
    final List<String> currentOrder = _userAnswers[question.id] as List<String>;

    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final String item = currentOrder.removeAt(oldIndex);
          currentOrder.insert(newIndex, item);
          _userAnswers[question.id] = currentOrder;
        });
      },
      children: [
        for (int i = 0; i < currentOrder.length; i++)
          Container(
            key: ValueKey(currentOrder[i]),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryMedium),
            ),
            child: Row(
              children: [
                const Icon(Icons.drag_handle, color: AppColors.textMuted),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    currentOrder[i],
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _getQuestionTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'Çoktan Seçmeli';
      case QuestionType.fillInBlanks:
        return 'Boşluk Doldurma';
      case QuestionType.trueFalse:
        return 'Doğru / Yanlış';
      case QuestionType.writing:
        return 'Yazma (Writing)';
      case QuestionType.matching:
        return 'Eşleştirme';
      case QuestionType.ordering:
        return 'Sıralama';
    }
  }
}

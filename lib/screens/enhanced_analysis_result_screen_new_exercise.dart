// YENİ EXERCISE DISPLAY WIDGET - SONRA KOPYALANACAK

Widget _buildExerciseContent() {
  final content = _specialContent!;

  // Yeni yapıyı mı eski yapıyı mı kullanıyor kontrol et
  final hasNewStructure = content['solutionsByType'] != null;
  final hasOldStructure = content['solutions'] != null;

  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Teaching Introduction (sadece yeni yapıda)
        if (content['teachingIntro'] != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accentBright.withOpacity(0.2),
                  AppColors.info.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.school,
                  color: AppColors.accentBright,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🎓 Öğretmen Notları',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentBright,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        content['teachingIntro'],
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
          ),
          const SizedBox(height: 20),
        ],

        // Genel bilgi
        if (content['exerciseDescription'] != null) ...[
          Text(
            content['exerciseDescription'],
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
        ],

        // YENİ YAPI: solutionsByType
        if (hasNewStructure)
          ...(content['solutionsByType'] as List).map((typeSection) {
            return _buildQuestionTypeSection(typeSection);
          }),

        // ESKİ YAPI: solutions (backwards compatibility)
        if (!hasNewStructure && hasOldStructure)
          ...(content['solutions'] as List).map((solution) {
            return _buildOldStyleSolution(solution);
          }),

        // Overall Teaching (yeni yapı)
        if (content['overallTeaching'] != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentBright.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.school, color: AppColors.accentBright, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '📚 Özet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentBright,
                      ),
                    ),
                  ],
                ),
                if (content['overallTeaching']['summary'] != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    content['overallTeaching']['summary'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),
      ],
    ),
  );
}

// Yeni yapı için tip bazlı soru bölümü
Widget _buildQuestionTypeSection(Map<String, dynamic> typeSection) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Tip başlığı
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.accentBright.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.category, color: AppColors.accentBright, size: 18),
            const SizedBox(width: 8),
            Text(
              typeSection['type']?.toString().toUpperCase() ?? 'SORULAR',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.accentBright,
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 12),

      // Bu tipteki sorular
      if (typeSection['solutions'] != null)
        ...(typeSection['solutions'] as List).map((solution) {
          return _buildEnhancedSolution(solution);
        }),

      const SizedBox(height: 20),
    ],
  );
}

// Yeni yapı için gelişmiş çözüm kartı
Widget _buildEnhancedSolution(Map<String, dynamic> solution) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.backgroundCard,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.success.withOpacity(0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Soru numarası
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Soru ${solution['questionNumber'] ?? ''}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Soru
        if (solution['question'] != null) ...[
          Text(
            solution['question'],
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Doğru cevap
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '✅ ${solution['correctAnswer'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Düşünce süreci (yeni)
        if (solution['stepByStepThinking'] != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.psychology, color: AppColors.warning, size: 18),
                    SizedBox(width: 8),
                    Text(
                      '💭 Nasıl Düşünüyoruz?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...(solution['stepByStepThinking'] as List).asMap().entries.map(
                  (entry) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.value.toString(),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],

        // Açıklama
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
                const Row(
                  children: [
                    Icon(Icons.lightbulb, color: AppColors.info, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Açıklama',
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

        // Yaygın hatalar (yeni)
        if (solution['commonMistakes'] != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber, color: AppColors.error, size: 18),
                    SizedBox(width: 8),
                    Text(
                      '⚠️ Dikkat!',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...(solution['commonMistakes'] as List).map((mistake) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '• ${mistake['whyWrong'] ?? mistake['wrongAnswer'] ?? mistake}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],

        // Hafıza ipucu (yeni)
        if (solution[' memoryTrick'] != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Text('🧠', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    solution['memoryTrick'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      fontStyle: FontStyle.italic,
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
}

// Eski yapı için basit çözüm kartı (backwards compatibility)
Widget _buildOldStyleSolution(Map<String, dynamic> solution) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.backgroundCard,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.success.withOpacity(0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Soru numarası
        Text(
          'Soru ${solution['questionNumber'] ?? ''}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.success,
          ),
        ),

        const SizedBox(height: 8),

        // Soru
        if (solution['question'] != null) ...[
          Text(
            solution['question'],
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
        ],

        // Cevap
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '✅ ${solution['correctAnswer'] ?? ''}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
        ),

        // Açıklama
        if (solution['explanation'] != null) ...[
          const SizedBox(height: 12),
          Text(
            solution['explanation'],
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ],
    ),
  );
}

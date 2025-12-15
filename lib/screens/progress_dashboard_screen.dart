import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../services/ai_feedback_service.dart';
import '../services/learning_progress_service.dart';

/// Personalized progress dashboard with AI feedback
class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() =>
      _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  final AIFeedbackService _feedbackService = AIFeedbackService('test_user');
  final LearningProgressService _progressService = LearningProgressService(
    'test_user',
  );

  PersonalizedFeedback? _feedback;
  WeeklySummary? _weeklySummary;
  Map<String, dynamic>? _progressStats;
  bool _isLoading = true;
  String _dailyInsight = '';

  @override
  void initState() {
    super.initState();
    _loadData(); // Initial load uses cache
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _feedbackService.generateFeedback(
          forceRefresh: forceRefresh,
        ), // Cache or refresh
        _feedbackService.generateWeeklySummary(),
        _feedbackService.generateDailyInsight(),
        _progressService.getProgressStats(),
      ]);

      if (mounted) {
        setState(() {
          _feedback = results[0] as PersonalizedFeedback;
          _weeklySummary = results[1] as WeeklySummary;
          _dailyInsight = results[2] as String;
          _progressStats = results[3] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text(
          'İlerleme Panosu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.backgroundCard,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yeniden Analiz Et',
            onPressed: () =>
                _loadData(forceRefresh: true), // AI'dan yeni veri çek!
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accentBright),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.accentBright,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Daily Insight Card
                    _buildDailyInsightCard(),
                    const SizedBox(height: 16),

                    // Progress Overview
                    _buildProgressOverviewCard(),
                    const SizedBox(height: 16),

                    // AI Feedback Section
                    if (_feedback != null) ...[
                      _buildAIFeedbackCard(),
                      const SizedBox(height: 16),
                    ],

                    // Weekly Summary
                    if (_weeklySummary != null) ...[
                      _buildWeeklySummaryCard(),
                      const SizedBox(height: 16),
                    ],

                    // Strengths & Weaknesses
                    if (_feedback != null) ...[
                      _buildStrengthsWeaknessesCard(),
                      const SizedBox(height: 16),
                    ],

                    // Recommendations
                    if (_feedback != null) ...[
                      _buildRecommendationsCard(),
                      const SizedBox(height: 16),
                    ],

                    // Study Plan
                    if (_feedback != null) ...[
                      _buildStudyPlanCard(),
                      const SizedBox(height: 16),
                    ],

                    // Next Steps
                    if (_feedback != null) ...[_buildNextStepsCard()],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDailyInsightCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentBright.withOpacity(0.2),
            AppColors.info.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentBright.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentBright.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb,
              color: AppColors.accentBright,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _dailyInsight,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressOverviewCard() {
    final progress = _progressStats?['overallProgress'] ?? 0;
    final progressToB2 = _progressStats?['progressToB2'] ?? 0;
    final currentLevel = _progressStats?['currentLevel'] ?? 'A1';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Genel İlerleme',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentBright.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  currentLevel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentBright,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Overall Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Toplam İlerleme',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '%$progress',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentBright,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 10,
                  backgroundColor: AppColors.backgroundDark,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.accentBright,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // B2 Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'B2 Hedefine İlerleme',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '%$progressToB2',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progressToB2 / 100,
                  minHeight: 10,
                  backgroundColor: AppColors.backgroundDark,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.success,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.school,
                  label: 'Kelime',
                  value: '${_progressStats?['vocabularyMastered'] ?? 0}',
                  color: AppColors.info,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.quiz,
                  label: 'Test',
                  value: '${_progressStats?['quizzesTaken'] ?? 0}',
                  color: AppColors.warning,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.calendar_today,
                  label: 'Gün',
                  value: '${_progressStats?['totalStudyDays'] ?? 0}',
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildAIFeedbackCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentBright.withOpacity(0.15),
            AppColors.info.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentBright.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentBright.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: AppColors.accentBright,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI Değerlendirmesi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(_feedback!.trendEmoji, style: const TextStyle(fontSize: 24)),
            ],
          ),
          const SizedBox(height: 16),

          // Overall Assessment
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _feedback!.overallAssessment,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Motivation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite, color: AppColors.success, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _feedback!.motivation,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySummaryCard() {
    final trend = _weeklySummary!.trend;
    final trendIcon = trend == 'increasing'
        ? Icons.trending_up
        : trend == 'decreasing'
        ? Icons.trending_down
        : Icons.trending_flat;
    final trendColor = trend == 'increasing'
        ? AppColors.success
        : trend == 'decreasing'
        ? AppColors.error
        : AppColors.info;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bu Hafta',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Icon(trendIcon, color: trendColor, size: 28),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildWeekStatItem(
                  'Çalışma',
                  '${_weeklySummary!.studySessions}',
                  'oturum',
                  AppColors.accentBright,
                ),
              ),
              Expanded(
                child: _buildWeekStatItem(
                  'Soru',
                  '${_weeklySummary!.totalQuestions}',
                  'adet',
                  AppColors.info,
                ),
              ),
              Expanded(
                child: _buildWeekStatItem(
                  'Başarı',
                  '%${_weeklySummary!.accuracy}',
                  '',
                  AppColors.success,
                ),
              ),
            ],
          ),
          if (_weeklySummary!.comparison != 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: trendColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(trendIcon, color: trendColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Geçen haftaya göre ${_weeklySummary!.comparison.abs()} ${_weeklySummary!.comparison > 0 ? 'daha fazla' : 'daha az'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: trendColor,
                      fontWeight: FontWeight.w600,
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

  Widget _buildWeekStatItem(
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (unit.isNotEmpty)
          Text(
            unit,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.7)),
          ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStrengthsWeaknessesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'Analiz',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Strengths
          if (_feedback!.strengths.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Güçlü Alanlar',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _feedback!.strengths
                  .map((strength) => _buildChip(strength, AppColors.success))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Weaknesses
          if (_feedback!.weaknesses.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.trending_up,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Geliştirilmesi Gerekenler',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _feedback!.weaknesses
                  .map((weakness) => _buildChip(weakness, AppColors.warning))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
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
          const Row(
            children: [
              Icon(
                Icons.tips_and_updates,
                color: AppColors.accentBright,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Öneriler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._feedback!.recommendations.asMap().entries.map((entry) {
            final index = entry.key;
            final rec = entry.value;
            final priorityColor = rec.priority == 'high'
                ? AppColors.error
                : rec.priority == 'medium'
                ? AppColors.warning
                : AppColors.info;

            return Padding(
              padding: EdgeInsets.only(
                bottom: index < _feedback!.recommendations.length - 1 ? 12 : 0,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: priorityColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: priorityColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rec.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      rec.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStudyPlanCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withOpacity(0.15),
            AppColors.info.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_month, color: AppColors.success, size: 24),
              SizedBox(width: 8),
              Text(
                'Çalışma Planı',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPlanItem(
            'Bu Hafta',
            _feedback!.studyPlan.thisWeek,
            Icons.calendar_today,
          ),
          const SizedBox(height: 12),
          _buildPlanItem(
            'Günlük Hedef',
            _feedback!.studyPlan.daily,
            Icons.today,
          ),
          const SizedBox(height: 12),
          _buildPlanItem(
            'Odak Konusu',
            _feedback!.studyPlan.focus,
            Icons.gps_fixed,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.success, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
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
          const Row(
            children: [
              Icon(
                Icons.arrow_forward,
                color: AppColors.accentBright,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Sonraki Adımlar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._feedback!.nextSteps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < _feedback!.nextSteps.length - 1 ? 8 : 0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.accentBright.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentBright,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        step,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
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
}

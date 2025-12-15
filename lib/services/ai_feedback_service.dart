import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/gemini_ai_service.dart';
import '../services/learning_progress_service.dart';
import '../services/vocabulary_service.dart';

/// AI-powered personalized feedback service
class AIFeedbackService {
  final String userId;
  final GeminiAIService _aiService = GeminiAIService();
  late final LearningProgressService _progressService;
  late final VocabularyService _vocabularyService;

  static const String _cacheKey = 'ai_feedback_cache';
  static const String _cacheDateKey = 'ai_feedback_cache_date';

  AIFeedbackService(this.userId) {
    _progressService = LearningProgressService(userId);
    _vocabularyService = VocabularyService(userId);
  }

  /// Generate comprehensive personalized feedback with caching
  /// Only regenerates when forceRefresh = true
  Future<PersonalizedFeedback> generateFeedback({
    bool forceRefresh = false,
  }) async {
    try {
      // Check cache first (unless force refresh)
      if (!forceRefresh) {
        final cached = await _getCachedFeedback();
        if (cached != null) {
          print('✅ Using cached feedback');
          return cached;
        }
      }

      print('🔄 Generating new feedback from AI...');

      // Gather all user data
      final progressStats = await _progressService.getProgressStats();
      final studyHistory = await _progressService.getStudyHistory(days: 30);
      final vocabularyStats = await _vocabularyService.getStatistics();

      // Build AI prompt with user data
      final prompt =
          '''
Analyze this German learner's progress and provide personalized, motivating feedback in TURKISH.

USER DATA:
📊 Genel İlerleme: ${progressStats['overallProgress']}%
📚 Mevcut Seviye: ${progressStats['currentLevel']}
🎯 Hedef: B2 (${progressStats['progressToB2']}% tamamlandı)

💪 Güçlü Alanlar: ${(progressStats['strongAreas'] as List).join(', ')}
⚠️ Zayıf Alanlar: ${(progressStats['weakAreas'] as List).join(', ')}

📖 Kelime İstatistikleri:
- Toplam: ${vocabularyStats['total']}
- Öğrenildi: ${vocabularyStats['learned']}
- Ustalaşıldı: ${vocabularyStats['mastered']}
- Bugün tekrar: ${vocabularyStats['dueToday']}

📝 Test İstatistikleri:
- Test sayısı: ${progressStats['quizzesTaken']}
- Ortalama puan: ${progressStats['averageQuizScore'].toStringAsFixed(1)}%

📅 Aktivite:
- Toplam çalışma günü: ${progressStats['totalStudyDays']}
- Bu hafta çalışma: ${progressStats['studySessionsThisWeek']} oturum
- Son 30 gün aktivite: ${studyHistory.length} oturum

GÖREV:
1. İlerlemeyi değerlendir (İlerliyor/Durgun/Geriliyor)
2. Motivasyon ver (övgü ve cesaret)
3. Spesifik tavsiyelerde bulun
4. Bir sonraki adımları öner
5. Hedeflere ne kadar yakın olduğunu açıkla

JSON formatında döndür:
{
  "overallAssessment": "genel değerlendirme (2-3 cümle)",
  "progressTrend": "improving/stable/declining",
  "trendEmoji": "📈 veya ➡️ veya 📉",
  "motivation": "motivasyon mesajı (1-2 cümle)",
  "strengths": ["güçlü_alan_1", "güçlü_alan_2"],
  "weaknesses": ["zayıf_alan_1", "zayıf_alan_2"],
  "recommendations": [
    {
      "title": "Öneri 1",
      "description": "Detaylı açıklama",
      "priority": "high/medium/low"
    }
  ],
  "nextSteps": ["adım_1", "adım_2", "adım_3"],
  "studyPlan": {
    "thisWeek": "Bu hafta önerisi",
    "daily": "Günlük hedef",
    "focus": "Odaklanılacak konu"
  },
  "milestone": {
    "current": "Şu anki başarı",
    "next": "Sonraki hedef",
    "distanceToB2": "B2'ye mesafe açıklaması"
  }
}
''';

      // Call AI
      final response = await _aiService.generateContent(
        prompt: prompt,
        temperature: 0.7,
        responseFormat: 'application/json',
      );

      final feedback = PersonalizedFeedback.fromJson(response);

      // Cache the result
      await _cacheFeedback(feedback);
      print('✅ Feedback cached');

      return feedback;
    } catch (e) {
      print('Error generating feedback: $e');
      return _getFallbackFeedback();
    }
  }

  /// Get cached feedback if available
  Future<PersonalizedFeedback?> _getCachedFeedback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);

      if (cachedJson == null) return null;

      final json = jsonDecode(cachedJson) as Map<String, dynamic>;
      return PersonalizedFeedback.fromJson(json);
    } catch (e) {
      print('Error reading cache: $e');
      return null;
    }
  }

  /// Cache feedback to local storage
  Future<void> _cacheFeedback(PersonalizedFeedback feedback) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = feedback.toJson();
      await prefs.setString(_cacheKey, jsonEncode(json));
      await prefs.setString(_cacheDateKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error caching feedback: $e');
    }
  }

  /// Generate quick daily insight
  Future<String> generateDailyInsight() async {
    try {
      final vocabularyStats = await _vocabularyService.getStatistics();
      final dueWords = vocabularyStats['dueToday'] ?? 0;

      if (dueWords > 0) {
        return '💡 Bugün $dueWords kelime seni bekliyor! Hadi pratik yapalım! 🚀';
      }

      final studyHistory = await _progressService.getStudyHistory(days: 7);
      if (studyHistory.isEmpty) {
        return '⏰ Bu hafta henüz çalışmadın. Bugün başlamak için harika bir gün! 💪';
      }

      return '🌟 Harika gidiyorsun! Bugün de devam et! 📚';
    } catch (e) {
      return '📖 Almanca öğrenmeye hazır mısın? Hadi başlayalım!';
    }
  }

  /// Generate and cache a batch of daily learning tips for notifications
  Future<void> generateDailyTipsBatch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastGen = prefs.getString('tips_generated_date');
      final now = DateTime.now();

      // Only generate once per day
      if (lastGen != null) {
        final lastDate = DateTime.parse(lastGen);
        if (lastDate.year == now.year &&
            lastDate.month == now.month &&
            lastDate.day == now.day) {
          print('✅ Tips already generated for today.');
          return;
        }
      }

      print('🔄 Generating daily tips batch...');

      final prompt = '''
Generate 20 SHORT, diverse German learning tips for notifications. Output ONLY valid JSON.
Language: German tip with Turkish explanation.

Content Types:
1. Vocabulary (Word + Meaning + Example)
2. Grammar Snippet (Rule + Example)
3. Common Mistake (Wrong vs Right)
4. Motivation (Quote)
5. Idiom (Redewendung)

Format:
[
  {
    "title": "🇩🇪 Günün Kelimesi: der Stern",
    "content": "Yıldız. Die Sterne leuchten heute hell. (Yıldızlar bugün parlak parlıyor.)"
  },
  {
    "title": "⚠️ Dikkat: seit vs. vor",
    "content": "'Seit' geçmişten bugüne devam eden (since), 'vor' bitmiş olaylar (ago) için kullanılır."
  }
]
''';

      final response = await _aiService.generateContent(
        prompt: prompt,
        temperature: 0.8,
        responseFormat: 'application/json',
      );

      // Validate JSON (simple check)
      final List<dynamic> json = response as List<dynamic>;

      // Cache
      await prefs.setString('daily_tips_cache', jsonEncode(json));
      await prefs.setString('tips_generated_date', now.toIso8601String());
      print('✅ Cached ${json.length} daily tips');
    } catch (e) {
      print('❌ Error generating daily tips: $e');
      // Fallback tips could be cached here if needed
    }
  }

  /// Generate weekly summary
  Future<WeeklySummary> generateWeeklySummary() async {
    try {
      final sessions = await _progressService.getStudyHistory(days: 7);
      final previousWeekSessions = await _progressService.getStudyHistory(
        days: 14,
      );

      final thisWeekCount = sessions.length;
      final lastWeekCount = previousWeekSessions.length - thisWeekCount;

      final trend = thisWeekCount > lastWeekCount
          ? 'increasing'
          : thisWeekCount < lastWeekCount
          ? 'decreasing'
          : 'stable';

      final totalQuestions = sessions.fold(
        0,
        (sum, s) => sum + s.questionsAnswered,
      );
      final totalCorrect = sessions.fold(0, (sum, s) => sum + s.correctAnswers);

      final accuracy = totalQuestions > 0
          ? (totalCorrect / totalQuestions) * 100
          : 0;

      return WeeklySummary(
        studySessions: thisWeekCount,
        totalQuestions: totalQuestions,
        accuracy: accuracy.round(),
        trend: trend,
        comparison: thisWeekCount - lastWeekCount,
      );
    } catch (e) {
      print('Error generating weekly summary: $e');
      return WeeklySummary(
        studySessions: 0,
        totalQuestions: 0,
        accuracy: 0,
        trend: 'stable',
        comparison: 0,
      );
    }
  }

  /// Fallback feedback when AI fails
  PersonalizedFeedback _getFallbackFeedback() {
    return PersonalizedFeedback(
      overallAssessment:
          'İlerleme kaydediliyor! Çalışmaya devam et, başarıya yaklaşıyorsun!',
      progressTrend: 'stable',
      trendEmoji: '➡️',
      motivation: 'Her gün biraz daha ilerliyorsun. Harika iş çıkarıyorsun!',
      strengths: ['Düzenli çalışma', 'Kararlılık'],
      weaknesses: ['Daha fazla pratik gerekli'],
      recommendations: [
        Recommendation(
          title: 'Günlük Pratik',
          description: 'Her gün en az 15 dakika çalış',
          priority: 'high',
        ),
      ],
      nextSteps: [
        'Kelime çalışması yap',
        'Gramer konularını tekrar et',
        'Test çöz',
      ],
      studyPlan: StudyPlan(
        thisWeek: 'Zayıf alanlara odaklan',
        daily: '15 dakika çalışma',
        focus: 'Kelime ve gramer',
      ),
      milestone: Milestone(
        current: 'İlerleme kaydediliyor',
        next: 'B2 seviyesine yaklaş',
        distanceToB2: 'Yolun yarısındasın!',
      ),
    );
  }
}

/// Personalized feedback model
class PersonalizedFeedback {
  final String overallAssessment;
  final String progressTrend; // improving/stable/declining
  final String trendEmoji;
  final String motivation;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<Recommendation> recommendations;
  final List<String> nextSteps;
  final StudyPlan studyPlan;
  final Milestone milestone;

  PersonalizedFeedback({
    required this.overallAssessment,
    required this.progressTrend,
    required this.trendEmoji,
    required this.motivation,
    required this.strengths,
    required this.weaknesses,
    required this.recommendations,
    required this.nextSteps,
    required this.studyPlan,
    required this.milestone,
  });

  factory PersonalizedFeedback.fromJson(Map<String, dynamic> json) {
    return PersonalizedFeedback(
      overallAssessment: json['overallAssessment'] ?? '',
      progressTrend: json['progressTrend'] ?? 'stable',
      trendEmoji: json['trendEmoji'] ?? '➡️',
      motivation: json['motivation'] ?? '',
      strengths: List<String>.from(json['strengths'] ?? []),
      weaknesses: List<String>.from(json['weaknesses'] ?? []),
      recommendations: (json['recommendations'] as List? ?? [])
          .map((r) => Recommendation.fromJson(r))
          .toList(),
      nextSteps: List<String>.from(json['nextSteps'] ?? []),
      studyPlan: StudyPlan.fromJson(json['studyPlan'] ?? {}),
      milestone: Milestone.fromJson(json['milestone'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overallAssessment': overallAssessment,
      'progressTrend': progressTrend,
      'trendEmoji': trendEmoji,
      'motivation': motivation,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'recommendations': recommendations.map((r) => r.toJson()).toList(),
      'nextSteps': nextSteps,
      'studyPlan': studyPlan.toJson(),
      'milestone': milestone.toJson(),
    };
  }
}

class Recommendation {
  final String title;
  final String description;
  final String priority;

  Recommendation({
    required this.title,
    required this.description,
    required this.priority,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'description': description, 'priority': priority};
  }
}

class StudyPlan {
  final String thisWeek;
  final String daily;
  final String focus;

  StudyPlan({required this.thisWeek, required this.daily, required this.focus});

  factory StudyPlan.fromJson(Map<String, dynamic> json) {
    return StudyPlan(
      thisWeek: json['thisWeek'] ?? '',
      daily: json['daily'] ?? '',
      focus: json['focus'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'thisWeek': thisWeek, 'daily': daily, 'focus': focus};
  }
}

class Milestone {
  final String current;
  final String next;
  final String distanceToB2;

  Milestone({
    required this.current,
    required this.next,
    required this.distanceToB2,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      current: json['current'] ?? '',
      next: json['next'] ?? '',
      distanceToB2: json['distanceToB2'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'current': current, 'next': next, 'distanceToB2': distanceToB2};
  }
}

class WeeklySummary {
  final int studySessions;
  final int totalQuestions;
  final int accuracy;
  final String trend; // increasing/stable/decreasing
  final int comparison; // vs last week

  WeeklySummary({
    required this.studySessions,
    required this.totalQuestions,
    required this.accuracy,
    required this.trend,
    required this.comparison,
  });
}

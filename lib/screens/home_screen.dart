import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../services/firestore_service.dart';
import '../services/vocabulary_service.dart';
import '../services/learning_progress_service.dart';
import 'upload_screen.dart';
import 'categories_screen.dart';
import 'create_test_screen.dart';
import 'profile_screen.dart';
import 'my_vocabulary_screen.dart';
import 'flashcard_screen.dart';
import 'german_writing_assistant_screen.dart';
import 'progress_dashboard_screen.dart';
import 'mari_ai_chat_screen.dart';
import '../models/document_analysis_model.dart';

/// Main home screen with bottom navigation and animated upload button
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _documentCount = 0;
  int _categoryCount = 0;
  int _quizCount = 0;
  int _vocabularyCount = 0;
  int _dueWordsCount = 0;
  Map<String, dynamic> _progressStats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final firestoreService = FirestoreService();
      final vocabularyService = VocabularyService('test_user');
      final progressService = LearningProgressService('test_user');

      // Load document count
      final docs = await firestoreService.getAllDocuments();
      final categories = await firestoreService.getCategoryCounts();
      final quizResults = await firestoreService.getQuizResults();
      final vocabStats = await vocabularyService.getStatistics();
      final progressStats = await progressService.getProgressStats();

      if (mounted) {
        setState(() {
          _documentCount = docs.length;
          _categoryCount = categories.values.where((c) => c > 0).length;
          _quizCount = quizResults.length;
          _vocabularyCount = vocabStats['total'] ?? 0;
          _dueWordsCount = vocabStats['dueToday'] ?? 0;
          _progressStats = progressStats;
        });

        // Debug: Print vocabulary stats
        print('📊 Vocabulary Stats:');
        print('   Total words: $_vocabularyCount');
        print('   Due today: $_dueWordsCount');
        print('   New: ${vocabStats['new']}');
        print('   Learning: ${vocabStats['learning']}');
        print('   Learned: ${vocabStats['learned']}');
        print('   Mastered: ${vocabStats['mastered']}');

        // Debug: Print progress stats
        print('📈 Progress Stats:');
        print('   Overall: ${_progressStats['overallProgress']}%');
        print('   Level: ${_progressStats['currentLevel']}');
        print('   To B2: ${_progressStats['progressToB2']}%');
      }
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  // Page titles for each tab
  final List<String> _pageTitles = [
    'Ana Sayfa',
    'Kategoriler',
    '', // Empty for center button
    'Testler',
    'Profil',
  ];

  @override
  Widget build(BuildContext context) {
    // Only show AppBar for Home (0) and Categories (1)
    // Other screens (Upload, Tests, Profile) have their own Scaffolds/AppBars
    final bool showAppBar = _currentIndex == 0 || _currentIndex == 1;

    return Scaffold(
      extendBody: false,
      appBar: showAppBar
          ? AppBar(
              title: _currentIndex == 0
                  ? _buildLogoTitle() // Logo style for home
                  : Text(
                      _pageTitles[_currentIndex],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    // TODO: Show notifications
                  },
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: _buildBody(),
      bottomNavigationBar: _buildCustomBottomNavigationBar(),
    );
  }

  /// Build logo-style title "Deutsch mit Mari"
  Widget _buildLogoTitle() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          AppColors.accentBright,
          Color(0xFF00D9FF), // Cyan
          AppColors.accentBright,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: 'Deutsch ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                fontStyle: FontStyle.italic,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
            TextSpan(
              text: 'mit ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.5,
                color: Colors.white,
              ),
            ),
            TextSpan(
              text: 'Mari',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    Widget content;
    switch (_currentIndex) {
      case 0:
        content = _buildHomePage();
        break;
      case 1:
        content = const CategoriesScreen();
        break;
      case 2:
        content = const UploadScreen();
        break;
      case 3:
        content = const CreateTestScreen();
        break;
      case 4:
        content = const ProfileScreen();
        break;
      default:
        content = _buildHomePage();
    }

    // Add ambient glow at the bottom
    return Stack(
      children: [
        content,
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 150,
          child: IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.bottomGlow),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card with Glow Effect
          Stack(
            children: [
              // Ambient Glow behind the card
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.all(4), // Slightly smaller than card
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: AppColors.ambientGlow,
                  ),
                ),
              ),
              // Main Card Content
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowMedium,
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.accentBright.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Glow behind "Hoş Geldin" text
                    Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment.topLeft,
                                radius: 2.0,
                                colors: [
                                  AppColors.accentBright.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Text(
                          'Hoş Geldin! 👋',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            shadows: [
                              Shadow(
                                color: AppColors.accentBright,
                                blurRadius: 10,
                                offset: Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Bugün Almanca öğrenmeye hazır mısın?',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MariAIChatScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentBright.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.accentBright.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: AppColors.accentBright,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Yapay zeka asistanın hazır!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.accentBright,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: AppColors.accentBright,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Learning Progress Card
          if (_progressStats.isNotEmpty) ...[
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProgressDashboardScreen(),
                  ),
                ).then((_) => _loadStats());
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accentBright.withOpacity(0.1),
                      AppColors.info.withOpacity(0.1),
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
                            Icons.trending_up,
                            color: AppColors.accentBright,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Öğrenme İlerlemen',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Seviye: ${_progressStats['currentLevel'] ?? 'A1'}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Overall progress badge
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
                            '${_progressStats['overallProgress'] ?? 0}%',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.accentBright,
                          size: 16,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Progress to B2
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'B2 Hedefine İlerleme',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '%${_progressStats['progressToB2'] ?? 0}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.accentBright,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (_progressStats['progressToB2'] ?? 0) / 100,
                            minHeight: 8,
                            backgroundColor: AppColors.backgroundCard,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.accentBright,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Weak and Strong Areas
                    Row(
                      children: [
                        // Weak areas
                        if ((_progressStats['weakAreas'] as List?)
                                ?.isNotEmpty ??
                            false)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.trending_down,
                                        size: 16,
                                        color: AppColors.error,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Geliştirilmeli',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ...(_progressStats['weakAreas'] as List)
                                      .take(2)
                                      .map(
                                        (area) => Padding(
                                          padding: const EdgeInsets.only(
                                            top: 2,
                                          ),
                                          child: Text(
                                            '• $area',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                ],
                              ),
                            ),
                          ),

                        if ((_progressStats['weakAreas'] as List?)
                                ?.isNotEmpty ??
                            false)
                          const SizedBox(width: 12),

                        // Strong areas
                        if ((_progressStats['strongAreas'] as List?)
                                ?.isNotEmpty ??
                            false)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 16,
                                        color: AppColors.success,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Güçlü Alanlar',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ...(_progressStats['strongAreas'] as List)
                                      .take(2)
                                      .map(
                                        (area) => Padding(
                                          padding: const EdgeInsets.only(
                                            top: 2,
                                          ),
                                          child: Text(
                                            '• $area',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Quick Stats
          const Text(
            'İstatistikler',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.book_outlined,
                  title: 'Ders Notları',
                  value: '$_documentCount',
                  color: AppColors.accentBright,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.category_outlined,
                  title: 'Kategoriler',
                  value: '$_categoryCount',
                  color: AppColors.info,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.quiz_outlined,
                  title: 'Testler',
                  value: '$_quizCount',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.translate,
                  title: 'Kelimeler',
                  value: '$_vocabularyCount',
                  color: AppColors.warning,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Vocabulary Study Card (always show)
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _vocabularyCount > 0
                            ? Icons.school
                            : Icons.add_circle_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kelime Çalışması',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _vocabularyCount == 0
                                ? 'Henüz kelime yok. Döküman yükle!'
                                : _dueWordsCount > 0
                                ? '$_dueWordsCount kelime seni bekliyor!'
                                : '$_vocabularyCount kelime kaydedildi',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_vocabularyCount > 0) ...[
                  Row(
                    children: [
                      if (_dueWordsCount > 0)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // Show loading
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (c) =>
                                    Center(child: CircularProgressIndicator()),
                              );

                              try {
                                final vocabularyService = VocabularyService(
                                  'test_user',
                                );
                                final dueWords = await vocabularyService
                                    .getDueWords();

                                Navigator.pop(context); // Close loading

                                if (dueWords.isNotEmpty) {
                                  final enhancedVocab = dueWords
                                      .map(
                                        (w) => EnhancedVocabularyItem(
                                          german: w.german,
                                          translation: w.translation,
                                          exampleSentence: w.exampleSentence,
                                          article: w.article,
                                          plural: w.plural,
                                          professionalContext:
                                              w.professionalContext,
                                        ),
                                      )
                                      .toList();

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FlashcardScreen(
                                        vocabulary: enhancedVocab,
                                        title: 'Günlük Tekrar',
                                      ),
                                    ),
                                  ).then((_) => _loadStats());
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Bugün tekrar edilecek kelime yok!',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                Navigator.pop(context); // Close loading
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Hata: $e')),
                                );
                              }
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Çalışmaya Başla'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.accentBright,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      if (_dueWordsCount > 0) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MyVocabularyScreen(),
                              ),
                            ).then((_) => _loadStats());
                          },
                          icon: const Icon(Icons.list),
                          label: Text(
                            _dueWordsCount > 0 ? 'Tümü' : 'Kelimeleri Gör',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _currentIndex = 2); // Go to upload
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Döküman Yükle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.info,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick Actions
          const Text(
            'Hızlı Erişim',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.category,
                  title: 'Kategoriler',
                  onTap: () => setState(() => _currentIndex = 1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.quiz,
                  title: 'Test Oluştur',
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.edit_note,
                  title: 'Yazma Asistanı',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const GermanWritingAssistantScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.book,
                  title: 'Kelimelerim',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyVocabularyScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.textMuted.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.accentBright),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            children: [
              Expanded(
                child: _buildNavItem(0, Icons.home_rounded, 'Ana Sayfa'),
              ),
              Expanded(
                child: _buildNavItem(1, Icons.category_rounded, 'Kategoriler'),
              ),
              // Upload button in the center
              Expanded(child: _buildUploadNavItem()),
              Expanded(child: _buildNavItem(3, Icons.quiz_rounded, 'Testler')),
              Expanded(child: _buildNavItem(4, Icons.person_rounded, 'Profil')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadNavItem() {
    final isSelected = _currentIndex == 2;
    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = 2;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: isSelected ? 1 : 0),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value * 3.14159 * 2, // Full rotation when selected
                  child: Icon(
                    Icons.upload_file_rounded,
                    color: isSelected
                        ? AppColors.accentBright
                        : AppColors.textSecondary,
                    size: 24,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              'Yükle',
              style: TextStyle(
                color: isSelected
                    ? AppColors.accentBright
                    : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.accentBright
                  : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.accentBright
                    : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

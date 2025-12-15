import 'package:flutter/material.dart';
import '../models/document_analysis_model.dart';
import '../models/vocabulary_word.dart';
import '../services/vocabulary_service.dart';
import '../services/category_service.dart';
import '../utils/app_colors.dart';
import 'flashcard_screen.dart';

/// Screen to view and manage all vocabulary words
class MyVocabularyScreen extends StatefulWidget {
  const MyVocabularyScreen({super.key});

  @override
  State<MyVocabularyScreen> createState() => _MyVocabularyScreenState();
}

class _MyVocabularyScreenState extends State<MyVocabularyScreen>
    with SingleTickerProviderStateMixin {
  final VocabularyService _vocabularyService = VocabularyService('test_user');
  final CategoryService _categoryService = CategoryService('test_user');

  List<VocabularyWord> _allWords = [];
  List<VocabularyWord> _filteredWords = [];
  Map<String, int> _categoryCounts = {}; // Category ID -> word count
  Map<String, String> _categoryNames = {}; // Category ID -> category name
  Map<String, int> _levelCounts = {}; // Level -> word count (A1, A2, B1, etc.)
  Map<String, int> _topicCounts = {}; // Topic -> word count
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedLevel; // Selected language level filter
  String? _selectedTopic; // Selected topic filter
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadWords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _filterWords();
    }
  }

  Future<void> _loadWords() async {
    setState(() => _isLoading = true);

    try {
      final words = await _vocabularyService.getAllWords();
      final stats = await _vocabularyService.getStatistics();

      // Calculate category counts
      final Map<String, int> categoryCounts = {};
      final Set<String> categoryIds = {};

      // Calculate level counts
      final Map<String, int> levelCounts = {};

      // Calculate topic counts
      final Map<String, int> topicCounts = {};

      for (final word in words) {
        if (word.sourceCategory != null && word.sourceCategory!.isNotEmpty) {
          categoryCounts[word.sourceCategory!] =
              (categoryCounts[word.sourceCategory!] ?? 0) + 1;
          categoryIds.add(word.sourceCategory!);
        }

        // Count by language level
        if (word.languageLevel.isNotEmpty) {
          levelCounts[word.languageLevel] =
              (levelCounts[word.languageLevel] ?? 0) + 1;
        }

        // Count by topic
        if (word.sourceTopic != null && word.sourceTopic!.isNotEmpty) {
          topicCounts[word.sourceTopic!] =
              (topicCounts[word.sourceTopic!] ?? 0) + 1;
        }
      }

      // Fetch category names
      final Map<String, String> categoryNames = {};
      for (final categoryId in categoryIds) {
        try {
          final category = await _categoryService.getCategory(categoryId);
          if (category != null) {
            categoryNames[categoryId] = category.name;
          }
        } catch (e) {
          print('Error fetching category $categoryId: $e');
          categoryNames[categoryId] = 'Kategori';
        }
      }

      setState(() {
        _allWords = words;
        _stats = stats;
        _categoryCounts = categoryCounts;
        _categoryNames = categoryNames;
        _levelCounts = levelCounts;
        _topicCounts = topicCounts;
        _isLoading = false;
      });

      _filterWords();
    } catch (e) {
      print('Error loading words: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterWords() {
    List<VocabularyWord> filtered = _allWords;

    // Filter by category first
    if (_selectedCategoryId != null) {
      filtered = filtered
          .where((w) => w.sourceCategory == _selectedCategoryId)
          .toList();
    }

    // Filter by language level
    if (_selectedLevel != null) {
      filtered = filtered
          .where((w) => w.languageLevel == _selectedLevel)
          .toList();
    }

    // Filter by topic
    if (_selectedTopic != null) {
      filtered = filtered
          .where((w) => w.sourceTopic == _selectedTopic)
          .toList();
    }

    // Filter by tab (status)
    switch (_tabController.index) {
      case 0: // Tümü
        break;
      case 1: // Yeni
        filtered = filtered
            .where((w) => w.status == LearningStatus.new_word)
            .toList();
        break;
      case 2: // Öğreniliyor
        filtered = filtered
            .where((w) => w.status == LearningStatus.learning)
            .toList();
        break;
      case 3: // Öğrenildi
        filtered = filtered
            .where((w) => w.status == LearningStatus.learned)
            .toList();
        break;
      case 4: // Ustalaşıldı
        filtered = filtered
            .where((w) => w.status == LearningStatus.mastered)
            .toList();
        break;
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((word) {
        return word.german.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            word.translation.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Sort by next review date
    filtered.sort((a, b) => a.nextReviewAt.compareTo(b.nextReviewAt));

    setState(() {
      _filteredWords = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Kelimelerim'),
        backgroundColor: AppColors.backgroundCard,
        actions: [
          IconButton(
            icon: const Icon(Icons.school),
            onPressed: _navigateToFlashcards,
            tooltip: 'Kelime Çalış',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.accentBright,
          labelColor: AppColors.accentBright,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: 'Tümü (${_stats['total'] ?? 0})'),
            Tab(text: 'Yeni (${_stats['new'] ?? 0})'),
            Tab(text: 'Öğreniliyor (${_stats['learning'] ?? 0})'),
            Tab(text: 'Öğrenildi (${_stats['learned'] ?? 0})'),
            Tab(text: 'Ustalaşıldı (${_stats['mastered'] ?? 0})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _filterWords();
              },
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Kelime ara...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textMuted,
                ),
                filled: true,
                fillColor: AppColors.backgroundCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Statistics card
          if (_stats.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: AppColors.backgroundCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Bugün Tekrar',
                        '${_stats['dueToday'] ?? 0}',
                        Icons.today,
                        AppColors.accentBright,
                      ),
                      _buildStatItem(
                        'Başarı',
                        '%${_stats['masteredPercentage'] ?? 0}',
                        Icons.trending_up,
                        AppColors.success,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Category filter chips
          if (_categoryCounts.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // "Tümü" chip
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text('Tümü (${_allWords.length})'),
                      selected: _selectedCategoryId == null,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategoryId = null;
                          _selectedCategoryName = null;
                        });
                        _filterWords();
                      },
                      selectedColor: AppColors.accentBright.withOpacity(0.2),
                      checkmarkColor: AppColors.accentBright,
                      labelStyle: TextStyle(
                        color: _selectedCategoryId == null
                            ? AppColors.accentBright
                            : AppColors.textSecondary,
                        fontWeight: _selectedCategoryId == null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  // Category chips
                  ..._categoryCounts.entries.map((entry) {
                    final categoryId = entry.key;
                    final count = entry.value;
                    // Get category name from map
                    final categoryName =
                        _categoryNames[categoryId] ?? 'Kategori';

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text('$categoryName ($count)'),
                        selected: _selectedCategoryId == categoryId,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategoryId = selected ? categoryId : null;
                            _selectedCategoryName = selected
                                ? categoryName
                                : null;
                          });
                          _filterWords();
                        },
                        selectedColor: AppColors.accentBright.withOpacity(0.2),
                        checkmarkColor: AppColors.accentBright,
                        labelStyle: TextStyle(
                          color: _selectedCategoryId == categoryId
                              ? AppColors.accentBright
                              : AppColors.textSecondary,
                          fontWeight: _selectedCategoryId == categoryId
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

          // Level filter chips (A1, A2, B1, B2, etc.)
          if (_levelCounts.isNotEmpty)
            Container(
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // "Tüm Seviyeler" chip
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Tüm Seviyeler'),
                      selected: _selectedLevel == null,
                      onSelected: (selected) {
                        setState(() => _selectedLevel = null);
                        _filterWords();
                      },
                      selectedColor: AppColors.success.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: _selectedLevel == null
                            ? AppColors.success
                            : AppColors.textSecondary,
                        fontWeight: _selectedLevel == null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  // Level chips (sorted: A1, A2, B1, B2, C1, C2)
                  ...['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
                      .where((level) => _levelCounts.containsKey(level))
                      .map((level) {
                        final count = _levelCounts[level] ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('$level ($count)'),
                            selected: _selectedLevel == level,
                            onSelected: (selected) {
                              setState(
                                () => _selectedLevel = selected ? level : null,
                              );
                              _filterWords();
                            },
                            selectedColor: AppColors.success.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: _selectedLevel == level
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                              fontWeight: _selectedLevel == level
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      }),
                ],
              ),
            ),

          // Topic filter chips (Konular)
          if (_topicCounts.isNotEmpty)
            Container(
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              margin: const EdgeInsets.only(top: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // "Tüm Konular" chip
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Tüm Konular'),
                      selected: _selectedTopic == null,
                      onSelected: (selected) {
                        setState(() => _selectedTopic = null);
                        _filterWords();
                      },
                      selectedColor: const Color(
                        0xFF9C27B0,
                      ).withOpacity(0.2), // Purple tint
                      labelStyle: TextStyle(
                        color: _selectedTopic == null
                            ? const Color(0xFF9C27B0)
                            : AppColors.textSecondary,
                        fontWeight: _selectedTopic == null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  // Topic chips (sorted by count)
                  ...(_topicCounts.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value)))
                      .map((entry) {
                        final topic = entry.key;
                        final count = entry.value;
                        // Shorten topic name if too long
                        final displayTopic = topic.length > 20
                            ? '${topic.substring(0, 18)}...'
                            : topic;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('$displayTopic ($count)'),
                            selected: _selectedTopic == topic,
                            tooltip: topic,
                            onSelected: (selected) {
                              setState(
                                () => _selectedTopic = selected ? topic : null,
                              );
                              _filterWords();
                            },
                            // Custom color for topics (Purple/DeepPurple)
                            selectedColor: const Color(
                              0xFF9C27B0,
                            ).withOpacity(0.2),
                            side: BorderSide(
                              color: _selectedTopic == topic
                                  ? const Color(0xFF9C27B0)
                                  : Colors.grey.withOpacity(0.2),
                            ),
                            labelStyle: TextStyle(
                              color: _selectedTopic == topic
                                  ? const Color(0xFF9C27B0)
                                  : AppColors.textSecondary,
                              fontWeight: _selectedTopic == topic
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      })
                      .toList(),
                ],
              ),
            ),

          // Study button for selected category
          if ((_selectedCategoryId != null || _selectedTopic != null) &&
              _filteredWords.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: () {
                  final enhancedVocab = _filteredWords
                      .map(
                        (w) => EnhancedVocabularyItem(
                          german: w.german,
                          translation: w.translation,
                          exampleSentence: w.exampleSentence,
                          article: w.article,
                          plural: w.plural,
                          professionalContext: w.professionalContext,
                        ),
                      )
                      .toList();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FlashcardScreen(
                        vocabulary: enhancedVocab,
                        title: _selectedCategoryName ?? 'Kelime Çalışması',
                      ),
                    ),
                  ).then((_) => _loadWords());
                },
                icon: const Icon(Icons.school),
                label: Text(
                  '$_selectedCategoryName Çalış (${_filteredWords.length} kelime)',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBright,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Word list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredWords.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadWords,
                    color: AppColors.accentBright,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredWords.length,
                      itemBuilder: (context, index) {
                        return _buildWordCard(_filteredWords[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: _stats['dueToday'] != null && _stats['dueToday'] > 0
          ? FloatingActionButton.extended(
              onPressed: _navigateToFlashcards,
              backgroundColor: AppColors.accentBright,
              icon: const Icon(Icons.school),
              label: Text('${_stats['dueToday']} Kelime Çalış'),
            )
          : null,
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 80,
            color: AppColors.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Henüz kelime yok',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Döküman yükleyerek kelime ekleyin',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildWordCard(VocabularyWord word) {
    final isDue = word.nextReviewAt.isBefore(DateTime.now());
    final isLearned =
        word.status == LearningStatus.learned ||
        word.status == LearningStatus.mastered;

    return Dismissible(
      key: Key(word.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Öğrendim',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.warning,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Tekrar Çalış',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.refresh, color: Colors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Sağa kaydır: Öğrendim
          await _markAsLearned(word);
        } else {
          // Sola kaydır: Tekrar çalış
          await _markForReview(word);
        }
        return false; // Kartı silme, sadece durumu güncelle
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isDue
              ? const BorderSide(color: AppColors.accentBright, width: 2)
              : BorderSide.none,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getStatusColor(word.status).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                word.article.isNotEmpty ? word.article : '📚',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(word.status),
                ),
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  word.german,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (isDue)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentBright.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'TEKRAR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentBright,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                word.translation,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              if (word.plural.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Çoğul: ${word.plural}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted.withOpacity(0.7),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(word.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getStatusText(word.status),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(word.status),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${word.reviewCount} tekrar',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const Spacer(),
                  // Öğrendim / Tekrar Çalış butonları
                  if (!isLearned)
                    IconButton(
                      icon: const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.success,
                      ),
                      tooltip: 'Öğrendim',
                      onPressed: () => _markAsLearned(word),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppColors.warning),
                      tooltip: 'Tekrar Çalış',
                      onPressed: () => _markForReview(word),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                ],
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _confirmDelete(word),
          ),
          onTap: () => _showWordDetails(word),
        ),
      ),
    );
  }

  Future<void> _markAsLearned(VocabularyWord word) async {
    try {
      final updatedWord = word.copyWith(
        status: LearningStatus.learned,
        lastReviewedAt: DateTime.now(),
        nextReviewAt: DateTime.now().add(
          const Duration(days: 7),
        ), // 1 hafta sonra tekrar
      );
      await _vocabularyService.updateWord(updatedWord);
      _loadWords();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ "${word.german}" öğrenildi olarak işaretlendi'),
            backgroundColor: AppColors.success,
            action: SnackBarAction(
              label: 'Geri Al',
              textColor: Colors.white,
              onPressed: () async {
                await _vocabularyService.updateWord(word);
                _loadWords();
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error marking as learned: $e');
    }
  }

  Future<void> _markForReview(VocabularyWord word) async {
    try {
      final updatedWord = word.copyWith(
        status: LearningStatus.learning,
        nextReviewAt: DateTime.now(), // Hemen tekrar için uygun
      );
      await _vocabularyService.updateWord(updatedWord);
      _loadWords();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔄 "${word.german}" tekrar listesine eklendi'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      print('Error marking for review: $e');
    }
  }

  void _showWordDetails(VocabularyWord word) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Row(
          children: [
            if (word.article.isNotEmpty)
              Text(
                '${word.article} ',
                style: const TextStyle(color: AppColors.accentBright),
              ),
            Expanded(
              child: Text(
                word.german,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Çeviri', word.translation),
              if (word.plural.isNotEmpty) _buildDetailRow('Çoğul', word.plural),
              if (word.exampleSentence.isNotEmpty)
                _buildDetailRow('Örnek', word.exampleSentence),
              if (word.professionalContext.isNotEmpty)
                _buildDetailRow('Bağlam', word.professionalContext),
              _buildDetailRow('Seviye', word.languageLevel),
              _buildDetailRow('Durum', _getStatusText(word.status)),
              _buildDetailRow('Tekrar Sayısı', '${word.reviewCount}'),
              _buildDetailRow('Sonraki Tekrar', _formatDate(word.nextReviewAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(VocabularyWord word) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Kelimeyi Sil',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          '"${word.german}" kelimesini silmek istediğinize emin misiniz?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _vocabularyService.deleteWord(word.id);
              _loadWords();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kelime silindi'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Sil', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _navigateToFlashcards() {
    final enhancedVocab = _filteredWords
        .map(
          (w) => EnhancedVocabularyItem(
            german: w.german,
            translation: w.translation,
            exampleSentence: w.exampleSentence,
            article: w.article,
            plural: w.plural,
            professionalContext: w.professionalContext,
          ),
        )
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardScreen(
          vocabulary: enhancedVocab,
          title: _selectedCategoryName ?? 'Kelime Çalışması',
        ),
      ),
    ).then((_) => _loadWords());
  }

  Color _getStatusColor(LearningStatus status) {
    switch (status) {
      case LearningStatus.new_word:
        return AppColors.info;
      case LearningStatus.learning:
        return AppColors.warning;
      case LearningStatus.learned:
        return AppColors.accentBright;
      case LearningStatus.mastered:
        return AppColors.success;
    }
  }

  String _getStatusText(LearningStatus status) {
    switch (status) {
      case LearningStatus.new_word:
        return 'Yeni';
      case LearningStatus.learning:
        return 'Öğreniliyor';
      case LearningStatus.learned:
        return 'Öğrenildi';
      case LearningStatus.mastered:
        return 'Ustalaşıldı';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.isNegative) {
      return 'Şimdi';
    } else if (diff.inDays == 0) {
      return 'Bugün';
    } else if (diff.inDays == 1) {
      return 'Yarın';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} gün sonra';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

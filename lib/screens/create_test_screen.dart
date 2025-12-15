import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../services/gemini_ai_service.dart';
import '../services/firestore_service.dart';
import '../models/quiz_model.dart';
import '../models/study_document.dart';
import 'take_test_screen.dart';
import 'test_history_screen.dart';

class CreateTestScreen extends StatefulWidget {
  const CreateTestScreen({super.key});

  @override
  State<CreateTestScreen> createState() => _CreateTestScreenState();
}

class _CreateTestScreenState extends State<CreateTestScreen> {
  final GeminiAIService _aiService = GeminiAIService();
  final FirestoreService _firestoreService = FirestoreService();

  String _selectedCategory = 'Genel';
  String _selectedLevel = 'A1';
  bool _isLoading = false;
  bool _useMyMaterials = false;
  List<StudyDocument> _userDocuments = [];
  final Set<String> _selectedDocumentIds = {};

  final List<String> _levels = ['A1', 'A2', 'B1', 'B2', 'C1'];
  final List<StudyCategory> _categories = StudyCategory.getDefaultCategories();

  @override
  void initState() {
    super.initState();
    _fetchUserDocuments();
  }

  Future<void> _fetchUserDocuments() async {
    final docs = await _firestoreService.getAllDocuments();
    if (mounted) {
      setState(() {
        _userDocuments = docs;
        // Default select all if few, or none
        if (docs.length <= 5) {
          _selectedDocumentIds.addAll(docs.map((d) => d.id));
        }
      });
    }
  }

  Future<void> _createTest() async {
    setState(() => _isLoading = true);

    try {
      Quiz quiz;
      if (_useMyMaterials && _selectedDocumentIds.isNotEmpty) {
        // Get selected documents text
        final selectedDocs = _userDocuments
            .where((doc) => _selectedDocumentIds.contains(doc.id))
            .toList();

        final sourceTexts = selectedDocs
            .map((doc) => "Title: ${doc.title}\nContent: ${doc.extractedText}")
            .toList();

        quiz = await _aiService.generateQuizFromContext(
          sourceTexts: sourceTexts,
          level: _selectedLevel,
        );
      } else {
        quiz = await _aiService.generateQuiz(
          topic: _selectedCategory,
          level: _selectedLevel,
        );
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TakeTestScreen(quiz: quiz)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test oluşturulurken hata: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          title: const Text('Testler'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: AppColors.accentBright,
            labelColor: AppColors.accentBright,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'Yeni Test'),
              Tab(text: 'Geçmiş'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Create Test
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Kendini Dene!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hangi konuda pratik yapmak istersin?',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Source Selection Toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryMedium),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildToggleButton(
                            title: 'Genel Pratik',
                            isSelected: !_useMyMaterials,
                            onTap: () =>
                                setState(() => _useMyMaterials = false),
                          ),
                        ),
                        Expanded(
                          child: _buildToggleButton(
                            title: 'Materyallerim',
                            isSelected: _useMyMaterials,
                            onTap: () => setState(() => _useMyMaterials = true),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_useMyMaterials)
                    _buildMyMaterialsSelection()
                  else
                    _buildCategorySelection(),

                  const SizedBox(height: 32),

                  // Level Selection
                  const Text(
                    'Zorluk Seviyesi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentBright,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _levels.map((level) {
                      final isSelected = _selectedLevel == level;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedLevel = level),
                        child: Container(
                          width: 50,
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accentBright
                                : AppColors.backgroundCard,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accentBright
                                  : AppColors.textMuted.withValues(alpha: 0.3),
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.accentBright.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            level,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? AppColors.primaryDark
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 48),

                  // Create Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          _isLoading ||
                              (_useMyMaterials && _selectedDocumentIds.isEmpty)
                          ? null
                          : _createTest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentBright,
                        foregroundColor: AppColors.primaryDark,
                        disabledBackgroundColor: AppColors.backgroundCard,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: AppColors.primaryDark,
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.auto_awesome),
                                const SizedBox(width: 12),
                                Text(
                                  _useMyMaterials
                                      ? 'Kişisel Sınavı Oluştur'
                                      : 'Sınavı Oluştur',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  if (_useMyMaterials && _selectedDocumentIds.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Lütfen en az bir döküman seçin.',
                        style: TextStyle(color: AppColors.error, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),

            // Tab 2: Test History
            const TestHistoryScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryMedium : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Konu Seçimi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.accentBright,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.accentBright.withValues(alpha: 0.3),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              dropdownColor: AppColors.backgroundCard,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.accentBright,
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category.name,
                  child: Row(
                    children: [
                      Icon(
                        _getIconData(category.iconName),
                        color: Color(
                          int.parse(
                            category.colorHex.replaceFirst('#', '0xFF'),
                          ),
                        ),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(category.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedCategory = value);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyMaterialsSelection() {
    if (_userDocuments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Henüz yüklenmiş dökümanınız yok. Lütfen önce ders notu yükleyin.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Döküman Seçimi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.accentBright,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    color: AppColors.accentBright,
                  ),
                  onPressed: _fetchUserDocuments,
                  tooltip: 'Yenile',
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedDocumentIds.length ==
                          _userDocuments.length) {
                        _selectedDocumentIds.clear();
                      } else {
                        _selectedDocumentIds.addAll(
                          _userDocuments.map((d) => d.id),
                        );
                      }
                    });
                  },
                  child: Text(
                    _selectedDocumentIds.length == _userDocuments.length
                        ? 'Temizle'
                        : 'Tümünü Seç',
                    style: const TextStyle(color: AppColors.accentBright),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryMedium),
          ),
          child: ListView.builder(
            itemCount: _userDocuments.length,
            itemBuilder: (context, index) {
              final doc = _userDocuments[index];
              final isSelected = _selectedDocumentIds.contains(doc.id);
              return CheckboxListTile(
                value: isSelected,
                activeColor: AppColors.accentBright,
                checkColor: AppColors.primaryDark,
                title: Text(
                  doc.title,
                  style: const TextStyle(color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  doc.primaryCategory,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                secondary: Icon(
                  doc.fileType == 'pdf' ? Icons.picture_as_pdf : Icons.image,
                  color: AppColors.textMuted,
                ),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedDocumentIds.add(doc.id);
                    } else {
                      _selectedDocumentIds.remove(doc.id);
                    }
                  });
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_selectedDocumentIds.length} döküman seçildi',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'history':
        return Icons.history;
      case 'arrow_forward':
        return Icons.arrow_forward;
      case 'arrow_downward':
        return Icons.arrow_downward;
      case 'access_time':
        return Icons.access_time;
      case 'psychology':
        return Icons.psychology;
      case 'work':
        return Icons.work;
      case 'restaurant':
        return Icons.restaurant;
      case 'flight':
        return Icons.flight;
      case 'family':
        return Icons.family_restroom;
      case 'home':
        return Icons.home;
      case 'favorite':
        return Icons.favorite;
      case 'sports':
        return Icons.sports_soccer;
      case 'book':
        return Icons.book;
      case 'schedule':
        return Icons.schedule;
      case 'done_all':
        return Icons.done_all;
      case 'build':
        return Icons.build;
      case 'style':
        return Icons.style;
      case 'place':
        return Icons.place;
      case 'wb_sunny':
        return Icons.wb_sunny;
      default:
        return Icons.folder;
    }
  }
}

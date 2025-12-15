import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/category_model.dart';
import '../models/document_analysis_model.dart';
import '../services/category_service.dart';

/// Dialog for selecting or creating document category
class CategorySelectionDialog extends StatefulWidget {
  final SimpleCategorySuggestion? aiSuggestion;

  const CategorySelectionDialog({super.key, this.aiSuggestion});

  @override
  State<CategorySelectionDialog> createState() =>
      _CategorySelectionDialogState();
}

class _CategorySelectionDialogState extends State<CategorySelectionDialog> {
  late CategoryService _categoryService;
  List<Category> _mainCategories = [];
  List<Category> _subCategories = [];
  Category? _selectedMainCategory;
  Category? _selectedSubCategory;
  bool _isLoading = true;
  bool _isCreatingNew = false;
  final _newCategoryController = TextEditingController();
  final _newSubCategoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    const userId = 'test_user'; // TODO: Get from auth
    _categoryService = CategoryService(userId);
    _loadCategories();
  }

  @override
  void dispose() {
    _newCategoryController.dispose();
    _newSubCategoryController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _categoryService.getMainCategories();
      setState(() {
        _mainCategories = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSubCategories(String parentId) async {
    try {
      final subs = await _categoryService.getSubcategories(parentId);
      setState(() {
        _subCategories = subs;
      });
    } catch (e) {
      print('Error loading subcategories: $e');
    }
  }

  Future<void> _createMainCategory() async {
    print('_createMainCategory called');
    print('Category name: ${_newCategoryController.text}');

    if (_newCategoryController.text.trim().isEmpty) {
      print('Category name is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen kategori adı girin')),
      );
      return;
    }

    print(
      'Attempting to create category: ${_newCategoryController.text.trim()}',
    );
    try {
      final categoryId = await _categoryService.createCategory(
        name: _newCategoryController.text.trim(),
      );

      if (categoryId != null) {
        await _loadCategories();
        _newCategoryController.clear();
        setState(() => _isCreatingNew = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${_newCategoryController.text.trim()} kategorisi oluşturuldu!',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kategori oluşturulamadı'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      print('Error creating category: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _createSubCategory() async {
    if (_newSubCategoryController.text.trim().isEmpty ||
        _selectedMainCategory == null) {
      return;
    }

    try {
      final categoryId = await _categoryService.createCategory(
        name: _newSubCategoryController.text.trim(),
        parentId: _selectedMainCategory!.id,
      );

      if (categoryId != null) {
        await _loadSubCategories(_selectedMainCategory!.id);

        // Auto-select the newly created subcategory
        final newCategory = _subCategories.firstWhere(
          (cat) => cat.id == categoryId,
          orElse: () => Category(
            id: categoryId,
            name: _newSubCategoryController.text.trim(),
            level: 1,
            createdAt: DateTime.now(),
          ),
        );

        setState(() {
          _selectedSubCategory = newCategory;
        });

        _newSubCategoryController.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${newCategory.name} alt kategorisi oluşturuldu ve seçildi!',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      print('Error creating subcategory: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.backgroundDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(
                    Icons.folder_outlined,
                    color: AppColors.accentBright,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Kategori Seç',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              // AI Suggestion
              if (widget.aiSuggestion != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accentBright.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accentBright.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: AppColors.accentBright,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'AI Önerisi',
                            style: TextStyle(
                              color: AppColors.accentBright,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.aiSuggestion!.mainCategory} > ${widget.aiSuggestion!.subCategory}',
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      if (widget.aiSuggestion!.reason.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.aiSuggestion!.reason,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Main Category Selection
              const Text(
                'Ana Kategori',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_mainCategories.isEmpty)
                _buildEmptyState()
              else
                _buildMainCategoryList(),

              // Create New Main Category Button
              const SizedBox(height: 12),
              if (!_isCreatingNew)
                OutlinedButton.icon(
                  onPressed: () => setState(() => _isCreatingNew = true),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Yeni Ana Kategori'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentBright,
                    side: const BorderSide(color: AppColors.accentBright),
                  ),
                )
              else
                _buildNewCategoryInput(),

              // AI Suggested Subcategory (auto-selected)
              if (_selectedMainCategory != null &&
                  widget.aiSuggestion != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accentBright.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accentBright.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: AppColors.accentBright,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AI Alt Kategori Önerisi',
                              style: TextStyle(
                                color: AppColors.accentBright,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.aiSuggestion!.subCategory,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _selectedMainCategory != null
                        ? () async {
                            // Auto-create subcategory from AI suggestion if doesn't exist
                            if (widget.aiSuggestion != null) {
                              final subCategoryId =
                                  await _createOrGetSubCategory(
                                    widget.aiSuggestion!.subCategory,
                                  );
                              if (mounted) {
                                Navigator.pop(context, subCategoryId);
                              }
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBright,
                      foregroundColor: AppColors.textPrimary,
                    ),
                    child: const Text('Seç'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'Henüz kategori yok.\nYeni kategori oluşturun.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildMainCategoryList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 150),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _mainCategories.length,
        itemBuilder: (context, index) {
          final category = _mainCategories[index];
          final isSelected = _selectedMainCategory?.id == category.id;

          return ListTile(
            title: Text(
              category.name,
              style: TextStyle(
                color: isSelected
                    ? AppColors.accentBright
                    : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: Text(
              '${category.documentCount} döküman',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            selected: isSelected,
            selectedTileColor: AppColors.accentBright.withOpacity(0.1),
            onTap: () {
              setState(() {
                _selectedMainCategory = category;
                _selectedSubCategory = null;
                _subCategories = [];
              });
              _loadSubCategories(category.id);
            },
          );
        },
      ),
    );
  }

  Widget _buildSubCategoryList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 150),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: _subCategories.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Alt kategori yok. Yeni oluşturun.',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              itemCount: _subCategories.length,
              itemBuilder: (context, index) {
                final category = _subCategories[index];
                final isSelected = _selectedSubCategory?.id == category.id;

                return ListTile(
                  title: Text(
                    category.name,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.accentBright
                          : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: Text(
                    '${category.documentCount} döküman',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: AppColors.accentBright.withOpacity(0.1),
                  onTap: () {
                    setState(() {
                      _selectedSubCategory = category;
                    });
                  },
                );
              },
            ),
    );
  }

  Widget _buildNewCategoryInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _newCategoryController,
            decoration: const InputDecoration(
              hintText: 'Yeni kategori adı',
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _createMainCategory,
          icon: const Icon(Icons.check, color: AppColors.success),
        ),
        IconButton(
          onPressed: () {
            _newCategoryController.clear();
            setState(() => _isCreatingNew = false);
          },
          icon: const Icon(Icons.close, color: AppColors.error),
        ),
      ],
    );
  }

  Widget _buildNewSubCategoryInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _newSubCategoryController,
            decoration: const InputDecoration(
              hintText: 'Yeni alt kategori adı',
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _createSubCategory,
          icon: const Icon(Icons.add, color: AppColors.accentBright),
        ),
      ],
    );
  }

  /// Create subcategory if doesn't exist, or return existing one
  Future<String?> _createOrGetSubCategory(String subCategoryName) async {
    if (_selectedMainCategory == null) return null;

    try {
      // Check if subcategory already exists
      final existingSubs = await _categoryService.getSubcategories(
        _selectedMainCategory!.id,
      );
      final existing = existingSubs
          .where((cat) => cat.name == subCategoryName)
          .firstOrNull;

      if (existing != null) {
        print('Subcategory already exists: ${existing.id}');
        return existing.id;
      }

      // Create new subcategory
      print('Creating new subcategory: $subCategoryName');
      final categoryId = await _categoryService.createCategory(
        name: subCategoryName,
        parentId: _selectedMainCategory!.id,
      );

      return categoryId;
    } catch (e) {
      print('Error in _createOrGetSubCategory: $e');
      return null;
    }
  }
}

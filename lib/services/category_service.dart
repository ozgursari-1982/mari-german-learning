import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

/// Service for managing document categories
class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId;

  CategoryService(this._userId);

  /// Get all categories for the user
  Future<List<Category>> getAllCategories() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('categories')
          .get();

      final categories = snapshot.docs
          .map((doc) => Category.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      // Sort in memory
      categories.sort((a, b) {
        final levelCompare = a.level.compareTo(b.level);
        if (levelCompare != 0) return levelCompare;
        return a.name.compareTo(b.name);
      });

      return categories;
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  /// Get main categories only (level 0)
  Future<List<Category>> getMainCategories() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('categories')
          .where('level', isEqualTo: 0)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => Category.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting main categories: $e');
      return [];
    }
  }

  /// Get subcategories of a parent category
  Future<List<Category>> getSubcategories(String parentId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('categories')
          .where('parentId', isEqualTo: parentId)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => Category.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting subcategories: $e');
      return [];
    }
  }

  /// Create a new category
  Future<String?> createCategory({
    required String name,
    String? parentId,
  }) async {
    try {
      print('Creating category: $name for user: $_userId');

      // Determine level
      int level = 0;
      if (parentId != null) {
        final parent = await getCategory(parentId);
        if (parent != null) {
          level = parent.level + 1;
        }
      }

      final category = Category(
        id: '', // Firestore will generate
        name: name,
        parentId: parentId,
        level: level,
        createdAt: DateTime.now(),
        documentCount: 0,
      );

      print('Category data: ${category.toMap()}');

      final docRef = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('categories')
          .add(category.toMap());

      print('Category created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating category: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  /// Get a single category by ID
  Future<Category?> getCategory(String categoryId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('categories')
          .doc(categoryId)
          .get();

      if (doc.exists) {
        return Category.fromMap({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error getting category: $e');
      return null;
    }
  }

  /// Update category name
  Future<bool> updateCategoryName(String categoryId, String newName) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('categories')
          .doc(categoryId)
          .update({'name': newName});
      return true;
    } catch (e) {
      print('Error updating category: $e');
      return false;
    }
  }

  /// Delete a category (and optionally its subcategories)
  Future<bool> deleteCategory(
    String categoryId, {
    bool deleteSubcategories = false,
  }) async {
    try {
      if (deleteSubcategories) {
        // Delete all subcategories recursively
        final subcategories = await getSubcategories(categoryId);
        for (final sub in subcategories) {
          await deleteCategory(sub.id, deleteSubcategories: true);
        }
      }

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('categories')
          .doc(categoryId)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting category: $e');
      return false;
    }
  }

  /// Increment document count for a category
  Future<void> incrementDocumentCount(String categoryId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('categories')
          .doc(categoryId)
          .update({'documentCount': FieldValue.increment(1)});
    } catch (e) {
      print('Error incrementing document count: $e');
    }
  }

  /// Decrement document count for a category
  Future<void> decrementDocumentCount(String categoryId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('categories')
          .doc(categoryId)
          .update({'documentCount': FieldValue.increment(-1)});
    } catch (e) {
      print('Error decrementing document count: $e');
    }
  }

  /// Build category tree structure
  Future<List<CategoryTree>> getCategoryTree() async {
    final allCategories = await getAllCategories();
    final mainCategories = allCategories
        .where((c) => c.isMainCategory)
        .toList();

    return mainCategories.map((main) {
      return _buildTree(main, allCategories);
    }).toList();
  }

  CategoryTree _buildTree(Category category, List<Category> allCategories) {
    final children = allCategories
        .where((c) => c.parentId == category.id)
        .map((child) => _buildTree(child, allCategories))
        .toList();

    return CategoryTree(category: category, children: children);
  }

  /// Get full category path
  Future<String> getCategoryPath(String categoryId) async {
    final allCategories = await getAllCategories();
    final category = allCategories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () =>
          Category(id: '', name: '', level: 0, createdAt: DateTime.now()),
    );

    if (category.id.isEmpty) return '';

    final tree = CategoryTree(category: category);
    return tree.getFullPath(allCategories);
  }

  /// Assign document to category
  Future<bool> assignDocumentToCategory({
    required String documentId,
    required String categoryId,
    required bool isManual,
  }) async {
    try {
      final assignment = DocumentCategoryAssignment(
        documentId: documentId,
        categoryId: categoryId,
        assignedAt: DateTime.now(),
        isManual: isManual,
      );

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('documentCategories')
          .doc(documentId)
          .set(assignment.toMap());

      // Increment category document count for this category and all parents
      await _incrementCategoryAndParents(categoryId);

      return true;
    } catch (e) {
      print('Error assigning document to category: $e');
      return false;
    }
  }

  /// Increment document count for category and all its parents
  Future<void> _incrementCategoryAndParents(String categoryId) async {
    try {
      // Increment this category
      await incrementDocumentCount(categoryId);

      // Get category to find parent
      final category = await getCategory(categoryId);
      if (category != null && category.parentId != null) {
        // Recursively increment parent
        await _incrementCategoryAndParents(category.parentId!);
      }
    } catch (e) {
      print('Error incrementing category and parents: $e');
    }
  }

  /// Get category for a document
  Future<String?> getDocumentCategory(String documentId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('documentCategories')
          .doc(documentId)
          .get();

      if (doc.exists) {
        final assignment = DocumentCategoryAssignment.fromMap(doc.data()!);
        return assignment.categoryId;
      }
      return null;
    } catch (e) {
      print('Error getting document category: $e');
      return null;
    }
  }

  /// Get all documents in a category (including subcategories)
  Future<List<String>> getDocumentsInCategory(String categoryId) async {
    try {
      // Get all category IDs (this category + all subcategories recursively)
      final categoryIds = await _getCategoryAndSubcategoryIds(categoryId);

      final documentIds = <String>[];

      // Get documents for each category
      for (final catId in categoryIds) {
        final snapshot = await _firestore
            .collection('users')
            .doc(_userId)
            .collection('documentCategories')
            .where('categoryId', isEqualTo: catId)
            .get();

        documentIds.addAll(
          snapshot.docs.map((doc) => doc.data()['documentId'] as String),
        );
      }

      // Remove duplicates
      return documentIds.toSet().toList();
    } catch (e) {
      print('Error getting documents in category: $e');
      return [];
    }
  }

  /// Get category ID and all subcategory IDs recursively
  Future<List<String>> _getCategoryAndSubcategoryIds(String categoryId) async {
    final ids = [categoryId];

    try {
      final subcategories = await getSubcategories(categoryId);
      for (final sub in subcategories) {
        // Recursively get subcategories
        final subIds = await _getCategoryAndSubcategoryIds(sub.id);
        ids.addAll(subIds);
      }
    } catch (e) {
      print('Error getting subcategory IDs: $e');
    }

    return ids;
  }
}

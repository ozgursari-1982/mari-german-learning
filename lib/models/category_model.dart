/// Flexible category system - users can create unlimited categories and subcategories
class Category {
  final String id;
  final String name;
  final String? parentId; // null ise ana kategori, değer varsa alt kategori
  final int
  level; // 0 = ana kategori, 1 = alt kategori, 2 = alt-alt kategori, vb.
  final DateTime createdAt;
  final int documentCount; // Bu kategorideki döküman sayısı

  Category({
    required this.id,
    required this.name,
    this.parentId,
    required this.level,
    required this.createdAt,
    this.documentCount = 0,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      parentId: map['parentId'],
      level: map['level'] ?? 0,
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      documentCount: map['documentCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parentId': parentId,
      'level': level,
      'createdAt': createdAt.toIso8601String(),
      'documentCount': documentCount,
    };
  }

  bool get isMainCategory => parentId == null;
  bool get isSubCategory => parentId != null;

  Category copyWith({
    String? id,
    String? name,
    String? parentId,
    int? level,
    DateTime? createdAt,
    int? documentCount,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      level: level ?? this.level,
      createdAt: createdAt ?? this.createdAt,
      documentCount: documentCount ?? this.documentCount,
    );
  }
}

/// Category tree structure for hierarchical display
class CategoryTree {
  final Category category;
  final List<CategoryTree> children;

  CategoryTree({required this.category, this.children = const []});

  /// Get full path (e.g., "Wortschatz > İş Kazaları > Güvenlik")
  String getFullPath(List<Category> allCategories) {
    final path = <String>[];
    Category? current = category;

    while (current != null) {
      path.insert(0, current.name);
      if (current.parentId != null) {
        current = allCategories.firstWhere(
          (c) => c.id == current!.parentId,
          orElse: () =>
              Category(id: '', name: '', level: 0, createdAt: DateTime.now()),
        );
        if (current.id.isEmpty) break;
      } else {
        break;
      }
    }

    return path.join(' > ');
  }
}

/// AI's category suggestion based on document content
class CategorySuggestion {
  final String suggestedCategoryId;
  final String suggestedCategoryName;
  final String? suggestedParentId;
  final double confidence; // 0-1
  final String reasoning;
  final List<String> keywords; // AI'nın tespit ettiği anahtar kelimeler

  CategorySuggestion({
    required this.suggestedCategoryId,
    required this.suggestedCategoryName,
    this.suggestedParentId,
    required this.confidence,
    required this.reasoning,
    required this.keywords,
  });

  factory CategorySuggestion.fromJson(Map<String, dynamic> json) {
    return CategorySuggestion(
      suggestedCategoryId: json['categoryId'] ?? '',
      suggestedCategoryName: json['categoryName'] ?? '',
      suggestedParentId: json['parentId'],
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      reasoning: json['reasoning'] ?? '',
      keywords: List<String>.from(json['keywords'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': suggestedCategoryId,
      'categoryName': suggestedCategoryName,
      'parentId': suggestedParentId,
      'confidence': confidence,
      'reasoning': reasoning,
      'keywords': keywords,
    };
  }
}

/// Document's category assignment
class DocumentCategoryAssignment {
  final String documentId;
  final String categoryId;
  final DateTime assignedAt;
  final bool isManual; // true = kullanıcı seçti, false = AI önerdi

  DocumentCategoryAssignment({
    required this.documentId,
    required this.categoryId,
    required this.assignedAt,
    required this.isManual,
  });

  factory DocumentCategoryAssignment.fromMap(Map<String, dynamic> map) {
    return DocumentCategoryAssignment(
      documentId: map['documentId'] ?? '',
      categoryId: map['categoryId'] ?? '',
      assignedAt: DateTime.parse(
        map['assignedAt'] ?? DateTime.now().toIso8601String(),
      ),
      isManual: map['isManual'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'categoryId': categoryId,
      'assignedAt': assignedAt.toIso8601String(),
      'isManual': isManual,
    };
  }
}

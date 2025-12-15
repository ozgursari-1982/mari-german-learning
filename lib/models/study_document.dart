import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for a study document uploaded by the user
class StudyDocument {
  final String id;
  final String userId;
  final String title;
  final String fileUrl;
  final String fileType; // 'image' or 'pdf'
  final DateTime uploadedAt;

  // Document Classification
  final String documentType; // 'grammar' or 'topic'

  // AI Analysis Results
  final String extractedText;
  final List<String> mainTopics;
  final List<String> grammarStructures;
  final String vocabularyLevel; // A1, A2, B1, B2, C1
  final int difficultyRating; // 1-10
  final String learningFocus;
  final String recommendations;

  // Categorization
  final String primaryCategory; // Main category (e.g., "Beruf")
  final String subCategory; // Specific topic (e.g., "İş Kazası", "Mülakat")
  final List<String> tags; // Additional tags

  // New Hierarchical Categorization
  final String? levelId; // e.g., 'b2'
  final String? themeId; // e.g., 'b2_1'
  final String? topic; // e.g., 'Berufliche Einstiege'
  final String? contentType; // e.g., 'theory' - AI's detection
  final String? userSelectedType; // User's manual selection - takes priority!

  // Full Enhanced Analysis Data
  final Map<String, dynamic> analysisData;

  StudyDocument({
    required this.id,
    required this.userId,
    required this.title,
    required this.fileUrl,
    required this.fileType,
    required this.uploadedAt,
    required this.documentType,
    required this.extractedText,
    required this.mainTopics,
    required this.grammarStructures,
    required this.vocabularyLevel,
    required this.difficultyRating,
    required this.learningFocus,
    required this.recommendations,
    required this.primaryCategory,
    required this.subCategory,
    required this.tags,
    this.levelId,
    this.themeId,
    this.topic,
    this.contentType,
    this.userSelectedType,
    this.analysisData = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'documentType': documentType,
      'extractedText': extractedText,
      'mainTopics': mainTopics,
      'grammarStructures': grammarStructures,
      'vocabularyLevel': vocabularyLevel,
      'difficultyRating': difficultyRating,
      'learningFocus': learningFocus,
      'recommendations': recommendations,
      'primaryCategory': primaryCategory,
      'subCategory': subCategory,
      'tags': tags,
      'levelId': levelId,
      'themeId': themeId,
      'topic': topic,
      'contentType': contentType,
      'userSelectedType': userSelectedType,
      'analysisData': analysisData,
    };
  }

  factory StudyDocument.fromMap(Map<String, dynamic> map) {
    return StudyDocument(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileType: map['fileType'] ?? 'image',
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
      documentType: map['documentType'] ?? 'topic',
      extractedText: map['extractedText'] ?? '',
      mainTopics: List<String>.from(map['mainTopics'] ?? []),
      grammarStructures: List<String>.from(map['grammarStructures'] ?? []),
      vocabularyLevel: map['vocabularyLevel'] ?? 'A1',
      difficultyRating: map['difficultyRating'] ?? 1,
      learningFocus: map['learningFocus'] ?? '',
      recommendations: map['recommendations'] ?? '',
      primaryCategory: map['primaryCategory'] ?? 'Genel',
      subCategory: map['subCategory'] ?? 'Genel',
      tags: List<String>.from(map['tags'] ?? []),
      levelId: map['levelId'],
      themeId: map['themeId'],
      topic: map['topic'],
      contentType: map['contentType'],
      userSelectedType: map['userSelectedType'],
      analysisData: Map<String, dynamic>.from(map['analysisData'] ?? {}),
    );
  }
}

/// Category model for grouping documents
class StudyCategory {
  final String name;
  final String description;
  final int documentCount;
  final String iconName;
  final String colorHex;

  StudyCategory({
    required this.name,
    required this.description,
    required this.documentCount,
    required this.iconName,
    required this.colorHex,
  });

  static List<StudyCategory> getDefaultCategories() {
    return [
      // --- GRAMMAR CATEGORIES ---
      StudyCategory(
        name: 'Präsens',
        description: 'Şimdiki Zaman',
        documentCount: 0,
        iconName: 'schedule',
        colorHex: '#FFC107', // Amber
      ),
      StudyCategory(
        name: 'Präteritum',
        description: 'Di\'li Geçmiş Zaman',
        documentCount: 0,
        iconName: 'history',
        colorHex: '#FF9800', // Orange
      ),
      StudyCategory(
        name: 'Perfekt',
        description: 'Geçmiş Zaman (Konuşma)',
        documentCount: 0,
        iconName: 'done_all',
        colorHex: '#4CAF50', // Green
      ),
      StudyCategory(
        name: 'Passiv',
        description: 'Edilgen Çatı',
        documentCount: 0,
        iconName: 'build',
        colorHex: '#607D8B', // Blue Grey
      ),
      StudyCategory(
        name: 'Akkusativ',
        description: 'İsmin -i Hali',
        documentCount: 0,
        iconName: 'arrow_forward',
        colorHex: '#2196F3', // Blue
      ),
      StudyCategory(
        name: 'Dativ',
        description: 'İsmin -e Hali',
        documentCount: 0,
        iconName: 'arrow_downward',
        colorHex: '#3F51B5', // Indigo
      ),
      StudyCategory(
        name: 'Adjektive',
        description: 'Sıfatlar ve Çekimleri',
        documentCount: 0,
        iconName: 'style',
        colorHex: '#9C27B0', // Purple
      ),
      StudyCategory(
        name: 'Präpositionen',
        description: 'Edatlar (in, an, auf...)',
        documentCount: 0,
        iconName: 'place',
        colorHex: '#E91E63', // Pink
      ),

      // --- TOPIC CATEGORIES ---
      StudyCategory(
        name: 'Beruf',
        description: 'İş ve Meslekler',
        documentCount: 0,
        iconName: 'work',
        colorHex: '#795548', // Brown
      ),
      StudyCategory(
        name: 'Essen',
        description: 'Yemek ve Mutfak',
        documentCount: 0,
        iconName: 'restaurant',
        colorHex: '#F44336', // Red
      ),
      StudyCategory(
        name: 'Reisen',
        description: 'Seyahat ve Tatil',
        documentCount: 0,
        iconName: 'flight',
        colorHex: '#03A9F4', // Light Blue
      ),
      StudyCategory(
        name: 'Gesundheit',
        description: 'Sağlık ve Vücut',
        documentCount: 0,
        iconName: 'favorite',
        colorHex: '#E53935', // Red
      ),
      StudyCategory(
        name: 'Wohnen',
        description: 'Ev ve Yaşam',
        documentCount: 0,
        iconName: 'home',
        colorHex: '#009688', // Teal
      ),
      StudyCategory(
        name: 'Alltag',
        description: 'Günlük Yaşam',
        documentCount: 0,
        iconName: 'wb_sunny',
        colorHex: '#FF5722', // Deep Orange
      ),
      StudyCategory(
        name: 'Genel',
        description: 'Diğer Konular',
        documentCount: 0,
        iconName: 'folder',
        colorHex: '#9E9E9E', // Grey
      ),
    ];
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../services/file_upload_service.dart';
import '../services/gemini_ai_service.dart';
import '../services/firestore_service.dart';
import '../services/vocabulary_service.dart';
import '../models/course_structure.dart';
import '../data/course_data.dart';
import '../models/document_analysis_model.dart' hide DocumentType;
import 'enhanced_analysis_result_screen.dart';

/// Screen for uploading and previewing files
class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final FileUploadService _uploadService = FileUploadService();
  final GeminiAIService _aiService = GeminiAIService();
  final FirestoreService _firestoreService = FirestoreService();

  File? _selectedFile;
  String? _fileType; // 'image' or 'pdf'
  bool _isUploading = false;
  bool _isAnalyzing = false;
  double _uploadProgress = 0.0;
  String? _uploadedUrl;
  StudyMaterialAnalysis? _analysis;

  // Category Selection State
  String? _selectedLevelId;
  String? _selectedThemeId;
  String? _selectedTopic;
  DocumentType? _selectedContentType;

  List<CourseTheme> get _availableThemes {
    if (_selectedLevelId == null) return [];
    return courseThemes[_selectedLevelId] ?? [];
  }

  List<String> get _availableTopics {
    if (_selectedThemeId == null) return [];
    final theme = _availableThemes.firstWhere(
      (t) => t.id == _selectedThemeId,
      orElse: () => _availableThemes.first,
    );
    return theme.topics;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: _selectedFile == null
            ? _buildEmptyState()
            : _buildPreviewState(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentBright.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.cloud_upload_outlined,
                size: 60,
                color: AppColors.accentBright,
              ),
            ),

            const SizedBox(height: 32),

            // Title
            const Text(
              'Dosya Yükle',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              'Ders notlarını, kitap sayfalarını veya PDF dosyalarını yükle',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),

            // Upload Options
            _buildUploadOption(
              icon: Icons.photo_library_outlined,
              title: 'Galeriden Seç',
              description: 'Kitap sayfası veya not fotoğrafı',
              color: AppColors.accentBright,
              onTap: _pickFromGallery,
            ),

            const SizedBox(height: 16),

            _buildUploadOption(
              icon: Icons.camera_alt_outlined,
              title: 'Fotoğraf Çek',
              description: 'Kamera ile çek',
              color: AppColors.info,
              onTap: _takePhoto,
            ),

            const SizedBox(height: 16),

            _buildUploadOption(
              icon: Icons.picture_as_pdf_outlined,
              title: 'PDF Yükle',
              description: 'Ders notları veya kitap',
              color: AppColors.warning,
              onTap: _pickPDF,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewState() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textPrimary),
                onPressed: _isUploading ? null : _clearSelection,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fileType == 'image' ? 'Resim Önizleme' : 'PDF Seçildi',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (_selectedFile != null)
                      Text(
                        '${_uploadService.getFileSizeInMB(_selectedFile!).toStringAsFixed(2)} MB',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Preview
        Expanded(
          child: _fileType == 'image'
              ? _buildImagePreview()
              : _buildPDFPreview(),
        ),

        // Upload Progress
        if (_isUploading)
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.backgroundCard,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Yükleniyor...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${(_uploadProgress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentBright,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: AppColors.primaryMedium,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.accentBright,
                  ),
                ),
              ],
            ),
          ),

        // AI Analysis Progress
        if (_isAnalyzing)
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.backgroundCard,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.accentBright,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'AI Analiz Ediyor...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.psychology,
                      color: AppColors.accentBright,
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Metin çıkarılıyor, konular belirleniyor...',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  backgroundColor: AppColors.primaryMedium,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.accentBright,
                  ),
                ),
              ],
            ),
          ),

        // Category Selection
        if (!_isUploading && !_isAnalyzing) _buildCategorySelection(),

        // Action Buttons
        if (!_isUploading)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowDark,
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearSelection,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.primaryMedium),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('İptal'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _uploadFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBright,
                      foregroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload),
                        SizedBox(width: 8),
                        Text(
                          'Yükle ve Analiz Et',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Container(
      color: AppColors.backgroundDark,
      child: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(_selectedFile!, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildPDFPreview() {
    return Container(
      color: AppColors.backgroundDark,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf, size: 100, color: AppColors.warning),
            const SizedBox(height: 16),
            Text(
              'PDF Dosyası Seçildi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFile!.path.split('/').last,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.backgroundCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kategori Seçimi',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),

          // Level Selection
          DropdownButtonFormField<String>(
            initialValue: _selectedLevelId,
            decoration: InputDecoration(
              labelText: 'Seviye',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.backgroundDark,
            ),
            dropdownColor: AppColors.backgroundCard,
            items: courseLevels.map((level) {
              return DropdownMenuItem(
                value: level.id,
                child: Text(
                  level.name,
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedLevelId = value;
                _selectedThemeId = null;
                _selectedTopic = null;
              });
            },
          ),
          SizedBox(height: 12),

          // Theme Selection
          if (_selectedLevelId != null)
            DropdownButtonFormField<String>(
              initialValue: _selectedThemeId,
              decoration: InputDecoration(
                labelText: 'Tema',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: AppColors.backgroundDark,
              ),
              dropdownColor: AppColors.backgroundCard,
              items: _availableThemes.map((theme) {
                return DropdownMenuItem(
                  value: theme.id,
                  child: Text(
                    '${theme.themeNumber}. ${theme.title}',
                    style: TextStyle(color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedThemeId = value;
                  _selectedTopic = null;
                });
              },
            ),

          if (_selectedThemeId != null) ...[
            SizedBox(height: 12),
            // Topic Selection
            DropdownButtonFormField<String>(
              initialValue: _selectedTopic,
              decoration: InputDecoration(
                labelText: 'Konu Başlığı',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: AppColors.backgroundDark,
              ),
              dropdownColor: AppColors.backgroundCard,
              items: _availableTopics.map((topic) {
                return DropdownMenuItem(
                  value: topic,
                  child: Text(
                    topic,
                    style: TextStyle(color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTopic = value;
                });
              },
            ),
          ],

          SizedBox(height: 12),
          // Content Type Selection
          DropdownButtonFormField<DocumentType>(
            initialValue: _selectedContentType,
            decoration: InputDecoration(
              labelText: 'İçerik Tipi',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.backgroundDark,
            ),
            dropdownColor: AppColors.backgroundCard,
            items: [
              DropdownMenuItem(
                value: DocumentType.vocabulary,
                child: Text(
                  'Kelime Listesi',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
              DropdownMenuItem(
                value: DocumentType.practice,
                child: Text(
                  'Alıştırma',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
              DropdownMenuItem(
                value: DocumentType.grammar,
                child: Text(
                  'Gramer',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
              DropdownMenuItem(
                value: DocumentType.dialogue,
                child: Text(
                  'Diyalog',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
              DropdownMenuItem(
                value: DocumentType.pdfGeneral,
                child: Text(
                  'PDF Genel',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedContentType = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  // File picking methods
  Future<void> _pickFromGallery() async {
    final file = await _uploadService.pickImageFromGallery();
    if (file != null) {
      if (_uploadService.isFileSizeAcceptable(file)) {
        setState(() {
          _selectedFile = file;
          _fileType = 'image';
        });
      } else {
        _showError('Dosya çok büyük! Maksimum 10MB olmalı.');
      }
    }
  }

  Future<void> _takePhoto() async {
    final file = await _uploadService.takePhoto();
    if (file != null) {
      if (_uploadService.isFileSizeAcceptable(file)) {
        setState(() {
          _selectedFile = file;
          _fileType = 'image';
        });
      } else {
        _showError('Dosya çok büyük! Maksimum 10MB olmalı.');
      }
    }
  }

  Future<void> _pickPDF() async {
    final file = await _uploadService.pickPDF();
    if (file != null) {
      if (_uploadService.isFileSizeAcceptable(file, maxSizeMB: 20)) {
        setState(() {
          _selectedFile = file;
          _fileType = 'pdf';
        });
      } else {
        _showError('PDF çok büyük! Maksimum 20MB olmalı.');
      }
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedFile = null;
      _fileType = null;
      _uploadProgress = 0.0;
      _uploadedUrl = null;
    });
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;

    if (_selectedLevelId == null ||
        _selectedThemeId == null ||
        _selectedTopic == null ||
        _selectedContentType == null) {
      _showError('Lütfen tüm kategori seçimlerini yapınız.');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Step 1: Upload to Storage
      final folder = _fileType == 'image' ? 'study_images' : 'study_pdfs';

      final url = await _uploadService.uploadToStorage(
        file: _selectedFile!,
        folder: folder,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      if (url != null) {
        setState(() {
          _uploadedUrl = url;
          _isUploading = false;
          _isAnalyzing = true;
        });

        _showSuccess('Dosya yüklendi! AI detaylı analiz yapıyor...');

        // Step 2: Enhanced AI Analysis
        if (_fileType == 'image' || _fileType == 'pdf') {
          final mimeType = _fileType == 'image'
              ? 'image/jpeg'
              : 'application/pdf';

          try {
            // Call enhanced analysis with user's manual selection
            final enhancedAnalysis = await _aiService.analyzeDocumentEnhanced(
              _selectedFile!,
              mimeType,
              userSelectedType: _selectedContentType
                  ?.toString()
                  .split('.')
                  .last,
            );

            setState(() {
              _isAnalyzing = false;
            });

            // Step 3: Convert to old format and save
            final analysis = StudyMaterialAnalysis(
              primaryCategory:
                  enhancedAnalysis.categorySuggestion?.mainCategory ?? 'Genel',
              subCategory:
                  enhancedAnalysis.categorySuggestion?.subCategory ?? 'Genel',
              extractedText: enhancedAnalysis.extractedText,
              mainTopics: enhancedAnalysis.keyTopics,
              grammarStructures: enhancedAnalysis.grammarRules
                  .map((g) => g.rule)
                  .toList(),
              vocabularyLevel: enhancedAnalysis.languageLevel
                  .toString()
                  .split('.')
                  .last
                  .toUpperCase(),
              keyVocabulary: enhancedAnalysis.vocabulary
                  .map(
                    (v) => VocabularyItem(
                      german: v.german,
                      turkish: v.translation,
                      example: v.exampleSentence,
                    ),
                  )
                  .toList(),
              learningFocus: enhancedAnalysis.mainTheme,
              difficultyRating: 5,
              recommendations:
                  'Kategori: $_selectedTopic\n\nB2 Berufsprache hazırlığı için öneriler',
            );

            // Save to Firestore
            try {
              final documentId = await _firestoreService.saveStudyDocument(
                fileUrl: url,
                fileType: _fileType!,
                analysis: analysis,
                enhancedAnalysis: enhancedAnalysis,
                levelId: _selectedLevelId,
                themeId: _selectedThemeId,
                topic: _selectedTopic,
                contentType: _selectedContentType?.toString().split('.').last,
                userSelectedType: _selectedContentType
                    ?.toString()
                    .split('.')
                    .last, // USER'S CHOICE!
              );

              // Save vocabulary words
              try {
                final vocabularyService = VocabularyService(
                  'test_user',
                ); // TODO: Get from auth
                await vocabularyService.saveVocabularyFromAnalysis(
                  analysis: enhancedAnalysis,
                  documentId: documentId,
                  categoryId: _selectedTopic ?? 'Genel',
                );
              } catch (e) {
                print('Error saving vocabulary: $e');
              }

              _showSuccess('Analiz tamamlandı ve kaydedildi!');

              // Step 4: Show Enhanced Results
              if (mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EnhancedAnalysisResultScreen(
                      analysis: enhancedAnalysis,
                      imageUrl: url,
                      documentId: documentId,
                      userSelectedType: _selectedContentType
                          ?.toString()
                          .split('.')
                          .last, // Pass user's choice!
                      userSelectedCategoryId:
                          _selectedThemeId ?? _selectedLevelId,
                    ),
                  ),
                );
                _clearSelection();
              }
            } catch (e) {
              _showError('Kaydetme hatası: $e');
            }
          } catch (e) {
            print('Error in enhanced analysis: $e');
            setState(() => _isAnalyzing = false);

            // User-friendly error message
            String errorMessage = 'Analiz hatası';
            if (e.toString().contains('503') ||
                e.toString().contains('overloaded')) {
              errorMessage =
                  'AI servisi şu anda yoğun. Lütfen birkaç saniye sonra tekrar deneyin.';
            } else if (e.toString().contains('network') ||
                e.toString().contains('connection')) {
              errorMessage =
                  'İnternet bağlantısı hatası. Lütfen bağlantınızı kontrol edin.';
            } else {
              errorMessage = 'Analiz hatası: ${e.toString().split('\n').first}';
            }

            _showError(errorMessage);
            return;
          }
        }
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _isAnalyzing = false;
      });
      _showError('Hata: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }
}

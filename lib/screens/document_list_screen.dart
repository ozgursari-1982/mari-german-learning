import 'package:flutter/material.dart';
import '../models/course_structure.dart';
import '../models/study_document.dart';
import '../services/firestore_service.dart';
import '../utils/app_colors.dart';
import 'enhanced_analysis_result_screen.dart';
import '../models/document_analysis_model.dart' hide DocumentType;

class DocumentListScreen extends StatefulWidget {
  final CourseLevel level;
  final CourseTheme theme;
  final String topic;
  final DocumentType contentType;
  final String contentTypeTitle;

  const DocumentListScreen({
    super.key,
    required this.level,
    required this.theme,
    required this.topic,
    required this.contentType,
    required this.contentTypeTitle,
  });

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<StudyDocument> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      final docs = await _firestoreService.getDocumentsByHierarchy(
        levelId: widget.level.id,
        themeId: widget.theme.id,
        topic: widget.topic,
        contentType: widget.contentType.toString().split('.').last,
      );
      setState(() {
        _documents = docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading documents: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dökümanlar yüklenirken hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.contentTypeTitle,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.topic,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        backgroundColor: AppColors.backgroundCard,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: widget.level.color))
          : _documents.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _documents.length,
              itemBuilder: (context, index) {
                final doc = _documents[index];
                return _buildDocumentCard(doc);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            'Bu kategoride henüz döküman yok.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(StudyDocument doc) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      color: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.level.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            doc.fileType == 'pdf' ? Icons.picture_as_pdf : Icons.image,
            color: widget.level.color,
          ),
        ),
        title: Text(
          doc.title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${doc.uploadedAt.day}/${doc.uploadedAt.month}/${doc.uploadedAt.year}',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: () {
          // Navigate to analysis result
          // Note: We need to reconstruct EnhancedDocumentAnalysis from doc.analysisData
          final enhancedAnalysis = EnhancedDocumentAnalysis.fromJson(
            doc.analysisData,
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EnhancedAnalysisResultScreen(
                analysis: enhancedAnalysis,
                imageUrl: doc.fileUrl,
                documentId: doc.id,
                userSelectedType: doc.userSelectedType, // Pass user's choice!
              ),
            ),
          );
        },
      ),
    );
  }
}

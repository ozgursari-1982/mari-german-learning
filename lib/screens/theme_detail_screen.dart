import 'package:flutter/material.dart';
import '../models/course_structure.dart';
import '../utils/app_colors.dart';
import 'document_list_screen.dart';
import '../services/firestore_service.dart';
import 'flashcard_screen.dart';

class ThemeDetailScreen extends StatelessWidget {
  final CourseLevel level;
  final CourseTheme theme;

  const ThemeDetailScreen({
    super.key,
    required this.level,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tema ${theme.themeNumber}',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            Text(
              theme.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.backgroundCard,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          // Üst Bilgi Kartı
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              border: Border(
                bottom: BorderSide(
                  color: level.color.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        theme.subtitle,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: level.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: level.color.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          '${theme.topics.length} Konu Başlığı',
                          style: TextStyle(
                            color: level.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Konu Listesi
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: theme.topics.length,
              itemBuilder: (context, index) {
                final topic = theme.topics[index];
                final topicLetter = String.fromCharCode(
                  65 + index,
                ); // A, B, C...

                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  color: AppColors.backgroundCard,
                  shadowColor: Colors.black45,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                      colorScheme: ColorScheme.dark(primary: level.color),
                    ),
                    child: ExpansionTile(
                      iconColor: level.color,
                      collapsedIconColor: AppColors.textSecondary,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: level.color.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: level.color.withOpacity(0.5),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            topicLetter,
                            style: TextStyle(
                              color: level.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        topic,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      children: [
                        _buildContentTypeItem(
                          context,
                          DocumentType.vocabulary,
                          'Kelime Listesi (Wortschatz)',
                          Icons.list_alt,
                          topic,
                        ),
                        _buildContentTypeItem(
                          context,
                          DocumentType.practice,
                          'Alıştırmalar (Pratik)',
                          Icons.edit_note,
                          topic,
                        ),
                        _buildContentTypeItem(
                          context,
                          DocumentType.grammar,
                          'Dilbilgisi (Gramer)',
                          Icons.spellcheck,
                          topic,
                        ),
                        _buildContentTypeItem(
                          context,
                          DocumentType.dialogue,
                          'Diyaloglar',
                          Icons.chat_bubble_outline,
                          topic,
                        ),
                        _buildContentTypeItem(
                          context,
                          DocumentType.pdfGeneral,
                          'PDF Genel',
                          Icons.picture_as_pdf,
                          topic,
                        ),
                        SizedBox(height: 12),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentTypeItem(
    BuildContext context,
    DocumentType type,
    String title,
    IconData icon,
    String topic,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textSecondary, size: 20),
        title: Text(
          title,
          style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
          size: 18,
        ),
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          if (type == DocumentType.vocabulary) {
            _showVocabularyOptions(context, topic, type, title);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DocumentListScreen(
                  level: level,
                  theme: theme,
                  topic: topic,
                  contentType: type,
                  contentTypeTitle: title,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  void _showVocabularyOptions(
    BuildContext context,
    String topic,
    DocumentType type,
    String title,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kelime Çalışması',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 24),
            _buildOptionTile(
              context,
              icon: Icons.style,
              title: 'Flashcard ile Çalış',
              subtitle: 'Bu konudaki tüm kelimelerle pratik yap',
              onTap: () async {
                Navigator.pop(context); // Close sheet
                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (c) => Center(child: CircularProgressIndicator()),
                );

                try {
                  final firestoreService = FirestoreService();
                  final vocab = await firestoreService.getVocabularyByHierarchy(
                    levelId: level.id,
                    themeId: theme.id,
                    topic: topic,
                  );

                  Navigator.pop(context); // Close loading

                  if (vocab.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FlashcardScreen(
                          vocabulary: vocab,
                          title: '$topic - Flashcards',
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Bu konuda henüz kelime bulunamadı.'),
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context); // Close loading
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Hata: $e')));
                }
              },
            ),
            SizedBox(height: 16),
            _buildOptionTile(
              context,
              icon: Icons.folder_open,
              title: 'Dökümanları Gör',
              subtitle: 'Yüklenen kelime listelerini incele',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DocumentListScreen(
                      level: level,
                      theme: theme,
                      topic: topic,
                      contentType: type,
                      contentTypeTitle: title,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentBright.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.accentBright, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/document_analysis_model.dart';

/// Screen to display AI analysis results
class AnalysisResultScreen extends StatelessWidget {
  final StudyMaterialAnalysis analysis;
  final String imageUrl;

  const AnalysisResultScreen({
    super.key,
    required this.analysis,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Analiz Sonuçları'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.success.withOpacity(0.2),
                    AppColors.accentBright.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Analiz Tamamlandı!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ders materyaliniz başarıyla analiz edildi',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Categories
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accentBright.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.category, color: AppColors.accentBright),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kategori',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              analysis.primaryCategory,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (analysis.subCategory != 'Genel') ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                analysis.subCategory,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.accentBright,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Level Badge
            _buildInfoCard(
              title: 'Seviye',
              icon: Icons.school,
              color: AppColors.info,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.info, width: 2),
                    ),
                    child: Text(
                      analysis.vocabularyLevel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.info,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Zorluk: ${analysis.difficultyRating}/10',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Extracted Text (OCR Result)
            _buildInfoCard(
              title: 'Çıkarılan Metin (OCR)',
              icon: Icons.text_fields,
              color: AppColors.accentLight,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  analysis.extractedText,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.6,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Main Topics
            _buildInfoCard(
              title: 'Ana Konular',
              icon: Icons.topic,
              color: AppColors.accentBright,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: analysis.mainTopics.map((topic) {
                  return Chip(
                    label: Text(topic),
                    backgroundColor: AppColors.accentBright.withOpacity(0.2),
                    labelStyle: const TextStyle(
                      color: AppColors.accentBright,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Grammar Structures
            _buildInfoCard(
              title: 'Gramer Yapıları',
              icon: Icons.auto_awesome,
              color: AppColors.warning,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: analysis.grammarStructures.map((grammar) {
                  return Chip(
                    label: Text(grammar),
                    backgroundColor: AppColors.warning.withOpacity(0.2),
                    labelStyle: const TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Learning Focus
            _buildInfoCard(
              title: 'Odaklanman Gereken',
              icon: Icons.lightbulb,
              color: AppColors.accentLight,
              child: Text(
                analysis.learningFocus,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Recommendations
            _buildInfoCard(
              title: 'Öneriler',
              icon: Icons.recommend,
              color: AppColors.success,
              child: Text(
                analysis.recommendations,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBright,
                  foregroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Tamam, Anladım!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

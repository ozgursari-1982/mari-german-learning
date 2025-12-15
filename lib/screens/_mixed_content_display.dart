import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Helper widget to display mixed content based on AI response format
class MixedContentDisplay extends StatelessWidget {
  final Map<String, dynamic> content;
  final Color headerColor;

  const MixedContentDisplay({
    super.key,
    required this.content,
    required this.headerColor,
  });

  @override
  Widget build(BuildContext context) {
    // Check content type by keys
    final hasExerciseFields =
        content.containsKey('exerciseType') || content.containsKey('solutions');

    if (hasExerciseFields) {
      return _buildExerciseContent();
    }

    // Fallback to generic display
    return _buildGenericContent();
  }

  Widget _buildExerciseContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Exercise Type
        if (content['exerciseType'] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '📝 ${content['exerciseType']}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: headerColor,
              ),
            ),
          ),

        // Description
        if (content['exerciseDescription'] != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: headerColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              content['exerciseDescription'].toString(),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),

        // Solutions
        if (content['solutions'] != null) ...[
          const Text(
            '✅ Çözümler',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 12),
          ..._buildSolutions(),
        ],

        // Overall Explanation
        if (content['overallExplanation'] != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💡 Genel Açıklama',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content['overallExplanation'].toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

        // Completed Version
        if (content['completedVersion'] != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: headerColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: headerColor.withOpacity(0.2), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 18, color: headerColor),
                    const SizedBox(width: 8),
                    Text(
                      'Tamamlanmış Versiyon',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: headerColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  content['completedVersion'].toString(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<Widget> _buildSolutions() {
    try {
      final solutions = content['solutions'];
      if (solutions is List) {
        return solutions.map<Widget>((sol) {
          if (sol is Map) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (sol['question'] != null)
                    Text(
                      'Soru: ${sol['question']}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  if (sol['answer'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Cevap: ${sol['answer']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (sol['explanation'] != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      sol['explanation'].toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }
          return Text(sol.toString());
        }).toList();
      }
      return [];
    } catch (e) {
      return [Text('Çözümler: ${content['solutions']}')];
    }
  }

  Widget _buildGenericContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        if (content['title'] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              content['title'].toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: headerColor,
              ),
            ),
          ),

        // Explanation
        if (content['explanation'] != null)
          Text(
            content['explanation'].toString(),
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
      ],
    );
  }
}

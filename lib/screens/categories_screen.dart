import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/course_structure.dart';
import '../data/course_data.dart';
import 'theme_detail_screen.dart';

/// Screen showing course levels (A1-C1)
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: courseLevels.length,
        itemBuilder: (context, index) {
          final level = courseLevels[index];
          return _buildLevelCard(context, level);
        },
      ),
    );
  }

  Widget _buildLevelCard(BuildContext context, CourseLevel level) {
    // Count themes for this level
    final themeCount = courseThemes[level.id]?.length ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: level.color.withOpacity(0.5), width: 1),
      ),
      child: InkWell(
        onTap: () => _navigateToThemes(context, level),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [level.color.withOpacity(0.1), Colors.transparent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: level.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: level.color, width: 2),
                ),
                child: Center(
                  child: Text(
                    level.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: level.color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      level.description,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$themeCount Tema',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: level.color, size: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToThemes(BuildContext context, CourseLevel level) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ThemeListScreen(level: level)),
    );
  }
}

/// Screen showing themes for a specific level
class ThemeListScreen extends StatelessWidget {
  final CourseLevel level;

  const ThemeListScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final themes = courseThemes[level.id] ?? [];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('${level.name} Temaları'),
        backgroundColor: AppColors.backgroundCard,
      ),
      body: themes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 80,
                    color: level.color.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bu seviyede henüz tema yok',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: themes.length,
              itemBuilder: (context, index) {
                final theme = themes[index];
                return _buildThemeCard(context, theme);
              },
            ),
    );
  }

  Widget _buildThemeCard(BuildContext context, CourseTheme theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: level.color.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ThemeDetailScreen(level: level, theme: theme),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: level.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${theme.themeNumber}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: level.color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      theme.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (theme.subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          theme.subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

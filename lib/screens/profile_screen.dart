import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';
import '../services/gemini_ai_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GeminiAIService _aiService = GeminiAIService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.accentBright.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: AppColors.accentBright,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Kullanıcı Profili',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'test_user@example.com',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Ayarlar',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildSettingsTile(
                icon: Icons.vpn_key,
                title: 'API Anahtarı',
                subtitle: 'Gemini AI API anahtarını yönet',
                onTap: _showApiKeyDialog,
              ),
              _buildSettingsTile(
                icon: Icons.notifications,
                title: 'Bildirimler',
                subtitle: 'Uygulama bildirimlerini ayarla',
                onTap: () {},
              ),
              _buildSettingsTile(
                icon: Icons.language,
                title: 'Dil',
                subtitle: 'Uygulama dilini değiştir',
                onTap: () {},
              ),
              const SizedBox(height: 24),
              const Text(
                'Geliştirici Seçenekleri',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              _buildSettingsTile(
                icon: Icons.refresh,
                title: 'İlerlemeyi Sıfırla',
                subtitle:
                    'Test sonuçları ve ilerleme verilerini sil (dökümanlar korunur)',
                onTap: _resetProgress,
                isDestructive: true,
              ),
              _buildSettingsTile(
                icon: Icons.delete_forever,
                title: 'Tüm Verileri Temizle',
                subtitle:
                    'Yüklenen dökümanlar, kelimeler ve TÜM veriler silinir',
                onTap: _clearAllData,
                isDestructive: true,
              ),
              _buildSettingsTile(
                icon: Icons.logout,
                title: 'Çıkış Yap',
                subtitle: '',
                onTap: () {},
                isDestructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resetProgress() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'İlerlemeyi Sıfırla?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Tüm test sonuçları ve ilerleme verileri silinecek. Bu işlem geri alınamaz!',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final firestore = FirebaseFirestore.instance;

        // Delete progress
        await firestore
            .collection('users')
            .doc('test_user')
            .collection('progress')
            .doc('current')
            .delete();

        // Delete quiz results
        final quizResults = await firestore
            .collection('users')
            .doc('test_user')
            .collection('quiz_results')
            .get();
        for (var doc in quizResults.docs) {
          await doc.reference.delete();
        }

        // Delete study sessions
        final sessions = await firestore
            .collection('users')
            .doc('test_user')
            .collection('study_sessions')
            .get();
        for (var doc in sessions.docs) {
          await doc.reference.delete();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'İlerleme sıfırlandı! Uygulamayı yeniden başlatın.',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _clearAllData() async {
    // İLK DOĞRULAMA
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.error, size: 28),
            SizedBox(width: 8),
            Text('DİKKAT!', style: TextStyle(color: AppColors.error)),
          ],
        ),
        content: const Text(
          'Bu işlem TÜM verilerinizi silecek:\n\n'
          '• Yüklenen tüm dökümanlar\n'
          '• Tüm kelime listeleri\n'
          '• Tüm test sonuçları\n'
          '• Tüm ilerleme verileri\n\n'
          'Bu işlem GERİ ALINAMAZ!',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Devam Et'),
          ),
        ],
      ),
    );

    if (confirm1 != true) return;

    // İKİNCİ DOĞRULAMA
    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'EMİN MİSİNİZ?',
          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Tüm verileriniz kalıcı olarak silinecek.\n\n'
          'Bu işlemi onaylamak için "Devam Et" butonuna basın.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('EVET, TÜM VERİLERİ SİL'),
          ),
        ],
      ),
    );

    if (confirm2 != true) return;

    // TÜM VERİLERİ SİL
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veriler siliniyor... Lütfen bekleyin.'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 10),
          ),
        );
      }

      final firestore = FirebaseFirestore.instance;
      final userId = 'test_user';

      // 1. Study documents sil (TÜM dökümanları sil - userId filtresi yok, eski dökümanlar için)
      final docs = await firestore
          .collection('study_documents')
          .get(); // No filter - delete ALL
      for (var doc in docs.docs) {
        await doc.reference.delete();
      }
      print('✅ ${docs.docs.length} döküman silindi');

      // 2. Vocabulary sil (users subcollection)
      final vocab = await firestore
          .collection('users')
          .doc(userId)
          .collection('vocabulary')
          .get();
      for (var doc in vocab.docs) {
        await doc.reference.delete();
      }
      print('✅ ${vocab.docs.length} kelime silindi');

      // 3. Quiz results sil (TÜM test sonuçlarını sil)
      final quizResults = await firestore
          .collection('quiz_results')
          .get(); // No filter - delete ALL
      for (var doc in quizResults.docs) {
        await doc.reference.delete();
      }
      print('✅ ${quizResults.docs.length} test sonucu silindi');

      // 4. Progress sil
      await firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc('current')
          .delete();
      print('✅ İlerleme verileri silindi');

      // 5. Study sessions sil
      final sessions = await firestore
          .collection('users')
          .doc(userId)
          .collection('study_sessions')
          .get();
      for (var doc in sessions.docs) {
        await doc.reference.delete();
      }
      print('✅ ${sessions.docs.length} çalışma oturumu silindi');

      // 6. AI feedback cache sil
      final feedbackCache = await firestore
          .collection('users')
          .doc(userId)
          .collection('ai_feedback_cache')
          .get();
      for (var doc in feedbackCache.docs) {
        await doc.reference.delete();
      }
      print('✅ AI cache silindi');

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Tüm veriler silindi! Uygulamayı yeniden başlatın.',
            ),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('❌ Veri silme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive
                ? AppColors.error.withOpacity(0.1)
                : AppColors.accentBright.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDestructive ? AppColors.error : AppColors.accentBright,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? AppColors.error : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(
                subtitle,
                style: const TextStyle(color: AppColors.textSecondary),
              )
            : null,
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _showApiKeyDialog() async {
    final currentKey = await _aiService.getApiKey();
    final controller = TextEditingController(text: currentKey);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'API Anahtarı',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Gemini AI API anahtarını buradan değiştirebilirsiniz.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'API Key',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.textSecondary.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accentBright),
                ),
                filled: true,
                fillColor: AppColors.backgroundDark,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _aiService.setApiKey(controller.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('API anahtarı güncellendi'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBright,
              foregroundColor: AppColors.textPrimary,
            ),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}

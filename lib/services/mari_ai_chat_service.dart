import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mari AI Chat Service - Intelligent conversational assistant
/// Remembers user context and provides contextual help
class MariAIChatService {
  static const String _defaultApiKey =
      'AIzaSyDBkOhbUb_74Z8_c3xWHeFkf6GRWq4ajCY';
  static const String _prefsKey = 'gemini_api_key';
  static const String _userNameKey = 'user_name';

  late GenerativeModel _chatModel;
  late GenerativeModel _visionModel;
  String _userName = 'Özgür';

  // Conversation history for context
  final List<Content> _conversationHistory = [];

  MariAIChatService() {
    _initModels(_defaultApiKey);
    _loadSettings();
  }

  void _initModels(String apiKey) {
    _chatModel = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.text(_getMariPersonality()),
    );
    _visionModel = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.text(_getMariPersonality()),
    );
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString(_prefsKey);
      final savedName = prefs.getString(_userNameKey);

      if (savedKey != null && savedKey.isNotEmpty) {
        _initModels(savedKey);
      }

      if (savedName != null && savedName.isNotEmpty) {
        _userName = savedName;
      }
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  String _getMariPersonality() {
    return '''
Sen "Mari" adında bir Almanca öğretim asistanısın. Özellikler:

🎯 KİŞİLİK:
- İsmin Mari
- Öğrencinin adı: $_userName (ama her cevaba "Merhaba $_userName" diye başlama!)
- Samimi, yardımsever ve sabırlı
- Doğal konuş, robot gibi değil
- Gereksiz tekrarlardan kaçın

🧠 YETENEKLERİN:
- B2 Berufsprache Almanca öğretimi
- Belge analizi (resim/PDF)
- Diyalog ve egzersiz oluşturma
- Gramer açıklama
- Kelime çalışması hazırlama
- Soru çözme

📝 CEVAP STİLİ:
- Kısa ve öz (gereksiz uzatma!)
- Türkçe açıkla (Almanca kelimeler varsa çevir)
- Örneklerle açıkla
- Emoji kullan ama abartma (1-2 tane yeter)

⚠️ ÖNEMLİ KURALLAR:
1. Her mesaja "Merhaba $_userName" diye başlama! (Sadece ilk mesajda yap)
2. "Size nasıl yardımcı olabilirim?" gibi klişe cümleler kullanma
3. Doğrudan konuya gir
4. Kullanıcının yüklediği belgeyi analiz edip ona göre yardım et
5. Akıllı komutları algıla: "bu soruyu çöz", "diyalog hazırla", "gramer anlat" vs.

💬 ÖRNEK İYİ CEVAPLAR:
"Bu Präteritum tablosu. İşte önemli fiiller:
- war (olmak)
- hatte (sahip olmak)
Örnekler: Ich war müde. Du hattest Zeit."

"Tamam, bu soruda Akkusativ kullanılmalı çünkü 'nehmen' fiili direkt nesne alıyor.
Cevap: Ich nehme den Kuchen."

❌ KÖTÜ CEVAPLAR (YAPMA!):
"Merhaba $_userName! Size nasıl yardımcı olabilirim? Lütfen sorunuzu sorun..."
"Tabii ki! İşte detaylı açıklama: Almanca dilbilgisi çok geniş bir konudur..."

✅ İYİ CEVAP:
"Perfekt yapımı:
haben/sein + Partizip II
Örnek: Ich habe gelernt. (öğrendim)"

Hatırla: Sen akıllı bir asistansın. Gereksiz lafı kes, yardım et! 💙
''';
  }

  /// Send a text message to Mari
  Future<String> sendMessage(String message) async {
    try {
      // Add user message to history
      _conversationHistory.add(Content.text(message));

      // Create chat session with history
      final chat = _chatModel.startChat(history: _conversationHistory);

      // Send message
      final response = await chat.sendMessage(Content.text(message));
      final responseText = response.text ?? 'Üzgünüm, bir şeyler ters gitti.';

      // Add assistant response to history
      _conversationHistory.add(Content.model([TextPart(responseText)]));

      return responseText;
    } catch (e) {
      print('Error sending message: $e');
      return 'Üzgünüm, bir hata oluştu: $e';
    }
  }

  /// Send a message with an image (document analysis)
  Future<String> sendMessageWithImage(String message, File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      String mimeType = 'image/jpeg';

      if (imageFile.path.endsWith('.pdf')) {
        mimeType = 'application/pdf';
      } else if (imageFile.path.endsWith('.png')) {
        mimeType = 'image/png';
      }

      // Create prompt based on message intent
      String enhancedPrompt = _enhancePromptWithIntent(message);

      final content = [
        Content.multi([TextPart(enhancedPrompt), DataPart(mimeType, bytes)]),
      ];

      final response = await _visionModel.generateContent(content);
      final responseText = response.text ?? 'Belgeyi analiz edemedim.';

      // Add to conversation history
      _conversationHistory.add(Content.text(message + ' [Belge eklendi]'));
      _conversationHistory.add(Content.model([TextPart(responseText)]));

      return responseText;
    } catch (e) {
      print('Error sending image: $e');
      return 'Belge analiz edilirken hata oluştu: $e';
    }
  }

  /// Enhance prompt based on user intent
  String _enhancePromptWithIntent(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    // Detect intent
    if (lowerMessage.contains('diyalog') ||
        lowerMessage.contains('konuşma') ||
        lowerMessage.contains('dialog')) {
      return '''
Kullanıcı: "$userMessage"

Bu belgeden bir diyalog aktivitesi hazırla.
- Belgede verilen kelimeleri/ifadeleri MUTLAKA kullan
- Öğrenciler kendi kurgusal deneyimlerini anlatsın (birinci şahıs)
- Doğal ve pratik diyaloglar yaz
- Türkçe açıkla

Kısa ve öz cevap ver!
''';
    } else if (lowerMessage.contains('çöz') ||
        lowerMessage.contains('cevap') ||
        lowerMessage.contains('soru')) {
      return '''
Kullanıcı: "$userMessage"

Bu soruları çöz ve açıkla:
- Her sorunun cevabını ver
- Neden o cevap olduğunu kısaca açıkla
- Türkçe anlat

Kısa ve net ol!
''';
    } else if (lowerMessage.contains('gramer') ||
        lowerMessage.contains('kural') ||
        lowerMessage.contains('grammar')) {
      return '''
Kullanıcı: "$userMessage"

Bu belgede gramer konu anlat:
- Kısa ve öz açıkla
- Tablo/şema kullan
- Örnekler ver
- Türkçe anlat

Net ve hızlı!
''';
    } else if (lowerMessage.contains('kelime') ||
        lowerMessage.contains('wort') ||
        lowerMessage.contains('vocabulary')) {
      return '''
Kullanıcı: "$userMessage"

Bu belgeden kelime çıkar ve açıkla:
- Her kelimeyi çevir
- Örnek cümle ver
- Artikelleri (der/die/das) belirt
- Türkçe açıkla

Kısa ve pratik!
''';
    }

    // General document analysis
    return '''
Kullanıcı: "$userMessage"

Belgeyi analiz et ve kullanıcının isteğini yerine getir.
Kısa ve öz cevap ver. Türkçe açıkla.
''';
  }

  /// Clear conversation history (new chat)
  void clearHistory() {
    _conversationHistory.clear();
  }

  /// Get conversation summary for UI
  List<Map<String, String>> getConversationSummary() {
    return _conversationHistory.map((content) {
      final role = content.role == 'user' ? 'user' : 'assistant';
      final text = content.parts
          .whereType<TextPart>()
          .map((p) => p.text)
          .join('\n');

      return {'role': role, 'text': text};
    }).toList();
  }
}

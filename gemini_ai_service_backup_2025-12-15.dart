import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/quiz_model.dart';
import '../models/document_analysis_model.dart';
import '../models/ai_feedback_model.dart';

/// Advanced Gemini AI Service for personalized German learning
class GeminiAIService {
  static const String _defaultApiKey =
      'AIzaSyDBkOhbUb_74Z8_c3xWHeFkf6GRWq4ajCY';
  static const String _prefsKey = 'gemini_api_key';

  late GenerativeModel _visionModel;
  late GenerativeModel _textModel;
  String _currentApiKey = _defaultApiKey;

  GeminiAIService() {
    _initModels(_defaultApiKey);
    _loadApiKey();
  }

  void _initModels(String apiKey) {
    _currentApiKey = apiKey;
    _visionModel = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
    _textModel = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
  }

  Future<void> _loadApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString(_prefsKey);
      if (savedKey != null && savedKey.isNotEmpty) {
        _initModels(savedKey);
        print('Loaded custom API key');
      }
    } catch (e) {
      print('Error loading API key: $e');
    }
  }

  Future<void> setApiKey(String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, apiKey);
      _initModels(apiKey);
      print('API key updated successfully');
    } catch (e) {
      print('Error saving API key: $e');
      rethrow;
    }
  }

  Future<String> getApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefsKey) ?? _defaultApiKey;
    } catch (e) {
      return _currentApiKey;
    }
  }

  /// Analyze uploaded image
  Future<StudyMaterialAnalysis> analyzeImage(File imageFile) async {
    return _analyzeFile(imageFile, 'image/jpeg');
  }

  /// Analyze uploaded PDF
  Future<StudyMaterialAnalysis> analyzePdf(File pdfFile) async {
    return _analyzeFile(pdfFile, 'application/pdf');
  }

  /// Enhanced document analysis with detailed extraction
  Future<EnhancedDocumentAnalysis> analyzeDocumentEnhanced(
    File file,
    String mimeType, {
    String? userSelectedType, // USER'S MANUAL SELECTION - ALWAYS PRIORITY!
  }) async {
    try {
      final bytes = await file.readAsBytes();

      // Prepare user selection context
      String userSelectionContext = '';
      String userDocType = 'mixed'; // default

      if (userSelectedType != null && userSelectedType.isNotEmpty) {
        userDocType = userSelectedType.toLowerCase();
        userSelectionContext =
            '\n\n' +
            '🎯 **CRITICAL: USER\'S MANUAL SELECTION (HIGHEST PRIORITY!)**\n' +
            '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n' +
            'USER SELECTED DOCUMENT TYPE: "$userSelectedType"\n' +
            '\n' +
            '⚠️ ABSOLUTE RULE:\n' +
            '- NO MATTER what the document content says, you MUST set documentType to: "$userDocType"\n' +
            '- The user has MANUALLY classified this document as: "$userSelectedType"\n' +
            '- DO NOT override user\'s choice based on content analysis\n' +
            '- Even if document says "Sprechen Sie" or shows dialogue instructions - if user selected "exercise", it IS an exercise\n' +
            '- Even if document has fill-in-blanks - if user selected "dialogue", it IS a dialogue\n' +
            '- USER\'S SELECTION = FINAL DECISION\n' +
            '\n' +
            'EXAMPLE:\n' +
            '- If user selected "exercise" but doc says "Sprechen Sie" → documentType = "exercise" ✓\n' +
            '- If user selected "dialogue" but doc has blanks → documentType = "dialogue" ✓\n' +
            '- If user selected "grammar" but doc shows images → documentType = "grammar" ✓\n' +
            '\n' +
            'YOUR ANALYSIS MUST BE TAILORED TO: "$userSelectedType"\n' +
            '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n';
      }

      // Build document type section based on user selection
      String documentTypeSection;
      if (userSelectedType != null) {
        documentTypeSection =
            '\n📋 YOUR ANALYSIS FOCUS:\n' +
            'Since the user classified this as "$userSelectedType", your analysis should focus on:\n' +
            '\n' +
            _getAnalysisFocusInstructions(userSelectedType) +
            '\n' +
            'CRITICAL: Set "documentType" to: "$userDocType" (user\'s choice)\n';
      } else {
        documentTypeSection =
            '\n📋 DOCUMENT TYPE - Only if user didn\'t specify, identify what kind of document this is:\n' +
            '   - "vocabulary" = Wortschatz/word lists\n' +
            '   - "grammar" = Grammar lessons/rules\n' +
            '   - "professional" = Professional/business texts (Berufsprache)\n' +
            '   - "exercise" = Exercises/practice questions (fill-in, multiple choice, matching)\n' +
            '   - "dialogue" = Conversations/dialogues OR activities asking students to create dialogues\n' +
            '   - "mixed" = Mixed content\n';
      }

      final prompt =
          '''
IMPORTANT: You MUST respond with ONLY valid JSON. No explanations, no markdown, just pure JSON.
$userSelectionContext

Analyze this German learning material and provide analysis for B2 Berufsprache exam preparation.

⚠️ **CRITICAL EFFICIENCY RULE - SAVE API RESOURCES:**

IF documentType is "vocabulary", "grammar", "practice", "exercise", or "dialogue":
  - ✅ Focus ONLY on extracting the specific content (vocab, grammar rules, exercises, dialogue)
  - ❌ DO NOT analyze images in detail → Set imageDescriptions = [] (empty array)
  - ❌ DO NOT create contentStructure → Set contentStructure = [] (empty array)
  - ✅ These images were already analyzed in initial upload
  - ✅ Save API resources by skipping redundant analysis

IF documentType is "pdfGeneral" or "mixed":
  - ✅ DO analyze images and create imageDescriptions array
  - ✅ DO create contentStructure array
  - ✅ This is the ONLY case where detailed image/structure analysis is needed

🔍 IMAGE ANALYSIS (ONLY for pdfGeneral/mixed):
⚠️ FOCUS ON EDUCATIONAL CONTENT, NOT VISUAL DETAILS!

📖 **STEP 1: READ THE TEXT FIRST (MOST IMPORTANT!)**
   Before analyzing ANY image, you MUST:
   1. Read ALL text on the page (titles, instructions, questions, captions)
   2. Identify what the page is teaching (topic, profession, activity)
   3. Find any text directly below/above/near the images
   4. Look for questions like "Sprechen Sie über...", "Was sehen Sie?", "Welcher Beruf ist das?"
   5. Look for captions or labels under/near images
   
   ⚠️ The text tells you EXACTLY what the images represent - USE THIS INFORMATION!

🖼️ **STEP 2: ANALYZE IMAGES IN CONTEXT (ONLY for pdfGeneral/mixed)**
   Now that you know what the page is about from the text:
   1. Identify the MAIN EDUCATIONAL PURPOSE: What profession/topic/activity is being taught?
   2. Match each image to the topic/question/instruction you read
   3. DO NOT describe clothing colors, background details, or other irrelevant visual elements
   4. ONLY describe what is RELEVANT to the learning objective (profession, activity, topic)
   5. Keep descriptions CONCISE and FOCUSED on the educational theme
   
   Example workflow:
   - Text says: "Sprechen Sie über die Berufe. Was machen diese Personen?"
   - You see 3 images of people working
   - Your analysis: Focus on identifying the PROFESSIONS and ACTIVITIES, not clothing or backgrounds
   
$documentTypeSection

🖼️ IMAGE DESCRIPTIONS - CONDITIONAL:
   ⚠️ IF documentType = vocabulary/grammar/practice/exercise/dialogue → Set imageDescriptions = [] (EMPTY!)
   ✅ IF documentType = pdfGeneral or mixed → Create detailed imageDescriptions array
   
   For pdfGeneral/mixed ONLY, create "imageDescriptions" array focusing on EDUCATIONAL content:
   
   ⚠️ CRITICAL RULES (for pdfGeneral/mixed only):
   - First READ the page text, then describe images based on that context
   - NO descriptions of clothing colors, furniture, background scenery (UNLESS directly relevant to profession)
   - YES to: profession name, main activity, educational theme
   - If text says "Arzt" near an image → describe as "Ein Arzt..." (use the text information!)
   - Keep descriptions SHORT and FOCUSED on the learning objective
   - Both German and Turkish should be CONCISE (1-2 sentences maximum)
   
   ❌ BAD Example (TOO MUCH DETAIL, ignoring context):
   "Ein Mann in blauem T-Shirt hilft einem älteren Mann, der im Bett sitzt. Der Mann hält die Beine des älteren Mannes..."
   
   ✅ GOOD Example (FOCUSED ON LEARNING, using page context):
   "Ein Altenpfleger hilft einem Patienten bei der Mobilisierung. / Bir yaşlı bakıcısı hastanın hareket etmesine yardım ediyor."
   
   [
     {
       "imageNumber": 1,
       "description": "CONCISE description based on page context (profession/activity from text) in German / Turkish",
       "relevantVocabulary": [
         {"german": "der Arzt", "turkish": "doktor"},
         {"german": "untersuchen", "turkish": "muayene etmek"}
       ],
       "profession": "profession name from context/text (German / Turkish)",
       "activity": "Main activity from context (German / Turkish) - CONCISE"
     }
   ]

📝 EXTRACTED TEXT - All German text AND all text instructions from the document

🎯 ACTIVITY INSTRUCTIONS:
   Extract the exact instructions given to students (in German and translate to Turkish)
   Example: "Sprechen Sie mit Ihrem Partner über die Berufe" → "Meslekler hakkında partnerinizle konuşun"

📚 CONTENT STRUCTURE - CONDITIONAL:
   ⚠️ IF documentType = vocabulary/grammar/practice/exercise/dialogue → Set contentStructure = [] (EMPTY!)
   ✅ IF documentType = pdfGeneral or mixed → Create detailed contentStructure array
   
   For pdfGeneral/mixed ONLY, analyze the document and identify main sections/parts:
   
   [
     {
       "title": "Section title (e.g., 'Teil A', 'Wortschatz', 'Übung 1')",
       "type": "section|heading|exercise|vocabulary|image|text",
       "content": "Brief description of what this section contains (Turkish)",
       "page": 1 (if multi-page document)
     }
   ]
   
   Example for pdfGeneral/mixed:
   [
     {"title": "Berufe", "type": "heading", "content": "Ana başlık - Meslekler", "page": 1},
     {"title": "Bilder", "type": "image", "content": "3 meslek görseli (Doktor, Öğretmen, Bakıcı)", "page": 1},
     {"title": "Sprechen Sie", "type": "exercise", "content": "Konuşma aktivitesi - Meslekler hakkında", "page": 1}
   ]

Response format (ONLY JSON):
{
  "documentType": "${userDocType}",
  "hasVisualElements": true,
  "languageLevel": "B2",
  "mainTopic": "Meslekler",
  "mainTheme": "İş ve Kariyer", 
  "categories": ["Berufsprache", "Dialog"],
  "imageDescriptions": [], // EMPTY for vocabulary/grammar/practice/exercise/dialogue, detailed ONLY for pdfGeneral/mixed
  "activityInstructions": {
    "german": "Instructions from document",
    "turkish": "Türkçe talimatlar",
    "activityType": "based on user selection"
  },
  "vocabulary": [],
  "grammarRules": [],
  "extractedText": "full text here including all instructions",
  "keyTopics": ["Berufe", "Arbeit"],
  "professionalContext": "Farklı meslekler ve iş aktiviteleri",
  "isBerufsprache": true,
  "confidence": 0.95,
  "contentStructure": [], // EMPTY for vocabulary/grammar/practice/exercise/dialogue, detailed ONLY for pdfGeneral/mixed
  "categorySuggestion": {
    "mainCategory": "Based on user selection",
    "subCategory": "Specific detail",
    "confidence": 0.9,
    "reasoning": "Analysis reasoning",
    "keywords": ["key", "words"]
  }
}

CRITICAL REMINDERS:
- 🔴 EFFICIENCY: If documentType = vocabulary/grammar/practice/exercise/dialogue → imageDescriptions = [], contentStructure = [] (EMPTY!)
- 🔴 EFFICIENCY: ONLY pdfGeneral or mixed types need detailed imageDescriptions and contentStructure
- 🔴 STEP 1: READ ALL PAGE TEXT FIRST (titles, questions, instructions, captions) BEFORE analyzing images!
- 🔴 STEP 2: Use the text context to understand what images represent (e.g., if text says "Berufe", focus on professions)
- FOCUS on EDUCATIONAL CONTENT, not visual details (no clothing colors, backgrounds, etc.)
- IMAGE DESCRIPTIONS must be BILINGUAL: German FIRST, then "/" then Turkish (ONLY for pdfGeneral/mixed)
- Keep descriptions CONCISE (1-2 sentences) - focus ONLY on profession/activity/theme based on PAGE CONTEXT
- Format: "Short German about profession/activity. / Kısa Türkçe meslek/aktivite açıklaması."
- Activity field: "Main activity in German / Ana aktivite Türkçe" (CONCISE)
- Connect images to the learning objective from text, NOT to visual appearance
- ALWAYS set hasVisualElements = true if there are images
- CRITICAL VOCABULARY EXTRACTION:
  * If documentType is "vocabulary", extract ALL words into vocabulary array:
    {"german": "das Wort", "article": "das", "plural": "die Wörter", "translation": "kelime", "exampleSentence": "...", "professionalContext": "..."}
  * For OTHER document types (dialogue, exercise, grammar): Keep "vocabulary" and "grammarRules" as EMPTY arrays [] for API efficiency
${userSelectedType != null ? '\n⚠️ REMEMBER: documentType MUST be "$userDocType" (user\'s selection is FINAL!)' : ''}
''';

      final content = [
        Content.multi([TextPart(prompt), DataPart(mimeType, bytes)]),
      ];

      // Retry logic for overloaded model
      int maxRetries = 3;
      int retryCount = 0;
      Duration retryDelay = const Duration(seconds: 2);

      while (retryCount < maxRetries) {
        try {
          final response = await _visionModel.generateContent(
            content,
            generationConfig: GenerationConfig(
              temperature: 0.1,
              responseMimeType: 'application/json',
            ),
          );

          final analysisText = response.text ?? '';
          print('📨 Raw AI Response length: ${analysisText.length}');

          // Clean the response (remove markdown code blocks if present)
          final cleanedText = _cleanJsonResponse(analysisText);
          print('🧹 Cleaned response length: ${cleanedText.length}');
          print(
            '🔍 First 300 chars: ${cleanedText.substring(0, cleanedText.length > 300 ? 300 : cleanedText.length)}',
          );

          return _parseEnhancedAnalysis(cleanedText);
        } catch (e) {
          retryCount++;

          // Check if it's a 503 error (overloaded)
          if (e.toString().contains('503') ||
              e.toString().contains('overloaded')) {
            if (retryCount < maxRetries) {
              print(
                '⚠️ Model overloaded. Retrying in ${retryDelay.inSeconds}s... (Attempt $retryCount/$maxRetries)',
              );
              await Future.delayed(retryDelay);
              retryDelay *= 2; // Exponential backoff
              continue;
            }
          }

          // If not 503 or max retries reached, throw error
          print('Error in enhanced analysis: $e');
          rethrow;
        }
      }

      // This should never be reached, but just in case
      throw Exception('Failed to analyze document after $maxRetries attempts');
    } catch (e) {
      print('Error in enhanced analysis: $e');
      rethrow;
    }
  }

  EnhancedDocumentAnalysis _parseEnhancedAnalysis(String jsonText) {
    try {
      print('📝 Parsing enhanced analysis JSON...');
      print('📄 JSON length: ${jsonText.length} characters');
      print(
        '📄 First 500 chars: ${jsonText.substring(0, jsonText.length > 500 ? 500 : jsonText.length)}',
      );

      final json = jsonDecode(jsonText);
      print('✅ JSON decoded successfully');
      print('📊 Document type from JSON: ${json['documentType']}');
      print('📊 Has visual elements: ${json['hasVisualElements']}');
      print(
        '📊 Image descriptions count: ${(json['imageDescriptions'] as List?)?.length ?? 0}',
      );

      return EnhancedDocumentAnalysis.fromJson(json);
    } catch (e, stackTrace) {
      print('❌ Error parsing enhanced analysis: $e');
      print('📍 Stack trace: $stackTrace');
      print('📄 Full JSON text:\n$jsonText');

      // Return default analysis on error
      return EnhancedDocumentAnalysis(
        documentType: DocumentType.unknown,
        languageLevel: LanguageLevel.unknown,
        mainTopic: 'Unbekannt',
        mainTheme: 'Unbekannt',
        categories: [],
        vocabulary: [],
        grammarRules: [],
        extractedText: '',
        keyTopics: [],
        professionalContext: '',
        isBerufsprache: false,
        confidence: 0.0,
      );
    }
  }

  /// Clean JSON response by removing markdown code blocks and extra whitespace
  String _cleanJsonResponse(String text) {
    String cleaned = text.trim();

    // Remove markdown code blocks (```json ... ``` or ``` ... ```)
    if (cleaned.startsWith('```')) {
      // Find the first newline after ```
      int firstNewline = cleaned.indexOf('\n');
      if (firstNewline != -1) {
        cleaned = cleaned.substring(firstNewline + 1);
      }

      // Remove closing ```
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }

      cleaned = cleaned.trim();
    }

    // Remove any remaining backticks at start/end
    while (cleaned.startsWith('`')) {
      cleaned = cleaned.substring(1);
    }
    while (cleaned.endsWith('`')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }

    return cleaned.trim();
  }

  /// Get analysis focus instructions based on user's manual selection
  String _getAnalysisFocusInstructions(String userSelectedType) {
    final type = userSelectedType.toLowerCase();

    switch (type) {
      case 'theory':
      case 'konu anlatımı':
        return '''
- Extract main concepts and theoretical explanations
- Identify key learning points
- Focus on understanding the topic, not practicing
- Summarize the theoretical content in Turkish
''';

      case 'vocabulary':
      case 'kelime listesi':
        return '''
- Extract ALL vocabulary words with articles (der/die/das)
- Include plural forms, translations, and example sentences
- Group words by category if applicable
- Focus on vocabulary extraction, not grammar or exercises
''';

      case 'practice':
      case 'exercise':
      case 'alıştırma':
        return '''
- Identify exercise types (fill-in-blanks, multiple choice, matching)
- Extract questions and correct answers if visible
- Focus on practice activities and solutions
- Even if document says "Sprechen Sie", treat it as EXERCISE practice
- Analyze what grammar/vocabulary is being practiced
''';

      case 'grammar':
      case 'gramer':
        return '''
- Extract grammar rules and explanations
- Identify tenses, cases, or structures being taught
- Include example sentences showing the grammar in use
- Focus on grammatical concepts, not vocabulary lists
- Summarize grammar rules in Turkish
''';

      case 'dialogue':
      case 'diyalog':
        return '''
- Extract dialogue text if present
- Identify conversation scenarios and contexts
- Focus on speaking/conversation practice
- Even if document has fill-in-blanks, treat it as DIALOGUE practice
- Analyze communication patterns and phrases
- Prepare sample dialogues based on the context
''';

      case 'pdfgeneral':
      case 'pdf genel':
      case 'mixed':
        return '''
- Analyze all content types present (theory, exercises, vocab, etc.)
- Provide a comprehensive overview
- Identify main sections and their purposes
- Extract key information from all parts
''';

      default:
        return '''
- Analyze the document content thoroughly
- Extract relevant information based on the context
- Provide comprehensive analysis
''';
    }
  }

  Future<StudyMaterialAnalysis> _analyzeFile(File file, String mimeType) async {
    try {
      final bytes = await file.readAsBytes();

      final prompt =
          '''
IMPORTANT: You MUST respond with ONLY valid JSON. No explanations, no markdown, just pure JSON.

Analyze this German study material ($mimeType) and CLASSIFY it:

CRITICAL RULE:
- If the document contains grammar tables, conjugation rules, tense explanations (Präteritum, Perfekt), or passive voice -> IT IS A GRAMMAR CATEGORY.
- Do NOT classify grammar sheets as "Beruf" or "Essen" even if the example sentences use those words.

FIRST: Determine the PRIMARY CATEGORY:

GRAMMAR CATEGORIES (Priority if grammar rules are present):
- Präsens (Present tense)
- Präteritum (Simple past - war, hatte, ging)
- Perfekt (Perfect tense - habe/bin gemacht)
- Passiv (Passive voice - wurde gemacht)
- Akkusativ (Accusative case)
- Dativ (Dative case)
- Adjektive (Adjective endings, comparison)
- Präpositionen (Prepositions - in, an, auf, mit)

TOPIC CATEGORIES (Only if NO grammar rules are the main focus):
- Beruf (Work, jobs, career, office)
- Essen (Food, cooking, restaurant)
- Reisen (Travel, holiday, transport)
- Gesundheit (Health, body, doctor)
- Wohnen (Living, house, furniture)
- Alltag (Daily life, shopping, routine)
- Genel (General/Other)

Choose ONE category that best fits the main focus.

SECOND: Determine the SUB-CATEGORY (Specific Topic):
- If "Präteritum", sub-category could be "Regular Verbs", "Irregular Verbs", "Modal Verbs".
- If "Beruf", sub-category could be "Job Interview", "Work Accident".
Provide a short, specific Turkish sub-category name.

Then extract:
1. ALL German text (OCR) - Be very thorough with PDFs.
2. Main topics covered
3. Grammar structures found
4. CEFR level (A1, A2, B1, B2, C1)
5. Key vocabulary with Turkish translations
6. Learning focus in Turkish
7. Difficulty 1-10
8. Study recommendations in Turkish

Response format (ONLY JSON):
{
  "primaryCategory": "Beruf",
  "subCategory": "İş Kazası",
  "extractedText": "all German text from document",
  "mainTopics": ["topic1", "topic2"],
  "grammarStructures": ["Perfekt", "Akkusativ"],
  "vocabularyLevel": "B1",
  "keyVocabulary": [
    {"german": "lernen", "turkish": "öğrenmek", "example": "Ich lerne Deutsch"}
  ],
  "learningFocus": "focus areas in Turkish",
  "difficultyRating": 5,
  "recommendations": "study tips in Turkish"
}
''';

      final content = [
        Content.multi([TextPart(prompt), DataPart(mimeType, bytes)]),
      ];

      final response = await _visionModel.generateContent(
        content,
        generationConfig: GenerationConfig(
          temperature: 0.1,
          responseMimeType: 'application/json',
        ),
      );
      final analysisText = response.text ?? '';

      print('AI Response: $analysisText');

      return _parseAnalysis(analysisText);
    } catch (e) {
      print('Error analyzing file: $e');
      rethrow;
    }
  }

  StudyMaterialAnalysis _parseAnalysis(String jsonText) {
    try {
      String cleanJson = jsonText.trim();
      if (cleanJson.startsWith('```json')) {
        cleanJson = cleanJson.substring(7);
      }
      if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.substring(3);
      }
      if (cleanJson.endsWith('```')) {
        cleanJson = cleanJson.substring(0, cleanJson.length - 3);
      }
      cleanJson = cleanJson.trim();

      print('Parsing JSON: $cleanJson');

      final Map<String, dynamic> json = jsonDecode(cleanJson);

      final List<VocabularyItem> vocabulary = [];
      if (json['keyVocabulary'] != null) {
        for (final item in json['keyVocabulary']) {
          vocabulary.add(
            VocabularyItem(
              german: item['german'] ?? '',
              turkish: item['turkish'] ?? '',
              example: item['example'] ?? '',
            ),
          );
        }
      }

      return StudyMaterialAnalysis(
        primaryCategory: json['primaryCategory'] ?? 'Genel',
        subCategory: json['subCategory'] ?? 'Genel',
        extractedText: json['extractedText'] ?? 'Metin çıkarılamadı',
        mainTopics: List<String>.from(json['mainTopics'] ?? ['Genel']),
        grammarStructures: List<String>.from(
          json['grammarStructures'] ?? ['Belirsiz'],
        ),
        vocabularyLevel: json['vocabularyLevel'] ?? 'A1',
        keyVocabulary: vocabulary,
        learningFocus: json['learningFocus'] ?? 'Temel konulara odaklan',
        difficultyRating: json['difficultyRating'] ?? 5,
        recommendations: json['recommendations'] ?? 'Düzenli çalış',
      );
    } catch (e) {
      print('Error parsing JSON: $e');
      print('Raw text: $jsonText');

      return StudyMaterialAnalysis(
        primaryCategory: 'Genel',
        subCategory: 'Hata',
        extractedText: jsonText.length > 500
            ? jsonText.substring(0, 500) + '...'
            : jsonText,
        mainTopics: ['Analiz Hatası'],
        grammarStructures: ['JSON parse edilemedi'],
        vocabularyLevel: 'Belirsiz',
        keyVocabulary: [],
        learningFocus: 'AI yanıtı beklenmeyen formatta. Lütfen tekrar deneyin.',
        difficultyRating: 5,
        recommendations: 'Resmi tekrar yükleyin veya farklı bir resim deneyin.',
      );
    }
  }

  /// Generate a mixed-format quiz based on topic and level
  Future<Quiz> generateQuiz({
    required String topic,
    required String level,
    List<String>? subTopics,
  }) async {
    try {
      final prompt =
          '''
IMPORTANT: You MUST respond with ONLY valid JSON. No explanations.

Create a German language quiz for Level $level on the topic: "$topic".
Include sub-topics if relevant: ${subTopics?.join(', ') ?? 'General'}.

⚠️ CRITICAL FORMATTING RULES:
1. "questionText" MUST be in GERMAN (not Turkish!)
2. "questionTextTurkish" field: Turkish translation of the question (small text below)
3. "options" (for multiple choice) MUST be in GERMAN
4. "explanation" MUST be in TURKISH (this explains the answer)
5. Title can be in Turkish

Response format (JSON):
{
  "title": "Quiz Title (Turkish)",
  "questions": [
    {
      "type": "multipleChoice",
      "questionText": "Wie heißt du?",
      "questionTextTurkish": "(Adın ne?)",
      "options": ["Ich heiße Maria", "Du heißt Maria", "Er heißt Maria"],
      "correctAnswer": "Ich heiße Maria",
      "explanation": "Explanation in Turkish",
      "points": 10
    },
    {
      "type": "fillInBlanks",
      "questionText": "GERMAN Sentence with _____ blank.",
      "questionTextTurkish": "(Turkish translation)",
      "correctAnswer": "word",
      "explanation": "Explanation in Turkish",
      "points": 10
    },
    {
      "type": "trueFalse",
      "questionText": "GERMAN Statement",
      "questionTextTurkish": "(Turkish translation)",
      "options": ["Richtig", "Falsch"],
      "correctAnswer": "Richtig",
      "explanation": "Explanation in Turkish",
      "points": 10
    },
    {
      "type": "matching",
      "questionText": "Eşleştirin (Match the following)",
      "questionTextTurkish": "",
      "matchingPairs": {
        "GermanWord1": "TurkishMeaning1",
        "GermanWord2": "TurkishMeaning2",
        "GermanWord3": "TurkishMeaning3",
        "GermanWord4": "TurkishMeaning4"
      },
      "correctAnswer": "Matches",
      "explanation": "Explanation in Turkish",
      "points": 15
    },
    {
      "type": "ordering",
      "questionText": "Kelimeleri doğru sıraya koyun.",
      "questionTextTurkish": "(Put words in correct order)",
      "options": ["Ich", "gehe", "heute", "ins", "Kino"],
      "correctAnswer": "Ich gehe heute ins Kino",
      "explanation": "Explanation in Turkish",
      "points": 15
    },
    {
      "type": "writing",
      "questionText": "GERMAN: Schreiben Sie eine E-Mail an Ihren Freund...",
      "questionTextTurkish": "(Turkish translation of writing task)",
      "correctAnswer": "Example response...",
      "explanation": "Key points to include...",
      "points": 20
    }
  ]
}
''';

      final response = await _textModel.generateContent([Content.text(prompt)]);
      final jsonText = response.text ?? '';

      return _parseQuiz(jsonText, topic, level);
    } catch (e) {
      print('Error generating quiz: $e');
      rethrow;
    }
  }

  /// Generate a quiz based on specific source materials (user documents)
  Future<Quiz> generateQuizFromContext({
    required List<String> sourceTexts,
    required String level,
  }) async {
    try {
      // Combine texts but limit length to avoid token limits (rough approximation)
      String combinedContext = sourceTexts.join('\n\n');

      // Check if any source text contains visual element indicators
      final hasVisualElements = combinedContext.contains(
        RegExp(r'\(A\)|\(B\)|\(C\)|Bild|Foto|Abbildung|siehe Bild'),
      );

      if (hasVisualElements) {
        print(
          '⚠️ Visual elements detected in source materials. Adjusting quiz generation.',
        );
        // Add warning to context
        combinedContext =
            'UYARI: Bu materyalde resim referansları var. Sadece metin tabanlı sorular oluştur.\n\n' +
            combinedContext;
      }

      if (combinedContext.length > 30000) {
        combinedContext =
            combinedContext.substring(0, 30000) + '... (truncated)';
      }

      final prompt =
          '''
IMPORTANT: You MUST respond with ONLY valid JSON. No explanations.

Create a German language quiz for Level $level based ONLY on the following study materials provided by the user.
The questions must be directly related to the vocabulary, grammar, and topics found in these texts.

CRITICAL RULES:
1. If you see references like (A), (B), (C), "Bild", "Foto", or "Abbildung", these refer to IMAGES that are NOT available
2. DO NOT create questions that require seeing images to answer
3. Only create questions based on the TEXT content that is visible
4. If the material is primarily image-based exercises, create general questions about the TOPIC instead
5. Focus on vocabulary, grammar rules, and concepts that can be understood from text alone

SOURCE MATERIALS:
"""
$combinedContext
"""

The quiz MUST contain exactly 10 questions with this mix:
- 3 Multiple Choice Questions (type: "multipleChoice")
- 2 Fill in the Blanks Questions (type: "fillInBlanks")
- 2 True/False Questions (type: "trueFalse")
- 1 Matching Question (type: "matching") - Match 4 pairs of related terms/definitions found in the text.
- 1 Ordering Question (type: "ordering") - Put words in correct order to form a sentence related to the text.
- 1 Writing Task (type: "writing") - A writing prompt related to the topics in the text.

Response format (JSON):
{
  "title": "Kişisel Çalışma Sınavı",
  "questions": [
    {
      "type": "multipleChoice",
      "questionText": "Question in German",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correctAnswer": "Option B",
      "explanation": "Explanation in Turkish",
      "points": 10
    },
    {
      "type": "fillInBlanks",
      "questionText": "Sentence with _____ blank.",
      "correctAnswer": "word",
      "explanation": "Explanation in Turkish",
      "points": 10
    },
    {
      "type": "trueFalse",
      "questionText": "Statement in German",
      "options": ["Richtig", "Falsch"],
      "correctAnswer": "Richtig",
      "explanation": "Explanation in Turkish",
      "points": 10
    },
    {
      "type": "matching",
      "questionText": "Match the following terms.",
      "matchingPairs": {
        "GermanWord1": "TurkishMeaning1",
        "GermanWord2": "TurkishMeaning2",
        "GermanWord3": "TurkishMeaning3",
        "GermanWord4": "TurkishMeaning4"
      },
      "correctAnswer": "Matches",
      "explanation": "Explanation in Turkish",
      "points": 15
    },
    {
      "type": "ordering",
      "questionText": "Put the words in the correct order.",
      "options": ["Ich", "gehe", "heute", "ins", "Kino"],
      "correctAnswer": "Ich gehe heute ins Kino",
      "explanation": "Explanation in Turkish",
      "points": 15
    },
    {
      "type": "writing",
      "questionText": "Writing prompt in Turkish",
      "correctAnswer": "Example response in German",
      "explanation": "Key points to include in Turkish",
      "points": 20
    }
  ]
}
''';

      final response = await _textModel.generateContent([Content.text(prompt)]);
      final jsonText = response.text ?? '';

      return _parseQuiz(jsonText, 'Kişisel Materyal', level);
    } catch (e) {
      print('Error generating quiz from context: $e');
      rethrow;
    }
  }

  Quiz _parseQuiz(String jsonText, String topic, String level) {
    try {
      String cleanJson = jsonText.trim();
      if (cleanJson.startsWith('```json')) {
        cleanJson = cleanJson.substring(7);
      }
      if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.substring(3);
      }
      if (cleanJson.endsWith('```')) {
        cleanJson = cleanJson.substring(0, cleanJson.length - 3);
      }
      cleanJson = cleanJson.trim();

      final Map<String, dynamic> json = jsonDecode(cleanJson);
      final List<Question> questions = [];

      if (json['questions'] != null) {
        for (final q in json['questions']) {
          questions.add(Question.fromJson(q));
        }
      }

      return Quiz(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title'] ?? '$topic Sınavı',
        topic: topic,
        level: level,
        questions: questions,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      print('Error parsing quiz JSON: $e');
      throw Exception('Sınav oluşturulurken bir hata oluştu.');
    }
  }

  /// Generate feedback based on quiz results
  Future<QuizFeedback> generateQuizFeedback({
    required Quiz quiz,
    required Map<String, dynamic> userAnswers,
    Map<String, bool>? correctnessMap,
  }) async {
    try {
      // Prepare data for AI
      final questionsData = quiz.questions.map((q) {
        final isCorrect = correctnessMap != null
            ? (correctnessMap[q.id] ?? false)
            : (userAnswers[q.id].toString().toLowerCase().trim() ==
                  q.correctAnswer.toLowerCase().trim());

        return {
          'id': q.id,
          'question': q.questionText,
          'correctAnswer': q.correctAnswer,
          'userAnswer': userAnswers[q.id] ?? 'No Answer',
          'isCorrect': isCorrect,
        };
      }).toList();

      final prompt =
          '''
IMPORTANT: You MUST respond with ONLY valid JSON. No explanations.

Act as an expert German language teacher. Analyze the student's quiz performance and provide detailed feedback.

QUIZ TOPIC: ${quiz.topic}
LEVEL: ${quiz.level}

RESULTS:
${jsonEncode(questionsData)}

⚠️ CRITICAL TOLERANCE RULE FOR MINOR ERRORS:
When analyzing answers, apply SMART TOLERANCE for minor mistakes:
- **Punctuation errors** (missing/extra punctuation marks like . , ! ?)
- **Capitalization** (lowercase vs uppercase in nouns)
- **Minor spelling** (missing/extra umlaut, ß vs ss)
- **Extra spaces** or whitespace

If the answer is SEMANTICALLY and GRAMMATICALLY correct but has these MINOR issues:
1. Mark it as "partiallyCorrect": true
2. In "minorIssues": Explain what small mistake was made
3. In "correctedAnswer": Show the perfect version
4. Still give FULL or PARTIAL credit in feedback

Example:
- User: "ich gehe zur schule" (lowercase)
- Correct: "Ich gehe zur Schule."
- → partiallyCorrect: true, minorIssues: "Küçük harf hatası ve noktalama eksik"

Provide a JSON response with:
1. "overallComment": A motivational summary of their performance in Turkish.
2. "weakTopics": List of specific grammar/vocabulary topics they struggled with.
3. "strongTopics": List of topics they understood well.
4. "mistakeAnalyses": Array of objects for EACH incorrect answer, containing:
   - "questionId": The ID of the question.
   - "topic": The specific grammar rule or vocabulary topic of this question.
   - "explanation": Why their answer was wrong and why the correct one is right (in Turkish).
   - "correctUsage": A simple example sentence showing correct usage.
   - "partiallyCorrect": true if semantically correct but has minor issues
   - "minorIssues": (if applicable) Description of small mistakes
   - "correctedAnswer": The perfect version of their answer
5. "answerDetails": Array for ALL answers (correct and incorrect), containing:
   - "questionId": Question ID
   - "questionText": The question
   - "userAnswer": What the student answered
   - "correctAnswer": The correct answer
   - "isCorrect": true/false
   - "partiallyCorrect": true if minor issues only
   - "minorIssues": Description of small errors (if any)
   - "explanation": Detailed explanation in Turkish
   - "topic": Grammar/vocabulary topic
6. "studyRecommendation": Specific advice on what to study next (in Turkish).

Response format (JSON):
{
  "overallComment": "...",
  "weakTopics": ["...", "..."],
  "strongTopics": ["...", "..."],
  "mistakeAnalyses": [
    {
      "questionId": "...",
      "topic": "...",
      "explanation": "...",
      "correctUsage": "...",
      "partiallyCorrect": false,
      "minorIssues": "",
      "correctedAnswer": ""
    }
  ],
  "answerDetails": [
    {
      "questionId": "...",
      "questionText": "...",
      "userAnswer": "...",
      "correctAnswer": "...",
      "isCorrect": true,
      "partiallyCorrect": false,
      "minorIssues": "",
      "explanation": "...",
      "topic": "..."
    }
  ],
  "studyRecommendation": "..."
}
''';

      final response = await _textModel.generateContent([Content.text(prompt)]);
      final jsonText = response.text ?? '';

      return _parseFeedback(jsonText);
    } catch (e) {
      print('Error generating feedback: $e');
      rethrow;
    }
  }

  QuizFeedback _parseFeedback(String jsonText) {
    try {
      String cleanJson = jsonText.trim();
      if (cleanJson.startsWith('```json')) {
        cleanJson = cleanJson.substring(7);
      }
      if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.substring(3);
      }
      if (cleanJson.endsWith('```')) {
        cleanJson = cleanJson.substring(0, cleanJson.length - 3);
      }
      cleanJson = cleanJson.trim();

      final Map<String, dynamic> json = jsonDecode(cleanJson);
      return QuizFeedback.fromJson(json);
    } catch (e) {
      print('Error parsing feedback JSON: $e');
      throw Exception('Feedback oluşturulurken bir hata oluştu.');
    }
  }

  /// Generate a short lesson for a specific topic
  Future<Lesson> generateLesson(String topic) async {
    try {
      final prompt =
          '''
IMPORTANT: You MUST respond with ONLY valid JSON. No explanations.

Act as an expert German language teacher. Create a short, clear lesson about the topic: "$topic".
The explanation should be in Turkish, easy to understand, and include examples.

Response format (JSON):
{
  "title": "$topic",
  "explanation": "Detailed explanation in Turkish...",
  "examples": [
    {"german": "Example sentence 1", "turkish": "Turkish translation 1"},
    {"german": "Example sentence 2", "turkish": "Turkish translation 2"}
  ],
  "tips": ["Tip 1", "Tip 2"]
}
''';

      final response = await _textModel.generateContent([Content.text(prompt)]);
      final jsonText = response.text ?? '';

      return _parseLesson(jsonText);
    } catch (e) {
      print('Error generating lesson: $e');
      rethrow;
    }
  }

  Lesson _parseLesson(String jsonText) {
    try {
      String cleanJson = jsonText.trim();
      if (cleanJson.startsWith('```json')) {
        cleanJson = cleanJson.substring(7);
      }
      if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.substring(3);
      }
      if (cleanJson.endsWith('```')) {
        cleanJson = cleanJson.substring(0, cleanJson.length - 3);
      }
      cleanJson = cleanJson.trim();

      final Map<String, dynamic> json = jsonDecode(cleanJson);
      return Lesson.fromJson(json);
    } catch (e) {
      print('Error parsing lesson JSON: $e');
      throw Exception('Ders oluşturulurken bir hata oluştu.');
    }
  }

  /// Check German text and provide detailed feedback
  Future<AIFeedback> checkGermanText(String text) async {
    try {
      final prompt =
          '''
IMPORTANT: You MUST respond with ONLY valid JSON. No explanations, no markdown, just pure JSON.

You are an expert German language teacher. Analyze the following German text written by a B2 level student and provide detailed feedback.

Text to analyze: "$text"

Provide comprehensive feedback including:

1. IS CORRECT - true if the text is grammatically correct and natural, false if there are errors

2. CORRECTED TEXT - If there are errors, provide the fully corrected version. If correct, leave empty.

3. ERRORS - List of all errors found. For each error:
   - errorType: "grammar", "spelling", "word_choice", or "style"
   - errorText: the incorrect part from the original text
   - correction: the correct version
   - explanation: detailed explanation in TURKISH why it's wrong
   - rule: the grammar rule name (e.g., "Akkusativ", "Perfekt", "Wortstellung")
   - examples: 2-3 example sentences showing correct usage
   - startIndex: character position where error starts in original text
   - endIndex: character position where error ends

4. SUGGESTIONS - List of 3-5 suggestions to improve the text (in TURKISH):
   - Alternative ways to express the same idea
   - More natural/native expressions
   - B2-level vocabulary suggestions
   - Style improvements

5. OVERALL FEEDBACK - General feedback about the text (in TURKISH):
   - What was done well
   - Main areas for improvement
   - Encouragement

6. SCORE - Overall score from 0-100 based on:
   - Grammar accuracy (40%)
   - Vocabulary appropriateness (30%)
   - Natural expression (20%)
   - Style and coherence (10%)

Response format (ONLY JSON):
{
  "originalText": "the original text here",
  "isCorrect": false,
  "correctedText": "Die korrigierte Version hier",
  "errors": [
    {
      "errorType": "grammar",
      "errorText": "ich gehe zu Schule",
      "correction": "ich gehe zur Schule",
      "explanation": "'zu' edatı ile 'die Schule' birleştiğinde 'zur' olur (zu + der = zur)",
      "rule": "Präposition + Artikel",
      "examples": [
        "Ich gehe zur Arbeit.",
        "Er fährt zum Bahnhof.",
        "Wir gehen zur Party."
      ],
      "startIndex": 0,
      "endIndex": 18
    }
  ],
  "suggestions": [
    "Daha resmi bir ifade için 'Ich begebe mich zur Schule' kullanabilirsiniz.",
    "'zur Schule gehen' yerine 'die Schule besuchen' de kullanılabilir.",
    "Cümleye zaman belirteci ekleyerek daha net olabilir: 'Jeden Tag gehe ich zur Schule.'"
  ],
  "overallFeedback": "Genel olarak iyi bir deneme! Edat kullanımında küçük bir hata var ama cümle yapısı doğru. B2 seviyesi için uygun kelime seçimi yapmışsınız. Devam edin!",
  "score": 85
}

IMPORTANT: 
- All explanations, suggestions, and feedback MUST be in TURKISH
- Be encouraging and constructive
- Focus on B2-level learning goals
- Provide practical examples
- If text is correct, still give suggestions for improvement
''';

      final response = await _textModel.generateContent(
        [Content.text(prompt)],
        generationConfig: GenerationConfig(
          temperature: 0.3,
          responseMimeType: 'application/json',
        ),
      );

      final feedbackText = response.text ?? '';
      print('AI Feedback Response: $feedbackText');

      final feedbackJson = json.decode(feedbackText);
      return AIFeedback.fromJson(feedbackJson);
    } catch (e) {
      print('Error checking German text: $e');
      // Return a fallback response
      return AIFeedback(
        originalText: text,
        isCorrect: false,
        errors: [],
        suggestions: ['Bir hata oluştu. Lütfen tekrar deneyin.'],
        overallFeedback: 'Analiz sırasında bir hata oluştu.',
        score: 0,
      );
    }
  }

  /// Generate educational content for dialogue activities
  /// For dialogue creation, discussion topics, conversation practice
  Future<Map<String, dynamic>> generateDialogueActivity({
    required String extractedText,
    required String mainTopic,
    required String languageLevel,
    List<Map<String, dynamic>>?
    imageDescriptions, // Kept for compatibility but NOT used
  }) async {
    try {
      // ⚠️ IMPORTANT: We DO NOT use imageDescriptions here to save API resources
      // Image analysis was already done in the initial document analysis
      // Here we focus ONLY on creating dialogue based on the CONTEXT from text

      final prompt =
          '''
IMPORTANT: You MUST respond with ONLY valid JSON. No explanations, no markdown, just pure JSON.

Sen uzman bir Almanca öğretmenisin. Öğrenci ders kitabından bir diyalog aktivitesi belgesi yükledi.

📖 **ADIM 1: SAYFAYI DİKKATLİCE OKU VE ANALİZ ET**

Belgedeki metni ÇOK DİKKATLİ oku ve şunları tespit et:

1️⃣ **SAYFA YAPISINI ANLA:**
   - Üstte ne var? (Resimler mi? Başlık mı?)
   - Ortada ne var? (Kelime listesi mi? Talimat mı?)
   - Altta ne var? (Aktivite talimatı mı? Sorular mı?)

2️⃣ **VERİLEN KELİMELERİ/İFADELERİ TESPİT ET:**
   ⚠️ ÇOK ÖNEMLİ! Belgede genellikle şu şekilde kelimeler verilir:
   - "Redemittel" (Konuşma kalıpları)
   - "Wortschatz" (Kelime listesi)
   - "Nützliche Ausdrücke" (Faydalı ifadeler)
   - Madde işaretleri ile liste halinde kelimeler
   - Kutular içinde örnek cümleler
   
   Bu kelimeleri/ifadeleri NOT AL - bunları diyaloglarda KULLANACAKSIN!

3️⃣ **AKTİVİTE TALİMATINI ANLAintiıMA:**
   Şu talimatları ara:
   - "Sprechen Sie..." (Konuşun...)
   - "Erzählen Sie..." (Anlatın...)
   - "Diskutieren Sie..." (Tartışın...)
   - "Bilden Sie Dialoge..." (Diyalog oluşturun...)
   - "Verwenden Sie..." (Kullanın...)
   
   TALİMAT NE İSTİYOR? → Öğrenciler NE YAPACAK?

4️⃣ **KONUYU BELİRLE:**
   Sayfa hangi konu hakkında? (Berufe, Arbeitsunfall, Bewerbung, Gesundheit, vs.)

📖 **BELGE İÇERİĞİ:**
"""
$extractedText
"""

**KONU:** $mainTopic
**SEVİYE:** $languageLevel

---

🎯 **ADIM 2: AKTİVİTE TİPİNİ ANLA**

Bu aktivite ÇOK MUHTEMEL şunlardan BİRİ:

**TİP A: VERİLEN KELİMELERLE DİYALOG OLUŞTURMA**
- Belgede kelime listesi/ifadeler VAR
- Talimat: "Bu kelimelerle diyalog yapın" veya "Verwenden Sie diese Redemittel"
- Öğrenciler verilen kelimeleri KULLANARAK diyalog yapacak
→ SENİN GÖREVİN: Verilen kelimeleri MUTLAKA kullanarak örnek diyaloglar yaz!

**TİP B: KİŞİSEL DENEYİM PAYLAŞIMI**
- Talimat: "Kendi deneyiminizi paylaşın" veya "Erzählen Sie über Ihre Erfahrung"
- Öğrenciler HAYALİ/KURGUSAL bir senaryoyu birinci şahıstan anlatacak
→ SENİN GÖREVİN: "Ben böyle bir şey yaşadım..." tarzı kişisel diyaloglar yaz!

**TİP C: KONU TARTIŞMASI**
- Talimat: "Konuşun", "Tartışın" veya "Diskutieren Sie"
- Öğrenciler bir konu hakkında fikir alışverişi yapacak
→ SENİN GÖREVİN: Doğal tartışma diyalogları yaz!

---

🛠️ **ADIM 3: DİYALOG OLUŞTUR**

**ÇOK ÖNEMLİ KURALLAR:**

✅ **EĞER BELGEDE KELİME LİSTESİ VARSA:**
   - Bu kelimeleri/ifadeleri MUTLAKA diyaloglarda kullan!
   - Her kelime en az 1 diyalogda geçmeli
   - Doğal bir şekilde yerleştir

✅ **EĞER TALİMAT "KENDİ DENEYİMİNİZ" DİYORSA:**
   - Öğrenciler BİRİNCİ ŞAHIS kullanacak: "Ich...", "Mir...", "Mein..."
   - KURGUSAL ama GERÇEKÇİ senaryolar yaz
   - RESİMLERDEKİ kişileri ANLATMA! Öğrencilerin kendi hikayesi olmalı

✅ **DOĞAL VE PRATİK DİYALOGLAR:**
   - Günlük konuşma gibi
   - Kısa ve öz cümleler
   - Gerçek hayattan sahneler

❌ **YAPMA:**
   - "Bu resimler hakkında konuşalım" - HAYIR!
   - "Bu fotoğraftaki kişi..." - HAYIR!
   - Verilen kelimeleri kullanmamak - HAYIR!

---

**JSON FORMATINDA YANIT VER (SADECE JSON):**
{
"activityType": "Aktivite türü: kelime_kullanımı_diyaloğu | kişisel_deneyim_paylaşımı | konu_tartışması",
"activityDescription": "Öğrenciden BELGEDE ne isteniyor? (Türkçe, ayrıntılı açıklama). Örn: 'Sayfa 23'teki Redemittel'leri kullanarak iş görüşmesi hakkında diyalog oluşturacaklar' veya 'Kendi iş kazası deneyimlerini (kurgusal) paylaşacaklar'",
"providedVocabulary": [
  "Belgede VERİLEN kelimeler/ifadeler listesi (Almanca). EĞER kelime listesi varsa buraya ekle, yoksa boş bırak"
],
"learningObjectives": [
  "Öğrenme hedefi 1 (Türkçe)",
  "Öğrenme hedefi 2 (Türkçe)"
],
"keyVocabulary": [
  {
    "german": "Belgede VERİLEN Almanca kelime/ifade",
    "turkish": "Türkçe anlamı",
    "example": "Bu kelimeyi kullanarak örnek cümle (Almanca)",
    "usage": "Ne zaman kullanılır (Türkçe)"
  }
],
"exampleDialogues": [
  {
    "title": "Diyalog başlığı (Türkçe)",
    "dialogue": [
      {"speaker": "Öğrenci A / Person A", "text": "Almanca metin - EĞER KELİME LİSTESİ VARSA O KELİMELERİ KULLAN!"},
      {"speaker": "Öğrenci B / Person B", "text": "Almanca metin"},
      {"speaker": "Öğrenci A", "text": "Almanca metin"},
      {"speaker": "Öğrenci B", "text": "Almanca metin"}
    ],
    "translation": "Diyalogun Türkçe çevirisi",
    "notes": "Bu diyalogda HANGİ VERİLEN KELİMELER kullanıldı? Listele. (Türkçe), örn: 'ich möchte mich bewerben, Könnten Sie mir sagen..., vs. kelimeleri kullanıldı'"
  }
],
"practicePrompts": [
  "Öğrenciye pratik önerisi (Türkçe), örn: 'Verilen Redemittel'leri kullanarak kendi diyalogunuzu oluşturun'"
],
"culturalNotes": "Kültürel bağlam (Türkçe)",
"grammarPoints": [
  {
    "point": "Dilbilgisi konusu",
    "explanation": "Açıklama (Türkçe)",
    "examples": ["Örnek 1", "Örnek 2"]
  }
],
"completedExamples": "Tamamlanmış örnekler (Türkçe)"
}

---

**KONTROL LİSTESİ - YANIT VERMEDEN ÖNCE KONTROL ET:**

□ Belgede verilen KELİME LİSTESİNİ tespit ettim mi?
□ Bu kelimeleri diyaloglarda KULLANDIM MI?
□ Aktivite talimatını DOĞRU anladım mı?
□ Diyaloglar DOĞAL ve GERÇEKÇİ mi?
□ Eğer "kişisel deneyim" isteniyorsa, BİRİNCİ ŞAHIS kullandım mı?
□ RESİMLERİ ANLATMADIM, sadece KONUYU kullandım mı?

**ÇOK ÖNEMLİ HATIRLATMALAR:**
- BELGEDE VERİLEN KELİMELERİ/İFADELERİ MUTLAKA KULLAN!
- Sayfanın tamamını OKU - üst, orta, alt her yeri!
- Verilen "Redemittel", "Wortschatz", "Nützliche Ausdrücke" gibi kutuları ATLAMA!
- Diyaloglarda bu kelimeleri DOĞAL bir şekilde yerleştir!
- TÜM açıklamalar TÜRKÇE!
''';

      final response = await _textModel.generateContent(
        [Content.text(prompt)],
        generationConfig: GenerationConfig(
          temperature: 0.7,
          responseMimeType: 'application/json',
        ),
      );

      final resultText = response.text ?? '';
      print('Dialogue Activity Response: $resultText');

      return json.decode(resultText) as Map<String, dynamic>;
    } catch (e) {
      print('Error generating dialogue activity: $e');
      return {
        'activityType': 'error',
        'activityDescription':
            'Diyalog aktivitesi oluşturulurken bir hata oluştu: $e',
        'providedVocabulary': [],
        'learningObjectives': [],
        'keyVocabulary': [],
        'exampleDialogues': [],
        'practicePrompts': [],
        'culturalNotes': '',
        'grammarPoints': [],
        'completedExamples': '',
      };
    }
  }

  /// Generate solutions and explanations for exercise activities
  /// For fill-in-blanks, matching, completion exercises, image-based questions, etc.
  Future<Map<String, dynamic>> generateExerciseSolution({
    required String extractedText,
    required String mainTopic,
    required String languageLevel,
  }) async {
    try {
      final prompt =
          '''
IMPORTANT: You MUST respond with ONLY valid JSON. No explanations, no markdown, just pure JSON.

Sen uzman bir Almanca öğretmenisin. Öğrenci ders kitabından bir alıştırma belgesi yükledi.

**GÖREVİN:**
1. Belgede bulunan SORULARI oku ve anla
2. Her soru için DOĞRU CEVABI bul  
3. Her cevap için **NEDEN bu cevabın doğru olduğunu AÇIKLA**
4. Öğrencinin anlaması için **BASİT ve NET açıklamalar** yap

**BELGE İÇERİĞİ:**
"""
$extractedText
"""

**KONU:** $mainTopic
**SEVİYE:** $languageLevel

**ÖNEMLİ NOTLAR:**
- Alıştırma TÜRLERİ değişkenlik gösterebilir: boşluk doldurma, eşleştirme, çoktan seçmeli, resim tabanlı sorular, cümle tamamlama, kelime sıralama vb.
- Belgede zaten sorular yazıyor - sen sadece ÇÖZMEK zorundasın
- SADECE soruları çöz, gereksiz dilbilgisi dersi verme
- Her cevabın NEDEN doğru olduğunu BASİT bir şekilde AÇIKLA

**JSON FORMATINDA YANIT VER (SADECE JSON):**
{
  "exerciseType": "Alıştırma türü (boşluk_doldurma, eşleştirme, çoktan_seçmeli, resim, tamamlama, sıralama vb.)",
  "exerciseDescription": "Bu alıştırmanın ne olduğunu KISA açıkla (Türkçe)",
  "solutions": [
    {
      "questionNumber": 1,
      "question": "Sorunun tam metni",
      "correctAnswer": "Doğru cevap",
      "explanation": "Bu cevabın NEDEN doğru olduğunun DETAYLI açıklaması (Türkçe). Öğrenci anlamalı.",
      "grammarRule": "Hangi dilbilgisi kuralı test ediliyor (varsa)",
      "additionalNotes": "Ekstra notlar veya ipuçları (varsa)"
    }
  ],
  "overallExplanation": "Genel olarak bu alıştırmanın amacı ve öğrenciye öneriler (Türkçe)",
  "completedVersion": "Tamamlanmış alıştırmanın tam versiyonu (tüm cevaplar doldurulmuş halde)"
}

**ÇOK ÖNEMLİ:**
- TÜM açıklamalar TÜRKÇE olmalı
- Her cevap için NEDEN doğru olduğunu AÇIKLA
- BASİT ve ANLAŞILIR dil kullan
- Öğrenci EZBERLEMESİN, ANLASIN
- Sorular resimle ilgiliyse, resim açıklamalarını da kullan
''';

      final response = await _textModel.generateContent(
        [Content.text(prompt)],
        generationConfig: GenerationConfig(
          temperature: 0.3,
          responseMimeType: 'application/json',
        ),
      );

      final resultText = response.text ?? '';
      print('Exercise Solution Response: $resultText');

      return json.decode(resultText) as Map<String, dynamic>;
    } catch (e) {
      print('Error generating exercise solution: $e');
      return {
        'exerciseType': 'error',
        'exerciseDescription': 'Çözüm oluşturulurken bir hata oluştu.',
        'solutions': [],
        'overallExplanation': '',
        'completedVersion': '',
      };
    }
  }

  /// Generate enhanced grammar explanation with focus on fast, memorable learning
  /// Uses visual thinking, tables, patterns, and common mistakes
  Future<Map<String, dynamic>> generateEnhancedGrammarExplanation({
    required String extractedText,
    required String mainTopic,
    required String languageLevel,
    List<Map<String, dynamic>>?
    imageDescriptions, // Kept for compatibility but NOT used
  }) async {
    try {
      // ⚠️ IMPORTANT: We DO NOT use imageDescriptions here to save API resources
      // Image analysis was already done in the initial document analysis

      final prompt =
          '''
IMPORTANT: You MUST respond with ONLY valid JSON. No explanations, no markdown, just pure JSON.

Sen uzman bir Almanca öğretmenisin. Bu grameri HIZLI VE AKILDA KALICI şekilde öğret.

**BELGE:**
"""
$extractedText
"""
**KONU:** $mainTopic
**SEVİYE:** $languageLevel

**GÖREV:** Kısa, görsel, akılda kalıcı gramer anlatımı yap.

**JSON YANIT:**
{
  "grammarTopic": "Gramer konusu (kısa)",
  "quickSummary": "Tek cümlede özet",
  "teachingMethod": "Yöntem (tablo/şema/kalıp)",
  "visualSchema": "Text-based şema (kısa, anlaşılır)",
  "coreRules": [
    {"rule": "Kural", "explanation": "Türkçe açıklama", "pattern": "Örnek kalıp"}
  ],
  "examplePatterns": [
    {"pattern": "Kalıp", "examples": ["Örnek 1", "Örnek 2"], "translation": "Türkçe"}
  ],
  "comparisonTable": {
    "title": "Başlık",
    "headers": ["Sütun1", "Sütun2"],
    "rows": [["Veri1", "Veri2"]]
  },
  "commonMistakes": [
    {"mistake": "❌ Yanlış", "why": "Neden", "correct": "✅ Doğru", "tip": "İpucu"}
  ],
  "quickTips": ["💡 İpucu 1", "💡 İpucu 2"],
  "practicePrompts": ["Pratik 1", "Pratik 2"],
  "memoryTricks": ["🧠 Ezber tekniği 1"]
}

**ÖNEMLI:** KISA yaz, HIZLI cevap ver, TÜM açıklamalar TÜRKÇE!
''';

      final response = await _textModel.generateContent(
        [Content.text(prompt)],
        generationConfig: GenerationConfig(
          temperature: 0.7,
          responseMimeType: 'application/json',
        ),
      );

      final resultText = response.text ?? '';
      print('Enhanced Grammar Explanation Response: $resultText');

      return json.decode(resultText) as Map<String, dynamic>;
    } catch (e) {
      print('Error generating enhanced grammar explanation: $e');
      return {
        'grammarTopic': 'Gramer açıklaması oluşturulurken hata oluştu',
        'quickSummary': 'Bir hata oluştu: $e',
        'teachingMethod': 'error',
        'visualSchema': '',
        'coreRules': [],
        'examplePatterns': [],
        'comparisonTable': {'title': '', 'headers': [], 'rows': []},
        'commonMistakes': [],
        'quickTips': [],
        'practicePrompts': [],
        'memoryTricks': [],
      };
    }
  }

  /// Generic content generation for flexible AI interactions
  Future<dynamic> generateContent({
    required String prompt,
    double temperature = 0.7,
    String responseFormat = 'application/json',
  }) async {
    try {
      final response = await _textModel.generateContent(
        [Content.text(prompt)],
        generationConfig: GenerationConfig(
          temperature: temperature,
          responseMimeType: responseFormat,
        ),
      );

      final responseText = response.text ?? '{}';

      // Clean and parse JSON
      String cleanedText = responseText.trim();
      if (cleanedText.startsWith('```json')) {
        cleanedText = cleanedText.substring(7);
      }
      if (cleanedText.startsWith('```')) {
        cleanedText = cleanedText.substring(3);
      }
      if (cleanedText.endsWith('```')) {
        cleanedText = cleanedText.substring(0, cleanedText.length - 3);
      }
      cleanedText = cleanedText.trim();

      return jsonDecode(cleanedText) as Map<String, dynamic>;
    } catch (e) {
      print('Error in generateContent: $e');
      return {};
    }
  }
}

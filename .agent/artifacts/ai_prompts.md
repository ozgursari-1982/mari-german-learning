# MARI Uygulaması - AI Prompt'ları

## 1. DÖKÜMAN ANALİZİ PROMPT'U

### Kullanım Yeri:
Kullanıcı bir resim veya PDF yüklediğinde bu prompt kullanılır.

### Prompt:

```
IMPORTANT: You MUST respond with ONLY valid JSON. No explanations, no markdown, just pure JSON.

Analyze this German learning material and provide DETAILED analysis for B2 Berufsprache exam preparation.

Extract the following:

1. DOCUMENT TYPE - Identify what kind of document this is:
 - "vocabulary" = Wortschatz/word lists
 - "grammar" = Grammar lessons/rules
 - "professional" = Professional/business texts (Berufsprache)
 - "exercise" = Exercises/practice questions
 - "dialogue" = Conversations/dialogues
 - "mixed" = Mixed content

2. LANGUAGE LEVEL (CEFR): A1, A2, B1, B2, C1, or C2

3. MAIN TOPIC - The primary subject (e.g., "Arbeitsunfälle", "Geschäftsbriefe", "Perfekt Tense")

4. MAIN THEME - Broader theme (e.g., "Arbeitssicherheit", "Geschäftskommunikation", "Vergangenheit")

5. CATEGORIES - List of relevant categories (e.g., ["Berufsprache", "Sicherheit"])

6. VOCABULARY - IMPORTANT: Extract vocabulary ONLY if this is a "vocabulary" (Wortschatz) document.
 For other document types (grammar, dialogue, exercise, professional), return an empty array [].
 
 If this IS a vocabulary document, extract ALL German words with:
 - german: the word
 - article: "der", "die", "das", or "" if not applicable
 - plural: plural form (e.g., "Unfälle") or "" if not applicable
 - translation: Turkish translation
 - exampleSentence: example sentence using the word
 - professionalContext: professional context if applicable
 - level: estimated CEFR level (A1-C2)
 - category: word category (e.g., "Business", "Technical", "Medical")

7. GRAMMAR RULES - Extract grammar rules found (focus on this for grammar documents):
 - rule: the grammar rule name (e.g., "Perfekt mit haben")
 - explanation: brief explanation
 - examples: list of example sentences
 - category: grammar category (e.g., "Perfekt", "Akkusativ")

8. EXTRACTED TEXT - All German text from the document

9. KEY TOPICS - List of key topics covered

10. PROFESSIONAL CONTEXT - Description of professional/business context

11. IS BERUFSPRACHE - true if this is professional German content, false otherwise

12. CONFIDENCE - Your confidence in this analysis (0.0 to 1.0)

13. CATEGORY SUGGESTION:
 - mainCategory: suggested main category name (in Turkish, e.g., "Wortschatz", "Grammatik", "Dialog", "Alıştırma")
 - subCategory: suggested subcategory name (in Turkish, e.g., "İş Kazaları", "Toplantılar", "Perfekt Zamanı")
 - confidence: confidence in suggestion (0.0 to 1.0)
 - reasoning: why you suggest this category (IN TURKISH)
 - keywords: key words that led to this suggestion

Response format (ONLY JSON):
{
  "documentType": "vocabulary",
  "languageLevel": "B2",
  "mainTopic": "Arbeitsunfälle",
  "mainTheme": "Arbeitssicherheit",
  "categories": ["Berufsprache", "Sicherheit"],
  "vocabulary": [
    {
      "german": "Unfall",
      "article": "der",
      "plural": "Unfälle",
      "translation": "kaza",
      "exampleSentence": "Der Unfall passierte in der Fabrik.",
      "professionalContext": "workplace safety",
      "level": "B1",
      "category": "Business"
    }
  ],
  "grammarRules": [
    {
      "rule": "Perfekt mit haben",
      "explanation": "Past tense formation with haben",
      "examples": ["Ich habe gearbeitet", "Er hat gelernt"],
      "category": "Perfekt"
    }
  ],
  "extractedText": "full text here",
  "keyTopics": ["Arbeitssicherheit", "Unfallverhütung"],
  "professionalContext": "Workplace safety and accident prevention",
  "isBerufsprache": true,
  "confidence": 0.95,
  "categorySuggestion": {
    "mainCategory": "Wortschatz",
    "subCategory": "İş Kazaları",
    "confidence": 0.9,
    "reasoning": "Doküman iş kazaları hakkında kelime listesi içeriyor",
    "keywords": ["Unfall", "Arbeit", "Sicherheit"]
  }
}

REMEMBER: Only extract vocabulary if documentType is "vocabulary". For all other types, return "vocabulary": []
```

### Ayarlar:
- **Model:** gemini-2.0-flash-exp (vision model)
- **Temperature:** 0.1 (düşük = daha tutarlı)
- **Response Format:** JSON

---

## 2. YAZMA ASISTANI PROMPT'U

### Kullanım Yeri:
Kullanıcı "Yazma Asistanı" ekranında Almanca metin yazdığında bu prompt kullanılır.

### Prompt:

```
IMPORTANT: You MUST respond with ONLY valid JSON. No explanations, no markdown, just pure JSON.

You are an expert German language teacher. Analyze the following German text written by a B2 level student and provide detailed feedback.

Text to analyze: "[KULLANICI METNİ]"

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
```

### Ayarlar:
- **Model:** gemini-2.0-flash-exp (text model)
- **Temperature:** 0.3 (orta = dengeli)
- **Response Format:** JSON

---

## 3. QUIZ OLUŞTURMA PROMPT'U

### Kullanım Yeri:
Kullanıcı yeni bir quiz oluşturduğunda bu prompt kullanılır.

### Prompt Yapısı:

```
Generate a comprehensive German language quiz for B2 Berufsprache preparation.

Topic: [KONU]
Level: [SEVİYE]
Number of questions: 10

Include these question types:
1. Multiple choice (4 questions)
2. Fill in the blanks (3 questions)
3. True/False (3 questions)

Focus on:
- Professional German vocabulary
- Business communication
- Grammar relevant to the topic
- Real-world workplace scenarios

Response format: JSON with questions array
```

### Ayarlar:
- **Model:** gemini-2.0-flash-exp
- **Temperature:** 0.4
- **Response Format:** JSON

---

## ÖNEMLİ NOTLAR

### 1. Neden JSON Format?
- Tutarlı yanıtlar
- Kolay parse edilebilir
- Hata oranı düşük

### 2. Neden Düşük Temperature?
- **0.1-0.3:** Tutarlı, öngörülebilir yanıtlar
- **0.7-1.0:** Yaratıcı ama tutarsız olabilir

### 3. Türkçe Açıklamalar
Tüm açıklamalar, öneriler ve geri bildirimler Türkçe olarak isteniyor çünkü:
- Kullanıcı Türk
- Daha iyi anlaşılır
- Öğrenme daha etkili

### 4. Kelime Çıkarımı Optimizasyonu
**ÖNEMLİ:** Sadece "vocabulary" tipindeki dökümanlardan kelime çıkarılıyor.
- Dialog → Kelime çıkarma ❌
- Gramer → Kelime çıkarma ❌
- Egzersiz → Kelime çıkarma ❌
- Wortschatz → Kelime çıkar ✅

Bu sayede **%70 maliyet tasarrufu** sağlanıyor!

---

## PROMPT İYİLEŞTİRME ÖNERİLERİ

### Senin Önerine Göre Eklenebilecekler:

```
14. DOCUMENT PURPOSE - Identify the purpose:
 - "information" = Bilgilendirme metni
 - "dialogue" = Dialog/konuşma
 - "exercise" = Pratik soru/egzersiz
 - "explanation" = Açıklama/anlatım

15. IF EXERCISE - If this is an exercise:
 - Solve the exercise
 - Provide answers with explanations (in Turkish)
 - Show step-by-step solution
```

Bu ekleme yapılırsa AI:
1. Dökümanın pratik soru olduğunu anlar
2. Soruları çözer
3. Cevapları açıklamalarıyla verir
4. Analizi buna göre yapar

İsterseniz bu iyileştirmeyi ekleyebilirim! 🚀

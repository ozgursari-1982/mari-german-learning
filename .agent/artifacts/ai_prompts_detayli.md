# MARI Uygulaması - AI Prompt'ları Detaylı Açıklama

## 🎯 PROMPT NEDİR?

**Basit Açıklama:** 
Prompt, yapay zekaya verdiğimiz talimatlardır. Tıpkı bir çalışana iş tarifi verir gibi, yapay zekaya "şunu şöyle yap" diye söyleriz.

**Örnek:**
- ❌ Kötü prompt: "Bu resmi analiz et"
- ✅ İyi prompt: "Bu resimde Almanca kelimeler var. Kelimeleri bul, Türkçe karşılıklarını yaz, örnek cümleler ver"

---

## 📄 1. DÖKÜMAN ANALİZİ PROMPT'U

### Ne Zaman Kullanılır?
Sen uygulamaya bir resim veya PDF yüklediğinde bu prompt devreye girer.

### Ne İster?

#### Adım 1: Döküman Tipini Belirle
Yapay zekaya şunu söyleriz:
> "Bu döküman ne tür bir şey? Kelime listesi mi, gramer kuralları mı, dialog mu, yoksa alıştırma mı?"

**Olası Tipler:**
- **"vocabulary"** = Wortschatz (kelime listesi)
- **"grammar"** = Gramer kuralları
- **"professional"** = İş Almancası metni
- **"exercise"** = Alıştırma soruları
- **"dialogue"** = Konuşma/dialog
- **"mixed"** = Karışık içerik

**Örnek:**
```
Resimde: "Wortschatz - Arbeitsunfälle"
AI'nın Cevabı: "vocabulary" (kelime listesi)
```

---

#### Adım 2: Seviye Belirle
> "Bu döküman hangi seviyede? A1, A2, B1, B2, C1, C2?"

**Örnek:**
```
Döküman: İş kazaları hakkında profesyonel kelimeler
AI'nın Cevabı: "B2" (çünkü profesyonel kelimeler)
```

---

#### Adım 3: Ana Konu Bul
> "Bu dökümanın ana konusu ne?"

**Örnek:**
```
Döküman: İş kazaları kelimeleri
AI'nın Cevabı: "Arbeitsunfälle" (İş Kazaları)
```

---

#### Adım 4: Genel Tema Bul
> "Daha geniş tema ne?"

**Örnek:**
```
Ana Konu: Arbeitsunfälle
Genel Tema: "Arbeitssicherheit" (İş Güvenliği)
```

---

#### Adım 5: Kategoriler Belirle
> "Bu döküman hangi kategorilere girer?"

**Örnek:**
```
AI'nın Cevabı: ["Berufsprache", "Sicherheit", "Arbeit"]
```

---

#### Adım 6: KELİMELERİ ÇIKAR (ÇOK ÖNEMLİ!)

**ÖNEMLİ KURAL:** 
Sadece "vocabulary" (kelime listesi) tipindeki dökümanlardan kelime çıkar. Diğerlerinden ÇIKARMA!

**Neden?**
- Dialog'dan kelime çıkarırsan → Gereksiz maliyet
- Gramer dökümanından kelime çıkarırsan → Gereksiz maliyet
- Sadece Wortschatz'tan çıkar → %70 tasarruf!

**Eğer Kelime Listesi İse, Her Kelime İçin:**

1. **german** = Almanca kelime
   - Örnek: "Unfall"

2. **article** = Artikel (der, die, das)
   - Örnek: "der"

3. **plural** = Çoğul hali
   - Örnek: "Unfälle"

4. **translation** = Türkçe karşılık
   - Örnek: "kaza"

5. **exampleSentence** = Örnek cümle
   - Örnek: "Der Unfall passierte in der Fabrik."

6. **professionalContext** = İş bağlamı
   - Örnek: "workplace safety"

7. **level** = Kelime seviyesi
   - Örnek: "B1"

8. **category** = Kelime kategorisi
   - Örnek: "Business"

**Sonuç:**
```json
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
```

---

#### Adım 7: GRAMER KURALLARI ÇIKAR

Eğer döküman gramer içeriyorsa:

1. **rule** = Gramer kuralı adı
   - Örnek: "Perfekt mit haben"

2. **explanation** = Kısa açıklama
   - Örnek: "Geçmiş zaman oluşturma"

3. **examples** = Örnek cümleler
   - Örnek: ["Ich habe gearbeitet", "Er hat gelernt"]

4. **category** = Gramer kategorisi
   - Örnek: "Perfekt"

---

#### Adım 8: METNİ ÇIKAR
> "Dökümanın tüm Almanca metnini çıkar"

---

#### Adım 9: ANA KONULARI BUL
> "Bu dökümanın ana konuları neler?"

**Örnek:**
```
["Arbeitssicherheit", "Unfallverhütung", "Erste Hilfe"]
```

---

#### Adım 10: PROFESYONEL BAĞLAM
> "Bu döküman iş hayatıyla ilgili mi? Nasıl bir bağlamda?"

**Örnek:**
```
"Workplace safety and accident prevention in industrial settings"
```

---

#### Adım 11: BERUFSPRACHE Mİ?
> "Bu profesyonel Almanca mı?"

**Örnek:**
```
true (evet, iş Almancası)
```

---

#### Adım 12: GÜVENİLİRLİK
> "Bu analizine ne kadar eminsin? 0-1 arası"

**Örnek:**
```
0.95 (çok emin)
```

---

#### Adım 13: KATEGORİ ÖNERİSİ

AI'ya şunu söyleriz:
> "Bu dökümanı hangi kategoriye koymalıyım? Neden?"

**Döndürdüğü Bilgiler:**

1. **mainCategory** = Ana kategori (Türkçe)
   - Örnek: "Wortschatz"

2. **subCategory** = Alt kategori (Türkçe)
   - Örnek: "İş Kazaları"

3. **confidence** = Emin olma derecesi
   - Örnek: 0.9

4. **reasoning** = Neden bu kategori? (Türkçe)
   - Örnek: "Doküman iş kazaları hakkında kelime listesi içeriyor"

5. **keywords** = Anahtar kelimeler
   - Örnek: ["Unfall", "Arbeit", "Sicherheit"]

---

### SONUÇ ÖRNEK:

```json
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
  "categorySuggestion": {
    "mainCategory": "Wortschatz",
    "subCategory": "İş Kazaları",
    "confidence": 0.9,
    "reasoning": "Doküman iş kazaları hakkında kelime listesi içeriyor"
  }
}
```

---

## ✍️ 2. YAZMA ASISTANI PROMPT'U

### Ne Zaman Kullanılır?
Sen "Yazma Asistanı" ekranında Almanca bir cümle yazdığında bu prompt devreye girer.

### Ne İster?

#### Adım 1: DOĞRU MU YANLIŞ MI?
> "Bu metin gramatik olarak doğru mu?"

**Örnek:**
```
Metin: "Ich gehe zu Schule"
AI'nın Cevabı: false (yanlış)
```

---

#### Adım 2: DÜZELTİLMİŞ HALİ
> "Eğer yanlışsa, doğru hali ne?"

**Örnek:**
```
Yanlış: "Ich gehe zu Schule"
Doğru: "Ich gehe zur Schule"
```

---

#### Adım 3: HATALARI BUL VE AÇIKLA

Her hata için AI şunları verir:

1. **errorType** = Hata tipi
   - "grammar" = Gramer hatası
   - "spelling" = Yazım hatası
   - "word_choice" = Kelime seçimi hatası
   - "style" = Stil hatası

2. **errorText** = Yanlış olan kısım
   - Örnek: "zu Schule"

3. **correction** = Doğru hali
   - Örnek: "zur Schule"

4. **explanation** = Türkçe açıklama
   - Örnek: "'zu' edatı ile 'die Schule' birleştiğinde 'zur' olur (zu + der = zur)"

5. **rule** = Gramer kuralı
   - Örnek: "Präposition + Artikel"

6. **examples** = Doğru kullanım örnekleri
   ```
   - "Ich gehe zur Arbeit."
   - "Er fährt zum Bahnhof."
   - "Wir gehen zur Party."
   ```

7. **startIndex** = Hatanın başladığı karakter
   - Örnek: 10

8. **endIndex** = Hatanın bittiği karakter
   - Örnek: 19

**Sonuç:**
```json
{
  "errorType": "grammar",
  "errorText": "zu Schule",
  "correction": "zur Schule",
  "explanation": "'zu' edatı ile 'die Schule' birleştiğinde 'zur' olur",
  "rule": "Präposition + Artikel",
  "examples": [
    "Ich gehe zur Arbeit.",
    "Er fährt zum Bahnhof."
  ]
}
```

---

#### Adım 4: İYİLEŞTİRME ÖNERİLERİ

AI 3-5 öneri verir (Türkçe):

**Örnek Öneriler:**
1. "Daha resmi bir ifade için 'Ich begebe mich zur Schule' kullanabilirsiniz."
2. "'zur Schule gehen' yerine 'die Schule besuchen' de kullanılabilir."
3. "Cümleye zaman belirteci ekleyerek daha net olabilir: 'Jeden Tag gehe ich zur Schule.'"

---

#### Adım 5: GENEL GERİ BİLDİRİM

AI genel bir değerlendirme yapar (Türkçe):

**Örnek:**
```
"Genel olarak iyi bir deneme! Edat kullanımında küçük bir hata var 
ama cümle yapısı doğru. B2 seviyesi için uygun kelime seçimi 
yapmışsınız. Devam edin!"
```

---

#### Adım 6: PUAN VER (0-100)

AI şu kriterlere göre puan verir:

- **%40** = Gramer doğruluğu
- **%30** = Kelime uygunluğu
- **%20** = Doğal ifade
- **%10** = Stil ve tutarlılık

**Örnek:**
```
Puan: 85/100
```

---

### TAM ÖRNEK:

**Senin Yazdığın:**
```
"Ich gehe zu Schule jeden Tag weil ich möchte lernen Deutsch."
```

**AI'nın Verdiği:**
```json
{
  "originalText": "Ich gehe zu Schule jeden Tag weil ich möchte lernen Deutsch.",
  "isCorrect": false,
  "correctedText": "Ich gehe jeden Tag zur Schule, weil ich Deutsch lernen möchte.",
  "errors": [
    {
      "errorType": "grammar",
      "errorText": "zu Schule",
      "correction": "zur Schule",
      "explanation": "'zu' edatı 'die Schule' ile birleşince 'zur' olur",
      "rule": "Präposition + Artikel"
    },
    {
      "errorType": "grammar",
      "errorText": "möchte lernen Deutsch",
      "correction": "Deutsch lernen möchte",
      "explanation": "Modalverb cümlesinde infinitiv (lernen) cümle sonuna gider",
      "rule": "Modalverben Satzbau"
    }
  ],
  "suggestions": [
    "Virgül kullanımına dikkat et: 'weil' den önce virgül koy",
    "Kelime sırası: 'jeden Tag' cümle başına da gelebilir",
    "Daha resmi: 'Ich besuche täglich die Schule'"
  ],
  "overallFeedback": "İyi bir deneme! İki gramer hatası var ama fikrin anlaşılıyor. Edat kullanımı ve kelime sırasına dikkat et. Devam et!",
  "score": 75
}
```

---

## 🎯 3. QUIZ OLUŞTURMA PROMPT'U

### Ne Zaman Kullanılır?
Sen "Yeni Test Oluştur" dediğinde bu prompt kullanılır.

### Ne İster?

1. **Konu** = Hangi konuda test?
   - Örnek: "Perfekt Tense"

2. **Seviye** = Hangi seviyede?
   - Örnek: "B2"

3. **Soru Sayısı** = Kaç soru?
   - Örnek: 10

4. **Soru Tipleri:**
   - 4 çoktan seçmeli
   - 3 boşluk doldurma
   - 3 doğru/yanlış

**AI'nın Oluşturduğu:**
```json
{
  "questions": [
    {
      "type": "multiple_choice",
      "question": "Ich ___ gestern im Büro gearbeitet.",
      "options": ["habe", "bin", "hatte", "war"],
      "correctAnswer": "habe",
      "explanation": "Perfekt zamanı 'haben' ile kurulur"
    }
  ]
}
```

---

## 🔧 TEKNİK AYARLAR

### Temperature Nedir?

**Basit Açıklama:**
Temperature, AI'nın ne kadar "yaratıcı" olacağını belirler.

- **0.1** = Çok tutarlı, her seferinde benzer cevap (döküman analizi için)
- **0.3** = Dengeli (yazma asistanı için)
- **0.7** = Yaratıcı (quiz oluşturma için)
- **1.0** = Çok yaratıcı ama tutarsız olabilir

**Örnek:**
```
Soru: "Almanya'nın başkenti neresi?"

Temperature 0.1: Her zaman "Berlin" der
Temperature 1.0: Bazen "Berlin", bazen "Başkent Berlin'dir", 
                 bazen "Berlin şehri" der
```

---

### JSON Format Nedir?

**Basit Açıklama:**
JSON, bilgisayarların anlayabileceği düzenli bir veri formatıdır.

**Örnek:**
```json
{
  "isim": "Ahmet",
  "yas": 25,
  "sehir": "İstanbul"
}
```

**Neden JSON?**
- ✅ Her zaman aynı yapıda
- ✅ Kolay işlenir
- ✅ Hata oranı düşük

---

## 💡 ÖZET

### Döküman Analizi Ne Yapar?
1. Döküman tipini belirler (kelime listesi mi, gramer mi, dialog mu?)
2. Seviyeyi tespit eder (A1-C2)
3. Sadece kelime listelerinden kelime çıkarır (%70 tasarruf!)
4. Gramer kurallarını bulur
5. Kategori önerir

### Yazma Asistanı Ne Yapar?
1. Hataları bulur
2. Doğru halini gösterir
3. Türkçe açıklama yapar
4. Örnekler verir
5. Öneriler sunar
6. Puan verir

### Quiz Oluşturucu Ne Yapar?
1. Konuya uygun sorular üretir
2. Farklı soru tipleri oluşturur
3. Doğru cevapları belirler
4. Açıklamalar ekler

---

## ❓ SORULAR?

Herhangi bir prompt hakkında daha detaylı bilgi istersen söyle! 🚀

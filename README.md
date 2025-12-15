# Mari - Almanca Öğrenme Asistanı 🎓

Mari, yapay zeka destekli kişisel Almanca öğrenme asistanınızdır. Ders notlarınızı, kitap resimlerinizi ve PDF dosyalarınızı yükleyin, yapay zeka sizin için özelleştirilmiş testler ve gramer konuları oluştursun!

## ✨ Özellikler

- 📸 **Akıllı Dosya Yükleme**: Ders notları, kitap sayfaları ve PDF dosyalarını yükleyin
- 🤖 **AI Analiz**: Google Gemini AI ile otomatik içerik analizi
- 📚 **Otomatik Kategorilendirme**: Konular otomatik olarak kategorilere ayrılır
- ✍️ **Test Oluşturma**: Yüklediğiniz içeriğe göre özelleştirilmiş testler
- 📊 **İlerleme Takibi**: Başarınızı ve eksik konularınızı görün
- 🎯 **Gramer Konu Anlatımı**: Eksik olduğunuz konularda detaylı açıklamalar
- 🌙 **Modern Dark Theme**: Göz yormayan, şık arayüz
- 🇹🇷 **Türkçe Arayüz**: Tamamen Türkçe kullanıcı deneyimi

## 🚀 Kurulum

### Gereksinimler

- Flutter SDK (3.9.2 veya üzeri)
- Android Studio / VS Code
- Android cihaz veya emülatör
- Firebase hesabı
- Google Gemini API anahtarı

### Adım 1: Projeyi Klonlayın

```bash
git clone <repository-url>
cd mari
```

### Adım 2: Bağımlılıkları Yükleyin

```bash
flutter pub get
```

### Adım 3: Firebase Kurulumu

1. [Firebase Console](https://console.firebase.google.com)'a gidin
2. Yeni proje oluşturun (örn: "mari-learning-app")
3. Android uygulaması ekleyin:
   - Package name: `com.mariapp.mari`
   - App nickname: `Mari`
4. `google-services.json` dosyasını indirin
5. Dosyayı `android/app/` klasörüne kopyalayın

#### Firebase CLI ile Kurulum (Alternatif)

```bash
# Firebase CLI'yi yükleyin (eğer yoksa)
npm install -g firebase-tools

# Firebase'e giriş yapın
firebase login

# FlutterFire CLI'yi yükleyin
dart pub global activate flutterfire_cli

# Firebase projesini yapılandırın
flutterfire configure
```

### Adım 4: Firestore ve Storage'ı Etkinleştirin

Firebase Console'da:
1. **Firestore Database** → "Create database" → Test mode
2. **Storage** → "Get started" → Test mode

### Adım 5: Gemini API Anahtarı

1. [Google AI Studio](https://makersuite.google.com/app/apikey)'ya gidin
2. API anahtarı oluşturun
3. `lib/services/gemini_service.dart` dosyasında API anahtarınızı ekleyin

### Adım 6: Uygulamayı Çalıştırın

```bash
# Android cihazınızı bağlayın veya emülatör başlatın
flutter devices

# Uygulamayı çalıştırın
flutter run
```

## 📱 Kullanım

1. **Ana Sayfa**: İstatistiklerinizi ve son aktivitelerinizi görün
2. **Yükleme Butonu** (Ortadaki yeşil buton):
   - Fotoğraf çekin veya galeriden seçin
   - PDF dosyası yükleyin
   - AI otomatik analiz eder
3. **Kategoriler**: Konularınızı kategorilere göre görüntüleyin
4. **Testler**: Oluşturulan testleri çözün
5. **Profil**: Ayarlarınızı düzenleyin

## 🛠️ Teknolojiler

- **Flutter**: Cross-platform mobil uygulama framework'ü
- **Firebase**:
  - Firestore: Veritabanı
  - Storage: Dosya depolama
- **Google Generative AI (Gemini)**: İçerik analizi ve test oluşturma
- **Provider**: State management
- **Flutter Animate**: Animasyonlar
- **Lottie**: Animasyonlu grafikler

## 📂 Proje Yapısı

```
lib/
├── main.dart                 # Uygulama giriş noktası
├── models/                   # Veri modelleri
├── screens/                  # Ekranlar
│   └── home_screen.dart     # Ana sayfa
├── widgets/                  # Özel widget'lar
│   └── animated_upload_button.dart
├── services/                 # Servisler (Firebase, AI)
├── providers/                # State management
└── utils/                    # Yardımcı dosyalar
    ├── app_colors.dart      # Renk paleti
    └── app_theme.dart       # Tema yapılandırması
```

## 🎨 Tasarım

Uygulama modern, dark green temalı bir tasarıma sahiptir:
- **Ana Renkler**: Koyu yeşil tonları (#0A2F1F, #1A4D2E)
- **Vurgu Renkleri**: Parlak neon yeşil (#4ADE80)
- **Animasyonlar**: Dönen yükleme butonu, pulsing efektler
- **Tipografi**: Modern, okunabilir fontlar

## 🔮 Gelecek Özellikler

- [ ] Spaced Repetition System (SRS)
- [ ] Sesli okuma (Text-to-Speech)
- [ ] Flashcard sistemi
- [ ] Offline mod
- [ ] Günlük hedefler ve hatırlatıcılar
- [ ] İlerleme grafikleri
- [ ] Kelime defteri
- [ ] Telaffuz pratiği

## 📝 Lisans

Bu proje kişisel kullanım içindir.

## 👨‍💻 Geliştirici

Developed with ❤️ using Flutter and AI

---

**Not**: Bu uygulama henüz geliştirme aşamasındadır. Firebase ve Gemini API kurulumunu tamamladıktan sonra tüm özellikler aktif olacaktır.

# Bisimo 🐰

**Aplikasi Pendukung Kesehatan Mental Berbasis AI untuk Siswa Tunarungu**

---

## 📋 Definisi

Bisimo adalah aplikasi pendukung kesehatan mental berbasis kecerdasan buatan (Artificial Intelligence) yang dirancang khusus untuk siswa tunarungu. Aplikasi ini berfungsi sebagai **ruang aman digital** yang menjembatani komunikasi emosional siswa dengan lingkungannya.

---

## ✨ Fitur Utama

Bisimo menggabungkan tiga teknologi utama untuk mendukung kesejahteraan emosional siswa:

### 1. 🎥 Deteksi Emosi & BISINDO
- Membaca ekspresi wajah dan bahasa isyarat (Bisindo) siswa secara real-time dengan kamera
- Mendeteksi kondisi emosional pengguna secara akurat
- Memberikan feedback visual yang responsif

### 2. 💬 Konsultasi Emosional
- Fitur chatbot cerdas yang mampu memberikan respons empatetik
- Validasi perasaan dan saran penenangan diri
- Dukungan emosional 24/7 yang aman dan personal

### 3. 👁️ Sistem Pemantauan (Monitoring)
- Akses khusus bagi Wali Kelas untuk memantau kondisi emosional siswa
- Deteksi potensi krisis sejak dini
- Dashboard analytics untuk melihat tren kesejahteraan siswa

---

## 🎯 Tujuan

Bisimo dibuat untuk:
- ✅ Membantu siswa mengenali dan meregulasi emosi mereka
- ✅ Membantu pihak sekolah menciptakan lingkungan pendidikan **inklusif**
- ✅ Meningkatkan kesadaran mental health di kalangan siswa tunarungu
- ✅ Menjembatani kesenjangan komunikasi emosional

---

## 🛠️ Teknologi yang Digunakan

### Frontend & Framework
- **Flutter** 3.9.2 - Cross-platform mobile development
- **Provider** 6.1.2 - State management
- **Go Router** 14.6.2 - Navigation & routing

### Backend & Database
- **Firebase Core** 3.15.2
- **Firebase Authentication** 5.6.2 - Autentikasi pengguna
- **Cloud Firestore** 5.6.12 - Real-time database

### UI & Visualization
- **Flutter ScreenUtil** 5.9.3 - Responsive design
- **Flutter SVG** 2.0.10 - Vector graphics
- **Cached Network Image** 3.4.1 - Image caching

### Features & Utilities
- **Camera** 0.11.0+ - Akses kamera untuk deteksi emosi
- **Google Sign-In** 6.2.2 - Autentikasi Google
- **Shared Preferences** 2.3.3 - Local data storage
- **QR Code Generator** 4.1.0 - QR code untuk monitoring
- **Intl** 0.20.2 - Internationalization & localization
- **URL Launcher** 6.3.2 - Membuka URL
- **Crypto** 3.0.3 - Hashing untuk keamanan token

---

## 📱 Prototipe Desain

Lihat prototipe interaktif Bisimo di Figma:
🔗 [Bisimo Prototype - Figma](https://www.figma.com/proto/lfEiwdHPvvN49sCH6yqMV8/Bisimo?node-id=0-1&p=f&t=LGFhENmiMqkqrfEl-0&scaling=scale-down&content-scaling=fixed&starting-point-node-id=83%3A2)

---

## 🚀 Cara Menjalankan Project

### Prasyarat
- Flutter SDK 3.9.2 atau lebih baru
- Dart SDK (disertakan dengan Flutter)
- Android Studio / Xcode (untuk emulator atau device testing)
- Firebase project yang sudah dikonfigurasi

### Langkah-langkah Instalasi

1. **Clone repository**
   ```bash
   git clone https://github.com/paranroman/bisimo.git
   cd bisimo
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Konfigurasi Firebase**
   - Pastikan `google-services.json` sudah ada di `android/app/`
   - Pastikan `GoogleService-Info.plist` sudah ada di `ios/Runner/` (untuk iOS)
   - Jalankan konfigurasi Firebase untuk platform yang digunakan

4. **Jalankan aplikasi**
   ```bash
   flutter run
   ```

5. **Build untuk Production**
   - **Android:**
     ```bash
     flutter build apk
     ```
   - **iOS:**
     ```bash
     flutter build ios
     ```

---

## 📁 Struktur Project

```
bisimo/
├── lib/                          # Kode sumber utama
│   ├── app.dart                 # Main app widget
│   ├── main.dart                # Entry point
│   ├── firebase_options.dart    # Firebase configuration
│   ├── core/                    # Core utilities & helpers
│   ├── data/                    # Data layer (API, database)
│   ├── features/                # Feature modules
│   ├── providers/               # State management (Provider)
│   └── shared/                  # Shared components & utilities
├── assets/                      # Gambar, fonts, dan resources
│   ├── Fonts/                   # Custom fonts (Baloo 2, Lexend, SF Pro)
│   └── Screens/                 # Asset untuk setiap screen
├── android/                     # Konfigurasi Android
├── ios/                         # Konfigurasi iOS
├── web/                         # Web platform (optional)
├── pubspec.yaml                 # Dependencies
├── firebase.json                # Firebase config
├── firestore.rules              # Firestore security rules
└── README.md                    # File ini
```

---

## 🔐 Keamanan & Privacy

- Data pribadi disimpan secara aman di Firestore dengan security rules yang ketat
- Autentikasi menggunakan Firebase Authentication
- Data pengguna dienkripsi dan compliance dengan regulasi privasi
- Fitur monitoring hanya accessible oleh authorized Wali Kelas

---

## 👥 Target Users

- **Siswa Tunarungu** - Pengguna utama aplikasi
- **Wali Kelas/Guru** - Untuk monitoring dan support


---

## 📞 Support & Kontribusi

Untuk pertanyaan, bug reports, atau kontribusi, silakan menghubungi email bisimo:
**bisimousu@gmail.com**.

---
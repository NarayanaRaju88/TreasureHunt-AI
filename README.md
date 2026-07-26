# AI Treasure Hunt

This repository is the cleaned Flutter application base for AI Treasure Hunt.

## Repository status

- Existing Flutter application source is preserved.
- Redundant Android Gradle Kotlin DSL project files were removed.
- Unrelated sample Kotlin `org.example` application/test files were removed.
- Abacus marker file was removed.
- Firebase rules and existing project documentation are preserved.
- GitHub Actions CI was added for formatting, analysis, and tests.

## Local verification

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

Release APK/AAB builds should be verified locally before production release.

## Important

Do not commit API secrets, service-account keys, or signing keys. Review `android/app/google-services.json` and Firebase configuration before publishing to a public repository.

<div align="center">

# 🗺️ AI Treasure Hunt

### _Discover the world around you — one AI-generated treasure at a time._

**AI Treasure Hunt** is a gamified, location-based exploration app that uses **Google Gemini** to generate unique, story-rich treasures anchored to real-world places. Explore the map, unlock treasures within range, collect XP, earn badges, keep your streak alive, and take on daily AI challenges.

![Flutter](https://img.shields.io/badge/Flutter-3.19+-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.3+-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?logo=firebase&logoColor=black)
![Gemini](https://img.shields.io/badge/Google_Gemini-1.5_Flash-8E75B2?logo=google&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)
![License](https://img.shields.io/badge/License-Proprietary-lightgrey)

</div>

---

## ✨ Features

- 🤖 **AI-Generated Treasures** — Gemini 1.5 Flash creates fresh treasures, fun facts, and lore on the fly.
- 🗺️ **Live Interactive Map** — Google Maps with real-time location tracking and treasure markers.
- 📍 **Proximity Unlocking** — Treasures unlock when you physically get close enough (geofenced radius).
- 🎮 **Gamification Engine** — XP, levels, streaks, achievements, and rarity-tiered badges.
- 🏆 **Daily Challenges** — AI-curated daily quests that keep exploration fresh.
- 🧠 **AI Quiz & Stories** — Each treasure ships with a generated story and quiz question.
- 🔍 **Natural-Language Search** — Ask for places in plain English, powered by Gemini.
- ☀️ **Weather-Aware** — Live weather context for your current location.
- 🔐 **Multi-Auth** — Google Sign-In, Email/Password, and Anonymous guest mode.
- 🔔 **Push Notifications** — FCM + local notifications for reminders and nearby treasures.
- 🎨 **Glassmorphic Material 3 UI** — Light & dark themes, Poppins typography, Lottie animations.
- 📴 **Offline-First Caching** — Hive + SharedPreferences for a resilient offline experience.

---

## 🧰 Tech Stack

| Layer | Technology |
| --- | --- |
| **Framework** | Flutter 3.19+ / Dart 3.3+ |
| **State Management** | Riverpod (flutter_riverpod, riverpod_annotation) |
| **Routing** | go_router (ShellRoute + nested navigation) |
| **AI** | Google Generative AI — Gemini 1.5 Flash / Pro |
| **Backend** | Firebase (Auth, Firestore, Storage, Messaging, Analytics, Crashlytics) |
| **Maps & Location** | google_maps_flutter, geolocator, geocoding |
| **Local Storage** | Hive, hive_flutter, shared_preferences, path_provider |
| **Networking** | dio, connectivity_plus |
| **Media & Device** | image_picker, camera, permission_handler, url_launcher |
| **Notifications** | firebase_messaging, flutter_local_notifications, timezone |
| **UI / Design** | google_fonts, lottie, flutter_svg, shimmer, cached_network_image, flutter_animate |
| **Utilities** | intl, uuid, equatable, logger |

---

## 📁 Folder Structure

```text
ai_treasure_hunt/
├── android/                         # Android platform project (Gradle, Manifest, Kotlin)
│   └── app/
│       ├── build.gradle             # App module build config + signing
│       └── src/main/
│           ├── AndroidManifest.xml  # Permissions, API keys, FCM config
│           └── kotlin/app/aitreasurehunt/MainActivity.kt
├── assets/
│   ├── animations/                  # Lottie JSON animations
│   ├── fonts/                       # Poppins font family
│   ├── icons/                       # SVG / PNG icons
│   └── images/                      # Logos, onboarding, placeholders
├── docs/
│   ├── FIREBASE_SETUP.md            # Firebase project setup guide
│   ├── GEMINI_SETUP.md              # Gemini API key setup
│   ├── GOOGLE_MAPS_SETUP.md         # Google Maps / Places setup
│   ├── APK_BUILD_GUIDE.md           # Build & signing guide
│   └── PLAY_STORE_GUIDE.md          # Play Store publishing guide
├── lib/
│   ├── core/
│   │   ├── constants/               # app_constants.dart (keys, tuning, collections)
│   │   ├── errors/                  # Custom exception hierarchy
│   │   ├── extensions/              # BuildContext & String extensions
│   │   ├── providers/               # Global service providers
│   │   ├── routes/                  # app_router.dart (go_router config)
│   │   ├── services/                # Firebase, Gemini, Location, Weather, FCM, Hive, Storage
│   │   ├── theme/                   # Colors, Material 3 themes, theme extensions
│   │   ├── utils/                   # Helpers & form validators
│   │   └── widgets/                 # Reusable UI widgets (cards, badges, shimmer)
│   ├── features/
│   │   ├── auth/                    # Splash, onboarding, login, register, forgot password
│   │   ├── discovery/               # Treasure discovery screen
│   │   ├── gamification/            # Achievements & badges (models, repo, provider)
│   │   ├── home/                    # Home screen + MainShell (bottom nav)
│   │   ├── map/                     # Interactive map screen
│   │   ├── profile/                 # User profile screen
│   │   ├── settings/                # Settings screen + model
│   │   └── treasure/                # Treasure models, repository, providers
│   └── main.dart                    # App entry point & bootstrap
├── firestore.rules                  # Firestore security rules
├── firebase_storage.rules           # Cloud Storage security rules
├── pubspec.yaml                     # Dependencies & asset declarations
└── README.md                        # You are here
```

---

## 🚀 Quick Start

### Prerequisites

- **Flutter SDK** `>= 3.19.0` — [install guide](https://docs.flutter.dev/get-started/install)
- **Dart SDK** `>= 3.3.0` (bundled with Flutter)
- **Android Studio** (with Android SDK + platform tools) or **VS Code** + Flutter extension
- **JDK 17** (required by the Android Gradle plugin)
- A physical Android device or emulator (API 21+)

Verify your toolchain:

```bash
flutter doctor -v
```

### 1. Clone & install dependencies

```bash
git clone <your-repo-url> ai_treasure_hunt
cd ai_treasure_hunt
flutter pub get
```

### 2. Configure the required services

This app depends on three external services. Follow each guide **before** your first run:

| Service | Guide |
| --- | --- |
| 🔥 Firebase (Auth / Firestore / Storage / FCM) | [`docs/FIREBASE_SETUP.md`](docs/FIREBASE_SETUP.md) |
| 🤖 Google Gemini API | [`docs/GEMINI_SETUP.md`](docs/GEMINI_SETUP.md) |
| 🗺️ Google Maps Platform | [`docs/GOOGLE_MAPS_SETUP.md`](docs/GOOGLE_MAPS_SETUP.md) |

### 3. Run the app

```bash
flutter run \
  --dart-define=GEMINI_API_KEY=your_gemini_key \
  --dart-define=GOOGLE_MAPS_API_KEY=your_maps_key \
  --dart-define=WEATHER_API_KEY=your_weather_key
```

> The app reads API keys via `String.fromEnvironment(...)` in `lib/core/constants/app_constants.dart`. Passing them with `--dart-define` keeps secrets out of source control.

---

## 🔑 Environment Setup

All secrets are injected at build/run time via `--dart-define` and consumed in `lib/core/constants/app_constants.dart`:

| Variable | Description | Required |
| --- | --- | --- |
| `GEMINI_API_KEY` | Google AI Studio API key for Gemini | ✅ |
| `GOOGLE_MAPS_API_KEY` | Google Maps Platform key (also injected into `AndroidManifest.xml` via Gradle) | ✅ |
| `WEATHER_API_KEY` | OpenWeatherMap API key | Optional |

To avoid retyping keys, create a `dart_defines.json` (git-ignored) and pass it:

```bash
flutter run --dart-define-from-file=dart_defines.json
```

```json
{
  "GEMINI_API_KEY": "your_gemini_key",
  "GOOGLE_MAPS_API_KEY": "your_maps_key",
  "WEATHER_API_KEY": "your_weather_key"
}
```

You also need two **non-dart-define** files that are NOT committed:

- `android/app/google-services.json` — from Firebase (see [`docs/FIREBASE_SETUP.md`](docs/FIREBASE_SETUP.md))
- `android/key.properties` + a release keystore — for signed builds (see [`docs/APK_BUILD_GUIDE.md`](docs/APK_BUILD_GUIDE.md))

---

## 🏗️ Build Instructions

Full details in [`docs/APK_BUILD_GUIDE.md`](docs/APK_BUILD_GUIDE.md). Quick reference:

```bash
# Clean and refresh
flutter clean
flutter pub get

# Debug APK
flutter build apk --debug --dart-define-from-file=dart_defines.json

# Release APK (single, universal)
flutter build apk --release --dart-define-from-file=dart_defines.json

# Release split-per-ABI APKs (smaller downloads)
flutter build apk --release --split-per-abi --dart-define-from-file=dart_defines.json

# App Bundle for Google Play
flutter build appbundle --release --dart-define-from-file=dart_defines.json
```

Outputs:

- APK → `build/app/outputs/flutter-apk/app-release.apk`
- AAB → `build/app/outputs/bundle/release/app-release.aab`

Publishing to the Play Store? See [`docs/PLAY_STORE_GUIDE.md`](docs/PLAY_STORE_GUIDE.md).

---

## 📚 Documentation Index

| Doc | Purpose |
| --- | --- |
| [`docs/FIREBASE_SETUP.md`](docs/FIREBASE_SETUP.md) | Create the Firebase project, enable Auth/Firestore/Storage/FCM/Analytics, deploy rules |
| [`docs/GEMINI_SETUP.md`](docs/GEMINI_SETUP.md) | Get a Gemini API key, models used, rate limits, prompt examples |
| [`docs/GOOGLE_MAPS_SETUP.md`](docs/GOOGLE_MAPS_SETUP.md) | Enable Maps/Places/Directions/Geocoding APIs, restrict the key, billing |
| [`docs/APK_BUILD_GUIDE.md`](docs/APK_BUILD_GUIDE.md) | Prerequisites, keystore, signing config, building APK/AAB |
| [`docs/PLAY_STORE_GUIDE.md`](docs/PLAY_STORE_GUIDE.md) | Play Console, store listing, content rating, release tracks |

---

## 📦 App Details

- **App name:** AI Treasure Hunt
- **Android package / applicationId:** `app.aitreasurehunt`
- **Firebase Android app package:** `com.aitreasure.hunt`
- **Min SDK:** 21 · **Target/Compile SDK:** 34
- **Target audience:** Ages 15–45, primary market India 🇮🇳

---

<div align="center">

Built with ❤️ using Flutter & Google Gemini.

</div>

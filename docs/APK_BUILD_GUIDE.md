# 🏗️ APK / App Bundle Build Guide

This guide covers building **AI Treasure Hunt** for Android — from a debug run to a signed release APK and an App Bundle (`.aab`) ready for the Play Store.

---

## 1. Prerequisites

| Tool | Version | Notes |
| --- | --- | --- |
| **Flutter SDK** | `>= 3.19.0` | https://docs.flutter.dev/get-started/install |
| **Dart SDK** | `>= 3.3.0` | Bundled with Flutter |
| **Android Studio** | Latest | Provides Android SDK, platform-tools, emulator |
| **Android SDK** | Platform 34 + build-tools | Install via Android Studio SDK Manager |
| **JDK** | **17** | Required by the Android Gradle Plugin used here |

Verify your environment:

```bash
flutter --version
flutter doctor -v      # resolve any ❌ before building
java -version          # should report 17.x
```

Also complete the service setup first:
- [`FIREBASE_SETUP.md`](FIREBASE_SETUP.md) → `android/app/google-services.json`
- [`GEMINI_SETUP.md`](GEMINI_SETUP.md) → `GEMINI_API_KEY`
- [`GOOGLE_MAPS_SETUP.md`](GOOGLE_MAPS_SETUP.md) → `GOOGLE_MAPS_API_KEY`

---

## 2. Clean & Fetch Dependencies

Always start a release build from a clean state:

```bash
flutter clean
flutter pub get
```

`flutter clean` removes stale `build/` and `.dart_tool/` artifacts; `flutter pub get` restores dependencies from `pubspec.yaml`.

---

## 3. Debug Build (quick device test)

```bash
flutter build apk --debug --dart-define-from-file=dart_defines.json
# or run directly on a connected device/emulator:
flutter run --dart-define-from-file=dart_defines.json
```

Where `dart_defines.json` (git-ignored) holds your keys:

```json
{
  "GEMINI_API_KEY": "AIza...",
  "GOOGLE_MAPS_API_KEY": "AIza...",
  "WEATHER_API_KEY": "..."
}
```

> The Google Maps key must ALSO reach Gradle (via `android/gradle.properties` or the `GOOGLE_MAPS_API_KEY` env var) so it lands in the manifest. See the Google Maps guide, Step 5.

---

## 4. Create a Release Signing Keystore

Release builds must be signed with your own keystore. Generate one **once** and keep it safe — losing it means you can't update the app on Play.

```bash
keytool -genkey -v \
  -keystore ~/keystores/aitreasurehunt-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

You'll be prompted for a keystore password, a key password, and identity fields. Record these securely (password manager). Recommended: store the `.jks` **outside** the repo.

> For Play App Signing (recommended), this is your **upload key**. Google manages the final app signing key on their side.

---

## 5. Configure `key.properties`

Create `android/key.properties` (this file is git-ignored and must **never** be committed):

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/absolute/path/to/aitreasurehunt-upload.jks
```

- `storeFile` can be an absolute path, or a path relative to the `android/app/` directory.
- Keep this file local; add it to your secrets vault / CI secret store for automated builds.

---

## 6. Gradle Signing Config (already wired)

`android/app/build.gradle` already loads `key.properties` and defines a `release` signing config. For reference, the relevant logic looks like:

```gradle
// Load signing config from key.properties if present
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            if (keystorePropertiesFile.exists()) {
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
                storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
                storePassword keystoreProperties['storePassword']
            }
        }
    }

    buildTypes {
        release {
            // Falls back to debug signing if key.properties is absent (dev convenience)
            signingConfig keystorePropertiesFile.exists()
                ? signingConfigs.release
                : signingConfigs.debug
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

> If `key.properties` is missing, the release build falls back to debug signing (useful for local smoke tests) — but Play Store uploads **require** your real release signing.

---

## 7. Build a Release APK

Single universal APK (largest, installs on any ABI):

```bash
flutter build apk --release --dart-define-from-file=dart_defines.json
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

Smaller, per-ABI APKs (recommended for direct distribution):

```bash
flutter build apk --release --split-per-abi --dart-define-from-file=dart_defines.json
```

Outputs:
- `app-armeabi-v7a-release.apk`
- `app-arm64-v8a-release.apk`
- `app-x86_64-release.apk`

Install on a connected device to verify:

```bash
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

---

## 8. Build an App Bundle (for Google Play)

The Play Store requires an **Android App Bundle** (`.aab`), not an APK:

```bash
flutter build appbundle --release --dart-define-from-file=dart_defines.json
```

Output: `build/app/outputs/bundle/release/app-release.aab`

Upload this `.aab` to the Play Console (see [`PLAY_STORE_GUIDE.md`](PLAY_STORE_GUIDE.md)). Google generates optimized per-device APKs from it.

---

## 9. Versioning

The version comes from `pubspec.yaml`:

```yaml
version: 1.0.0+1   # <versionName>+<versionCode>
```

- `1.0.0` → `versionName` (user-visible).
- `1` → `versionCode` (must increase with every Play upload).

Bump before each release, e.g. `1.0.1+2`, or override at build time:

```bash
flutter build appbundle --release --build-name=1.0.1 --build-number=2 \
  --dart-define-from-file=dart_defines.json
```

---

## 10. Build Checklist

- [ ] `flutter doctor` shows no blocking issues.
- [ ] `google-services.json` present at `android/app/`.
- [ ] `GEMINI_API_KEY` and `GOOGLE_MAPS_API_KEY` supplied (Dart + Gradle).
- [ ] `key.properties` + keystore configured for release.
- [ ] `version` bumped in `pubspec.yaml`.
- [ ] `flutter clean && flutter pub get` run.
- [ ] Release build installs and launches; map + AI + auth verified on-device.

---

## 🛠️ Troubleshooting

| Symptom | Fix |
| --- | --- |
| `Execution failed ... Java 17` errors | Install JDK 17 and point `JAVA_HOME`/Android Studio Gradle JDK to it. |
| `google-services.json is missing` | Place it at `android/app/google-services.json`. |
| Map gray in release only | Add the **release** SHA-1 to the Maps key restriction. |
| `Keystore file not found` | Fix `storeFile` path in `key.properties` (use absolute path). |
| App installs but crashes on launch | Missing `--dart-define` keys or Firebase config; check `adb logcat`. |
| Minify strips needed classes | Add keep rules to `android/app/proguard-rules.pro`. |

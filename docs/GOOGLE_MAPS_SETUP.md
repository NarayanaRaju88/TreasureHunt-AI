# 🗺️ Google Maps Platform Setup Guide

**AI Treasure Hunt** renders an interactive map, tracks the user's location, geocodes addresses, and recommends routes/places. This requires a **Google Maps Platform** API key with the right APIs enabled.

> The key is injected into `AndroidManifest.xml` via Gradle (`GOOGLE_MAPS_API_KEY`) and also passed to Dart via `--dart-define`.

---

## 1. Open Google Cloud Console

1. Go to **https://console.cloud.google.com/**
2. Sign in and select (or create) a project. If your Firebase project already exists, you can reuse its underlying Google Cloud project so billing/quotas stay consolidated.
   - Firebase projects appear in Cloud Console under the same name.

---

## 2. Enable the Required APIs

Navigate to **APIs & Services → Library** (https://console.cloud.google.com/apis/library) and **Enable** each of the following:

| API | Why it's needed | Direct link |
| --- | --- | --- |
| **Maps SDK for Android** | Render the map on Android | https://console.cloud.google.com/apis/library/maps-android-backend.googleapis.com |
| **Places API** | Place search / recommendations | https://console.cloud.google.com/apis/library/places-backend.googleapis.com |
| **Directions API** | Routing to treasures | https://console.cloud.google.com/apis/library/directions-backend.googleapis.com |
| **Geocoding API** | Convert addresses ⇄ coordinates (used by `geocoding`) | https://console.cloud.google.com/apis/library/geocoding-backend.googleapis.com |

For each: open the link → click **Enable**. Wait for confirmation before moving on.

📸 _Screenshot guidance: Under **APIs & Services → Enabled APIs & services**, all four APIs should be listed as enabled._

---

## 3. Create an API Key

1. Go to **APIs & Services → Credentials** → https://console.cloud.google.com/apis/credentials
2. Click **+ Create credentials → API key**.
3. Copy the generated key (`AIza...`). Click **Edit API key** to restrict it (next step).

---

## 4. Restrict the API Key (Android app restriction)

Restricting the key prevents abuse if it leaks. Configure two kinds of restrictions:

### A) Application restriction → Android apps
1. In the key's edit page, under **Application restrictions**, select **Android apps**.
2. Click **Add an item** and provide:
   - **Package name:** the `applicationId` your app is built with — `app.aitreasurehunt` (or `com.aitreasure.hunt` if you changed it).
   - **SHA-1 certificate fingerprint:** your debug and/or release signing SHA-1.
     ```bash
     # Debug SHA-1
     keytool -list -v -alias androiddebugkey \
       -keystore ~/.android/debug.keystore \
       -storepass android -keypass android

     # Release SHA-1 (after you create a release keystore — see APK Build Guide)
     keytool -list -v -alias upload -keystore /path/to/upload-keystore.jks
     ```
   - Add a separate entry for each build (debug + release).

### B) API restriction
1. Under **API restrictions**, choose **Restrict key**.
2. Select only the APIs this key needs: **Maps SDK for Android**, **Places API**, **Directions API**, **Geocoding API**.
3. Click **Save**.

> 💡 You may prefer two keys: one **Android-restricted** key for the Maps SDK in the manifest, and one **server/IP or unrestricted-for-dev** key for REST APIs (Directions/Geocoding/Places) called over HTTP. For simplicity, a single Android-restricted key with all four APIs works for on-device SDK usage.

📸 _Screenshot guidance: The key detail page shows **Application restrictions: Android apps** with your package + SHA-1, and **API restrictions** listing the four APIs._

---

## 5. Add the Key to `AndroidManifest.xml`

The manifest already declares the Maps key placeholder — you do **not** hard-code it there. It reads from a Gradle manifest placeholder:

```xml
<!-- android/app/src/main/AndroidManifest.xml (already present) -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${GOOGLE_MAPS_API_KEY}" />
```

`android/app/build.gradle` fills that placeholder from a project property or environment variable:

```gradle
// android/app/build.gradle (already present)
def googleMapsApiKey = project.findProperty('GOOGLE_MAPS_API_KEY')
    ?: System.getenv('GOOGLE_MAPS_API_KEY')
    ?: ''

defaultConfig {
    manifestPlaceholders += [GOOGLE_MAPS_API_KEY: googleMapsApiKey]
}
```

So provide the key to Gradle in **one** of these ways:

**Option A — Gradle property in `android/gradle.properties`** (git-ignore it if the file holds secrets):
```properties
GOOGLE_MAPS_API_KEY=AIza...your_maps_key...
```

**Option B — Environment variable** (good for CI):
```bash
export GOOGLE_MAPS_API_KEY=AIza...your_maps_key...
flutter build apk --release
```

**Option C — Command-line Gradle property via Flutter:**
```bash
flutter build apk --release -Pandroid.injected... # (prefer Option A or B)
```

Additionally, pass the key to Dart so REST calls (Directions/Places/Geocoding) work:
```bash
flutter run --dart-define=GOOGLE_MAPS_API_KEY=AIza...your_maps_key...
```

---

## 6. Billing Setup (Required)

Google Maps Platform **requires a billing account** even though it includes a recurring monthly free credit.

1. Go to **Billing** → https://console.cloud.google.com/billing
2. Create or link a billing account (requires a payment method).
3. Attach the billing account to the project used for the Maps key.
4. Google Maps Platform provides a **recurring monthly credit** (historically ~$200/month) that covers substantial development and light production usage — verify the current amount at https://mapsplatform.google.com/pricing/
5. Set **budget alerts** (Billing → Budgets & alerts) to avoid surprises, and keep your key restricted (Step 4) so it can't be abused.

> Without an active billing account, the map will render a blank/gray tile and API calls will return `REQUEST_DENIED` or authorization errors.

---

## 7. Verify It Works

1. Build/run with the Maps key provided to both Gradle and Dart.
2. Open the **Map** screen — you should see live Google map tiles (not a gray grid) and treasure markers.
3. Grant location permission — the blue "my location" dot should appear.
4. If the map is blank/gray:
   - Confirm **Maps SDK for Android** is enabled.
   - Confirm billing is active on the project.
   - Confirm the key's package name + SHA-1 match your build.
   - Check `adb logcat` for `Authorization failure` / `API key not found` messages.

---

## 🔗 Useful URLs

| Purpose | URL |
| --- | --- |
| Google Cloud Console | https://console.cloud.google.com/ |
| API Library | https://console.cloud.google.com/apis/library |
| Credentials (API keys) | https://console.cloud.google.com/apis/credentials |
| Billing | https://console.cloud.google.com/billing |
| Maps Platform pricing | https://mapsplatform.google.com/pricing/ |
| Maps SDK for Android docs | https://developers.google.com/maps/documentation/android-sdk |

---

## 🛠️ Troubleshooting

| Symptom | Fix |
| --- | --- |
| Gray/blank map | Maps SDK not enabled, billing inactive, or key restriction mismatch. |
| `REQUEST_DENIED` from Places/Directions/Geocoding | Enable the specific API and add it to the key's API restrictions. |
| `Authorization failure` in logcat | Package name / SHA-1 in the key restriction doesn't match the running build. |
| Key works in debug, fails in release | Add the **release** SHA-1 to the key restriction and re-build. |

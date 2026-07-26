# 🔥 Firebase Setup Guide

This guide walks you through creating and configuring the Firebase backend for **AI Treasure Hunt**. Complete every section before running the app, otherwise authentication, data, storage, and notifications will fail.

> **Android package name used throughout:** `com.aitreasure.hunt`
> **Estimated time:** ~20 minutes.

---

## 1. Create a Firebase Project

1. Go to the Firebase Console → **https://console.firebase.google.com/**
2. Click **Add project** (or **Create a project**).
3. Enter a project name, e.g. `AI Treasure Hunt`.
4. (Recommended) Keep **Google Analytics** enabled and choose/create an Analytics account.
5. Click **Create project** and wait for provisioning to finish.

📸 _Screenshot guidance: You should land on the project **Overview** dashboard with a row of platform icons (iOS, Android, Web, etc.)._

---

## 2. Add the Android App

1. On the project **Overview**, click the **Android** icon (`</>` shows web; pick the little Android robot).
2. Fill in the registration form:
   - **Android package name:** `com.aitreasure.hunt` &nbsp;← must match exactly.
   - **App nickname:** `AI Treasure Hunt (Android)` (optional).
   - **Debug signing certificate SHA-1:** recommended for Google Sign-In. Generate it with:
     ```bash
     # Debug keystore (development)
     keytool -list -v \
       -alias androiddebugkey \
       -keystore ~/.android/debug.keystore \
       -storepass android -keypass android
     ```
     Copy the `SHA1` value and paste it into the form. (You can add release SHA-1/SHA-256 later — see the APK Build Guide.)
3. Click **Register app**.

> ⚠️ **Note on package names:** the Firebase Android app is registered as `com.aitreasure.hunt`. The Gradle `applicationId` in this project is `app.aitreasurehunt`. If you want Firebase to work out of the box, either (a) register a second Android app in Firebase using `app.aitreasurehunt`, or (b) change `applicationId` in `android/app/build.gradle` and `namespace` to `com.aitreasure.hunt`. **The package name in Firebase must match the `applicationId` your APK is built with.**

---

## 3. Download & Place `google-services.json`

1. After registering, click **Download google-services.json**.
2. Place the file at:
   ```text
   android/app/google-services.json
   ```
3. This file is git-ignored by default (it contains project identifiers). Never commit it to a public repo.
4. The project already applies the Google Services Gradle plugin (`com.google.gms.google-services`) in `android/app/build.gradle`, so no extra Gradle edits are needed.

📸 _Screenshot guidance: In your file explorer / IDE, confirm `google-services.json` sits directly inside `android/app/` (next to `build.gradle`)._

---

## 4. Enable Authentication

1. In the left sidebar go to **Build → Authentication**, then click **Get started**.
2. Open the **Sign-in method** tab and enable the following providers:

   | Provider | Steps |
   | --- | --- |
   | **Google** | Toggle **Enable**, choose a project support email, **Save**. |
   | **Email/Password** | Toggle **Enable** (leave "Email link" off unless needed), **Save**. |
   | **Anonymous** | Toggle **Enable**, **Save**. (Powers the "Continue as guest" flow.) |

3. For **Google Sign-In** to work on Android, make sure the SHA-1 fingerprint from Step 2 is registered under **Project settings → Your apps → Android app → SHA certificate fingerprints**. Re-download `google-services.json` after adding fingerprints.

📸 _Screenshot guidance: The Sign-in method list should show **Google**, **Email/Password**, and **Anonymous** all marked **Enabled**._

---

## 5. Create the Firestore Database

1. Left sidebar → **Build → Firestore Database** → **Create database**.
2. Choose a start mode:
   - Select **Start in production mode** (we will deploy custom rules next).
3. **Select a location / region.** Pick the region closest to your primary users. Since the target market is **India**, a good choice is:
   - `asia-south1` (Mumbai) — lowest latency for India.
   - _Note: the location is permanent and cannot be changed later._
4. Click **Enable** and wait for the database to be created.

### Deploy the Firestore Security Rules

This repo ships production-ready rules at [`firestore.rules`](../firestore.rules). Deploy them one of two ways:

**Option A — Console (copy/paste):**
1. Firestore Database → **Rules** tab.
2. Open `firestore.rules` from this repo, copy the full contents.
3. Paste over the default rules, click **Publish**.

**Option B — Firebase CLI (recommended for repeatability):**
```bash
npm install -g firebase-tools
firebase login
firebase use --add            # select your project
firebase deploy --only firestore:rules
```

📸 _Screenshot guidance: After publishing, the Rules editor should show your `rules_version = '2'` block and a green "Rules published" confirmation._

---

## 6. Enable Cloud Storage & Deploy Storage Rules

1. Left sidebar → **Build → Storage** → **Get started**.
2. Choose **Start in production mode**, click **Next**.
3. Confirm/choose the storage bucket location (use the same region family as Firestore, e.g. `asia-south1`), click **Done**.
4. Deploy the storage rules shipped in this repo at [`firebase_storage.rules`](../firebase_storage.rules):

**Option A — Console:**
- Storage → **Rules** tab → paste the contents of `firebase_storage.rules` → **Publish**.

**Option B — CLI:**
```bash
firebase deploy --only storage
```

> The app uploads avatars, treasure images, and discovery photos under the paths defined in `AppConstants` (`avatars/`, `treasure_images/`, `discovery_photos/`). The rules restrict writes to authenticated users.

📸 _Screenshot guidance: The Storage **Files** tab shows an empty bucket `gs://<project-id>.appspot.com`, and the **Rules** tab shows your published rules._

---

## 7. Enable Cloud Messaging (FCM)

1. Cloud Messaging is enabled automatically when you add an app, but confirm it:
   - Left sidebar → **Run/Engage → Messaging** (or **Project settings → Cloud Messaging**).
2. The app registers an Android notification channel and requests the `POST_NOTIFICATIONS` permission at runtime (Android 13+), handled by `FcmService`.
3. No server key setup is required for client receipt. To **send** campaigns/test messages:
   - **Messaging → Create your first campaign → Firebase Notification messages**, or
   - Use the **Cloud Messaging API (V1)** with a service account for backend sends.
4. The default notification topic and channel are defined in `AppConstants` (`fcmDefaultTopic`, `fcmDefaultChannelId`) and referenced in `AndroidManifest.xml`.

📸 _Screenshot guidance: In **Project settings → Cloud Messaging**, the **Firebase Cloud Messaging API (V1)** should show status **Enabled**._

---

## 8. Enable Analytics & Crashlytics

### Google Analytics
- If you enabled Analytics during project creation, it's already active. Verify under **Analytics → Dashboard**.
- If you skipped it: **Project settings → Integrations → Google Analytics → Enable**.

### Crashlytics
1. Left sidebar → **Release & Monitor → Crashlytics** → **Enable Crashlytics**.
2. Crashlytics starts collecting data after the app runs and records its first event/crash. To force a test crash during development, trigger a fatal error from a debug build and confirm it appears in the dashboard (may take a few minutes).

> If you add the Crashlytics/Analytics Flutter plugins later (`firebase_crashlytics`, `firebase_analytics`), remember to run `flutter pub get` and, for Crashlytics, apply the `com.google.firebase.crashlytics` Gradle plugin.

📸 _Screenshot guidance: Crashlytics dashboard initially shows "Waiting for your app to record events" until the first session is received._

---

## 9. Verify the Setup

Run the app and confirm:

```bash
flutter run --dart-define-from-file=dart_defines.json
```

Checklist:

- [ ] App launches without a Firebase initialization error in the console.
- [ ] You can sign in with Google, Email/Password, and as a guest.
- [ ] A user document appears in **Firestore → `users` collection** after sign-in.
- [ ] Uploading an avatar creates a file under **Storage → `avatars/`**.
- [ ] A test push from **Messaging** is received on the device.

---

## 🔗 Useful Console URLs

| Purpose | URL |
| --- | --- |
| Firebase Console (all projects) | https://console.firebase.google.com/ |
| Authentication | https://console.firebase.google.com/project/_/authentication/providers |
| Firestore Database | https://console.firebase.google.com/project/_/firestore |
| Firestore Rules | https://console.firebase.google.com/project/_/firestore/rules |
| Cloud Storage | https://console.firebase.google.com/project/_/storage |
| Cloud Messaging | https://console.firebase.google.com/project/_/messaging |
| Crashlytics | https://console.firebase.google.com/project/_/crashlytics |
| Project Settings | https://console.firebase.google.com/project/_/settings/general |

_Replace `_` with your project ID, or just navigate from the console sidebar._

---

## 🛠️ Troubleshooting

| Symptom | Likely cause & fix |
| --- | --- |
| `Default FirebaseApp is not initialized` | `google-services.json` missing or in the wrong folder. Must be `android/app/google-services.json`. |
| Google Sign-In fails silently / `ApiException: 10` | SHA-1 not registered, or `google-services.json` outdated. Add SHA-1 in Project settings, re-download the JSON. |
| `PERMISSION_DENIED` from Firestore | Security rules not deployed or user not authenticated. Deploy `firestore.rules` and ensure the user is signed in. |
| Storage upload fails with permission error | Storage rules not deployed, or path doesn't match the allowed paths. Deploy `firebase_storage.rules`. |
| Package name mismatch | The Firebase app package must equal your build `applicationId`. See the note in Step 2. |

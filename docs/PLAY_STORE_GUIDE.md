# 🚀 Google Play Store Publishing Guide

This guide takes you from a signed App Bundle to a live listing for **AI Treasure Hunt** on the Google Play Store.

> Build the `.aab` first — see [`APK_BUILD_GUIDE.md`](APK_BUILD_GUIDE.md).
> **Package / applicationId:** `app.aitreasurehunt` · **Target audience:** ages 15–45, primary market **India** 🇮🇳

---

## 1. Set Up Google Play Console

1. Go to **https://play.google.com/console/**
2. Sign in and pay the **one-time $25 developer registration fee** (if you don't already have an account).
3. Complete account details and verify identity (Google may require ID + address verification, and D-U-N-S for organizations).
4. Click **Create app** and fill in:
   - **App name:** `AI Treasure Hunt`
   - **Default language:** e.g. English (India) `en-IN`
   - **App or game:** Game (or App — choose based on your store strategy; this is a location-based game).
   - **Free or paid:** Free
   - Accept the developer program & US export declarations.

---

## 2. App Signing (Play App Signing)

1. Under **Release → Setup → App integrity → App signing**, enroll in **Play App Signing** (default for new apps).
2. Upload your `.aab` signed with your **upload key** (from `key.properties`). Google re-signs with the managed app signing key.
3. Keep your **upload keystore** safe — it's how Google verifies future updates come from you.

> Benefit: if you ever lose the upload key, Google can help you reset it; the app signing key stays protected on Google's side.

---

## 3. Store Listing Requirements

Go to **Grow → Store presence → Main store listing** and provide:

### Text
| Field | Limit | Notes |
| --- | --- | --- |
| **App name** | 30 chars | `AI Treasure Hunt` |
| **Short description** | 80 chars | Hook: e.g. "Explore real places & unlock AI-generated treasures on a live map." |
| **Full description** | 4,000 chars | Features, how it works, gamification, privacy note. |

### Graphic Assets
| Asset | Spec |
| --- | --- |
| **App icon** | 512 × 512 px, 32-bit PNG (with alpha) |
| **Feature graphic** | 1024 × 500 px, JPG/PNG (no alpha) |
| **Phone screenshots** | Min **2**, up to 8. 16:9 or 9:16, min side 320 px, max 3840 px |
| **7-inch tablet screenshots** | Optional but recommended |
| **10-inch tablet screenshots** | Optional |
| **Promo video** | Optional YouTube URL |

---

## 4. Screenshots & Assets Guidance

- Capture from a real device or emulator at a clean resolution (e.g. 1080 × 1920).
  ```bash
  adb exec-out screencap -p > screenshot.png
  ```
- Showcase the highest-value screens: the **live map with treasure markers**, a **treasure discovery** with AI story, the **gamification/profile** (XP, badges, streak), and a **daily challenge**.
- Keep on-screen text legible; optionally add framed device mockups + captions.
- Ensure no placeholder/dummy content, no other brands' logos, and nothing misleading.

---

## 5. Content Rating

1. Go to **Policy → App content → Content ratings** → **Start questionnaire**.
2. Select category (e.g. **App / Reference, or Game**), enter your email.
3. Answer honestly about violence, user interaction, location sharing, etc.
   - AI Treasure Hunt shares **approximate location** for gameplay and has **user-generated content / social** aspects if you enable sharing — declare these.
4. Submit to receive IARC ratings (e.g. PEGI, ESRB, and India's applicable rating).

---

## 6. Target Audience & Content

Under **Policy → App content → Target audience and content**:

- **Age groups:** select **15–17** and **18+** (target 15–45). Do **not** target children under 13, which triggers Families policy and stricter requirements.
- Confirm the app is **not** primarily directed at children.
- **Primary market:** India — set country availability under **Release → Production → Countries/regions** (add India and any others).
- Complete additional declarations: **Data safety**, **Ads** (declare if you show ads), **News**, **COVID-19** (as applicable), **Government apps** (no).

---

## 7. Data Safety & Privacy Policy (Required)

1. **Privacy policy URL** is mandatory. Host a policy that discloses:
   - Location data collection & use (foreground/background).
   - Account data (email, Google profile) via Firebase Auth.
   - User content (photos uploaded to Storage).
   - Analytics/Crashlytics data.
   - Third parties: Google (Maps, Gemini/AI, Firebase), OpenWeatherMap.
   - Enter it under **Policy → App content → Privacy policy**.
2. Complete the **Data safety** form (**Policy → App content → Data safety**): declare each data type collected, whether shared, and security practices (encryption in transit, deletion requests).
3. If you request **background location** (`ACCESS_BACKGROUND_LOCATION`), you must justify it with a **prominent disclosure + in-app rationale**, and may need to submit a permissions declaration form and a short demo video.

---

## 8. Release Tracks

Play Console offers a promotion ladder — test before going wide:

```
Internal testing  →  Closed testing  →  Open testing  →  Production
   (≤100 testers)      (invite lists)     (public opt-in)   (everyone)
```

| Track | Use it for |
| --- | --- |
| **Internal testing** | Fastest distribution to your own team (up to 100 testers). Ideal first smoke test of the signed bundle. |
| **Closed testing** | Larger invited groups (email lists / Google Groups). Gather structured feedback. Google may require a minimum tester count / duration for new personal accounts before production. |
| **Open testing** | Public beta anyone can join via a link. Great for a soft launch in India. |
| **Production** | Full public release. Supports **staged rollout** (e.g. 10% → 50% → 100%). |

### To create a release
1. **Release → Testing/Production →** choose the track → **Create new release**.
2. Upload the `app-release.aab`.
3. Add **release notes** per language.
4. **Review** → resolve any errors/warnings → **Start rollout**.

> New apps go through Google review, which can take from hours to several days. Address any policy flags promptly.

---

## 9. Pre-Launch Checklist

- [ ] Signed `.aab` uploaded, Play App Signing enrolled.
- [ ] Store listing complete (name, descriptions, icon, feature graphic, ≥2 screenshots).
- [ ] Content rating questionnaire submitted.
- [ ] Target audience set to 15+ (not children).
- [ ] Privacy policy URL live; Data safety form complete.
- [ ] Background location justified (if used).
- [ ] Countries/regions include India.
- [ ] Tested via Internal → Closed/Open track before Production.
- [ ] `versionCode` incremented from any prior upload.

---

## 🔗 Useful URLs

| Purpose | URL |
| --- | --- |
| Google Play Console | https://play.google.com/console/ |
| Launch checklist | https://developer.android.com/distribute/best-practices/launch/launch-checklist |
| App signing docs | https://support.google.com/googleplay/android-developer/answer/9842756 |
| Data safety form | https://support.google.com/googleplay/android-developer/answer/10787469 |
| Content ratings | https://support.google.com/googleplay/android-developer/answer/9859655 |
| Target audience policy | https://support.google.com/googleplay/android-developer/answer/9877531 |

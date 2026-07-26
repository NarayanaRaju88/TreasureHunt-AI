# 🤖 Google Gemini API Setup Guide

**AI Treasure Hunt** uses Google's **Gemini** models to generate treasures, fun facts, stories, quiz questions, place recommendations, and to power natural-language search. This guide gets you a key and wires it into the app.

> **Model used:** `gemini-1.5-flash` (fast, cost-efficient). A `gemini-1.5-pro` fallback is also defined for heavier generation.

---

## 1. Get an API Key from Google AI Studio

1. Open **Google AI Studio** → **https://aistudio.google.com/**
2. Sign in with your Google account.
3. Click **Get API key** (top-left menu) → **https://aistudio.google.com/app/apikey**
4. Click **Create API key**.
   - You can create the key in a new project or an existing Google Cloud project.
5. Copy the generated key (starts with `AIza...`). **Store it securely** — treat it like a password.

📸 _Screenshot guidance: The **API keys** page lists your key with a **Copy** button and the associated Cloud project._

---

## 2. Add the Key to the App

The app reads the Gemini key from an environment variable via `String.fromEnvironment(...)` in
`lib/core/constants/app_constants.dart`:

```dart
// lib/core/constants/app_constants.dart
static const String geminiApiKey =
    String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

static const String geminiModel = 'gemini-1.5-flash';
static const String geminiProModel = 'gemini-1.5-pro';
```

### Recommended: pass the key at build/run time (keeps secrets out of source control)

```bash
flutter run --dart-define=GEMINI_API_KEY=AIza...your_key...
```

Or via a git-ignored `dart_defines.json`:

```json
{
  "GEMINI_API_KEY": "AIza...your_key...",
  "GOOGLE_MAPS_API_KEY": "AIza...maps_key...",
  "WEATHER_API_KEY": "your_openweather_key"
}
```

```bash
flutter run --dart-define-from-file=dart_defines.json
```

### Alternative: hard-code for quick local testing (NOT recommended)

You _can_ replace the `defaultValue` with your key for a fast local trial, but **never commit** a key this way:

```dart
static const String geminiApiKey =
    String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'AIza...your_key...');
```

> ⚠️ Hard-coded keys ship inside your APK and can be extracted. For production, prefer `--dart-define` and add API key restrictions in Google Cloud.

---

## 3. Model & Configuration

The `GeminiService` (`lib/core/services/gemini_service.dart`) uses the `google_generative_ai` package:

- **Primary model:** `gemini-1.5-flash` — low latency, high free-tier limits, ideal for on-demand content.
- **Fallback / heavy model:** `gemini-1.5-pro` — richer reasoning for complex generation.
- JSON-structured output is requested (via `responseMimeType: application/json`) for treasures, quizzes, and search so responses parse deterministically.
- Safety settings and `GenerationConfig` (temperature, max tokens) are configured in the service.

---

## 4. Rate Limits

Limits depend on whether you're on the **free tier** or a **paid (billing-enabled) tier**, and Google updates them periodically. Typical `gemini-1.5-flash` limits:

| Tier | Requests/min (RPM) | Tokens/min (TPM) | Requests/day (RPD) |
| --- | --- | --- | --- |
| **Free** | ~15 RPM | ~1,000,000 TPM | ~1,500 RPD |
| **Paid (Tier 1)** | ~1,000+ RPM | ~1,000,000+ TPM | much higher |

Guidance:
- The app makes on-demand calls (e.g. generating a daily treasure, fun facts on discovery). Free-tier limits are usually sufficient for development and light usage.
- For production scale, **enable billing** on the associated Cloud project to raise limits.
- Handle `429 Too Many Requests` gracefully — `GeminiService` surfaces failures as `AIServiceException`; consider client-side caching (Hive) and backoff.
- Check current limits: **https://ai.google.dev/gemini-api/docs/rate-limits**

---

## 5. Prompt Examples Used in the App

`GeminiService` builds prompts like the following (paraphrased) for each feature:

### 🎁 Generate a Daily Treasure (`generateDailyTreasure`)
```text
You are a creative treasure designer for a location-based exploration game.
Given the user's city/coordinates and interests, invent ONE unique treasure at a
real, publicly accessible nearby place.
Return STRICT JSON with keys:
{ "name", "description", "category", "difficulty", "story",
  "funFacts": [..], "latitude", "longitude", "xpReward" }.
Keep it family-friendly and factually plausible.
```

### 💡 Generate Fun Facts (`generateFunFacts`)
```text
Give 3 short, surprising, factual fun facts about "<place name>" located near
<lat,lng>. Return a JSON array of strings. Keep each fact under 25 words.
```

### 📖 Generate a Treasure Story (`generateTreasureStory`)
```text
Write a 3–4 sentence immersive, adventurous mini-story that makes discovering
"<treasure name>" feel exciting. Second person ("you"). No spoilers of exact
GPS. Return plain text.
```

### 📍 Recommend Nearby Places (`recommendNearbyPlaces`)
```text
Suggest up to 5 interesting real places to explore near <lat,lng> that match the
category "<category>". Return JSON array of { "name", "why", "approxLatitude",
"approxLongitude" }.
```

### 🔍 Natural-Language Search (`naturalLanguageSearch`)
```text
The user typed: "<query>". Extract structured search intent for a treasure-hunt
map. Return JSON { "keywords": [..], "category", "radiusMeters", "difficulty" }.
```

### ❓ Generate a Quiz Question (`generateQuizQuestion`)
```text
Create ONE multiple-choice trivia question about "<treasure/place>".
Return JSON { "question", "options": [4 strings], "correctIndex", "explanation" }.
Ensure exactly one correct option and plausible distractors.
```

> These prompts are constructed in code and may include the user's coordinates, selected category, difficulty, and interests. Because output is requested as JSON, the service parses and maps it into the app's models (`TreasureModel`, `QuizQuestion`, etc.).

---

## 6. Verify It Works

1. Run the app with `GEMINI_API_KEY` set.
2. Trigger a treasure generation (e.g. open Home / daily challenge).
3. Confirm AI content appears (name, story, fun facts) rather than an error snackbar.
4. If you see an `AIServiceException` or empty content:
   - Check the key is valid and passed via `--dart-define`.
   - Check you haven't hit rate limits (`429`).
   - Confirm the device has internet access.

---

## 🔗 Useful URLs

| Purpose | URL |
| --- | --- |
| Google AI Studio | https://aistudio.google.com/ |
| Create / manage API keys | https://aistudio.google.com/app/apikey |
| Gemini API docs | https://ai.google.dev/gemini-api/docs |
| Models & pricing | https://ai.google.dev/gemini-api/docs/models/gemini |
| Rate limits | https://ai.google.dev/gemini-api/docs/rate-limits |

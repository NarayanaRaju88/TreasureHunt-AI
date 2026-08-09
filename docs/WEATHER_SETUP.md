# Weather API Key Setup (OpenWeatherMap)

Home weather needs a free OpenWeatherMap key, stored as a GitHub Actions secret.

## 1. Create the key

1. Open https://openweathermap.org/api
2. Sign up / log in
3. Go to **API keys** (account page)
4. Copy your **Default** key (or create a new one)
5. Wait a few minutes — new keys can take up to ~10 minutes to activate

## 2. Add it to GitHub Secrets

1. Open your repo on GitHub: `TreasureHunt-AI`
2. Go to **Settings → Secrets and variables → Actions**
3. Click **New repository secret**
4. Name exactly:

```text
WEATHER_API_KEY
```

5. Paste the OpenWeatherMap key as the value
6. Save

Also confirm these secrets exist (for treasure + map):

| Secret | Used for |
| --- | --- |
| `GEMINI_API_KEY` | AI daily treasures |
| `GOOGLE_MAPS_API_KEY` | Map tiles |
| `WEATHER_API_KEY` | Home weather card |

## 3. Rebuild the APK

1. GitHub → **Actions → Build Flutter APK → Run workflow**
2. Download the new APK artifact
3. Uninstall the old app on your phone
4. Install the new APK

## How the app uses it

The release build injects:

```bash
--dart-define=WEATHER_API_KEY=${{ secrets.WEATHER_API_KEY }}
```

If the secret is missing/empty, Home shows:

> Add WEATHER_API_KEY to enable live weather

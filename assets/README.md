# Assets

This directory holds all bundled assets for the **AI Treasure Hunt** app. The
folders below are declared in `pubspec.yaml`. Drop the real asset files in each
folder using the exact filenames referenced in `lib/core/constants/app_constants.dart`.

## Structure

```
assets/
├── fonts/        # Poppins font family (.ttf)
├── animations/   # Lottie animation JSON files
├── images/       # Raster images (PNG/JPG/WebP)
└── icons/        # SVG / small PNG icons
```

## fonts/
Required Poppins weights (download from Google Fonts):

| File                     | Weight |
|--------------------------|--------|
| `Poppins-Regular.ttf`    | 400    |
| `Poppins-Medium.ttf`     | 500    |
| `Poppins-SemiBold.ttf`   | 600    |
| `Poppins-Bold.ttf`       | 700    |

> The app also loads Poppins dynamically via the `google_fonts` package, so the
> bundled files act as an offline fallback.

## animations/
Lottie JSON files referenced in `AppConstants`:

- `splash.json`
- `loading.json`
- `success.json`
- `treasure.json`
- `empty.json`
- `error.json`

## images/
- `logo.png`
- `avatar_placeholder.png`
- `onboarding_1.png`, `onboarding_2.png`, `onboarding_3.png`
- `empty_state.png`

## icons/
App-specific SVG/PNG icons (map markers, badges, rarity tiers, etc.).

---

**Note:** Placeholder `.gitkeep` files are included so the empty folders are
tracked by git. Replace them with the real assets before building a release.

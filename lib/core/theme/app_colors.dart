import 'package:flutter/material.dart';

/// Centralized color constants for the AI Treasure Hunt app.
///
/// Primary brand color: #4CAF50 (green)
/// Accent brand color:  #FFC107 (amber)
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Brand
  // ---------------------------------------------------------------------------
  static const Color primary = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF388E3C);
  static const Color primaryLight = Color(0xFF81C784);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color accent = Color(0xFFFFC107);
  static const Color accentDark = Color(0xFFFFA000);
  static const Color accentLight = Color(0xFFFFD54F);
  static const Color onAccent = Color(0xFF1B1B1B);

  static const Color secondary = Color(0xFF00BCD4);
  static const Color tertiary = Color(0xFF7C4DFF);

  // ---------------------------------------------------------------------------
  // Light theme surfaces
  // ---------------------------------------------------------------------------
  static const Color lightBackground = Color(0xFFF6F8F6);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEDF2ED);
  static const Color lightOnBackground = Color(0xFF1B1B1B);
  static const Color lightOnSurface = Color(0xFF232323);
  static const Color lightOutline = Color(0xFFD3DAD3);

  // ---------------------------------------------------------------------------
  // Dark theme surfaces
  // ---------------------------------------------------------------------------
  static const Color darkBackground = Color(0xFF0F1511);
  static const Color darkSurface = Color(0xFF1A211C);
  static const Color darkSurfaceVariant = Color(0xFF232B25);
  static const Color darkOnBackground = Color(0xFFF1F5F1);
  static const Color darkOnSurface = Color(0xFFE4E9E4);
  static const Color darkOutline = Color(0xFF3A423C);

  // ---------------------------------------------------------------------------
  // Semantic / status
  // ---------------------------------------------------------------------------
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFB8C00);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF1E88E5);
  static const Color onError = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Neutrals
  // ---------------------------------------------------------------------------
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);
  static const Color transparent = Color(0x00000000);

  // ---------------------------------------------------------------------------
  // Glassmorphism
  // ---------------------------------------------------------------------------
  static const Color glassLight = Color(0x33FFFFFF);
  static const Color glassLightBorder = Color(0x4DFFFFFF);
  static const Color glassDark = Color(0x1AFFFFFF);
  static const Color glassDarkBorder = Color(0x33FFFFFF);
  static const Color glassShadow = Color(0x1A000000);

  // ---------------------------------------------------------------------------
  // Gamification / rarity tiers
  // ---------------------------------------------------------------------------
  static const Color bronze = Color(0xFFCD7F32);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color gold = Color(0xFFFFD700);
  static const Color platinum = Color(0xFFE5E4E2);
  static const Color legendary = Color(0xFFB388FF);
  static const Color xpBar = Color(0xFFFFC107);
  static const Color xpBarTrack = Color(0xFF3A423C);

  // ---------------------------------------------------------------------------
  // Gradients
  // ---------------------------------------------------------------------------
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD54F), Color(0xFFFFA000)],
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFF8A65), Color(0xFFFFC107), Color(0xFF4CAF50)],
  );

  static const LinearGradient darkGlassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
  );
}

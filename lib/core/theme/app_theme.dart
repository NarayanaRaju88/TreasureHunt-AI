import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Theme extension that exposes glassmorphism related tokens so widgets can
/// consume them via `Theme.of(context).extension<GlassmorphismTheme>()`.
@immutable
class GlassmorphismTheme extends ThemeExtension<GlassmorphismTheme> {
  const GlassmorphismTheme({
    required this.tint,
    required this.borderColor,
    required this.shadowColor,
    required this.blurSigma,
    required this.borderRadius,
  });

  final Color tint;
  final Color borderColor;
  final Color shadowColor;
  final double blurSigma;
  final double borderRadius;

  @override
  GlassmorphismTheme copyWith({
    Color? tint,
    Color? borderColor,
    Color? shadowColor,
    double? blurSigma,
    double? borderRadius,
  }) {
    return GlassmorphismTheme(
      tint: tint ?? this.tint,
      borderColor: borderColor ?? this.borderColor,
      shadowColor: shadowColor ?? this.shadowColor,
      blurSigma: blurSigma ?? this.blurSigma,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  @override
  GlassmorphismTheme lerp(ThemeExtension<GlassmorphismTheme>? other, double t) {
    if (other is! GlassmorphismTheme) return this;
    return GlassmorphismTheme(
      tint: Color.lerp(tint, other.tint, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      blurSigma: _lerpDouble(blurSigma, other.blurSigma, t),
      borderRadius: _lerpDouble(borderRadius, other.borderRadius, t),
    );
  }

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

  static const GlassmorphismTheme light = GlassmorphismTheme(
    tint: AppColors.glassLight,
    borderColor: AppColors.glassLightBorder,
    shadowColor: AppColors.glassShadow,
    blurSigma: 18,
    borderRadius: 20,
  );

  static const GlassmorphismTheme dark = GlassmorphismTheme(
    tint: AppColors.glassDark,
    borderColor: AppColors.glassDarkBorder,
    shadowColor: AppColors.glassShadow,
    blurSigma: 22,
    borderRadius: 20,
  );
}

/// Theme extension for gamification-specific colors used across the app.
@immutable
class GamificationTheme extends ThemeExtension<GamificationTheme> {
  const GamificationTheme({
    required this.xpBarColor,
    required this.xpBarTrackColor,
    required this.bronze,
    required this.silver,
    required this.gold,
    required this.platinum,
    required this.legendary,
  });

  final Color xpBarColor;
  final Color xpBarTrackColor;
  final Color bronze;
  final Color silver;
  final Color gold;
  final Color platinum;
  final Color legendary;

  @override
  GamificationTheme copyWith({
    Color? xpBarColor,
    Color? xpBarTrackColor,
    Color? bronze,
    Color? silver,
    Color? gold,
    Color? platinum,
    Color? legendary,
  }) {
    return GamificationTheme(
      xpBarColor: xpBarColor ?? this.xpBarColor,
      xpBarTrackColor: xpBarTrackColor ?? this.xpBarTrackColor,
      bronze: bronze ?? this.bronze,
      silver: silver ?? this.silver,
      gold: gold ?? this.gold,
      platinum: platinum ?? this.platinum,
      legendary: legendary ?? this.legendary,
    );
  }

  @override
  GamificationTheme lerp(ThemeExtension<GamificationTheme>? other, double t) {
    if (other is! GamificationTheme) return this;
    return GamificationTheme(
      xpBarColor: Color.lerp(xpBarColor, other.xpBarColor, t)!,
      xpBarTrackColor: Color.lerp(xpBarTrackColor, other.xpBarTrackColor, t)!,
      bronze: Color.lerp(bronze, other.bronze, t)!,
      silver: Color.lerp(silver, other.silver, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      platinum: Color.lerp(platinum, other.platinum, t)!,
      legendary: Color.lerp(legendary, other.legendary, t)!,
    );
  }

  static const GamificationTheme standard = GamificationTheme(
    xpBarColor: AppColors.xpBar,
    xpBarTrackColor: AppColors.xpBarTrack,
    bronze: AppColors.bronze,
    silver: AppColors.silver,
    gold: AppColors.gold,
    platinum: AppColors.platinum,
    legendary: AppColors.legendary,
  );
}

/// Central place for building the app's Material 3 light and dark themes.
class AppTheme {
  AppTheme._();

  static const double _radius = 16;

  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    final ColorScheme colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: isDark ? AppColors.primaryDark : AppColors.primaryLight,
      onPrimaryContainer: isDark ? AppColors.white : AppColors.primaryDark,
      secondary: AppColors.accent,
      onSecondary: AppColors.onAccent,
      secondaryContainer: isDark ? AppColors.accentDark : AppColors.accentLight,
      onSecondaryContainer: isDark ? AppColors.white : AppColors.accentDark,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.white,
      error: AppColors.error,
      onError: AppColors.onError,
      surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      onSurface: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
      surfaceContainerHighest:
          isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
      onSurfaceVariant: isDark ? AppColors.grey400 : AppColors.grey600,
      outline: isDark ? AppColors.darkOutline : AppColors.lightOutline,
      outlineVariant: isDark ? AppColors.grey800 : AppColors.grey300,
      shadow: AppColors.black,
      scrim: AppColors.black,
      inverseSurface: isDark ? AppColors.lightSurface : AppColors.darkSurface,
      onInverseSurface: isDark ? AppColors.black : AppColors.white,
      inversePrimary: AppColors.primaryLight,
    );

    final TextTheme baseTextTheme =
        isDark ? Typography.whiteMountainView : Typography.blackMountainView;
    final TextTheme textTheme = GoogleFonts.poppinsTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      textTheme: textTheme,
      primaryColor: AppColors.primary,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        foregroundColor:
            isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.grey400,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.poppins(
          color: isDark ? AppColors.grey500 : AppColors.grey600,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.poppins(
          color: isDark ? AppColors.grey400 : AppColors.grey700,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        errorStyle: GoogleFonts.poppins(
          color: AppColors.error,
          fontSize: 12,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius + 4),
          side: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
            width: 0.5,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor:
            isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
        selectedColor: AppColors.primary,
        labelStyle: GoogleFonts.poppins(fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: isDark ? AppColors.grey500 : AppColors.grey600,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
        elevation: 4,
        height: 68,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        elevation: 4,
      ),
      dialogTheme: DialogTheme(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius + 8),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.grey800 : AppColors.grey900,
        contentTextStyle: GoogleFonts.poppins(
          color: AppColors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
        thickness: 0.5,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.grey400,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primaryLight
              : AppColors.grey300,
        ),
      ),
      iconTheme: IconThemeData(
        color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
      ),
      extensions: <ThemeExtension<dynamic>>[
        isDark ? GlassmorphismTheme.dark : GlassmorphismTheme.light,
        GamificationTheme.standard,
      ],
    );
  }
}

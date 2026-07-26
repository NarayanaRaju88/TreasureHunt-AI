import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Convenience extensions on [BuildContext] to reduce boilerplate when
/// accessing theme, media query and navigation.
extension ThemeContextX on BuildContext {
  /// Current [ThemeData].
  ThemeData get theme => Theme.of(this);

  /// Current [TextTheme].
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Current [ColorScheme].
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// App's glassmorphism theme extension.
  GlassmorphismTheme get glass =>
      Theme.of(this).extension<GlassmorphismTheme>() ??
      GlassmorphismTheme.light;

  /// App's gamification theme extension.
  GamificationTheme get gamification =>
      Theme.of(this).extension<GamificationTheme>() ??
      GamificationTheme.standard;

  /// Whether the current theme is dark.
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

extension MediaContextX on BuildContext {
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Full screen size.
  Size get screenSize => MediaQuery.sizeOf(this);

  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Device pixel ratio.
  double get pixelRatio => MediaQuery.devicePixelRatioOf(this);

  /// Safe-area padding (notches, status bar, gesture bars).
  EdgeInsets get padding => MediaQuery.paddingOf(this);

  /// On-screen keyboard / view insets.
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  double get statusBarHeight => MediaQuery.paddingOf(this).top;
  double get bottomInset => MediaQuery.viewInsetsOf(this).bottom;

  /// True when the keyboard is visible.
  bool get isKeyboardOpen => MediaQuery.viewInsetsOf(this).bottom > 0;

  /// Text scale factor.
  TextScaler get textScaler => MediaQuery.textScalerOf(this);

  Orientation get orientation => MediaQuery.orientationOf(this);
  bool get isPortrait => orientation == Orientation.portrait;
  bool get isLandscape => orientation == Orientation.landscape;

  /// Simple responsive breakpoints.
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1024;
  bool get isDesktop => screenWidth >= 1024;

  /// Returns [width] as a fraction of the screen width.
  double widthFraction(double fraction) => screenWidth * fraction;

  /// Returns [height] as a fraction of the screen height.
  double heightFraction(double fraction) => screenHeight * fraction;
}

extension NavigationContextX on BuildContext {
  NavigatorState get navigator => Navigator.of(this);

  /// Pushes a widget route.
  Future<T?> push<T>(Widget page) =>
      Navigator.of(this).push<T>(MaterialPageRoute(builder: (_) => page));

  /// Replaces the current route with a widget route.
  Future<T?> pushReplacement<T, TO>(Widget page) =>
      Navigator.of(this).pushReplacement<T, TO>(
        MaterialPageRoute(builder: (_) => page),
      );

  /// Pops the current route if possible.
  void pop<T>([T? result]) {
    if (Navigator.of(this).canPop()) {
      Navigator.of(this).pop<T>(result);
    }
  }

  bool get canPop => Navigator.of(this).canPop();
}

extension FeedbackContextX on BuildContext {
  /// Shows a themed [SnackBar] with an optional [isError] styling.
  void showSnackBar(
    String message, {
    bool isError = false,
    Duration? duration,
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(this);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration ?? const Duration(seconds: 3),
          backgroundColor: isError ? theme.colorScheme.error : null,
          action: action,
        ),
      );
  }

  /// Hides any currently visible snackbar.
  void hideSnackBar() =>
      ScaffoldMessenger.of(this).hideCurrentSnackBar();

  /// Dismisses the on-screen keyboard.
  void unfocus() => FocusScope.of(this).unfocus();
}

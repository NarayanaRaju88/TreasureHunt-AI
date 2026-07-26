import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../main.dart';
import '../providers/auth_provider.dart';

/// Animated splash screen shown on cold start.
///
/// Plays a Lottie treasure animation with the app logo and tagline, then
/// auto-navigates after [AppConstants.splashDuration] based on onboarding and
/// authentication state.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  Timer? _navTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _scale = CurvedAnimation(parent: _logoController, curve: Curves.elasticOut);
    _fade = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );
    _logoController.forward();

    // Auto-navigate after ~3 seconds.
    _navTimer = Timer(const Duration(seconds: 3), _decideNavigation);
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _logoController.dispose();
    super.dispose();
  }

  void _decideNavigation() {
    if (_navigated || !mounted) return;
    _navigated = true;

    final prefs = ref.read(sharedPreferencesProvider);
    final bool onboarded =
        prefs.getBool(AppConstants.keyOnboardingComplete) ?? false;

    if (!onboarded) {
      context.goNamed(AppRoutes.onboarding);
      return;
    }

    final authState = ref.read(authStateProvider);
    final bool signedIn = authState.maybeWhen(
      data: (user) => user != null,
      orElse: () => ref.read(currentUserProvider).isAuthenticated,
    );

    context.goNamed(signedIn ? AppRoutes.home : AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Spacer(flex: 2),
                // Lottie treasure animation with graceful fallback.
                SizedBox(
                  height: 220,
                  width: 220,
                  child: Lottie.asset(
                    AppConstants.treasureAnimation,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return ScaleTransition(
                        scale: _scale,
                        child: _LogoFallback(),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _fade,
                  child: const Text(
                    AppConstants.appName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FadeTransition(
                  opacity: _fade,
                  child: Text(
                    'Discover Something Amazing Every Day',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Icon(
        Icons.travel_explore_rounded,
        size: 84,
        color: Colors.white,
      ),
    );
  }
}

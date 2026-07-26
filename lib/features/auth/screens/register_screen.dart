import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/glassmorphic_container.dart';
import '../providers/auth_provider.dart';
import '../widgets/animated_auth_background.dart';
import '../widgets/auth_text_field.dart';

/// Interest option shown as a selectable chip during registration.
class _Interest {
  const _Interest(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Registration screen collecting name, email, password, confirmation and a
/// set of interests used to personalize AI-generated treasures.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  final Set<String> _selectedInterests = <String>{};

  static const List<_Interest> _interests = <_Interest>[
    _Interest('Nature', Icons.park_rounded),
    _Interest('Food', Icons.restaurant_rounded),
    _Interest('History', Icons.account_balance_rounded),
    _Interest('Art', Icons.palette_rounded),
    _Interest('Adventure', Icons.terrain_rounded),
    _Interest('Culture', Icons.theater_comedy_rounded),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    context.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedInterests.isEmpty) {
      context.showSnackBar('Pick at least one interest', isError: true);
      return;
    }
    final ok = await ref.read(currentUserProvider.notifier).register(
          _emailController.text.trim(),
          _passwordController.text,
          displayName: _nameController.text.trim(),
        );
    if (!mounted) return;
    if (ok) {
      context.goNamed(AppRoutes.home);
    } else {
      final error = ref.read(currentUserProvider).error;
      if (error != null) context.showSnackBar(error, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool loading = ref.watch(currentUserProvider).isLoading;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          const AnimatedAuthBackground(),
          SafeArea(
            child: Column(
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.canPop
                        ? context.pop()
                        : context.goNamed(AppRoutes.login),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'Create your account',
                          textAlign: TextAlign.center,
                          style: context.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Join the hunt and start exploring',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 22),
                        GlassmorphicContainer(
                          padding: const EdgeInsets.all(22),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                AuthTextField(
                                  controller: _nameController,
                                  hint: 'Full name',
                                  icon: Icons.person_outline_rounded,
                                  validator: Validators.name,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization: TextCapitalization.words,
                                ),
                                const SizedBox(height: 14),
                                AuthTextField(
                                  controller: _emailController,
                                  hint: 'Email',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: Validators.email,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 14),
                                AuthTextField(
                                  controller: _passwordController,
                                  hint: 'Password',
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: _obscure,
                                  validator: Validators.password,
                                  textInputAction: TextInputAction.next,
                                  suffix: IconButton(
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                AuthTextField(
                                  controller: _confirmController,
                                  hint: 'Confirm password',
                                  icon: Icons.lock_reset_rounded,
                                  obscureText: _obscureConfirm,
                                  validator: (v) => Validators.confirmPassword(
                                      v, _passwordController.text),
                                  textInputAction: TextInputAction.done,
                                  suffix: IconButton(
                                    onPressed: () => setState(() =>
                                        _obscureConfirm = !_obscureConfirm),
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Your interests',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.95),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: _interests.map((interest) {
                                    final bool selected = _selectedInterests
                                        .contains(interest.label);
                                    return _InterestChip(
                                      interest: interest,
                                      selected: selected,
                                      onTap: () {
                                        setState(() {
                                          if (selected) {
                                            _selectedInterests
                                                .remove(interest.label);
                                          } else {
                                            _selectedInterests
                                                .add(interest.label);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: loading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppColors.primaryDark,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: loading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                AppColors.primary,
                                              ),
                                            ),
                                          )
                                        : const Text(
                                            'Create Account',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              'Already have an account? ',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            GestureDetector(
                              onTap: loading
                                  ? null
                                  : () => context.goNamed(AppRoutes.login),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({
    required this.interest,
    required this.selected,
    required this.onTap,
  });

  final _Interest interest;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white.withValues(alpha: selected ? 1 : 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              interest.icon,
              size: 17,
              color: selected ? AppColors.primaryDark : Colors.white,
            ),
            const SizedBox(width: 7),
            Text(
              interest.label,
              style: TextStyle(
                color: selected ? AppColors.primaryDark : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

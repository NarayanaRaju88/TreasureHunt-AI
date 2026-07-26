import '../constants/app_constants.dart';

/// Reusable form field validators.
///
/// Each validator returns `null` when the value is valid, or a human-readable
/// error string when it is not — matching the signature expected by
/// [TextFormField.validator].
class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
  );

  static final RegExp _nameRegex = RegExp(r"^[a-zA-Z][a-zA-Z '\-.]*$");
  static final RegExp _upperCase = RegExp(r'[A-Z]');
  static final RegExp _lowerCase = RegExp(r'[a-z]');
  static final RegExp _digit = RegExp(r'\d');
  static final RegExp _specialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\[\]/\\;+=~`]');

  // ---------------------------------------------------------------------------
  // Email
  // ---------------------------------------------------------------------------
  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your email address.';
    if (!_emailRegex.hasMatch(v)) return 'Enter a valid email address.';
    return null;
  }

  // ---------------------------------------------------------------------------
  // Password (for registration / strong checks)
  // ---------------------------------------------------------------------------
  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Please enter a password.';
    if (v.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters.';
    }
    if (v.length > AppConstants.maxPasswordLength) {
      return 'Password must be under ${AppConstants.maxPasswordLength} characters.';
    }
    if (!_upperCase.hasMatch(v)) {
      return 'Include at least one uppercase letter.';
    }
    if (!_lowerCase.hasMatch(v)) {
      return 'Include at least one lowercase letter.';
    }
    if (!_digit.hasMatch(v)) return 'Include at least one number.';
    if (!_specialChar.hasMatch(v)) {
      return 'Include at least one special character.';
    }
    return null;
  }

  /// A lighter password check used on the login screen where we only need a
  /// non-empty value of reasonable length (rules are enforced at signup).
  static String? loginPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Please enter your password.';
    if (v.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters.';
    }
    return null;
  }

  /// Validates that [value] matches [original] (confirm-password fields).
  static String? confirmPassword(String? value, String? original) {
    final v = value ?? '';
    if (v.isEmpty) return 'Please confirm your password.';
    if (v != (original ?? '')) return 'Passwords do not match.';
    return null;
  }

  // ---------------------------------------------------------------------------
  // Name
  // ---------------------------------------------------------------------------
  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your name.';
    if (v.length < AppConstants.minNameLength) {
      return 'Name must be at least ${AppConstants.minNameLength} characters.';
    }
    if (v.length > AppConstants.maxNameLength) {
      return 'Name must be under ${AppConstants.maxNameLength} characters.';
    }
    if (!_nameRegex.hasMatch(v)) {
      return 'Name can only contain letters, spaces, and - . \'';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Username
  // ---------------------------------------------------------------------------
  static String? username(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please choose a username.';
    if (v.length < 3) return 'Username must be at least 3 characters.';
    if (v.length > 20) return 'Username must be under 20 characters.';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
      return 'Only letters, numbers and underscores allowed.';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Generic helpers
  // ---------------------------------------------------------------------------
  static String? required(String? value, {String field = 'This field'}) {
    if ((value?.trim() ?? '').isEmpty) return '$field is required.';
    return null;
  }

  static String? maxLength(String? value, int max, {String field = 'This field'}) {
    if ((value?.length ?? 0) > max) {
      return '$field must be under $max characters.';
    }
    return null;
  }

  static String? bio(String? value) {
    if (value == null) return null;
    if (value.length > AppConstants.maxBioLength) {
      return 'Bio must be under ${AppConstants.maxBioLength} characters.';
    }
    return null;
  }

  /// Runs multiple validators in order and returns the first error found.
  static String? compose(
    String? value,
    List<String? Function(String?)> validators,
  ) {
    for (final validator in validators) {
      final result = validator(value);
      if (result != null) return result;
    }
    return null;
  }
}

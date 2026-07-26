/// Handy, null-safe extensions on [String] used throughout the app.
extension StringX on String {
  /// Capitalizes the first character, leaving the rest unchanged.
  String get capitalize {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  /// Capitalizes the first letter of each word.
  String get titleCase {
    if (isEmpty) return this;
    return split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? w : w.capitalize)
        .join(' ');
  }

  /// Removes all whitespace characters.
  String get removeAllWhitespace => replaceAll(RegExp(r'\s+'), '');

  /// Collapses repeated internal whitespace into single spaces and trims.
  String get normalizeSpaces => trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Truncates the string to [maxLength], appending [ellipsis] if truncated.
  String truncate(int maxLength, {String ellipsis = '…'}) {
    if (length <= maxLength) return this;
    if (maxLength <= ellipsis.length) return substring(0, maxLength);
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Returns the string reversed.
  String get reversed => split('').reversed.join();

  /// Returns up to two uppercase initials from the string.
  String get initials {
    final parts = trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      final single = parts.first;
      return single.length == 1
          ? single.toUpperCase()
          : single.substring(0, 2).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// A URL/anchor friendly slug: lowercase, hyphen-separated, alnum only.
  String get slugify => toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'-+'), '-');

  // ---------------------------------------------------------------------------
  // Validation predicates
  // ---------------------------------------------------------------------------
  bool get isValidEmail => RegExp(
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
      ).hasMatch(trim());

  bool get isNumeric => RegExp(r'^-?\d+(\.\d+)?$').hasMatch(trim());

  bool get isAlphabetic => RegExp(r'^[a-zA-Z]+$').hasMatch(this);

  bool get isAlphanumeric => RegExp(r'^[a-zA-Z0-9]+$').hasMatch(this);

  bool get isValidUrl {
    final uri = Uri.tryParse(trim());
    return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
  }

  /// True when the string is empty or only whitespace.
  bool get isBlank => trim().isEmpty;
  bool get isNotBlank => trim().isNotEmpty;

  // ---------------------------------------------------------------------------
  // Parsing helpers
  // ---------------------------------------------------------------------------
  int? get toIntOrNull => int.tryParse(trim());
  double? get toDoubleOrNull => double.tryParse(trim());

  /// Masks all but the domain of an email, e.g. "j***@mail.com".
  String get maskEmail {
    if (!isValidEmail) return this;
    final parts = split('@');
    final name = parts[0];
    final masked = name.length <= 1
        ? name
        : '${name[0]}${'*' * (name.length - 1)}';
    return '$masked@${parts[1]}';
  }
}

/// Extensions on nullable strings for concise null/blank handling.
extension NullableStringX on String? {
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;
  bool get isNotNullOrBlank => !isNullOrBlank;

  /// Returns [fallback] when the string is null or blank.
  String orElse(String fallback) => isNullOrBlank ? fallback : this!;
}

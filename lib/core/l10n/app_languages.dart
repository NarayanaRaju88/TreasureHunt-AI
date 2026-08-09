/// Supported in-app languages (persisted via Settings `language` code).
class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.nativeName,
    required this.englishName,
  });

  final String code;
  final String nativeName;
  final String englishName;

  String get label =>
      nativeName == englishName ? englishName : '$nativeName ($englishName)';
}

/// Languages available in Settings / Profile.
const List<AppLanguage> kSupportedAppLanguages = <AppLanguage>[
  AppLanguage(code: 'en', nativeName: 'English', englishName: 'English'),
  AppLanguage(code: 'hi', nativeName: 'हिन्दी', englishName: 'Hindi'),
  AppLanguage(code: 'te', nativeName: 'తెలుగు', englishName: 'Telugu'),
  AppLanguage(code: 'ta', nativeName: 'தமிழ்', englishName: 'Tamil'),
  AppLanguage(code: 'kn', nativeName: 'ಕನ್ನಡ', englishName: 'Kannada'),
  AppLanguage(code: 'ml', nativeName: 'മലയാളം', englishName: 'Malayalam'),
  AppLanguage(code: 'mr', nativeName: 'मराठी', englishName: 'Marathi'),
  AppLanguage(code: 'bn', nativeName: 'বাংলা', englishName: 'Bengali'),
  AppLanguage(code: 'gu', nativeName: 'ગુજરાતી', englishName: 'Gujarati'),
  AppLanguage(code: 'es', nativeName: 'Español', englishName: 'Spanish'),
  AppLanguage(code: 'fr', nativeName: 'Français', englishName: 'French'),
  AppLanguage(code: 'ar', nativeName: 'العربية', englishName: 'Arabic'),
];

AppLanguage? appLanguageByCode(String code) {
  for (final lang in kSupportedAppLanguages) {
    if (lang.code == code) return lang;
  }
  return null;
}

enum AppLanguage {
  uzbek('uz', 'O\'zbekcha', 'O\'zbekcha'),
  russian('ru', 'Русский', 'Русский'),
  english('en', 'English', 'English');

  const AppLanguage(this.code, this.label, this.nativeLabel);

  final String code;
  final String label;
  final String nativeLabel;

  static AppLanguage fromCode(String? code) {
    if (code == 'ru') return AppLanguage.russian;
    if (code == 'en') return AppLanguage.english;
    return AppLanguage.uzbek;
  }
}

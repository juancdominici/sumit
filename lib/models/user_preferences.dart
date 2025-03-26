class UserPreferences {
  UserPreferences({
    required this.userId,
    required this.language,
    required this.darkMode,
    required this.currency,
    required this.hasFirstLogin,
  });

  final String userId;
  final String language;
  final bool darkMode;
  final String currency;
  final bool hasFirstLogin;

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      userId: json['user_id'],
      language: json['language'],
      darkMode: json['dark_mode'],
      currency: json['currency'],
      hasFirstLogin: json['first_login'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'language': language,
      'dark_mode': darkMode,
      'currency': currency,
      'first_login': hasFirstLogin,
    };
  }
}

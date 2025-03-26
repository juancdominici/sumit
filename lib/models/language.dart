class Language {
  final String id;
  final String i18nCode;
  final String name;

  Language({required this.id, required this.i18nCode, required this.name});

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      id: json['id'] as String,
      i18nCode: json['i18n_code'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'i18n_code': i18nCode, 'name': name};
  }
}

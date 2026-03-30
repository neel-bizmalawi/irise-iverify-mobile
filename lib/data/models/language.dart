class Language {
  final int? id;
  final String langName;

  Language({
    this.id,
    required this.langName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lang_name': langName,
    };
  }

  factory Language.fromMap(Map<String, dynamic> map) {
    return Language(
      id: map['id'] as int?,
      langName: map['lang_name'] as String,
    );
  }

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      langName: json['lang_name'] as String,
    );
  }
}

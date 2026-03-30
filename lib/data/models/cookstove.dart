class Cookstove {
  final int? id;
  final String cookstoveName;

  Cookstove({
    this.id,
    required this.cookstoveName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cookstove_name': cookstoveName,
    };
  }

  factory Cookstove.fromMap(Map<String, dynamic> map) {
    return Cookstove(
      id: map['id'] as int?,
      cookstoveName: map['cookstove_name'] as String,
    );
  }

  factory Cookstove.fromJson(Map<String, dynamic> json) {
    return Cookstove(
      cookstoveName: json['cookstove_name'] as String,
    );
  }
}

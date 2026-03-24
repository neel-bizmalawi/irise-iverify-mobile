class AuthResponse {
  final String? message;
  final UserData? user;
  final String? accessToken;
  final String? refreshToken;

  AuthResponse({
    this.message,
    this.user,
    this.accessToken,
    this.refreshToken,
  });

  bool get success => accessToken != null && accessToken!.isNotEmpty;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message: json['message'],
      user: json['user'] != null ? UserData.fromJson(json['user']) : null,
      accessToken: json['AccessTokenss'], // Note: API uses 'AccessTokenss'
      refreshToken: json['RefreshToken'],
    );
  }
}

class UserData {
  final int? id;
  final String? email;
  final String? name;

  UserData({
    this.id,
    this.email,
    this.name,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'],
      email: json['email'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
    };
  }
}

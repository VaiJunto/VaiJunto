class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final List<String> profileTypes;
  final String? universityId;
  final String? universityName;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.profileTypes,
    this.universityId,
    this.universityName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      profileTypes: List<String>.from(json['profileTypes'] ?? []),
      universityId: json['universityId'],
      universityName: json['universityName'],
    );
  }
}

class AuthResponse {
  final String token;
  final UserModel user;

  AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
      user: UserModel.fromJson(json['user']),
    );
  }
}

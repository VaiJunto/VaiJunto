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

/// Resposta de `/auth/login`: ou já vem autenticado (device conhecido), ou
/// só um [challengeToken] pra trocar pelo código de e-mail em
/// `/auth/verify-device` (device novo — MFA de primeiro acesso).
class LoginResult {
  final bool deviceVerificationRequired;
  final String? challengeToken;
  final String? token;
  final UserModel? user;

  LoginResult._({
    required this.deviceVerificationRequired,
    this.challengeToken,
    this.token,
    this.user,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final requiresChallenge = json['deviceVerificationRequired'] == true;
    return LoginResult._(
      deviceVerificationRequired: requiresChallenge,
      challengeToken: json['challengeToken'] as String?,
      token: json['token'] as String?,
      user: requiresChallenge ? null : UserModel.fromJson(json['user']),
    );
  }
}

/// Resposta do cadastro. Sem usuário/token de propósito — a conta só fica
/// utilizável depois que o código de confirmação enviado a [email] é validado.
class RegisterResult {
  final String email;
  final String message;

  RegisterResult({required this.email, required this.message});

  factory RegisterResult.fromJson(Map<String, dynamic> json) {
    return RegisterResult(
      email: json['email'] as String,
      message: json['message'] as String? ?? '',
    );
  }
}

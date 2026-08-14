import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthRepository(dio, secureStorage);
});

class AuthRepository {
  final Dio _dio;
  final SecureStorage _storage;

  AuthRepository(this._dio, this._storage);

  // Os DioException sobem intactos de propósito: quem trata (AuthNotifier)
  // converte para ApiException e extrai a mensagem que o backend mandou.
  // Embrulhar aqui num Exception genérico faria vazar o stack cru para a tela.
  Future<LoginResult> login(String email, String password) async {
    final deviceId = await _storage.getOrCreateDeviceId();

    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
      'deviceId': deviceId,
    });

    final result = LoginResult.fromJson(response.data);
    if (!result.deviceVerificationRequired) {
      await _storage.saveToken(result.token!);
      await _storage.saveUserId(result.user!.id);
    }

    return result;
  }

  /// Troca o challengeToken (device novo no login) + o código recebido por
  /// e-mail por uma sessão de verdade — mesma forma de resposta do login
  /// normal/verifyEmail, já autenticado.
  Future<UserModel> verifyDevice(String challengeToken, String code) async {
    final response = await _dio.post('/auth/verify-device', data: {
      'challengeToken': challengeToken,
      'code': code,
    });

    final authData = AuthResponse.fromJson(response.data);
    await _storage.saveToken(authData.token);
    await _storage.saveUserId(authData.user.id);

    return authData.user;
  }

  Future<void> resendDeviceCode(String challengeToken) async {
    await _dio.post('/auth/resend-device-code', data: {
      'challengeToken': challengeToken,
    });
  }

  /// Sem token de propósito — a conta só fica utilizável após [verifyEmail].
  Future<RegisterResult> register(Map<String, dynamic> requestData) async {
    final response = await _dio.post('/auth/register', data: requestData);
    return RegisterResult.fromJson(response.data);
  }

  /// O código confirmado já é o login: o backend devolve token igual ao de
  /// login/register bem-sucedido. Manda o deviceId junto para que este
  /// aparelho já saia do cadastro marcado como conhecido — sem isso, o
  /// próximo login neste mesmo device pediria o desafio de MFA de novo.
  Future<UserModel> verifyEmail(String email, String code) async {
    final deviceId = await _storage.getOrCreateDeviceId();

    final response = await _dio.post('/auth/verify-email', data: {
      'email': email,
      'code': code,
      'deviceId': deviceId,
    });

    final authData = AuthResponse.fromJson(response.data);
    await _storage.saveToken(authData.token);
    await _storage.saveUserId(authData.user.id);

    return authData.user;
  }

  Future<void> resendVerificationCode(String email) async {
    await _dio.post('/auth/resend-verification', data: {'email': email});
  }

  /// Usado no boot do app para restaurar a sessão a partir do token salvo.
  Future<UserModel> fetchCurrentUser() async {
    final response = await _dio.get('/auth/me');
    return UserModel.fromJson(response.data);
  }

  Future<bool> hasStoredToken() async => (await _storage.getToken()) != null;

  Future<void> logout() async {
    await _storage.clearAll();
  }
}

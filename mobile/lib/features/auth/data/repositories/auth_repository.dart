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
  Future<UserModel> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    final authData = AuthResponse.fromJson(response.data);
    await _storage.saveToken(authData.token);
    await _storage.saveUserId(authData.user.id);

    return authData.user;
  }

  /// Sem token de propósito — a conta só fica utilizável após [verifyEmail].
  Future<RegisterResult> register(Map<String, dynamic> requestData) async {
    final response = await _dio.post('/auth/register', data: requestData);
    return RegisterResult.fromJson(response.data);
  }

  /// O código confirmado já é o login: o backend devolve token igual ao de
  /// login/register bem-sucedido.
  Future<UserModel> verifyEmail(String email, String code) async {
    final response = await _dio.post('/auth/verify-email', data: {
      'email': email,
      'code': code,
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

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

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final authData = AuthResponse.fromJson(response.data);
      await _storage.saveToken(authData.token);
      await _storage.saveUserId(authData.user.id);
      
      return authData.user;
    } catch (e) {
      throw Exception('Falha no login: $e');
    }
  }

  Future<UserModel> register(Map<String, dynamic> requestData) async {
    try {
      final response = await _dio.post('/auth/register', data: requestData);
      
      final authData = AuthResponse.fromJson(response.data);
      await _storage.saveToken(authData.token);
      await _storage.saveUserId(authData.user.id);
      
      return authData.user;
    } catch (e) {
      throw Exception('Falha no cadastro: $e');
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }
}

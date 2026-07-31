import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return ApiClient(secureStorage).dio;
});

class ApiClient {
  late final Dio dio;
  final SecureStorage _secureStorage;

  // Utilize um IP configurável, para emuladores Android use 10.0.2.2
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1';

  ApiClient(this._secureStorage) {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Tratar erros globais de autenticação (ex: 401)
        if (e.response?.statusCode == 401) {
          _secureStorage.clearAll();
          // Aqui caberia um evento global para deslogar via Riverpod
        }
        return handler.next(e);
      },
    ));
  }
}

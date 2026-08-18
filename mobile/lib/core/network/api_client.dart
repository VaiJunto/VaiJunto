import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import 'dart:math';
import '../storage/secure_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return ApiClient(secureStorage).dio;
});

class ApiClient {
  late final Dio dio;
  final SecureStorage _secureStorage;

  // Dev (padrão, sem flags): dispositivo físico via USB, requer
  // `adb reverse tcp:8080 tcp:8080`. Em emulador Android, buildar com
  // --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1.
  // Prod: --dart-define=API_BASE_URL=https://api.vaijunto.app.br/api/v1
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8080/api/v1',
  );

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
        final correlationId =
            '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${Random.secure().nextInt(1 << 32).toRadixString(36)}';
        options.headers['X-Correlation-Id'] = correlationId;
        options.extra['correlationId'] = correlationId;
        final token = options.path.startsWith('/admin')
            ? await _secureStorage.getAdminToken()
            : await _secureStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        final correlationId = e.response?.headers.value('x-correlation-id') ??
            e.requestOptions.extra['correlationId'];
        developer.log(
          'API request failed: method=${e.requestOptions.method} '
          'url=${e.requestOptions.uri} type=${e.type.name} '
          'status=${e.response?.statusCode} correlationId=$correlationId '
          'response=${e.response?.data}',
          name: 'ApiClient',
          level: 1000,
          error: e.error ?? e,
          stackTrace: e.stackTrace,
        );
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

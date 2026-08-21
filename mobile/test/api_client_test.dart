import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaijunto/core/network/api_client.dart';
import 'package:vaijunto/core/storage/secure_storage.dart';

void main() {
  test('login publico nao le token antes de enviar', () async {
    final client = ApiClient(_ThrowingTokenStorage()).dio;
    final adapter = _RecordingAdapter();
    client.httpClientAdapter = adapter;

    await client.post<void>('/auth/login', data: {
      'email': 'diagnostico@aluno.cps.sp.gov.br',
      'password': 'Teste123!',
      'deviceId': 'diagnostico',
    });

    expect(adapter.calls, 1);
  });
}

class _ThrowingTokenStorage extends SecureStorage {
  _ThrowingTokenStorage() : super(const FlutterSecureStorage());

  @override
  Future<String?> getToken() => throw StateError('token local corrompido');

  @override
  Future<String?> getAdminToken() =>
      throw StateError('token administrativo local corrompido');
}

class _RecordingAdapter implements HttpClientAdapter {
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    return ResponseBody.fromString('{}', 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

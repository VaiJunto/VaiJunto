import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaijunto/core/network/api_exception.dart';

void main() {
  test('extrai mensagem e codigo quando a resposta JSON chega como texto', () {
    final options = RequestOptions(path: '/auth/login');
    final error = DioException.badResponse(
      statusCode: 401,
      requestOptions: options,
      response: Response<Object?>(
        requestOptions: options,
        statusCode: 401,
        data: '{"code":"INVALID_CREDENTIALS","message":"Senha incorreta."}',
        headers: Headers.fromMap({
          'x-correlation-id': ['abc-123'],
        }),
      ),
    );

    final result = ApiException.fromDio(error);

    expect(result.message, 'Senha incorreta.');
    expect(result.code, 'INVALID_CREDENTIALS');
    expect(result.correlationId, 'abc-123');
    expect(result.toString(), contains('ref. abc-123'));
  });

  test('explica falha sem resposta e preserva a referencia da requisicao', () {
    final options = RequestOptions(
      path: '/admin/auth/login',
      extra: {'correlationId': 'local-456'},
    );
    final error = DioException.connectionError(
      requestOptions: options,
      reason: 'Failed to fetch',
    );

    final result = ApiException.fromDio(error);

    expect(result.message, contains('CORS'));
    expect(result.correlationId, 'local-456');
  });
}

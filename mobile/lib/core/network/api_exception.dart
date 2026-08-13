import 'package:dio/dio.dart';

/// Erro de API já traduzido para uma mensagem que pode ir direto na tela.
///
/// O backend responde `{"code": "...", "message": "..."}` via
/// GlobalExceptionHandler; aqui extraímos os dois e caímos para mensagens
/// genéricas quando não houver corpo. O `code` existe para telas que precisam
/// reagir de forma diferente a um erro específico (ex: EMAIL_NOT_VERIFIED
/// leva para a tela de confirmação em vez de só mostrar um snackbar) sem
/// depender de comparar a mensagem traduzida.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  factory ApiException.fromDio(DioException e) {
    final response = e.response;
    final data = response?.data;

    if (data is Map && data['message'] is String) {
      final message = data['message'] as String;
      final code = data['code'] is String ? data['code'] as String : null;
      if (message.trim().isNotEmpty) {
        return ApiException(message, statusCode: response?.statusCode, code: code);
      }
    }

    return ApiException(
      switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          'O servidor demorou para responder. Tente novamente.',
        DioExceptionType.connectionError =>
          'Não foi possível conectar ao servidor. Verifique sua conexão.',
        _ => switch (response?.statusCode ?? 0) {
            401 => 'E-mail ou senha incorretos.',
            403 => 'Acesso negado.',
            404 => 'Recurso não encontrado.',
            >= 500 => 'Erro no servidor. Tente novamente mais tarde.',
            _ => 'Algo deu errado. Tente novamente.',
          },
      },
      statusCode: response?.statusCode,
    );
  }

  @override
  String toString() => message;
}

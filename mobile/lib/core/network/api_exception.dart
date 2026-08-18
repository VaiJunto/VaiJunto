import 'dart:convert';

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
  const ApiException(
    this.message, {
    this.statusCode,
    this.code,
    this.correlationId,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final String? correlationId;

  factory ApiException.fromDio(DioException e) {
    final response = e.response;
    final data = _responseMap(response?.data);
    final correlationId = response?.headers.value('x-correlation-id') ??
        e.requestOptions.extra['correlationId']?.toString();

    if (data != null && data['message'] is String) {
      final message = data['message'] as String;
      final code = data['code'] is String ? data['code'] as String : null;
      if (message.trim().isNotEmpty) {
        return ApiException(message,
            statusCode: response?.statusCode,
            code: code,
            correlationId: correlationId);
      }
    }

    final path = e.requestOptions.path;
    final isAdminLogin = path.endsWith('/admin/auth/login');
    final isUserLogin = path.endsWith('/auth/login') && !isAdminLogin;

    return ApiException(
      switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          'O servidor demorou para responder. Tente novamente.',
        DioExceptionType.connectionError =>
          'Não foi possível conectar à API. Verifique se o servidor está no ar e se o acesso não foi bloqueado por CORS.',
        DioExceptionType.badCertificate =>
          'O certificado de segurança da API não pôde ser validado.',
        DioExceptionType.cancel => 'A requisição foi cancelada.',
        _ => switch (response?.statusCode ?? 0) {
            0 =>
              'A API não respondeu. Confira o endereço configurado e o bloqueio de CORS no navegador.',
            401 when isAdminLogin => 'Credenciais administrativas inválidas.',
            401 when isUserLogin => 'E-mail ou senha incorretos.',
            401 => 'Sua sessão expirou. Entre novamente.',
            403 => 'Você não tem autorização para realizar esta ação.',
            400 => 'Não foi possível concluir por uma regra da carona.',
            404 => 'Recurso não encontrado.',
            >= 500 => 'Erro no servidor. Tente novamente mais tarde.',
            _ => 'Algo deu errado. Tente novamente.',
          },
      },
      statusCode: response?.statusCode,
      correlationId: correlationId,
    );
  }

  @override
  String toString() {
    final details = <String>[
      if (code != null) code!,
      if (correlationId != null) 'ref. $correlationId',
    ];
    return details.isEmpty ? message : '$message (${details.join(' • ')})';
  }
}

Map<String, dynamic>? _responseMap(Object? data) {
  if (data is Map) return Map<String, dynamic>.from(data);
  if (data is! String || data.trim().isEmpty) return null;

  try {
    final decoded = jsonDecode(data);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
  } on FormatException {
    return null;
  }
}

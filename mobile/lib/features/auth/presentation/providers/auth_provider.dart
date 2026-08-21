import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

/// Dispara [AuthNotifier.restoreSession] uma única vez, no boot do app.
/// Ver uso em `main.dart`.
final sessionRestoreProvider = FutureProvider<void>((ref) {
  return ref.read(authStateProvider.notifier).restoreSession();
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AsyncValue.data(null));

  /// Retorna o token do desafio quando o backend exige confirmação deste
  /// dispositivo. Esse resultado esperado não deve virar [AsyncValue.error]:
  /// a tela usa o token para abrir diretamente o passo de verificação.
  Future<String?> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.login(email, password);
      if (result.deviceVerificationRequired) {
        state = const AsyncValue.data(null);
        return result.challengeToken!;
      }
      state = AsyncValue.data(result.user);
    } on DioException catch (e, st) {
      state = AsyncValue.error(ApiException.fromDio(e), st);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
    return null;
  }

  /// Chamada pela tela de verificação de e-mail: o código confirmado JÁ é o
  /// login (o backend devolve token), então aqui só entra o resultado — não
  /// existe um "AuthNotifier.register()" porque o cadastro em si não
  /// autentica mais ninguém (ver RegisterScreen, que chama o repositório
  /// direto para não contaminar este estado global com um passo intermediário
  /// que não é login).
  void setAuthenticated(UserModel user) {
    state = AsyncValue.data(user);
  }

  /// Restaura a sessão a partir do token salvo, se houver.
  ///
  /// Sem isto, fechar e reabrir o app sempre caía na tela de login mesmo com
  /// um token de 3 dias ainda válido guardado — a sessão era "persistente" só
  /// no storage, nunca lida de volta. `/auth/me` é a fonte da verdade: se o
  /// token expirou ou foi invalidado, o 401 daqui é quem decide o logout, não
  /// uma checagem de data feita só no aparelho.
  Future<void> restoreSession() async {
    final hasToken = await _repository.hasStoredToken();
    if (!hasToken) {
      state = const AsyncValue.data(null);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final user = await _repository.fetchCurrentUser();
      state = AsyncValue.data(user);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        await _repository.logout();
      }
      // Erro de rede (sem 401/403): mantém o token salvo — pode ser só falta
      // de conexão no boot — e deixa a tela de login abrir normalmente; o
      // usuário tenta de novo quando quiser.
      state = const AsyncValue.data(null);
    } catch (_) {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(null);
  }
}

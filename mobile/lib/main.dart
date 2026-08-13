import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/neo_brutal_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/widgets/vaijunto_logo.dart';
import 'features/home/presentation/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: VaiJuntoApp(),
    ),
  );
}

class VaiJuntoApp extends StatelessWidget {
  const VaiJuntoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VaiJunto',
      debugShowCheckedModeBanner: false,
      theme: buildNeoBrutalTheme(Brightness.light),
      darkTheme: buildNeoBrutalTheme(Brightness.dark),
      home: const _AppStartup(),
    );
  }
}

/// Tela raiz: espera a restauração de sessão terminar antes de decidir entre
/// login e app autenticado.
///
/// Sem esta espera, `_AuthGate` leria `authStateProvider` ainda no seu valor
/// inicial (`data(null)`) e mostraria a tela de login por um instante mesmo
/// quando existe um token válido salvo — a sessão pareceria não ser
/// persistente mesmo sendo.
class _AppStartup extends ConsumerWidget {
  const _AppStartup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restore = ref.watch(sessionRestoreProvider);

    return restore.when(
      data: (_) => const _AuthGate(),
      loading: () => const _SplashScreen(),
      error: (_, __) => const _AuthGate(),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VaiJuntoLogo(),
            SizedBox(height: 32),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

/// Decide entre login e app autenticado a partir de um único ponto.
///
/// Centralizar aqui evita que cada tela navegue por conta própria: a
/// RegisterScreen fica empilhada sobre a LoginScreen, então ambas ouviriam o
/// mesmo provider e reagiriam ao mesmo sucesso (mostrando duas mensagens, uma
/// delas errada). Trocando a raiz, a pilha inteira é substituída de uma vez.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;

    return user == null ? const LoginScreen() : HomeScreen(user: user);
  }
}

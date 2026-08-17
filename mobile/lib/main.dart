import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/neo_brutal_theme.dart';
import 'core/ui/neo_card.dart';
import 'core/ui/neo_loading_indicator.dart';
import 'core/ui/neo_street_backdrop.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/widgets/vaijunto_logo.dart';
import 'features/admin/presentation/screens/desktop_admin_entry_screen.dart';
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
      routes: {
        '/': (_) => const _AppStartup(),
        '/admin': (_) => const DesktopAdminEntryScreen(),
      },
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const NeoStreetBackdrop(
            variant: NeoStreetBackdropVariant.loading,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const VaiJuntoLogo(size: 62),
                      const SizedBox(height: 28),
                      NeoCard(
                        color: scheme.surface,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'VJ//LOCAL_BOOT',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: scheme.tertiary,
                                    fontSize: 9,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 4,
                                  ),
                                  color: scheme.secondary,
                                  child: Text(
                                    'SJC NODE',
                                    style:
                                        theme.textTheme.labelMedium?.copyWith(
                                      color: Colors.white,
                                      fontSize: 8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(height: 2, color: scheme.ink),
                            const SizedBox(height: 16),
                            const NeoBootRail(label: 'RECUPERANDO SUA ROTA'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'SESSÃO LOCAL • SEM DESVIOS • VAI JUNTO',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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

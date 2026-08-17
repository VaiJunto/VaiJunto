import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaijunto/core/app_version.dart';
import 'package:vaijunto/core/theme/neo_brutal_theme.dart';
import 'package:vaijunto/core/ui/neo_bottom_nav_bar.dart';
import 'package:vaijunto/core/ui/neo_button.dart';
import 'package:vaijunto/core/ui/neo_street_backdrop.dart';
import 'package:vaijunto/features/auth/data/models/user_model.dart';
import 'package:vaijunto/features/auth/presentation/screens/login_screen.dart';
import 'package:vaijunto/features/auth/presentation/screens/register_screen.dart';
import 'package:vaijunto/features/auth/presentation/widgets/password_requirements.dart';
import 'package:vaijunto/features/admin/presentation/screens/desktop_admin_entry_screen.dart';
import 'package:vaijunto/features/home/presentation/screens/home_screen.dart';
import 'package:vaijunto/features/demands/presentation/providers/demand_provider.dart';
import 'package:vaijunto/features/offers/presentation/providers/offer_provider.dart';

void main() {
  testWidgets('navbar exibe e seleciona todas as abas', (tester) async {
    var selectedIndex = 1;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildNeoBrutalTheme(Brightness.light),
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              bottomNavigationBar: NeoBottomNavBar(
                currentIndex: selectedIndex,
                onSelected: (index) => setState(() => selectedIndex = index),
                destinations: const [
                  NeoBottomNavDestination(
                      icon: Icons.route_rounded, label: 'Caronas'),
                  NeoBottomNavDestination(
                      icon: Icons.add_box_outlined, label: 'Criar'),
                  NeoBottomNavDestination(
                      icon: Icons.forum_rounded, label: 'Chat'),
                  NeoBottomNavDestination(
                      icon: Icons.tune_rounded, label: 'Ajustes'),
                ],
              ),
            );
          },
        ),
      ),
    );

    expect(find.text('CARONAS'), findsOneWidget);
    expect(find.text('CRIAR'), findsOneWidget);
    expect(find.text('CHAT'), findsOneWidget);
    expect(find.text('AJUSTES'), findsOneWidget);

    await tester.tap(find.text('CHAT'));
    await tester.pumpAndSettle();

    expect(selectedIndex, 2);
  });

  testWidgets('navbar mantém o ícone de Minhas em telas estreitas',
      (tester) async {
    tester.view.physicalSize = const Size(240, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildNeoBrutalTheme(Brightness.light),
        home: Scaffold(
          bottomNavigationBar: NeoBottomNavBar(
            currentIndex: 1,
            onSelected: (_) {},
            destinations: const [
              NeoBottomNavDestination(
                  icon: Icons.route_rounded, label: 'Caronas'),
              NeoBottomNavDestination(
                icon: Icons.directions_car_filled_rounded,
                label: 'Minhas',
              ),
              NeoBottomNavDestination(
                  icon: Icons.forum_outlined, label: 'Chat'),
              NeoBottomNavDestination(
                  icon: Icons.tune_rounded, label: 'Ajustes'),
            ],
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.directions_car_filled_rounded), findsOneWidget);
    expect(find.text('MINHAS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('área autenticada não estoura em largura de celular',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nearbyOffersProvider.overrideWith((ref, location) async => []),
          nearbyDemandsProvider.overrideWith((ref, location) async => []),
        ],
        child: MaterialApp(
          theme: buildNeoBrutalTheme(Brightness.light),
          builder: _disableAnimations,
          home: HomeScreen(
            user: UserModel(
              id: 'layout-test',
              name: 'Gabriel Silva',
              email: 'gabriel.silva@fatec.sp.gov.br',
              profileTypes: const ['PASSENGER'],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OFERECER CARONA').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('CONTINUAR'), findsOneWidget);
    expect(tester.getBottomRight(find.text('CONTINUAR')).dy, lessThan(760));

    await tester.pageBack();
    await tester.pumpAndSettle();

    for (final tab in ['Chat', 'Ajustes', 'Caronas']) {
      await tester.tap(find.descendant(
          of: find.byType(NeoBottomNavBar),
          matching: find.text(tab.toUpperCase())));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('login e cadastro cabem na primeira viewport do celular',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildNeoBrutalTheme(Brightness.dark),
          builder: _disableAnimations,
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('ENTRAR'), findsNWidgets(2));
    expect(find.textContaining('CRIAR CONTA'), findsOneWidget);
    expect(find.text('V $kAppVersion'), findsOneWidget);
    expect(
      tester.getBottomRight(find.textContaining('CRIAR CONTA')).dy,
      lessThan(830),
    );

    await tester.tap(find.textContaining('CRIAR CONTA'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('CONTINUAR'), findsNothing);
    expect(find.textContaining('VAN/FRETADO'), findsNothing);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.text('V $kAppVersion'), findsOneWidget);
    expect(find.text('COMECE A DIGITAR'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).last, 'Abcdefg1');
    await tester.pump();
    expect(find.text('PRONTA'), findsOneWidget);
    final createButton = find.ancestor(
      of: find.text('CRIAR CONTA'),
      matching: find.byType(NeoButton),
    );
    expect(
      find.descendant(
        of: createButton,
        matching: find.byIcon(Icons.arrow_forward_rounded),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .getBottomRight(
            find.descendant(
              of: createButton,
              matching: find.text('CRIAR CONTA'),
            ),
          )
          .dy,
      lessThan(830),
    );
  });

  test('mapa vivo normaliza o fim para o início do ciclo', () {
    expect(neoLoopProgress(0), 0);
    expect(neoLoopProgress(1), 0);
    expect(neoLoopProgress(12), 0);
    expect(neoLoopProgress(1.25), closeTo(0.25, 0.000001));
  });

  testWidgets('teclado nao empurra o login e revela os requisitos da senha',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildNeoBrutalTheme(Brightness.dark),
          builder: _disableAnimations,
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final createAccount = find.textContaining('CRIAR CONTA');
    final createAccountTop = tester.getTopLeft(createAccount).dy;
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pump();

    expect(
      tester.getTopLeft(createAccount).dy,
      closeTo(createAccountTop, 0.1),
    );

    tester.view.resetViewInsets();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildNeoBrutalTheme(Brightness.dark),
          builder: _disableAnimations,
          home: const RegisterScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.tap(find.byType(TextFormField).last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    const keyboardTop = 844.0 - 320.0;
    expect(
      tester.getBottomRight(find.byType(PasswordRequirements)).dy,
      lessThan(keyboardTop),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('entrada administrativa se adapta a telas grandes e compactas',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildNeoBrutalTheme(Brightness.dark),
          builder: _disableAnimations,
          home: const DesktopAdminEntryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CENTRAL DE\nOPERAÇÕES'), findsOneWidget);
    expect(find.text('ENTRAR NO PAINEL'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('ENTRAR NO PAINEL'));
    await tester.pumpAndSettle();
    expect(find.text('ACESSO ADMINISTRATIVO'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(3));
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(900, 760);
    await tester.pumpAndSettle();
    expect(find.text('ACESSO ADMINISTRATIVO'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _disableAnimations(BuildContext context, Widget? child) {
  return MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child!,
  );
}

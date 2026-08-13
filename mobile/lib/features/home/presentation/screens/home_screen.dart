import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_brutal_theme.dart';
import '../../../../core/ui/neo_avatar.dart';
import '../../../../core/ui/neo_button.dart';
import '../../../../core/ui/neo_card.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../demands/presentation/screens/create_demand_screen.dart';
import '../../../offers/presentation/screens/create_offer_screen.dart';

/// Tela inicial pós-autenticação.
///
/// Ainda não tem busca/listagem nem mapa — só os atalhos para publicar uma
/// demanda ou oferta, que é o que já existe de ponta a ponta com o backend.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.user});

  final UserModel user;

  bool _isDriver(UserModel user) => user.profileTypes.any((p) => p.contains('DRIVER'));

  void _openAccountSheet(BuildContext context, WidgetRef ref) {
    final isDriver = _isDriver(user);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: NeoCard(
            color: theme.colorScheme.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    NeoAvatar(name: user.name, size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name.toUpperCase(), style: theme.textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                NeoBadge(
                  color: isDriver ? theme.colorScheme.secondary : theme.colorScheme.surface,
                  child: Text(isDriver ? 'MOTORISTA' : 'PASSAGEIRO'),
                ),
                const SizedBox(height: 20),
                NeoOutlineButton(
                  height: 48,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    ref.read(authStateProvider.notifier).logout();
                  },
                  child: const Text('SAIR'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.ink;
    final firstName = user.name.trim().split(' ').first;
    final isDriver = _isDriver(user);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.rotate(
              angle: -0.06,
              child: Container(
                width: 32,
                height: 32,
                decoration: NeoBrutal.decoration(
                  color: theme.colorScheme.secondary,
                  borderColor: ink,
                  radius: 8,
                  offset: NeoBrutal.shadowOffsetSmall,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.airport_shuttle_rounded, size: 18, color: ink),
              ),
            ),
            const SizedBox(width: 10),
            const Text('VAIJUNTO'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: NeoAvatar(
              name: user.name,
              onTap: () => _openAccountSheet(context, ref),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'OLÁ, ${firstName.toUpperCase()}',
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              NeoBadge(
                color: isDriver ? theme.colorScheme.secondary : theme.colorScheme.surface,
                child: Text(isDriver ? 'MOTORISTA' : 'PASSAGEIRO'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          NeoButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateDemandScreen()),
            ),
            icon: const Icon(Icons.search_rounded),
            child: const Text('PEDIR CARONA'),
          ),
          if (isDriver) ...[
            const SizedBox(height: 14),
            NeoOutlineButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateOfferScreen()),
              ),
              icon: const Icon(Icons.directions_car_filled_rounded),
              child: const Text('PUBLICAR ROTA'),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Buscar caronas/rotas publicadas e acompanhar viagens em tempo real '
            'chegam nas próximas etapas.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

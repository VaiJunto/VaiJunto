import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/neo_brutal_theme.dart';
import '../../../../core/ui/app_version_label.dart';
import '../../../../core/ui/neo_avatar.dart';
import '../../../../core/ui/neo_button.dart';
import '../../../../core/ui/neo_card.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../vehicles/presentation/screens/vehicles_screen.dart';
import '../../../addresses/presentation/screens/addresses_screen.dart';
import 'blocked_users_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, required this.user});

  final UserModel user;

  bool get _isDriver =>
      user.profileTypes.any((profile) => profile.contains('DRIVER'));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NeoCard(
              color: scheme.surface,
              padding: const EdgeInsets.all(14),
              offset: NeoBrutal.shadowOffsetSmall,
              child: Row(
                children: [
                  NeoAvatar(name: user.name, size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (user.fullName ?? user.name).toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user.email,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        if ((user.course ?? '').isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            user.course!,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                  NeoBadge(
                    color: scheme.secondary,
                    child: Text(_isDriver ? 'MOTORISTA' : 'PASSAGEIRO'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('SISTEMA', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            NeoCard(
              color: scheme.surface,
              padding: EdgeInsets.zero,
              offset: NeoBrutal.shadowOffsetSmall,
              child: Column(
                children: [
                  _SettingRow(
                    icon: Icons.directions_car_rounded,
                    title: 'Meus veículos',
                    subtitle: 'Cadastre e escolha o veículo padrão',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const VehiclesScreen())),
                  ),
                  const _HudDivider(),
                  _SettingRow(
                    icon: Icons.place_outlined,
                    title: 'Endereços salvos',
                    subtitle: 'Casa, trabalho e locais recentes',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const AddressesScreen())),
                  ),
                  const _HudDivider(),
                  _SettingRow(
                    icon: Icons.block_rounded,
                    title: 'Bloqueados',
                    subtitle: 'Gerencie pessoas bloqueadas',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const BlockedUsersScreen())),
                  ),
                  const _HudDivider(),
                  const _SettingRow(
                    icon: Icons.notifications_outlined,
                    title: 'Notificações',
                    subtitle: 'Viagens, pedidos e mensagens',
                  ),
                  const _HudDivider(),
                  const _SettingRow(
                    icon: Icons.shield_outlined,
                    title: 'Privacidade',
                    subtitle: 'Conta e dados pessoais',
                  ),
                  const _HudDivider(),
                  const _SettingRow(
                    icon: Icons.contrast_rounded,
                    title: 'Aparência',
                    subtitle: 'Tema do dispositivo',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            NeoOutlineButton(
              height: 48,
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => ref.read(authStateProvider.notifier).logout(),
              child: const Text('SAIR DA CONTA'),
            ),
            const SizedBox(height: 16),
            const Center(child: AppVersionLabel()),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow(
      {required this.icon,
      required this.title,
      required this.subtitle,
      this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                color: scheme.primary,
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title.toUpperCase(),
                        style: theme.textTheme.labelMedium),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              NeoBadge(color: scheme.secondary, child: const Text('EM BREVE')),
            ],
          ),
        ));
  }
}

class _HudDivider extends StatelessWidget {
  const _HudDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 2, color: Theme.of(context).colorScheme.ink);
  }
}

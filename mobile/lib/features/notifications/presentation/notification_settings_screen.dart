import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/neo_brutal_theme.dart';
import '../../../core/ui/neo_card.dart';
import '../data/repositories/notification_repository.dart';
import '../data/services/notification_service.dart';

final notificationPreferencesProvider = FutureProvider(
    (ref) => ref.watch(notificationRepositoryProvider).preferences());

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(notificationPreferencesProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
        appBar: AppBar(title: const Text('NOTIFICAÇÕES')),
        body: preferences.when(
            data: (value) =>
                ListView(padding: const EdgeInsets.all(16), children: [
                  NeoCard(
                      color: scheme.primaryContainer,
                      child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading:
                              const Icon(Icons.notifications_active_outlined),
                          title: const Text('ATIVAR NOTIFICAÇÕES'),
                          subtitle: const Text(
                              'Receba avisos mesmo com o VaiJunto fechado.'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _enablePush(context, ref))),
                  const SizedBox(height: 16),
                  Text('PREFERÊNCIAS',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  NeoCard(
                      color: scheme.surface,
                      offset: NeoBrutal.shadowOffsetSmall,
                      padding: EdgeInsets.zero,
                      child: Column(children: [
                        SwitchListTile(
                            value: value.hideContent,
                            title: const Text('OCULTAR CONTEÚDO NA PRÉVIA'),
                            subtitle: const Text(
                                'Mostra apenas que há uma notificação na tela bloqueada.'),
                            onChanged: (enabled) => _update(ref,
                                hideContent: enabled,
                                muteChat: value.muteChat)),
                        const Divider(height: 1),
                        SwitchListTile(
                            value: value.muteChat,
                            title: const Text('SILENCIAR CHAT COMUM'),
                            subtitle: const Text(
                                'Eventos críticos continuam aparecendo.'),
                            onChanged: (enabled) => _update(ref,
                                hideContent: value.hideContent,
                                muteChat: enabled))
                      ])),
                  const SizedBox(height: 16),
                  Text('Estas preferências são salvas na sua conta.',
                      style: TextStyle(color: scheme.onSurfaceVariant))
                ]),
            loading: () =>
                const Center(child: Text('CARREGANDO PREFERÊNCIAS...')),
            error: (_, __) => Center(
                child: TextButton(
                    onPressed: () =>
                        ref.invalidate(notificationPreferencesProvider),
                    child: const Text('TENTAR NOVAMENTE')))));
  }

  Future<void> _update(WidgetRef ref,
      {required bool hideContent, required bool muteChat}) async {
    await ref
        .read(notificationRepositoryProvider)
        .updatePreferences(hideContent: hideContent, muteChat: muteChat);
    ref.invalidate(notificationPreferencesProvider);
  }

  Future<void> _enablePush(BuildContext context, WidgetRef ref) async {
    final enabled =
        await ref.read(notificationServiceProvider).enablePushNotifications();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(enabled
            ? 'Notificações ativadas.'
            : 'Permissão de notificações não concedida.')));
  }
}

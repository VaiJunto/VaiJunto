import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/neo_brutal_theme.dart';
import '../../../core/ui/neo_card.dart';
import '../data/repositories/notification_repository.dart';

final notificationsProvider =
    FutureProvider((ref) => ref.watch(notificationRepositoryProvider).list());
final notificationPreferencesProvider = FutureProvider(
    (ref) => ref.watch(notificationRepositoryProvider).preferences());

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final notifications = ref.watch(notificationsProvider);
    final preferences = ref.watch(notificationPreferencesProvider).valueOrNull;
    return Scaffold(
        appBar: AppBar(title: const Text('NOTIFICAÇÕES')),
        body: Column(children: [
          if (preferences != null)
            Padding(
                padding: const EdgeInsets.all(16),
                child: NeoCard(
                    color: scheme.surface,
                    child: Column(children: [
                      SwitchListTile(
                          value: preferences.hideContent,
                          title: const Text('OCULTAR CONTEÚDO NA PRÉVIA'),
                          onChanged: (value) async {
                            await ref
                                .read(notificationRepositoryProvider)
                                .updatePreferences(
                                    hideContent: value,
                                    muteChat: preferences.muteChat);
                            ref.invalidate(notificationPreferencesProvider);
                          }),
                      SwitchListTile(
                          value: preferences.muteChat,
                          title: const Text('SILENCIAR CHAT COMUM'),
                          subtitle: const Text(
                              'Eventos críticos continuam aparecendo.'),
                          onChanged: (value) async {
                            await ref
                                .read(notificationRepositoryProvider)
                                .updatePreferences(
                                    hideContent: preferences.hideContent,
                                    muteChat: value);
                            ref.invalidate(notificationPreferencesProvider);
                          })
                    ]))),
          Expanded(
              child: notifications.when(
                  data: (items) => items.isEmpty
                      ? const Center(child: Text('NENHUMA NOTIFICAÇÃO AGORA'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, index) {
                            final item = items[index];
                            return InkWell(
                                onTap: () async {
                                  await ref
                                      .read(notificationRepositoryProvider)
                                      .markRead(item.id);
                                  ref.invalidate(notificationsProvider);
                                },
                                child: NeoCard(
                                    color: item.isRead
                                        ? scheme.surface
                                        : scheme.secondary,
                                    offset: NeoBrutal.shadowOffsetSmall,
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(item.type,
                                              style: TextStyle(
                                                  fontFamily: 'IBMPlexMono',
                                                  color: item.isRead
                                                      ? scheme.tertiary
                                                      : Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800)),
                                          const SizedBox(height: 6),
                                          Text(item.title ?? 'VAIJUNTO',
                                              style: TextStyle(
                                                  color: item.isRead
                                                      ? scheme.ink
                                                      : Colors.white,
                                                  fontWeight: FontWeight.w900)),
                                          if (item.body != null)
                                            Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 4),
                                                child: Text(item.body!,
                                                    style: TextStyle(
                                                        color: item.isRead
                                                            ? scheme
                                                                .onSurfaceVariant
                                                            : Colors.white)))
                                        ])));
                          }),
                  loading: () =>
                      const Center(child: Text('CARREGANDO NOTIFICAÇÕES...')),
                  error: (_, __) => Center(
                      child: TextButton(
                          onPressed: () =>
                              ref.invalidate(notificationsProvider),
                          child: const Text('TENTAR NOVAMENTE')))))
        ]));
  }
}

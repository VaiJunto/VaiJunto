import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/neo_brutal_theme.dart';
import '../../../core/ui/neo_card.dart';
import '../data/repositories/notification_repository.dart';

final notificationsProvider =
    FutureProvider((ref) => ref.watch(notificationRepositoryProvider).list());

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final notifications = ref.watch(notificationsProvider);
    return Scaffold(
        appBar: AppBar(title: const Text('NOTIFICAÇÕES')),
        body: notifications.when(
            data: (items) => items.isEmpty
                ? const _EmptyNotifications()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                    itemCount: items.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      if (index == 0) {
                        final unread =
                            items.where((item) => !item.isRead).length;
                        return _NotificationSummary(unread: unread);
                      }
                      final item = items[index - 1];
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Expanded(
                                          child: Text(item.type,
                                              style: TextStyle(
                                                  fontFamily: 'IBMPlexMono',
                                                  color: item.isRead
                                                      ? scheme.tertiary
                                                      : Colors.white,
                                                  fontSize: 10,
                                                  fontWeight:
                                                      FontWeight.w800))),
                                      Text(_relativeTime(item.createdAt),
                                          style: TextStyle(
                                              color: item.isRead
                                                  ? scheme.onSurfaceVariant
                                                  : Colors.white70,
                                              fontSize: 11)),
                                    ]),
                                    const SizedBox(height: 7),
                                    Row(children: [
                                      if (!item.isRead) ...[
                                        const Icon(Icons.circle,
                                            color: Colors.white, size: 9),
                                        const SizedBox(width: 8),
                                      ],
                                      Expanded(
                                          child: Text(item.title ?? 'VAIJUNTO',
                                              style: TextStyle(
                                                  color: item.isRead
                                                      ? scheme.ink
                                                      : Colors.white,
                                                  fontWeight:
                                                      FontWeight.w900))),
                                    ]),
                                    if (item.body != null)
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(item.body!,
                                              style: TextStyle(
                                                  color: item.isRead
                                                      ? scheme.onSurfaceVariant
                                                      : Colors.white)))
                                  ])));
                    }),
            loading: () =>
                const Center(child: Text('CARREGANDO NOTIFICAÇÕES...')),
            error: (_, __) => Center(
                child: TextButton(
                    onPressed: () => ref.invalidate(notificationsProvider),
                    child: const Text('TENTAR NOVAMENTE')))));
  }
}

class _NotificationSummary extends StatelessWidget {
  const _NotificationSummary({required this.unread});
  final int unread;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return NeoCard(
        color: scheme.surface,
        offset: NeoBrutal.shadowOffsetSmall,
        child: Row(children: [
          Icon(Icons.notifications_active_outlined, color: scheme.secondary),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('CENTRAL DE NOTIFICAÇÕES',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                Text(
                    unread == 0
                        ? 'Você está em dia.'
                        : '$unread ${unread == 1 ? 'nova notificação' : 'novas notificações'}',
                    style: TextStyle(color: scheme.onSurfaceVariant))
              ]))
        ]));
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.notifications_none_rounded, size: 48),
            const SizedBox(height: 14),
            Text('NENHUMA NOTIFICAÇÃO AGORA',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            const Text(
                'Quando houver novidades sobre suas caronas e mensagens, elas aparecerão aqui.',
                textAlign: TextAlign.center)
          ])));
}

String _relativeTime(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);
  if (difference.inMinutes < 1) return 'agora';
  if (difference.inHours < 1) return '${difference.inMinutes} min';
  if (difference.inDays < 1) return '${difference.inHours} h';
  if (difference.inDays == 1) return 'ontem';
  return '${difference.inDays} dias';
}

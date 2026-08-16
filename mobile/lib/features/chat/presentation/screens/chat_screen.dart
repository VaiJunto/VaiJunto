import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/neo_brutal_theme.dart';
import '../../../../core/ui/neo_card.dart';

import '../providers/conversation_provider.dart';
import 'conversation_screen.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final conversations = ref.watch(conversationsProvider);
    return SafeArea(
      top: false,
      child: conversations.when(
          data: (items) => items.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: NeoCard(
                      color: scheme.surface,
                      rotation: -0.012,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('VJ//COMMS_CHANNEL',
                                  style: _hudStyle(scheme)),
                              const SizedBox(width: 10),
                              Expanded(
                                  child:
                                      Divider(color: scheme.ink, thickness: 2)),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                decoration: NeoBrutal.decoration(
                                  color: scheme.primary,
                                  borderColor: scheme.ink,
                                  radius: 3,
                                  offset: NeoBrutal.shadowOffsetSmall,
                                ),
                                child: const Icon(Icons.forum_rounded,
                                    size: 28, color: Colors.white),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AINDA NÃO HÁ\nCONVERSAS',
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        height: 0.95,
                                        letterSpacing: -0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    NeoBadge(
                                      color: scheme.secondary,
                                      child: const Text('CANAL OFFLINE'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'Um chat aparece quando uma carona é aceita ou uma proposta precisa ser combinada.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            color: scheme.ink,
                            child: Text(
                              'STATUS: AGUARDANDO UMA CARONA',
                              style: TextStyle(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                fontFamily: 'IBMPlexMono',
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return InkWell(
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    ConversationScreen(conversation: item))),
                        child: NeoCard(
                            color: scheme.surface,
                            padding: const EdgeInsets.all(14),
                            offset: NeoBrutal.shadowOffsetSmall,
                            child: Row(children: [
                              Container(
                                  width: 42,
                                  height: 42,
                                  color: scheme.secondary,
                                  alignment: Alignment.center,
                                  child: Icon(
                                      item.type == 'ADMINISTRATIVE'
                                          ? Icons.support_agent_rounded
                                          : Icons.forum_rounded,
                                      color: Colors.white)),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(item.title.toUpperCase(),
                                        style: theme.textTheme.titleSmall),
                                    const SizedBox(height: 3),
                                    Text(
                                        item.readOnly
                                            ? 'ARQUIVADA • SOMENTE LEITURA'
                                            : item.type,
                                        style: _hudStyle(scheme))
                                  ])),
                              if (item.archived)
                                const Icon(Icons.archive_outlined)
                            ])));
                  }),
          loading: () => const Center(child: Text('CARREGANDO CONVERSAS...')),
          error: (_, __) => const Center(
              child: Text('Não foi possível carregar as conversas.'))),
    );
  }
}

TextStyle _hudStyle(ColorScheme scheme) => TextStyle(
      color: scheme.secondary,
      fontFamily: 'IBMPlexMono',
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.8,
    );

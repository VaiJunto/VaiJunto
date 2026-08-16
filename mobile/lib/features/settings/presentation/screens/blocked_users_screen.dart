import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/ui/neo_button.dart';
import '../../../../core/ui/neo_card.dart';

final blockedUsersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await ref.watch(dioProvider).get('/blocks');
  return (response.data as List)
      .cast<Map>()
      .map((e) => e.cast<String, dynamic>())
      .toList();
});

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(blockedUsersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('BLOQUEADOS')),
      body: users.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('NÃO FOI POSSÍVEL CARREGAR')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('NENHUM USUÁRIO BLOQUEADO'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) {
                  final item = items[index];
                  return NeoCard(
                      child: Row(children: [
                    Expanded(
                        child: Text((item['name'] as String).toUpperCase())),
                    NeoOutlineButton(
                        onPressed: () async {
                          await ref
                              .read(dioProvider)
                              .delete('/blocks/${item['userId']}');
                          ref.invalidate(blockedUsersProvider);
                        },
                        child: const Text('DESBLOQUEAR'))
                  ]));
                }),
      ),
    );
  }
}

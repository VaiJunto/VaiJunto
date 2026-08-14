import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_brutal_theme.dart';
import '../../../../core/ui/neo_card.dart';
import '../../data/repositories/address_repository.dart';
import '../providers/address_provider.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final addresses = ref.watch(savedAddressesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('ENDEREÇOS SALVOS')),
      body: addresses.when(
        data: (items) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (items.isEmpty)
              NeoCard(
                  color: scheme.surface,
                  child: const Text(
                      'NENHUM ENDEREÇO SALVO\nSalve um endereço ao escolher origem ou destino.')),
            ...items.map((address) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: NeoCard(
                    color: scheme.surface,
                    padding: const EdgeInsets.all(12),
                    offset: NeoBrutal.shadowOffsetSmall,
                    child: Row(children: [
                      Icon(
                          address.recent
                              ? Icons.history_rounded
                              : Icons.star_rounded,
                          color: address.recent
                              ? scheme.secondary
                              : scheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                          child:
                              Text('${address.label}\n${address.addressName}')),
                      IconButton(
                          onPressed: () async {
                            await ref
                                .read(addressRepositoryProvider)
                                .delete(address.id);
                            ref.invalidate(savedAddressesProvider);
                          },
                          icon: const Icon(Icons.delete_outline_rounded)),
                    ]),
                  ),
                )),
            if (items.any((item) => item.recent))
              TextButton(
                  onPressed: () async {
                    await ref.read(addressRepositoryProvider).clearRecents();
                    ref.invalidate(savedAddressesProvider);
                  },
                  child: const Text('LIMPAR LOCAIS RECENTES')),
          ],
        ),
        loading: () => const Center(child: Text('CARREGANDO ENDEREÇOS...')),
        error: (_, __) => const Center(
            child: Text('Não foi possível carregar os endereços.')),
      ),
    );
  }
}

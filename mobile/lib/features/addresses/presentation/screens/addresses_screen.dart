import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/geocoding/geocoding_result_model.dart';
import '../../../../core/theme/neo_brutal_theme.dart';
import '../../../../core/ui/address_autocomplete_field.dart';
import '../../../../core/ui/app_snackbar.dart';
import '../../../../core/ui/neo_button.dart';
import '../../../../core/ui/neo_card.dart';
import '../../data/models/saved_address_model.dart';
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
        data: (items) {
          final saved = items.where((item) => !item.recent).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              NeoCard(
                color: scheme.secondaryContainer,
                child: Row(
                  children: [
                    const Icon(Icons.bookmark_added_rounded,
                        color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${saved.length}/10 SALVOS\nUse-os como atalho ao criar uma carona.',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (saved.isEmpty)
                NeoCard(
                  color: scheme.surface,
                  child: const Text(
                    'NENHUM ENDEREÇO SALVO\nCadastre casa, trabalho ou qualquer ponto que você usa sempre.',
                  ),
                ),
              ...saved.map((address) => _AddressCard(
                    address: address,
                    onEdit: () => _openForm(context, ref, address),
                    onDelete: () => _deleteAddress(context, ref, address),
                  )),
              if (items.any((item) => item.recent)) ...[
                const SizedBox(height: 10),
                Text('LOCAIS RECENTES',
                    style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 8),
                ...items.where((item) => item.recent).map(
                      (address) => _RecentAddressCard(address: address),
                    ),
                TextButton.icon(
                  onPressed: () => _clearRecents(context, ref),
                  icon: const Icon(Icons.delete_sweep_rounded),
                  label: const Text('LIMPAR LOCAIS RECENTES'),
                ),
              ],
              const SizedBox(height: 12),
              NeoButton(
                onPressed:
                    saved.length >= 10 ? null : () => _openForm(context, ref),
                icon: const Icon(Icons.add_location_alt_rounded),
                child: Text(saved.length >= 10
                    ? 'LIMITE DE 10 ENDEREÇOS'
                    : 'CADASTRAR NOVO ENDEREÇO'),
              ),
            ],
          );
        },
        loading: () => const Center(child: Text('CARREGANDO ENDEREÇOS...')),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref,
      [SavedAddressModel? existing]) async {
    final label = TextEditingController(text: existing?.label ?? '');
    GeocodingResult? selected = existing == null
        ? null
        : GeocodingResult(
            displayName: existing.addressName,
            primaryText: existing.addressName,
            secondaryText: '',
            latitude: existing.latitude,
            longitude: existing.longitude,
            distanceKm: null,
          );
    final formKey = GlobalKey<FormState>();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
        child: _AddressFormSheet(
          formKey: formKey,
          label: label,
          initialAddress: selected,
          isEditing: existing != null,
          onAddressSelected: (value) => selected = value,
          onSave: () async {
            if (!(formKey.currentState?.validate() ?? false) ||
                selected == null) {
              return;
            }
            try {
              final repository = ref.read(addressRepositoryProvider);
              if (existing == null) {
                await repository.create(
                  label: label.text,
                  addressName: selected!.displayName,
                  latitude: selected!.latitude,
                  longitude: selected!.longitude,
                );
              } else {
                await repository.update(
                  id: existing.id,
                  label: label.text,
                  addressName: selected!.displayName,
                  latitude: selected!.latitude,
                  longitude: selected!.longitude,
                );
              }
              if (sheetContext.mounted) {
                Navigator.pop(sheetContext, true);
              }
            } catch (error) {
              if (sheetContext.mounted) {
                AppSnackbar.error(sheetContext, error.toString());
              }
            }
          },
        ),
      ),
    );
    label.dispose();
    if (saved == true) {
      ref.invalidate(savedAddressesProvider);
      if (context.mounted) {
        AppSnackbar.success(context,
            existing == null ? 'ENDEREÇO CADASTRADO' : 'ENDEREÇO ATUALIZADO');
      }
    }
  }

  Future<void> _deleteAddress(
      BuildContext context, WidgetRef ref, SavedAddressModel address) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('EXCLUIR ENDEREÇO?'),
        content:
            Text('“${address.label}” deixará de aparecer nos seus atalhos.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCELAR')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('EXCLUIR')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(addressRepositoryProvider).delete(address.id);
      ref.invalidate(savedAddressesProvider);
      if (context.mounted) AppSnackbar.success(context, 'ENDEREÇO EXCLUÍDO');
    } catch (error) {
      if (context.mounted) AppSnackbar.error(context, error.toString());
    }
  }

  Future<void> _clearRecents(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(addressRepositoryProvider).clearRecents();
      ref.invalidate(savedAddressesProvider);
      if (context.mounted) {
        AppSnackbar.success(context, 'LOCAIS RECENTES LIMPOS');
      }
    } catch (error) {
      if (context.mounted) AppSnackbar.error(context, error.toString());
    }
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard(
      {required this.address, required this.onEdit, required this.onDelete});
  final SavedAddressModel address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NeoCard(
        color: scheme.surface,
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: NeoBrutal.decoration(
                color: scheme.primary,
                borderColor: scheme.ink,
                offset: Offset.zero),
            child: const Icon(Icons.place_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(address.label,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(address.addressName,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ])),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (action) => action == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('EDITAR')),
              PopupMenuItem(value: 'delete', child: Text('EXCLUIR')),
            ],
          ),
        ]),
      ),
    );
  }
}

class _RecentAddressCard extends StatelessWidget {
  const _RecentAddressCard({required this.address});
  final SavedAddressModel address;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          const Icon(Icons.history_rounded, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(address.addressName,
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      );
}

class _AddressFormSheet extends StatelessWidget {
  const _AddressFormSheet({
    required this.formKey,
    required this.label,
    required this.initialAddress,
    required this.isEditing,
    required this.onAddressSelected,
    required this.onSave,
  });
  final GlobalKey<FormState> formKey;
  final TextEditingController label;
  final GeocodingResult? initialAddress;
  final bool isEditing;
  final ValueChanged<GeocodingResult?> onAddressSelected;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .9),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border.all(color: scheme.ink, width: NeoBrutal.borderWidth),
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(NeoBrutal.borderRadius)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Form(
            key: formKey,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                      child:
                          Container(width: 42, height: 4, color: scheme.ink)),
                  const SizedBox(height: 20),
                  Text(isEditing ? 'EDITAR ENDEREÇO' : 'NOVO ENDEREÇO',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  const Text(
                      'Escolha um nome fácil de reconhecer e confirme o local no mapa.'),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: label,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 80,
                    decoration: const InputDecoration(
                        labelText: 'Nome do atalho',
                        hintText: 'Ex.: CASA, TRABALHO'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Informe um nome para o endereço'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  AddressAutocompleteField(
                    label: 'Endereço',
                    hint: 'Busque rua, bairro ou ponto de referência',
                    initialValue: initialAddress,
                    onSelected: onAddressSelected,
                  ),
                  const SizedBox(height: 22),
                  NeoButton(
                    onPressed: () => onSave(),
                    icon: const Icon(Icons.save_rounded),
                    child: Text(
                        isEditing ? 'SALVAR ALTERAÇÕES' : 'SALVAR ENDEREÇO'),
                  ),
                ]),
          ),
        ),
      ),
    );
  }
}

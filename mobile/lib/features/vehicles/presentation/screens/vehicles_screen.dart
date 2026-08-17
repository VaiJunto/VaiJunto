import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/neo_brutal_theme.dart';
import '../../../../core/ui/app_snackbar.dart';
import '../../../../core/ui/neo_button.dart';
import '../../../../core/ui/neo_card.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../providers/vehicle_provider.dart';

class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final vehicles = ref.watch(vehiclesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('MEUS VEÍCULOS')),
      body: vehicles.when(
        data: (items) => SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: items.isEmpty
                    ? _EmptyVehicleState(onAdd: () => _openForm(context, ref))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 112),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (_, index) {
                          final vehicle = items[index];
                          return NeoCard(
                            color: scheme.surface,
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  alignment: Alignment.center,
                                  color: scheme.secondary,
                                  child: const Icon(
                                    Icons.directions_car_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        vehicle.model.isEmpty
                                            ? 'VEÍCULO SEM MODELO'
                                            : vehicle.model.toUpperCase(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${vehicle.licensePlate}  •  ${vehicle.capacity} vagas',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                if (vehicle.isDefault)
                                  const NeoBadge(
                                    color: NeoBrutal.lime,
                                    foregroundColor: NeoBrutal.inkLight,
                                    child: Text('PADRÃO'),
                                  )
                                else
                                  IconButton(
                                    tooltip: 'Tornar veículo padrão',
                                    onPressed: () async {
                                      await ref
                                          .read(vehicleRepositoryProvider)
                                          .makeDefault(vehicle.id);
                                      ref.invalidate(vehiclesProvider);
                                    },
                                    icon:
                                        const Icon(Icons.star_outline_rounded),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              if (items.isNotEmpty)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border:
                        Border(top: BorderSide(color: scheme.ink, width: 2)),
                  ),
                  child: NeoButton(
                    onPressed: () => _openForm(context, ref),
                    icon: const Icon(Icons.add_rounded),
                    child: const Text('ADICIONAR VEÍCULO'),
                  ),
                ),
            ],
          ),
        ),
        loading: () => const Center(child: Text('CARREGANDO VEÍCULOS...')),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    final draft = await showModalBottomSheet<_VehicleDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _VehicleFormSheet(),
    );
    if (draft == null) return;

    try {
      await ref.read(vehicleRepositoryProvider).create(
            plate: draft.plate,
            model: draft.model,
            capacity: draft.capacity,
          );
      ref.invalidate(vehiclesProvider);
    } catch (error) {
      if (context.mounted) AppSnackbar.error(context, error.toString());
    }
  }
}

class _EmptyVehicleState extends StatelessWidget {
  const _EmptyVehicleState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              alignment: Alignment.center,
              decoration: NeoBrutal.decoration(
                color: scheme.secondary,
                borderColor: scheme.ink,
              ),
              child: const Icon(Icons.directions_car_outlined,
                  color: Colors.white, size: 38),
            ),
            const SizedBox(height: 24),
            Text('SEU PRIMEIRO VEÍCULO',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Cadastre o veículo que você usa para oferecer caronas.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            NeoButton(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              child: const Text('CADASTRAR VEÍCULO'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleFormSheet extends StatefulWidget {
  const _VehicleFormSheet();

  @override
  State<_VehicleFormSheet> createState() => _VehicleFormSheetState();
}

class _VehicleFormSheetState extends State<_VehicleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _plate = TextEditingController();
  final _model = TextEditingController();
  int _capacity = 4;

  @override
  void dispose() {
    _plate.dispose();
    _model.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      _VehicleDraft(
        plate: _plate.text.trim().toUpperCase(),
        model: _model.text.trim(),
        capacity: _capacity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset + 12),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: scheme.ink, width: NeoBrutal.borderWidth),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        color: scheme.primary,
                        child: const Icon(Icons.directions_car_rounded,
                            color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('CADASTRAR VEÍCULO',
                            style: Theme.of(context).textTheme.titleLarge),
                      ),
                      IconButton(
                        tooltip: 'Fechar',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Essas informações aparecem quando você oferecer uma carona.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _plate,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    maxLength: 8,
                    decoration: const InputDecoration(
                      labelText: 'Placa',
                      hintText: 'ABC1D23',
                      prefixIcon: Icon(Icons.pin_outlined),
                      counterText: '',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Informe a placa do veículo.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _model,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Marca e modelo',
                      hintText: 'Ex.: Fiat Argo',
                      prefixIcon: Icon(Icons.sell_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Informe a marca e o modelo.'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  Text('VAGAS PARA PASSAGEIROS',
                      style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 6),
                  Text('Não inclui o assento do motorista.',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(7, (index) {
                      final value = index + 1;
                      final selected = value == _capacity;
                      return ChoiceChip(
                        label: Text('$value'),
                        selected: selected,
                        onSelected: (_) => setState(() => _capacity = value),
                        selectedColor: scheme.secondary,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : scheme.ink,
                          fontWeight: FontWeight.w800,
                        ),
                        side: BorderSide(color: scheme.ink, width: 2),
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),
                  NeoButton(
                    onPressed: _submit,
                    icon: const Icon(Icons.check_rounded),
                    child: const Text('SALVAR VEÍCULO'),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCELAR'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleDraft {
  const _VehicleDraft({
    required this.plate,
    required this.model,
    required this.capacity,
  });

  final String plate;
  final String model;
  final int capacity;
}

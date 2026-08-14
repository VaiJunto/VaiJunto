import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        data: (items) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (items.isEmpty)
              NeoCard(
                color: scheme.surface,
                child: const Text(
                    'NENHUM VEÍCULO\nCadastre seu veículo para oferecer uma carona.'),
              ),
            ...items.map((vehicle) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: NeoCard(
                    color: scheme.surface,
                    child: Row(children: [
                      const Icon(Icons.directions_car_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(
                              '${vehicle.model.isEmpty ? 'VEÍCULO' : vehicle.model.toUpperCase()}\n${vehicle.licensePlate} • ${vehicle.capacity} vagas')),
                      if (vehicle.isDefault)
                        const Text('PADRÃO')
                      else
                        TextButton(
                          onPressed: () async {
                            await ref
                                .read(vehicleRepositoryProvider)
                                .makeDefault(vehicle.id);
                            ref.invalidate(vehiclesProvider);
                          },
                          child: const Text('TORNAR PADRÃO'),
                        ),
                    ]),
                  ),
                )),
            const SizedBox(height: 8),
            NeoButton(
                onPressed: () => _openForm(context, ref),
                child: const Text('ADICIONAR VEÍCULO')),
          ],
        ),
        loading: () => const Center(child: Text('CARREGANDO VEÍCULOS...')),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    final plate = TextEditingController();
    final model = TextEditingController();
    final capacity = TextEditingController(text: '4');
    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('CADASTRAR VEÍCULO'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: plate,
              decoration: const InputDecoration(labelText: 'Placa')),
          TextField(
              controller: model,
              decoration: const InputDecoration(labelText: 'Marca e modelo')),
          TextField(
              controller: capacity,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Vagas sem motorista')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCELAR')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('SALVAR')),
        ],
      ),
    );
    if (submit == true) {
      try {
        await ref.read(vehicleRepositoryProvider).create(
            plate: plate.text,
            model: model.text,
            capacity: int.tryParse(capacity.text) ?? 0);
        ref.invalidate(vehiclesProvider);
      } catch (error) {
        if (context.mounted) AppSnackbar.error(context, error.toString());
      }
    }
    plate.dispose();
    model.dispose();
    capacity.dispose();
  }
}

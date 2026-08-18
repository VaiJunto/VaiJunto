import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/neo_brutal_theme.dart';
import '../../../../core/ui/app_snackbar.dart';
import '../../../../core/ui/neo_button.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../providers/vehicle_provider.dart';

Future<VehicleModel?> showCreateVehicleSheet(
    BuildContext context, WidgetRef ref) async {
  final draft = await showModalBottomSheet<VehicleDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const VehicleFormSheet(),
  );
  if (draft == null) return null;
  try {
    final vehicle = await ref.read(vehicleRepositoryProvider).create(
          plate: draft.plate,
          model: draft.model,
          capacity: draft.capacity,
        );
    ref.invalidate(vehiclesProvider);
    return vehicle;
  } catch (error) {
    if (context.mounted) AppSnackbar.error(context, error.toString());
    return null;
  }
}

class VehicleFormSheet extends StatefulWidget {
  const VehicleFormSheet({super.key});
  @override
  State<VehicleFormSheet> createState() => _VehicleFormSheetState();
}

class _VehicleFormSheetState extends State<VehicleFormSheet> {
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
        VehicleDraft(
          plate: _plate.text.trim().toUpperCase(),
          model: _model.text.trim(),
          capacity: _capacity,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            12, 0, 12, MediaQuery.viewInsetsOf(context).bottom + 12),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: scheme.ink, width: NeoBrutal.borderWidth),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.directions_car_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text('CADASTRAR VEÍCULO',
                              style: Theme.of(context).textTheme.titleLarge)),
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded)),
                    ]),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _plate,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 8,
                      decoration: const InputDecoration(
                          labelText: 'Placa',
                          hintText: 'ABC1D23',
                          counterText: ''),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Informe a placa do veículo.'
                              : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _model,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                          labelText: 'Marca e modelo',
                          hintText: 'Ex.: Fiat Argo'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Informe a marca e o modelo.'
                              : null,
                    ),
                    const SizedBox(height: 20),
                    Text('VAGAS PARA PASSAGEIROS',
                        style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 10),
                    Wrap(
                        spacing: 10,
                        children: List.generate(7, (index) {
                          final value = index + 1;
                          return ChoiceChip(
                            label: Text('$value'),
                            selected: value == _capacity,
                            onSelected: (_) =>
                                setState(() => _capacity = value),
                          );
                        })),
                    const SizedBox(height: 24),
                    NeoButton(
                        onPressed: _submit,
                        icon: const Icon(Icons.check_rounded),
                        child: const Text('SALVAR VEÍCULO')),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}

class VehicleDraft {
  const VehicleDraft(
      {required this.plate, required this.model, required this.capacity});
  final String plate;
  final String model;
  final int capacity;
}

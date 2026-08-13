import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/campus.dart';
import '../../../../core/geocoding/geocoding_result_model.dart';
import '../../../../core/models/location_model.dart';
import '../../../../core/ui/address_autocomplete_field.dart';
import '../../../../core/ui/app_snackbar.dart';
import '../../../../core/ui/fatec_direction_selector.dart';
import '../../../../core/ui/neo_button.dart';
import '../providers/demand_provider.dart';

/// Formulário de "pedir carona": o passageiro escolhe se está indo para a
/// Fatec ou saindo dela, busca o endereço do outro lado (autocomplete real,
/// não texto livre) e o horário desejado. Vira uma [Demand] no backend.
class CreateDemandScreen extends ConsumerStatefulWidget {
  const CreateDemandScreen({super.key});

  @override
  ConsumerState<CreateDemandScreen> createState() => _CreateDemandScreenState();
}

class _CreateDemandScreenState extends ConsumerState<CreateDemandScreen> {
  final _formKey = GlobalKey<FormState>();

  TripDirection _direction = TripDirection.toFatec;
  GeocodingResult? _otherAddress;
  DateTime _desiredTime = DateTime.now().add(const Duration(hours: 1));

  Future<void> _pickDesiredTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _desiredTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_desiredTime),
    );
    if (time == null) return;

    setState(() {
      _desiredTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final other = _otherAddress!;
    final otherLocation = LocationModel(latitude: other.latitude, longitude: other.longitude);
    final goingToFatec = _direction == TripDirection.toFatec;

    ref.read(createDemandProvider.notifier).create(
          originName: goingToFatec ? other.displayName : kFatecName,
          originLocation: goingToFatec ? otherLocation : kFatecLocation,
          destinationName: goingToFatec ? kFatecName : other.displayName,
          destinationLocation: goingToFatec ? kFatecLocation : otherLocation,
          desiredTime: _desiredTime,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createState = ref.watch(createDemandProvider);
    final dateLabel =
        '${_desiredTime.day.toString().padLeft(2, '0')}/${_desiredTime.month.toString().padLeft(2, '0')}/${_desiredTime.year} às '
        '${_desiredTime.hour.toString().padLeft(2, '0')}:${_desiredTime.minute.toString().padLeft(2, '0')}';

    ref.listen(createDemandProvider, (previous, next) {
      next.whenOrNull(
        data: (demand) {
          if (demand != null) {
            AppSnackbar.success(context, 'Pedido de carona publicado!');
            Navigator.of(context).pop();
          }
        },
        error: (error, _) => AppSnackbar.error(context, error.toString()),
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Pedir carona')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FatecDirectionSelector(
                  direction: _direction,
                  onChanged: (direction) => setState(() => _direction = direction),
                ),
                const SizedBox(height: 24),
                Text(
                  _direction == TripDirection.toFatec ? 'De onde você vai sair' : 'Para onde você vai',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                AddressAutocompleteField(
                  label: _direction == TripDirection.toFatec ? 'Endereço de origem' : 'Endereço de destino',
                  hint: 'Rua, bairro ou ponto de referência',
                  onSelected: (result) => setState(() => _otherAddress = result),
                ),
                const SizedBox(height: 28),
                Text('Horário desejado', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                NeoOutlineButton(
                  height: 48,
                  onPressed: _pickDesiredTime,
                  icon: const Icon(Icons.schedule_rounded, size: 18),
                  child: Text(dateLabel),
                ),
                const SizedBox(height: 32),
                NeoButton(
                  onPressed: createState.isLoading ? null : _submit,
                  child: createState.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('PUBLICAR PEDIDO'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

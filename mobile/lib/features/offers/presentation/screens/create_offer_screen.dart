import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/campus.dart';
import '../../../../core/geocoding/geocoding_result_model.dart';
import '../../../../core/models/location_model.dart';
import '../../../../core/ui/address_autocomplete_field.dart';
import '../../../../core/ui/app_snackbar.dart';
import '../../../../core/ui/fatec_direction_selector.dart';
import '../../../../core/ui/neo_button.dart';
import '../providers/offer_provider.dart';

/// Formulário de "publicar rota": o motorista escolhe se está indo para a
/// Fatec ou saindo dela, busca o endereço do outro lado (autocomplete real)
/// e define vagas, preço e horário. Vira uma [Route] + [Offer] no backend
/// (criadas juntas — não existe cadastro de rota separado ainda).
class CreateOfferScreen extends ConsumerStatefulWidget {
  const CreateOfferScreen({super.key});

  @override
  ConsumerState<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends ConsumerState<CreateOfferScreen> {
  final _formKey = GlobalKey<FormState>();

  final _seatsController = TextEditingController(text: '1');
  final _priceController = TextEditingController(text: '0');

  TripDirection _direction = TripDirection.toFatec;
  GeocodingResult? _otherAddress;
  DateTime _departureAt = DateTime.now().add(const Duration(hours: 1));

  @override
  void dispose() {
    _seatsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDepartureAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _departureAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_departureAt),
    );
    if (time == null) return;

    setState(() {
      _departureAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final other = _otherAddress!;
    final otherLocation = LocationModel(latitude: other.latitude, longitude: other.longitude);
    final goingToFatec = _direction == TripDirection.toFatec;
    final routeName = goingToFatec ? '${other.displayName} → $kFatecName' : '$kFatecName → ${other.displayName}';

    ref.read(createOfferProvider.notifier).create(
          routeName: routeName,
          originName: goingToFatec ? other.displayName : kFatecName,
          originLocation: goingToFatec ? otherLocation : kFatecLocation,
          destinationName: goingToFatec ? kFatecName : other.displayName,
          destinationLocation: goingToFatec ? kFatecLocation : otherLocation,
          availableSeats: int.parse(_seatsController.text.trim()),
          price: double.parse(_priceController.text.trim().replaceAll(',', '.')),
          departureAt: _departureAt,
        );
  }

  String? _seatsValidator(String? value) {
    final seats = int.tryParse(value?.trim() ?? '');
    if (seats == null || seats < 1) return 'Informe ao menos 1 vaga';
    return null;
  }

  String? _priceValidator(String? value) {
    final price = double.tryParse(value?.trim().replaceAll(',', '.') ?? '');
    if (price == null || price < 0) return 'Preço inválido';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createState = ref.watch(createOfferProvider);
    final dateLabel =
        '${_departureAt.day.toString().padLeft(2, '0')}/${_departureAt.month.toString().padLeft(2, '0')}/${_departureAt.year} às '
        '${_departureAt.hour.toString().padLeft(2, '0')}:${_departureAt.minute.toString().padLeft(2, '0')}';

    ref.listen(createOfferProvider, (previous, next) {
      next.whenOrNull(
        data: (offer) {
          if (offer != null) {
            AppSnackbar.success(context, 'Rota publicada!');
            Navigator.of(context).pop();
          }
        },
        error: (error, _) => AppSnackbar.error(context, error.toString()),
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Publicar rota')),
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
                  _direction == TripDirection.toFatec ? 'De onde a rota sai' : 'Para onde a rota vai',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                AddressAutocompleteField(
                  label: _direction == TripDirection.toFatec ? 'Endereço de origem' : 'Endereço de destino',
                  hint: 'Rua, bairro ou ponto de referência',
                  onSelected: (result) => setState(() => _otherAddress = result),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _seatsController,
                        decoration: const InputDecoration(labelText: 'Vagas'),
                        keyboardType: TextInputType.number,
                        validator: _seatsValidator,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(labelText: 'Preço (R\$)'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: _priceValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text('Saída', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                NeoOutlineButton(
                  height: 48,
                  onPressed: _pickDepartureAt,
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
                      : const Text('PUBLICAR ROTA'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

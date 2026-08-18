import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../../core/config/campus.dart';
import '../../../../core/geocoding/geocoding_result_model.dart';
import '../../../../core/models/location_model.dart';
import '../../../../core/theme/neo_brutal_theme.dart';
import '../../../../core/ui/address_autocomplete_field.dart';
import '../../../../core/ui/app_snackbar.dart';
import '../../../../core/ui/fatec_direction_selector.dart';
import '../../../../core/ui/neo_button.dart';
import '../../../../core/ui/neo_flow_header.dart';
import '../../../../core/ui/neo_loading_indicator.dart';
import '../../../../core/ui/neo_street_backdrop.dart';
import '../providers/offer_provider.dart';
import '../../data/models/offer_model.dart';
import '../../../vehicles/presentation/providers/vehicle_provider.dart';
import '../../../vehicles/data/models/vehicle_model.dart';
import '../../../vehicles/presentation/widgets/vehicle_form_sheet.dart';

class CreateOfferScreen extends ConsumerStatefulWidget {
  const CreateOfferScreen({
    super.key,
    this.embedded = false,
    this.onCreated,
    this.initialOffer,
  });

  final bool embedded;
  final VoidCallback? onCreated;
  final OfferModel? initialOffer;

  @override
  ConsumerState<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends ConsumerState<CreateOfferScreen> {
  final _routeFormKey = GlobalKey<FormState>();
  final _detailsFormKey = GlobalKey<FormState>();
  final _seatsController = TextEditingController(text: '1');
  final _priceController = TextEditingController(text: '0');
  final _priceFocus = FocusNode();

  int _step = 1;
  TripDirection _direction = TripDirection.toFatec;
  GeocodingResult? _otherAddress;
  DateTime _departureAt = DateTime.now().add(const Duration(hours: 1));
  bool _isFixed = false;
  final Set<int> _daysOfWeek = <int>{};
  VehicleModel? _vehicle;

  @override
  void initState() {
    super.initState();
    _priceFocus.addListener(() {
      if (!_priceFocus.hasFocus) {
        final value =
            double.tryParse(_priceController.text.replaceAll(',', '.'));
        if (value != null) {
          _priceController.text = value.toStringAsFixed(2).replaceAll('.', ',');
        }
      }
    });
    final offer = widget.initialOffer;
    if (offer == null ||
        offer.originLocation == null ||
        offer.destinationLocation == null) {
      return;
    }
    final toFatec = offer.destinationName.toUpperCase().contains('FATEC');
    _direction = toFatec ? TripDirection.toFatec : TripDirection.fromFatec;
    final point = toFatec ? offer.originLocation! : offer.destinationLocation!;
    final name = toFatec ? offer.originName : offer.destinationName;
    _otherAddress = GeocodingResult(
        displayName: name,
        primaryText: name,
        secondaryText: '',
        latitude: point.latitude,
        longitude: point.longitude,
        distanceKm: null);
    _departureAt = offer.departureAt.add(const Duration(days: 1));
    _seatsController.text = offer.availableSeats.toString();
    _priceController.text = offer.price.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _seatsController.dispose();
    _priceController.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  void _continueToDetails() {
    FocusScope.of(context).unfocus();
    if (!_routeFormKey.currentState!.validate()) return;
    setState(() => _step = 2);
  }

  Future<void> _pickDepartureAt() async {
    if (_isFixed) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_departureAt),
      );
      if (time == null) return;
      final today = DateTime.now();
      setState(() {
        _departureAt = DateTime(
            today.year, today.month, today.day, time.hour, time.minute);
        _departureAt = _nextRecurringOccurrence(_departureAt);
      });
      return;
    }

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
      _departureAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_detailsFormKey.currentState!.validate()) return;
    if (_vehicle == null) {
      AppSnackbar.error(context, 'Selecione um veículo para publicar.');
      return;
    }
    if (_isFixed && _daysOfWeek.isEmpty) {
      AppSnackbar.error(context, 'Escolha ao menos um dia da semana.');
      return;
    }

    final other = _otherAddress!;
    final otherLocation = LocationModel(
      latitude: other.latitude,
      longitude: other.longitude,
    );
    final goingToFatec = _direction == TripDirection.toFatec;
    final routeName = goingToFatec
        ? '${other.displayName} → $kFatecName'
        : '$kFatecName → ${other.displayName}';

    ref.read(createOfferProvider.notifier).create(
          routeName: routeName,
          originName: goingToFatec ? other.displayName : kFatecName,
          originLocation: goingToFatec ? otherLocation : kFatecLocation,
          destinationName: goingToFatec ? kFatecName : other.displayName,
          destinationLocation: goingToFatec ? kFatecLocation : otherLocation,
          availableSeats: int.parse(_seatsController.text.trim()),
          price:
              double.parse(_priceController.text.trim().replaceAll(',', '.')),
          departureAt: _departureAt,
          isFixed: _isFixed,
          daysOfWeek: _daysOfWeek.toList()..sort(),
          vehicleId: _vehicle!.id,
        );
  }

  DateTime _nextRecurringOccurrence(DateTime candidate) {
    var value = candidate;
    for (var i = 0; i < 8; i++) {
      if ((_daysOfWeek.isEmpty || _daysOfWeek.contains(value.weekday)) &&
          value.isAfter(DateTime.now())) {
        return value;
      }
      value = value.add(const Duration(days: 1));
    }
    return value;
  }

  Future<void> _registerVehicle() async {
    final created = await showCreateVehicleSheet(context, ref);
    if (created == null || !mounted) return;
    setState(() {
      _vehicle = created;
      if ((int.tryParse(_seatsController.text) ?? 1) > created.capacity) {
        _seatsController.text = created.capacity.toString();
      }
    });
  }

  String? _seatsValidator(String? value) {
    final seats = int.tryParse(value?.trim() ?? '');
    if (seats == null || seats < 1) return 'Mínimo: 1';
    if (_vehicle != null && seats > _vehicle!.capacity) {
      return 'Máximo: ${_vehicle!.capacity} vagas';
    }
    return null;
  }

  String? _priceValidator(String? value) {
    final price = double.tryParse(value?.trim().replaceAll(',', '.') ?? '');
    if (price == null || price < 0) return 'Valor inválido';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createOfferProvider);
    final vehicles = ref.watch(vehiclesProvider);
    vehicles.whenData((list) {
      if (_vehicle == null && list.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _vehicle = list.firstWhere(
                (v) => v.id == widget.initialOffer?.vehicleId,
                orElse: () => list.firstWhere((v) => v.isDefault,
                    orElse: () => list.first)));
          }
        });
      }
    });

    ref.listen(createOfferProvider, (previous, next) {
      next.whenOrNull(
        data: (offer) {
          if (offer == null) return;
          AppSnackbar.success(context, 'Carona publicada!');
          widget.onCreated?.call();
          if (!widget.embedded) Navigator.of(context).pop();
        },
        error: (error, _) => AppSnackbar.error(context, error.toString()),
      );
    });

    final body = AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      child: _step == 1
          ? _RouteStep(
              key: const ValueKey('offer-route'),
              formKey: _routeFormKey,
              direction: _direction,
              onDirectionChanged: (value) => setState(() => _direction = value),
              onAddressSelected: (value) =>
                  setState(() => _otherAddress = value),
              onContinue: _continueToDetails,
            )
          : _OfferDetailsStep(
              key: const ValueKey('offer-details'),
              formKey: _detailsFormKey,
              origin: _originName,
              destination: _destinationName,
              dateLabel: _dateLabel,
              seatsController: _seatsController,
              priceController: _priceController,
              priceFocus: _priceFocus,
              seatsValidator: _seatsValidator,
              priceValidator: _priceValidator,
              isFixed: _isFixed,
              onFixedChanged: (value) => setState(() {
                _isFixed = value;
                if (value && _daysOfWeek.isEmpty) {
                  _daysOfWeek.add(DateTime.now().weekday);
                }
                if (value) {
                  _departureAt = _nextRecurringOccurrence(_departureAt);
                }
              }),
              daysOfWeek: _daysOfWeek,
              onDayChanged: (day) => setState(() {
                _daysOfWeek.contains(day)
                    ? _daysOfWeek.remove(day)
                    : _daysOfWeek.add(day);
                if (_isFixed) {
                  _departureAt = _nextRecurringOccurrence(_departureAt);
                }
              }),
              onEditRoute: () => setState(() => _step = 1),
              onPickDate: _pickDepartureAt,
              onSubmit: createState.isLoading ? null : _submit,
              isLoading: createState.isLoading,
              vehicle: _vehicle,
              vehicles: vehicles.valueOrNull ?? const [],
              onVehicleChanged: (value) => setState(() {
                _vehicle = value;
                if (int.tryParse(_seatsController.text) != null &&
                    int.parse(_seatsController.text) > value.capacity) {
                  _seatsController.text = value.capacity.toString();
                }
              }),
              onRegisterVehicle: _registerVehicle,
            ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar:
          widget.embedded ? null : AppBar(title: const Text('OFERECER CARONA')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const NeoStreetBackdrop(),
          body,
        ],
      ),
    );
  }

  String get _originName => _direction == TripDirection.toFatec
      ? _otherAddress?.displayName ?? ''
      : kFatecName;

  String get _destinationName => _direction == TripDirection.toFatec
      ? kFatecName
      : _otherAddress?.displayName ?? '';

  String get _dateLabel {
    final day = _departureAt.day.toString().padLeft(2, '0');
    final month = _departureAt.month.toString().padLeft(2, '0');
    final hour = _departureAt.hour.toString().padLeft(2, '0');
    final minute = _departureAt.minute.toString().padLeft(2, '0');
    if (_isFixed) return 'PRÓXIMA OCORRÊNCIA • $day/$month • $hour:$minute';
    return '$day/$month/${_departureAt.year} • $hour:$minute';
  }
}

class _RouteStep extends StatelessWidget {
  const _RouteStep({
    super.key,
    required this.formKey,
    required this.direction,
    required this.onDirectionChanged,
    required this.onAddressSelected,
    required this.onContinue,
  });

  final GlobalKey<FormState> formKey;
  final TripDirection direction;
  final ValueChanged<TripDirection> onDirectionChanged;
  final ValueChanged<GeocodingResult?> onAddressSelected;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const NeoFlowHeader(
              currentStep: 1,
              totalSteps: 2,
              title: 'Monte a rota',
              description: 'Escolha o sentido e informe apenas o outro ponto.',
            ),
            const SizedBox(height: 16),
            FatecDirectionSelector(
                direction: direction, onChanged: onDirectionChanged),
            const SizedBox(height: 16),
            AddressAutocompleteField(
              label: direction == TripDirection.toFatec
                  ? 'De onde você sai?'
                  : 'Para onde você vai?',
              hint: 'Rua, bairro ou ponto de referência',
              onSelected: onAddressSelected,
            ),
            const SizedBox(height: 18),
            NeoButton(
              onPressed: onContinue,
              trailing: const Icon(Icons.arrow_forward_rounded),
              child: const Text('CONTINUAR'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferDetailsStep extends StatelessWidget {
  const _OfferDetailsStep({
    super.key,
    required this.formKey,
    required this.origin,
    required this.destination,
    required this.dateLabel,
    required this.seatsController,
    required this.priceController,
    required this.priceFocus,
    required this.seatsValidator,
    required this.priceValidator,
    required this.isFixed,
    required this.onFixedChanged,
    required this.daysOfWeek,
    required this.onDayChanged,
    required this.onEditRoute,
    required this.onPickDate,
    required this.onSubmit,
    required this.isLoading,
    required this.vehicle,
    required this.vehicles,
    required this.onVehicleChanged,
    required this.onRegisterVehicle,
  });

  final GlobalKey<FormState> formKey;
  final String origin;
  final String destination;
  final String dateLabel;
  final TextEditingController seatsController;
  final TextEditingController priceController;
  final FocusNode priceFocus;
  final FormFieldValidator<String> seatsValidator;
  final FormFieldValidator<String> priceValidator;
  final bool isFixed;
  final ValueChanged<bool> onFixedChanged;
  final Set<int> daysOfWeek;
  final ValueChanged<int> onDayChanged;
  final VoidCallback onEditRoute;
  final VoidCallback onPickDate;
  final VoidCallback? onSubmit;
  final bool isLoading;
  final VehicleModel? vehicle;
  final List<VehicleModel> vehicles;
  final ValueChanged<VehicleModel> onVehicleChanged;
  final VoidCallback onRegisterVehicle;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const NeoFlowHeader(
              currentStep: 2,
              totalSteps: 2,
              title: 'Detalhes da carona',
              description: 'Confirme horário, vagas e ajuda de custo.',
            ),
            const SizedBox(height: 16),
            NeoRouteReview(
                origin: origin, destination: destination, onEdit: onEditRoute),
            const SizedBox(height: 14),
            if (vehicles.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.ink,
                    width: NeoBrutal.borderWidth,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                        'Cadastre um veículo para concluir a publicação.'),
                    const SizedBox(height: 12),
                    NeoButton(
                      onPressed: onRegisterVehicle,
                      icon: const Icon(Icons.add_rounded),
                      child: const Text('CADASTRAR VEÍCULO'),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<VehicleModel>(
                initialValue: vehicle,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Veículo'),
                hint: const Text('Cadastre um veículo para continuar'),
                items: vehicles
                    .map((v) => DropdownMenuItem(
                        value: v,
                        child: Text(
                            '${v.model.isEmpty ? 'Veículo' : v.model} • ${v.capacity} vagas')))
                    .toList(),
                onChanged: (value) {
                  if (value != null) onVehicleChanged(value);
                },
                validator: (_) =>
                    vehicle == null ? 'Selecione um veículo' : null,
              ),
            const SizedBox(height: 14),
            _FixedOfferToggle(value: isFixed, onChanged: onFixedChanged),
            if (isFixed) ...[
              const SizedBox(height: 12),
              Text('DIAS DA SEMANA',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(7, (index) {
                  const labels = [
                    'SEG',
                    'TER',
                    'QUA',
                    'QUI',
                    'SEX',
                    'SÁB',
                    'DOM'
                  ];
                  final day = index + 1;
                  return FilterChip(
                    label: Text(labels[index]),
                    selected: daysOfWeek.contains(day),
                    onSelected: (_) => onDayChanged(day),
                  );
                }),
              ),
            ],
            const SizedBox(height: 12),
            NeoOutlineButton(
              onPressed: onPickDate,
              icon: const Icon(Icons.schedule_rounded),
              trailing: const Icon(Icons.edit_rounded),
              child: Text(dateLabel),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: seatsController,
                    decoration: const InputDecoration(labelText: 'Vagas'),
                    keyboardType: TextInputType.number,
                    validator: seatsValidator,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: priceController,
                    focusNode: priceFocus,
                    decoration: const InputDecoration(
                      labelText: 'Valor por pessoa',
                      prefixText: 'R\$ ',
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*[\.,]?\d{0,2}'),
                      ),
                    ],
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: priceValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            NeoButton(
              onPressed: onSubmit,
              icon: const Icon(Icons.bolt_rounded),
              trailing: const Icon(Icons.arrow_forward_rounded),
              child: isLoading
                  ? const NeoLoadingIndicator(compact: true)
                  : const Text('PUBLICAR CARONA'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FixedOfferToggle extends StatelessWidget {
  const _FixedOfferToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: value ? scheme.secondary : scheme.surface,
        border: Border.all(color: scheme.ink, width: NeoBrutal.borderWidth),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Icon(
          Icons.all_inclusive_rounded,
          color: value ? Colors.white : scheme.primary,
        ),
        title: Text(
          value ? 'CARONA RECORRENTE' : 'CARONA ÚNICA',
          style: theme.textTheme.labelMedium?.copyWith(
            color: value ? Colors.white : scheme.ink,
            fontSize: 10,
          ),
        ),
        subtitle: Text(
          value
              ? 'Repete semanalmente nos dias escolhidos.'
              : 'Acontece uma vez na data e horário escolhidos.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: value
                ? Colors.white.withValues(alpha: 0.82)
                : scheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

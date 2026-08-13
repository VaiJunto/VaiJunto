import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/campus.dart';
import '../../../../core/geocoding/geocoding_result_model.dart';
import '../../../../core/models/location_model.dart';
import '../../../../core/ui/address_autocomplete_field.dart';
import '../../../../core/ui/app_snackbar.dart';
import '../../../../core/ui/fatec_direction_selector.dart';
import '../../../../core/ui/neo_button.dart';
import '../../../../core/ui/neo_flow_header.dart';
import '../providers/demand_provider.dart';

class CreateDemandScreen extends ConsumerStatefulWidget {
  const CreateDemandScreen({
    super.key,
    this.embedded = false,
    this.onCreated,
  });

  final bool embedded;
  final VoidCallback? onCreated;

  @override
  ConsumerState<CreateDemandScreen> createState() => _CreateDemandScreenState();
}

class _CreateDemandScreenState extends ConsumerState<CreateDemandScreen> {
  final _routeFormKey = GlobalKey<FormState>();

  int _step = 1;
  TripDirection _direction = TripDirection.toFatec;
  GeocodingResult? _otherAddress;
  DateTime _desiredTime = DateTime.now().add(const Duration(hours: 1));

  void _continueToTime() {
    FocusScope.of(context).unfocus();
    if (!_routeFormKey.currentState!.validate()) return;
    setState(() => _step = 2);
  }

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
      _desiredTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _submit() {
    final other = _otherAddress!;
    final otherLocation = LocationModel(
      latitude: other.latitude,
      longitude: other.longitude,
    );
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
    final createState = ref.watch(createDemandProvider);

    ref.listen(createDemandProvider, (previous, next) {
      next.whenOrNull(
        data: (demand) {
          if (demand == null) return;
          AppSnackbar.success(context, 'Pedido publicado!');
          widget.onCreated?.call();
          if (!widget.embedded) Navigator.of(context).pop();
        },
        error: (error, _) => AppSnackbar.error(context, error.toString()),
      );
    });

    final body = AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      child: _step == 1
          ? _DemandRouteStep(
              key: const ValueKey('demand-route'),
              formKey: _routeFormKey,
              direction: _direction,
              onDirectionChanged: (value) => setState(() => _direction = value),
              onAddressSelected: (value) =>
                  setState(() => _otherAddress = value),
              onContinue: _continueToTime,
            )
          : _DemandTimeStep(
              key: const ValueKey('demand-time'),
              origin: _originName,
              destination: _destinationName,
              dateLabel: _dateLabel,
              onEditRoute: () => setState(() => _step = 1),
              onPickDate: _pickDesiredTime,
              onSubmit: createState.isLoading ? null : _submit,
              isLoading: createState.isLoading,
            ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar:
          widget.embedded ? null : AppBar(title: const Text('PEDIR CARONA')),
      body: body,
    );
  }

  String get _originName => _direction == TripDirection.toFatec
      ? _otherAddress?.displayName ?? ''
      : kFatecName;

  String get _destinationName => _direction == TripDirection.toFatec
      ? kFatecName
      : _otherAddress?.displayName ?? '';

  String get _dateLabel {
    final day = _desiredTime.day.toString().padLeft(2, '0');
    final month = _desiredTime.month.toString().padLeft(2, '0');
    final hour = _desiredTime.hour.toString().padLeft(2, '0');
    final minute = _desiredTime.minute.toString().padLeft(2, '0');
    return '$day/$month/${_desiredTime.year} • $hour:$minute';
  }
}

class _DemandRouteStep extends StatelessWidget {
  const _DemandRouteStep({
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
              title: 'Qual é o trajeto?',
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

class _DemandTimeStep extends StatelessWidget {
  const _DemandTimeStep({
    super.key,
    required this.origin,
    required this.destination,
    required this.dateLabel,
    required this.onEditRoute,
    required this.onPickDate,
    required this.onSubmit,
    required this.isLoading,
  });

  final String origin;
  final String destination;
  final String dateLabel;
  final VoidCallback onEditRoute;
  final VoidCallback onPickDate;
  final VoidCallback? onSubmit;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const NeoFlowHeader(
            currentStep: 2,
            totalSteps: 2,
            title: 'Quando você precisa?',
            description: 'Confirme a rota e escolha o melhor horário.',
          ),
          const SizedBox(height: 16),
          NeoRouteReview(
              origin: origin, destination: destination, onEdit: onEditRoute),
          const SizedBox(height: 14),
          NeoOutlineButton(
            onPressed: onPickDate,
            icon: const Icon(Icons.schedule_rounded),
            trailing: const Icon(Icons.edit_rounded),
            child: Text(dateLabel),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.secondary.withValues(alpha: 0.12),
              border:
                  Border(left: BorderSide(color: scheme.secondary, width: 4)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: scheme.secondary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Motoristas da região poderão visualizar este pedido.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          NeoButton(
            onPressed: onSubmit,
            icon: const Icon(Icons.bolt_rounded),
            trailing: const Icon(Icons.arrow_forward_rounded),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('PUBLICAR PEDIDO'),
          ),
        ],
      ),
    );
  }
}

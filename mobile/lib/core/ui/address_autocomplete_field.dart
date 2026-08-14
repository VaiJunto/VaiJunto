import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../geocoding/geocoding_repository.dart';
import '../geocoding/geocoding_result_model.dart';
import '../theme/neo_brutal_theme.dart';
import 'location_pin_picker.dart';

/// Campo de endereço com busca real (Nominatim/OpenStreetMap) em vez de
/// texto livre + latitude/longitude digitados à mão — assim não dá pra
/// mandar um endereço que não existe, e a demanda/oferta já nasce com
/// coordenadas de verdade.
///
/// Só aceita um endereço que veio da busca: [validator] (via [FormField])
/// reprova se o usuário digitou algo e não chegou a selecionar uma
/// sugestão da lista.
class AddressAutocompleteField extends ConsumerStatefulWidget {
  const AddressAutocompleteField({
    super.key,
    required this.label,
    required this.hint,
    required this.onSelected,
  });

  final String label;
  final String hint;
  final ValueChanged<GeocodingResult?> onSelected;

  @override
  ConsumerState<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState
    extends ConsumerState<AddressAutocompleteField> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<GeocodingResult> _results = [];
  bool _loading = false;
  bool _searchCompleted = false;
  bool _outsideRegion = false;
  GeocodingResult? _selected;
  int _searchGeneration = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _searchGeneration++;
    if (_selected != null) {
      setState(() => _selected = null);
      widget.onSelected(null);
    }

    _debounce?.cancel();
    if (query.trim().length < 3) {
      setState(() {
        _results = [];
        _loading = false;
        _searchCompleted = false;
      });
      return;
    }

    final generation = _searchGeneration;
    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => _search(query.trim(), generation),
    );
  }

  Future<void> _search(String query, int generation) async {
    setState(() {
      _loading = true;
      _searchCompleted = false;
    });
    try {
      final repository = ref.read(geocodingRepositoryProvider);
      final results =
          await repository.search(query, outsideRegion: _outsideRegion);
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _results = results;
        _searchCompleted = true;
      });
    } catch (_) {
      if (mounted && generation == _searchGeneration) {
        setState(() {
          _results = [];
          _searchCompleted = true;
        });
      }
    } finally {
      if (mounted && generation == _searchGeneration) {
        setState(() => _loading = false);
      }
    }
  }

  void _select(GeocodingResult result) {
    setState(() {
      _selected = result;
      _results = [];
      _controller.text = result.displayName;
    });
    FocusScope.of(context).unfocus();
    widget.onSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FormField<GeocodingResult>(
      validator: (_) =>
          _selected == null ? 'Busque e selecione um endereço da lista' : null,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: widget.label,
                hintText: widget.hint,
                errorText: field.errorText,
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : (_selected != null
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: NeoBrutal.lime,
                          )
                        : null),
              ),
              onChanged: (value) {
                _onChanged(value);
                field.didChange(_selected);
              },
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.near_me_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Sugestões no Vale do Paraíba, perto da Fatec SJC',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final selected = await Navigator.of(context)
                      .push<GeocodingResult>(MaterialPageRoute(
                          builder: (_) => const LocationPinPicker()));
                  if (selected != null && mounted) {
                    _select(selected);
                    field.didChange(selected);
                  }
                },
                icon: const Icon(Icons.my_location_rounded, size: 16),
                label: const Text('USAR MINHA LOCALIZAÇÃO'),
              ),
            ),
            if (_searchCompleted && !_loading && _results.isEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _outsideRegion
                      ? null
                      : () {
                          setState(() => _outsideRegion = true);
                          _searchGeneration++;
                          _search(_controller.text.trim(), _searchGeneration);
                        },
                  icon: const Icon(Icons.public_rounded, size: 16),
                  label: const Text('BUSCAR FORA DA REGIÃO'),
                ),
              ),
            if (_results.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 6),
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: NeoBrutal.decoration(
                  color: theme.colorScheme.surface,
                  borderColor: theme.colorScheme.ink,
                  offset: NeoBrutal.shadowOffsetSmall,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _results.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: theme.colorScheme.ink),
                  itemBuilder: (context, index) {
                    final result = _results[index];
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        _select(result);
                        field.didChange(result);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              color: theme.colorScheme.primary,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.place_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    result.primaryText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (result.secondaryText.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      result.secondaryText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                  if (result.distanceLabel.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      result.distanceLabel,
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.secondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Icon(Icons.north_east_rounded, size: 16),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (_searchCompleted && !_loading && _results.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _outsideRegion
                      ? 'Não encontramos esse endereço no Brasil. Tente incluir cidade ou bairro.'
                      : 'Não encontramos esse local no Vale do Paraíba. Tente incluir o bairro ou a cidade.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

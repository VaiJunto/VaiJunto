import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../geocoding/geocoding_repository.dart';
import '../geocoding/geocoding_result_model.dart';
import '../theme/neo_brutal_theme.dart';

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
  GeocodingResult? _selected;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    if (_selected != null) {
      setState(() => _selected = null);
      widget.onSelected(null);
    }

    _debounce?.cancel();
    if (query.trim().length < 3) {
      setState(() => _results = []);
      return;
    }

    _debounce =
        Timer(const Duration(milliseconds: 600), () => _search(query.trim()));
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    try {
      final repository = ref.read(geocodingRepositoryProvider);
      final results = await repository.search(query);
      if (!mounted) return;
      setState(() => _results = results);
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _loading = false);
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
                              child: Text(
                                result.displayName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
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
          ],
        );
      },
    );
  }
}

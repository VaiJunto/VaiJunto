import 'package:flutter/material.dart';

import '../config/campus.dart';
import '../theme/neo_brutal_theme.dart';
import 'neo_card.dart';
import 'neo_segmented_control.dart';

enum TripDirection { toFatec, fromFatec }

/// Direção da rota em um único controle compacto, seguido do ponto fixo.
class FatecDirectionSelector extends StatelessWidget {
  const FatecDirectionSelector({
    super.key,
    required this.direction,
    required this.onChanged,
  });

  final TripDirection direction;
  final ValueChanged<TripDirection> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        NeoSegmentedControl(
          selectedIndex: direction == TripDirection.toFatec ? 0 : 1,
          onSelected: (index) => onChanged(
            index == 0 ? TripDirection.toFatec : TripDirection.fromFatec,
          ),
          segments: const [
            NeoSegment(label: 'Ir pra Fatec', icon: Icons.south_east_rounded),
            NeoSegment(label: 'Sair da Fatec', icon: Icons.north_east_rounded),
          ],
        ),
        const SizedBox(height: 12),
        NeoCard(
          color: scheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          offset: NeoBrutal.shadowOffsetSmall,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  border: Border.all(color: scheme.ink, width: 2),
                  borderRadius: BorderRadius.circular(3),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.school_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      direction == TripDirection.toFatec
                          ? 'DESTINO FIXO'
                          : 'ORIGEM FIXA',
                      style: TextStyle(
                        color: scheme.secondary,
                        fontFamily: 'IBMPlexMono',
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      kFatecName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

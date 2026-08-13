import 'package:flutter/material.dart';

import '../theme/neo_brutal_theme.dart';

class NeoSegment {
  const NeoSegment({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Seletor compacto para decisões mutuamente exclusivas. Não cria quatro
/// botões independentes nem compete com o CTA principal.
class NeoSegmentedControl extends StatelessWidget {
  const NeoSegmentedControl({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.segments,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<NeoSegment> segments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.ink, width: NeoBrutal.borderWidth),
        borderRadius: BorderRadius.circular(NeoBrutal.borderRadius),
      ),
      child: Row(
        children: List.generate(segments.length, (index) {
          final segment = segments[index];
          final selected = index == selectedIndex;
          final foreground = selected ? scheme.onSecondary : scheme.ink;

          return Expanded(
            child: Semantics(
              button: true,
              selected: selected,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 130),
                  decoration: BoxDecoration(
                    color: selected ? scheme.secondary : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(segment.icon, size: 18, color: foreground),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          segment.label.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: foreground,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

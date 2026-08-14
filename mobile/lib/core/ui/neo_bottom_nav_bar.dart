import 'package:flutter/material.dart';

import '../theme/neo_brutal_theme.dart';

class NeoBottomNavDestination {
  const NeoBottomNavDestination(
      {required this.icon, required this.label, this.badgeCount = 0});

  final IconData icon;
  final String label;
  final int badgeCount;
}

/// Uma única peça de navegação para economizar altura e reduzir ruído visual.
class NeoBottomNavBar extends StatelessWidget {
  const NeoBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    required this.destinations,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;
  final List<NeoBottomNavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
          child: Container(
            height: 62,
            padding: const EdgeInsets.all(3),
            decoration: NeoBrutal.decoration(
              color: scheme.surface,
              borderColor: scheme.ink,
              offset: NeoBrutal.shadowOffsetSmall,
            ),
            child: Row(
              children: List.generate(destinations.length, (index) {
                final destination = destinations[index];
                final selected = currentIndex == index;
                final foreground = selected ? scheme.onSecondary : scheme.ink;

                return Expanded(
                  child: Semantics(
                    button: true,
                    selected: selected,
                    label: destination.label,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelected(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 130),
                        decoration: BoxDecoration(
                          color:
                              selected ? scheme.secondary : Colors.transparent,
                          border: index == 0
                              ? null
                              : Border(
                                  left:
                                      BorderSide(color: scheme.ink, width: 2)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(clipBehavior: Clip.none, children: [
                              Icon(destination.icon,
                                  size: 21, color: foreground),
                              if (destination.badgeCount > 0)
                                Positioned(
                                    right: -9,
                                    top: -8,
                                    child: Container(
                                        constraints: const BoxConstraints(
                                            minWidth: 16, minHeight: 16),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                            color: scheme.primary,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: scheme.ink, width: 1.5)),
                                        child: Text(
                                            destination.badgeCount > 9
                                                ? '9+'
                                                : '${destination.badgeCount}',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                                fontWeight: FontWeight.w900))))
                            ]),
                            const SizedBox(height: 4),
                            Text(
                              destination.label.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: foreground,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 9,
                                    letterSpacing: 0.25,
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
          ),
        ),
      ),
    );
  }
}

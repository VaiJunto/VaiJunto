import 'package:flutter/material.dart';

import '../theme/neo_brutal_theme.dart';

/// Loader em células sólidas, mais coerente com o HUD do app do que o spinner
/// circular padrão do Material.
class NeoLoadingIndicator extends StatefulWidget {
  const NeoLoadingIndicator({
    super.key,
    this.compact = false,
    this.label,
  });

  final bool compact;
  final String? label;

  @override
  State<NeoLoadingIndicator> createState() => _NeoLoadingIndicatorState();
}

class _NeoLoadingIndicatorState extends State<NeoLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduceMotion) {
      _controller.stop();
      _controller.value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cellCount = widget.compact ? 3 : 8;

    return Semantics(
      label: widget.label ?? 'Carregando',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final active = (_controller.value * cellCount).floor() % cellCount;
          final cells = Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(cellCount, (index) {
              final distance = (index - active).abs();
              final color = index == active
                  ? scheme.primary
                  : distance == 1
                      ? scheme.tertiary.withValues(alpha: 0.72)
                      : scheme.ink.withValues(alpha: 0.18);
              return Container(
                width: widget.compact ? 6 : 18,
                height: widget.compact ? 16 : 10,
                margin: EdgeInsets.only(right: index == cellCount - 1 ? 0 : 4),
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(
                    color: scheme.ink,
                    width: widget.compact ? 1 : 1.5,
                  ),
                ),
              );
            }),
          );

          if (widget.label == null || widget.compact) return cells;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              cells,
              const SizedBox(height: 12),
              Text(
                widget.label!,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Linha de boot para a splash: trilho, marcador e estado humano.
class NeoBootRail extends StatelessWidget {
  const NeoBootRail({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 7, height: 7, color: NeoBrutal.lime),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(fontSize: 10),
              ),
            ),
            Text(
              'SYNC',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.tertiary,
                fontSize: 9,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const NeoLoadingIndicator(),
      ],
    );
  }
}

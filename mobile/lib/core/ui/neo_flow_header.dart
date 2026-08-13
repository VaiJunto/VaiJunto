import 'package:flutter/material.dart';

import '../theme/neo_brutal_theme.dart';

class NeoFlowHeader extends StatelessWidget {
  const NeoFlowHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.title,
    required this.description,
  });

  final int currentStep;
  final int totalSteps;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              color: scheme.secondary,
              child: Text(
                '${currentStep.toString().padLeft(2, '0')}/${totalSteps.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: scheme.onSecondary,
                  fontFamily: 'IBMPlexMono',
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(totalSteps, (index) {
            final filled = index < currentStep;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 5),
                color:
                    filled ? scheme.primary : scheme.ink.withValues(alpha: 0.2),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class NeoRouteReview extends StatelessWidget {
  const NeoRouteReview({
    super.key,
    required this.origin,
    required this.destination,
    required this.onEdit,
  });

  final String origin;
  final String destination;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.ink, width: NeoBrutal.borderWidth),
        borderRadius: BorderRadius.circular(NeoBrutal.borderRadius),
      ),
      child: Row(
        children: [
          Column(
            children: [
              _Node(color: scheme.primary),
              Container(width: 2, height: 28, color: scheme.ink),
              _Node(color: scheme.secondary),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(origin,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 18),
                Text(destination,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            tooltip: 'Editar rota',
            icon: const Icon(Icons.edit_rounded),
          ),
        ],
      ),
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Theme.of(context).colorScheme.ink, width: 2),
      ),
    );
  }
}

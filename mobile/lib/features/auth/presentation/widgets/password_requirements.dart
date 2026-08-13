import 'package:flutter/material.dart';
import '../../../../core/ui/neo_card.dart';
import '../../../../core/validation/auth_validators.dart';

/// Checklist ao vivo dos requisitos de senha.
///
/// Cada regra fica cinza até ser atendida, então vira verde com um check.
class PasswordRequirements extends StatelessWidget {
  const PasswordRequirements({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: NeoCard(
        color: theme.colorScheme.surfaceContainerHighest,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sua senha precisa ter:',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ...passwordRules.map((rule) {
            final ok = rule.isSatisfiedBy(password);
            final color = ok
                ? const Color(0xFF2E7D32)
                : theme.colorScheme.onSurfaceVariant;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    ok ? Icons.check_circle : Icons.circle_outlined,
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    rule.label,
                    style: theme.textTheme.bodySmall?.copyWith(color: color),
                  ),
                ],
              ),
            );
          }),
        ],
        ),
      ),
    );
  }
}

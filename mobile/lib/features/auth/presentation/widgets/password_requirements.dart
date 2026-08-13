import 'package:flutter/material.dart';

import '../../../../core/theme/neo_brutal_theme.dart';
import '../../../../core/validation/auth_validators.dart';

class PasswordRequirements extends StatelessWidget {
  const PasswordRequirements({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final results = passwordRules
        .map((rule) => (rule: rule, valid: rule.isSatisfiedBy(password)))
        .toList();
    final completed = results.where((result) => result.valid).length;
    final isComplete = completed == passwordRules.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.92),
        border: Border.all(color: scheme.ink, width: 2),
        borderRadius: BorderRadius.circular(NeoBrutal.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'FORÇA DA SENHA',
                  style: theme.textTheme.labelMedium?.copyWith(fontSize: 9),
                ),
              ),
              Text(
                _statusLabel(password, completed),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isComplete ? NeoBrutal.lime : scheme.tertiary,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(passwordRules.length, (index) {
              final active = index < completed;
              return Expanded(
                child: Container(
                  height: 5,
                  margin: EdgeInsets.only(
                    right: index == passwordRules.length - 1 ? 0 : 5,
                  ),
                  color: active
                      ? (isComplete ? NeoBrutal.lime : scheme.secondary)
                      : scheme.ink.withValues(alpha: 0.14),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 8,
                children: results.map((result) {
                  return SizedBox(
                    width: itemWidth,
                    child: _RequirementItem(
                      label: _compactLabel(result.rule.label),
                      valid: result.valid,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RequirementItem extends StatelessWidget {
  const _RequirementItem({required this.label, required this.valid});

  final String label;
  final bool valid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: valid ? NeoBrutal.lime : Colors.transparent,
            border: Border.all(color: scheme.ink, width: 1.5),
          ),
          child: valid
              ? const Icon(
                  Icons.check_rounded,
                  size: 11,
                  color: NeoBrutal.inkLight,
                )
              : null,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: valid ? scheme.ink : scheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}

String _statusLabel(String password, int completed) {
  if (password.isEmpty) return 'COMECE A DIGITAR';
  if (completed == passwordRules.length) return 'PRONTA';
  if (completed >= 2) return 'QUASE LÁ';
  return 'FRACA';
}

String _compactLabel(String label) {
  if (label.contains('8 caracteres')) return '8+ caracteres';
  if (label.contains('maiúscula')) return 'Maiúscula';
  if (label.contains('minúscula')) return 'Minúscula';
  if (label.contains('número')) return 'Número';
  return label;
}

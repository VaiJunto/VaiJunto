import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutal_theme.dart';

/// Marca do app: ícone de van num bloco neon levemente torto (efeito
/// adesivo colado) + wordmark bem pesada.
///
/// Desenhado em código para não depender de asset — o mesmo desenho é usado
/// como base do ícone do launcher.
class VaiJuntoLogo extends StatelessWidget {
  const VaiJuntoLogo({super.key, this.size = 72, this.showWordmark = true});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.ink;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: -0.06,
          child: Container(
            width: size,
            height: size,
            decoration: NeoBrutal.decoration(
              color: NeoBrutal.ultraviolet,
              borderColor: ink,
              radius: size * 0.22,
            ),
            child: Icon(
              Icons.airport_shuttle_rounded,
              size: size * 0.56,
              color: ink,
            ),
          ),
        ),
        if (showWordmark) ...[
          SizedBox(height: size * 0.3),
          Text(
            'VAIJUNTO',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'CARONAS E VANS UNIVERSITÁRIAS',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/neo_brutal_theme.dart';

/// Bloco padrão do app: fundo sólido, borda grossa preta (ou branca no
/// escuro) e sombra dura deslocada — a unidade de construção do
/// neobrutalismo em vez do `Card` com elevação suave do Material.
class NeoCard extends StatelessWidget {
  const NeoCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(16),
    this.rotation = 0,
    this.offset = NeoBrutal.shadowOffset,
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;

  /// Leve rotação (em radianos) pra dar o efeito "adesivo colado torto" de
  /// street art — usar com moderação, só em elementos de destaque.
  final double rotation;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final card = Container(
      padding: padding,
      decoration: NeoBrutal.decoration(
        color: color ?? scheme.surface,
        borderColor: scheme.ink,
        offset: offset,
      ),
      child: child,
    );

    if (rotation == 0) return card;
    return Transform.rotate(angle: rotation, child: card);
  }
}

/// Selo pequeno (badge) com o mesmo tratamento visual — usado pra rótulos
/// curtos (versão do app, status, tag).
class NeoBadge extends StatelessWidget {
  const NeoBadge({
    super.key,
    required this.child,
    this.color,
    this.rotation = 0,
  });

  final Widget child;
  final Color? color;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: NeoBrutal.decoration(
        color: color ?? scheme.surface,
        borderColor: scheme.ink,
        radius: 999,
        offset: NeoBrutal.shadowOffsetSmall,
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          color: scheme.ink,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
        child: child,
      ),
    );

    if (rotation == 0) return badge;
    return Transform.rotate(angle: rotation, child: badge);
  }
}

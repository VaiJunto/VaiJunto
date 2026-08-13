import 'package:flutter/material.dart';
import '../theme/neo_brutal_theme.dart';

/// Botão neobrutalista: bloco sólido, borda grossa, sombra dura deslocada
/// que "some" (o botão desliza pro canto da sombra) quando pressionado —
/// a simulação tátil de afundar um bloco físico, no lugar do ripple padrão
/// do Material.
class NeoButton extends StatefulWidget {
  const NeoButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
    this.height = 56,
    this.icon,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? color;
  final double height;
  final Widget? icon;

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null;
    final color = widget.color ?? scheme.primary;
    final ink = scheme.ink;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        height: widget.height,
        width: double.infinity,
        margin: EdgeInsets.only(
          left: _pressed ? NeoBrutal.shadowOffset.dx : 0,
          top: _pressed ? NeoBrutal.shadowOffset.dy : 0,
        ),
        decoration: NeoBrutal.decoration(
          color: enabled ? color : color.withOpacity(0.45),
          borderColor: ink,
          pressed: _pressed,
        ),
        alignment: Alignment.center,
        child: Opacity(
          opacity: enabled ? 1 : 0.6,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[widget.icon!, const SizedBox(width: 10)],
              DefaultTextStyle(
                style: TextStyle(
                  color: ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
                child: widget.child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Variante "vazada": mesma moldura e sombra, mas fundo da superfície em
/// vez de cor sólida — pra ações secundárias (ex: "criar conta" ao lado de
/// "entrar").
class NeoOutlineButton extends StatelessWidget {
  const NeoOutlineButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.height = 56,
    this.icon,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final double height;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return NeoButton(
      onPressed: onPressed,
      color: scheme.surface,
      height: height,
      icon: icon,
      child: child,
    );
  }
}

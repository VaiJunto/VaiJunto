import 'package:flutter/material.dart';

import '../theme/neo_brutal_theme.dart';

/// Ação digital neobrutalista: geometria reta, sombra sólida e resposta física.
class NeoButton extends StatefulWidget {
  const NeoButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
    this.foregroundColor,
    this.height = 52,
    this.icon,
    this.trailing,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? color;
  final Color? foregroundColor;
  final double height;
  final Widget? icon;
  final Widget? trailing;

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null;
    final background = widget.color ?? scheme.primary;
    final foreground = widget.foregroundColor ??
        (background == scheme.surface ? scheme.ink : Colors.white);

    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          height: widget.height,
          width: double.infinity,
          margin: EdgeInsets.only(
            left: _pressed ? NeoBrutal.shadowOffset.dx : 0,
            top: _pressed ? NeoBrutal.shadowOffset.dy : 0,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: NeoBrutal.decoration(
            color: enabled ? background : background.withValues(alpha: 0.45),
            borderColor: scheme.ink,
            pressed: _pressed,
          ),
          child: Opacity(
            opacity: enabled ? 1 : 0.65,
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  IconTheme(
                    data: IconThemeData(color: foreground, size: 20),
                    child: widget.icon!,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: DefaultTextStyle(
                      style: TextStyle(
                        color: foreground,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                      child: widget.child,
                    ),
                  ),
                ),
                if (widget.trailing != null) ...[
                  const SizedBox(width: 10),
                  IconTheme(
                    data: IconThemeData(color: foreground, size: 19),
                    child: widget.trailing!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NeoOutlineButton extends StatelessWidget {
  const NeoOutlineButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.height = 52,
    this.icon,
    this.trailing,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final double height;
  final Widget? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return NeoButton(
      onPressed: onPressed,
      color: scheme.surface,
      foregroundColor: scheme.ink,
      height: height,
      icon: icon,
      trailing: trailing,
      child: child,
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/neo_brutal_theme.dart';

/// Fundo exclusivo da autenticação: mais escuro que o restante do app e com
/// um único scanner lento. Não há mapa, texto ou múltiplos objetos competindo
/// com os campos; a animação só impede que o plano pareça uma cor chapada.
class NeoAuthBackdrop extends StatefulWidget {
  const NeoAuthBackdrop({super.key});

  @override
  State<NeoAuthBackdrop> createState() => _NeoAuthBackdropState();
}

class _NeoAuthBackdropState extends State<NeoAuthBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduceMotion) {
      _controller.stop();
      _controller.value = 0.34;
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
    final scheme = Theme.of(context).colorScheme;

    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _AuthBackdropPainter(
              progress: _controller.value % 1,
              isDark: scheme.brightness == Brightness.dark,
              ink: scheme.ink,
              signal: scheme.tertiary,
              selection: scheme.secondary,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _AuthBackdropPainter extends CustomPainter {
  const _AuthBackdropPainter({
    required this.progress,
    required this.isDark,
    required this.ink,
    required this.signal,
    required this.selection,
  });

  final double progress;
  final bool isDark;
  final Color ink;
  final Color signal;
  final Color selection;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = isDark ? const Color(0xFF09080D) : const Color(0xFFEAE5DB),
    );

    _drawArchitecture(canvas, size);
    _drawScanBand(canvas, size);
    _drawSignalLine(canvas, size);
  }

  void _drawArchitecture(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ink.withValues(alpha: isDark ? 0.028 : 0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRect(
      Rect.fromLTWH(
          -24, size.height * 0.13, size.width * 0.66, size.height * 0.24),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.48,
        size.height * 0.62,
        size.width * 0.68,
        size.height * 0.22,
      ),
      paint,
    );
  }

  void _drawScanBand(Canvas canvas, Size size) {
    const bandWidth = 96.0;
    final x = -bandWidth + (size.width + bandWidth * 2) * progress;
    final band = Path()
      ..moveTo(x, 0)
      ..lineTo(x + bandWidth, 0)
      ..lineTo(x + bandWidth * 0.42, size.height)
      ..lineTo(x - bandWidth * 0.58, size.height)
      ..close();

    canvas.drawPath(
      band,
      Paint()
        ..color = selection.withValues(alpha: isDark ? 0.032 : 0.04)
        ..style = PaintingStyle.fill,
    );
  }

  void _drawSignalLine(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(-20, size.height * 0.78)
      ..lineTo(size.width * 0.28, size.height * 0.78)
      ..lineTo(size.width * 0.28, size.height * 0.86)
      ..lineTo(size.width + 20, size.height * 0.86);
    final paint = Paint()
      ..color = signal.withValues(alpha: isDark ? 0.075 : 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (final metric in path.computeMetrics()) {
      var distance = -(progress * 30);
      while (distance < metric.length) {
        final start = distance.clamp(0.0, metric.length);
        final end = (distance + 9).clamp(0.0, metric.length);
        if (end > start) canvas.drawPath(metric.extractPath(start, end), paint);
        distance += 15;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AuthBackdropPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.isDark != isDark ||
      oldDelegate.ink != ink ||
      oldDelegate.signal != signal ||
      oldDelegate.selection != selection;
}

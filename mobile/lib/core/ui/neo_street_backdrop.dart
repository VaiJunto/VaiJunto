import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/neo_brutal_theme.dart';

enum NeoStreetBackdropVariant { app, auth, loading }

@visibleForTesting
double neoLoopProgress(double value) => value % 1;

/// Mapa técnico vivo usado como plano de fundo do VaiJunto.
///
/// A rota se desloca devagar, os nós respiram e um único pacote percorre o
/// caminho. O movimento é deliberadamente discreto para dar vida aos vazios
/// sem competir com formulários, cards ou CTAs.
class NeoStreetBackdrop extends StatefulWidget {
  const NeoStreetBackdrop({
    super.key,
    this.variant = NeoStreetBackdropVariant.app,
    this.animate = true,
  });

  final NeoStreetBackdropVariant variant;
  final bool animate;

  @override
  State<NeoStreetBackdrop> createState() => _NeoStreetBackdropState();
}

class _NeoStreetBackdropState extends State<NeoStreetBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(
      seconds: widget.variant == NeoStreetBackdropVariant.loading ? 6 : 12,
    ),
  );

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ||
        !widget.animate;
    if (_reduceMotion) {
      _controller.stop();
      _controller.value = 0.22;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant NeoStreetBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.variant != widget.variant ||
        oldWidget.animate != widget.animate) {
      _controller.duration = Duration(
        seconds: widget.variant == NeoStreetBackdropVariant.loading ? 6 : 12,
      );
      _reduceMotion =
          (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ||
              !widget.animate;
      if (_reduceMotion) {
        _controller.stop();
        _controller.value = 0.22;
      } else {
        _controller.repeat();
      }
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
            painter: _StreetMapPainter(
              ink: scheme.ink,
              signal: scheme.tertiary,
              action: scheme.primary,
              progress: neoLoopProgress(_controller.value),
              variant: widget.variant,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _StreetMapPainter extends CustomPainter {
  const _StreetMapPainter({
    required this.ink,
    required this.signal,
    required this.action,
    required this.progress,
    required this.variant,
  });

  final Color ink;
  final Color signal;
  final Color action;
  final double progress;
  final NeoStreetBackdropVariant variant;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    _drawGrid(canvas, size);

    final route = _routeFor(size);
    final routePaint = Paint()
      ..color = signal.withValues(alpha: 0.23)
      ..strokeWidth = variant == NeoStreetBackdropVariant.loading ? 2 : 1.5
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;
    // 30 Ã© exatamente dois ciclos de traÃ§o+espaÃ§o (15 px). Assim o frame
    // final coincide com o inicial e o repeat nÃ£o produz um salto visÃ­vel.
    _drawDashedPath(canvas, route, routePaint, phase: progress * 30);
    _drawNodes(canvas, size);
    _drawPacket(canvas, route);
    _drawHudLabels(canvas, size);
    _drawCutMarks(canvas, size);
  }

  Path _routeFor(Size size) {
    switch (variant) {
      case NeoStreetBackdropVariant.auth:
        return Path()
          ..moveTo(-24, size.height * 0.22)
          ..lineTo(size.width * 0.10, size.height * 0.22)
          ..lineTo(size.width * 0.10, size.height * 0.70)
          ..lineTo(size.width * 0.72, size.height * 0.70)
          ..lineTo(size.width * 0.72, size.height * 0.90)
          ..lineTo(size.width + 24, size.height * 0.90);
      case NeoStreetBackdropVariant.loading:
        final left = size.width * 0.14;
        final right = size.width * 0.86;
        final top = size.height * 0.25;
        final bottom = size.height * 0.75;
        return Path()
          ..moveTo(size.width * 0.50, top)
          ..lineTo(right, top)
          ..lineTo(right, bottom)
          ..lineTo(left, bottom)
          ..lineTo(left, top)
          ..close();
      case NeoStreetBackdropVariant.app:
        return Path()
          // O pacote nasce e termina fora da viewport. No reinÃ­cio ele troca
          // de lado enquanto estÃ¡ invisÃ­vel, em vez de teleportar na tela.
          ..moveTo(-24, size.height * 0.04)
          ..lineTo(size.width * 0.22, size.height * 0.04)
          ..lineTo(size.width * 0.22, size.height * 0.43)
          ..lineTo(size.width * 0.82, size.height * 0.43)
          ..lineTo(size.width * 0.82, size.height * 0.76)
          ..lineTo(size.width + 24, size.height * 0.76);
    }
  }

  List<Offset> _nodesFor(Size size) {
    switch (variant) {
      case NeoStreetBackdropVariant.auth:
        return [
          Offset(size.width * 0.10, size.height * 0.22),
          Offset(size.width * 0.10, size.height * 0.70),
          Offset(size.width * 0.72, size.height * 0.70),
          Offset(size.width * 0.72, size.height * 0.90),
        ];
      case NeoStreetBackdropVariant.loading:
        return [
          Offset(size.width * 0.50, size.height * 0.25),
          Offset(size.width * 0.86, size.height * 0.75),
          Offset(size.width * 0.14, size.height * 0.75),
        ];
      case NeoStreetBackdropVariant.app:
        return [
          Offset(size.width * 0.22, size.height * 0.04),
          Offset(size.width * 0.22, size.height * 0.43),
          Offset(size.width * 0.82, size.height * 0.43),
          Offset(size.width * 0.82, size.height * 0.76),
        ];
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ink.withValues(alpha: 0.052)
      ..strokeWidth = 1;
    const step = 56.0;
    // Percorre uma cÃ©lula completa: 0 e 1 pintam exatamente o mesmo grid.
    final shift = (progress * step) % step;

    for (var x = shift; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = step - shift; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawNodes(Canvas canvas, Size size) {
    final nodes = _nodesFor(size);
    for (var index = 0; index < nodes.length; index++) {
      final pulse = (math.sin((progress * math.pi * 2) + index * 1.35) + 1) / 2;
      final node = nodes[index];
      canvas.drawCircle(
        node,
        6 + pulse * 5,
        Paint()
          ..color = signal.withValues(alpha: 0.05 + pulse * 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      canvas.drawRect(
        Rect.fromCenter(center: node, width: 5, height: 5),
        Paint()
          ..color = signal.withValues(alpha: 0.30)
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _drawPacket(Canvas canvas, Path route) {
    for (final metric in route.computeMetrics()) {
      final tangent = metric.getTangentForOffset(metric.length * progress);
      if (tangent == null) continue;
      final rect = Rect.fromCenter(
        center: tangent.position,
        width: 9,
        height: 9,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = action.withValues(alpha: 0.72)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        rect.inflate(3),
        Paint()
          ..color = action.withValues(alpha: 0.20)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  void _drawHudLabels(Canvas canvas, Size size) {
    final List<(String, double, double)> labels = switch (variant) {
      NeoStreetBackdropVariant.auth => const [
          ('FATEC_SJC', 0.72, 0.76),
          ('23.16S // 45.90W', 12.0, 0.86),
        ],
      NeoStreetBackdropVariant.loading => const [
          ('BOOT//ROUTE_SYNC', 12.0, 0.15),
          ('LOCAL_FIRST', 0.67, 0.82),
        ],
      NeoStreetBackdropVariant.app => const [
          ('SJC//ROUTE_SCAN', 12.0, 0.10),
          ('NODE 03', 0.76, 0.60),
          ('23.16S // 45.90W', 12.0, 0.88),
        ],
    };

    for (final label in labels) {
      final x = label.$2 <= 1 ? size.width * label.$2 : label.$2;
      final painter = TextPainter(
        text: TextSpan(
          text: label.$1,
          style: TextStyle(
            color: signal.withValues(alpha: 0.20),
            fontFamily: 'IBMPlexMono',
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(x, size.height * label.$3));
    }
  }

  void _drawCutMarks(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ink.withValues(alpha: 0.09)
      ..strokeWidth = 1.2;
    for (var y = 84.0; y < size.height; y += 176) {
      _drawCross(canvas, Offset(size.width - 18, y), paint);
    }
    _drawCross(canvas, const Offset(18, 28), paint);
  }

  void _drawCross(Canvas canvas, Offset center, Paint paint) {
    canvas.drawLine(center.translate(-6, 0), center.translate(6, 0), paint);
    canvas.drawLine(center.translate(0, -6), center.translate(0, 6), paint);
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double phase,
  }) {
    for (final metric in path.computeMetrics()) {
      var distance = -phase;
      while (distance < metric.length) {
        final start = distance.clamp(0.0, metric.length);
        final end = (distance + 8).clamp(0.0, metric.length);
        if (end > start) canvas.drawPath(metric.extractPath(start, end), paint);
        distance += 15;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StreetMapPainter oldDelegate) =>
      oldDelegate.ink != ink ||
      oldDelegate.signal != signal ||
      oldDelegate.action != action ||
      oldDelegate.progress != progress ||
      oldDelegate.variant != variant;
}

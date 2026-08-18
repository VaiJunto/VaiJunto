import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/neo_brutal_theme.dart' show NeoBrutalColorScheme;

/// Relógio único da corrida geométrica.
///
/// Cada instância do backdrop tem o próprio [Ticker] só para agendar repaint,
/// mas todas leem este cronômetro. Assim duas áreas na mesma tela mostram
/// exatamente o mesmo trecho do percurso, sem precisar plumbing de controller.
final Stopwatch _runClock = Stopwatch();

/// Lado do bloco base do percurso. Tudo (pico, plataforma, salto) é múltiplo
/// disto — é o que dá a leitura de grade dura, sem forma orgânica.
const double _tile = 34;

/// Velocidade de rolagem em px de mundo por segundo (~3 blocos/s).
const double _speed = 104;

/// Cadência de obstáculos: um "slot" a cada 6 blocos (~2 s).
const int _slotTiles = 6;

const double _slotWidth = _slotTiles * _tile;

/// Trava a distância percorrida para testes: com isto o percurso vira uma
/// função pura do valor, sem depender de tempo real.
@visibleForTesting
double? debugGeometryRunDistance;

/// Corrida geométrica infinita para preencher vazios grandes do painel.
///
/// O percurso não é um loop: o obstáculo de cada slot vem de um hash do índice
/// do slot, que cresce junto com o tempo. Em 15 minutos passam ~2.750 blocos
/// (~460 slots) e nenhum trecho se repete — não existe frame de emenda para
/// combinar, porque nada volta ao início.
///
/// O salto é analítico, não simulado: para cada obstáculo existe um intervalo
/// fixo de decolagem/pouso derivado da largura e da altura dele. Isso garante
/// que o cubo sempre passa limpo, em qualquer taxa de quadros, e que a pose
/// congelada (`disableAnimations`) continua coerente.
class NeoGeometryRunBackdrop extends StatefulWidget {
  const NeoGeometryRunBackdrop(
      {super.key, this.animate = true, this.scale = 1});

  final bool animate;

  /// Fator de desenho do percurso. Abaixo de 1 o mundo inteiro (bloco, cubo,
  /// altura de salto) encolhe, então uma faixa baixa — o cabeçalho — ainda
  /// cabe o salto inteiro sem cortar o cubo no topo.
  final double scale;

  @override
  State<NeoGeometryRunBackdrop> createState() => _NeoGeometryRunBackdropState();
}

class _NeoGeometryRunBackdropState extends State<NeoGeometryRunBackdrop>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((_) => setState(() {}));
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant NeoGeometryRunBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) _syncMotion();
  }

  void _syncMotion() {
    _reduceMotion = (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ||
        !widget.animate;
    if (_reduceMotion) {
      if (_ticker.isActive) _ticker.stop();
    } else {
      if (!_runClock.isRunning) _runClock.start();
      if (!_ticker.isActive) _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Pose parada: um trecho qualquer do percurso, sem deslocamento.
    final distance = debugGeometryRunDistance ??
        (_reduceMotion
            ? _slotWidth * 2
            : (_runClock.elapsedMicroseconds / 1000000) * _speed);

    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _GeometryRunPainter(
            ink: scheme.ink,
            signal: scheme.tertiary,
            action: scheme.primary,
            accent: scheme.secondary,
            distance: distance,
            scale: widget.scale,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

/// Obstáculo de um slot, em coordenadas de mundo.
class _Obstacle {
  const _Obstacle({
    required this.x,
    required this.width,
    required this.height,
    required this.spikes,
    required this.block,
  });

  /// Borda esquerda em px de mundo.
  final double x;
  final double width;

  /// Altura acima da linha do chão.
  final double height;

  /// Quantidade de picos desenhados na base (ou no topo, se houver [block]).
  final int spikes;
  final bool block;

  double get takeoff => x - _tile * 0.85;
  double get landing => x + width + _tile * 0.85;
  double get span => landing - takeoff;

  /// Altura do ápice do salto: sempre sobra ~1 bloco de folga.
  double get apex => math.max(height + _tile * 0.95, _tile * 2);
}

/// Hash determinístico do índice do slot.
///
/// Multiplicadores e máscara ficam em 20 bits de propósito: na web `int` é
/// double, e produto de dois valores de 32 bits perderia precisão. Assim o
/// percurso é idêntico em mobile e no Chrome.
int _hash(int index) {
  var h = (index * 0x9E37 + 0x85EB) & 0xFFFFF;
  h ^= h >> 7;
  h = (h * 0x1B873) & 0xFFFFF;
  h ^= h >> 9;
  return h;
}

_Obstacle? _obstacleForSlot(int slot) {
  final h = _hash(slot);
  final kind = h % 100;
  if (kind < 12) return null; // respiro: trecho limpo

  final (int widthTiles, double height, int spikes, bool block) =
      switch (kind) {
    < 42 => (1, _tile, 1, false),
    < 60 => (2, _tile, 2, false),
    < 70 => (3, _tile, 3, false),
    < 78 => (1, _tile, 0, true),
    < 88 => (2, _tile * 2, 0, true),
    _ => (2, _tile, 1, true),
  };

  // Limita o deslocamento dentro do slot para que a janela de salto de um
  // obstáculo nunca invada a do próximo (senão o cubo pousaria em cima de um
  // pico). shift + largura <= 4 blocos deixa ~1,7 bloco de folga.
  final shift = ((h >> 5) % (5 - widthTiles)) * _tile;

  return _Obstacle(
    x: slot * _slotWidth + shift,
    width: widthTiles * _tile,
    height: height,
    spikes: spikes,
    block: block,
  );
}

class _GeometryRunPainter extends CustomPainter {
  const _GeometryRunPainter({
    required this.ink,
    required this.signal,
    required this.action,
    required this.accent,
    required this.distance,
    required this.scale,
  });

  final Color ink;
  final Color signal;
  final Color action;
  final Color accent;
  final double distance;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.clipRect(Offset.zero & size);
    if (scale != 1) {
      canvas.scale(scale);
      size = size / scale;
    }

    final ground = size.height - (size.height * 0.14).clamp(34.0, 78.0);
    final cubeX = math.min(size.width * 0.2, 150.0);

    _drawGrid(canvas, size, ground);
    _drawPillars(canvas, size, ground);
    _drawGround(canvas, size, ground);
    _drawObstacles(canvas, size, ground);
    _drawCube(canvas, ground, cubeX);
    _drawLabels(canvas, size, ground);
  }

  /// Grade técnica que corre com o percurso — mesma linguagem do
  /// `NeoStreetBackdrop`, só que rolando na horizontal.
  void _drawGrid(Canvas canvas, Size size, double ground) {
    final paint = Paint()
      ..color = ink.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    final shift = distance % _tile;
    for (var x = -shift; x < size.width; x += _tile) {
      canvas.drawLine(Offset(x, 0), Offset(x, ground), paint);
    }
    for (var y = ground - _tile; y > 0; y -= _tile) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  /// Torres de fundo em parallax (35% da velocidade), só contorno.
  void _drawPillars(Canvas canvas, Size size, double ground) {
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final parallax = distance * 0.35;
    final firstSlot = ((parallax - size.width) / _slotWidth).floor();
    final lastSlot = ((parallax + size.width) / _slotWidth).ceil();

    for (var slot = firstSlot; slot <= lastSlot; slot++) {
      final h = _hash(slot * 7 + 3);
      if (h % 3 == 0) continue;
      final height = _tile * (1.5 + (h % 5));
      final width = _tile * (1 + (h >> 4) % 3);
      final left = slot * _slotWidth + ((h >> 8) % 4) * _tile - parallax;
      canvas.drawRect(
        Rect.fromLTWH(left, ground - height, width, height),
        paint,
      );
    }
  }

  void _drawGround(Canvas canvas, Size size, double ground) {
    canvas.drawRect(
      Rect.fromLTWH(0, ground, size.width, size.height - ground),
      Paint()..color = ink.withValues(alpha: 0.06),
    );
    canvas.drawLine(
      Offset(0, ground),
      Offset(size.width, ground),
      Paint()
        ..color = ink.withValues(alpha: 0.24)
        ..strokeWidth = 2.5,
    );

    // Hachura diagonal correndo junto com o chão.
    final hatch = Paint()
      ..color = ink.withValues(alpha: 0.08)
      ..strokeWidth = 1.4;
    final depth = size.height - ground;
    final shift = distance % _tile;
    for (var x = -shift; x < size.width + depth; x += _tile) {
      canvas.drawLine(
        Offset(x, ground),
        Offset(x - depth, ground + depth),
        hatch,
      );
    }
  }

  void _drawObstacles(Canvas canvas, Size size, double ground) {
    final fill = Paint()..color = signal.withValues(alpha: 0.10);
    final stroke = Paint()
      ..color = signal.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final blockFill = Paint()..color = ink.withValues(alpha: 0.07);
    final blockStroke = Paint()
      ..color = ink.withValues(alpha: 0.26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final firstSlot = (distance / _slotWidth).floor() - 1;
    final lastSlot = ((distance + size.width) / _slotWidth).ceil() + 1;

    for (var slot = firstSlot; slot <= lastSlot; slot++) {
      final obstacle = _obstacleForSlot(slot);
      if (obstacle == null) continue;
      final left = obstacle.x - distance;
      if (left > size.width || left + obstacle.width < -_tile) continue;

      var spikeBase = ground;
      if (obstacle.block) {
        final rect = Rect.fromLTWH(
          left,
          ground - obstacle.height,
          obstacle.width,
          obstacle.height,
        );
        canvas.drawRect(rect, blockFill);
        canvas.drawRect(rect, blockStroke);
        canvas.drawRect(rect.deflate(7), blockStroke);
        spikeBase = rect.top;
      }

      for (var index = 0; index < obstacle.spikes; index++) {
        final width = obstacle.block ? _tile : obstacle.width / obstacle.spikes;
        final start = obstacle.block
            ? left + (obstacle.width - width) / 2
            : left + width * index;
        final path = Path()
          ..moveTo(start, spikeBase)
          ..lineTo(start + width / 2, spikeBase - _tile * 0.86)
          ..lineTo(start + width, spikeBase)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
      }
    }
  }

  void _drawCube(Canvas canvas, double ground, double cubeX) {
    final worldX = distance + cubeX;
    final slot = (worldX / _slotWidth).floor();
    var lift = 0.0;
    var turn = 0.0;

    for (var candidate = slot - 1; candidate <= slot + 1; candidate++) {
      final obstacle = _obstacleForSlot(candidate);
      if (obstacle == null) continue;
      if (worldX < obstacle.takeoff || worldX > obstacle.landing) continue;
      final t = (worldX - obstacle.takeoff) / obstacle.span;
      lift = 4 * obstacle.apex * t * (1 - t);
      turn = t * math.pi; // meia volta por salto: pousa sempre reto
      break;
    }

    const side = _tile * 0.72;
    final center = Offset(cubeX + side / 2, ground - lift - side / 2);
    final rect = Rect.fromCenter(center: center, width: side, height: side);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(turn);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawRect(rect, Paint()..color = action.withValues(alpha: 0.42));
    canvas.drawRect(
      rect,
      Paint()
        ..color = ink.withValues(alpha: 0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawRect(
      rect.deflate(side * 0.3),
      Paint()..color = ink.withValues(alpha: 0.22),
    );
    canvas.restore();
  }

  void _drawLabels(Canvas canvas, Size size, double ground) {
    _label(canvas, 'VJ//GEOMETRY_RUN', Offset(14, ground + 12));
    final blocks = (distance / _tile).floor();
    final text = '$blocks BLOCOS';
    final painter = _labelPainter(text);
    painter.paint(
      canvas,
      Offset(size.width - painter.width - 14, ground + 12),
    );
  }

  void _label(Canvas canvas, String text, Offset offset) =>
      _labelPainter(text).paint(canvas, offset);

  TextPainter _labelPainter(String text) => TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: signal.withValues(alpha: 0.22),
            fontFamily: 'IBMPlexMono',
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

  @override
  bool shouldRepaint(covariant _GeometryRunPainter oldDelegate) =>
      oldDelegate.distance != distance ||
      oldDelegate.scale != scale ||
      oldDelegate.ink != ink ||
      oldDelegate.signal != signal ||
      oldDelegate.action != action ||
      oldDelegate.accent != accent;
}

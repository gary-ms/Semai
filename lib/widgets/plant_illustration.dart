import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/plant.dart';

const Color _dark = Color(0xFF2D5A41);
const Color _mid = Color(0xFF4A7D55);
const Color _light = Color(0xFF86A87C);
const Color _vein = Color(0xFFB9CFAE);
const Color _pot = Color(0xFFB4533C);
const Color _potRim = Color(0xFF8F3E2B);

/// Ilustrasi tanaman bergaya botani, digambar dengan kode. Tetap tampil saat
/// offline, jadi dipakai sebagai cadangan foto. Warna datar, tanpa gradien.
class PlantIllustration extends StatelessWidget {
  const PlantIllustration({super.key, required this.kind});

  final PlantKind kind;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PlantPainter(kind),
      child: const SizedBox.expand(),
    );
  }
}

/// Tunas kecil yang tumbuh, dipakai di splash screen.
class SproutMark extends StatelessWidget {
  const SproutMark({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SproutPainter(progress),
      child: const SizedBox.expand(),
    );
  }
}

void _drawLeaf(
  Canvas canvas,
  Offset base,
  double angleDeg,
  double length,
  double width,
  Color color, {
  Color? vein,
}) {
  if (length <= 0 || width <= 0) return;
  canvas.save();
  canvas.translate(base.dx, base.dy);
  canvas.rotate(angleDeg * math.pi / 180);
  final Path path = Path()
    ..moveTo(0, 0)
    ..quadraticBezierTo(width, -length * 0.5, 0, -length)
    ..quadraticBezierTo(-width, -length * 0.5, 0, 0)
    ..close();
  canvas.drawPath(
    path,
    Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true,
  );
  if (vein != null) {
    canvas.drawLine(
      Offset.zero,
      Offset(0, -length * 0.82),
      Paint()
        ..color = vein
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..strokeCap = StrokeCap.round,
    );
  }
  canvas.restore();
}

Offset _quadPoint(Offset a, Offset c, Offset b, double t) {
  final double u = 1 - t;
  return Offset(
    u * u * a.dx + 2 * u * t * c.dx + t * t * b.dx,
    u * u * a.dy + 2 * u * t * c.dy + t * t * b.dy,
  );
}

/// Arah garis singgung kurva dalam derajat, 0 = lurus ke atas.
double _quadAngleDeg(Offset a, Offset c, Offset b, double t) {
  final double u = 1 - t;
  final double dx = 2 * u * (c.dx - a.dx) + 2 * t * (b.dx - c.dx);
  final double dy = 2 * u * (c.dy - a.dy) + 2 * t * (b.dy - c.dy);
  return math.atan2(dx, -dy) * 180 / math.pi;
}

class _PlantPainter extends CustomPainter {
  _PlantPainter(this.kind);

  final PlantKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = math.min(size.width, size.height) / 100;
    if (s <= 0) return;
    canvas.save();
    canvas.translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2);
    canvas.scale(s);
    switch (kind) {
      case PlantKind.leafy:
        _leafy(canvas);
      case PlantKind.rosette:
        _rosette(canvas);
      case PlantKind.fern:
        _fern(canvas);
      case PlantKind.cactus:
        _cactus(canvas);
      case PlantKind.blade:
        _blade(canvas);
      case PlantKind.trailing:
        _trailing(canvas);
    }
    canvas.restore();
  }

  void _drawPot(Canvas canvas) {
    final Path body = Path()
      ..moveTo(33, 76)
      ..lineTo(67, 76)
      ..lineTo(62, 96)
      ..lineTo(38, 96)
      ..close();
    canvas.drawPath(body, Paint()..color = _pot);
    canvas.drawRect(
      const Rect.fromLTRB(30, 72, 70, 78.5),
      Paint()..color = _potRim,
    );
  }

  void _leafy(Canvas canvas) {
    const Offset base = Offset(50, 76);
    const List<double> angles = <double>[-64, -42, -20, 0, 20, 42, 64];
    const List<double> lengths = <double>[30, 38, 44, 48, 42, 36, 29];
    for (int i = 0; i < angles.length; i++) {
      _drawLeaf(
        canvas,
        base,
        angles[i],
        lengths[i],
        22,
        i.isEven ? _dark : _mid,
        vein: _vein,
      );
    }
    _drawPot(canvas);
  }

  void _rosette(Canvas canvas) {
    const Offset base = Offset(50, 76);
    for (final double a in const <double>[-78, -52, 52, 78]) {
      _drawLeaf(canvas, base, a, 24, 14, _dark);
    }
    for (final double a in const <double>[-58, -34, -12, 12, 34, 58]) {
      _drawLeaf(canvas, base, a, 30, 14, _mid);
    }
    for (final double a in const <double>[-36, -14, 0, 14, 36]) {
      _drawLeaf(canvas, base, a, 20, 12, _light);
    }
    _drawPot(canvas);
  }

  void _fern(Canvas canvas) {
    const Offset base = Offset(50, 76);
    const List<List<double>> fronds = <List<double>>[
      <double>[-58, 40],
      <double>[-32, 48],
      <double>[-8, 52],
      <double>[16, 50],
      <double>[40, 46],
      <double>[62, 38],
    ];
    final Paint stem = Paint()
      ..color = _dark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round;

    for (final List<double> f in fronds) {
      final double a = f[0] * math.pi / 180;
      final double len = f[1];
      final Offset end = Offset(
        base.dx + math.sin(a) * len,
        base.dy - math.cos(a) * len * 0.85,
      );
      final Offset ctrl = Offset(
        base.dx + math.sin(a) * len * 0.15,
        base.dy - len * 0.95,
      );
      canvas.drawPath(
        Path()
          ..moveTo(base.dx, base.dy)
          ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy),
        stem,
      );
      const int steps = 7;
      for (int i = 0; i < steps; i++) {
        final double t = 0.25 + 0.75 * i / (steps - 1);
        final Offset p = _quadPoint(base, ctrl, end, t);
        final double deg = _quadAngleDeg(base, ctrl, end, t);
        final double size = 10 * (1 - t * 0.55);
        _drawLeaf(canvas, p, deg - 62, size, 7, _mid);
        _drawLeaf(canvas, p, deg + 62, size, 7, _dark);
      }
      _drawLeaf(
        canvas,
        end,
        _quadAngleDeg(base, ctrl, end, 1),
        7,
        6,
        _mid,
      );
    }
    _drawPot(canvas);
  }

  void _cactus(Canvas canvas) {
    final Paint body = Paint()
      ..color = _mid
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 17;
    canvas.drawLine(const Offset(50, 72), const Offset(50, 34), body);

    body.strokeWidth = 8;
    canvas.drawPath(
      Path()
        ..moveTo(44, 62)
        ..lineTo(34, 62)
        ..lineTo(34, 46),
      body,
    );
    canvas.drawPath(
      Path()
        ..moveTo(56, 54)
        ..lineTo(66, 54)
        ..lineTo(66, 40),
      body,
    );

    final Paint ridge = Paint()
      ..color = _light
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.9;
    canvas.drawLine(const Offset(47, 68), const Offset(47, 38), ridge);
    canvas.drawLine(const Offset(53, 68), const Offset(53, 38), ridge);

    canvas.drawCircle(
      const Offset(50, 25),
      3.2,
      Paint()..color = const Color(0xFFC96A4E),
    );
    _drawPot(canvas);
  }

  void _blade(Canvas canvas) {
    const List<List<double>> blades = <List<double>>[
      <double>[-24, 44, 9],
      <double>[-12, 54, 10],
      <double>[0, 58, 11],
      <double>[12, 50, 10],
      <double>[25, 40, 9],
    ];
    for (final List<double> b in blades) {
      final Offset base = Offset(50 + b[0] * 0.35, 76);
      _drawLeaf(canvas, base, b[0], b[1], b[2], _dark);
      _drawLeaf(canvas, base, b[0], b[1] * 0.8, b[2] * 0.5, _mid);
    }
    _drawPot(canvas);
  }

  void _vine(Canvas canvas, Offset a, Offset c, Offset b) {
    canvas.drawPath(
      Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(c.dx, c.dy, b.dx, b.dy),
      Paint()
        ..color = _dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round,
    );
    const List<double> ts = <double>[0.3, 0.55, 0.8, 1.0];
    for (int i = 0; i < ts.length; i++) {
      final Offset p = _quadPoint(a, c, b, ts[i]);
      final double deg = _quadAngleDeg(a, c, b, ts[i]);
      _drawLeaf(canvas, p, deg - 70, 9, 11, i.isEven ? _mid : _light);
      _drawLeaf(canvas, p, deg + 70, 9, 11, i.isEven ? _light : _mid);
    }
  }

  void _trailing(Canvas canvas) {
    const Offset base = Offset(50, 76);
    const List<double> angles = <double>[-40, -14, 14, 40];
    const List<double> lengths = <double>[22, 28, 26, 20];
    for (int i = 0; i < angles.length; i++) {
      _drawLeaf(
        canvas,
        base,
        angles[i],
        lengths[i],
        18,
        i.isEven ? _dark : _mid,
        vein: _vein,
      );
    }
    _drawPot(canvas);
    _vine(canvas, const Offset(38, 74), const Offset(22, 84), const Offset(27, 99));
    _vine(canvas, const Offset(62, 74), const Offset(78, 86), const Offset(72, 99));
  }

  @override
  bool shouldRepaint(covariant _PlantPainter oldDelegate) =>
      oldDelegate.kind != kind;
}

class _SproutPainter extends CustomPainter {
  _SproutPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = math.min(size.width, size.height) / 100;
    if (s <= 0) return;
    final double p = progress.clamp(0.0, 1.0);
    canvas.save();
    canvas.translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2);
    canvas.scale(s);

    const Color tip = Color(0xFF5FE08D);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 88), width: 44, height: 7),
      Paint()..color = const Color(0xFF2E3A33),
    );

    final double top = 86 - 52 * p;
    canvas.drawLine(
      const Offset(50, 86),
      Offset(50, top),
      Paint()
        ..color = tip
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );

    final double q = ((p - 0.35) / 0.65).clamp(0.0, 1.0);
    _drawLeaf(canvas, Offset(50, top + 12), -58, 26 * q, 22 * q, tip);
    _drawLeaf(canvas, Offset(50, top + 12), 58, 26 * q, 22 * q, tip);
    _drawLeaf(canvas, Offset(50, top + 1), 0, 15 * q, 12 * q, tip);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SproutPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

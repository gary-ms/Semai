import 'package:flutter/material.dart';

/// Durasi animasi yang jadi nol kalau pengguna mematikan animasi di sistem.
Duration motionDuration(BuildContext context, int milliseconds) {
  return MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : Duration(milliseconds: milliseconds);
}

/// Muncul dengan memudar dan naik sedikit, sekali saat pertama tampil.
/// [delay] dipakai untuk menyusun urutan antar bagian.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 16,
  });

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  static const int _travelMs = 380;

  late final AnimationController _controller =
      AnimationController(vsync: this);
  Animation<double>? _curve;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_curve != null) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      _curve = _controller;
      return;
    }
    final int total = widget.delay.inMilliseconds + _travelMs;
    _controller.duration = Duration(milliseconds: total);
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        widget.delay.inMilliseconds / total,
        1,
        curve: Curves.easeOutCubic,
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> a = _curve ?? _controller;
    return AnimatedBuilder(
      animation: a,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        return Opacity(
          opacity: a.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - a.value) * widget.offset),
            child: child,
          ),
        );
      },
    );
  }
}

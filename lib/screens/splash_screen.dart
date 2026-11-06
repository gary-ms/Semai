import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../routes.dart';
import '../state/plant_store.dart';
import '../widgets/plant_illustration.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _grow;
  late final Animation<double> _textFade;
  Timer? _timer;
  Timer? _dotsTimer;
  int _dots = 3;

  // Syarat ATS: splash tampil minimal 5 detik.
  static const Duration _splashDuration = Duration(milliseconds: 5500);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
    _grow = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );
    // Timer hidup di State, jadi tetap berjalan walau layar diputar.
    _timer = Timer(_splashDuration, _goNext);
    _dotsTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (!mounted) return;
      setState(() => _dots = _dots % 3 + 1);
    });
  }

  void _goNext() {
    if (!mounted) return;
    final bool loggedIn = context.read<PlantStore>().loggedIn;
    Navigator.of(context)
        .pushReplacementNamed(loggedIn ? Routes.home : Routes.login);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dotsTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.ink,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double markSize =
                math.max(88.0, math.min(220.0, constraints.maxHeight * 0.4));
            return Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AnimatedBuilder(
                      animation: _grow,
                      builder: (BuildContext context, Widget? child) {
                        return SizedBox(
                          width: markSize,
                          height: markSize,
                          child: SproutMark(progress: _grow.value),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _textFade,
                      child: Column(
                        children: <Widget>[
                          Text(
                            'Semai',
                            style: AppText.display(
                              56,
                              color: Palette.paper,
                              height: 1.0,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Catatan rawat untuk tanaman di rumahmu',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Palette.onNightMuted,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Memuat${'.' * _dots}',
                            style: const TextStyle(
                              color: Palette.onNightMuted,
                              fontSize: 13,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

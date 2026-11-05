import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/plant_detail_screen.dart';
import 'screens/plant_form_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/common.dart';

class Routes {
  Routes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String detail = '/detail';
  static const String form = '/form';

  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _fade(settings, const SplashScreen());
      case login:
        return _fade(settings, const LoginScreen());
      case home:
        return _fade(settings, const HomeShell());
      case detail:
        final Object? args = settings.arguments;
        return _page(
          settings,
          PlantDetailScreen(plantId: args is String ? args : ''),
        );
      case form:
        final Object? args = settings.arguments;
        return _page(
          settings,
          PlantFormScreen(plantId: args is String ? args : null),
        );
      default:
        return _page(settings, const _NotFoundScreen());
    }
  }

  static Route<void> _page(RouteSettings settings, Widget page) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (BuildContext context) => page,
    );
  }

  static Route<void> _fade(RouteSettings settings, Widget page) {
    return PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (BuildContext context, Animation<double> animation,
              Animation<double> secondary) =>
          page,
      transitionsBuilder: (BuildContext context, Animation<double> animation,
              Animation<double> secondary, Widget child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: EmptyState(
        title: 'Halaman tidak ditemukan',
        message: 'Alamat halaman yang dibuka tidak dikenali.',
        actionLabel: 'Kembali',
        onAction: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}

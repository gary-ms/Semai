import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'routes.dart';
import 'state/plant_store.dart';

void main() {
  // Semua error yang lolos ditangkap di sini supaya aplikasi tidak force close.
  runZonedGuarded<void>(() {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
    };

    // Kalau satu widget gagal digambar, tampilkan pesan ramah, bukan layar merah.
    ErrorWidget.builder = (FlutterErrorDetails details) => _FriendlyError(
          detail: kDebugMode ? details.exceptionAsString() : null,
        );

    runApp(const SemaiApp());
  }, (Object error, StackTrace stack) {
    debugPrint('Kesalahan tak tertangani: $error');
  });
}

class SemaiApp extends StatelessWidget {
  const SemaiApp({super.key, this.store});

  /// Hanya dipakai untuk test. Di aplikasi nyata store dibuat otomatis.
  final PlantStore? store;

  @override
  Widget build(BuildContext context) {
    final MaterialApp app = MaterialApp(
      title: 'Semai',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('id'),
      supportedLocales: const <Locale>[Locale('id'), Locale('en')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: Routes.splash,
      onGenerateRoute: Routes.generate,
    );

    final PlantStore? injected = store;
    if (injected != null) {
      return ChangeNotifierProvider<PlantStore>.value(
        value: injected,
        child: app,
      );
    }
    return ChangeNotifierProvider<PlantStore>(
      create: (BuildContext context) => PlantStore(),
      child: app,
    );
  }
}

class _FriendlyError extends StatelessWidget {
  const _FriendlyError({this.detail});

  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: Palette.paperDeep,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              detail == null
                  ? 'Bagian ini gagal ditampilkan. Coba kembali ke halaman sebelumnya.'
                  : 'Bagian ini gagal ditampilkan.\n$detail',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Palette.ink,
                fontSize: 14,
                height: 1.4,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

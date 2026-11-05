import 'package:flutter/material.dart';

/// Palet: halaman abu sangat muda, kartu putih, tinta hitam, satu aksen hijau.
/// Permukaan dibedakan lewat selisih tone, bukan garis atau bayangan.
class Palette {
  Palette._();

  static const Color paper = Color(0xFFF2F4F3);
  static const Color paperDeep = Color(0xFFFFFFFF);
  static const Color paperDeeper = Color(0xFFE5E9E7);
  static const Color ink = Color(0xFF111413);
  static const Color inkSoft = Color(0xFF5B6560);
  static const Color leaf = Color(0xFF17874A);
  static const Color lime = Color(0xFF5FE08D);
  static const Color night = Color(0xFF141716);
  static const Color nightRaised = Color(0xFF242927);
  static const Color onNightMuted = Color(0xFFA7B0AB);
  static const Color danger = Color(0xFFC93636);
  static const Color dangerSoft = Color(0xFFF7DADA);
}

class AppText {
  AppText._();

  static const String family = 'Outfit';
  static const List<String> fallback = <String>[
    'Roboto',
    'Helvetica Neue',
    'Arial',
    'sans-serif',
  ];

  static TextStyle display(
    double size, {
    FontWeight weight = FontWeight.w600,
    Color color = Palette.ink,
    double? height,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: family,
      fontFamilyFallback: fallback,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}

class AppTheme {
  AppTheme._();

  /// Dua bentuk: kartu dan foto bersudut besar, tombol dan input bersudut kecil.
  static final BorderRadius radius = BorderRadius.circular(14);
  static final BorderRadius radiusSmall = BorderRadius.circular(10);

  static OutlineInputBorder _border(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: radius,
      borderSide: width == 0
          ? BorderSide.none
          : BorderSide(color: color, width: width),
    );
  }

  static ThemeData light() {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.light,
      primary: Palette.ink,
      onPrimary: Palette.paperDeep,
      secondary: Palette.leaf,
      onSecondary: Palette.paperDeep,
      error: Palette.danger,
      onError: Palette.paperDeep,
      surface: Palette.paper,
      onSurface: Palette.ink,
      surfaceContainerHighest: Palette.paperDeeper,
      outline: Palette.inkSoft,
      outlineVariant: Palette.paperDeeper,
    );

    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppText.family,
    );

    final TextTheme text = base.textTheme
        .apply(bodyColor: Palette.ink, displayColor: Palette.ink)
        .copyWith(
          headlineLarge: AppText.display(34, height: 1.08, letterSpacing: -0.6),
          headlineMedium: AppText.display(28, height: 1.1, letterSpacing: -0.3),
          headlineSmall: AppText.display(24, height: 1.15),
          titleLarge: AppText.display(20, height: 1.2),
          titleMedium: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Palette.ink,
          ),
          bodyLarge: const TextStyle(
            fontSize: 16,
            height: 1.45,
            color: Palette.ink,
          ),
          bodyMedium: const TextStyle(
            fontSize: 14.5,
            height: 1.45,
            color: Palette.ink,
          ),
          labelLarge: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Palette.ink,
          ),
        );

    final RoundedRectangleBorder squareShape =
        RoundedRectangleBorder(borderRadius: radiusSmall);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppText.family,
      fontFamilyFallback: AppText.fallback,
      scaffoldBackgroundColor: Palette.paper,
      canvasColor: Palette.paper,
      textTheme: text,
      dividerColor: Colors.transparent,
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
        space: 0,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Palette.ink,
        selectionHandleColor: Palette.ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Palette.paper,
        foregroundColor: Palette.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: AppText.display(22),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Palette.ink,
          foregroundColor: Palette.paperDeep,
          disabledBackgroundColor: Palette.paperDeeper,
          disabledForegroundColor: Palette.inkSoft,
          minimumSize: const Size(64, 52),
          shape: squareShape,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Palette.leaf,
          minimumSize: const Size(48, 48),
          shape: squareShape,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: Palette.ink,
          minimumSize: const Size(48, 48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Palette.paperDeep,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: _border(Colors.transparent, 0),
        enabledBorder: _border(Colors.transparent, 0),
        disabledBorder: _border(Colors.transparent, 0),
        focusedBorder: _border(Palette.ink, 2),
        errorBorder: _border(Palette.danger, 2),
        focusedErrorBorder: _border(Palette.danger, 2),
        labelStyle: const TextStyle(color: Palette.inkSoft),
        floatingLabelStyle: const TextStyle(
          color: Palette.ink,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(color: Palette.inkSoft),
        helperStyle: const TextStyle(color: Palette.inkSoft),
        errorStyle: const TextStyle(
          color: Palette.danger,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        errorMaxLines: 3,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Palette.lime,
        foregroundColor: Palette.ink,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: squareShape,
        extendedTextStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Palette.ink,
        contentTextStyle: const TextStyle(
          color: Palette.paper,
          fontSize: 14.5,
          height: 1.35,
        ),
        actionTextColor: Palette.lime,
        behavior: SnackBarBehavior.floating,
        shape: squareShape,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Palette.paper,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Palette.ink,
        circularTrackColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? Palette.paperDeep
              : Palette.inkSoft,
        ),
        trackColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? Palette.ink
              : Palette.paperDeeper,
        ),
        trackOutlineColor:
            const WidgetStatePropertyAll<Color?>(Colors.transparent),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) => states.contains(WidgetState.selected)
                ? Palette.ink
                : Palette.paperDeep,
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) => states.contains(WidgetState.selected)
                ? Palette.paperDeep
                : Palette.ink,
          ),
          side: const WidgetStatePropertyAll<BorderSide>(BorderSide.none),
          shape: WidgetStatePropertyAll<OutlinedBorder>(squareShape),
          textStyle: const WidgetStatePropertyAll<TextStyle>(
            TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

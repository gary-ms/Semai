import 'dart:io';

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/plant.dart';
import 'plant_illustration.dart';

/// Foto tanaman. Urutan pilihan: foto yang dipilih pengguna, foto PNG tanpa
/// latar dari assets, lalu ilustrasi sesuai jenisnya kalau keduanya tidak ada
/// atau gagal dimuat.
class PlantPhoto extends StatelessWidget {
  const PlantPhoto({
    super.key,
    required this.plant,
    this.alignment = Alignment.bottomCenter,
    this.padding = EdgeInsets.zero,
    this.inset = 10,
  });

  final Plant plant;
  final Alignment alignment;
  final EdgeInsets padding;

  /// Jarak foto pilihan pengguna dari tepi areanya.
  final double inset;

  @override
  Widget build(BuildContext context) {
    final Widget fallback = Padding(
      padding: padding,
      child: PlantIllustration(kind: plant.kind),
    );

    final String? path = plant.photoPath;
    if (path != null) {
      return Padding(
        padding: EdgeInsets.all(inset),
        child: ClipRRect(
          borderRadius: AppTheme.radiusSmall,
          child: Image.file(
            File(path),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            semanticLabel: 'Foto ${plant.name}',
            errorBuilder: (BuildContext c, Object e, StackTrace? s) => fallback,
          ),
        ),
      );
    }

    final String? asset = plant.photoAsset;
    if (asset == null) return fallback;
    return Padding(
      padding: padding,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        alignment: alignment,
        semanticLabel: 'Foto ${plant.name}',
        errorBuilder: (BuildContext c, Object e, StackTrace? s) {
          return PlantIllustration(kind: plant.kind);
        },
      ),
    );
  }
}

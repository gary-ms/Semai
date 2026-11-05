import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/plant.dart';
import 'common.dart';
import 'plant_photo.dart';

/// Kartu tanaman: foto di atas, nama dan jenis, tiga target perawatan, lalu
/// status siram. Tombol tetes di pojok kanan atas menandai sudah disiram.
class PlantCard extends StatelessWidget {
  const PlantCard({
    super.key,
    required this.plant,
    required this.today,
    required this.onTap,
    required this.onWater,
  });

  final Plant plant;
  final DateTime today;
  final VoidCallback onTap;
  final VoidCallback onWater;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Palette.paperDeep,
      borderRadius: AppTheme.radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: 150,
              width: double.infinity,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: Hero(
                      tag: 'foto-${plant.id}',
                      child: PlantPhoto(
                        plant: plant,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      tooltip: 'Tandai ${plant.name} sudah disiram',
                      onPressed: onWater,
                      style: IconButton.styleFrom(
                        backgroundColor: Palette.paper,
                      ),
                      icon: const Icon(Icons.water_drop_outlined),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          plant.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.display(20, height: 1.2),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          plant.species,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: Palette.inkSoft,
                          ),
                        ),
                      ],
                    ),
                    CareStats(plant: plant),
                    StatusPill(
                      status: plant.statusOn(today),
                      label: plant.statusLabelOn(today),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tiga target perawatan: kelembapan, suhu, cahaya.
class CareStats extends StatelessWidget {
  const CareStats({super.key, required this.plant, this.large = false});

  final Plant plant;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final double size = large ? 20 : 15;
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: <Widget>[
        _item(Icons.water_drop_outlined, '${plant.humidity}%', size),
        _item(Icons.thermostat, '${plant.temperature}°C', size),
        _item(Icons.wb_sunny_outlined, '${plant.lightPercent}%', size),
      ],
    );
  }

  Widget _item(IconData icon, String value, double size) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: size + 2, color: Palette.inkSoft),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(fontSize: size, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models/plant.dart';
import '../routes.dart';
import '../state/plant_store.dart';
import '../utils/dates.dart';
import '../widgets/common.dart';
import '../widgets/plant_photo.dart';

/// Beranda. Satu pertanyaan yang dijawab: tanaman mana yang perlu disiram
/// hari ini. Daftar itu jadi pusat layar, statistik hanya catatan kecil.
/// Semua data dibaca dari PlantStore, jadi aman saat layar diputar.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onOpenCollection});

  final VoidCallback onOpenCollection;

  void _openDetail(BuildContext context, Plant plant) {
    Navigator.of(context).pushNamed(Routes.detail, arguments: plant.id);
  }

  @override
  Widget build(BuildContext context) {
    final PlantStore store = context.watch<PlantStore>();
    final DateTime today = store.today;
    final List<Plant> due = store.duePlants;
    final TextTheme text = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: () => runSync(store, ScaffoldMessenger.of(context)),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    formatDayDate(today),
                    style: const TextStyle(color: Palette.inkSoft),
                  ),
                  const SizedBox(height: 2),
                  Semantics(
                    header: true,
                    child: Text(
                      'Halo, ${store.userName}',
                      style: text.headlineMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (store.plantCount == 0)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                title: 'Belum ada tanaman',
                message:
                    'Tambahkan tanaman pertamamu, lalu jadwal siramnya muncul di sini.',
                actionLabel: 'Tambah tanaman',
                onAction: () => Navigator.of(context).pushNamed(Routes.form),
              ),
            )
          else ...<Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        due.isEmpty
                            ? 'Semua tanaman sudah disiram'
                            : '${due.length} tanaman perlu disiram',
                        style: AppText.display(24, height: 1.15),
                      ),
                    ),
                    if (due.length > 1) ...<Widget>[
                      const SizedBox(width: 12),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(64, 48),
                        ),
                        onPressed: () => waterAllWithUndo(
                          store,
                          ScaffoldMessenger.of(context),
                          due,
                        ),
                        child: const Text('Siram semua'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (due.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Text(
                    _nextUp(store, today),
                    style: const TextStyle(color: Palette.inkSoft, height: 1.4),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: due.length,
                  separatorBuilder: (BuildContext c, int i) =>
                      const SizedBox(height: 8),
                  itemBuilder: (BuildContext c, int i) => _DueRow(
                    key: ValueKey<String>('perlu-${due[i].id}'),
                    plant: due[i],
                    today: today,
                    onTap: () => _openDetail(context, due[i]),
                    onWater: () => waterWithUndo(
                      store,
                      ScaffoldMessenger.of(context),
                      due[i],
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _SummaryStrip(
                  plants: store.plantCount,
                  due: due.length,
                  journal: store.journalCount,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 8, 0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Terbaru ditambahkan',
                        style: AppText.display(20, height: 1.2),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: onOpenCollection,
                      child: const Text('Semua tanaman'),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: LayoutBuilder(
                  builder: (BuildContext c, BoxConstraints box) {
                    final int columns = box.maxWidth >= 560 ? 3 : 2;
                    const double gap = 12;
                    final double width =
                        (box.maxWidth - gap * (columns - 1)) / columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: <Widget>[
                        for (final Plant p in store.latestPlants(columns))
                          SizedBox(
                            width: width,
                            child: _LatestTile(
                              key: ValueKey<String>('baru-${p.id}'),
                              plant: p,
                              onTap: () => _openDetail(context, p),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _nextUp(PlantStore store, DateTime today) {
    final List<Plant> list = store.scheduled;
    if (list.isEmpty) return '';
    final Plant next = list.first;
    return 'Berikutnya: ${next.name}, ${next.statusLabelOn(today).toLowerCase()}.';
  }
}

class _DueRow extends StatelessWidget {
  const _DueRow({
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 56,
                  height: 56,
                  child: ClipRRect(
                    borderRadius: AppTheme.radiusSmall,
                    child: ColoredBox(
                      color: Palette.paper,
                      child: PlantPhoto(
                        plant: plant,
                        inset: 0,
                        padding: const EdgeInsets.all(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        plant.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.display(18, height: 1.2),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plant.place.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Palette.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: StatusPill(
                          status: plant.statusOn(today),
                          label: plant.statusLabelOn(today),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Tandai ${plant.name} sudah disiram',
                  onPressed: onWater,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    backgroundColor: Palette.paper,
                  ),
                  icon: const Icon(Icons.water_drop_outlined),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tiga angka dalam satu permukaan, sengaja kecil agar tidak menyaingi
/// daftar tanaman yang perlu disiram.
class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.plants,
    required this.due,
    required this.journal,
  });

  final int plants;
  final int due;
  final int journal;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Palette.paperDeep,
      borderRadius: AppTheme.radius,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: _Figure(value: plants, label: 'Tanaman')),
            Expanded(child: _Figure(value: due, label: 'Perlu disiram')),
            Expanded(child: _Figure(value: journal, label: 'Catatan jurnal')),
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('$value', style: AppText.display(26, height: 1.1)),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              height: 1.25,
              color: Palette.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestTile extends StatelessWidget {
  const _LatestTile({super.key, required this.plant, required this.onTap});

  final Plant plant;
  final VoidCallback onTap;

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
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: 112,
              width: double.infinity,
              child: PlantPhoto(
                plant: plant,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    plant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.display(17, height: 1.2),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ditambahkan ${formatDate(plant.acquired)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Palette.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

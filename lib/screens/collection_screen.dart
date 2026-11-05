import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models/plant.dart';
import '../routes.dart';
import '../state/plant_store.dart';
import '../utils/dates.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/plant_card.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    // Teks pencarian diambil dari store, jadi tidak hilang saat kembali
    // dari halaman detail atau saat layar diputar.
    _search = TextEditingController(text: context.read<PlantStore>().query);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _summary(PlantStore store) {
    final int due = store.dueCount;
    final String dueText =
        due == 0 ? 'Belum ada yang perlu disiram.' : '$due perlu disiram.';
    return '${store.plantCount} tanaman. $dueText';
  }

  String _syncText(PlantStore store) {
    if (store.syncing) return 'Menyinkronkan...';
    final DateTime? last = store.lastSync;
    if (last == null) return 'Belum pernah disinkronkan';
    return 'Disinkronkan pukul ${formatTime(last)}';
  }

  @override
  Widget build(BuildContext context) {
    final PlantStore store = context.watch<PlantStore>();
    final List<Plant> plants = store.visiblePlants;
    final DateTime today = store.today;
    final TextTheme text = Theme.of(context).textTheme;

    final double scale = textScaleOf(context);
    final double extra = math.max(0.0, math.min(0.6, scale - 1));
    final double extent = 318.0 + extra * 190;

    return RefreshIndicator(
      onRefresh: () => runSync(store, ScaffoldMessenger.of(context)),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Semua tanaman', style: text.headlineMedium),
                        const SizedBox(height: 4),
                        Text(
                          _summary(store),
                          style: const TextStyle(color: Palette.inkSoft),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _syncText(store),
                          style: const TextStyle(
                            color: Palette.inkSoft,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sinkronkan data',
                    onPressed: store.syncing
                        ? null
                        : () => runSync(store, ScaffoldMessenger.of(context)),
                    icon: store.syncing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Icon(Icons.sync),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onChanged: (String value) =>
                    context.read<PlantStore>().setQuery(value),
                decoration: InputDecoration(
                  hintText: 'Cari nama atau jenis tanaman',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus pencarian',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _search.clear();
                            store.setQuery('');
                          },
                        ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: <Widget>[
                  appChoiceChip(
                    label: 'Semua lokasi',
                    selected: store.placeFilter == null,
                    onSelected: (_) => store.setPlaceFilter(null),
                  ),
                  for (final Place p in Place.values) ...<Widget>[
                    const SizedBox(width: 8),
                    appChoiceChip(
                      label: p.label,
                      selected: store.placeFilter == p,
                      onSelected: (_) => store.setPlaceFilter(p),
                    ),
                  ],
                  const SizedBox(width: 8),
                  appFilterChip(
                    label: 'Perlu disiram',
                    selected: store.onlyDue,
                    onSelected: (bool v) => store.setOnlyDue(v),
                  ),
                ],
              ),
            ),
          ),
          if (plants.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: store.plantCount == 0
                  ? EmptyState(
                      title: 'Belum ada tanaman',
                      message:
                          'Tambahkan tanaman pertamamu untuk mulai mencatat jadwal siram.',
                      actionLabel: 'Tambah tanaman',
                      onAction: () =>
                          Navigator.of(context).pushNamed(Routes.form),
                    )
                  : EmptyState(
                      title: 'Tidak ada tanaman yang cocok',
                      message: 'Coba kata kunci lain atau hapus filter.',
                      kind: PlantKind.rosette,
                      actionLabel: 'Hapus filter',
                      onAction: () {
                        _search.clear();
                        store.clearFilters();
                      },
                    ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 340,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: extent,
                ),
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int i) {
                    final Plant p = plants[i];
                    final Widget card = PlantCard(
                      key: ValueKey<String>(p.id),
                      plant: p,
                      today: today,
                      onTap: () => Navigator.of(context)
                          .pushNamed(Routes.detail, arguments: p.id),
                      onWater: () => waterWithUndo(
                        store,
                        ScaffoldMessenger.of(context),
                        p,
                      ),
                    );
                    if (i >= 8) return card;
                    return FadeSlideIn(
                      key: ValueKey<String>('masuk-${p.id}'),
                      delay: Duration(milliseconds: i * 60),
                      child: card,
                    );
                  },
                  childCount: plants.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

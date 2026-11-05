import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models/plant.dart';
import '../routes.dart';
import '../state/plant_store.dart';
import '../utils/dates.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/plant_photo.dart';
import 'journal_sheet.dart';

class PlantDetailScreen extends StatefulWidget {
  const PlantDetailScreen({super.key, required this.plantId});

  final String plantId;

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  /// Salinan terakhir, supaya layar tidak berkedip "tidak ditemukan" selama
  /// animasi keluar setelah tanaman dihapus.
  Plant? _cached;

  Future<void> _confirmDelete(Plant plant) async {
    final bool ok = await confirmDialog(
      context,
      title: 'Hapus ${plant.name}?',
      message: 'Tanaman beserta jurnal pertumbuhannya akan dihapus dari koleksi.',
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!ok || !mounted) return;

    final PlantStore store = context.read<PlantStore>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final int index = store.indexOf(plant.id);

    navigator.pop();
    final Plant? removed = store.remove(plant.id);
    if (removed == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${removed.name} dihapus.'),
        action: SnackBarAction(
          label: 'Urungkan',
          onPressed: () => store.insertAt(index, removed),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final PlantStore store = context.watch<PlantStore>();
    final Plant? fresh = store.byId(widget.plantId);
    if (fresh != null) _cached = fresh;
    final Plant? plant = fresh ?? _cached;

    if (plant == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          title: 'Tanaman tidak ditemukan',
          message: 'Mungkin tanaman ini sudah dihapus dari koleksi.',
          kind: PlantKind.rosette,
          actionLabel: 'Kembali',
          onAction: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    final DateTime today = store.today;

    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            tooltip: 'Ubah tanaman',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context)
                .pushNamed(Routes.form, arguments: plant.id),
          ),
          IconButton(
            tooltip: 'Hapus tanaman',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(plant),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool wide = constraints.maxWidth >= 720;
            final Widget header = FadeSlideIn(child: _Header(plant: plant));
            final Widget water = FadeSlideIn(
              delay: const Duration(milliseconds: 90),
              child: _WaterPanel(plant: plant, today: today),
            );
            final List<Widget> details = <Widget>[
              _Facts(plant: plant),
              if (plant.notes.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 24),
                Text('Catatan', style: AppText.display(20)),
                const SizedBox(height: 8),
                Text(plant.notes, style: const TextStyle(height: 1.45)),
              ],
              const SizedBox(height: 28),
              _JournalSection(plant: plant),
            ];

            final Widget detailsBlock = FadeSlideIn(
              delay: const Duration(milliseconds: 180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: details,
              ),
            );

            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 8, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          header,
                          const SizedBox(height: 16),
                          water,
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(8, 0, 16, 24),
                      child: detailsBlock,
                    ),
                  ),
                ],
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  header,
                  const SizedBox(height: 16),
                  water,
                  const SizedBox(height: 24),
                  detailsBlock,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.plant});

  final Plant plant;

  Widget _stat(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 22, color: Palette.inkSoft),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(value, style: AppText.display(22, height: 1.1)),
              Text(
                label,
                style: const TextStyle(color: Palette.inkSoft, fontSize: 12.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Palette.paperDeep,
        borderRadius: AppTheme.radius,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(plant.name, style: text.headlineLarge),
                  const SizedBox(height: 4),
                  Text(
                    plant.species,
                    style: const TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: Palette.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _stat(Icons.water_drop_outlined, 'Kelembapan',
                      '${plant.humidity}%'),
                  _stat(Icons.thermostat, 'Suhu', '${plant.temperature}\u00B0C'),
                  _stat(Icons.wb_sunny_outlined, 'Cahaya',
                      '${plant.lightPercent}%'),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: SizedBox(
                height: 280,
                child: Hero(
                  tag: 'foto-${plant.id}',
                  child: PlantPhoto(
                    plant: plant,
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterPanel extends StatelessWidget {
  const _WaterPanel({required this.plant, required this.today});

  final Plant plant;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final DateTime from = addDays(today, -3);
    final DateTime to = addDays(today, 3);
    final Set<DateTime> planned = plant.plannedBetween(from, to).toSet();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Palette.paperDeep,
        borderRadius: AppTheme.radius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Jadwal siram', style: AppText.display(20)),
          const SizedBox(height: 2),
          Text(
            'Hari ini, ${formatDate(today)}',
            style: const TextStyle(color: Palette.inkSoft, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              for (int i = -3; i <= 3; i++)
                Expanded(
                  child: _DayChip(
                    day: addDays(today, i),
                    isToday: i == 0,
                    watered: plant.wasWateredOn(addDays(today, i)),
                    planned: planned.contains(addDays(today, i)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              StatusPill(
                status: plant.statusOn(today),
                label: plant.statusLabelOn(today),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Terakhir disiram ${formatDate(plant.lastWatered)}. Diulang setiap ${plant.intervalDays} hari, berikutnya ${formatDayDate(plant.nextWatering)}.',
            style: const TextStyle(color: Palette.inkSoft, height: 1.4),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => waterWithUndo(
              context.read<PlantStore>(),
              ScaffoldMessenger.of(context),
              plant,
            ),
            icon: const Icon(Icons.water_drop_outlined),
            label: const Text('Siram sekarang'),
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.isToday,
    required this.watered,
    required this.planned,
  });

  final DateTime day;
  final bool isToday;
  final bool watered;
  final bool planned;

  @override
  Widget build(BuildContext context) {
    final Color bg = isToday
        ? Palette.ink
        : watered
            ? Palette.lime
            : planned
                ? Palette.paperDeeper
                : Colors.transparent;
    final Color fg = isToday ? Palette.paperDeep : Palette.ink;
    final String state = watered
        ? 'sudah disiram'
        : planned
            ? 'dijadwalkan siram'
            : 'tidak ada jadwal';

    return Semantics(
      label: '${formatDayDate(day)}, $state',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: motionDuration(context, 200),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: bg, borderRadius: AppTheme.radiusSmall),
        child: Column(
          children: <Widget>[
            Text(
              shortWeekday(day),
              style: TextStyle(fontSize: 11.5, color: fg),
            ),
            const SizedBox(height: 4),
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 16,
              child: watered || planned
                  ? Icon(
                      watered ? Icons.check : Icons.water_drop_outlined,
                      size: 14,
                      color: fg,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.plant});

  final Plant plant;

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Palette.inkSoft)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: Palette.paperDeep,
        borderRadius: AppTheme.radius,
      ),
      child: Column(
        children: <Widget>[
          _row('Lokasi', plant.place.label),
          _row('Jenis', plant.kind.label),
          _row('Dirawat sejak', formatDate(plant.acquired)),
        ],
      ),
    );
  }
}

class _JournalSection extends StatelessWidget {
  const _JournalSection({required this.plant});

  final Plant plant;

  @override
  Widget build(BuildContext context) {
    final List<JournalEntry> entries = plant.journalNewestFirst;
    final List<JournalEntry> series = plant.heightSeries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text('Jurnal pertumbuhan', style: AppText.display(20))),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Palette.lime,
                foregroundColor: Palette.ink,
                minimumSize: const Size(64, 48),
              ),
              onPressed: () => showJournalSheet(context, plant.id),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Catatan'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (series.length >= 2) ...<Widget>[
          _GrowthSummary(series: series),
          const SizedBox(height: 12),
        ],
        if (entries.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Palette.paperDeep,
              borderRadius: AppTheme.radius,
            ),
            child: const Text(
              'Belum ada catatan. Tulis perkembangan pertama, misalnya tinggi tanaman atau daun baru yang keluar.',
              style: TextStyle(color: Palette.inkSoft, height: 1.4),
            ),
          )
        else
          for (final JournalEntry e in entries) ...<Widget>[
            _JournalTile(plantId: plant.id, entry: e),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _GrowthSummary extends StatelessWidget {
  const _GrowthSummary({required this.series});

  final List<JournalEntry> series;

  String _cm(double v) {
    final String s = v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);
    return '${s.replaceAll('.', ',')} cm';
  }

  @override
  Widget build(BuildContext context) {
    final double first = series.first.heightCm!;
    final double last = series.last.heightCm!;
    final double diff = last - first;
    final String sign = diff >= 0 ? '+' : '-';
    final List<double> values =
        series.map((JournalEntry e) => e.heightCm!).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Palette.paperDeep,
        borderRadius: AppTheme.radius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${_cm(first)} menjadi ${_cm(last)}',
            style: AppText.display(20, height: 1.2),
          ),
          const SizedBox(height: 2),
          Text(
            '$sign${_cm(diff.abs())} sejak ${formatDate(series.first.date)}',
            style: const TextStyle(color: Palette.inkSoft),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            width: double.infinity,
            child: CustomPaint(painter: _GrowthPainter(values)),
          ),
        ],
      ),
    );
  }
}

class _GrowthPainter extends CustomPainter {
  _GrowthPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    const double pad = 8;
    double minV = values.first;
    double maxV = values.first;
    for (final double v in values) {
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
    final double range = (maxV - minV) == 0 ? 1 : (maxV - minV);
    final List<Offset> points = <Offset>[
      for (int i = 0; i < values.length; i++)
        Offset(
          pad + i * (size.width - 2 * pad) / (values.length - 1),
          size.height - pad - (values[i] - minV) / range * (size.height - 2 * pad),
        ),
    ];

    final Path path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final Offset p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Palette.leaf
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    for (final Offset p in points) {
      canvas.drawCircle(p, 4.5, Paint()..color = Palette.ink);
    }
  }

  @override
  bool shouldRepaint(covariant _GrowthPainter oldDelegate) =>
      !listEquals(oldDelegate.values, values);
}

class _JournalTile extends StatelessWidget {
  const _JournalTile({required this.plantId, required this.entry});

  final String plantId;
  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final double? h = entry.heightCm;
    final String height = h == null
        ? ''
        : '${h.toStringAsFixed(h == h.roundToDouble() ? 0 : 1).replaceAll('.', ',')} cm';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      decoration: BoxDecoration(
        color: Palette.paperDeep,
        borderRadius: AppTheme.radius,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 44,
            child: Column(
              children: <Widget>[
                Text('${entry.date.day}', style: AppText.display(24, height: 1.0)),
                const SizedBox(height: 2),
                Text(
                  shortMonth(entry.date),
                  style: const TextStyle(color: Palette.inkSoft, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (height.isNotEmpty)
                  Text(
                    'Tinggi $height',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                Text(entry.note, style: const TextStyle(height: 1.4)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Hapus catatan',
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              final PlantStore store = context.read<PlantStore>();
              final ScaffoldMessengerState messenger =
                  ScaffoldMessenger.of(context);
              store.removeJournal(plantId, entry.id);
              messenger.hideCurrentSnackBar();
              messenger.showSnackBar(
                SnackBar(
                  content: const Text('Catatan dihapus.'),
                  action: SnackBarAction(
                    label: 'Urungkan',
                    onPressed: () => store.addJournal(plantId, entry),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

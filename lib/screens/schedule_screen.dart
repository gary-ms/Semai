import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models/plant.dart';
import '../routes.dart';
import '../state/plant_store.dart';
import '../utils/dates.dart';
import '../widgets/motion.dart';
import '../widgets/plant_photo.dart';

/// Kalender siram bertema gelap. Bulan dan tanggal terpilih disimpan di State,
/// jadi tetap ada saat layar diputar atau berpindah tab.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime? _month;
  DateTime? _selected;

  void _shiftMonth(int delta) {
    final DateTime m = _month!;
    setState(() => _month = DateTime(m.year, m.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final PlantStore store = context.watch<PlantStore>();
    final DateTime today = store.today;
    _month ??= DateTime(today.year, today.month);
    _selected ??= today;
    final DateTime month = _month!;
    final DateTime selected = _selected!;
    final List<Plant> plants = store.scheduled;

    return ColoredBox(
      color: Palette.night,
      child: SafeArea(
        left: false,
        bottom: false,
        child: plants.isEmpty
            ? const _DarkEmpty()
            : LayoutBuilder(
                builder: (BuildContext context, BoxConstraints c) {
                  final Widget calendar = _Calendar(
                    month: month,
                    selected: selected,
                    today: today,
                    plants: plants,
                    onPrev: () => _shiftMonth(-1),
                    onNext: () => _shiftMonth(1),
                    onSelect: (DateTime d) => setState(() => _selected = d),
                  );
                  final Widget panel = _DayPanel(
                    day: selected,
                    today: today,
                    plants: plants,
                  );
                  if (c.maxWidth >= 640) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 20, 10, 24),
                            child: calendar,
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(10, 20, 20, 24),
                            child: panel,
                          ),
                        ),
                      ],
                    );
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        calendar,
                        const SizedBox(height: 20),
                        panel,
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _DarkEmpty extends StatelessWidget {
  const _DarkEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Belum ada jadwal. Tambahkan tanaman di tab Tanaman, jadwal siramnya muncul di sini.',
          textAlign: TextAlign.center,
          style: AppText.display(
            18,
            weight: FontWeight.w500,
            color: Palette.paperDeep,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.month,
    required this.selected,
    required this.today,
    required this.plants,
    required this.onPrev,
    required this.onNext,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selected;
  final DateTime today;
  final List<Plant> plants;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final DateTime first = DateTime(month.year, month.month);
    final int total = daysInMonth(first);
    final DateTime last = DateTime(month.year, month.month, total);

    final Set<DateTime> watered = <DateTime>{};
    final Set<DateTime> planned = <DateTime>{};
    for (final Plant p in plants) {
      for (final DateTime w in p.wateredOn) {
        final DateTime d = dateOnly(w);
        if (!d.isBefore(first) && !d.isAfter(last)) watered.add(d);
      }
      planned.addAll(p.plannedBetween(first, last));
    }

    final int offset = first.weekday - 1;
    final int cells = ((offset + total + 6) ~/ 7) * 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Jadwal',
          style: AppText.display(34, color: Palette.paperDeep, height: 1.1),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                monthYear(first),
                style: AppText.display(
                  18,
                  weight: FontWeight.w500,
                  color: Palette.onNightMuted,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Bulan sebelumnya',
              color: Palette.paperDeep,
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              tooltip: 'Bulan berikutnya',
              color: Palette.paperDeep,
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            for (int i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    shortWeekday(DateTime(2024, 1, 1 + i)),
                    style: const TextStyle(
                      color: Palette.onNightMuted,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (int row = 0; row < cells ~/ 7; row++)
          Row(
            children: <Widget>[
              for (int col = 0; col < 7; col++)
                Expanded(
                  child: _cell(row * 7 + col - offset + 1, total, first,
                      watered, planned),
                ),
            ],
          ),
        const SizedBox(height: 16),
        const Row(
          children: <Widget>[
            _LegendDot(color: Palette.lime, label: 'Sudah disiram'),
            SizedBox(width: 20),
            _LegendDot(color: Palette.nightRaised, label: 'Dijadwalkan'),
          ],
        ),
      ],
    );
  }

  Widget _cell(int dayNumber, int total, DateTime first, Set<DateTime> watered,
      Set<DateTime> planned) {
    if (dayNumber < 1 || dayNumber > total) {
      return const SizedBox(height: 48);
    }
    final DateTime d = DateTime(first.year, first.month, dayNumber);
    final bool isSelected = d == selected;
    final bool isWatered = watered.contains(d);
    final bool isPlanned = planned.contains(d);

    Color bg = Colors.transparent;
    Color fg = Palette.paperDeep;
    if (isWatered) {
      bg = Palette.lime;
      fg = Palette.ink;
    } else if (isPlanned) {
      bg = Palette.nightRaised;
    }
    if (isSelected) {
      bg = Palette.paperDeep;
      fg = Palette.ink;
    }
    final String state = isWatered
        ? 'ada yang sudah disiram'
        : isPlanned
            ? 'ada jadwal siram'
            : 'tidak ada jadwal';

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${formatDayDate(d)}, $state',
      excludeSemantics: true,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => onSelect(d),
        child: SizedBox(
          height: 48,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Text(
                '$dayNumber',
                style: TextStyle(
                  color: fg,
                  fontSize: 15,
                  fontWeight: d == today || isSelected
                      ? FontWeight.w800
                      : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Palette.onNightMuted, fontSize: 13),
        ),
      ],
    );
  }
}

class _DayPanel extends StatelessWidget {
  const _DayPanel({
    required this.day,
    required this.today,
    required this.plants,
  });

  final DateTime day;
  final DateTime today;
  final List<Plant> plants;

  @override
  Widget build(BuildContext context) {
    final List<Plant> rows = plants.where((Plant p) {
      final bool overdueToday = day == today && p.daysUntilWatering(today) < 0;
      return p.wasWateredOn(day) ||
          p.plannedBetween(day, day).isNotEmpty ||
          overdueToday;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          formatDayDate(day),
          style: AppText.display(22, color: Palette.paperDeep),
        ),
        const SizedBox(height: 12),
        if (rows.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Palette.nightRaised,
              borderRadius: AppTheme.radius,
            ),
            child: const Text(
              'Tidak ada jadwal siram di tanggal ini. Pilih tanggal lain di kalender.',
              style: TextStyle(color: Palette.onNightMuted, height: 1.4),
            ),
          )
        else
          for (final Plant p in rows) ...<Widget>[
            _DayRow(plant: p, day: day, today: today),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.plant, required this.day, required this.today});

  final Plant plant;
  final DateTime day;
  final DateTime today;

  void _water(BuildContext context) {
    final PlantStore store = context.read<PlantStore>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final DateTime? previous = store.water(plant.id, on: day);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${plant.name} ditandai disiram pada ${formatDate(day)}.'),
        action: previous == null
            ? null
            : SnackBarAction(
                label: 'Urungkan',
                onPressed: () => store.unwater(plant.id, previous, on: day),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool done = plant.wasWateredOn(day);
    final bool canWater = !done && !day.isAfter(today);
    final bool late = !done && day == today && plant.daysUntilWatering(today) < 0;
    final String status = done
        ? 'Sudah disiram'
        : late
            ? plant.statusLabelOn(today)
            : day.isAfter(today)
                ? 'Dijadwalkan'
                : 'Belum disiram';

    return Material(
      color: Palette.nightRaised,
      borderRadius: AppTheme.radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context)
            .pushNamed(Routes.detail, arguments: plant.id),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Palette.paperDeep,
                  borderRadius: AppTheme.radiusSmall,
                ),
                child: PlantPhoto(
                  plant: plant,
                  inset: 0,
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
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
                      style: AppText.display(17,
                          color: Palette.paperDeep, height: 1.2),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status,
                      style: TextStyle(
                        color: done ? Palette.lime : Palette.onNightMuted,
                        fontSize: 13.5,
                        fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (done)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.check_circle, color: Palette.lime),
                )
              else if (canWater)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Palette.lime,
                    foregroundColor: Palette.ink,
                    minimumSize: const Size(64, 48),
                  ),
                  onPressed: () => _water(context),
                  child: const Text('Siram'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import '../utils/dates.dart';

/// Jenis ilustrasi cadangan, dipakai saat foto belum ada atau gagal dimuat.
enum PlantKind { leafy, rosette, fern, cactus, blade, trailing }

extension PlantKindLabel on PlantKind {
  String get label {
    switch (this) {
      case PlantKind.leafy:
        return 'Berdaun lebar';
      case PlantKind.rosette:
        return 'Sukulen roset';
      case PlantKind.fern:
        return 'Pakis';
      case PlantKind.cactus:
        return 'Kaktus';
      case PlantKind.blade:
        return 'Daun pedang';
      case PlantKind.trailing:
        return 'Menjuntai';
    }
  }
}

enum Place { indoor, balcony, terrace }

extension PlaceLabel on Place {
  String get label {
    switch (this) {
      case Place.indoor:
        return 'Dalam ruangan';
      case Place.balcony:
        return 'Balkon';
      case Place.terrace:
        return 'Teras';
    }
  }
}

enum WaterStatus { overdue, today, soon, ok }

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.date,
    required this.note,
    this.heightCm,
  });

  final String id;
  final DateTime date;
  final String note;
  final double? heightCm;
}

class Plant {
  const Plant({
    required this.id,
    required this.name,
    required this.species,
    required this.kind,
    required this.place,
    required this.humidity,
    required this.temperature,
    required this.lightPercent,
    required this.intervalDays,
    required this.lastWatered,
    required this.acquired,
    this.notes = '',
    this.photoAsset,
    this.photoPath,
    this.wateredOn = const <DateTime>[],
    this.journal = const <JournalEntry>[],
  });

  final String id;
  final String name;
  final String species;
  final PlantKind kind;
  final Place place;
  final int humidity;
  final int temperature;
  final int lightPercent;
  final int intervalDays;
  final DateTime lastWatered;
  final DateTime acquired;
  final String notes;
  final String? photoAsset;
  final String? photoPath;
  final List<DateTime> wateredOn;
  final List<JournalEntry> journal;

  Plant copyWith({
    String? name,
    String? species,
    PlantKind? kind,
    Place? place,
    int? humidity,
    int? temperature,
    int? lightPercent,
    int? intervalDays,
    DateTime? lastWatered,
    DateTime? acquired,
    String? notes,
    List<DateTime>? wateredOn,
    String? photoPath,
    bool clearPhoto = false,
    List<JournalEntry>? journal,
  }) {
    return Plant(
      id: id,
      name: name ?? this.name,
      species: species ?? this.species,
      kind: kind ?? this.kind,
      place: place ?? this.place,
      humidity: humidity ?? this.humidity,
      temperature: temperature ?? this.temperature,
      lightPercent: lightPercent ?? this.lightPercent,
      intervalDays: intervalDays ?? this.intervalDays,
      lastWatered: lastWatered ?? this.lastWatered,
      acquired: acquired ?? this.acquired,
      notes: notes ?? this.notes,
      photoAsset: photoAsset,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      wateredOn: wateredOn ?? this.wateredOn,
      journal: journal ?? this.journal,
    );
  }

  /// Tanggal siram berikutnya = terakhir disiram + interval.
  DateTime get nextWatering =>
      addDays(dateOnly(lastWatered), intervalDays);

  /// Berapa hari lagi sampai jadwal siram. Negatif berarti terlambat.
  int daysUntilWatering(DateTime today) => daysBetween(today, nextWatering);

  /// Tanggal siram terjadwal dalam rentang [from, to], mulai dari jadwal
  /// berikutnya lalu berulang menurut interval.
  List<DateTime> plannedBetween(DateTime from, DateTime to) {
    final List<DateTime> out = <DateTime>[];
    DateTime d = nextWatering;
    int guard = 0;
    while (!d.isAfter(to) && guard++ < 400) {
      if (!d.isBefore(from)) out.add(d);
      d = addDays(d, intervalDays);
    }
    return out;
  }

  bool wasWateredOn(DateTime day) {
    final DateTime x = dateOnly(day);
    return wateredOn.any((DateTime w) => dateOnly(w) == x);
  }

  WaterStatus statusOn(DateTime today) {
    final int d = daysUntilWatering(today);
    if (d < 0) return WaterStatus.overdue;
    if (d == 0) return WaterStatus.today;
    if (d == 1) return WaterStatus.soon;
    return WaterStatus.ok;
  }

  String statusLabelOn(DateTime today) {
    final int d = daysUntilWatering(today);
    if (d < 0) return 'Terlambat ${-d} hari';
    if (d == 0) return 'Siram hari ini';
    if (d == 1) return 'Besok';
    return '$d hari lagi';
  }

  List<JournalEntry> get journalNewestFirst {
    final List<JournalEntry> list = List<JournalEntry>.of(journal);
    list.sort((JournalEntry a, JournalEntry b) => b.date.compareTo(a.date));
    return list;
  }

  /// Entri jurnal yang punya data tinggi, dari yang paling lama.
  List<JournalEntry> get heightSeries {
    final List<JournalEntry> list = journal
        .where((JournalEntry e) => e.heightCm != null)
        .toList();
    list.sort((JournalEntry a, JournalEntry b) => a.date.compareTo(b.date));
    return list;
  }
}

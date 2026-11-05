import '../models/plant.dart';
import '../utils/dates.dart';

/// Data contoh. Tanggalnya dihitung relatif terhadap hari ini supaya status
/// siramnya selalu bervariasi (terlambat, hari ini, besok, aman) saat didemokan.
List<Plant> buildDummyPlants(DateTime now) {
  final DateTime today = dateOnly(now);
  DateTime ago(int days) => addDays(today, -days);

  List<DateTime> history(int lastAgo, int interval, int count) {
    return <DateTime>[
      for (int i = 0; i < count; i++) ago(lastAgo + i * interval),
    ];
  }

  return <Plant>[
    Plant(
      id: 'p1',
      name: 'Monstera',
      species: 'Monstera deliciosa',
      kind: PlantKind.leafy,
      place: Place.indoor,
      humidity: 60,
      temperature: 24,
      lightPercent: 60,
      intervalDays: 7,
      lastWatered: ago(5),
      acquired: ago(210),
      photoAsset: 'assets/plants/monstera.png',
      wateredOn: history(5, 7, 4),
      notes: 'Daun baru keluar di sisi jendela. Tiang rambat sudah dipasang.',
      journal: <JournalEntry>[
        JournalEntry(
          id: 'j1',
          date: ago(62),
          heightCm: 28,
          note: 'Baru dipindah ke pot terakota yang lebih besar.',
        ),
        JournalEntry(
          id: 'j2',
          date: ago(33),
          heightCm: 34,
          note: 'Dua daun baru membuka, belum berlubang.',
        ),
        JournalEntry(
          id: 'j3',
          date: ago(6),
          heightCm: 41,
          note: 'Mulai merambat ke tiang. Ujung satu daun agak cokelat.',
        ),
      ],
    ),
    Plant(
      id: 'p2',
      name: 'Sukulen',
      species: 'Echeveria elegans',
      kind: PlantKind.rosette,
      place: Place.indoor,
      humidity: 30,
      temperature: 22,
      lightPercent: 85,
      intervalDays: 12,
      lastWatered: ago(13),
      acquired: ago(120),
      photoAsset: 'assets/plants/sukulen.png',
      wateredOn: history(13, 12, 3),
      notes: 'Siram sedikit, tanahnya harus kering dulu.',
    ),
    Plant(
      id: 'p3',
      name: 'Pakis',
      species: 'Nephrolepis exaltata',
      kind: PlantKind.fern,
      place: Place.terrace,
      humidity: 80,
      temperature: 23,
      lightPercent: 35,
      intervalDays: 3,
      lastWatered: ago(3),
      acquired: ago(300),
      photoAsset: 'assets/plants/pakis.png',
      wateredOn: history(3, 3, 8),
      notes: 'Suka lembap. Semprot daunnya saat siang panas.',
    ),
    Plant(
      id: 'p4',
      name: 'Kaktus',
      species: 'Mammillaria elongata',
      kind: PlantKind.cactus,
      place: Place.balcony,
      humidity: 25,
      temperature: 26,
      lightPercent: 90,
      intervalDays: 14,
      lastWatered: ago(4),
      acquired: ago(90),
      photoAsset: 'assets/plants/kaktus.png',
      wateredOn: history(4, 14, 3),
    ),
    Plant(
      id: 'p5',
      name: 'Lidah Mertua',
      species: 'Dracaena trifasciata',
      kind: PlantKind.blade,
      place: Place.indoor,
      humidity: 40,
      temperature: 24,
      lightPercent: 30,
      intervalDays: 14,
      lastWatered: ago(10),
      acquired: ago(400),
      photoAsset: 'assets/plants/lidah-mertua.png',
      wateredOn: history(10, 14, 3),
      journal: <JournalEntry>[
        JournalEntry(
          id: 'j4',
          date: ago(80),
          heightCm: 52,
          note: 'Dipindah ke sudut ruang tamu.',
        ),
        JournalEntry(
          id: 'j5',
          date: ago(20),
          heightCm: 55,
          note: 'Tunas anakan muncul di sisi kiri pot.',
        ),
      ],
    ),
    Plant(
      id: 'p6',
      name: 'Sirih Gading',
      species: 'Epipremnum aureum',
      kind: PlantKind.trailing,
      place: Place.indoor,
      humidity: 55,
      temperature: 25,
      lightPercent: 50,
      intervalDays: 5,
      lastWatered: ago(6),
      acquired: ago(150),
      photoAsset: 'assets/plants/sirih-gading.png',
      wateredOn: history(6, 5, 5),
      notes: 'Sulur sudah menjuntai hampir menyentuh lantai.',
      journal: <JournalEntry>[
        JournalEntry(
          id: 'j6',
          date: ago(45),
          heightCm: 60,
          note: 'Panjang sulur terpanjang saat diukur pertama kali.',
        ),
        JournalEntry(
          id: 'j7',
          date: ago(9),
          heightCm: 78,
          note: 'Dipangkas sedikit, potongannya ditaruh di air.',
        ),
      ],
    ),
  ];
}

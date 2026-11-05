const List<String> _bulan = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

const List<String> _bulanPanjang = <String>[
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

const List<String> _hari = <String>[
  'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
];

const List<String> _hariPendek = <String>[
  'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min',
];

/// Membuang jam, menyisakan tanggal saja.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Menambah hari kalender (aman terhadap pergantian jam musim).
DateTime addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

/// Selisih hari kalender dari [from] ke [to]. Negatif kalau [to] sudah lewat.
int daysBetween(DateTime from, DateTime to) {
  final DateTime a = DateTime.utc(from.year, from.month, from.day);
  final DateTime b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}

String formatDate(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';

String formatDayDate(DateTime d) =>
    '${_hari[d.weekday - 1]}, ${d.day} ${_bulan[d.month - 1]}';

String shortMonth(DateTime d) => _bulan[d.month - 1];

String shortWeekday(DateTime d) => _hariPendek[d.weekday - 1];

String formatTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}.${d.minute.toString().padLeft(2, '0')}';

String monthYear(DateTime d) => '${_bulanPanjang[d.month - 1]} ${d.year}';

int daysInMonth(DateTime d) => DateTime(d.year, d.month + 1, 0).day;

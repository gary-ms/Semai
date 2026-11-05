import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../data/dummy_data.dart';
import '../models/plant.dart';
import '../utils/dates.dart';

class SyncResult {
  const SyncResult(this.ok, this.message);

  final bool ok;
  final String message;
}

/// Sumber state seluruh aplikasi. Dipasang di atas MaterialApp lewat Provider,
/// jadi tidak hilang saat layar diputar atau pindah halaman (padanan ViewModel).
class PlantStore extends ChangeNotifier {
  PlantStore({
    List<Plant>? seed,
    bool listenConnectivity = true,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _plants = List<Plant>.of(seed ?? buildDummyPlants(_clock()));
    if (listenConnectivity) {
      _startConnectivity();
    }
  }

  static const String demoEmail = 'sari@semai.id';
  static const String demoPassword = 'semai123';

  final DateTime Function() _clock;
  late List<Plant> _plants;
  bool _disposed = false;

  bool _loggedIn = false;
  String _userEmail = '';
  final String _userName = 'Sari';

  // Pencarian dan filter (disimpan di sini agar bertahan saat pindah halaman)
  String _query = '';
  Place? _place;
  bool _onlyDue = false;

  bool _online = true;
  bool _syncing = false;
  bool _simulateOutage = false;
  DateTime? _lastSync;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  DateTime get today => dateOnly(_clock());

  bool get loggedIn => _loggedIn;
  String get userName => _userName;
  String get userEmail => _userEmail;

  /// Mengembalikan null kalau berhasil, atau pesan error kalau gagal.
  Future<String?> login(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final bool ok =
        email.trim().toLowerCase() == demoEmail && password == demoPassword;
    if (!ok) {
      return 'Email atau kata sandi tidak cocok. Coba lagi.';
    }
    _loggedIn = true;
    _userEmail = demoEmail;
    _notify();
    return null;
  }

  void logout() {
    _loggedIn = false;
    _userEmail = '';
    _query = '';
    _place = null;
    _onlyDue = false;
    _notify();
  }

  List<Plant> get allPlants => List<Plant>.unmodifiable(_plants);

  int get plantCount => _plants.length;

  int get dueCount {
    final DateTime t = today;
    return _plants.where((Plant p) => p.daysUntilWatering(t) <= 0).length;
  }

  int get journalCount =>
      _plants.fold<int>(0, (int sum, Plant p) => sum + p.journal.length);

  String get query => _query;
  Place? get placeFilter => _place;
  bool get onlyDue => _onlyDue;
  bool get hasActiveFilter =>
      _query.trim().isNotEmpty || _place != null || _onlyDue;

  void setQuery(String value) {
    if (value == _query) return;
    _query = value;
    _notify();
  }

  void setPlaceFilter(Place? value) {
    if (value == _place) return;
    _place = value;
    _notify();
  }

  void setOnlyDue(bool value) {
    if (value == _onlyDue) return;
    _onlyDue = value;
    _notify();
  }

  void clearFilters() {
    _query = '';
    _place = null;
    _onlyDue = false;
    _notify();
  }

  /// Daftar yang tampil di Koleksi: sudah disaring, yang paling mendesak dulu.
  List<Plant> get visiblePlants {
    final String q = _query.trim().toLowerCase();
    final DateTime t = today;
    final List<Plant> list = _plants.where((Plant p) {
      if (_place != null && p.place != _place) return false;
      if (_onlyDue && p.daysUntilWatering(t) > 0) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.species.toLowerCase().contains(q);
    }).toList();
    list.sort((Plant a, Plant b) {
      final int c = a.nextWatering.compareTo(b.nextWatering);
      return c != 0 ? c : a.name.compareTo(b.name);
    });
    return list;
  }

  /// Semua tanaman diurutkan menurut jadwal siram (untuk halaman Jadwal).
  List<Plant> get scheduled {
    final List<Plant> list = List<Plant>.of(_plants);
    list.sort((Plant a, Plant b) {
      final int c = a.nextWatering.compareTo(b.nextWatering);
      return c != 0 ? c : a.name.compareTo(b.name);
    });
    return list;
  }

  Plant? byId(String id) {
    for (final Plant p in _plants) {
      if (p.id == id) return p;
    }
    return null;
  }

  int indexOf(String id) => _plants.indexWhere((Plant p) => p.id == id);

  String newId() => 'p${DateTime.now().microsecondsSinceEpoch}';

  bool nameTaken(String name, {String? exceptId}) {
    final String n = name.trim().toLowerCase();
    return _plants.any(
      (Plant p) => p.id != exceptId && p.name.trim().toLowerCase() == n,
    );
  }

  void add(Plant plant) {
    _plants.add(plant);
    _notify();
  }

  void update(Plant plant) {
    final int i = indexOf(plant.id);
    if (i < 0) return;
    _plants[i] = plant;
    _notify();
  }

  /// Menghapus dan mengembalikan tanaman yang dihapus (null kalau tidak ada).
  Plant? remove(String id) {
    final int i = indexOf(id);
    if (i < 0) return null;
    final Plant removed = _plants.removeAt(i);
    _notify();
    return removed;
  }

  void insertAt(int index, Plant plant) {
    final int safe = index.clamp(0, _plants.length);
    _plants.insert(safe, plant);
    _notify();
  }

  /// Menandai sudah disiram. Mengembalikan tanggal siram sebelumnya agar
  /// aksinya bisa diurungkan.
  DateTime? water(String id, {DateTime? on}) {
    final int i = indexOf(id);
    if (i < 0) return null;
    final DateTime previous = _plants[i].lastWatered;
    final DateTime day = dateOnly(on ?? today);
    final List<DateTime> log = List<DateTime>.of(_plants[i].wateredOn);
    if (!log.any((DateTime w) => dateOnly(w) == day)) log.add(day);
    _plants[i] = _plants[i].copyWith(lastWatered: day, wateredOn: log);
    _notify();
    return previous;
  }

  /// Membatalkan siram: kembalikan tanggal sebelumnya dan hapus catatannya.
  void unwater(String id, DateTime previous, {DateTime? on}) {
    final int i = indexOf(id);
    if (i < 0) return;
    final DateTime day = dateOnly(on ?? today);
    final List<DateTime> log = _plants[i]
        .wateredOn
        .where((DateTime w) => dateOnly(w) != day)
        .toList();
    _plants[i] = _plants[i].copyWith(lastWatered: previous, wateredOn: log);
    _notify();
  }

  void addJournal(String plantId, JournalEntry entry) {
    final int i = indexOf(plantId);
    if (i < 0) return;
    final List<JournalEntry> next =
        List<JournalEntry>.of(_plants[i].journal)..add(entry);
    _plants[i] = _plants[i].copyWith(journal: next);
    _notify();
  }

  void removeJournal(String plantId, String entryId) {
    final int i = indexOf(plantId);
    if (i < 0) return;
    final List<JournalEntry> next = _plants[i]
        .journal
        .where((JournalEntry e) => e.id != entryId)
        .toList();
    _plants[i] = _plants[i].copyWith(journal: next);
    _notify();
  }

  bool get online => _online;
  bool get syncing => _syncing;
  bool get simulateOutage => _simulateOutage;
  DateTime? get lastSync => _lastSync;

  void setSimulateOutage(bool value) {
    if (value == _simulateOutage) return;
    _simulateOutage = value;
    _notify();
  }

  void _startConnectivity() {
    try {
      final Connectivity connectivity = Connectivity();
      recheckConnectivity();
      _connectivitySub = connectivity.onConnectivityChanged.listen(
        _applyConnectivity,
        onError: (Object _) {},
      );
    } catch (_) {
      // Plugin tidak tersedia (misalnya saat test): anggap tetap online.
    }
  }

  Future<void> recheckConnectivity() async {
    try {
      final List<ConnectivityResult> results =
          await Connectivity().checkConnectivity();
      _applyConnectivity(results);
    } catch (_) {
      // Abaikan: status koneksi tetap seperti sebelumnya.
    }
  }

  void _applyConnectivity(List<ConnectivityResult> results) {
    final bool nowOnline = results.isNotEmpty &&
        !results.every((ConnectivityResult r) => r == ConnectivityResult.none);
    if (nowOnline != _online) {
      _online = nowOnline;
      _notify();
    }
  }

  /// Simulasi sinkronisasi ke server. Gagal kalau offline atau kalau
  /// "gangguan jaringan" dinyalakan dari halaman Profil.
  Future<SyncResult> sync() async {
    if (_syncing) {
      return const SyncResult(false, 'Sinkronisasi sedang berjalan.');
    }
    _syncing = true;
    _notify();
    try {
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!_online) {
        return const SyncResult(
          false,
          'Tidak ada koneksi internet. Sambungkan lalu coba lagi.',
        );
      }
      if (_simulateOutage) {
        return const SyncResult(
          false,
          'Server tidak dapat dihubungi. Coba lagi nanti.',
        );
      }
      _lastSync = _clock();
      return const SyncResult(true, 'Data berhasil disinkronkan.');
    } catch (_) {
      return const SyncResult(false, 'Sinkronisasi gagal. Coba lagi.');
    } finally {
      _syncing = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _connectivitySub?.cancel();
    super.dispose();
  }
}

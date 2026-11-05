/// Semua validasi input ada di sini supaya mudah diuji dan dipakai ulang.
/// Setiap fungsi mengembalikan pesan error (String) atau null kalau valid.
class Validators {
  Validators._();

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static String? email(String? value) {
    final String v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email wajib diisi';
    if (!_emailPattern.hasMatch(v)) {
      return 'Format email belum benar, contoh: nama@email.com';
    }
    return null;
  }

  static String? password(String? value) {
    final String v = value ?? '';
    if (v.isEmpty) return 'Kata sandi wajib diisi';
    if (v.length < 6) return 'Kata sandi minimal 6 karakter';
    return null;
  }

  static String? plantName(
    String? value, {
    required bool Function(String name) isTaken,
  }) {
    final String v = value?.trim() ?? '';
    if (v.isEmpty) return 'Nama tanaman wajib diisi';
    if (v.length < 2) return 'Nama minimal 2 karakter';
    if (v.length > 30) return 'Nama maksimal 30 karakter';
    if (isTaken(v)) return 'Nama ini sudah dipakai tanaman lain';
    return null;
  }

  static String? species(String? value) {
    final String v = value?.trim() ?? '';
    if (v.isEmpty) return 'Jenis tanaman wajib diisi';
    if (v.length < 2) return 'Jenis minimal 2 karakter';
    if (v.length > 50) return 'Jenis maksimal 50 karakter';
    return null;
  }

  static String? intervalDays(String? value) {
    final String v = value?.trim() ?? '';
    if (v.isEmpty) return 'Interval siram wajib diisi';
    final int? n = int.tryParse(v);
    if (n == null) return 'Isi dengan angka bulat';
    if (n < 1 || n > 60) return 'Interval harus antara 1 dan 60 hari';
    return null;
  }

  /// Angka bulat dalam rentang [min, max], dipakai untuk target perawatan.
  static String? range(String? value, String label, int min, int max,
      {String unit = ''}) {
    final String v = value?.trim() ?? '';
    if (v.isEmpty) return '$label wajib diisi';
    final int? n = int.tryParse(v);
    if (n == null) return '$label harus berupa angka bulat';
    if (n < min || n > max) return '$label harus antara $min dan $max$unit';
    return null;
  }

  /// Tinggi boleh kosong. Kalau diisi harus angka antara 0 dan 500 cm.
  static String? height(String? value) {
    final String v = (value ?? '').trim().replaceAll(',', '.');
    if (v.isEmpty) return null;
    final double? n = double.tryParse(v);
    if (n == null) return 'Tinggi harus berupa angka, contoh 12,5';
    if (n <= 0 || n > 500) return 'Tinggi harus antara 0 dan 500 cm';
    return null;
  }

  static double? parseHeight(String? value) {
    final String v = (value ?? '').trim().replaceAll(',', '.');
    if (v.isEmpty) return null;
    return double.tryParse(v);
  }

  static String? journalNote(String? value) {
    final String v = value?.trim() ?? '';
    if (v.isEmpty) return 'Catatan wajib diisi';
    if (v.length < 3) return 'Tulis minimal 3 karakter';
    if (v.length > 200) return 'Catatan maksimal 200 karakter';
    return null;
  }
}

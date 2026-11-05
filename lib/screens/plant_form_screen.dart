import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models/plant.dart';
import '../state/plant_store.dart';
import '../utils/dates.dart';
import '../utils/validators.dart';
import '../widgets/common.dart';
import '../widgets/plant_illustration.dart';
import '../widgets/plant_photo.dart';

/// Form tambah dan ubah tanaman (mode ubah kalau [plantId] diisi).
///
/// Semua isian disimpan di State, jadi tidak hilang saat layar diputar.
/// Kalau ada perubahan yang belum disimpan, tombol kembali meminta konfirmasi.
class PlantFormScreen extends StatefulWidget {
  const PlantFormScreen({super.key, this.plantId});

  final String? plantId;

  @override
  State<PlantFormScreen> createState() => _PlantFormScreenState();
}

class _PlantFormScreenState extends State<PlantFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _species;
  late final TextEditingController _interval;
  late final TextEditingController _humidity;
  late final TextEditingController _temperature;
  late final TextEditingController _lightPct;
  late final TextEditingController _notes;

  Plant? _editing;
  late PlantKind _kind;
  late Place _place;
  late DateTime _lastWatered;
  String? _photoPath;

  bool _dirty = false;
  bool _submitted = false;

  bool get _isEdit => _editing != null;

  @override
  void initState() {
    super.initState();
    final PlantStore store = context.read<PlantStore>();
    final String? id = widget.plantId;
    _editing = id == null ? null : store.byId(id);
    final Plant? p = _editing;

    _name = TextEditingController(text: p?.name ?? '');
    _species = TextEditingController(text: p?.species ?? '');
    _interval = TextEditingController(text: '${p?.intervalDays ?? 7}');
    _notes = TextEditingController(text: p?.notes ?? '');
    _kind = p?.kind ?? PlantKind.leafy;
    _place = p?.place ?? Place.indoor;
    _humidity = TextEditingController(text: '${p?.humidity ?? 60}');
    _temperature = TextEditingController(text: '${p?.temperature ?? 24}');
    _lightPct = TextEditingController(text: '${p?.lightPercent ?? 60}');
    _lastWatered = p?.lastWatered ?? store.today;
    _photoPath = p?.photoPath;
  }

  @override
  void dispose() {
    _name.dispose();
    _species.dispose();
    _interval.dispose();
    _humidity.dispose();
    _temperature.dispose();
    _lightPct.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _pickDate() async {
    final DateTime today = context.read<PlantStore>().today;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _lastWatered.isAfter(today) ? today : _lastWatered,
      firstDate: addDays(today, -365),
      lastDate: today,
      helpText: 'Terakhir disiram',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked != null && mounted) {
      setState(() {
        _lastWatered = dateOnly(picked);
        _dirty = true;
      });
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      setState(() {
        _photoPath = file.path;
        _dirty = true;
      });
    } catch (_) {
      if (!mounted) return;
      showSnack(
        context,
        source == ImageSource.camera
            ? 'Kamera tidak bisa dibuka. Periksa izin kamera di pengaturan perangkat.'
            : 'Galeri tidak bisa dibuka. Periksa izin akses foto di pengaturan perangkat.',
      );
    }
  }

  Widget _photoPreview() {
    final String? path = _photoPath;
    final Plant? existing = _editing;
    final Widget child;
    if (path != null) {
      child = Image.file(
        File(path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        semanticLabel: 'Foto tanaman yang dipilih',
        errorBuilder: (BuildContext c, Object e, StackTrace? s) =>
            PlantIllustration(kind: _kind),
      );
    } else if (existing != null && existing.photoAsset != null) {
      child = PlantPhoto(
        plant: existing,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      );
    } else {
      child = Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: PlantIllustration(kind: _kind),
      );
    }
    return Container(
      height: 180,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Palette.paperDeep,
        borderRadius: AppTheme.radius,
      ),
      child: child,
    );
  }

  Widget _photoButton(IconData icon, String label, VoidCallback onTap) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: Palette.paperDeep,
        foregroundColor: Palette.ink,
        minimumSize: const Size(64, 48),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
    );
  }

  void _save() {
    setState(() => _submitted = true);
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      showSnack(
        context,
        'Ada isian yang perlu diperbaiki. Periksa kolom yang bertanda merah.',
      );
      return;
    }

    final PlantStore store = context.read<PlantStore>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState navigator = Navigator.of(context);

    final String name = _name.text.trim();
    final String species = _species.text.trim();
    final int interval = int.parse(_interval.text.trim());
    final int humidity = int.parse(_humidity.text.trim());
    final int temperature = int.parse(_temperature.text.trim());
    final int lightPct = int.parse(_lightPct.text.trim());
    final String notes = _notes.text.trim();

    final Plant? existing = _editing;
    if (existing == null) {
      store.add(
        Plant(
          id: store.newId(),
          name: name,
          species: species,
          kind: _kind,
          place: _place,
          humidity: humidity,
          temperature: temperature,
          lightPercent: lightPct,
          intervalDays: interval,
          lastWatered: _lastWatered,
          wateredOn: <DateTime>[_lastWatered],
          photoPath: _photoPath,
          acquired: store.today,
          notes: notes,
        ),
      );
    } else {
      store.update(
        existing.copyWith(
          name: name,
          species: species,
          kind: _kind,
          place: _place,
          humidity: humidity,
          temperature: temperature,
          lightPercent: lightPct,
          intervalDays: interval,
          lastWatered: _lastWatered,
          notes: notes,
          photoPath: _photoPath,
          clearPhoto: _photoPath == null,
        ),
      );
    }

    _dirty = false;
    navigator.pop();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(existing == null ? '$name ditambahkan ke koleksi.' : '$name diperbarui.'),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required String helper,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        helperText: helper,
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final PlantStore store = context.read<PlantStore>();

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final bool discard = await confirmDialog(
          context,
          title: 'Buang perubahan?',
          message: 'Isian yang belum disimpan akan hilang.',
          confirmLabel: 'Buang',
          destructive: true,
        );
        if (discard && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_isEdit ? 'Ubah tanaman' : 'Tambah tanaman')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Form(
                  key: _formKey,
                  onChanged: _markDirty,
                  autovalidateMode: _submitted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _photoPreview(),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          _photoButton(
                            Icons.photo_library_outlined,
                            'Pilih dari galeri',
                            () => _pickPhoto(ImageSource.gallery),
                          ),
                          _photoButton(
                            Icons.photo_camera_outlined,
                            'Ambil foto',
                            () => _pickPhoto(ImageSource.camera),
                          ),
                          if (_photoPath != null)
                            TextButton.icon(
                              onPressed: () => setState(() {
                                _photoPath = null;
                                _dirty = true;
                              }),
                              icon: const Icon(Icons.close, size: 20),
                              label: const Text('Hapus foto'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Opsional. Tanpa foto, tampil ilustrasi sesuai bentuk di bawah.',
                        style: TextStyle(color: Palette.inkSoft, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        maxLength: 30,
                        decoration: const InputDecoration(
                          labelText: 'Nama panggilan',
                          hintText: 'Misalnya Monti',
                        ),
                        validator: (String? v) => Validators.plantName(
                          v,
                          isTaken: (String n) =>
                              store.nameTaken(n, exceptId: _editing?.id),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _species,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Jenis tanaman',
                          hintText: 'Misalnya Monstera deliciosa',
                        ),
                        validator: Validators.species,
                      ),
                      const SizedBox(height: 20),
                      _label('Bentuk ilustrasi (tampil bila foto belum ada)'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          for (final PlantKind k in PlantKind.values)
                            appChoiceChip(
                              label: k.label,
                              selected: _kind == k,
                              onSelected: (_) => setState(() {
                                _kind = k;
                                _dirty = true;
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _label('Lokasi'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          for (final Place p in Place.values)
                            appChoiceChip(
                              label: p.label,
                              selected: _place == p,
                              onSelected: (_) => setState(() {
                                _place = p;
                                _dirty = true;
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _label('Target perawatan'),
                      _numberField(
                        controller: _humidity,
                        label: 'Kelembapan ideal',
                        suffix: '%',
                        helper: 'Antara 0 dan 100',
                        validator: (String? v) =>
                            Validators.range(v, 'Kelembapan', 0, 100, unit: '%'),
                      ),
                      const SizedBox(height: 12),
                      _numberField(
                        controller: _temperature,
                        label: 'Suhu ideal',
                        suffix: '\u00B0C',
                        helper: 'Antara 5 dan 45',
                        validator: (String? v) => Validators.range(
                            v, 'Suhu', 5, 45,
                            unit: '\u00B0C'),
                      ),
                      const SizedBox(height: 12),
                      _numberField(
                        controller: _lightPct,
                        label: 'Kebutuhan cahaya',
                        suffix: '%',
                        helper: 'Antara 0 dan 100',
                        validator: (String? v) =>
                            Validators.range(v, 'Cahaya', 0, 100, unit: '%'),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _interval,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Siram setiap',
                          suffixText: 'hari',
                          helperText: 'Antara 1 dan 60 hari',
                        ),
                        validator: Validators.intervalDays,
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: AppTheme.radius,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Terakhir disiram',
                            suffixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(formatDate(_lastWatered)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notes,
                        minLines: 2,
                        maxLines: 4,
                        maxLength: 200,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Catatan (opsional)',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _save,
                        child: Text(_isEdit ? 'Simpan perubahan' : 'Simpan tanaman'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

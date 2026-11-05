import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models/plant.dart';
import '../state/plant_store.dart';
import '../utils/dates.dart';
import '../utils/validators.dart';

Future<void> showJournalSheet(BuildContext context, String plantId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => JournalSheet(plantId: plantId),
  );
}

/// Form tambah catatan pertumbuhan. Controller ada di State, jadi isian tidak
/// hilang saat layar diputar ketika sheet sedang terbuka.
class JournalSheet extends StatefulWidget {
  const JournalSheet({super.key, required this.plantId});

  final String plantId;

  @override
  State<JournalSheet> createState() => _JournalSheetState();
}

class _JournalSheetState extends State<JournalSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _height = TextEditingController();
  final TextEditingController _note = TextEditingController();
  late DateTime _date;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _date = context.read<PlantStore>().today;
  }

  @override
  void dispose() {
    _height.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime today = context.read<PlantStore>().today;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: today,
      helpText: 'Tanggal catatan',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked != null && mounted) {
      setState(() => _date = dateOnly(picked));
    }
  }

  void _save() {
    setState(() => _submitted = true);
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final PlantStore store = context.read<PlantStore>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      store.addJournal(
        widget.plantId,
        JournalEntry(
          id: 'j${DateTime.now().microsecondsSinceEpoch}',
          date: _date,
          heightCm: Validators.parseHeight(_height.text),
          note: _note.text.trim(),
        ),
      );
    } catch (_) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Catatan belum tersimpan. Coba tekan Simpan lagi.'),
        ),
      );
      return;
    }
    Navigator.of(context).pop();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(content: Text('Catatan pertumbuhan ditambahkan.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        autovalidateMode: _submitted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Catatan pertumbuhan', style: AppText.display(24, height: 1.15)),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              borderRadius: AppTheme.radius,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal',
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(formatDate(_date)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _height,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Tinggi (opsional)',
                suffixText: 'cm',
              ),
              validator: Validators.height,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              minLines: 2,
              maxLines: 4,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Catatan',
                hintText: 'Misalnya: daun baru keluar, dipindah ke pot besar',
                alignLabelWithHint: true,
              ),
              validator: Validators.journalNote,
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: _save, child: const Text('Simpan catatan')),
          ],
        ),
      ),
    );
  }
}

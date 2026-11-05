import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/plant.dart';
import '../state/plant_store.dart';
import '../utils/dates.dart';
import 'motion.dart';
import 'plant_illustration.dart';

double textScaleOf(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(16) / 16;

/// Penanda status siram. Warna dan teks selalu dipakai bersama supaya tidak
/// hanya mengandalkan warna.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status, required this.label});

  final WaterStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: motionDuration(context, 220),
      child: _PillBody(
        key: ValueKey<String>(label),
        status: status,
        label: label,
      ),
    );
  }
}

class _PillBody extends StatelessWidget {
  const _PillBody({super.key, required this.status, required this.label});

  final WaterStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    switch (status) {
      case WaterStatus.overdue:
        bg = Palette.danger;
        fg = Palette.paper;
      case WaterStatus.today:
        bg = Palette.ink;
        fg = Palette.paper;
      case WaterStatus.soon:
        bg = Palette.paperDeeper;
        fg = Palette.ink;
      case WaterStatus.ok:
        bg = Palette.paperDeeper;
        fg = Palette.inkSoft;
    }
    final bool urgent =
        status == WaterStatus.overdue || status == WaterStatus.today;

    return DecoratedBox(
      decoration:
          BoxDecoration(color: bg, borderRadius: AppTheme.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (urgent) ...<Widget>[
              Icon(Icons.water_drop, size: 14, color: fg),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fg,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pesan error atau peringatan di dalam halaman (bukan dialog).
class InlineMessage extends StatelessWidget {
  const InlineMessage({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Palette.dangerSoft,
          borderRadius: AppTheme.radius,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.error_outline, color: Palette.danger, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Palette.ink,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.kind = PlantKind.leafy,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final PlantKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 104,
                height: 104,
                child: PlantIllustration(kind: kind),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppText.display(22, height: 1.2),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Palette.inkSoft, height: 1.4),
              ),
              if (actionLabel != null && onAction != null) ...<Widget>[
                const SizedBox(height: 20),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.visible, required this.onRetry});

  final bool visible;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: visible
          ? Semantics(
              liveRegion: true,
              child: Container(
                width: double.infinity,
                color: Palette.danger,
                padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.wifi_off, color: Palette.paper, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Tidak ada koneksi internet. Data di aplikasi tetap bisa dipakai, sinkronisasi ditunda.',
                        style: TextStyle(
                          color: Palette.paper,
                          fontSize: 13.5,
                          height: 1.3,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: onRetry,
                      style: TextButton.styleFrom(
                        foregroundColor: Palette.paper,
                      ),
                      child: const Text('Periksa lagi'),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}

ChoiceChip appChoiceChip({
  required String label,
  required bool selected,
  required ValueChanged<bool> onSelected,
}) {
  return ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: onSelected,
    showCheckmark: false,
    selectedColor: Palette.ink,
    backgroundColor: Palette.paperDeep,
    side: BorderSide.none,
    shape: RoundedRectangleBorder(borderRadius: AppTheme.radius),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
    labelStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: selected ? Palette.paper : Palette.ink,
    ),
  );
}

FilterChip appFilterChip({
  required String label,
  required bool selected,
  required ValueChanged<bool> onSelected,
}) {
  return FilterChip(
    label: Text(label),
    selected: selected,
    onSelected: onSelected,
    showCheckmark: false,
    selectedColor: Palette.lime,
    backgroundColor: Palette.paperDeep,
    side: BorderSide.none,
    shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusSmall),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
    labelStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Palette.ink,
    ),
  );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      backgroundColor: Palette.paperDeep,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppTheme.radius),
      title: Text(title, style: AppText.display(22, height: 1.2)),
      content: Text(message, style: const TextStyle(height: 1.4)),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Palette.danger,
                  foregroundColor: Palette.paper,
                  minimumSize: const Size(64, 48),
                )
              : FilledButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showSnack(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      action: (actionLabel != null && onAction != null)
          ? SnackBarAction(label: actionLabel, onPressed: onAction)
          : null,
    ),
  );
}

/// Menjalankan sinkronisasi lalu menampilkan hasilnya. Kalau gagal, ada tombol
/// "Coba lagi" di snackbar. Tidak memakai BuildContext setelah await.
Future<void> runSync(PlantStore store, ScaffoldMessengerState messenger) async {
  final SyncResult result = await store.sync();
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(result.message),
      action: result.ok
          ? null
          : SnackBarAction(
              label: 'Coba lagi',
              onPressed: () => runSync(store, messenger),
            ),
    ),
  );
}

/// Menandai sudah disiram, lalu memberi kesempatan mengurungkan.
void waterWithUndo(
  PlantStore store,
  ScaffoldMessengerState messenger,
  Plant plant,
) {
  final DateTime? previous = store.water(plant.id);
  final Plant? updated = store.byId(plant.id);
  final String next =
      updated == null ? '' : ' Berikutnya ${formatDayDate(updated.nextWatering)}.';
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text('${plant.name} sudah disiram.$next'),
      action: previous == null
          ? null
          : SnackBarAction(
              label: 'Urungkan',
              onPressed: () => store.unwater(plant.id, previous),
            ),
    ),
  );
}

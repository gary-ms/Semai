import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../routes.dart';
import '../state/plant_store.dart';
import '../utils/dates.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final bool ok = await confirmDialog(
      context,
      title: 'Keluar dari Semai?',
      message: 'Kamu bisa masuk lagi kapan saja dengan akun yang sama.',
      confirmLabel: 'Keluar',
    );
    if (!ok || !context.mounted) return;
    context.read<PlantStore>().logout();
    Navigator.of(context)
        .pushNamedAndRemoveUntil(Routes.login, (Route<dynamic> r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final PlantStore store = context.watch<PlantStore>();
    final TextTheme text = Theme.of(context).textTheme;
    final DateTime? last = store.lastSync;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: <Widget>[
            Text('Profil', style: text.headlineMedium),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Palette.ink,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    store.userName.isEmpty
                        ? '?'
                        : store.userName.substring(0, 1).toUpperCase(),
                    style: AppText.display(26, color: Palette.paper),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(store.userName, style: AppText.display(22, height: 1.2)),
                      Text(
                        store.userEmail.isEmpty ? PlantStore.demoEmail : store.userEmail,
                        style: const TextStyle(color: Palette.inkSoft),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(child: _Stat(value: '${store.plantCount}', label: 'Tanaman')),
                const SizedBox(width: 8),
                Expanded(child: _Stat(value: '${store.dueCount}', label: 'Perlu disiram')),
                const SizedBox(width: 8),
                Expanded(child: _Stat(value: '${store.journalCount}', label: 'Catatan jurnal')),
              ],
            ),
            const SizedBox(height: 28),
            Text('Sinkronisasi', style: AppText.display(20)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Palette.paperDeep,
                borderRadius: AppTheme.radius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        store.online ? Icons.wifi : Icons.wifi_off,
                        size: 20,
                        color: store.online ? Palette.leaf : Palette.danger,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          store.online ? 'Perangkat tersambung ke internet' : 'Perangkat sedang offline',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    last == null
                        ? 'Belum pernah disinkronkan.'
                        : 'Terakhir disinkronkan ${formatDate(last)} pukul ${formatTime(last)}.',
                    style: const TextStyle(color: Palette.inkSoft),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: store.syncing
                        ? null
                        : () => runSync(store, ScaffoldMessenger.of(context)),
                    icon: store.syncing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Icon(Icons.sync),
                    label: Text(store.syncing ? 'Menyinkronkan...' : 'Sinkronkan sekarang'),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Simulasikan gangguan jaringan',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Untuk menguji tampilan error saat sinkronisasi gagal.',
                      style: TextStyle(color: Palette.inkSoft),
                    ),
                    value: store.simulateOutage,
                    onChanged: store.setSimulateOutage,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Palette.danger),
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              label: const Text('Keluar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Palette.paperDeep,
        borderRadius: AppTheme.radius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(value, style: AppText.display(30, height: 1.0)),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Palette.inkSoft,
              fontSize: 12.5,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

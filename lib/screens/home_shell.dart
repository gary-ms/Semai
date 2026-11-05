import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../routes.dart';
import '../state/plant_store.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'collection_screen.dart';
import 'profile_screen.dart';
import 'schedule_screen.dart';

/// Kerangka utama dengan rel hitam di kiri (Tanaman, Jadwal, Profil).
/// IndexedStack menjaga state tiap tab (scroll, pencarian) saat berpindah tab.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: 1,
  );

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  void _select(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    if (!MediaQuery.disableAnimationsOf(context)) _fade.forward(from: 0);
  }

  static const List<String> _labels = <String>['Tanaman', 'Jadwal', 'Profil'];

  @override
  Widget build(BuildContext context) {
    final PlantStore store = context.watch<PlantStore>();

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) _select(0);
      },
      child: Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _SideRail(
              labels: _labels,
              selected: _index,
              online: store.online,
              onSelect: _select,
            ),
            Expanded(
              child: SafeArea(
                left: false,
                bottom: false,
                child: Column(
                  children: <Widget>[
                    OfflineBanner(
                      visible: !store.online,
                      onRetry: store.recheckConnectivity,
                    ),
                    Expanded(
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _fade,
                          curve: Curves.easeOut,
                        ),
                        child: IndexedStack(
                          index: _index,
                          children: const <Widget>[
                            CollectionScreen(),
                            ScheduleScreen(),
                            ProfileScreen(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: _index == 0
            ? FloatingActionButton(
                tooltip: 'Tambah tanaman',
                onPressed: () => Navigator.of(context).pushNamed(Routes.form),
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({
    required this.labels,
    required this.selected,
    required this.online,
    required this.onSelect,
  });

  final List<String> labels;
  final int selected;
  final bool online;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      color: Palette.night,
      child: SafeArea(
        right: false,
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 24),
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < labels.length; i++)
                      _RailItem(
                        label: labels[i],
                        selected: i == selected,
                        onTap: () => onSelect(i),
                      ),
                  ],
                ),
              ),
            ),
            Semantics(
              label: online ? 'Terhubung ke internet' : 'Sedang offline',
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Icon(
                  online ? Icons.wifi : Icons.wifi_off,
                  size: 22,
                  color: online ? Palette.lime : Palette.danger,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 64,
          height: 116,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              RotatedBox(
                quarterTurns: 3,
                child: AnimatedDefaultTextStyle(
                  duration: motionDuration(context, 200),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color:
                        selected ? Palette.paperDeep : Palette.onNightMuted,
                  ),
                  child: Text(label),
                ),
              ),
              Positioned(
                left: 0,
                child: AnimatedContainer(
                  duration: motionDuration(context, 220),
                  curve: Curves.easeOutCubic,
                  width: 4,
                  height: selected ? 36 : 0,
                  decoration: const BoxDecoration(
                    color: Palette.lime,
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

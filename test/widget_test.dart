import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:semai/main.dart';
import 'package:semai/models/plant.dart';
import 'package:semai/screens/dashboard_screen.dart';
import 'package:semai/state/plant_store.dart';
import 'package:semai/utils/validators.dart';

void main() {
  final DateTime fixedNow = DateTime(2026, 11, 4, 9, 30);

  group('Validators', () {
    test('email kosong dan salah format ditolak', () {
      expect(Validators.email(''), 'Email wajib diisi');
      expect(Validators.email('bukan-email'), isNotNull);
      expect(Validators.email('sari@semai.id'), isNull);
    });

    test('kata sandi minimal 6 karakter', () {
      expect(Validators.password(''), 'Kata sandi wajib diisi');
      expect(Validators.password('abc'), 'Kata sandi minimal 6 karakter');
      expect(Validators.password('semai123'), isNull);
    });

    test('interval siram harus angka 1 sampai 60', () {
      expect(Validators.intervalDays(''), isNotNull);
      expect(Validators.intervalDays('0'), isNotNull);
      expect(Validators.intervalDays('61'), isNotNull);
      expect(Validators.intervalDays('7'), isNull);
    });

    test('tinggi boleh kosong tapi kalau diisi harus angka', () {
      expect(Validators.height(''), isNull);
      expect(Validators.height('12,5'), isNull);
      expect(Validators.height('abc'), isNotNull);
      expect(Validators.height('900'), isNotNull);
    });

    test('nama tanaman tidak boleh kembar', () {
      expect(
        Validators.plantName('Monti', isTaken: (String n) => true),
        'Nama ini sudah dipakai tanaman lain',
      );
      expect(
        Validators.plantName('Monti', isTaken: (String n) => false),
        isNull,
      );
    });
  });

  group('PlantStore', () {
    PlantStore buildStore() =>
        PlantStore(listenConnectivity: false, clock: () => fixedNow);

    test('menyiram menggeser jadwal berikutnya dan bisa diurungkan', () {
      final PlantStore store = buildStore();
      final Plant before = store.byId('p2')!; // Sukulen, terlambat
      expect(before.statusOn(store.today), WaterStatus.overdue);

      final DateTime? previous = store.water('p2');
      final Plant after = store.byId('p2')!;
      expect(after.statusOn(store.today), WaterStatus.ok);
      expect(after.daysUntilWatering(store.today), after.intervalDays);

      store.unwater('p2', previous!);
      expect(store.byId('p2')!.statusOn(store.today), WaterStatus.overdue);
    });

    test('pencarian dan filter lokasi bekerja bersamaan', () {
      final PlantStore store = buildStore();
      store.setQuery('xyz');
      expect(store.visiblePlants, isEmpty);

      store.setQuery('mammillaria');
      expect(store.visiblePlants.map((Plant p) => p.name), <String>['Kaktus']);

      store.setQuery('');
      store.setPlaceFilter(Place.balcony);
      expect(
        store.visiblePlants.every((Plant p) => p.place == Place.balcony),
        isTrue,
      );
    });

    test('tambah, ubah, hapus tanaman dan nama kembar terdeteksi', () {
      final PlantStore store = buildStore();
      final int start = store.plantCount;
      expect(store.nameTaken('monti'), isTrue);

      store.add(
        Plant(
          id: 'baru',
          name: 'Cabai',
          species: 'Capsicum annuum',
          kind: PlantKind.leafy,
          place: Place.balcony,
          humidity: 50,
          temperature: 27,
          lightPercent: 90,
          intervalDays: 2,
          lastWatered: store.today,
          acquired: store.today,
        ),
      );
      expect(store.plantCount, start + 1);

      store.update(store.byId('baru')!.copyWith(name: 'Cabai Rawit'));
      expect(store.byId('baru')!.name, 'Cabai Rawit');

      expect(store.remove('baru'), isNotNull);
      expect(store.plantCount, start);
    });

    test('sinkronisasi gagal saat gangguan jaringan disimulasikan', () async {
      final PlantStore store = buildStore();
      store.setSimulateOutage(true);
      final SyncResult failed = await store.sync();
      expect(failed.ok, isFalse);

      store.setSimulateOutage(false);
      final SyncResult ok = await store.sync();
      expect(ok.ok, isTrue);
      expect(store.lastSync, isNotNull);
    });

    test('login menolak akun yang salah', () async {
      final PlantStore store = buildStore();
      expect(await store.login('salah@email.com', 'xxxxxx'), isNotNull);
      expect(store.loggedIn, isFalse);
      expect(
        await store.login(PlantStore.demoEmail, PlantStore.demoPassword),
        isNull,
      );
      expect(store.loggedIn, isTrue);
    });
  });

  testWidgets('splash menuju login, kolom kosong menampilkan pesan validasi',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final PlantStore store =
        PlantStore(listenConnectivity: false, clock: () => fixedNow);
    await tester.pumpWidget(SemaiApp(store: store));

    // Lewati animasi dan timer splash.
    await tester.pump(const Duration(milliseconds: 5600));
    await tester.pumpAndSettle();

    final Finder loginButton = find.widgetWithText(FilledButton, 'Masuk');
    expect(loginButton, findsOneWidget);

    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pump();

    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
  });

  group('Dashboard', () {
    PlantStore buildStore() =>
        PlantStore(listenConnectivity: false, clock: () => fixedNow);

    test('duePlants hanya berisi yang jadwalnya hari ini atau lewat', () {
      final PlantStore store = buildStore();
      final DateTime t = store.today;
      expect(store.duePlants.length, store.dueCount);
      expect(
        store.duePlants.every((Plant p) => p.daysUntilWatering(t) <= 0),
        isTrue,
      );
    });

    test('latestPlants urut dari yang paling baru dan dibatasi jumlahnya', () {
      final PlantStore store = buildStore();
      final List<Plant> latest = store.latestPlants(2);
      expect(latest.length, 2);
      expect(latest[0].acquired.isBefore(latest[1].acquired), isFalse);
    });

    testWidgets('menampilkan jumlah perlu disiram dan Siram semua bekerja',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final PlantStore store = buildStore();
      final int due = store.duePlants.length;
      expect(due, greaterThan(1));

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<PlantStore>.value(
            value: store,
            child: Scaffold(
              body: DashboardScreen(onOpenCollection: () {}),
            ),
          ),
        ),
      );

      expect(find.text('Halo, Sari'), findsOneWidget);
      expect(find.text('$due tanaman perlu disiram'), findsOneWidget);

      await tester.tap(find.text('Siram semua'));
      await tester.pump();

      expect(store.duePlants, isEmpty);
      expect(find.text('Semua tanaman sudah disiram'), findsOneWidget);
    });
  });
}

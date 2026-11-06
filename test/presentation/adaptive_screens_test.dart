import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solar_safe_smart_station/core/config/app_config.dart';
import 'package:solar_safe_smart_station/core/design/app_theme.dart';
import 'package:solar_safe_smart_station/data/repositories/measurement_repository.dart';
import 'package:solar_safe_smart_station/domain/models/measurement.dart';
import 'package:solar_safe_smart_station/features/dashboard/dashboard_screen.dart';
import 'package:solar_safe_smart_station/features/history/history_screen.dart';
import 'package:solar_safe_smart_station/features/alerts/alerts_screen.dart';
import 'package:solar_safe_smart_station/features/station/station_screen.dart';
import 'package:solar_safe_smart_station/features/shell/app_shell.dart';
import 'package:solar_safe_smart_station/features/shared/station_context.dart';

class FakeRepository implements MeasurementRepository {
  FakeRepository({this.empty = false, this.error = false});
  final bool empty, error;
  int rangeCalls = 0;
  List<Measurement> get data => empty
      ? []
      : List.generate(
          24,
          (i) => Measurement(
            id: '$i',
            stationId: 'EST-001',
            uv: 2 + i / 3,
            temperature: 22 + i / 4,
            humidity: 60 - i / 5,
            createdAt: DateTime.now().subtract(
              Duration(hours: 23 - i, minutes: 1),
            ),
          ),
        );
  @override
  Stream<Measurement?> watchLatest() => error
      ? Stream.error(const FormatException('invalid data'))
      : Stream.value(data.isEmpty ? null : data.last);
  @override
  Stream<List<Measurement>> watchRange(DateTime from, {DateTime? until}) {
    rangeCalls++;
    return error
        ? Stream.error(const FormatException('invalid data'))
        : Stream.value(data);
  }

  @override
  Future<List<Measurement>> fetchRange(
    DateTime from, {
    DateTime? until,
  }) async => data;
}

const config = AppConfig(
  supabaseUrl: '',
  supabaseAnonKey: '',
  measurementsTable: 'mediciones',
  stationName: 'Estación de prueba',
  stationLocation: 'Ubicación ilustrativa',
  maxMeasurementAge: Duration(minutes: 5),
);
void main() {
  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    for (final family in ['Manrope', 'JetBrainsMono']) {
      final loader = FontLoader(family)
        ..addFont(rootBundle.load('assets/fonts/$family.ttf'));
      await loader.load();
    }
  });
  Future<void> mount(
    WidgetTester tester,
    Widget screen,
    Size size, {
    double scale = 1,
    GlobalKey? boundary,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: StationContext(
              config: config,
              child: Scaffold(body: screen),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final width in [320.0, 375.0, 768.0, 1024.0, 1440.0]) {
    testWidgets('screens fit available width $width', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = FakeRepository();
      for (final screen in [
        DashboardScreen(repository: repo, isConfigured: true),
        HistoryScreen(repository: repo, isConfigured: true),
        AlertsScreen(repository: repo, isConfigured: true),
        StationScreen(repository: repo, isConfigured: true),
      ]) {
        final boundary = GlobalKey();
        await mount(tester, screen, Size(width, 1100), boundary: boundary);
        expect(tester.takeException(), isNull);
        if (const bool.fromEnvironment('CAPTURE_UI') &&
            screen is DashboardScreen &&
            (width == 375 || width == 1440)) {
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await render.toImage(pixelRatio: 1);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File('/tmp/solar-safe-${width.toInt()}.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.drag(find.byType(ListView).first, const Offset(0, -900));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  }
  testWidgets('large text remains readable on small phone', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = FakeRepository();
    for (final screen in [
      DashboardScreen(repository: repo, isConfigured: true),
      AlertsScreen(repository: repo, isConfigured: true),
      StationScreen(repository: repo, isConfigured: true),
    ]) {
      await mount(tester, screen, const Size(320, 900), scale: 2);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
  testWidgets('resizing shell preserves history filters and subscription', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = FakeRepository();
    final shell = AppShell(repository: repo, isConfigured: true);
    await mount(tester, shell, const Size(375, 900));
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30 días'));
    await tester.pumpAndSettle();
    final count = repo.rangeCalls;
    await mount(tester, shell, const Size(1440, 900));
    expect(repo.rangeCalls, count);
    expect(find.text('Historial ambiental'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('empty and malformed data show explicit states', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(
      tester,
      DashboardScreen(
        repository: FakeRepository(empty: true),
        isConfigured: true,
      ),
      const Size(375, 900),
    );
    expect(find.text('La primera medición está por llegar'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await mount(
      tester,
      DashboardScreen(
        repository: FakeRepository(error: true),
        isConfigured: true,
      ),
      const Size(375, 900),
    );
    expect(
      find.text('No podemos confirmar las condiciones actuales'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

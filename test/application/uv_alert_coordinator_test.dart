import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solar_safe_smart_station/application/uv_alert_coordinator.dart';
import 'package:solar_safe_smart_station/core/notifications/notification_gateway.dart';
import 'package:solar_safe_smart_station/data/repositories/measurement_repository.dart';
import 'package:solar_safe_smart_station/domain/models/measurement.dart';

class _Repository implements MeasurementRepository {
  final events = StreamController<Measurement?>();
  @override
  Stream<Measurement?> watchLatest() => events.stream;
  @override
  Stream<List<Measurement>> watchRange(DateTime from, {DateTime? until}) =>
      const Stream.empty();
  @override
  Future<List<Measurement>> fetchRange(
    DateTime from, {
    DateTime? until,
  }) async => [];
}

class _Notifications implements NotificationGateway {
  int delivered = 0;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> showUvAlert({
    required String title,
    required String body,
  }) async {
    delivered++;
  }
}

void main() {
  test('ignores initial and stale data, notifies risk changes without repeating every sample', () async {
    SharedPreferences.setMockInitialValues({'uv_notifications_enabled': true});
    final repository = _Repository();
    final notifications = _Notifications();
    final coordinator = UvAlertCoordinator(
      repository: repository,
      notifications: notifications,
      maxAge: const Duration(minutes: 5),
    );
    await coordinator.start();
    Future<void> emit(String id, double uv, {bool stale = false}) async {
      repository.events.add(
        Measurement(
          id: id,
          stationId: '1',
          uv: uv,
          temperature: 25,
          humidity: 50,
          createdAt: DateTime.now().subtract(Duration(minutes: stale ? 60 : 1)),
        ),
      );
      await Future<void>.delayed(Duration.zero);
    }

    await emit('1', 9, stale: true);
    expect(notifications.delivered, 0);
    await emit('2', 8);
    expect(notifications.delivered, 1);
    await emit('3', 9);
    expect(notifications.delivered, 1);
    await emit('4', 11);
    expect(notifications.delivered, 2);
    await coordinator.setEnabled(false);
    await emit('5', 4);
    expect(notifications.delivered, 2);
    expect(
      (await SharedPreferences.getInstance()).getBool(
        'uv_notifications_enabled',
      ),
      false,
    );
    coordinator.dispose();
    await repository.events.close();
  });
  test(
    'unknown cadence cannot generate supposedly current notifications',
    () async {
      SharedPreferences.setMockInitialValues({
        'uv_notifications_enabled': true,
      });
      final repository = _Repository();
      final notifications = _Notifications();
      final coordinator = UvAlertCoordinator(
        repository: repository,
        notifications: notifications,
      );
      await coordinator.start();
      repository.events.add(null);
      repository.events.add(
        Measurement(
          id: '1',
          stationId: '1',
          uv: 12,
          temperature: 25,
          humidity: 50,
          createdAt: DateTime.now(),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(notifications.delivered, 0);
      coordinator.dispose();
      await repository.events.close();
    },
  );
}

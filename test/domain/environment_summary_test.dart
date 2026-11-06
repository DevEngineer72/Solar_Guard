import 'package:flutter_test/flutter_test.dart';
import 'package:solar_safe_smart_station/domain/models/environment_summary.dart';
import 'package:solar_safe_smart_station/domain/models/measurement.dart';
import 'package:solar_safe_smart_station/domain/services/alert_service.dart';

Measurement sample(double uv, DateTime time, {String id = '1'}) => Measurement(
  id: id,
  stationId: 'station',
  uv: uv,
  temperature: 25 + uv,
  humidity: 50,
  createdAt: time,
);
void main() {
  final now = DateTime.utc(2026, 11, 4, 12);
  test('freshness distinguishes unknown, stale, future and recent', () {
    final old = sample(8, now.subtract(const Duration(hours: 1)));
    expect(measurementFreshness(old, now, null), MeasurementFreshness.unknown);
    expect(
      measurementFreshness(old, now, const Duration(minutes: 5)),
      MeasurementFreshness.stale,
    );
    expect(
      measurementFreshness(sample(4, now), now, const Duration(minutes: 5)),
      MeasurementFreshness.recent,
    );
    expect(
      measurementFreshness(
        sample(4, now.add(const Duration(minutes: 1))),
        now,
        null,
      ),
      MeasurementFreshness.future,
    );
  });
  test('summary uses every sample and retains peak timestamp', () {
    final samples = [
      sample(2, now),
      sample(9, now.add(const Duration(hours: 1))),
      sample(4, now.add(const Duration(hours: 2))),
    ];
    final summary = MetricSummary(samples, EnvironmentalMetric.uv);
    expect(summary.average, 5);
    expect(summary.minimum, 2);
    expect(summary.maximum, 9);
    expect(summary.peakAt, samples[1].createdAt);
  });
  test('weekly groups cross month boundaries by local Monday', () {
    final samples = [
      sample(2, DateTime(2026, 10, 31)),
      sample(4, DateTime(2026, 11, 1)),
      sample(6, DateTime(2026, 11, 2)),
    ];
    final groups = groupMeasurements(samples, weekly: true);
    expect(groups[DateTime(2026, 10, 26)]!.length, 2);
    expect(groups[DateTime(2026, 11, 2)]!.length, 1);
  });
  test('CSV contains UTC timestamps and escapes formula-like identifiers', () {
    final csv = measurementsCsv([sample(8, now, id: '=2+2')]);
    expect(csv, contains('"\'=2+2"'));
    expect(csv, contains(now.toIso8601String()));
    expect(
      csv,
      startsWith('\uFEFFid,station_id,uv,temperatura,humedad,created_at'),
    );
  });
  test('alerts use UV protection boundaries and preserve historical dates', () {
    final time = DateTime.now().subtract(const Duration(days: 3));
    final alerts = const AlertService().derive([
      sample(2.9, time),
      sample(3, time),
      sample(8, time),
    ]);
    expect(alerts.length, 2);
    expect(alerts.first.kind, StationAlertKind.critical);
    expect(alerts.last.kind, StationAlertKind.preventive);
    expect(alerts.first.createdAt, time);
  });
  test('invalid environmental values are rejected', () {
    final base = {
      'id': 1,
      'station_id': 1,
      'uv': 1,
      'temperatura': 20,
      'humedad': 40,
      'created_at': now.toIso8601String(),
    };
    for (final pair in [
      ('uv', double.nan),
      ('uv', -1),
      ('humedad', 101),
      ('temperatura', double.infinity),
    ]) {
      expect(
        () => Measurement.fromMap({...base, pair.$1: pair.$2}),
        throwsFormatException,
      );
    }
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:solar_safe_smart_station/domain/models/measurement.dart';

void main() {
  test('parses the documented Supabase measurement shape', () {
    final measurement = Measurement.fromMap({
      'id': '1',
      'station_id': 'station-1',
      'uv': 8.5,
      'temperatura': '31',
      'humedad': 62,
      'created_at': '2026-09-13T12:00:00Z',
    });
    expect(measurement.uv, 8.5);
    expect(measurement.temperature, 31);
  });

  test('rejects malformed measurements', () {
    expect(() => Measurement.fromMap({'id': '1'}), throwsFormatException);
  });
}

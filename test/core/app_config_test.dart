import 'package:flutter_test/flutter_test.dart';
import 'package:solar_safe_smart_station/core/config/app_config.dart';

void main() {
  test('accepts the configured mediciones table', () {
    final config = AppConfig.fromEnvironment({
      'SUPABASE_URL': 'https://example.supabase.co',
      'SUPABASE_ANON_KEY': 'public-key',
      'SUPABASE_MEASUREMENTS_TABLE': 'mediciones',
    });

    expect(config.isConfigured, isTrue);
    expect(config.measurementsTable, 'mediciones');
  });

  test('rejects an unsafe table identifier', () {
    final config = AppConfig.fromEnvironment({
      'SUPABASE_URL': 'https://example.supabase.co',
      'SUPABASE_ANON_KEY': 'public-key',
      'SUPABASE_MEASUREMENTS_TABLE': 'mediciones; drop table mediciones',
    });

    expect(config.isConfigured, isFalse);
  });
}

/// Configuración no secreta que la app obtiene del archivo `.env`.
///
/// Validar aquí evita intentar conectar con Supabase desde las pantallas si
/// faltan credenciales o si el nombre de tabla no es seguro.
class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.measurementsTable,
    this.stationName = 'Estación ambiental',
    this.stationLocation = 'Ubicación por confirmar',
    this.maxMeasurementAge,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String measurementsTable;
  final String stationName, stationLocation;
  final Duration? maxMeasurementAge;

  bool get isConfigured =>
      supabaseUrl.startsWith('https://') &&
      supabaseAnonKey.isNotEmpty &&
      _isValidPostgresIdentifier(measurementsTable);

  /// Convierte las variables de entorno en una configuración tipada.
  factory AppConfig.fromEnvironment(Map<String, String> values) => AppConfig(
    supabaseUrl: values['SUPABASE_URL']?.trim() ?? '',
    supabaseAnonKey: values['SUPABASE_ANON_KEY']?.trim() ?? '',
    stationName: _text(values['STATION_NAME'], 'Estación ambiental'),
    stationLocation: _text(
      values['STATION_LOCATION'],
      'Ubicación por confirmar',
    ),
    maxMeasurementAge: _maxAge(values['MEASUREMENT_MAX_AGE_SECONDS']),
    measurementsTable:
        values['SUPABASE_MEASUREMENTS_TABLE']?.trim() ?? 'mediciones',
  );

  static String _text(String? value, String fallback) =>
      value == null || value.trim().isEmpty ? fallback : value.trim();
  static Duration? _maxAge(String? value) {
    final seconds = int.tryParse(value ?? '');
    return seconds != null && seconds > 0 ? Duration(seconds: seconds) : null;
  }

  static bool _isValidPostgresIdentifier(String value) =>
      RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(value);
}

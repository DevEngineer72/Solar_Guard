/// Medición validada de una estación, independiente del formato de Supabase.
class Measurement {
  const Measurement({
    required this.id,
    required this.stationId,
    required this.uv,
    required this.temperature,
    required this.humidity,
    required this.createdAt,
  });

  final String id;
  final String stationId;
  final double uv;
  final double temperature;
  final double humidity;
  final DateTime createdAt;

  /// Convierte y valida una fila de la tabla `mediciones`.
  ///
  /// Supabase puede devolver números como `num` o texto según el tipo definido
  /// en PostgreSQL; ambos formatos se normalizan a `double` aquí.
  factory Measurement.fromMap(Map<String, dynamic> map) {
    double number(String key) {
      final value = map[key];
      final parsed = value is num
          ? value.toDouble()
          : double.tryParse(value?.toString() ?? '');
      if (parsed != null &&
          parsed.isFinite &&
          (key != 'uv' || parsed >= 0) &&
          (key != 'humedad' || (parsed >= 0 && parsed <= 100))) {
        return parsed;
      }
      throw const FormatException('Measurement numeric value is missing');
    }

    final createdAt = DateTime.tryParse(map['created_at']?.toString() ?? '');
    if (createdAt == null || map['id'] == null || map['station_id'] == null) {
      throw const FormatException(
        'Measurement contains required missing fields',
      );
    }
    return Measurement(
      id: map['id'].toString(),
      stationId: map['station_id'].toString(),
      uv: number('uv'),
      temperature: number('temperatura'),
      humidity: number('humedad'),
      createdAt: createdAt,
    );
  }
}

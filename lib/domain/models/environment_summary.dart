import 'measurement.dart';

enum EnvironmentalMetric { uv, temperature, humidity }

extension EnvironmentalMetricX on EnvironmentalMetric {
  String get label => switch (this) {
    EnvironmentalMetric.uv => 'Índice UV',
    EnvironmentalMetric.temperature => 'Temperatura',
    EnvironmentalMetric.humidity => 'Humedad',
  };
  String get unit => switch (this) {
    EnvironmentalMetric.uv => '',
    EnvironmentalMetric.temperature => '°C',
    EnvironmentalMetric.humidity => '%',
  };
  double value(Measurement m) => switch (this) {
    EnvironmentalMetric.uv => m.uv,
    EnvironmentalMetric.temperature => m.temperature,
    EnvironmentalMetric.humidity => m.humidity,
  };
}

class MetricSummary {
  MetricSummary(List<Measurement> data, EnvironmentalMetric metric)
    : assert(data.isNotEmpty) {
    minimum = maximum = metric.value(data.first);
    var sum = 0.0;
    peakAt = data.first.createdAt;
    for (final m in data) {
      final value = metric.value(m);
      if (value < minimum) minimum = value;
      if (value > maximum) {
        maximum = value;
        peakAt = m.createdAt;
      }
      sum += value;
    }
    average = sum / data.length;
  }
  late final double average;
  late double minimum, maximum;
  late DateTime peakAt;
}

/// Agrupa por calendario local. Los promedios son de muestras, no ponderados
/// por tiempo: intervalos irregulares no implican cobertura continua.
Map<DateTime, List<Measurement>> groupMeasurements(
  List<Measurement> data, {
  bool weekly = false,
}) {
  final groups = <DateTime, List<Measurement>>{};
  for (final m in data) {
    final date = m.createdAt.toLocal();
    final day = DateTime(
      date.year,
      date.month,
      date.day - (weekly ? date.weekday - 1 : 0),
    );
    groups.putIfAbsent(day, () => []).add(m);
  }
  return groups;
}

enum MeasurementFreshness { unknown, recent, stale, future }

MeasurementFreshness measurementFreshness(
  Measurement m,
  DateTime now,
  Duration? maxAge,
) {
  final age = now.difference(m.createdAt);
  if (age.isNegative) return MeasurementFreshness.future;
  if (maxAge == null) return MeasurementFreshness.unknown;
  return age <= maxAge
      ? MeasurementFreshness.recent
      : MeasurementFreshness.stale;
}

String measurementsCsv(List<Measurement> data) {
  String cell(String text) {
    // Spreadsheet formula injection protection for identifiers supplied remotely.
    if (RegExp(r'^[=+@\-\t\r]').hasMatch(text)) text = "'$text";
    return '"${text.replaceAll('"', '""')}"';
  }

  return '\uFEFFid,station_id,uv,temperatura,humedad,created_at\r\n${data.map((m) => '${cell(m.id)},${cell(m.stationId)},${m.uv},${m.temperature},${m.humidity},${m.createdAt.toUtc().toIso8601String()}').join('\r\n')}';
}

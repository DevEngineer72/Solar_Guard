import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../domain/models/measurement.dart';

/// Contrato de datos que usan las capas superiores.
///
/// La UI conoce este contrato, no el cliente de Supabase. Esto permite probar
/// las pantallas o cambiar la fuente de datos sin reescribirlas.
abstract interface class MeasurementRepository {
  Stream<Measurement?> watchLatest();
  Stream<List<Measurement>> watchRange(DateTime from, {DateTime? until});
  Future<List<Measurement>> fetchRange(DateTime from, {DateTime? until});

  factory MeasurementRepository.create(AppConfig config) => config.isConfigured
      ? SupabaseMeasurementRepository(config)
      : const UnconfiguredMeasurementRepository();
}

/// Implementación segura cuando aún no existe un `.env` configurado.
class UnconfiguredMeasurementRepository implements MeasurementRepository {
  const UnconfiguredMeasurementRepository();

  @override
  Future<List<Measurement>> fetchRange(
    DateTime from, {
    DateTime? until,
  }) async => [];

  @override
  Stream<Measurement?> watchLatest() => Stream.value(null);

  @override
  Stream<List<Measurement>> watchRange(DateTime from, {DateTime? until}) =>
      Stream.value([]);
}

/// Adaptador de Supabase que transforma filas remotas en modelos del dominio.
class SupabaseMeasurementRepository implements MeasurementRepository {
  SupabaseMeasurementRepository(AppConfig config, {SupabaseClient? client})
    : _table = config.measurementsTable {
    _client = client ?? Supabase.instance.client;
  }

  late final SupabaseClient _client;
  final String _table;

  @override
  /// `stream` usa Realtime: el Dashboard se actualiza al llegar una fila nueva
  /// sin hacer sondeo cada segundo.
  Stream<Measurement?> watchLatest() => _client
      .from(_table)
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .limit(1)
      .map((rows) => rows.isEmpty ? null : Measurement.fromMap(rows.first));

  @override
  Future<List<Measurement>> fetchRange(DateTime from, {DateTime? until}) async {
    final upperBound = (until ?? DateTime.now()).toUtc().toIso8601String();
    final items = <Measurement>[];
    var offset = 0;
    // Página explícita: los resúmenes/CSV no deben quedarse en el límite REST.
    while (true) {
      final rows = await _client
          .from(_table)
          .select()
          .gte('created_at', from.toUtc().toIso8601String())
          .lt('created_at', upperBound)
          .order('created_at')
          .order('id')
          .range(offset, offset + 499);
      if (rows.isEmpty) break;
      items.addAll(_parse(rows));
      offset += rows.length;
    }
    return items;
  }

  @override
  Stream<List<Measurement>> watchRange(DateTime from, {DateTime? until}) =>
      _client
          .from(_table)
          .stream(primaryKey: ['id'])
          .gte('created_at', from.toUtc().toIso8601String())
          .order('created_at')
          .asyncMap((_) => fetchRange(from, until: until));

  List<Measurement> _parse(List<Map<String, dynamic>> rows) =>
      rows.map(Measurement.fromMap).toList(growable: false)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
}

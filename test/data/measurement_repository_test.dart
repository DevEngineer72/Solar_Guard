import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:solar_safe_smart_station/core/config/app_config.dart';
import 'package:solar_safe_smart_station/data/repositories/measurement_repository.dart';

class _Transport extends http.BaseClient {
  _Transport({this.failAfterFirstPage = false});
  final bool failAfterFirstPage;
  final requests = <Uri>[];
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request.url);
    final offset = int.parse(request.url.queryParameters['offset']!);
    // Simula un límite del servidor inferior al tamaño de página solicitado.
    final count = min(200, max(0, 1205 - offset));
    if (failAfterFirstPage && offset > 0) {
      return http.StreamedResponse(Stream.value(utf8.encode('{"message":"connection failure"}')), 503, headers: {'content-type': 'application/json'});
    }
    final rows = List.generate(count, (i) => {'id': offset + i, 'station_id': 1, 'uv': (offset + i) % 12, 'temperatura': 25, 'humedad': 50, 'created_at': DateTime.utc(2026, 1, 1).add(Duration(seconds: offset + i)).toIso8601String()});
    return http.StreamedResponse(Stream.value(utf8.encode(jsonEncode(rows))), 200, headers: {'content-type': 'application/json'});
  }
}
const config = AppConfig(supabaseUrl: 'https://example.test', supabaseAnonKey: 'public-test-key', measurementsTable: 'mediciones');
void main() {
  test('pagination retrieves all rows even when server returns short pages', () async {
    final transport = _Transport();
    final client = SupabaseClient(config.supabaseUrl, config.supabaseAnonKey, httpClient: transport);
    addTearDown(client.dispose);
    final repo = SupabaseMeasurementRepository(config, client: client);
    final until = DateTime.utc(2026, 2, 1);
    final result = await repo.fetchRange(DateTime.utc(2026, 1, 1), until: until);
    expect(result.length, 1205);
    expect(result.map((m) => m.id).toSet().length, 1205);
    expect(transport.requests.length, 8);
    for (final request in transport.requests) {
      expect(request.queryParametersAll['created_at'], contains('lt.${until.toIso8601String()}'));
      expect(request.queryParameters['order'], 'created_at.asc,id.asc');
    }
  });
  test('a later page failure never yields a partial historical summary', () async {
    final transport = _Transport(failAfterFirstPage: true);
    final client = SupabaseClient(config.supabaseUrl, config.supabaseAnonKey, httpClient: transport);
    addTearDown(client.dispose);
    final repo = SupabaseMeasurementRepository(config, client: client);
    await expectLater(repo.fetchRange(DateTime.utc(2026, 1, 1)), throwsA(isA<PostgrestException>()));
  });
}

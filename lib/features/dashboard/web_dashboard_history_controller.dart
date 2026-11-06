import 'package:flutter/foundation.dart';

import '../../data/repositories/measurement_repository.dart';
import '../../domain/models/measurement.dart';

/// Carga el período elegido una vez y agrega lecturas del stream Realtime
/// que ya mantiene el Dashboard. Evita descargar 30 días cada tres segundos.
class WebDashboardHistoryController extends ChangeNotifier {
  WebDashboardHistoryController(this._repository, this.period);

  final MeasurementRepository _repository;
  final Duration period;
  final DateTime _startedAt = DateTime.now();
  List<Measurement> measurements = const [];
  Measurement? _latest;
  bool isLoading = true;
  Object? error;
  bool _disposed = false;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final fetched = await _repository.fetchRange(_startedAt.subtract(period));
      if (_disposed) return;
      measurements = fetched;
      isLoading = false;
      if (_latest != null) addLatest(_latest!);
      notifyListeners();
    } catch (failure) {
      if (_disposed) return;
      error = failure;
      isLoading = false;
      notifyListeners();
    }
  }

  void addLatest(Measurement value) {
    _latest = value;
    if (_disposed ||
        isLoading ||
        value.createdAt.isBefore(_startedAt.subtract(period))) {
      return;
    }
    final items = measurements;
    if (items.isNotEmpty && items.last.id == value.id) {
      if (items.last.createdAt == value.createdAt &&
          items.last.uv == value.uv &&
          items.last.temperature == value.temperature &&
          items.last.humidity == value.humidity) {
        return;
      }
      measurements = [...items.take(items.length - 1), value];
    } else if (items.isEmpty ||
        !value.createdAt.isBefore(items.last.createdAt)) {
      measurements = [...items, value];
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/repositories/measurement_repository.dart';
import '../../domain/models/measurement.dart';

/// Mantiene una suscripción a un rango de mediciones y expone su estado a UI.
///
/// `ChangeNotifier` es suficiente para esta app pequeña: evita añadir una
/// dependencia de gestión de estado sin mezclar acceso a datos con widgets.
class MeasurementsController extends ChangeNotifier {
  MeasurementsController(this._repository, {required this.from, this.until});

  final MeasurementRepository _repository;
  final DateTime from;
  final DateTime? until;
  StreamSubscription<List<Measurement>>? _subscription;
  List<Measurement> measurements = const [];
  Object? error;
  bool isLoading = true;

  void load() {
    // Cancelar primero impide duplicar suscripciones al cambiar el filtro.
    _subscription?.cancel();
    isLoading = true;
    error = null;
    notifyListeners();
    _subscription = _repository
        .watchRange(from, until: until)
        .listen(
          (items) {
            measurements = items;
            isLoading = false;
            error = null;
            notifyListeners();
          },
          onError: (Object value) {
            error = value;
            isLoading = false;
            notifyListeners();
          },
        );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Variante especializada para la única medición más reciente del Dashboard.
class LatestMeasurementController extends ChangeNotifier {
  LatestMeasurementController(this._repository);

  final MeasurementRepository _repository;
  Timer? _ageTimer;
  StreamSubscription<Measurement?>? _subscription;
  Measurement? measurement;
  Object? error;
  bool isLoading = true;

  void load() {
    _subscription?.cancel();
    isLoading = true;
    error = null;
    notifyListeners();
    _ageTimer ??= Timer.periodic(
      const Duration(seconds: 30),
      (_) => notifyListeners(),
    );
    _subscription = _repository.watchLatest().listen(
      (value) {
        measurement = value;
        error = null;
        isLoading = false;
        notifyListeners();
      },
      onError: (Object value) {
        error = value;
        isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _ageTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}

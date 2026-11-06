import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/notifications/notification_gateway.dart';
import '../data/repositories/measurement_repository.dart';
import '../domain/models/environment_summary.dart';
import '../domain/models/measurement.dart';
import '../domain/models/uv_risk.dart';

/// Preferencia local y entrega durante la ejecución de la app. No es push.
class UvAlertCoordinator extends ChangeNotifier {
  UvAlertCoordinator({
    required this.repository,
    required this.notifications,
    this.maxAge,
  });
  final MeasurementRepository repository;
  final NotificationGateway notifications;
  final Duration? maxAge;
  StreamSubscription<Measurement?>? _subscription;
  String? _lastId;
  UvRisk? _lastFreshRisk;
  bool _receivedInitial = false;
  bool enabled = false, busy = false;
  String? error;
  bool _disposed = false;
  Future<void>? _starting;
  Future<void> start() => _starting ??= _start();
  Future<void> _start() async {
    try {
      enabled =
          (await SharedPreferences.getInstance()).getBool(
            'uv_notifications_enabled',
          ) ??
          false;
      if (_disposed) return;
      if (enabled) await notifications.initialize();
      if (_disposed) return;
      _subscription = repository.watchLatest().listen(
        _onMeasurement,
        onError: (Object _) {
          /* Pantallas comunican el error de conexión. */
        },
      );
      notifyListeners();
    } catch (_) {
      if (!_disposed) {
        error = 'No se pudo cargar la preferencia de avisos.';
        notifyListeners();
      }
    }
  }

  Future<void> setEnabled(bool value) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      if (value) await notifications.initialize();
      await (await SharedPreferences.getInstance()).setBool(
        'uv_notifications_enabled',
        value,
      );
      enabled = value;
    } catch (_) {
      error = 'No se pudo guardar la preferencia. Intenta nuevamente.';
    }
    if (!_disposed) {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _onMeasurement(Measurement? m) async {
    final first = !_receivedInitial;
    _receivedInitial = true;
    if (m == null || m.id == _lastId) return;
    _lastId = m.id;
    final fresh =
        maxAge != null &&
        measurementFreshness(m, DateTime.now(), maxAge) ==
            MeasurementFreshness.recent;
    final previous = _lastFreshRisk;
    final risk = riskForUv(m.uv);
    _lastFreshRisk = fresh && enabled ? risk : null;
    // Pasar al mismo nivel no repite avisos con cada muestra del ESP32.
    // La carga inicial es contexto y nunca reproduce notificaciones antiguas.
    if (first ||
        !enabled ||
        !fresh ||
        risk.index < UvRisk.moderate.index ||
        risk == previous) {
      return;
    }
    try {
      await notifications.showUvAlert(
        title: 'Radiación UV ${risk.label.toLowerCase()}',
        body:
            'Índice ${m.uv.toStringAsFixed(1)}. ${risk.recommendations.first}',
      );
    } catch (_) {
      if (!_disposed) {
        error =
            'No se pudo mostrar el aviso. Revisa los permisos del dispositivo.';
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}

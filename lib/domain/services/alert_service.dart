import '../models/measurement.dart';
import '../models/uv_risk.dart';

enum AlertFilter { all, critical, preventive }

enum StationAlertKind { critical, preventive, info, healthy }

class StationAlert {
  const StationAlert({
    required this.kind,
    required this.title,
    required this.message,
    required this.createdAt,
    this.value,
  });
  final StationAlertKind kind;
  final String title, message;
  final DateTime createdAt;
  final String? value;
}

/// Registro derivado: una advertencia por medición UV >=3. No simula una tabla
/// de eventos ni certifica que se haya entregado una notificación al dispositivo.
class AlertService {
  const AlertService();
  List<StationAlert> derive(List<Measurement> measurements) => measurements
      .reversed
      .where((m) => m.uv >= 3 && !m.createdAt.isAfter(DateTime.now()))
      .map((m) {
        final risk = riskForUv(m.uv);
        return StationAlert(
          kind: m.uv >= 8
              ? StationAlertKind.critical
              : StationAlertKind.preventive,
          title: 'Radiación UV ${risk.label.toLowerCase()}',
          message: risk.recommendations.first,
          createdAt: m.createdAt,
          value: m.uv.toStringAsFixed(1),
        );
      })
      .toList();
}

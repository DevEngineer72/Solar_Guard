import 'package:flutter/material.dart';

import '../../core/design/app_tokens.dart';

enum UvRisk { low, moderate, high, veryHigh, extreme }

/// Información de presentación y límites de cada categoría del índice UV.
///
/// Los límites se definen aquí, en vez de en las pantallas, para que el
/// Dashboard, Historial y Alertas siempre comuniquen el mismo riesgo.
extension UvRiskX on UvRisk {
  String get label => switch (this) {
    UvRisk.low => 'BAJO',
    UvRisk.moderate => 'MODERADO',
    UvRisk.high => 'ALTO',
    UvRisk.veryHigh => 'MUY ALTO',
    UvRisk.extreme => 'EXTREMO',
  };

  Color get color => switch (this) {
    UvRisk.low => AppColors.green,
    UvRisk.moderate => const Color(0xffc08b00),
    UvRisk.high => AppColors.orange,
    UvRisk.veryHigh => AppColors.red,
    UvRisk.extreme => AppColors.purple,
  };

  List<String> get recommendations => switch (this) {
    UvRisk.low => [
      'Usa gafas de sol al aire libre.',
      'Consulta el índice UV antes de prolongar tu estancia.',
    ],
    UvRisk.moderate || UvRisk.high => [
      'Busca sombra alrededor del mediodía.',
      'Usa ropa que cubra la piel, sombrero y gafas de sol.',
      'Aplica protector solar de amplio espectro según sus instrucciones.',
    ],
    UvRisk.veryHigh || UvRisk.extreme => [
      'Reduce la exposición al sol alrededor del mediodía.',
      'Busca sombra y protege la piel con ropa y sombrero.',
      'Usa gafas de sol y protector de amplio espectro.',
    ],
  };

  /// Rango que se muestra a las personas usuarias.
  String get range => switch (this) {
    UvRisk.low => '0–2',
    UvRisk.moderate => '3–5',
    UvRisk.high => '6–7',
    UvRisk.veryHigh => '8–10',
    UvRisk.extreme => '11+',
  };
}

/// Clasifica una medición UV usando los rangos solicitados.
///
/// El sensor puede enviar decimales. Por eso 2.9 sigue siendo bajo y 3.0 ya
/// es moderado: los límites representan el inicio de cada índice entero.
UvRisk riskForUv(double value) {
  if (value < 3) return UvRisk.low;
  if (value < 6) return UvRisk.moderate;
  if (value < 8) return UvRisk.high;
  if (value < 11) return UvRisk.veryHigh;
  return UvRisk.extreme;
}

import 'package:flutter_test/flutter_test.dart';
import 'package:solar_safe_smart_station/domain/models/uv_risk.dart';

void main() {
  test('clasifica los límites exactos de la escala UV centralizada', () {
    expect(riskForUv(0), UvRisk.low);
    expect(riskForUv(3), UvRisk.moderate);
    expect(riskForUv(6), UvRisk.high);
    expect(riskForUv(8), UvRisk.veryHigh);
    expect(riskForUv(11), UvRisk.extreme);
  });

  test('mantiene el rango anterior hasta el siguiente índice entero', () {
    expect(riskForUv(2.9), UvRisk.low);
    expect(riskForUv(5.9), UvRisk.moderate);
    expect(riskForUv(7.9), UvRisk.high);
    expect(riskForUv(10.9), UvRisk.veryHigh);
  });
}

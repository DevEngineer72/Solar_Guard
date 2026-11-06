import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/environment_summary.dart';
import '../../domain/models/measurement.dart';
import '../shared/ui.dart';
import 'web_dashboard.dart';

/// Gráfico exclusivo del Dashboard Web. Cada serie ocupa su propio rango
/// observado; las unidades y extremos se muestran para evitar comparaciones
/// directas entre UV, grados y porcentaje.
class WebEnvironmentChart extends StatefulWidget {
  const WebEnvironmentChart({
    super.key,
    required this.data,
    required this.period,
    required this.onPeriodChanged,
    required this.isLoading,
    required this.error,
  });
  final List<Measurement> data;
  final Duration period;
  final ValueChanged<Duration> onPeriodChanged;
  final bool isLoading;
  final Object? error;

  @override
  State<WebEnvironmentChart> createState() => _WebEnvironmentChartState();
}

class _WebEnvironmentChartState extends State<WebEnvironmentChart> {
  int? _selected;
  List<Measurement>? _cachedData;
  Map<EnvironmentalMetric, _Range> _cachedRanges = const {};
  List<int> _cachedIndices = const [];
  static const periods = <(String, Duration)>[
    ('6 h', Duration(hours: 6)),
    ('24 h', Duration(hours: 24)),
    ('7 días', Duration(days: 7)),
    ('30 días', Duration(days: 30)),
  ];

  void _selectAt(double x, double width) {
    final data = widget.data;
    if (data.isEmpty) return;
    final fraction = ((x - 42) / math.max(1, width - 58)).clamp(0.0, 1.0);
    final first = data.first.createdAt.millisecondsSinceEpoch;
    final last = data.last.createdAt.millisecondsSinceEpoch;
    final target = first + (last - first) * fraction;
    var low = 0, high = data.length - 1;
    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (data[mid].createdAt.millisecondsSinceEpoch < target) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    if (low > 0 &&
        (target - data[low - 1].createdAt.millisecondsSinceEpoch).abs() <
            (target - data[low].createdAt.millisecondsSinceEpoch).abs()) {
      low--;
    }
    if (_selected != low) setState(() => _selected = low);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    if (!identical(_cachedData, data)) {
      _cachedData = data;
      _cachedRanges = data.isEmpty
          ? const {}
          : {
              for (final metric in EnvironmentalMetric.values)
                metric: _Range(data, metric),
            };
      _cachedIndices = data.isEmpty ? const [] : _sampleIndices(data);
      _selected = null;
    }
    final selected = data.isEmpty
        ? null
        : data[(_selected ?? data.length - 1).clamp(0, data.length - 1)];
    final ranges = _cachedRanges;
    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tendencias ambientales',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: WebColors.ink,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Mediciones de la estación en hora local',
                    style: TextStyle(fontSize: 12, color: WebColors.muted),
                  ),
                ],
              ),
              SegmentedButton<Duration>(
                showSelectedIcon: false,
                segments: [
                  for (final period in periods)
                    ButtonSegment(value: period.$2, label: Text(period.$1)),
                ],
                selected: {widget.period},
                onSelectionChanged: (value) {
                  setState(() => _selected = null);
                  widget.onPeriodChanged(value.first);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.isLoading)
            const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (widget.error != null)
            const StateNotice(
              icon: Icons.cloud_off_outlined,
              title: 'Tendencias no disponibles',
              message: 'No se pudo recuperar el historial de este período.',
            )
          else if (data.isEmpty)
            const StateNotice(
              icon: Icons.timeline,
              title: 'Sin mediciones en este período',
              message: 'Elige otro rango para explorar los datos.',
            )
          else ...[
            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                for (final metric in EnvironmentalMetric.values)
                  _Legend(metric: metric, range: ranges[metric]!),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Escala vertical: 0–100 % del rango observado de cada variable. Los valores reales se muestran abajo.',
              style: TextStyle(fontSize: 11, color: WebColors.muted),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) => MouseRegion(
                cursor: SystemMouseCursors.precise,
                onHover: (event) =>
                    _selectAt(event.localPosition.dx, constraints.maxWidth),
                child: GestureDetector(
                  onTapDown: (event) =>
                      _selectAt(event.localPosition.dx, constraints.maxWidth),
                  child: Semantics(
                    label: 'Tendencias de índice UV, temperatura y humedad. Usa el control inferior para explorar las lecturas.',
                    child: SizedBox(
                      height: 290,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _MultiLinePainter(
                                data,
                                ranges,
                                _cachedIndices,
                                _selected,
                              ),
                            ),
                          ),
                          if (_selected != null && selected != null)
                            Positioned(
                              top: 4,
                              left:
                                  (42 +
                                          (constraints.maxWidth - 58) *
                                              (selected
                                                      .createdAt
                                                      .millisecondsSinceEpoch -
                                                  data
                                                      .first
                                                      .createdAt
                                                      .millisecondsSinceEpoch) /
                                              math.max(
                                                1,
                                                data
                                                        .last
                                                        .createdAt
                                                        .millisecondsSinceEpoch -
                                                    data
                                                        .first
                                                        .createdAt
                                                        .millisecondsSinceEpoch,
                                              ) -
                                          115)
                                      .clamp(
                                        0.0,
                                        math.max(0, constraints.maxWidth - 230),
                                      ),
                              child: IgnorePointer(
                                child: SizedBox(
                                  width: 230,
                                  child: Material(
                                    color: WebColors.ink,
                                    borderRadius: BorderRadius.circular(9),
                                    elevation: 5,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            formatDate(
                                              selected.createdAt,
                                              seconds: true,
                                            ),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            'UV ${selected.uv.toStringAsFixed(2)}  ·  ${selected.temperature.toStringAsFixed(2)} °C  ·  ${selected.humidity.toStringAsFixed(2)} %',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _axisTime(data.first.createdAt, widget.period),
                  style: const TextStyle(fontSize: 11, color: WebColors.muted),
                ),
                Text(
                  _axisTime(data[data.length ~/ 2].createdAt, widget.period),
                  style: const TextStyle(fontSize: 11, color: WebColors.muted),
                ),
                Text(
                  _axisTime(data.last.createdAt, widget.period),
                  style: const TextStyle(fontSize: 11, color: WebColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (selected != null)
              Wrap(
                spacing: 16,
                runSpacing: 5,
                children: [
                  Text(
                    formatDate(selected.createdAt, seconds: true),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'UV ${selected.uv.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: WebColors.purple,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${selected.temperature.toStringAsFixed(2)} °C',
                    style: const TextStyle(
                      color: WebColors.green,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${selected.humidity.toStringAsFixed(2)} %',
                    style: const TextStyle(
                      color: WebColors.blue,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            if (data.length > 1)
              Slider(
                value: (_selected ?? data.length - 1)
                    .clamp(0, data.length - 1)
                    .toDouble(),
                max: (data.length - 1).toDouble(),
                divisions: math.min(data.length - 1, 1000),
                semanticFormatterCallback: (value) => formatDate(
                  data[value.round().clamp(0, data.length - 1)].createdAt,
                  seconds: true,
                ),
                onChanged: (value) => setState(() => _selected = value.round()),
              ),
          ],
        ],
      ),
    );
  }

  String _axisTime(DateTime date, Duration period) {
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return period.inDays >= 7
        ? '${two(local.day)}/${two(local.month)} ${two(local.hour)}:${two(local.minute)}'
        : '${two(local.hour)}:${two(local.minute)}';
  }
}

List<int> _sampleIndices(List<Measurement> data) {
  final stride = math.max(1, (data.length / 260).ceil());
  final indices = <int>{0, data.length - 1};
  for (var i = 0; i < data.length; i += stride) {
    final end = math.min(i + stride, data.length);
    for (final metric in EnvironmentalMetric.values) {
      var minIndex = i, maxIndex = i;
      for (var j = i + 1; j < end; j++) {
        if (metric.value(data[j]) < metric.value(data[minIndex])) {
          minIndex = j;
        }
        if (metric.value(data[j]) > metric.value(data[maxIndex])) {
          maxIndex = j;
        }
      }
      indices.add(minIndex);
      indices.add(maxIndex);
    }
  }
  return indices.toList()..sort();
}

class _Range {
  _Range(List<Measurement> data, this.metric) {
    minimum = maximum = metric.value(data.first);
    for (final row in data.skip(1)) {
      final value = metric.value(row);
      if (value < minimum) minimum = value;
      if (value > maximum) maximum = value;
    }
  }
  final EnvironmentalMetric metric;
  late double minimum, maximum;
  double normalized(Measurement m) => maximum == minimum
      ? .5
      : (metric.value(m) - minimum) / (maximum - minimum);
}

Color _seriesColor(EnvironmentalMetric metric) => switch (metric) {
  EnvironmentalMetric.uv => WebColors.purple,
  EnvironmentalMetric.temperature => WebColors.green,
  EnvironmentalMetric.humidity => WebColors.blue,
};

class _Legend extends StatelessWidget {
  const _Legend({required this.metric, required this.range});
  final EnvironmentalMetric metric;
  final _Range range;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 20,
        height: 3,
        decoration: BoxDecoration(
          color: _seriesColor(metric),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 7),
      Text(
        '${metric.label}: ${range.minimum.toStringAsFixed(2)}–${range.maximum.toStringAsFixed(2)} ${metric.unit}',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: WebColors.ink,
        ),
      ),
    ],
  );
}

class _MultiLinePainter extends CustomPainter {
  _MultiLinePainter(this.data, this.ranges, this.indices, this.selected);
  final List<Measurement> data;
  final Map<EnvironmentalMetric, _Range> ranges;
  final List<int> indices;
  final int? selected;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 42.0, right = 16.0, top = 12.0, bottom = 18.0;
    final width = math.max(1.0, size.width - left - right);
    final height = math.max(1.0, size.height - top - bottom);
    final first = data.first.createdAt.millisecondsSinceEpoch;
    final span = math.max(
      1,
      data.last.createdAt.millisecondsSinceEpoch - first,
    );
    double x(int index) =>
        left +
        width * (data[index].createdAt.millisecondsSinceEpoch - first) / span;
    double y(int index, EnvironmentalMetric metric) =>
        top + height * (1 - ranges[metric]!.normalized(data[index]));
    for (var tick = 0; tick <= 4; tick++) {
      final lineY = top + height * tick / 4;
      canvas.drawLine(
        Offset(left, lineY),
        Offset(left + width, lineY),
        Paint()..color = const Color(0xffe9edf2),
      );
      final label = TextPainter(
        text: TextSpan(
          text: '${100 - tick * 25}',
          style: const TextStyle(fontSize: 10, color: WebColors.muted),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(3, lineY - 6));
    }
    for (final metric in EnvironmentalMetric.values) {
      final color = _seriesColor(metric);
      final path = Path()..moveTo(x(indices.first), y(indices.first, metric));
      for (final index in indices.skip(1)) {
        path.lineTo(x(index), y(index, metric));
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeJoin = StrokeJoin.round,
      );
      final dotStride = math.max(1, (indices.length / 30).ceil());
      for (var i = 0; i < indices.length; i += dotStride) {
        canvas.drawCircle(
          Offset(x(indices[i]), y(indices[i], metric)),
          2.8,
          Paint()..color = color,
        );
      }
    }
    if (selected != null && selected! < data.length) {
      final position = x(selected!);
      canvas.drawLine(
        Offset(position, top),
        Offset(position, top + height),
        Paint()..color = WebColors.muted.withValues(alpha: .4),
      );
      for (final metric in EnvironmentalMetric.values) {
        canvas.drawCircle(
          Offset(position, y(selected!, metric)),
          5.5,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          Offset(position, y(selected!, metric)),
          3.5,
          Paint()..color = _seriesColor(metric),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_MultiLinePainter old) =>
      old.data != data ||
      old.selected != selected ||
      old.ranges != ranges ||
      old.indices != indices;
}

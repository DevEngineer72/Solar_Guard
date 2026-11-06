import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design/app_tokens.dart';
import '../../domain/models/environment_summary.dart';
import '../../domain/models/measurement.dart';
import 'ui.dart';

Color metricColor(EnvironmentalMetric metric) => switch (metric) {
  EnvironmentalMetric.uv => AppColors.navy,
  EnvironmentalMetric.temperature => const Color(0xffad4e00),
  EnvironmentalMetric.humidity => const Color(0xff007d91),
};

class EnvironmentChart extends StatefulWidget {
  const EnvironmentChart({
    super.key,
    required this.data,
    required this.metric,
    this.height = 220,
  });
  final List<Measurement> data;
  final EnvironmentalMetric metric;
  final double height;
  @override
  State<EnvironmentChart> createState() => _EnvironmentChartState();
}

class _EnvironmentChartState extends State<EnvironmentChart> {
  int? _selected;
  void _select(double x, double width) {
    final data = widget.data;
    if (data.length < 2) return;
    final ratio = ((x - 42) / math.max(1, width - 54)).clamp(0.0, 1.0);
    final first = data.first.createdAt.millisecondsSinceEpoch;
    final target =
        first + (data.last.createdAt.millisecondsSinceEpoch - first) * ratio;
    var lo = 0, hi = data.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) ~/ 2;
      if (data[mid].createdAt.millisecondsSinceEpoch < target) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    if (lo > 0 &&
        (target - data[lo - 1].createdAt.millisecondsSinceEpoch).abs() <
            (target - data[lo].createdAt.millisecondsSinceEpoch).abs()) {
      lo--;
    }
    if (_selected != lo) setState(() => _selected = lo);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    if (data.isEmpty) {
      return const StateNotice(
        icon: Icons.timeline,
        title: 'Sin mediciones',
        message: 'No hay datos para dibujar este período.',
      );
    }
    final index = (_selected ?? data.length - 1).clamp(0, data.length - 1);
    final selected = data[index];
    final metric = widget.metric;
    final color = metricColor(metric);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                metric.label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              StatusPill(
                '${data.length} mediciones',
                color: color,
                icon: Icons.timeline,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Toca o mueve el cursor para explorar.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) => MouseRegion(
              cursor: SystemMouseCursors.precise,
              onHover: (event) =>
                  _select(event.localPosition.dx, constraints.maxWidth),
              child: GestureDetector(
                onTapDown: (event) =>
                    _select(event.localPosition.dx, constraints.maxWidth),
                child: Semantics(
                  label:
                      'Gráfico de ${metric.label}. Consulta cada medición con el control inferior.',
                  child: SizedBox(
                    height: widget.height,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _ChartPainter(data, metric, color, index),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                formatDate(data.first.createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
              Text(
                formatDate(data.last.createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${metric.value(selected).toStringAsFixed(2)} ${metric.unit} · ${formatDate(selected.createdAt)}',
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
          if (data.length > 1)
            Slider(
              value: index.toDouble(),
              max: (data.length - 1).toDouble(),
              divisions: math.min(data.length - 1, 1000),
              label:
                  '${metric.value(selected).toStringAsFixed(2)} ${metric.unit}',
              semanticFormatterCallback: (value) {
                final m = data[value.round()];
                return '${formatDate(m.createdAt)}, ${metric.value(m).toStringAsFixed(2)} ${metric.unit}';
              },
              onChanged: (value) => setState(() => _selected = value.round()),
            ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.data, this.metric, this.color, this.selected);
  final List<Measurement> data;
  final EnvironmentalMetric metric;
  final Color color;
  final int selected;
  @override
  void paint(Canvas canvas, Size size) {
    final summary = MetricSummary(data, metric);
    final minY = metric == EnvironmentalMetric.temperature
        ? (summary.minimum - 2).floorToDouble()
        : 0.0;
    final maxY = math.max(
      minY + 1,
      (summary.maximum + (metric == EnvironmentalMetric.uv ? 1 : 2))
          .ceilToDouble(),
    );
    const left = 42.0, top = 8.0;
    final w = math.max(1.0, size.width - left - 12), h = size.height - 20;
    final start = data.first.createdAt.millisecondsSinceEpoch;
    final duration = data.last.createdAt.millisecondsSinceEpoch - start;
    Offset point(int i) => Offset(
      left +
          (duration == 0
                  ? .5
                  : (data[i].createdAt.millisecondsSinceEpoch - start) /
                        duration) *
              w,
      top + h * (1 - (metric.value(data[i]) - minY) / (maxY - minY)),
    );
    for (var i = 0; i < 5; i++) {
      final y = top + h * i / 4;
      canvas.drawLine(
        Offset(left, y),
        Offset(left + w, y),
        Paint()..color = AppColors.border,
      );
      final label = TextPainter(
        text: TextSpan(
          text: (maxY - (maxY - minY) * i / 4).toStringAsFixed(1),
          style: const TextStyle(color: AppColors.muted, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 38);
      label.paint(canvas, Offset(0, y - 6));
    }
    // Conserva mínimos/máximos por bloque; el cálculo estadístico usa todo.
    final indices = <int>{0, data.length - 1};
    final bucket = math.max(1, (data.length / 200).ceil());
    for (var i = 0; i < data.length; i += bucket) {
      var low = i, high = i;
      for (var j = i; j < math.min(data.length, i + bucket); j++) {
        if (metric.value(data[j]) < metric.value(data[low])) low = j;
        if (metric.value(data[j]) > metric.value(data[high])) high = j;
      }
      indices.addAll([low, high]);
    }
    final sorted = indices.toList()..sort();
    final line = Path()..moveTo(point(sorted.first).dx, point(sorted.first).dy);
    for (final i in sorted.skip(1)) {
      final p = point(i);
      line.lineTo(p.dx, p.dy);
    }
    final fill = Path.from(line)
      ..lineTo(point(sorted.last).dx, top + h)
      ..lineTo(point(sorted.first).dx, top + h)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: .16), color.withValues(alpha: .01)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
    final p = point(selected);
    canvas.drawLine(
      Offset(p.dx, top),
      Offset(p.dx, top + h),
      Paint()..color = color.withValues(alpha: .25),
    );
    canvas.drawCircle(p, 6, Paint()..color = Colors.white);
    canvas.drawCircle(p, 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.data != data || old.metric != metric || old.selected != selected;
}

class SummaryCards extends StatelessWidget {
  const SummaryCards({super.key, required this.data});
  final List<Measurement> data;
  @override
  Widget build(BuildContext context) => AdaptiveCards(
    children: [
      for (final metric in EnvironmentalMetric.values)
        Builder(
          builder: (context) {
            final summary = MetricSummary(data, metric);
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: metricColor(metric),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${summary.average.toStringAsFixed(2)} ${metric.unit}',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'Promedio de las mediciones',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      Text(
                        'Mín. ${summary.minimum.toStringAsFixed(2)} ${metric.unit}',
                      ),
                      Text(
                        'Máx. ${summary.maximum.toStringAsFixed(2)} ${metric.unit}',
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
    ],
  );
}

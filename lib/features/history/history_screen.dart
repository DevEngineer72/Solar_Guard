import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/design/app_tokens.dart';
import '../../core/export/download_csv.dart';
import '../../data/repositories/measurement_repository.dart';
import '../../domain/models/environment_summary.dart';
import '../../domain/models/measurement.dart';
import '../../domain/models/uv_risk.dart';
import '../shared/environment_chart.dart';
import '../shared/measurements_controller.dart';
import '../shared/ui.dart';

enum HistoryRange { day, week, month }

extension HistoryRangeX on HistoryRange {
  String get label => switch (this) {
    HistoryRange.day => '24 horas',
    HistoryRange.week => '7 días',
    HistoryRange.month => '30 días',
  };
  Duration get duration => Duration(
    days: switch (this) {
      HistoryRange.day => 1,
      HistoryRange.week => 7,
      HistoryRange.month => 30,
    },
  );
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.repository,
    required this.isConfigured,
  });
  final MeasurementRepository repository;
  final bool isConfigured;
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryRange _range = HistoryRange.week;
  EnvironmentalMetric _metric = EnvironmentalMetric.uv;
  DateTimeRange? _dates;
  MeasurementsController? _controller;
  bool _weekly = false, _compare = false;
  void _load() {
    _controller?.dispose();
    final end = _dates?.end;
    _controller = MeasurementsController(
      widget.repository,
      from: _dates?.start ?? DateTime.now().subtract(_range.duration),
      until: end == null ? null : DateTime(end.year, end.month, end.day + 1),
    )..load();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _pickDates() async {
    final dates = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
      initialDateRange: _dates,
      helpText: 'Selecciona el período',
      saveText: 'Aplicar',
    );
    if (dates != null && mounted) {
      setState(() {
        _dates = dates;
        _load();
      });
    }
  }

  void _export(List<Measurement> data) {
    try {
      downloadCsv(
        measurementsCsv(data),
        'solar-safe-${DateTime.now().millisecondsSinceEpoch}.csv',
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo descargar el archivo. Intenta nuevamente.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller!,
    builder: (context, _) {
      final controller = _controller!;
      final data = controller.measurements;
      final ready =
          widget.isConfigured &&
          !controller.isLoading &&
          controller.error == null &&
          data.isNotEmpty;
      return AppPage(
        title: 'Historial ambiental',
        subtitle: 'Explora la radiación UV, la temperatura y la humedad.',
        actions: [
          if (kIsWeb)
            OutlinedButton.icon(
              onPressed: ready ? () => _export(data) : null,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Exportar CSV'),
            ),
        ],
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilterPills<HistoryRange>(
                values: HistoryRange.values,
                selected: _dates == null ? _range : null,
                label: (v) => v.label,
                onChanged: (v) => setState(() {
                  _range = v;
                  _dates = null;
                  _load();
                }),
              ),
              if (kIsWeb)
                OutlinedButton.icon(
                  onPressed: _pickDates,
                  icon: const Icon(Icons.date_range_outlined),
                  label: Text(
                    _dates == null
                        ? 'Elegir fechas'
                        : '${formatDate(_dates!.start, time: false)} – ${formatDate(_dates!.end, time: false)}',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (!widget.isConfigured)
            const StateNotice(
              icon: Icons.timeline,
              title: 'El historial estará aquí',
              message: 'Conecta el servicio de datos para consultar las mediciones de la estación.',
            )
          else if (controller.isLoading)
            loadingPanel()
          else if (controller.error != null)
            StateNotice(
              icon: Icons.cloud_off,
              title: 'No se pudo recuperar el período completo',
              message: 'Revisa la conexión e inténtalo nuevamente.',
              action: TextButton(
                onPressed: () => setState(_load),
                child: const Text('Reintentar'),
              ),
            )
          else if (data.isEmpty)
            const StateNotice(
              icon: Icons.event_busy,
              title: 'Sin mediciones en este período',
              message: 'Prueba con otro rango de fechas.',
            )
          else ...[
            SummaryCards(data: data),
            const SizedBox(height: 16),
            Text(
              '${data.length} mediciones · ${formatDate(data.first.createdAt)} a ${formatDate(data.last.createdAt)} · Hora local',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilterPills<EnvironmentalMetric>(
                  values: EnvironmentalMetric.values,
                  selected: _metric,
                  label: (m) => m.label,
                  onChanged: (m) => setState(() => _metric = m),
                ),
                if (kIsWeb)
                  FilterChip(
                    label: const Text('Comparar las tres variables'),
                    selected: _compare,
                    onSelected: (v) => setState(() => _compare = v),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (_compare && kIsWeb)
              AdaptiveCards(
                minimumWidth: 300,
                children: [
                  for (final metric in EnvironmentalMetric.values)
                    EnvironmentChart(
                      key: ValueKey(metric),
                      data: data,
                      metric: metric,
                      height: 180,
                    ),
                ],
              )
            else
              EnvironmentChart(
                key: ValueKey((_range, _dates, _metric)),
                data: data,
                metric: _metric,
              ),
            const SizedBox(height: 28),
            if (kIsWeb) ...[
              Row(
                children: [
                  const Expanded(
                    child: SectionTitle('Comparación por período'),
                  ),
                  Switch(
                    value: _weekly,
                    onChanged: (v) => setState(() => _weekly = v),
                  ),
                  const Text('Semanas'),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Promedios de muestras disponibles. Los huecos de recepción no implican valores cero ni cobertura continua.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              _ComparisonTable(data: data, weekly: _weekly),
              const SizedBox(height: 24),
              _PeakCard(data: data),
            ] else ...[
              const SectionTitle('Últimas mediciones del período'),
              const SizedBox(height: 16),
              for (final m in data.reversed.take(10))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 20,
                      runSpacing: 12,
                      children: [
                        Text(
                          formatDate(m.createdAt),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'UV ${m.uv.toStringAsFixed(2)} · ${riskForUv(m.uv).label}',
                          style: TextStyle(
                            color: riskForUv(m.uv).color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text('${m.temperature.toStringAsFixed(2)} °C'),
                        Text('${m.humidity.toStringAsFixed(2)} %'),
                      ],
                    ),
                  ),
                ),
              if (data.length > 10)
                Text(
                  'Se muestran los 10 registros más recientes de ${data.length}.',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
            ],
          ],
        ],
      );
    },
  );
}

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({required this.data, required this.weekly});
  final List<Measurement> data;
  final bool weekly;
  @override
  Widget build(BuildContext context) {
    final groups = groupMeasurements(data, weekly: weekly);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Desplaza la tabla horizontalmente para ver todas las variables.',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text(weekly ? 'Semana del' : 'Día')),
                const DataColumn(label: Text('Muestras')),
                for (final metric in EnvironmentalMetric.values)
                  DataColumn(label: Text('${metric.label} ${metric.unit}')),
                const DataColumn(label: Text('UV máximo')),
              ],
              rows: [
                for (final entry in groups.entries)
                  DataRow(
                    cells: [
                      DataCell(Text(formatDate(entry.key, time: false))),
                      DataCell(Text('${entry.value.length}')),
                      for (final metric in EnvironmentalMetric.values)
                        DataCell(
                          Text(
                            MetricSummary(
                              entry.value,
                              metric,
                            ).average.toStringAsFixed(2),
                          ),
                        ),
                      DataCell(
                        Text(
                          MetricSummary(
                            entry.value,
                            EnvironmentalMetric.uv,
                          ).maximum.toStringAsFixed(2),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeakCard extends StatelessWidget {
  const _PeakCard({required this.data});
  final List<Measurement> data;
  @override
  Widget build(BuildContext context) {
    final uv = MetricSummary(data, EnvironmentalMetric.uv);
    final high = data.where((m) => m.uv >= 8).length;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mayor radiación del período',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
          const SizedBox(height: 12),
          Text(
            'UV ${uv.maximum.toStringAsFixed(2)} · ${formatDate(uv.peakAt)}',
            style: const TextStyle(fontSize: 18, color: AppColors.navy),
          ),
          const SizedBox(height: 8),
          Text('$high de ${data.length} mediciones con UV muy alto o extremo.'),
          const SizedBox(height: 8),
          const Text(
            'Datos registrados, no un pronóstico para tu próxima visita.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

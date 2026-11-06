import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/design/app_tokens.dart';
import '../../data/repositories/measurement_repository.dart';
import '../../domain/models/environment_summary.dart';
import '../../domain/models/measurement.dart';
import '../../domain/models/uv_risk.dart';
import '../shared/environment_chart.dart';
import '../shared/measurements_controller.dart';
import '../shared/station_context.dart';
import '../shared/ui.dart';
import 'web_dashboard.dart';
import 'web_dashboard_history_controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.repository,
    required this.isConfigured,
  });
  final MeasurementRepository repository;
  final bool isConfigured;
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final LatestMeasurementController _controller;
  WebDashboardHistoryController? _history;
  Duration _webPeriod = const Duration(hours: 24);

  void _changeWebPeriod(Duration period) {
    if (_webPeriod == period) return;
    setState(() {
      _webPeriod = period;
      _history?.dispose();
      _history = WebDashboardHistoryController(widget.repository, period)
        ..load();
      final latest = _controller.measurement;
      if (latest != null) _history!.addLatest(latest);
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = LatestMeasurementController(widget.repository)..load();
    _controller.addListener(_syncLatest);
    if (kIsWeb) {
      _history = WebDashboardHistoryController(widget.repository, _webPeriod)
        ..load();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_syncLatest);
    _controller.dispose();
    _history?.dispose();
    super.dispose();
  }

  void _syncLatest() {
    if (kIsWeb && _controller.error == null) {
      final latest = _controller.measurement;
      if (latest != null) _history?.addLatest(latest);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final station = StationContext.of(context);
      final m = _controller.measurement;
      if (kIsWeb) {
        return WebDashboard(
          measurement: m,
          history: _history,
          period: _webPeriod,
          onPeriodChanged: _changeWebPeriod,
          isConfigured: widget.isConfigured,
          isLoading: _controller.isLoading,
          error: _controller.error,
          onRefresh: () {
            _controller.load();
            _history?.load();
          },
        );
      }
      return AppPage(
        title: kIsWeb ? 'Panorama ambiental' : 'Tu día al aire libre',
        subtitle: '${station.stationName} · ${station.stationLocation}',
        actions: [
          if (m != null && _controller.error == null)
            StatusPill(
              'Último envío: ${formatDate(m.createdAt, seconds: true)}',
              color: AppColors.green,
              icon: Icons.schedule,
            ),
        ],
        children: [
          if (!widget.isConfigured)
            const StateNotice(
              icon: Icons.sensors_off,
              title: 'Esperando conexión con la estación',
              message: 'Las mediciones aparecerán cuando el servicio de datos esté disponible.',
            )
          else if (_controller.isLoading)
            loadingPanel()
          else if (_controller.error != null)
            StateNotice(
              icon: Icons.cloud_off,
              title: 'No podemos confirmar las condiciones actuales',
              message: 'No se pudieron leer mediciones válidas. Revisa la conexión e inténtalo de nuevo.',
              action: TextButton(
                onPressed: _controller.load,
                child: const Text('Reintentar'),
              ),
            )
          else if (m == null)
            const StateNotice(
              icon: Icons.wb_sunny_outlined,
              title: 'La primera medición está por llegar',
              message: 'Aquí verás el índice UV, la temperatura y la humedad de la estación.',
            )
          else ...[
            _DashboardData(measurement: m),
            if (_history != null) ...[
              const SizedBox(height: 28),
              const SectionTitle('Evolución de las últimas 24 horas'),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _history!,
                builder: (context, _) {
                  if (_history!.isLoading) return loadingPanel();
                  if (_history!.error != null) {
                    return const StateNotice(
                      icon: Icons.timeline,
                      title: 'Evolución no disponible',
                      message: 'No se pudo recuperar el historial.',
                    );
                  }
                  return EnvironmentChart(
                    data: _history!.measurements,
                    metric: EnvironmentalMetric.uv,
                  );
                },
              ),
            ],
          ],
        ],
      );
    },
  );
}

class FreshnessPill extends StatelessWidget {
  const FreshnessPill({super.key, required this.measurement});
  final Measurement measurement;
  @override
  Widget build(BuildContext context) {
    final status = measurementFreshness(
      measurement,
      DateTime.now(),
      StationContext.of(context).maxMeasurementAge,
    );
    return switch (status) {
      MeasurementFreshness.recent => const StatusPill(
        'Datos recientes',
        color: AppColors.green,
        icon: Icons.sensors,
      ),
      MeasurementFreshness.stale => const StatusPill(
        'Sin actualización',
        color: AppColors.red,
        icon: Icons.schedule,
      ),
      MeasurementFreshness.future => const StatusPill(
        'Fecha por verificar',
        color: AppColors.red,
        icon: Icons.error_outline,
      ),
      MeasurementFreshness.unknown => const StatusPill(
        'Última medición recibida',
        icon: Icons.schedule,
      ),
    };
  }
}

class _DashboardData extends StatelessWidget {
  const _DashboardData({required this.measurement});
  final Measurement measurement;
  @override
  Widget build(BuildContext context) {
    final risk = riskForUv(measurement.uv);
    final freshness = measurementFreshness(
      measurement,
      DateTime.now(),
      StationContext.of(context).maxMeasurementAge,
    );
    final current = freshness == MeasurementFreshness.recent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!current) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.softBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              freshness == MeasurementFreshness.stale
                  ? 'La última lectura no es reciente. Las condiciones de la playa pueden haber cambiado.'
                  : freshness == MeasurementFreshness.future
                  ? 'La estación envió una fecha futura. No podemos confirmar la actualidad de estos datos.'
                  : 'Última lectura registrada: ${formatDate(measurement.createdAt)}.',
              style: const TextStyle(color: AppColors.navy, height: 1.5),
            ),
          ),
          const SizedBox(height: 20),
        ] else if (risk.index >= UvRisk.veryHigh.index) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.redLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'UV ${risk.label.toLowerCase()}. Reduce la exposición y busca sombra.',
                    style: const TextStyle(
                      color: AppColors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        AdaptivePanels(
          primaryFlex: 1,
          secondaryFlex: 1,
          breakpoint: 820,
          primary: UvHero(measurement: measurement, current: current),
          secondary: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdaptiveCards(
                minimumWidth: 150,
                maxColumns: 2,
                children: [
                  _MetricCard(
                    'Temperatura',
                    '${measurement.temperature.toStringAsFixed(2)} °C',
                    Icons.thermostat_outlined,
                    const Color(0xffad4e00),
                  ),
                  _MetricCard(
                    'Humedad relativa',
                    '${measurement.humidity.toStringAsFixed(2)} %',
                    Icons.water_drop_outlined,
                    const Color(0xff007d91),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              RiskScale(risk: risk),
              const SizedBox(height: 20),
              RecommendationsPanel(risk: risk, current: current),
            ],
          ),
        ),
      ],
    );
  }
}

class UvHero extends StatelessWidget {
  const UvHero({super.key, required this.measurement, required this.current});
  final Measurement measurement;
  final bool current;
  @override
  Widget build(BuildContext context) {
    final risk = riskForUv(measurement.uv);
    return AppCard(
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text(
            current ? 'ÍNDICE UV ACTUAL' : 'ÚLTIMO ÍNDICE UV',
            style: const TextStyle(
              letterSpacing: 1.5,
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        value: (measurement.uv / 11).clamp(0, 1),
                        strokeWidth: 18,
                        strokeCap: StrokeCap.round,
                        backgroundColor: AppColors.border,
                        color: risk.color,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(42),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        measurement.uv.toStringAsFixed(2),
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 76,
                          fontWeight: FontWeight.w800,
                          color: risk.color,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          StatusPill(
            risk.label,
            color: risk.color,
            icon: Icons.wb_sunny_outlined,
          ),
          const SizedBox(height: 24),
          Text(
            'Medido el ${formatDate(measurement.createdAt)}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.label, this.value, this.icon, this.color);
  final String label, value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class RiskScale extends StatelessWidget {
  const RiskScale({super.key, required this.risk});
  final UvRisk risk;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Escala de riesgo UV',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (final value in UvRisk.values)
              Expanded(
                child: Container(
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: value.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            for (final value in UvRisk.values)
              Text(
                '${value.label.toLowerCase()} ${value.range}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: value == risk ? FontWeight.w800 : FontWeight.w400,
                  color: AppColors.muted,
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class RecommendationsPanel extends StatelessWidget {
  const RecommendationsPanel({
    super.key,
    required this.risk,
    this.current = false,
  });
  final UvRisk risk;
  final bool current;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿Cómo protegerte?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          current
              ? 'Para el nivel UV registrado ahora'
              : 'Guía para un nivel UV ${risk.label.toLowerCase()}',
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        for (final advice in risk.recommendations)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: AppColors.navy,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(advice, style: const TextStyle(height: 1.5)),
                ),
              ],
            ),
          ),
        const Divider(),
        const Text(
          'Protección solar · Guía general OMS / EPA',
          style: TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';

import '../../domain/models/measurement.dart';
import '../../domain/models/uv_risk.dart';
import '../shared/station_context.dart';
import '../shared/ui.dart';
import 'web_environment_chart.dart';
import 'web_dashboard_history_controller.dart';
import 'mascota_fuego_widget.dart';

/// Distribución de escritorio basada en design/web/DashBoard.png.
/// Los bloques usan únicamente campos presentes en la tabla de mediciones.
class WebDashboard extends StatefulWidget {
  const WebDashboard({
    super.key,
    required this.measurement,
    required this.history,
    required this.period,
    required this.onPeriodChanged,
    required this.isConfigured,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
  });

  final Measurement? measurement;
  final WebDashboardHistoryController? history;
  final Duration period;
  final ValueChanged<Duration> onPeriodChanged;
  final bool isConfigured;
  final bool isLoading;
  final Object? error;
  final VoidCallback onRefresh;

  @override
  State<WebDashboard> createState() => _WebDashboardState();
}

class _WebDashboardState extends State<WebDashboard> {
  double _scrollOffset = 0;
  @override
  Widget build(BuildContext context) {
    final station = StationContext.of(context);
    final measurement = widget.measurement;
    final history = widget.history;
    final period = widget.period;
    final onPeriodChanged = widget.onPeriodChanged;
    final error = widget.error;
    final isConfigured = widget.isConfigured;
    final isLoading = widget.isLoading;
    final onRefresh = widget.onRefresh;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification) {
              setState(() => _scrollOffset = notification.metrics.pixels);
            }
            return false;
          },
          child: ListView(
            padding: EdgeInsets.all(wide ? 24 : 16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dashboard',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: WebColors.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Resumen de ${station.stationName}',
                          style: const TextStyle(
                            color: WebColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (measurement != null && error == null)
                    StatusPill(
                      'Último envío: ${formatDate(measurement.createdAt, seconds: true)}',
                      color: WebColors.green,
                      icon: Icons.schedule,
                    ),
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: 'Actualizar mediciones',
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              if (!isConfigured)
                const StateNotice(
                  icon: Icons.sensors_off,
                  title: 'Estación sin configurar',
                  message: 'Configura Supabase para ver las mediciones.',
                )
              else if (isLoading)
                loadingPanel()
              else if (error != null)
                StateNotice(
                  icon: Icons.cloud_off,
                  title: 'No se pudieron cargar las mediciones',
                  message: 'Comprueba la conexión y vuelve a intentarlo.',
                  action: TextButton(
                    onPressed: onRefresh,
                    child: const Text('Reintentar'),
                  ),
                )
              else if (measurement == null)
                const StateNotice(
                  icon: Icons.timeline,
                  title: 'Todavía no hay mediciones',
                  message: 'Las lecturas de la estación aparecerán aquí.',
                )
              else ...[
                _Metrics(measurement: measurement),
                const SizedBox(height: 22),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _ScrollReveal(
                          offset: _scrollOffset,
                          start: 250,
                          child: _Trends(
                            history: history,
                            period: period,
                            onPeriodChanged: onPeriodChanged,
                          ),
                        ),
                      ),
                      const SizedBox(width: 22),
                      Expanded(
                        child: _ScrollReveal(
                          offset: _scrollOffset,
                          start: 250,
                          child: _MascotaUvPanel(measurement: measurement),
                        ),
                      ),
                    ],
                  )
                else ...[
                  _ScrollReveal(
                    offset: _scrollOffset,
                    start: 250,
                    child: _Trends(
                      history: history,
                      period: period,
                      onPeriodChanged: onPeriodChanged,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ScrollReveal(
                    offset: _scrollOffset,
                    start: 400,
                    child: _MascotaUvPanel(measurement: measurement),
                  ),
                ],
                const SizedBox(height: 18),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _Readings(
                          history: history,
                          fallback: measurement,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(child: _Risk(measurement: measurement)),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _ScrollReveal(
                          offset: _scrollOffset,
                          start: 500,
                          child: _Alerts(measurement: measurement),
                        ),
                      ),
                    ],
                  )
                else ...[
                  _Readings(history: history, fallback: measurement),
                  const SizedBox(height: 18),
                  _Risk(measurement: measurement),
                  const SizedBox(height: 18),
                  _ScrollReveal(
                    offset: _scrollOffset,
                    start: 720,
                    child: _Alerts(measurement: measurement),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ScrollReveal extends StatelessWidget {
  const _ScrollReveal({
    required this.offset,
    required this.start,
    required this.child,
  });
  final double offset, start;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final progress = reduced
        ? 1.0
        : ((offset + MediaQuery.sizeOf(context).height - start) / 220).clamp(
            0.0,
            1.0,
          );
    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset(0, 18 * (1 - progress)),
        child: child,
      ),
    );
  }
}

abstract final class WebColors {
  static const ink = Color(0xff182033);
  static const muted = Color(0xff647084);
  static const green = Color(0xff17994d);
  static const blue = Color(0xff3764d7);
  static const purple = Color(0xff8260b6);
  static const amber = Color(0xffe9a922);
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.measurement});
  final Measurement measurement;
  @override
  Widget build(BuildContext context) => AdaptiveCards(
    minimumWidth: 175,
    maxColumns: 3,
    children: [
      _Metric(
        'Índice UV',
        measurement.uv.toStringAsFixed(2),
        'design/logos_temperatura/radiacion_uv.png',
        WebColors.purple,
      ),
      _Metric(
        'Temperatura',
        '${measurement.temperature.toStringAsFixed(2)} °C',
        'design/logos_temperatura/temperatura.png',
        WebColors.green,
      ),
      _Metric(
        'Humedad',
        '${measurement.humidity.toStringAsFixed(2)} %',
        'design/logos_temperatura/humedad.png',
        WebColors.blue,
      ),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.logoPath, this.color);
  final String label, value;
  final String logoPath;
  final Color color;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 480),
    builder: (context, progress, child) => Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset(0, 14 * (1 - progress)),
        child: child,
      ),
    ),
    child: AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  logoPath,
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: WebColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 300),
            child: Text(
              value,
              key: ValueKey(value),
              style: const TextStyle(
                color: WebColors.ink,
                fontSize: 27,
                fontWeight: FontWeight.w700,
                fontFamily: 'JetBrainsMono',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Trends extends StatelessWidget {
  const _Trends({
    required this.history,
    required this.period,
    required this.onPeriodChanged,
  });
  final WebDashboardHistoryController? history;
  final Duration period;
  final ValueChanged<Duration> onPeriodChanged;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: history ?? Listenable.merge([]),
    builder: (context, _) {
      return WebEnvironmentChart(
        data: history?.measurements ?? const [],
        period: period,
        onPeriodChanged: onPeriodChanged,
        isLoading: history?.isLoading ?? true,
        error: history?.error,
      );
    },
  );
}

class _MascotaUvPanel extends StatelessWidget {
  const _MascotaUvPanel({required this.measurement});
  final Measurement measurement;
  @override
  Widget build(BuildContext context) {
    final risk = riskForUv(measurement.uv);
    return AppCard(
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Mascota solar',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: WebColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) => MascotaFuegoWidget(
              width: constraints.maxWidth,
              height: constraints.maxWidth * 9 / 16,
            ),
          ),
          Text(
            'Índice UV  ${measurement.uv.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: WebColors.ink,
            ),
          ),
          const SizedBox(height: 9),
          StatusPill(
            risk.label,
            color: risk.color,
            icon: Icons.wb_sunny_outlined,
          ),
          const SizedBox(height: 7),
          Text(
            'Haz clic en la mascota para ver una animación',
            textAlign: TextAlign.center,
            style: const TextStyle(color: WebColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _Readings extends StatelessWidget {
  const _Readings({required this.history, required this.fallback});
  final WebDashboardHistoryController? history;
  final Measurement fallback;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: history ?? Listenable.merge([]),
    builder: (context, _) {
      final values =
          history?.measurements.reversed.take(5).toList() ?? [fallback];
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lecturas recientes',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: WebColors.ink,
              ),
            ),
            const SizedBox(height: 14),
            const Row(
              children: [
                Expanded(child: Text('Hora')),
                Expanded(child: Text('UV')),
                Expanded(child: Text('Temp.')),
                Expanded(child: Text('Humedad')),
              ],
            ),
            const Divider(),
            for (final m in values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatDate(m.createdAt).split(' · ').last,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        m.uv.toStringAsFixed(2),
                        style: const TextStyle(
                          color: WebColors.purple,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${m.temperature.toStringAsFixed(2)}°',
                        style: const TextStyle(
                          color: WebColors.green,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${m.humidity.toStringAsFixed(2)}%',
                        style: const TextStyle(
                          color: WebColors.blue,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _Risk extends StatelessWidget {
  const _Risk({required this.measurement});
  final Measurement measurement;
  @override
  Widget build(BuildContext context) {
    final risk = riskForUv(measurement.uv);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Condición actual',
            style: TextStyle(fontWeight: FontWeight.w800, color: WebColors.ink),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.info_rounded, color: risk.color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Radiación UV ${risk.label.toLowerCase()}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: const Text(
              'Ver recomendaciones',
              style: TextStyle(fontSize: 13),
            ),
            children: [
              for (final advice in risk.recommendations)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      advice,
                      style: const TextStyle(
                        fontSize: 12,
                        color: WebColors.muted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Alerts extends StatelessWidget {
  const _Alerts({required this.measurement});
  final Measurement measurement;
  @override
  Widget build(BuildContext context) {
    final risk = riskForUv(measurement.uv);
    final active = risk.index >= UvRisk.high.index;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alertas',
            style: TextStyle(fontWeight: FontWeight.w800, color: WebColors.ink),
          ),
          const SizedBox(height: 14),
          StatusPill(
            'Riesgo UV ${risk.label.toLowerCase()}',
            color: risk.color,
            icon: active
                ? Icons.warning_amber_rounded
                : Icons.verified_outlined,
          ),
          const SizedBox(height: 14),
          Text(
            active
                ? 'Advertencia activa por radiación UV elevada.'
                : 'Sin advertencias UV elevadas en la última lectura.',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: WebColors.ink,
            ),
          ),
          const Divider(height: 24),
          for (final advice in risk.recommendations.take(2))
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: risk.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      advice,
                      style: const TextStyle(
                        fontSize: 12,
                        color: WebColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

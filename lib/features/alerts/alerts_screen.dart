import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../application/uv_alert_coordinator.dart';
import '../../core/design/app_tokens.dart';
import '../../data/repositories/measurement_repository.dart';
import '../../domain/models/uv_risk.dart';
import '../../domain/services/alert_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../shared/measurements_controller.dart';
import '../shared/ui.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({
    super.key,
    required this.repository,
    required this.isConfigured,
    this.notifications,
  });
  final MeasurementRepository repository;
  final bool isConfigured;
  final UvAlertCoordinator? notifications;
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late MeasurementsController _controller;
  AlertFilter _filter = AlertFilter.all;
  int _days = 7, _limit = 20;
  void _load() {
    _controller = MeasurementsController(
      widget.repository,
      from: DateTime.now().subtract(Duration(days: _days)),
    )..load();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final alerts = const AlertService()
          .derive(_controller.measurements)
          .where(
            (a) =>
                _filter == AlertFilter.all ||
                (_filter == AlertFilter.critical
                    ? a.kind == StationAlertKind.critical
                    : a.kind == StationAlertKind.preventive),
          )
          .toList();
      return AppPage(
        title: 'Alertas y protección',
        subtitle: 'Información para decidir cómo cuidarte al aire libre.',
        children: [
          if (!kIsWeb && widget.notifications != null) ...[
            _NotificationSettings(coordinator: widget.notifications!),
            const SizedBox(height: 24),
          ],
          if (kIsWeb) ...[
            const Text(
              'Advertencias derivadas de mediciones. La web muestra el registro; los avisos locales se configuran en la app.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 20),
          ],
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              FilterPills<AlertFilter>(
                values: AlertFilter.values,
                selected: _filter,
                label: (v) => switch (v) {
                  AlertFilter.all => 'Todas',
                  AlertFilter.critical => 'Críticas',
                  AlertFilter.preventive => 'Preventivas',
                },
                onChanged: (v) => setState(() {
                  _filter = v;
                  _limit = 20;
                }),
              ),
              FilterPills<int>(
                values: const [1, 7, 30],
                selected: _days,
                label: (v) => v == 1 ? '24 horas' : '$v días',
                onChanged: (v) => setState(() {
                  _days = v;
                  _limit = 20;
                  _controller.dispose();
                  _load();
                }),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (!widget.isConfigured)
            const StateNotice(
              icon: Icons.notifications_none,
              title: 'Esperando mediciones',
              message: 'Las advertencias se mostrarán cuando la estación envíe información.',
            )
          else if (_controller.isLoading)
            loadingPanel()
          else if (_controller.error != null)
            StateNotice(
              icon: Icons.cloud_off,
              title: 'No se pudieron actualizar las alertas',
              message: 'No podemos confirmar las condiciones de la estación.',
              action: TextButton(
                onPressed: _controller.load,
                child: const Text('Reintentar'),
              ),
            )
          else ...[
            if (_controller.measurements.isNotEmpty) ...[
              RecommendationsPanel(
                risk: riskForUv(_controller.measurements.last.uv),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              'Registro derivado · ${alerts.length} advertencias',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cada registro corresponde a una medición UV ≥ 3. No confirma el envío de una notificación.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            if (alerts.isEmpty)
              StateNotice(
                icon: Icons.notifications_none,
                title: 'Sin advertencias en esta categoría',
                message: _controller.measurements.isEmpty
                    ? 'No hay mediciones disponibles en el período.'
                    : 'Las mediciones disponibles no generan advertencias para este filtro.',
              ),
            AdaptiveCards(
              minimumWidth: 360,
              maxColumns: 2,
              children: [
                for (final alert in alerts.take(_limit))
                  _AlertCard(alert: alert),
              ],
            ),
            if (_limit < alerts.length)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: OutlinedButton(
                  onPressed: () => setState(() => _limit += 20),
                  child: const Text('Mostrar más registros'),
                ),
              ),
          ],
        ],
      );
    },
  );
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});
  final StationAlert alert;
  @override
  Widget build(BuildContext context) {
    final color = alert.kind == StationAlertKind.critical
        ? AppColors.red
        : const Color(0xff765400);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, color: color),
              Text(
                'UV ${alert.value}',
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
              Text(
                formatDate(alert.createdAt),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            alert.title,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(alert.message, style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }
}

class _NotificationSettings extends StatelessWidget {
  const _NotificationSettings({required this.coordinator});
  final UvAlertCoordinator coordinator;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: coordinator,
    builder: (context, _) => AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Avisos de protección solar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              coordinator.maxAge == null
                  ? 'Disponible al confirmar la frecuencia de actualización de la estación.'
                  : 'Avisos locales de UV ≥ 3 mientras la app está en ejecución. Requiere permiso del dispositivo.',
            ),
            value: coordinator.enabled,
            onChanged: coordinator.busy || coordinator.maxAge == null
                ? null
                : coordinator.setEnabled,
          ),
          if (coordinator.error != null)
            Text(
              coordinator.error!,
              style: const TextStyle(color: AppColors.red),
            ),
        ],
      ),
    ),
  );
}

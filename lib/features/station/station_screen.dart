import 'package:flutter/material.dart';

import '../../core/design/app_tokens.dart';
import '../../data/repositories/measurement_repository.dart';
import '../dashboard/dashboard_screen.dart';
import '../shared/measurements_controller.dart';
import '../shared/station_context.dart';
import '../shared/ui.dart';

class StationScreen extends StatefulWidget {
  const StationScreen({
    super.key,
    required this.repository,
    required this.isConfigured,
  });
  final MeasurementRepository repository;
  final bool isConfigured;
  @override
  State<StationScreen> createState() => _StationScreenState();
}

class _StationScreenState extends State<StationScreen> {
  late final LatestMeasurementController _controller;
  @override
  void initState() {
    super.initState();
    _controller = LatestMeasurementController(widget.repository)..load();
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
      final config = StationContext.of(context);
      final m = _controller.measurement;
      return AppPage(
        title: 'Nuestra estación',
        subtitle:
            'Conoce el sistema que observa las condiciones de tu entorno.',
        children: [
          AdaptivePanels(
            primaryFlex: 1,
            secondaryFlex: 1,
            primary: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.sensors, color: AppColors.navy, size: 36),
                  const SizedBox(height: 16),
                  Text(
                    config.stationName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!widget.isConfigured)
                    const Text('Servicio de datos pendiente de conexión.')
                  else if (_controller.isLoading)
                    const LinearProgressIndicator()
                  else if (_controller.error != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No se pudo comprobar la última medición.',
                          style: TextStyle(color: AppColors.red),
                        ),
                        TextButton(
                          onPressed: _controller.load,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    )
                  else if (m == null)
                    const StatusPill(
                      'Aún no hay mediciones',
                      icon: Icons.sensors_off,
                    )
                  else ...[
                    FreshnessPill(measurement: m),
                    const SizedBox(height: 24),
                    _Info('Identificador de la estación', m.stationId),
                    const SizedBox(height: 20),
                    _Info(
                      'Última medición registrada',
                      formatDate(m.createdAt),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'La recepción de datos no confirma por sí sola que todos los sensores estén funcionando.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            secondary: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ubicación',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    decoration: BoxDecoration(
                      color: AppColors.softBlue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      size: 64,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    config.stationLocation,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Estación única de monitoreo ambiental.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          const SectionTitle('Tecnología al servicio de tu bienestar'),
          const SizedBox(height: 16),
          const AdaptiveCards(
            minimumWidth: 180,
            maxColumns: 4,
            children: [
              _Component(
                Icons.wb_sunny_outlined,
                'Sensor UV',
                'Radiación ultravioleta',
              ),
              _Component(
                Icons.thermostat_outlined,
                'Temperatura',
                'Temperatura del ambiente',
              ),
              _Component(
                Icons.water_drop_outlined,
                'Humedad',
                'Humedad relativa del aire',
              ),
              _Component(
                Icons.memory_outlined,
                'ESP32',
                'Envío de mediciones por Wi-Fi',
              ),
            ],
          ),
          const SizedBox(height: 28),
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solar Safe Smart Station',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Convertimos las mediciones ambientales en información sencilla para ayudarte a planificar actividades al aire libre y reducir los riesgos de exposición solar.',
                  style: TextStyle(height: 1.6),
                ),
                SizedBox(height: 12),
                Text(
                  'Los datos describen condiciones registradas en la estación. No sustituyen un pronóstico ni representan todas las zonas de la playa.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    ],
  );
}

class _Component extends StatelessWidget {
  const _Component(this.icon, this.title, this.description);
  final IconData icon;
  final String title, description;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.navy, size: 30),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: AppColors.muted,
          ),
        ),
      ],
    ),
  );
}

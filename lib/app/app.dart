import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/design/app_theme.dart';
import '../features/shared/station_context.dart';

import '../application/uv_alert_coordinator.dart';
import '../core/config/app_config.dart';
import '../data/repositories/measurement_repository.dart';
import '../features/shell/app_shell.dart';

/// Raíz de la aplicación: configura el tema y el ciclo de vida global.
class SolarGuardApp extends StatefulWidget {
  const SolarGuardApp({
    super.key,
    required this.repository,
    required this.config,
    required this.uvAlertCoordinator,
  });

  final MeasurementRepository repository;
  final AppConfig config;
  final UvAlertCoordinator uvAlertCoordinator;

  @override
  State<SolarGuardApp> createState() => _SolarGuardAppState();
}

class _SolarGuardAppState extends State<SolarGuardApp> {
  @override
  void initState() {
    super.initState();
    widget.uvAlertCoordinator.start();
  }

  @override
  void dispose() {
    widget.uvAlertCoordinator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Solar Safe Smart Station',
    locale: const Locale('es'),
    supportedLocales: const [Locale('es')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    home: StationContext(
      config: widget.config,
      child: _Entrance(
        child: AppShell(
          repository: widget.repository,
          isConfigured: widget.config.isConfigured,
          notifications: widget.uvAlertCoordinator,
        ),
      ),
    ),
  );
}

class _Entrance extends StatelessWidget {
  const _Entrance({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: child,
      builder: (context, value, child) => Opacity(opacity: value, child: child),
    );
  }
}

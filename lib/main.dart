import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'application/uv_alert_coordinator.dart';
import 'core/config/app_config.dart';
import 'core/notifications/notification_service.dart';
import 'data/repositories/measurement_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    for (final font in ['Manrope', 'JetBrainsMono']) {
      yield LicenseEntryWithLineBreaks([
        font,
      ], await rootBundle.loadString('assets/fonts/$font-OFL.txt'));
    }
  });
  await dotenv.load(fileName: '.env');
  final config = AppConfig.fromEnvironment(dotenv.env);
  if (config.isConfigured) {
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabaseAnonKey,
    );
  }
  final repository = MeasurementRepository.create(config);
  final uvAlertCoordinator = UvAlertCoordinator(
    repository: repository,
    notifications: createNotificationGateway(),
    maxAge: config.maxMeasurementAge,
  );
  runApp(
    SolarGuardApp(
      repository: repository,
      config: config,
      uvAlertCoordinator: uvAlertCoordinator,
    ),
  );
}

import 'package:flutter/widgets.dart';

import '../../core/config/app_config.dart';

class StationContext extends InheritedWidget {
  const StationContext({super.key, required this.config, required super.child});
  final AppConfig config;
  static AppConfig of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StationContext>()?.config ??
      const AppConfig(
        supabaseUrl: '',
        supabaseAnonKey: '',
        measurementsTable: 'mediciones',
      );
  @override
  bool updateShouldNotify(StationContext oldWidget) =>
      config != oldWidget.config;
}

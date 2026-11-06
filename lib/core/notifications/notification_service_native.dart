import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_gateway.dart';

NotificationGateway createNotificationGateway() => _LocalNotificationGateway();

/// Adaptador para Android e iOS basado en `flutter_local_notifications`.
class _LocalNotificationGateway implements NotificationGateway {
  static const _channelId = 'uv_risk_alerts';
  static const _channelName = 'Alertas de radiación UV';
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  var _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings);
    await _requestPermissions();
    _isInitialized = true;
  }

  Future<void> _requestPermissions() async {
    // Cada sistema gestiona los permisos de forma distinta; el plugin expone
    // ambos casos para mantener esta decisión fuera de las pantallas.
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  @override
  Future<void> showUvAlert({
    required String title,
    required String body,
  }) async {
    await initialize();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Avisos de exposición solar peligrosa.',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    await _plugin.show(1001, title, body, details);
  }
}

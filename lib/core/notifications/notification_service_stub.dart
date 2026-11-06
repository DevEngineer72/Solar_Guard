import 'notification_gateway.dart';

NotificationGateway createNotificationGateway() =>
    const _UnsupportedNotificationGateway();

/// Sustituto sin efectos para plataformas sin notificaciones locales nativas.
class _UnsupportedNotificationGateway implements NotificationGateway {
  const _UnsupportedNotificationGateway();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> showUvAlert({
    required String title,
    required String body,
  }) async {}
}

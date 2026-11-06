import 'notification_gateway.dart';
import 'notification_service_stub.dart'
    if (dart.library.io) 'notification_service_native.dart'
    as platform;

/// Selecciona en compilación la implementación nativa o la alternativa Web.
NotificationGateway createNotificationGateway() =>
    platform.createNotificationGateway();

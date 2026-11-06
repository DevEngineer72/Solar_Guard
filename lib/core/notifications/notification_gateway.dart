/// Puerto que desacopla las notificaciones locales de la lógica UV.
abstract interface class NotificationGateway {
  Future<void> initialize();

  Future<void> showUvAlert({required String title, required String body});
}

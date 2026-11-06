# Solar Safe Smart Station

Aplicación Flutter para consultar radiación UV, temperatura y humedad de una
estación ambiental. Comparte datos Supabase entre Android, iOS y Web.

## Ejecutar

1. Instalar Flutter compatible con Dart 3.13 o posterior.
2. Copiar `.env.example` a `.env` y completar URL y clave pública de Supabase.
3. Completar metadata y umbral de antigüedad solo cuando estén confirmados.
4. Ejecutar `flutter pub get` y `flutter run -d chrome` o un dispositivo móvil.

Nunca incluir una clave `service_role` ni una clave secreta en esta aplicación.
El archivo `.env` se incorpora a la app cliente; sus valores deben ser públicos.

## Experiencia

Móvil y Web: Dashboard, Historial, Alertas y Estación. Historial permite comparar
por días/semanas, usar rangos personalizados y descargar CSV. Los gráficos admiten
ratón, toque y selección mediante teclado. Las tipografías se incluyen localmente.

Los datos antiguos y las fechas futuras no se presentan como condiciones actuales.
Sin un umbral confirmado, se indica que la conexión no está confirmada.
Los avisos son locales, optativos y requieren que la aplicación esté en ejecución.
El historial de alertas se deriva del índice UV, no de un registro de entregas push.

## Diseño y documentación

- [Sistema de diseño](docs/design-system.md)
- [Arquitectura](docs/architecture.md)
- [Datos y Realtime](docs/supabase.md)
- [Plan y pendientes](docs/development-plan.md)

La web toma `design/web/DashBoard.png` como referencia de composición y color.
CO₂ y humedad de suelo no se muestran porque no forman parte del modelo real.

## Verificación

```sh
dart format lib test
flutter analyze
flutter test
flutter build web
```

Las pruebas de interfaz usan datos ficticios aislados de la aplicación y revisan
320, 375, 768, 1024 y 1440 píxeles, texto ampliado y estados vacíos/error.
La validación con ESP32 y permisos de Android/iOS requiere dispositivos reales.
# Solar_Guard

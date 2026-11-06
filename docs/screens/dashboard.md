# Dashboard

## Reference

Primary visual reference:

```text
design/mobile/Dashboard.png
```

## Purpose

Show the current condition of the intelligent station and the latest environmental measurements.

## Main UI

The mobile design contains:

1. station header
2. online status
3. active UV alert
4. UV index card
5. temperature metric
6. humidity metric
7. risk scale
8. protection recommendations
9. bottom navigation

The SOS button shown in the Stitch design is excluded from this project.

## Header

Show the station label:

```text
Playa 1 - Estación Central
```

The user does not select a station.

There is only one station from the user's perspective.

## Online status

Display the station status when a reliable data source exists.

Do not invent a backend status field that does not exist.

## UV card

Display:

- current UV value
- risk level
- circular visual indicator

The Stitch screenshot shows `8.5` and `MUY ALTO` as reference values.

These are design examples and must not remain hardcoded after Supabase integration.

## Temperature and humidity

Show:

- temperature in °C
- humidity in %

The Stitch screenshot shows `31 °C` and `62 %` as reference values.

## Risk scale

Reproduce the visual risk scale from the Stitch design.

Risk classification should be centralized in application logic.

Do not duplicate thresholds across widgets.

## Active alert

The visual design includes an active warning when UV conditions are severe.

The exact alert-generation rules are defined separately from this screen.

## Recommendations

The Stitch design includes:

- Usa protector solar FPS 30+
- Busca sombra inmediatamente
- Hidrátate constantemente

Treat these as visual/reference content until dynamic recommendation rules are explicitly defined.

## Realtime

The Dashboard should react to new Supabase measurements as they arrive.

Prefer Supabase Realtime subscriptions.

## States

Implement:

- loading
- loaded
- empty/no data
- connection error
- malformed/unexpected data

## Web

Use `design/web/DashBoard.png`: lateral oscuro, tres métricas, tendencia multivariable
normalizada con rangos y unidades reales, indicador circular, lecturas recientes,
condición y alertas UV. La tarjeta lateral usa `MascotaFuegoWidget` con dos
animaciones MP4 que se reproducen de una en una y al azar al hacer clic. El
video ocupa todo el ancho interior de la tarjeta en formato 16:9 y los clics
durante la reproducción se ignoran. La tarjeta
mantiene el valor/riesgo UV; las métricas superiores usan los logos
de `design/logos_temperatura/`. Períodos: 6 h, 24 h, 7 y 30 días. El período se carga
una vez y las nuevas lecturas llegan del stream Realtime del Dashboard. No mostrar
CO₂, humedad de suelo, mapa ficticio ni variaciones diarias inventadas.

## Interfaz renovada

UV en anillo, fecha exacta, indicador de actualidad, métricas, escala y consejos
según categoría. En web incorpora evolución UV de 24 h. El estado no afirma
conexión física: distingue datos recientes, sin actualización, fecha futura y
conexión no confirmada según configuración. Carga/error/vacío tienen tratamiento
propio; un error no deja las cifras anteriores presentadas como actuales.

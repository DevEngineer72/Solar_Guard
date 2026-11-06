# Architecture

## Objective

Build a maintainable Flutter application for monitoring an intelligent UV/environment station.

The application targets:

- Android
- iOS
- Web

The mobile application has exactly four main screens:

1. Dashboard
2. Historial
3. Alertas
4. Estación

Web and mobile share four destinations: Dashboard, Historial, Alertas and Estación.

The Profile screen is excluded from the project.

The SOS/emergency flow shown in the Stitch design is excluded from the project.

## Architecture principles

Separate the application into clear layers:

```text
Presentation / UI
        |
        v
Application / State
        |
        v
Repositories / Data access
        |
        v
Supabase
```

Keep Supabase queries out of large UI widgets.

Keep feature-specific logic close to its feature.

Keep reusable UI elements in shared components.

Avoid unnecessary abstractions and dependencies.

## Suggested Flutter structure

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router/
│   └── theme/
├── core/
│   ├── constants/
│   ├── errors/
│   └── utils/
├── data/
│   ├── models/
│   ├── repositories/
│   └── supabase/
├── features/
│   ├── dashboard/
│   ├── historial/
│   ├── alertas/
│   └── estacion/
└── shared/
    ├── navigation/
    └── widgets/
```

Codex may adjust this structure when there is a strong technical reason, but it should preserve separation of concerns.

## Navigation

There are four mobile main destinations:

- Inicio / Dashboard
- Historial
- Alertas
- Estación

Do not implement:

- Perfil
- SOS/emergency screen
- station selection

There is one station from the user's perspective.

## Data flow

The latest measurement is used by the Dashboard.

Historical measurements are used by Historial.

Measurement-derived conditions and system information may feed Alertas.

Station information and location are shown by Estación.

## Implemented structure

`lib/domain` contains immutable measurement and risk models plus centralized
alert derivation. `lib/data/repositories` owns Supabase access. Feature widgets
use small controllers rather than querying Supabase directly: range controllers
serve Historial, Alertas and Estación, while `LatestMeasurementController`
serves the Dashboard. `application/UvAlertCoordinator` observes the latest
measurement and delegates native local delivery to `core/notifications`; it
does not couple notification code to UI or data access. `app` configures the
theme and owns the notification coordinator lifecycle, while `features/shell`
owns the four-destination responsive navigation.

The shell and screen layouts use `LayoutBuilder` constraints: compact windows
keep the bottom navigation, medium layouts use a navigation rail, and wide
layouts use a persistent labeled sidebar (from 800 px on Web, 1100 px on
mobile platforms). Dashboard, Historial, Alertas and Estación reorganize
their content into columns or grids when their own content width allows it;
they keep the mobile hierarchy on narrow screens. The thresholds are local
layout decisions rather than a web-versus-app platform check.

Brand assets follow one source of truth: Flutter UI widgets load
`design/mobile/logo.png`, and `tool/sync_logo.sh` resizes that source without
distorting it into the required Android, iOS and Web icon dimensions before a
release build.

Use real Supabase data after integration is completed.

## Realtime

Prefer Supabase Realtime subscriptions so the UI reacts to new measurements.

Do not use one-second polling as the default architecture when Realtime can satisfy the requirement.

## Platform strategy

### Android and iOS

Use the mobile Stitch design as the primary reference. Android and iOS should remain visually equivalent.

### Web

Do not simply stretch the mobile layout to desktop widths. Adapt layout, content width, spacing, and grouping professionally while preserving the same visual identity.

## Testing and validation

Every completed feature should be:

- formatted
- statically analyzed
- tested where applicable
- run on the intended platform when possible
- visually compared with the Stitch reference

## Implementación del alcance ampliado

- `core/design/app_theme.dart` y `app_tokens.dart` implementan el sistema de
  `docs/design-system.md`. Fuentes incluidas en assets.
- `StationContext` proporciona metadata pública y el umbral de antigüedad.
- `AppPage`, `AdaptivePanels`, `AdaptiveCards` y `EnvironmentChart` se comparten.
- Web y móvil tienen cuatro destinos. El shell crea pantallas al visitarlas y
  conserva estado al redimensionar.
- Historial integra consulta, resúmenes, gráficos y selección de
  períodos. Las comparaciones usan promedios de muestras y calendario local.
- CSV exporta fechas UTC y protege identificadores contra fórmulas de planillas.
- La entrada por opacidad respeta la preferencia de reducir movimiento.

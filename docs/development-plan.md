# Development Plan

The application must be implemented incrementally. Each phase should leave the repository buildable.

## Phase 1 — Flutter project setup

Tasks:

- create Flutter project from scratch
- configure Android, iOS, and Web
- create initial folder structure
- configure environment variables
- add Supabase dependency
- configure fonts
- configure the shared theme
- verify a successful build

Do not implement all screens yet.

## Phase 2 — Shared design system

Tasks:

- colors
- typography
- spacing
- card styles
- common buttons
- common navigation styles
- reusable icon patterns

Goal: create a reusable visual foundation close to Stitch.

## Phase 3 — Shared navigation

Implement navigation between:

- Dashboard
- Historial
- Alertas
- Estación

Exclude:

- Perfil
- SOS
- station selection

Verify navigation on mobile and Web.

## Phase 4 — Dashboard UI

Reference:

```text
design/mobile/Dashboard.png
docs/screens/dashboard.md
```

Implement the mobile UI first.

Temporary data may be used during this phase.

Focus on visual fidelity.

## Phase 5 — Dashboard Supabase integration

Connect the Dashboard to Supabase.

Display the latest measurement:

- UV
- temperature
- humidity
- timestamp

Implement Realtime updates.

Implement loading, empty, and error states.

## Phase 6 — Historial UI

Reference:

```text
design/mobile/Historial.png
docs/screens/historial.md
```

Implement:

- 24h filter
- 7d filter
- 30d filter
- graph
- highlighted records
- responsive behavior

Use temporary data initially if needed.

## Phase 7 — Historial Supabase integration

Connect historical data to Supabase.

The selected range must affect the historical dataset.

Use real timestamps and measurements.

## Phase 8 — Alertas UI

Reference:

```text
design/mobile/Alertas.png
docs/screens/alertas.md
```

Implement:

- alert cards
- filters
- critical/preventive/informational visual states
- empty state

## Phase 9 — Alert logic and data

Centralize alert-generation logic.

Do not duplicate thresholds across multiple widgets.

The final alert-generation rules must be defined before production business logic is considered complete.

## Phase 10 — Estación UI

Reference:

```text
design/mobile/Estado_de_la_Estacion.png
docs/screens/estacion.md
```

Implement:

- station status
- technical information
- components
- location
- responsive behavior

Only make values dynamic when the backend provides the corresponding data.

## Phase 11 — Web refinement

Adapt the interface for larger screens professionally.

Do not merely stretch the mobile layout.

Preserve the same visual identity and information hierarchy.

## Phase 12 — Final validation

Run:

```bash
flutter analyze
dart format .
flutter test
```

Also verify:

- navigation
- realtime updates
- Supabase connectivity
- loading states
- error states
- empty states
- visual consistency
- Web responsiveness

## Alcance ampliado: implementación por etapas

1. Sistema de diseño: definido en `docs/design-system.md`.
2. Fundamentos: tema, tipografías locales, assets corregidos y componentes comunes.
3. Dashboard: datos reales, actualidad explícita, consejos por UV y evolución web.
4. Historial: tres variables, fechas, resúmenes, comparación y CSV.
5. Alertas/Estación: registro derivado, preferencia local, metadata sin valores falsos.
6. Navegación: cuatro destinos móviles; cinco en web, carga diferida y estado
   conservado al redimensionar. Entrada suave compatible con reducir movimiento.
7. Validación: análisis, pruebas de dominio/controlador/interfaz y compilación web.

### Pendientes que requieren información o dispositivo real

- Nombre y ubicación definitivos; coordenadas si se desea mapa geográfico.
- Cadencia del ESP32 y umbral autorizado de antigüedad.
- Validar nuevas inserciones reales por Realtime con la estación física.
- Verificar permisos y entrega de notificaciones en Android/iOS reales.
- Push con la app cerrada requiere arquitectura de servidor adicional; los avisos
  locales implementados solo cubren la aplicación en ejecución.

La lectura pública de Supabase se comprobó con HTTP 200 y filas con los seis
campos esperados. Esto no demuestra recepción Realtime desde el ESP32.

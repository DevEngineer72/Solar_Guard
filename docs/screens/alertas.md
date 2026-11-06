# Alertas

## Reference

Primary visual reference:

```text
design/mobile/Alertas.png
```

## Purpose

Provide a centralized view of important station conditions and system notifications.

## Filters

The user can filter the list by:

- Todas
- Críticas
- Preventivas

The selected filter changes the visible list.

## Alert categories

The design uses different visual treatments for different types of alerts, including:

- critical/error
- warning/preventive
- informational/system
- positive/healthy

Use the shared design system for colors and typography.

## Example alert content

The Stitch reference includes examples such as:

- Nivel UV Extremo
- Riesgo de Calor
- Sincronización Exitosa
- Humedad Óptima

These examples describe the intended UI, not a finalized backend schema.

## Data model

There is currently no dedicated alerts table.

Do not create one automatically.

Until a dedicated backend model is approved, alert logic should be centralized and derived from measurement/system information where appropriate.

## Alert rules

Final business rules are not yet defined.

Do not hardcode the same thresholds in multiple widgets.

Centralize the rules so they can be changed later.

## Empty state

When no alerts match the selected filter, show an appropriate empty state based on the Stitch design.

## Realtime

When a new measurement arrives, newly relevant alerts should be reflected in the interface.

## Web

Adapt the list layout for larger screens when useful, without changing the visual language.

## Interfaz renovada

Períodos 24 h/7 d/30 d, categorías preventivas y críticas desde UV 3/8, registro
derivado con fecha exacta y paginación visual. No se genera historial de entregas
ficticio. Preferencia local persistente para avisos Android/iOS; la carga inicial
y mediciones antiguas no disparan avisos. Un nivel repetido no avisa en cada muestra.
Web presenta recomendaciones y registro; no simula permisos push.

# Historial

## Reference

Primary visual reference:

```text
design/mobile/Historial.png
```

## Purpose

Display historical UV measurements and highlighted records from the station.

## Time filters

The user can choose:

- 24h
- 7d
- 30d

Only one period is active at a time.

## Chart

Display the historical UV index as a graph.

The graph should eventually use real Supabase measurement data.

The visual appearance should stay close to the Stitch reference, including axes, line treatment, labels, and overall card layout.

## Highlighted records

Display important historical records.

A record may show:

- time
- risk level
- UV index
- temperature
- trend indicator

The exact fields shown dynamically must come from available measurement data.

## Query behavior

The selected period should affect the dataset used by the graph and highlighted records.

Avoid unnecessary data retrieval.

## Realtime interaction

Realtime is relevant when new measurements arrive, but the historical range should remain controlled by the selected filter.

## States

Implement:

- loading
- loaded
- empty
- error

## Reference values

Values shown in the Stitch screenshot are visual examples only. They should not become permanent hardcoded production data.

## Web

Use a professional wider layout when useful, while preserving the same chart and information hierarchy.

## Interfaz renovada

Gráficos UV/temperatura/humedad seleccionables con fecha real en el eje temporal.
Selección por ratón, toque o slider accesible; comparación web en gráficos separados
por unidad. Resúmenes de todas las muestras y últimas diez lecturas. Web añade
fechas personalizadas y CSV. Historial permite comparar días
locales o semanas iniciadas el lunes, identificar el pico UV y contar muestras UV≥8.
Los promedios no están ponderados por tiempo ni completan períodos sin datos.

# Estación

## Reference

Primary visual reference:

```text
design/mobile/Estado_de_la_Estacion.png
```

## Purpose

Display technical information, state, components, and location of the intelligent station.

## Station identity

Show:

```text
Playa 1 - Estación Central
```

There is no station-selection flow.

## Status information

The Stitch design contains:

- En línea
- ID Estación
- Firmware
- Última sincronización

Only values backed by a real data source should be dynamic.

The current measurement schema does not define firmware or station metadata fields.

## Components

The design shows:

- Panel Solar
- Sensor UV
- Sensor Temp. y Humedad
- ESP32
- Alarma Sonora

These represent the physical station and should be presented as informational UI unless a backend control/data requirement is later defined.

## Location

Show the station location.

The user only needs to know where the station is located.

There is no station-selection interface.

## Map

The visual reference contains a map area.

The implementation may use an appropriate Flutter map solution or another practical method when the actual location data source is defined.

Do not invent precise coordinates in production.

## Realtime

Update dynamic station information when its real data source changes.

## States

Implement:

- loading
- loaded
- empty where applicable
- error

## Web

Use a wider and more structured layout when beneficial, while preserving the same hierarchy and visual identity.

## Interfaz renovada

Metadata pública configurable y estado basado en la última lectura disponible.
ID y fecha provienen de la medición. Sin fuente de coordenadas no se dibuja un
mapa geográfico inventado. El contenido de sensores y propósito es informativo;
no se afirma firmware, salud de componentes ni conexión física sin evidencia.

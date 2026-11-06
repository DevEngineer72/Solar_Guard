# Supabase

## Backend

Supabase is the backend for the application.

The Supabase project contains the production measurement table `public.mediciones`.

## Environment variables

Use:

```text
.env
```

with:

```env
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
SUPABASE_MEASUREMENTS_TABLE=mediciones
```

See `docs/env.md` for environment rules.

## Measurement entity

The initial measurement data model is:

```text
id
station_id
uv
temperatura
humedad
created_at
```

## Production database schema

```text
public.mediciones
id bigint identity primary key
station_id bigint not null
uv double precision not null
temperatura double precision not null
humedad double precision not null
created_at timestamptz not null default now()
```

## Integration implemented in the app

The client reads the table selected by `SUPABASE_MEASUREMENTS_TABLE` (default:
`mediciones`) and reads exactly the six fields
listed above. It obtains initial data and subsequent changes through the
Supabase Realtime stream keyed by `id`; it does not use periodic polling.

`docs/supabase-schema.sql` records the agreed production schema. The Flutter
model safely converts the `bigint` identifiers to strings for presentation.

## Field meaning

`id`

Unique identifier of the measurement record.

`station_id`

Identifier of the station that produced the measurement.

There is only one station from the user's perspective, but the measurement model still contains `station_id`.

`uv`

Ultraviolet index measurement.

`temperatura`

Temperature measurement.

`humedad`

Humidity measurement.

`created_at`

Timestamp associated with the measurement.

## Dashboard

Dashboard needs the newest available measurement.

Display:

- UV
- temperature
- humidity
- time/recency

## Historial

Historial uses measurement records within the selected period:

- 24h
- 7d
- 30d

Do not fetch more data than necessary.

## Realtime

Prefer Supabase Realtime subscriptions for new measurements.

The Dashboard should react when a new measurement is inserted.

Avoid unnecessary one-second polling when Realtime is available.

### Required Supabase project checks

The Flutter code already subscribes with `stream(primaryKey: ['id'])`. For an
insert to reach that stream, execute `docs/supabase-schema.sql` in the target
project or verify all of the following in the Supabase dashboard:

1. `public.mediciones` is included in the `supabase_realtime` publication.
2. `id` is the primary key and is included in the row payload.
3. The client role (`anon` when the app is unauthenticated) has `SELECT`
   permission through RLS.
4. The inserted row has valid values for all six fields and `created_at` is a
   valid `timestamptz`.

The app's initial REST query can succeed while Realtime remains silent; that
is why checking only whether the table loads once does not prove that Realtime
is configured. `stream()` also emits an error to the screen when the channel
cannot subscribe, instead of silently falling back to polling.

## Alerts

The current schema does not define an alerts table.

Do not invent an alerts table automatically.

Alerts can potentially be derived from measurements and system events, but the final business rules have not yet been specified.

Centralize alert-generation logic so thresholds and categories are not duplicated across the UI.

The Stitch design contains examples such as:

- Nivel UV Extremo
- Riesgo de Calor
- Sincronización Exitosa
- Humedad Óptima

These are visual examples, not a confirmed database schema.

## Station information limitation

The current measurement schema does not include fields for:

- firmware
- station status
- latitude
- longitude
- station name

Do not pretend that these values are dynamic from Supabase until a data source for them is defined.

The Estación screen may use design/reference values during UI work, but production data must only be marked dynamic when the backend actually provides it.

## Database decisions still required

Before production database setup, define:

1. Realtime configuration for `public.mediciones`
2. Alert-generation rules beyond the approved UV threshold
3. Source of station metadata

## Alertas y notificaciones actualizadas

`AlertService` deriva advertencias históricas de las mediciones UV: desde 3
(protección) y desde 8 (protección adicional). No crea tablas ni simula entregas
registradas. Las clasificaciones provisionales de calor/humedad se retiraron:
no había una regla operacional aprobada para ellas.

Fuentes: [OMS](https://www.who.int/news-room/questions-and-answers/item/radiation-the-ultraviolet-(uv)-index)
y [EPA](https://www.epa.gov/sunsafety/uv-index-scale-0).

Los avisos locales Android/iOS son optativos y la preferencia persiste en el
dispositivo. Requieren permisos del SO y un umbral de antigüedad configurado.
La carga inicial no genera una alerta por datos históricos. No se garantiza
entrega con la app suspendida o cerrada; eso requiere un servicio push.

## Rango completo y fechas

La lectura del historial pagina resultados en grupos de hasta 500 filas, con
orden por fecha e ID y un límite superior de fecha capturado al empezar. El
límite personalizado es exclusivo (inicio del día siguiente, hora local).
Realtime provoca la actualización del rango; no hay sondeo periódico de red.
CSV, resúmenes y comparaciones usan todas las filas del rango recuperado.
La lectura paginada no es una transacción: modificaciones concurrentes de filas
históricas podrían requerir volver a consultar para obtener otra instantánea.

## Actualidad y metadata

`STATION_NAME` y `STATION_LOCATION` son configuración pública, no campos nuevos.
`MEASUREMENT_MAX_AGE_SECONDS` debe reflejar la cadencia real acordada del ESP32.
Si falta, la app muestra la hora del último envío recibido. Si el umbral
se supera, muestra «Sin actualización»; eso no diagnostica una desconexión física.
Un temporizador local actualiza esa indicación sin consultar Supabase. Una fecha
futura se marca para verificarla y no se trata como una medición actual.

# Environment Variables

## Purpose

Keep Supabase configuration outside the source code.

## Files

Create:

```text
.env
```

Commit:

```text
.env.example
```

## Variables

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_MEASUREMENTS_TABLE=mediciones
```

## Security

Never commit real credentials.

Never hardcode Supabase credentials in Dart source files.

Never put a Supabase service-role key inside the Flutter client application.

The client should use the public client credential intended for frontend use.

`SUPABASE_MEASUREMENTS_TABLE` is not a secret. It makes the deployed table
name explicit and must be a simple PostgreSQL identifier; the app rejects
unsafe values before initializing Supabase.

## Git

The repository should ignore `.env`.

A template `.env.example` should contain placeholders only.

## Implementation note

Codex should choose an appropriate Flutter environment-variable solution and document the chosen approach in the repository.

The final implementation must work consistently for Android, iOS, and Web.

## Metadata y antigüedad

Variables públicas opcionales, documentadas en `.env.example`:

- `STATION_NAME`: nombre real; vacío muestra «Estación ambiental».
- `STATION_LOCATION`: ubicación legible; vacío muestra «Ubicación por confirmar».
- `MEASUREMENT_MAX_AGE_SECONDS`: segundos máximos aceptados desde una lectura;
  debe acordarse con la cadencia del ESP32. Vacío/inválido no supone actualidad.

No se han modificado las credenciales existentes. `.env` está excluido de Git.

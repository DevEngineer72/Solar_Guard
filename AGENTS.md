# AGENTS.md

## 1. Project Overview

This repository contains a Flutter application for monitoring an intelligent UV/weather station.

The application will target:

- Android
- iOS
- Web

The mobile application has exactly four main screens:

1. Dashboard
2. Historial
3. Alertas
4. Estación

The Web application also has exactly four main destinations.

The Perfil screen is NOT part of this project.

The SOS/emergency button shown in the Stitch Dashboard design is also NOT part of this project and must not be implemented.

---

## 2. Source of Truth

The visual source of truth is the Stitch design located in:

design/

Each screen has its own reference image.

Expected files:

- design/mobile/Dashboard.png
- design/mobile/Historial.png
- design/mobile/Alertas.png
- design/mobile/Estado_de_la_Estacion.png
- design/web/DashBoard.png

There is also a Stitch-generated HTML reference document containing the original visual definitions.

Use the screenshots and Stitch reference as design references.

Do not redesign the mobile UI unless explicitly requested.

The Android and iOS interfaces should remain visually equivalent.

For Web, preserve the same visual identity, but adapt the layout professionally for larger screens.

---

## 3. Main Development Principle

Build the application incrementally.

Do NOT implement the complete application in a single step.

Recommended development order:

1. Project setup
2. Flutter architecture
3. Shared design system
4. Shared navigation
5. Dashboard UI
6. Dashboard Supabase integration
7. Historial UI
8. Historial Supabase integration
9. Alertas UI
10. Alertas data integration
11. Estación UI
12. Estación data integration
13. Cross-platform refinement
14. Testing and final cleanup

Each phase must leave the project in a buildable state.

---

## 4. Before Coding

Before making significant changes:

1. Inspect the current repository.
2. Read this AGENTS.md.
3. Read the relevant documentation inside docs/.
4. Inspect the relevant Stitch reference image.
5. Understand the existing architecture before creating new files.
6. Identify ambiguities instead of silently inventing requirements.

When requirements are ambiguous, prefer asking for clarification over creating arbitrary business logic.

---

## 5. Flutter

Use Flutter and Dart.

Prefer a clean and maintainable architecture.

Separate:

- presentation/UI
- application/state logic
- data access
- models

Avoid putting Supabase queries directly inside large UI widgets.

Shared components should be reusable.

Avoid unnecessary complexity and unnecessary dependencies.

Do not introduce a state-management package unless it provides clear value for the project.

---

## 6. Supabase

Supabase is the backend.

The application will eventually read real data from Supabase.

The initial measurement data model contains these fields:

- id
- station_id
- uv
- temperatura
- humedad
- created_at

The exact PostgreSQL data types are not yet defined.

DO NOT invent database fields without documenting why they are needed.

DO NOT create additional database tables unless the requirement is explicit or the implementation cannot reasonably work without them.

Supabase credentials must NOT be hardcoded.

Use environment variables.

Expected environment configuration:

.env

Example:

SUPABASE_URL=...
SUPABASE_ANON_KEY=...

Also create:

.env.example

Never commit real credentials to Git.

Never expose a Supabase service-role key inside the Flutter application.

---

## 7. Realtime Data

The Dashboard and other data-driven screens should update when new measurements arrive.

Prefer Supabase Realtime/subscriptions for live updates.

Do not implement constant one-second polling as the default architecture if realtime subscriptions can provide the required behavior.

A polling fallback may be considered only when technically necessary.

---

## 8. Navigation

The mobile application contains exactly four main destinations:

- Inicio / Dashboard
- Historial
- Alertas
- Estación

The bottom navigation shown in the Stitch design should be implemented for Android and iOS.

Do not implement:

- Perfil
- SOS/emergency screen
- station selection

There is only one station from the user's perspective.

The application should show the station's location rather than allowing users to select stations.

---

## 9. Visual Fidelity

The mobile application should reproduce the Stitch design as closely as reasonably possible.

Pay attention to:

- spacing
- typography
- font weights
- colors
- border radius
- shadows
- card sizes
- icon selection
- alignment
- hierarchy
- navigation
- empty states
- loading states

Do not replace the visual design with generic Flutter widgets when that would noticeably change the appearance.

Create reusable theme/design-system definitions rather than duplicating values throughout the application.

---

## 10. Design System

The Stitch design uses:

- Manrope
- JetBrains Mono

The main visual system includes the colors and spacing documented in:

docs/design-system.md

Use the design-system document as the reference for Flutter theme definitions.

---

## 11. Responsive Design

Android and iOS should use the same mobile-oriented design.

Web must not simply stretch the mobile layout.

For Web:

- use the Stitch design as the visual reference
- adapt content width professionally
- use larger-screen layouts where appropriate
- preserve the same information hierarchy
- preserve the same brand identity
- avoid excessive empty space
- avoid creating an entirely different visual language

The Web implementation is allowed to differ structurally when necessary for usability.

---

## 12. Data States

Every screen that depends on Supabase must handle:

- loading
- successful data
- empty data
- connection error
- malformed/unexpected data

Do not leave the UI permanently showing hardcoded sample values after real data integration is completed.

Temporary mock data is allowed during UI development but must be clearly separated from production data access.

---

## 13. Validation

After implementing a feature:

1. Format the Dart code.
2. Run static analysis.
3. Run relevant tests.
4. Run the application when possible.
5. Verify the UI against the Stitch reference.
6. Fix obvious visual or functional regressions.

Do not consider a task complete only because the code compiles.

---

## 14. Documentation

Keep documentation updated when architecture or requirements change.

Important documentation files:

- docs/architecture.md
- docs/design-system.md
- docs/supabase.md
- docs/development-plan.md
- docs/screens/dashboard.md
- docs/screens/historial.md
- docs/screens/alertas.md
- docs/screens/estacion.md

---

## 15. Git and Changes

Prefer small, understandable changes.

Do not rewrite unrelated files.

Do not remove working functionality to solve an unrelated problem.

Before adding a dependency, determine whether Flutter's existing APIs or an already-installed dependency can solve the problem.

Do not generate unnecessary abstractions.

---

## 16. Completion Criteria

A screen is considered complete only when:

- UI closely matches the Stitch reference
- navigation works
- data integration works when applicable
- loading/error/empty states exist
- the code is formatted
- analyzer reports no relevant errors
- the feature works on the intended platform

Do not mark a feature complete merely because its UI has been created.

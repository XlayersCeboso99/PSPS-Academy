# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/). La versión de la app sigue `pubspec.yaml`.

## [Sin publicar]

## [0.2.0+5] — 2026-11-06 — Migración al repositorio independiente

Sin cambios funcionales respecto a `TSP_PSPS@119ab3e` (`Sprint 2/psps_academy`).

### Añadido
- Pruebas de caracterización de la migración en `test/regression/` (formatos persistidos v1–v3, logro heredado L-10, G-01, repaso, temas, inventario del catálogo).
- Documentación: README, `CONTRIBUTING.md`, `docs/ARCHITECTURE.md`, `SETUP.md`, `TESTING.md`, `USE_CASES.md`, `MIGRATION_REPORT.md`, `SPRINT3_PREPARATION.md` e informes de auditoría en `docs/audit/`.
- Workflow de GitHub Actions con análisis y pruebas.

### Cambiado
- `lib/` reorganizado en `app/`, `core/` y `features/` (solo movimiento de archivos e imports).
- `lib/data/catalog_validation.dart` renombrado a `lib/core/content/catalog_identity_validation.dart`.
- Documentos del Sprint 1/2 movidos a `docs/legacy/`; diagramas a `docs/uml/`.
- `.gitignore` ampliado (intermedios de Android, credenciales, editores).

## [0.2.0+5] — 2026-10-29 — Sprint 2 (en `TSP_PSPS`)

CU-05 a CU-10, logros G-02, temas G-03 y correcciones D-S1-01, D-S1-02, D-S1-03 y H-01. Historial completo en el repositorio de origen.

## [0.1.0+1] — 2026-10-10 — Sprint 1 (en `TSP_PSPS`, tag `v0.1.0-sprint01`)

CU-01 a CU-04 con almacenamiento local.

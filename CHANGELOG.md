# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/). La versión de la app sigue `pubspec.yaml`.

## [Sin publicar]

### Añadido
- CU-11 Notas personales por subtema (`lib/features/notes/`, pantallas en `lib/app/notes_screens.dart`), clave `psps.notes.v1`.
- CU-12 Recordatorio de estudio semanal con notificaciones locales (`lib/features/reminders/`, pantalla en `lib/app/reminder_screens.dart`), clave `psps.reminder.v1`. Interfaz de plataforma `NotificationPort` separada del adaptador Android/iOS (`adapters/flutter_notification_port.dart`) y punto único de selección `adapters/notification_port_factory.dart`.
- Pruebas del ID 21 en `test/sprint3/` (43 escenarios portados de `TSP_PSPS@a285d4c`) y 5 pruebas de aislamiento entre notas, recordatorios y avance.
- Dependencias `flutter_local_notifications 20.1.0`, `flutter_timezone 5.1.0`, `timezone 0.10.1`, `app_settings 7.0.0`.
- Android: permisos `POST_NOTIFICATIONS` y `RECEIVE_BOOT_COMPLETED`, receptores de notificaciones programadas y de reinicio, *core library desugaring*.
- Documentación: CU-11/CU-12 en `docs/USE_CASES.md`, trazabilidad en `docs/sprint3/TRAZABILIDAD_CU11_CU12.md` y guía `docs/platforms/ANDROID.md`.

- Catálogo ampliado a 40 preguntas y 20 actividades: dos preguntas nuevas por subtema (`CT-xx.s1.q3`, `CT-xx.s1.q4`) y una actividad adicional por tema (`CT-xx.a2`). Los 30 identificadores anteriores y sus textos se conservan.
- Modelo con varias actividades por tema (`Topic.extraPractices`, `Topic.practices`), compatible con el formato guardado `version` 3.
- `lib/core/content/catalog_legacy.dart`: identificadores congelados del catálogo anterior y regla de conservación de logros ya obtenidos.
- Pruebas `test/sprint3/multi_activity_model_test.dart` y `test/sprint3/catalog_expansion_test.dart`; inventario y caracterización de `test/regression/` adaptados al catálogo ampliado.

### Cambiado
- L-05 «Todas las prácticas» exige todas las actividades del catálogo vigente (antes, las 10). Quien ya lo había obtenido lo conserva.
- Al publicarse preguntas nuevas, un subtema completado antes pasa a «En progreso» hasta responderlas; las respuestas, puntos y logros guardados no cambian.

### Corregido
- `app_settings` 6.1.1 (versión del origen) compila contra Android API 33 y hacía fallar `assembleDebug` (`checkDebugAarMetadata`); se fijó la 7.0.0, que compila contra API 36 y mantiene la misma API y el soporte de CocoaPods.

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

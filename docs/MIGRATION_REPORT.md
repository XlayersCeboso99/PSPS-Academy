# Informe de migración

Migración de PSPS Academy desde `TSP_PSPS` a este repositorio independiente. Fecha: 06/11/2026. Coordinación con Orca (Run `run_f4b52873b4f9`): Claude Code (coordinador e integrador), Codex CLI (calidad) y OpenCode (migración técnica).

## 1. Procedencia

| Dato | Valor |
| --- | --- |
| Repositorio de origen | `https://github.com/XlayersCeboso99/TSP_PSPS` |
| Rama | `develop` |
| Commit | `119ab3eed0467c62d6b6c3c73b0705ff302a16b1` (merge PR #19, 29/10/2026 15:49:44 -0600) |
| Carpeta | `Sprint 2/psps_academy` |
| Versión de la app | `0.2.0+5` |
| Método | `git archive` del commit → copia de la carpeta a la raíz (145 archivos, idénticos byte a byte) |
| Commit de línea base aquí | `33b23fc` (`chore: migrate verified Flutter project from TSP_PSPS`) |

Motivo de la selección: `develop` contiene todo `main` más 33 commits (incluye CU-05…CU-10); las ramas no integradas solo añaden documentos. Detalle en [audit/DECISIONES_ARQUITECTURA.md](audit/DECISIONES_ARQUITECTURA.md) D-01.

**No migrado (permanece en `TSP_PSPS`):** historial Git, carpeta `Sprint 1/`, documentación de nivel de sprint fuera de la app (SRS, diseños, WP, reportes, PDF/DOCX, evidencias `Sprint 2/Pruebas/`), retrospectiva y *project plan*.

## 2. Informes de auditoría

| Informe | Autor (agente Orca) |
| --- | --- |
| [audit/INVENTARIO_ORIGINAL.md](audit/INVENTARIO_ORIGINAL.md) | OpenCode (tarea A2) |
| [audit/TRAZABILIDAD_CU01_CU10.md](audit/TRAZABILIDAD_CU01_CU10.md) | Codex (tarea A1) |
| [audit/RIESGOS_MIGRACION.md](audit/RIESGOS_MIGRACION.md) | Claude Code |
| [audit/DECISIONES_ARQUITECTURA.md](audit/DECISIONES_ARQUITECTURA.md) | Claude Code |

## 3. Cambios principales

1. **Línea base** idéntica al origen (`33b23fc`).
2. **Reorganización solo por movimiento** (`refactor/organize-structure`, OpenCode): `lib/ui|domain|data|features/cu08` → `lib/app`, `lib/core/{models,content,persistence,learning}`, `lib/features/{activities,search}`. En los `.dart` solo cambian líneas `import`/`part`; la *library* de UI y sus `part` se movieron sin dividirse. Documentos heredados a `docs/legacy/`, UML a `docs/uml/`. Nuevo `docs/ARCHITECTURE.md`.
3. **Pruebas de caracterización** (`test/migration-regression`, Codex): 8 pruebas nuevas en `test/regression/` y `docs/TESTING.md`. No se modificó ninguna prueba existente.
4. **Documentación y configuración** (`docs/project-documentation`, Claude Code): README, SETUP, USE_CASES, CONTRIBUTING, SPRINT3_PREPARATION, CHANGELOG, este informe, `.gitignore` ampliado y workflow de CI.

Sin cambios: paquete `psps`, `applicationId mx.edu.uaz.psps`, clave `psps.progress.v1`, IDs del catálogo, `pubspec.yaml`, `pubspec.lock`, `android/`, `ios/`, `web/`, lógica de `lib/`.

## 4. Validación

Entorno: Windows 11, Flutter 3.47.9 (stable), Dart 3.13.7, Android SDK 36, JDK de Android Studio.

| Comprobación | Origen (copia del snapshot) | Línea base `33b23fc` | Final (`main`) |
| --- | --- | --- | --- |
| `flutter pub get` | OK, lock sin cambios | OK, lock sin cambios | OK con `--enforce-lockfile` |
| `flutter analyze` | No issues found | No issues found | No issues found |
| `flutter test` | 140 aprobadas | 140 aprobadas | **148 aprobadas** (140 + 8) |
| `tool/verifications/defects_sprint01_verification_test.dart` | — | 5 aprobadas | 5 aprobadas |
| `flutter build apk --debug` | — | Compilado | Compilado (tras `flutter clean`) |
| Nombres de prueba (reporte JSON) | 140 | — | Los 140 originales presentes; 8 añadidas |
| `git diff --check` | — | Avisos solo en archivos heredados idénticos al origen (espacios finales en logs de evidencia, línea en blanco final en manifiestos) | Sin avisos en archivos nuevos |
| `dart format --set-exit-if-changed` | 7 archivos sin formato | 7 | 7 (heredados, sin tocar) |

Contenido educativo conservado: la prueba `INV-01` fija 4 módulos, 10 temas, 10 subtemas, 20 preguntas y 10 actividades con sus IDs y relaciones históricas.

**No ejecutado:** pruebas `integration_test/` en dispositivo (no había dispositivo Android conectado), workflow de CI (sin remoto), iOS. Los 10 CU se consideran preservados por: código sin cambios lógicos, 148 pruebas automatizadas y trazabilidad documental; **no** por verificación manual en dispositivo tras la migración.

## 5. Problemas encontrados y resolución

| Problema | Resolución |
| --- | --- |
| `main` del origen no contiene la versión final. | Se migró `develop@119ab3e`. |
| Argumentos con comillas dobles rotos por PowerShell 5.1 al lanzar trabajadores. | Se sustituyeron por comillas simples en las especificaciones; el intento fallido no creó recursos. |
| OpenCode pidió permiso para leer el snapshot fuera de su workspace; la aprobación persistente fue denegada por la política de seguridad local. | Se aprobó una lectura puntual, se copió el snapshot a una carpeta local excluida de Git (`.audit_source/`, eliminada al cierre) y se comprobó que OpenCode no guardó reglas de permiso. |
| El primer prompt de la tarea Q1 se perdió (Codex aún arrancaba). | Se reenvió una vez a la misma terminal el preámbulo exacto obtenido con `orca orchestration dispatch-show --preamble`; no se creó un segundo trabajador. |
| `debug.log` de crashpad generado por una herramienta de un trabajador en la raíz. | Eliminado; añadido a `.gitignore`. |
| 7 archivos heredados no pasan `dart format`. | No se reformatean en la migración; CI sin control de formato por ahora (Sprint 3). |
| Las pruebas de regresión se escribieron contra las rutas antiguas en paralelo a la reorganización. | Imports actualizados al integrar (`4d75509`). |
| El documento de arquitectura afirmaba «formato sin cambios». | Corregido (`1d24210`). |

## 6. Git

- Historial independiente; ningún objeto del repositorio original.
- Ramas: `main`, `develop`, `refactor/organize-structure`, `test/migration-regression`, `docs/project-documentation` (además de las ramas técnicas que Orca creó para sus worktrees).
- Sin `origin` configurado: ver §7.

## 7. Publicación en GitHub

**Bloqueada.** `gh auth status`: no hay sesión iniciada en ningún host. La API pública devuelve 404 para `XlayersCeboso99/PSPS-Academy` (no existe públicamente; sin autenticación no se puede descartar que exista como privado). Los commits se conservan localmente. Para publicar:

```bash
gh auth login
gh repo view XlayersCeboso99/PSPS-Academy   # debe fallar: el nombre debe estar libre
gh repo create XlayersCeboso99/PSPS-Academy --private --source . --remote origin
git push -u origin main develop
```

## 8. Repositorio original

`PSPS_SOURCE` se usó solo con comandos de lectura (`log`, `show`, `ls-tree`, `diff`, `archive`). `git status --porcelain` vacío al inicio y al cierre; ramas y HEAD sin cambios; ningún push (su *push URL* es `DO_NOT_PUSH_TO_SOURCE`).

## Pendientes

1. Pruebas en dispositivo Android tras la migración (`tool/verify_sprint2_android.ps1` con cada destino) y actualización sobre una instalación previa sin desinstalar.
2. Publicar el repositorio (requiere `gh auth login`) y verificar la primera ejecución del CI.
3. Decidir RP-01 (estructuras vacías) y la política para estados guardados con L-10 (R-06, caracterizado en `MIG-02`).
4. iOS (macOS/Xcode) y evaluación de HarmonyOS NEXT.
5. Deuda técnica: dividir `lib/app/app.dart`, formatear 7 archivos, firma *release*, actualizar dependencias, considerar versionar el *wrapper* de Gradle (recomendación de `INVENTARIO_ORIGINAL.md` §9).

Detalle en [SPRINT3_PREPARATION.md](SPRINT3_PREPARATION.md).

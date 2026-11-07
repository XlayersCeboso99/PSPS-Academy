# Decisiones de arquitectura y migración

Responsable: coordinador (Claude Code). Fecha: 06/11/2026.
Convención: **HECHO** = comprobado con comando o archivo citado; **DECISIÓN** = elección del coordinador con su justificación; **PENDIENTE** = abierto.

## D-01. Versión de origen

**DECISIÓN.** Se migra el proyecto Flutter `Sprint 2/psps_academy` del commit
`119ab3eed0467c62d6b6c3c73b0705ff302a16b1` (rama `develop` de `XlayersCeboso99/TSP_PSPS`,
merge del PR #19, 29/10/2026 15:49:44 -0600).

Justificación (**HECHO**, comandos de solo lectura sobre `PSPS_SOURCE`):

- `git rev-list --count origin/develop..origin/main` = 0 y `origin/main..origin/develop` = 33: `develop` contiene todo `main` (53355a9) y 33 commits más.
- Las ramas no integradas en `develop` (`Project-Plan`, `feature/CU-07-repaso`, `feature/CU-08-actividades`, `fix-registro-defectos`) solo añaden PDF/DOCX/Markdown de documentación (`git diff --stat merge-base..rama`); ninguna contiene código Dart.
- `Sprint 2/psps_academy` es superconjunto funcional de `Sprint 1/psps_academy` (añade `lib/features/cu08`, `content_search`, `gamification`, `catalog_validation`, `activity_store`).
- La auditoría de trazabilidad (`docs/audit/TRAZABILIDAD_CU01_CU10.md`) localiza implementación y pruebas de CU-01 a CU-10 en esta versión y evidencia histórica de 140 pruebas aprobadas sobre ella.
- Reproducción propia antes de migrar (copia del `git archive`, Flutter 3.47.9 / Dart 3.13.7): `flutter pub get` OK sin cambiar `pubspec.lock`, `flutter analyze` sin incidencias, `flutter test` **140 aprobadas**.

`main` **no** es la versión final: le faltan CU-05 a CU-10 integrados.

## D-02. Método de copia

**DECISIÓN.** `git archive 119ab3e` → extracción en un directorio temporal → copia de `Sprint 2/psps_academy/*` a la raíz del repo nuevo. Así solo viajan archivos versionados (sin `.git`, `build/`, `.dart_tool/`, `local.properties`, cachés). **HECHO:** 145 archivos origen, 145 presentes tras la copia. El repo original no se modificó (`git status --porcelain` vacío antes y después).

No se migran los materiales de nivel de sprint que están fuera de la carpeta de la app (PDF/DOCX de planeación, diseño, pruebas y retrospectivas en `Sprint 1/`, `Sprint 2/`, `docs/` raíz). Permanecen en `TSP_PSPS`, que conserva el historial; `docs/MIGRATION_REPORT.md` los referencia.

## D-03. Identidades que NO cambian (contratos de compatibilidad)

| Identidad | Valor | Motivo |
| --- | --- | --- |
| Nombre de paquete Dart | `psps` | Todos los imports `package:psps/...` de pruebas. |
| `applicationId` / `namespace` Android | `mx.edu.uaz.psps` | Actualizar sin desinstalar conserva datos; `tool/verify_sprint2_android.ps1` lo sustituye literalmente. |
| Ruta `MainActivity.kt` | `android/app/src/main/kotlin/mx/edu/uaz/psps/` | Usada por el script de verificación. |
| Clave de almacenamiento | `psps.progress.v1` (JSON con `version` 1–3) | Persistencia del avance de usuarios existentes. |
| IDs de catálogo | m1…m4, temas, subtemas, preguntas, prácticas | Asocian el estado guardado con el contenido. |
| `version` de `pubspec.yaml` | `0.2.0+5` | Sin cambio funcional en la migración. |
| Dependencias | `shared_preferences ^2.5.6`, `cupertino_icons 1.0.9`, `flutter_lints ^6.0.0`, `pubspec.lock` sin cambios | Reproducibilidad. |
| Carpetas nativas | `android/`, `ios/`, `web/` sin modificar | Fuera del alcance; iOS sin verificar. |

## D-04. Estructura de `lib/` (contrato C-01)

**HECHO.** El origen tiene 3 689 líneas en 16 archivos. `lib/ui/app.dart` (1 232 líneas) es una *library* con `part 'review_screens.dart'` y `part 'sprint2_screens.dart'`; las tres comparten miembros privados. `learning_controller.dart` depende de `gamification.dart`, `progress_store.dart` y de los dos validadores.

**DECISIÓN.** Reorganización **solo por movimiento** (`git mv` + actualización de imports), sin cambiar el contenido de clases ni funciones:

| Origen | Destino | Capa |
| --- | --- | --- |
| `lib/main.dart` | `lib/main.dart` | arranque |
| `lib/ui/app.dart` | `lib/app/app.dart` | app (UI, *library*) |
| `lib/ui/review_screens.dart` | `lib/app/review_screens.dart` | `part of` app |
| `lib/ui/sprint2_screens.dart` | `lib/app/sprint2_screens.dart` | `part of` app |
| `lib/domain/course.dart` | `lib/core/models/course.dart` | core |
| `lib/data/catalog.dart` | `lib/core/content/catalog.dart` | core |
| `lib/domain/catalog_validation.dart` | `lib/core/content/catalog_validation.dart` | core |
| `lib/data/catalog_validation.dart` | `lib/core/content/catalog_identity_validation.dart` | core |
| `lib/data/progress_store.dart` | `lib/core/persistence/progress_store.dart` | core |
| `lib/domain/learning_controller.dart` | `lib/core/learning/learning_controller.dart` | core |
| `lib/domain/gamification.dart` | `lib/core/learning/gamification.dart` | core |
| `lib/domain/content_search.dart` | `lib/features/search/content_search.dart` | feature CU-09 |
| `lib/features/cu08/activity_engine.dart` | `lib/features/activities/activity_engine.dart` | feature CU-08 |
| `lib/features/cu08/activity_models.dart` | `lib/features/activities/activity_models.dart` | feature CU-08 |
| `lib/features/cu08/activity_page.dart` | `lib/features/activities/activity_page.dart` | feature CU-08 |
| `lib/data/activity_store.dart` | `lib/features/activities/activity_store.dart` | feature CU-08 |

Reglas de dependencia: `core` no importa `app` ni `features`; `features` puede importar `core`; `app` importa ambos. Se usan imports `package:psps/...` en `lib/` para consistencia.

Razones:

- `gamification` vive en `core/learning` porque el controlador central lo usa para puntos (G-01) y logros; ponerlo en `features` invertiría la dependencia.
- El validador de `data/` se renombra a `catalog_identity_validation.dart` porque ya se importaba con alias `identity_validation`; elimina la ambigüedad de dos archivos con el mismo nombre. **No** se fusionan: cambiar validaciones alteraría RP-01/D-S1-01.
- **No** se divide `app.dart` ni sus `part`: separarlos obligaría a hacer públicos miembros privados y a reescribir navegación, con riesgo de regresión sin beneficio funcional. Queda como candidato para Sprint 3 (D-08).
- No se crea `shared/`: los widgets reutilizables (`StatusBadge`, `ScreenFrame`) están dentro de la *library* `app` y moverlos tiene el mismo problema.

## D-05. Pruebas

**DECISIÓN.** Se conservan las 140 pruebas de `test/`, las 8 de `integration_test/`, `test_driver/` y `tool/verifications/`. Solo se actualizan sus líneas `import 'package:psps/...'`. Criterio de aceptación de la reorganización: mismo número de pruebas y todas aprobadas, `flutter analyze` sin incidencias. Las pruebas nuevas de regresión se añaden en archivos nuevos (`test/regression/`), nunca modificando aserciones existentes.

## D-06. Documentación heredada

**DECISIÓN.** Los documentos que venían dentro de la carpeta de la app se conservan, reubicados:

| Origen | Destino |
| --- | --- |
| `docs/CU07_REPASO.md`, `docs/DISENO_SPRINT2.md`, `docs/GUIA_DEMO.md`, `docs/SPRINT_1.md` | `docs/legacy/` |
| `Pruebas/` (REPRODUCIR.md y evidencias del Sprint 1) | `docs/legacy/evidencias_sprint1/` |
| `UML_fuentes/*.puml` | `docs/uml/` |

Se marcan como históricos: contienen afirmaciones superadas (p. ej., logro L-10, once logros) que la adenda del 29/10 retiró; ver `RIESGOS_MIGRACION.md` R-05.

## D-07. Git y ramas

**DECISIÓN.** Historial nuevo e independiente, sin `.git` del original. `main` estable; `develop` para el Sprint 3; trabajo en `refactor/*`, `test/*`, `docs/*`, `feature/*` con Conventional Commits. `origin` apuntará solo a `XlayersCeboso99/PSPS-Academy`. En la copia local del original el *push URL* ya es `DO_NOT_PUSH_TO_SOURCE`.

## D-08. Fuera de alcance / Sprint 3

- División de `lib/app/app.dart` por pantallas (requiere diseño de API pública y pruebas de navegación).
- Puertos iOS (requiere macOS/Xcode) y HarmonyOS NEXT (el Flutter oficial instalado no ofrece ese destino; habrá que evaluar en Sprint 3 el SDK Flutter mantenido por la comunidad OpenHarmony u otra alternativa — no evaluado en esta migración).
- CU-11 y CU-12.
- Resolución formal de RP-01 (estructuras vacías) y de textos heredados L-10.

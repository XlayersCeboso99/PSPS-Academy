# Inventario técnico del proyecto original — PSPS Academy

**Tipo de documento:** inventario técnico de solo lectura para planear la migración.
**Fecha del inventario:** 2026-11-06.
**Repo nuevo (destino):** `C:\Users\sebas\source\PSPS_Academy_Migration\PSPS_Academy`.
**Repo original (solo lectura):** `C:\Users\sebas\source\PSPS_Academy_Migration\PSPS_SOURCE` (remoto `TSP_PSPS`).
**Versión de origen analizada:** rama `origin/develop`, commit `119ab3eed0467c62d6b6c3c73b0705ff302a16b1` (2026-10-29).
**Referencia de citación:** `TSP_PSPS@119ab3e:<ruta>` denota el árbol de `origin/develop` en el commit indicado; las rutas sin prefijo son relativas a `TSP_PSPS@119ab3e:Sprint 2/psps_academy` salvo que se indique otro árbol.
**Proyecto Flutter analizado:** `TSP_PSPS@119ab3e:Sprint 2/psps_academy`.

> Convención de marcas usada en todo el documento:
> - **HECHO** = dato comprobado directamente en el árbol `TSP_PSPS@119ab3e` o con comandos `git` de solo lectura; se indica la ruta o la referencia git.
> - **SUPUESTO** = inferencia razonable no verificada todavía.
> - **PENDIENTE** = dato que exige compilación, ejecución, decisión del equipo o revisión posterior.
>
> No se ejecutó Flutter, no se modificó el repo original y no se creó ningún archivo distinto de este informe.

---

## Resumen ejecutivo

1. El repo original tiene **20 ramas remotas reales** (más el alias `origin/HEAD`): **16 están contenidas en `develop`** y **4 no lo están**. Las cuatro no integradas (`Project-Plan`, `feature/CU-07-repaso`, `feature/CU-08-actividades`, `fix-registro-defectos`) aportan únicamente documentación o evidencias, no código Dart. **HECHO** (`git branch -r`, `git diff --name-status origin/develop...origin/<rama>`).
2. `Sprint 2/psps_academy` es **superconjunto de archivos** de `Sprint 1/psps_academy`: 107 archivos del Sprint 1, 145 del Sprint 2, sin ninguna ruta relativa del Sprint 1 ausente en el Sprint 2; además 38 archivos nuevos y 96 archivos compartidos modificados. **HECHO** (`git ls-tree`, `git diff --stat`).
3. La app del Sprint 2 es pequeña y autocontenida: **16 archivos en `lib/` (3,689 líneas)**, **20 archivos de prueba unitaria/widget (3,677 líneas)** y **8 pruebas de integración**. Todo el contenido educativo está hardcodeado en `lib/data/catalog.dart`; **no hay carpeta `assets/`, fuentes ni imágenes de contenido**. **HECHO**.
4. Android requiere regenerar localmente el wrapper de Gradle (`gradlew`, `gradlew.bat`, `gradle-wrapper.jar`) y `android/local.properties`; el repo además no tiene `.metadata`. La firma de release usa la clave de depuración y no hay keystore de producción. **HECHO** (`.gitignore`, `android/settings.gradle.kts`, `android/app/build.gradle.kts`).
5. No se encontraron keystores, tokens ni archivos `.env`. Sí hay **56 archivos de evidencias/logs del Sprint 2 con rutas locales de Windows** (por ejemplo `C:/Users/bolis/...`) y datos de dispositivo; no son credenciales, pero conviene excluirlos o sanitizarlos. **HECHO** (`git grep` sobre `origin/develop -- "Sprint 2"`).
6. Hallazgos que afectan la migración: el catálogo estático de logros define **10 logros (L-01…L-09 y L-11)**, no 11; **L-10 no existe como `Achievement`** aunque README/docs/pruebas hablan de 11. También hay **dos validadores de catálogo duplicados** (`lib/data/catalog_validation.dart` y `lib/domain/catalog_validation.dart`) usados simultáneamente. **HECHO**.

---

## 1. Estructura del repositorio original

### 1.1 Ramas remotas y estado de integración

**HECHO** — obtenido con `git branch -r`, `git branch -r --merged origin/develop`, `git branch -r --no-merged origin/develop` en `PSPS_SOURCE`.

Ramas **contenidas en `develop`** (16):

| Rama | Rol / contenido observado | Estado |
| --- | --- | --- |
| `origin/main` | Rama de versiones liberadas. Punta `53355a9` (2026-10-26); es ancestro de `develop`. | **HECHO** |
| `origin/develop` | Rama de integración. Punta `119ab3e` (2026-10-29). | **HECHO** |
| `origin/codex/sprint02-integracion-cierre` | Cierre de integración del Sprint 2 (IDs 74 y 82); punta `cb71d13` (2026-10-28). | **HECHO** |
| `origin/codex/sprint02-pruebas-calidad` | Pruebas y calidad del Sprint 2 (CU-05/CU-10); punta `ade1b44` (2026-10-25). | **HECHO** |
| `origin/feature/CU-05-modulos` | Exploración de módulos (CU-05); punta `8e03d0f` (2026-10-24). | **HECHO** |
| `origin/feature/CU-06-logros` | Logros y temas (CU-06/G-02/G-03); punta `6fef628` (2026-10-28). | **HECHO** |
| `origin/feature/CU-09-busqueda` | Búsqueda local (CU-09); punta `0a4c4e8` (2026-10-28). | **HECHO** |
| `origin/feature/CU-10-puntos` | Puntos y regla G-01 (CU-10); punta `c28a51a` (2026-10-24). | **HECHO** |
| `origin/feature/sprint02-app` | Entregas del Sprint 2 (CU-07 y evidencias); punta `c51ad9d` (2026-10-24). | **HECHO** |
| `origin/fix/D-S1-01-validar-catalogo` | Corrección del defecto D-S1-01. | **HECHO** |
| `origin/fix/D-S1-02-orden-actividad` | Corrección del defecto D-S1-02. | **HECHO** |
| `origin/fix/D-S1-03-iconos-progreso` | Corrección del defecto D-S1-03. | **HECHO** |
| `origin/fix/H-01-respuesta-repetida` | Corrección del hallazgo H-01. | **HECHO** |
| `origin/fix/integracion-develop` | Integración final; punta `134adcb` (2026-10-29). | **HECHO** |
| `origin/integracion/pablo-develop` | Integración de componentes de Pablo; punta `8ed8239` (2026-10-28). | **HECHO** |
| `origin/release-sprint01-temp` | Rama temporal de liberación del Sprint 1; punta `5c4e56b` (2026-10-11). | **HECHO** |

Ramas **NO contenidas en `develop`** (4): se detallan en la sección 1.2.

**HECHO** — `main` es ancestro de `develop` (`git merge-base --is-ancestor origin/main origin/develop` devuelve éxito) y `develop` está 225 archivos y 11,279 inserciones por delante de `main` (`git diff --stat origin/main origin/develop`). `main` no contiene los merges finales #18 y #19 del Sprint 2.

### 1.2 Ramas no integradas en `develop`

**HECHO** — la columna “cambios únicos” sale de `git diff --name-status origin/develop...origin/<rama>`; los tamaños salen de `git ls-tree -r -l`. El diff de triple punto compara contra el ancestro común, por lo que muestra lo que la rama añade respecto de su base.

| Rama | Punta (fecha) | Cambios únicos respecto de `develop` | Tamaño / observación |
| --- | --- | --- | --- |
| `origin/Project-Plan` | `795560f` (2026-09-25) | Añade `Project Plan.pdf` en la raíz. | 224,409 B. Solo documentación; no toca código. |
| `origin/feature/CU-07-repaso` | `e8c4474` (2026-10-24) | Añade `Sprint 2/CU06/LOGROS.md` y `Sprint 2/CU06/PSPS_CatalogoLogros_G02G03_Sprint02_TSP_Ago26.pdf`. | `LOGROS.md` = 9 B (contenido literal `# LOGROS`); PDF = 188,089 B. La rama se llama CU-07 pero su aporte único es documentación de CU-06. No hay código Dart en el diff. |
| `origin/feature/CU-08-actividades` | `455cdd5` (2026-10-28) | Añade `Pruebas/CU08/PSPS_EvidenciasPruebas_CU08_ID57_Sprint02_TSP.docx`. | DOCX = 45,483 B. El tip de la rama también conserva `Pruebas/CU08/PLAN_VERIFICACION.md` (1,174 B) en la ubicación antigua de la raíz; en `develop` ese documento vive en `Sprint 2/Pruebas/CU08/PLAN_VERIFICACION.md`. No hay código Flutter en el diff. |
| `origin/fix-registro-defectos` | `28e1374` (2026-10-24) | Añade `Sprint 2/defectos/RegistroCorreccion.md` y `Sprint 2/defectos/PSPS_CorreccionDefectos_H01_TSP_Ago26.pdf`. | MD = 38 B; PDF = 186,896 B. Ojo: la carpeta es `defectos` en minúsculas, mientras `develop` usa `Sprint 2/Defectos`; en Windows/macOS podría colisionar al integrar. **HECHO** la ruta; **SUPUESTO** el riesgo de colisión. |

**Observación de migración:** ninguna de las cuatro ramas no integradas aporta código de la app. Su valor es documental/evidencial. **HECHO**.

### 1.3 Tag `v0.1.0-sprint01`

- **HECHO** — el tag es un tag ligero (`git cat-file -t v0.1.0-sprint01` → `commit`), apunta a `5c4e56b1789382f839bdfbeeb2638c5c24b1a838` (2026-10-11) y contiene **119 archivos**.
- **HECHO** — contenido principal del tag:
  - `Documentacion/PSPS_GuiaDeOperacion_TSP_Ago26.pdf`
  - `Documentacion/PSPS_ManualDeUsuario_TSP_Ago26.pdf`
  - `README.md`
  - `Sprint 1/Diagramas UML/` (fuentes `.txt` y PDF de diagramas)
  - `Sprint 1/PSPS_ImplementacionDeEntorno_TSP_Ago26.pdf`, `PSPS_SRS_TSP_Ago26.pdf`, `PSPS_Wireframes_TSP_Ago26.pdf`
  - `Sprint 1/Pruebas/` (casos de prueba ejecutados, reporte de pruebas y evidencias)
  - `Sprint 1/psps_academy/` (proyecto Flutter completo del Sprint 1, 107 archivos)
- **HECHO** — el tag es ancestro de las 20 ramas remotas (`git for-each-ref --contains 5c4e56b refs/remotes` cuenta 20).
- **HECHO** — `develop` está **70 commits por delante** del tag (`git rev-list --count v0.1.0-sprint01..origin/develop`); `git describe origin/develop` devuelve `v0.1.0-sprint01-70-g119ab3e`.
- **HECHO** — el tag todavía contiene `.metadata`, `android/.gitignore` e `ios/.gitignore` dentro de `Sprint 1/psps_academy`; esos archivos ya no aparecen en `develop` ni en el proyecto del Sprint 2. Es decir, la plantilla Flutter fue depurada en el camino.

---

## 2. Diferencias entre `Sprint 1/psps_academy` y `Sprint 2/psps_academy`

**HECHO** — rutas comparadas en el mismo commit `origin/develop` con:

```sh
git diff --stat "origin/develop:Sprint 1/psps_academy" "origin/develop:Sprint 2/psps_academy"
git ls-tree -r --name-only "origin/develop:Sprint 1/psps_academy"
git ls-tree -r --name-only "origin/develop:Sprint 2/psps_academy"
```

| Métrica | Sprint 1 | Sprint 2 |
| --- | --- | --- |
| Archivos totales | 107 | 145 |
| Archivos en `lib/` | 6 | 16 |
| Líneas en `lib/` | 1,764 | 3,689 |
| Archivos en `test/` | 4 | 20 |
| Líneas en `test/` | 354 | 3,677 |
| Archivos en `integration_test/` | 2 | 8 |
| Archivos en `test_driver/` | 1 | 2 |
| Archivos en `docs/` | 2 | 4 |
| `.gitignore` propio del proyecto | No | Sí |
| `pubspec.yaml` versión | `0.1.0+1` | `0.2.0+5` |
| `flutter_driver` en dev_dependencies | No | Sí |
| Directorio `features/` | No | Sí (`lib/features/cu08`) |

**HECHO** — el diff entre ambos árboles reporta **96 archivos cambiados, 10,855 inserciones y 4,284 eliminaciones**. Los 38 archivos nuevos del Sprint 2 son:

- Raíz: `.gitignore`.
- `docs/`: `CU07_REPASO.md`, `DISENO_SPRINT2.md`.
- `integration_test/`: `cu05_offline_test.dart`, `cu06_logros_offline_test.dart`, `cu07_offline_test.dart`, `cu09_busqueda_offline_test.dart`, `cu10_offline_test.dart`, `sprint2_design_test.dart`.
- `lib/`: `data/activity_store.dart`, `data/catalog_validation.dart`, `domain/catalog_validation.dart`, `domain/content_search.dart`, `domain/gamification.dart`, `features/cu08/activity_engine.dart`, `features/cu08/activity_models.dart`, `features/cu08/activity_page.dart`, `ui/review_screens.dart`, `ui/sprint2_screens.dart`.
- `test/`: `catalog_integrity_test.dart`, `cu06_achievements_test.dart`, `cu08_activity_engine_test.dart`, `cu08_activity_page_test.dart`, `cu08_shared_store_test.dart`, `cu09_search_test.dart`, `fix_ds101_validar_catalogo_test.dart`, `fix_ds102_orden_actividad_test.dart`, `fix_ds103_iconos_progreso_test.dart`, `fix_h01_respuesta_repetida_test.dart`, `module_exploration_test.dart`, `points_consultation_test.dart`, `review_cu08_refresh_test.dart`, `review_test.dart`, `sprint2_test.dart`, `wp14_cu05_cu10_test.dart`.
- `test_driver/`: `design_driver.dart`.
- `tool/`: `verify_sprint2_android.ps1`, `verifications/defects_sprint01_verification_test.dart`.

**Conclusión:** `Sprint 2/psps_academy` es **superconjunto de archivos** del Sprint 1 (ninguna ruta relativa del Sprint 1 falta en el Sprint 2), pero **no es un superconjunto de contenido**: 96 archivos compartidos fueron reescritos o ampliados. **HECHO**.

**HECHO** — el Sprint 1 conserva 6 archivos en `lib/`: `main.dart` (16), `data/catalog.dart` (369), `data/progress_store.dart` (61), `domain/course.dart` (82), `domain/learning_controller.dart` (131), `ui/app.dart` (1,105). No tiene `features/`, ni búsqueda, ni gamificación, ni repaso, ni logros.

---

## 3. Árbol de `Sprint 2/psps_academy`

**HECHO** — inventario del snapshot: **145 archivos, 1,902,236 bytes** en total. Directorios de primer nivel:

```text
Sprint 2/psps_academy/
├── android/
├── docs/
├── integration_test/
├── ios/
├── lib/
├── Pruebas/
├── test/
├── test_driver/
├── tool/
├── UML_fuentes/
├── web/
├── .gitignore
├── analysis_options.yaml
├── pubspec.lock
├── pubspec.yaml
└── README.md
```

No existen `assets/`, `fonts/`, `images/` ni `res/raw/`. No hay carpeta `build/`, `.dart_tool/` ni `.gradle/` en el snapshot (son artefactos, no se versionan). **HECHO**.

### 3.1 `lib/` — 16 archivos, 3,689 líneas

| Archivo | Líneas | Responsabilidad (1 línea) |
| --- | ---: | --- |
| `lib/main.dart` | 16 | Punto de entrada: crea `LearningController` con `catalog` y `LocalProgressStore`, carga el avance y ejecuta `PspsApp`. |
| `lib/data/catalog.dart` | 369 | Catálogo educativo hardcodeado (4 módulos, 10 temas, 10 actividades) construido con el helper `_topic`; IDs estables para persistencia. |
| `lib/data/progress_store.dart` | 104 | `ProgressSnapshot` (JSON versiones 1–3) y `LocalProgressStore` sobre `shared_preferences` con clave `psps.progress.v1`. |
| `lib/data/activity_store.dart` | 48 | Adaptador entre `ActivityStore` de CU-08 y el estado real de `LearningController`; impide retirar actividades y guarda una por operación. |
| `lib/data/catalog_validation.dart` | 40 | Validador de identidad estricto: lanza `FormatException` si IDs vacíos/repetidos u opciones/respuestas inválidas (usado como `identity_validation`). |
| `lib/domain/course.dart` | 113 | Modelos `Question`, `Lesson`, `Practice`, `Topic`, `CourseModule` y `ProgressStatus`; incluye `presentationOrder` estable de actividades. |
| `lib/domain/learning_controller.dart` | 305 | Estado central `ChangeNotifier`: carga/guarda avance, responde preguntas, guarda orden, repaso, tema y calcula progreso/logros/puntos. |
| `lib/domain/gamification.dart` | 281 | Reglas G-01/G-02/G-03: 10 puntos por actividad, catálogo estático de 10 logros, 4 temas visuales y evaluación de condiciones. |
| `lib/domain/content_search.dart` | 107 | Búsqueda local CU-09: normaliza mayúsculas/acentos, exige 3 caracteres, prioriza títulos y genera fragmentos resaltados. |
| `lib/domain/catalog_validation.dart` | 59 | Validador que devuelve lista de errores (D-S1-01) y permite estados vacíos; usado por `LearningController` antes de mostrar la UI. |
| `lib/features/cu08/activity_models.dart` | 67 | Modelos de CU-08 (`ActivityDefinition`, `ActivityState`, `CompletionOutcome`) y contrato `ActivityStore`. |
| `lib/features/cu08/activity_engine.dart` | 121 | Motor C05→C06→C07: valida elementos, evita dobles premios, otorga 10 puntos y logros L-03/L-04/L-05, con cola de escritura. |
| `lib/features/cu08/activity_page.dart` | 134 | Pantalla de la actividad CU-08 (ordenamiento de pasos) y manejo de estados pendiente/realizada. |
| `lib/ui/app.dart` | 1,232 | Tema visual, `MaterialApp`, navegación y pantallas `HomeScreen`, `ModuleScreen`, `TopicScreen`, `LessonScreen`, `QuestionsScreen`, `PracticeScreen`; declara los `part`. |
| `lib/ui/review_screens.dart` | 256 | `part of app.dart`: pantallas de repaso CU-07 (`ReviewEntry`, `ReviewListScreen`, `ReviewQuestionScreen`). |
| `lib/ui/sprint2_screens.dart` | 437 | `part of app.dart`: pantallas de puntos, actividades, logros, búsqueda y accesos del Sprint 2. |

**HECHO** — `lib/features/cu08` es el único directorio de funcionalidad por caso de uso; el resto de CU vive en `ui/app.dart` y `ui/sprint2_screens.dart`.

### 3.2 `test/` — 20 archivos, 3,677 líneas

| Archivo | Líneas | Responsabilidad (1 línea) |
| --- | ---: | --- |
| `test/support.dart` | 20 | Doble de prueba `MemoryStore` para `ProgressStore` con fallos simulados de lectura/escritura. |
| `test/app_test.dart` | 126 | Pruebas de interfaz y RNF05: pantalla estrecha y texto ampliado siguen siendo navegables. |
| `test/audit_evidence_test.dart` | 78 | Evidencia TU-02: respuesta correcta muestra retroalimentación y registra avance. |
| `test/progress_test.dart` | 130 | Dominio CU-01/CU-02/CU-03, datos corruptos y catálogo con diez temas e IDs únicos. |
| `test/catalog_integrity_test.dart` | 80 | Integridad CAT-02: rechaza respuestas correctas fuera de rango y entradas inválidas. |
| `test/module_exploration_test.dart` | 364 | CU-05: inicio, módulos, temas, subtemas y estados sin completar por navegar. |
| `test/cu06_achievements_test.dart` | 416 | G-02/G-03: catálogo de logros/temas, fechas, desbloqueos y no recompensa por consultar. |
| `test/cu08_activity_engine_test.dart` | 154 | CU-08: lectura sin escritura, primera actividad, repetición, intento incompleto y logros L-03/L-04/L-05. |
| `test/cu08_activity_page_test.dart` | 65 | CU-08 UI: estados visibles, sin escritura y navegación delegada. |
| `test/cu08_shared_store_test.dart` | 88 | Adaptador CU-08: conserva respuestas, repaso, tema y recompensas existentes en el almacén compartido. |
| `test/cu09_search_test.dart` | 312 | CU-09: normalización, mínimo de caracteres, ranking, resaltado y casos de pantalla estrecha. |
| `test/fix_ds101_validar_catalogo_test.dart` | 146 | D-S1-01: catálogo válido, errores por tipo, estados vacíos y mensaje “Contenido no disponible”. |
| `test/fix_ds102_orden_actividad_test.dart` | 106 | D-S1-02: orden de presentación estable y actividades pequeñas o con muchos IDs. |
| `test/fix_ds103_iconos_progreso_test.dart` | 99 | D-S1-03: cada estado tiene icono propio y los badges usan el mismo icono que las listas. |
| `test/fix_h01_respuesta_repetida_test.dart` | 134 | H-01: reintento tras respuesta incorrecta y respuesta repetida que no vuelve a contar. |
| `test/points_consultation_test.dart` | 397 | CU-10/G-01: total local, cero sin actividades, carga pendiente y actualización solo tras guardar. |
| `test/review_test.dart` | 286 | CU-07: selección, error, reintento, guardado, estados vacíos y error de recuperación. |
| `test/review_cu08_refresh_test.dart` | 76 | Revisión CU-08: al volver de la actividad se refleja como realizada. |
| `test/sprint2_test.dart` | 388 | Integración de G-03, CU-06/CU-08/CU-09/CU-10 y manejo de errores de carga. |
| `test/wp14_cu05_cu10_test.dart` | 212 | Casos WP14 de CU-05 a CU-10: temas únicos, relaciones ambiguas, recompensas ausentes y consulta de puntos. |

### 3.3 `integration_test/` — 8 archivos, 1,074 líneas

| Archivo | Líneas | Responsabilidad (1 línea) |
| --- | ---: | --- |
| `integration_test/offline_test.dart` | 113 | RF-08: el almacenamiento nativo real sobrevive a la recreación del controlador. |
| `integration_test/evidence_test.dart` | 102 | Recorrido offline de dos fases y persistencia real del proceso; genera evidencias. |
| `integration_test/sprint2_design_test.dart` | 168 | Recorrido integral del diseño del Sprint 2 en dispositivo. |
| `integration_test/cu05_offline_test.dart` | 138 | CU-05 en modo avión sin modificar el estado nativo. |
| `integration_test/cu06_logros_offline_test.dart` | 162 | CU-06: obtener, consultar y conservar logros sin conexión. |
| `integration_test/cu07_offline_test.dart` | 111 | CU-07: repaso offline con persistencia. |
| `integration_test/cu09_busqueda_offline_test.dart` | 131 | CU-09: buscar y abrir contenido offline sin cambios de estado. |
| `integration_test/cu10_offline_test.dart` | 149 | CU-10: puntos offline y conservación del total. |

### 3.4 `test_driver/` y `tool/`

| Archivo | Líneas | Responsabilidad (1 línea) |
| --- | ---: | --- |
| `test_driver/evidence_driver.dart` | 17 | Driver de integración que escribe capturas en `PSPS_EVIDENCE_DIR` (por defecto `evidence/`). |
| `test_driver/design_driver.dart` | 24 | Driver de integración para capturas del diseño; escribe `capturas.txt` con los nombres. |
| `tool/build_android.ps1` | 14 | `flutter pub get` + `flutter build apk --debug` usando el almacén de certificados de Windows. |
| `tool/instalar_android.bat` | 5 | Lanzador de Windows para `instalar_android.ps1`. |
| `tool/instalar_android.ps1` | 18 | Analiza, prueba, compila e instala el APK en el primer teléfono Android conectado. |
| `tool/verify_sprint2_android.ps1` | 52 | Copia temporal del proyecto, cambia `applicationId` a `mx.edu.uaz.psps.integration` y ejecuta una prueba de integración concreta. |
| `tool/verifications/defects_sprint01_verification_test.dart` | 150 | Verificación de defectos del Sprint 1 fuera de `test/`; no la ejecuta `flutter test` por defecto. |

**HECHO** — `tool/verify_sprint2_android.ps1` referencia el archivo `android/app/build.gradle.kts` y exige la cadena literal `applicationId = "mx.edu.uaz.psps"`; si cambia el ID de la app, el script falla.

### 3.5 `docs/`, `UML_fuentes/` y `Pruebas/`

| Archivo | Líneas | Responsabilidad (1 línea) |
| --- | ---: | --- |
| `docs/DISENO_SPRINT2.md` | 74 | Decisiones de diseño e implementación del Sprint 2 (CU-05 a CU-10, G-01 a G-03). |
| `docs/CU07_REPASO.md` | 66 | Alcance, reglas y pruebas de CU-07; declara versión 0.2.0-dev.1+2 y base `develop` (5a816f1). |
| `docs/GUIA_DEMO.md` | 47 | Guía de instalación y demostración; está enfocada al APK y a la versión 0.1.0+1 del Sprint 1. |
| `docs/SPRINT_1.md` | 88 | Alcance y evidencias históricas del Sprint 1; documento heredado dentro del proyecto del Sprint 2. |
| `UML_fuentes/PSPS_DiagramaCasosDeUso.puml` | 43 | Fuente PlantUML del diagrama de casos de uso. |
| `UML_fuentes/PSPS_DiagramaClases.puml` | 104 | Fuente PlantUML del diagrama de clases. |
| `UML_fuentes/PSPS_DiagramaEstados.puml` | 31 | Fuente PlantUML del diagrama de estados. |
| `UML_fuentes/PSPS_DiagramaSecuencia.puml` | 35 | Fuente PlantUML del diagrama de secuencia. |
| `Pruebas/REPRODUCIR.md` | 83 | Pasos para reproducir pruebas, pero **habla del Sprint 1** y ordena `cd "Sprint 1/psps_academy"`; está desactualizado dentro del proyecto del Sprint 2. |
| `Pruebas/evidencias/` | 16 archivos | Evidencias del Sprint 1 copiadas al proyecto del Sprint 2: `analyze_final.log`, `build.log`, `dispositivo.json`, `E01`–`E08` (PNG), `flutter_test_final.log`, `inspecciones.md`, `integration.log`, `offline_prepare_final.log`, `offline_verify_final.log`. |

**HECHO** — las ocho capturas `E01`–`E08` de `Pruebas/evidencias/` pesan entre 153,097 y 187,661 bytes cada una; el total de esa carpeta es de aproximadamente 1.4 MB. **HECHO** — `Pruebas/REPRODUCIR.md` contiene la cadena `cd "Sprint 1/psps_academy"` en la línea 14 y por tanto no corresponde al árbol del Sprint 2.

---

## 4. `pubspec.yaml`, dependencias y SDK

**HECHO** — archivo `Sprint 2/psps_academy/pubspec.yaml` (25 líneas):

| Campo | Valor |
| --- | --- |
| `name` | `psps` (no `psps_academy`) |
| `description` | Aplicación educativa offline de Ingeniería de Software con diseño del Sprint 2 |
| `publish_to` | `'none'` |
| `version` | `0.2.0+5` |
| `environment.sdk` | `^3.13.2` |
| `flutter.uses-material-design` | `true` |
| `assets` / `fonts` | No declarados |

Dependencias directas **HECHO**:

| Tipo | Paquete | Restricción |
| --- | --- | --- |
| dependency | `flutter` | SDK |
| dependency | `cupertino_icons` | `1.0.9` (fijada exacta) |
| dependency | `shared_preferences` | `^2.5.6` |
| dev_dependency | `flutter_driver` | SDK |
| dev_dependency | `flutter_test` | SDK |
| dev_dependency | `integration_test` | SDK |
| dev_dependency | `flutter_lints` | `^6.0.0` |

Versiones resueltas relevantes en `pubspec.lock` (385 líneas) **HECHO**:

| Paquete | Versión resuelta |
| --- | --- |
| `shared_preferences` | 2.5.6 |
| `shared_preferences_android` | 2.4.28 |
| `shared_preferences_foundation` | 2.5.7 |
| `shared_preferences_linux` | 2.4.1 |
| `shared_preferences_web` | 2.4.3 |
| `shared_preferences_windows` | 2.4.1 |
| `shared_preferences_platform_interface` | 2.4.2 |
| `cupertino_icons` | 1.0.9 |
| `flutter_lints` | 6.0.0 |
| `lints` | 6.1.0 |
| `leak_tracker` | 11.0.2 |
| `matcher` | 0.12.20 |
| `meta` | 1.18.3 |
| `test_api` | 0.7.12 |
| `vm_service` | 15.3.0 |
| `web` | 1.1.1 |
| `webdriver` | 3.2.0 |
| `integration_test`, `flutter_test`, `flutter_driver`, `flutter` | 0.0.0 (paquetes del SDK) |

**HECHO** — `pubspec.lock` declara:

```yaml
sdks:
  dart: ">=3.13.2 <4.0.0"
  flutter: ">=3.44.0"
```

**HECHO** — el `README.md` del proyecto exige “Flutter 3.47.2 con Dart 3.13.2 o una versión compatible” (línea 17). **HECHO** — hay una discrepancia de versión: `pubspec.yaml` dice `0.2.0+5`, el `README.md` del proyecto dice `0.2.0-dev.2+3` (línea 3) y `Sprint 2/README.md` usa ambas (`0.2.0+5` en el título y `0.2.0-dev.2+3` en el cuerpo). **PENDIENTE** — decidir cuál es la versión canónica al migrar.

No hay dependencias de red, base de datos, estado global de terceros, generación de código ni internacionalización. **HECHO**.

---

## 5. Assets, fuentes, imágenes e iconos

- **HECHO** — no existe carpeta `assets/`, `fonts/`, `images/` ni `res/raw/` en `Sprint 2/psps_academy`.
- **HECHO** — `pubspec.yaml` no declara la sección `flutter.assets` ni `flutter.fonts`; solo `uses-material-design: true`.
- **HECHO** — el contenido educativo (módulos, temas, lecciones, preguntas y actividades) está en código: `lib/data/catalog.dart` (369 líneas). El archivo define 4 `CourseModule(` y 10 llamadas al helper `_topic(` (una por tema); el `README.md` y `docs/SPRINT_1.md` declaran 20 preguntas y 10 actividades.
- **HECHO** — no hay imágenes de contenido ni sprites; las capturas PNG del repo son evidencias de pruebas, no assets de la app.
- **HECHO** — iconos de launcher Android: 5 PNG en `android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png`, con tamaños de 442 a 1,443 bytes. Por su tamaño parecen los iconos por defecto de la plantilla Flutter; **SUPUESTO**, no se verificó visualmente.
- **HECHO** — iconos iOS: 15 PNG en `ios/Runner/Assets.xcassets/AppIcon.appiconset/` (tamaños de 282 a 10,932 bytes) y 3 PNG de `LaunchImage.imageset`.
- **HECHO** — web: `web/favicon.png` (917 B) y 4 iconos en `web/icons/` (`Icon-192.png` 5,292 B, `Icon-512.png` 8,252 B, `Icon-maskable-192.png` 5,594 B, `Icon-maskable-512.png` 20,998 B).
- **HECHO** — no hay imagen de splash: `android/app/src/main/res/drawable/launch_background.xml` usa `@android:color/white` y el `drawable-v21` equivalente; los estilos usan `Theme.Light.NoTitleBar` / `Theme.Black.NoTitleBar`.
- **HECHO** — no hay fuentes personalizadas; la app depende de la tipografía del tema Material.

---

## 6. Android

### 6.1 Archivos presentes

**HECHO** — inventario de `Sprint 2/psps_academy/android/`:

| Archivo | Líneas / tamaño | Responsabilidad |
| --- | ---: | --- |
| `android/settings.gradle.kts` | 26 líneas | Carga `local.properties`, incluye el build de Flutter y fija versiones de plugins. |
| `android/build.gradle.kts` | 24 líneas | Repositorios `google()`/`mavenCentral()`, redirección del build a `../../build` y tarea `clean`. |
| `android/gradle.properties` | 6 líneas | JVM `-Xmx8G`, `android.useAndroidX=true`, `android.newDsl=false`, `android.builtInKotlin=false`. |
| `android/gradle/wrapper/gradle-wrapper.properties` | 5 líneas | Distribución `gradle-9.3.1-all.zip`. |
| `android/app/build.gradle.kts` | 49 líneas | `namespace`/`applicationId`, Java 17, SDK desde Flutter, `versionCode`/`versionName` desde pubspec y firma. |
| `android/app/src/main/AndroidManifest.xml` | 46 líneas | Activity principal, tema, label `PSPS Academy`, icono, `queries` de PROCESS_TEXT. |
| `android/app/src/debug/AndroidManifest.xml` | 8 líneas | Permiso `INTERNET` solo para depuración. |
| `android/app/src/profile/AndroidManifest.xml` | 8 líneas | Permiso `INTERNET` solo para perfilado. |
| `android/app/src/main/kotlin/mx/edu/uaz/psps/MainActivity.kt` | 5 líneas | `class MainActivity : FlutterActivity()` en el paquete `mx.edu.uaz.psps`. |
| `android/app/src/main/res/values/styles.xml` | 21 líneas | `LaunchTheme` y `NormalTheme` en modo claro. |
| `android/app/src/main/res/values-night/styles.xml` | 21 líneas | Variantes de tema para modo oscuro. |
| `android/app/src/main/res/drawable/launch_background.xml` | 13 líneas | Fondo de arranque (color blanco). |
| `android/app/src/main/res/drawable-v21/launch_background.xml` | 13 líneas | Variante API 21+ del fondo de arranque. |
| `android/app/src/main/res/mipmap-*/ic_launcher.png` | 5 archivos | Iconos de launcher en cinco densidades. |

### 6.2 Configuración comprobada

- **HECHO** — `namespace = "mx.edu.uaz.psps"` y `applicationId = "mx.edu.uaz.psps"` (`android/app/build.gradle.kts`, líneas 8 y 19).
- **HECHO** — `MainActivity.kt` usa el mismo paquete (`package mx.edu.uaz.psps`).
- **HECHO** — `compileSdk`, `minSdk`, `targetSdk`, `ndkVersion`, `versionCode` y `versionName` se toman de las variables de Flutter (`flutter.compileSdkVersion`, `flutter.minSdkVersion`, `flutter.targetSdkVersion`, `flutter.versionCode`, `flutter.versionName`), no están fijados en el repo. **PENDIENTE** — fijarlos si la migración exige compilaciones reproducibles.
- **HECHO** — Java/Kotlin: `sourceCompatibility`/`targetCompatibility` Java 17 y `jvmTarget = JVM_17`.
- **HECHO** — plugins Gradle: AGP `com.android.application` 9.1.0, Kotlin `org.jetbrains.kotlin.android` 2.4.0 y `dev.flutter.flutter-plugin-loader` 1.0.0 (`android/settings.gradle.kts`, líneas 20–24).
- **HECHO** — Gradle 9.3.1 (`gradle-wrapper.properties`).
- **HECHO** — permisos: el manifest principal **no declara `uses-permission`**; `INTERNET` aparece únicamente en `src/debug` y `src/profile`, por lo que la build de release no pide red.
- **HECHO** — firma: `buildTypes.release` usa `signingConfig = signingConfigs.getByName("debug")` con comentarios `TODO`; no hay `key.properties` ni keystore de release.
- **HECHO** — el label visible es `PSPS Academy` y el icono `@mipmap/ic_launcher` (`AndroidManifest.xml`, líneas 3–5).
- **HECHO** — no existe `mipmap-anydpi-v26/` ni icono adaptativo; solo PNG por densidad.

### 6.3 Qué se debe regenerar localmente

**HECHO** — no están en el repo y el `.gitignore` los excluye o no existen:

- `android/gradlew`, `android/gradlew.bat` y `android/gradle/wrapper/gradle-wrapper.jar` (el `.gitignore` del proyecto los ignora expresamente en las líneas 10–12).
- `android/local.properties` (ignorado en la línea 9). Es **obligatorio** para configurar Gradle: `android/settings.gradle.kts` lee `local.properties` y lanza un error si falta `flutter.sdk` (líneas 2–9).
- `.dart_tool/`, `.flutter-plugins`, `.flutter-plugins-dependencies`, `.packages`, `build/`, `coverage/` (ignorados en las líneas 2–7).
- `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java` (ignorado, se genera).
- `.metadata` del proyecto: no existe en `Sprint 2/psps_academy` (la plantilla del tag sí lo tenía). **PENDIENTE** — decidir si se regenera con `flutter create .` o se crea manualmente.
- Para publicar: keystore de release y `android/key.properties` (no existen). **PENDIENTE**.

**SUPUESTO** — con `flutter pub get` y una compilación Android se regeneran `.dart_tool/`, `GeneratedPluginRegistrant` y, si se ejecuta la plantilla, el wrapper. No se ejecutó Flutter en esta tarea, por lo que no está verificado.

---

## 7. iOS y web

### 7.1 iOS

**HECHO** — archivos presentes en `Sprint 2/psps_academy/ios/` (39 archivos en total):

- `ios/Flutter/AppFrameworkInfo.plist`, `Debug.xcconfig`, `Release.xcconfig`.
- `ios/Runner.xcodeproj/project.pbxproj`, `project.xcworkspace/*`, `xcshareddata/xcschemes/Runner.xcscheme`.
- `ios/Runner.xcworkspace/*`.
- `ios/Runner/AppDelegate.swift`, `SceneDelegate.swift`, `Info.plist`, `Runner-Bridging-Header.h`.
- `ios/Runner/Base.lproj/LaunchScreen.storyboard`, `Main.storyboard`.
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/*` (15 PNG) y `LaunchImage.imageset/*` (3 PNG).
- `ios/RunnerTests/RunnerTests.swift`.

**HECHO** — `PRODUCT_BUNDLE_IDENTIFIER = mx.edu.uaz.psps` y `mx.edu.uaz.psps.RunnerTests`; `IPHONEOS_DEPLOYMENT_TARGET = 15.0`; `CFBundleDisplayName = PSPS` (`ios/Runner.xcodeproj/project.pbxproj`, `ios/Runner/Info.plist`).

**HECHO** — no hay `Podfile`, `Podfile.lock`, `Pods/`, `ios/Flutter/Generated.xcconfig` ni `ios/Flutter/ephemeral/` en el árbol.

**PENDIENTE** — iOS no está compilado ni probado; el `README.md` del proyecto lo declara expresamente (“iOS aún no está verificado”, línea 3, y “requiere compilación, firma y pruebas con macOS/Xcode”, línea 72). No se puede validar en Windows.

### 7.2 Web

**HECHO** — archivos presentes en `Sprint 2/psps_academy/web/`:

- `web/index.html` (1,533 B): plantilla Flutter con `<base href="$FLUTTER_BASE_HREF">`, título `PSPS`, descripción y `flutter_bootstrap.js`.
- `web/manifest.json` (924 B): nombre `PSPS`, `display: standalone`, colores `#164E3C`, orientación `portrait-primary`, 4 iconos.
- `web/favicon.png` y `web/icons/Icon-192.png`, `Icon-512.png`, `Icon-maskable-192.png`, `Icon-maskable-512.png`.

**PENDIENTE** — no hay evidencia de compilación o prueba web en el repo; el diseño y las pruebas se centran en Android. El contenido de `Sprint 2/README.md` no menciona una verificación web.

---

## 8. Archivos obsoletos, temporales, generados y documentación/evidencias

### 8.1 Clasificación

| Categoría | Archivos / rutas | Recomendación (no vinculante) | Estado |
| --- | --- | --- | --- |
| Código de la app a migrar | `lib/`, `test/`, `integration_test/`, `test_driver/`, `android/`, `ios/`, `web/`, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `.gitignore`, `README.md` | Migrar al repo nuevo como base del proyecto. | **HECHO** (contenido) / **PENDIENTE** (decisión final) |
| Documentación técnica útil | `docs/DISENO_SPRINT2.md`, `docs/CU07_REPASO.md`, `UML_fuentes/*.puml` | Conservar; son fuente de alcance y diagramas. | **HECHO** |
| Documentación histórica dentro de la app | `docs/SPRINT_1.md`, `docs/GUIA_DEMO.md`, `Pruebas/REPRODUCIR.md` | Mover a `docs/legacy/` o excluir; `REPRODUCIR.md` está desactualizado (habla del Sprint 1). | **HECHO** (desactualización) / **PENDIENTE** (decisión) |
| Evidencias dentro de la app | `Pruebas/evidencias/` (16 archivos, ~1.4 MB) | No son necesarias para compilar; conservar en `docs/legacy/evidence/` o fuera del repo. | **HECHO** (contenido) / **PENDIENTE** (decisión) |
| Evidencias y documentación del Sprint 2 (fuera de la app) | `Sprint 2/Pruebas/` (157 archivos), `Sprint 2/05 Pruebas y Calidad/` (29 archivos), `Sprint 2/Construccion/`, `Sprint 2/Defectos/`, `Sprint 2/Diseno/`, `Sprint 2/04 Construccion/APK/README.md` | No forman parte del build; si se conservan, llevarlas a `docs/legacy/` o a un repo de evidencias. | **HECHO** (contenido) / **PENDIENTE** (decisión) |
| Documentación del repo raíz | `README.md`, `Retrospectiva de la primera iteración.pdf`, `docs/Sprint 1/` (22 archivos: PDF/DOCX/XLSX), `Sprint 2/README.md`, `Sprint 2/BackLog.md` | Son documentos de gestión; evaluar `docs/legacy/` o exclusión. No son necesarios para compilar. | **HECHO** (inventario) / **PENDIENTE** (decisión) |
| Proyecto Sprint 1 completo | `Sprint 1/psps_academy/` (107 archivos) | No migrar como app: el Sprint 2 lo reemplaza. Conservar solo si se quiere historia. | **HECHO** (superseded) / **PENDIENTE** (decisión) |
| Artefactos generados o de máquina | `.dart_tool/`, `.flutter-plugins*`, `build/`, `coverage/`, `android/.gradle/`, `android/local.properties`, `android/gradlew*`, `android/gradle/wrapper/gradle-wrapper.jar`, `GeneratedPluginRegistrant.java`, `ios/Pods/`, `ios/.symlinks/`, `ios/Flutter/Generated.xcconfig`, `ios/Flutter/ephemeral/`, `*.apk`, `*.jks`, `*.keystore` | **No migrar**; regenerar o configurar en cada máquina. | **HECHO** (el `.gitignore` los excluye o no están en el snapshot) |
| Pruebas fuera del árbol de test | `tool/verifications/defects_sprint01_verification_test.dart` (150 líneas) | Mover a `test/` o eliminar; `flutter test` no lo ejecuta por defecto. | **HECHO** / **PENDIENTE** (decisión) |
| Pruebas de captura | `test_driver/evidence_driver.dart`, `test_driver/design_driver.dart` | Conservar solo si se mantiene el pipeline de evidencias; no son necesarias para la app. | **HECHO** / **PENDIENTE** (decisión) |
| Duplicado de validación | `lib/data/catalog_validation.dart` y `lib/domain/catalog_validation.dart` | No borrar sin acuerdo: ambos se usan y tienen contratos distintos. Consolidar en una fase posterior. | **HECHO** (duplicado) / **PENDIENTE** (decisión) |

### 8.2 Volumen de documentación y evidencias en el snapshot completo

**HECHO** — el snapshot completo (incluyendo `Sprint 1`, `Sprint 2` y `docs/`) contiene:

| Extensión | Archivos | Tamaño total |
| --- | ---: | ---: |
| `.pdf` | 32 | 7,872,064 B (~7.5 MB) |
| `.docx` | 17 | 10,359,342 B (~9.9 MB) |
| `.png` | 118 | 8,665,751 B (~8.3 MB) |
| `.log` | 96 | 778,132 B (~760 KB) |
| `.xlsx` | 1 | 223,502 B |
| `.md` | 55 | 200,302 B |
| `.json` | 42 | 184,143 B |

**HECHO** — el proyecto `Sprint 2/psps_academy` por sí solo contiene 145 archivos y ~1.9 MB; la mayor parte de los PDF/DOCX/PNG del snapshot está fuera de la app (documentación de sprint, evidencias y planificación).

### 8.3 Hallazgos que conviene resolver antes o durante la migración

1. **L-10 no está en el catálogo estático de logros. HECHO.** `lib/domain/gamification.dart` declara `achievements` con 10 entradas: `L-01` a `L-09` y `L-11`; no hay `Achievement('L-10', ...)`. El campo `reviewedQuestions` y el comentario de la línea 218 existen, y `test/cu06_achievements_test.dart` (CP06-01) verifica explícitamente la lista omitiendo el 10 (`if (i != 10)`); en cambio `README.md`, `docs/DISENO_SPRINT2.md` y el texto de G-02 hablan de 11 logros (L-01 a L-11). **PENDIENTE** — confirmar con el equipo si L-10 se eliminó, quedó pendiente o se implementa en una rama no integrada.
2. **Dos validadores de catálogo. HECHO.** `lib/data/catalog_validation.dart` lanza `FormatException` y `lib/domain/catalog_validation.dart` devuelve `List<String>`; `lib/domain/learning_controller.dart` importa ambos (uno como `identity_validation`). Es deuda técnica de integración, no necesariamente un error funcional.
3. **`README.md` del proyecto desactualizado. HECHO.** Versión `0.2.0-dev.2+3` frente a `0.2.0+5` en `pubspec.yaml`; enlaces a `PSPS_ManualDeUsuario_TSP_Ago26.pdf`, `PSPS_GuiaDeOperacion_TSP_Ago26.pdf`, `PSPS_CasosDePruebaEjecutados_WP14.pdf` y `PSPS_ReporteDePruebas_WP15.pdf` que no existen en el árbol de `develop` (solo estaban en el tag/`Documentacion/`). **HECHO** (búsqueda en el snapshot sin resultados).
4. **`Pruebas/REPRODUCIR.md` apunta al Sprint 1. HECHO.** Es una copia heredada; sus comandos usan `Sprint 1/psps_academy`.
5. **Rutas con distinta capitalización entre ramas. HECHO/SUPUESTO.** `fix-registro-defectos` usa `Sprint 2/defectos` y `develop` usa `Sprint 2/Defectos`; en un filesystem insensible a mayúsculas (Windows/macOS) el merge puede comportarse de forma confusa. Es un riesgo a verificar al integrar la rama, no un defecto del código actual.
6. **Sin verificación de build en esta tarea. PENDIENTE.** No se ejecutó Flutter; por tanto, no se confirmó que `flutter pub get`, `flutter analyze` ni `flutter test` funcionen en el entorno actual. El repo original reporta pruebas aprobadas en su documentación, pero eso no se revalidó aquí.

---

## 9. Propuesta de `.gitignore` para el repo nuevo

Texto propuesto (no se creó ningún archivo; es solo una recomendación). Ajustar a la política del equipo, especialmente la parte de evidencias.

```gitignore
# ---- Flutter / Dart ----
.dart_tool/
.packages
.pub-cache/
.pub/
build/
coverage/
.flutter-plugins
.flutter-plugins-dependencies
*.iml

# ---- IDE / sistema ----
.idea/
.vscode/
.DS_Store
Thumbs.db

# ---- Android ----
android/.gradle/
android/local.properties
android/key.properties
*.jks
*.keystore
android/app/debug/
android/app/profile/
android/app/release/

# El wrapper de Gradle se recomienda versionarlo para compilaciones reproducibles:
# NO ignorar android/gradlew, android/gradlew.bat ni
# android/gradle/wrapper/gradle-wrapper.jar.
# El .gitignore original sí los ignoraba; esta propuesta cambia esa decisión.

# ---- iOS / macOS ----
ios/Pods/
ios/.symlinks/
ios/Flutter/Generated.xcconfig
ios/Flutter/flutter_export_environment.sh
ios/Flutter/ephemeral/
ios/Runner/GeneratedPluginRegistrant.*
macos/Flutter/ephemeral/
macos/Pods/

# ---- Artefactos de compilación ----
*.apk
*.aab
*.ipa
*.app

# ---- Evidencias locales (opcional según política) ----
# Si se decide conservar evidencias en el repo, quitar estas reglas.
# build/design_evidence/
# **/capturas.txt
# **/*.log
```

**Notas:**
- **HECHO** — el `.gitignore` original (`Sprint 2/psps_academy/.gitignore`, 23 líneas) ignora `.dart_tool/`, `.flutter-plugins*`, `.packages`, `build/`, `coverage/`, `android/.gradle/`, `android/local.properties`, `android/gradlew`, `android/gradlew.bat`, `android/gradle/wrapper/gradle-wrapper.jar`, `android/key.properties`, `GeneratedPluginRegistrant.java`, `*.jks`, `*.keystore`, `ios/Flutter/Generated.xcconfig`, `ios/Flutter/flutter_export_environment.sh`, `ios/Flutter/ephemeral/`, `ios/Runner/GeneratedPluginRegistrant.*`, `ios/Pods/`, `ios/.symlinks/` y `*.apk`.
- **SUPUESTO/RECOMENDACIÓN** — en el repo nuevo conviene **versionar el wrapper de Gradle** (a diferencia del original) para que la compilación no dependa de la versión de Gradle instalada en cada máquina. Es una decisión de equipo.
- **PENDIENTE** — decidir si las evidencias (`*.log`, capturas, JSON) se versionan, se mueven a `docs/legacy/` o se excluyen.

---

## 10. Posibles secretos o datos privados

- **HECHO** — no se encontraron archivos `*.jks`, `*.keystore`, `*.p12`, `*.p8`, `*.mobileprovision`, `key.properties`, `local.properties`, `.env` ni tokens en el snapshot.
- **HECHO** — `git grep` sobre `origin/develop -- "Sprint 2"` con patrones de credenciales (`ghp_...`, `github_pat_...`, `AKIA...`, `BEGIN ... PRIVATE KEY`, `xox...`) devolvió **0 coincidencias**.
- **HECHO** — no hay APK versionado en el repo (el `README.md` lo dice y el árbol no contiene `*.apk`).
- **HECHO** — no hay keystore de release; la build de release usa la firma de depuración (`android/app/build.gradle.kts`, líneas 32–38). **PENDIENTE** — crear una clave de release segura antes de publicar.
- **HECHO** — hay **56 archivos** bajo `Sprint 2/` con rutas locales de Windows en logs/JSON, por ejemplo `C:/Users/bolis/Documents/Codex/2026-10-21/seg/work/revision_pr28/...` en `Sprint 2/05 Pruebas y Calidad/Revision por pares/Evidencias_28Oct/cu09_regresion.log` y en otros logs de `Sprint 2/Defectos/`.
- **HECHO** — `Sprint 2/psps_academy/Pruebas/evidencias/dispositivo.json` contiene modelo de teléfono (`24049RN28L`), versión de Android (16), PIDs y comandos `adb`; y los logs de integración pueden contener rutas y nombres de usuario.
- **HECHO** — el `README.md` raíz incluye nombres de integrantes del equipo y el nombre del cliente; son datos personales del proyecto, no secretos, pero deben tratarse con cuidado si el repo nuevo será público.
- **Recomendación (SUPUESTO):** excluir o sanitizar las evidencias/logs del repo nuevo; conservar solo resultados agregados y sin rutas de máquina. No se tomó ninguna decisión al respecto.

---

## 11. Mapa de imports internos de `lib/`

**HECHO** — extraído de las sentencias `import`, `export` y `part` de cada archivo de `lib/` (commit `origin/develop` @ `119ab3e`).

### 11.1 Aristas archivo → archivo

| Origen | Importa a (interno) | Imports externos / notas |
| --- | --- | --- |
| `lib/main.dart` | `data/catalog.dart`, `data/progress_store.dart`, `domain/learning_controller.dart`, `ui/app.dart` | `package:flutter/material.dart` |
| `lib/data/catalog.dart` | `domain/course.dart` | — |
| `lib/data/progress_store.dart` | — | `dart:convert`, `package:shared_preferences/shared_preferences.dart` |
| `lib/data/activity_store.dart` | `domain/learning_controller.dart`, `features/cu08/activity_models.dart` | — |
| `lib/data/catalog_validation.dart` | `domain/course.dart` | — |
| `lib/domain/course.dart` | — | — |
| `lib/domain/learning_controller.dart` | `data/progress_store.dart`, `domain/catalog_validation.dart`, `data/catalog_validation.dart` (como `identity_validation`), `domain/course.dart`, `domain/gamification.dart` | `package:flutter/foundation.dart` |
| `lib/domain/gamification.dart` | `domain/course.dart` | — |
| `lib/domain/content_search.dart` | `domain/course.dart` | — |
| `lib/domain/catalog_validation.dart` | `domain/course.dart` | — |
| `lib/features/cu08/activity_models.dart` | — | — |
| `lib/features/cu08/activity_engine.dart` | `activity_models.dart` | `dart:async` |
| `lib/features/cu08/activity_page.dart` | `activity_engine.dart`, `activity_models.dart` | `dart:async`, `package:flutter/material.dart` |
| `lib/ui/app.dart` | `domain/course.dart`, `domain/learning_controller.dart`, `domain/content_search.dart`, `domain/gamification.dart`, `data/activity_store.dart`, `features/cu08/activity_engine.dart`, `features/cu08/activity_models.dart`, `features/cu08/activity_page.dart` | `package:flutter/material.dart`; `part 'review_screens.dart'` y `part 'sprint2_screens.dart'` |
| `lib/ui/review_screens.dart` | `part of 'app.dart'` | No tiene imports propios. |
| `lib/ui/sprint2_screens.dart` | `part of 'app.dart'` | No tiene imports propios. |

### 11.2 Lectura del grafo

- `lib/domain/course.dart` es la base del modelo: lo importan 7 archivos (`catalog.dart`, `catalog_validation.dart` de data y domain, `learning_controller.dart`, `gamification.dart`, `content_search.dart`, `app.dart`). **HECHO**.
- `lib/domain/learning_controller.dart` es el eje de estado: lo importan `main.dart`, `data/activity_store.dart` y `ui/app.dart`. **HECHO**.
- `lib/ui/app.dart` es el eje de presentación: importa directa o indirectamente casi toda la capa `lib/` y contiene las pantallas base; `review_screens.dart` y `sprint2_screens.dart` son `part` suyos, no módulos independientes. **HECHO**.
- `lib/features/cu08` es el único módulo por funcionalidad; `activity_models.dart` es su contrato, `activity_engine.dart` su lógica y `activity_page.dart` su UI. **HECHO**.
- No se observaron ciclos de imports entre archivos (las relaciones `part` no cuentan como import). **HECHO** según las aristas anteriores; **SUPUESTO** que no hay dependencias ocultas fuera de `lib/`.
- **Deuda técnica observada:** `lib/domain/learning_controller.dart` importa tanto `domain/catalog_validation.dart` como `data/catalog_validation.dart`; la capa de dominio depende además de `data/progress_store.dart`. Para una reorganización posterior conviene mover la interfaz de almacenamiento a dominio y unificar validadores. **HECHO** (imports) / **SUPUESTO** (recomendación de diseño).

---

## Anexo: comandos de verificación usados (solo lectura)

**HECHO** — todos los datos de ramas, tags y árboles se obtuvieron con comandos de lectura sobre `PSPS_SOURCE`, sin `checkout`, `fetch`, `pull`, `commit`, `stash`, `reset` ni escritura:

```sh
git branch -a
git branch -r --merged origin/develop
git branch -r --no-merged origin/develop
git log --oneline origin/develop
git log --oneline origin/<rama>
git diff --name-status origin/develop...origin/<rama>
git diff --stat "origin/develop:Sprint 1/psps_academy" "origin/develop:Sprint 2/psps_academy"
git ls-tree -r --name-only "origin/develop:Sprint 2/psps_academy"
git ls-tree -r -l origin/feature/CU-08-actividades -- "Pruebas/CU08"
git cat-file -t v0.1.0-sprint01
git rev-list --count v0.1.0-sprint01..origin/develop
git describe --tags --always origin/develop
git grep -n -I -E "<patrones-de-secretos>" origin/develop -- "Sprint 2"
```

**PENDIENTE** — la validación funcional (compilar, analizar y ejecutar pruebas) queda fuera de este inventario por restricción explícita de la tarea.

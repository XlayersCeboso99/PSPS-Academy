# Arquitectura de PSPS Academy

Documento de referencia de la estructura actual del código. Describe las capas,
los módulos, sus dependencias, el flujo de datos, la navegación y el mapeo de los
casos de uso CU-01 a CU-10. Se basa en el código de `lib/`; no introduce
componentes ni comportamientos que no existan en él.

## 1. Visión general

PSPS Academy es una aplicación Flutter con un único paquete Dart llamado `psps`.
Funciona sin conexión: el catálogo educativo vive en el código y el avance del
estudiante se guarda en el almacenamiento local del dispositivo. La interfaz se
construye con Material 3 y no usa un gestor de estado externo; el estado
compartido es un `ChangeNotifier` (`LearningController`) al que las pantallas se
suscriben.

## 2. Capas

| Capa | Ruta | Responsabilidad |
| --- | --- | --- |
| Arranque | `lib/main.dart` | Crea el controlador con el catálogo y el almacenamiento local, carga el avance y arranca la aplicación. |
| Aplicación (UI) | `lib/app/` | Widgets, pantallas, tema visual, navegación y presentación de recompensas. |
| Núcleo | `lib/core/` | Modelos del dominio, catálogo, validaciones, persistencia, controlador de aprendizaje y gamificación. No conoce la UI ni las features. |
| Features | `lib/features/` | Lógica y pantallas específicas de un caso de uso que no pertenecen al núcleo: búsqueda (CU-09) y actividades (CU-08). |

Árbol de `lib/`:

```text
lib/
├── main.dart
├── app/
│   ├── app.dart                  (library principal de la UI)
│   ├── review_screens.dart       (part of app.dart)
│   └── sprint2_screens.dart      (part of app.dart)
├── core/
│   ├── models/
│   │   └── course.dart
│   ├── content/
│   │   ├── catalog.dart
│   │   ├── catalog_validation.dart
│   │   └── catalog_identity_validation.dart
│   ├── persistence/
│   │   └── progress_store.dart
│   └── learning/
│       ├── learning_controller.dart
│       └── gamification.dart
└── features/
    ├── search/
    │   └── content_search.dart
    └── activities/
        ├── activity_models.dart
        ├── activity_engine.dart
        ├── activity_page.dart
        └── activity_store.dart
```

## 3. Módulos y responsabilidades

| Archivo | Responsabilidad |
| --- | --- |
| `lib/main.dart` | Punto de entrada. Instancia `LearningController` con `catalog` y `LocalProgressStore`, llama a `load()` y ejecuta `PspsApp`. |
| `lib/app/app.dart` | Library de la UI. Contiene constantes visuales y `academyTheme`, `PspsApp`, `HomeScreen` (pestañas Módulos y Mi progreso), `ModuleScreen`, `TopicScreen`, `LessonScreen`, `QuestionsScreen`, `PracticeScreen`, los widgets reutilizables `StatusBadge` y `ScreenFrame`, y los ayudantes `openScreen`, `reportSave`, `panel`, `caption` y `heading`. |
| `lib/app/review_screens.dart` | `part of 'app.dart'`. Pantallas de CU-07: `ReviewEntry`, `ReviewListScreen` y `ReviewQuestionScreen`. Comparte miembros privados con la library. |
| `lib/app/sprint2_screens.dart` | `part of 'app.dart'`. Pantallas de la segunda entrega: `FeatureLinks`, `PointsScreen` (CU-10), `ActivitiesScreen` (CU-08), `AchievementsScreen` (CU-06) y `SearchScreen` (CU-09). |
| `lib/core/models/course.dart` | Entidades del catálogo: `CourseModule`, `Topic`, `Lesson`, `Question`, `Practice` y el enum `ProgressStatus`. Incluye `Practice.presentationOrder`, que mezcla los pasos de forma determinista por identificador. Cada `Topic` tiene una actividad principal `practice` (`<tema>.a1`) y una lista opcional `extraPractices` (`<tema>.a2`, `<tema>.a3`, …); el getter `practices` devuelve todas, en ese orden, y es lo que usan las reglas de avance, puntos, logros, validación y la UI. |
| `lib/core/content/catalog.dart` | Catálogo educativo local con cuatro módulos (`m1`–`m4`), sus temas, subtemas, preguntas y actividades. Los identificadores son estables porque el avance guardado se asocia a ellos. El ayudante `_topic` acepta `extraPractices` (título, instrucción, pasos) y numera esas actividades por posición a partir de `a2`. |
| `lib/core/content/catalog_legacy.dart` | `legacyContentIds`: conjunto congelado con los 20 identificadores de pregunta y los 10 de actividad del catálogo publicado hasta el Sprint 3, y `legacyView(modules, {legacyIds})`, que devuelve el catálogo restringido a ese contenido (solo preguntas legadas, sin `extraPractices`, omitiendo módulos, temas y subtemas sin contenido legado). Solo se usa para conservar logros ya obtenidos; no se modifica al ampliar el catálogo. |
| `lib/core/content/catalog_validation.dart` | `validateCatalog` de la corrección D-S1-01: devuelve la lista de problemas estructurales del catálogo (identificadores vacíos o repetidos, subtemas sin preguntas, opciones o respuestas inválidas). No modifica datos. |
| `lib/core/content/catalog_identity_validation.dart` | Segundo validador, antes en `lib/data/catalog_validation.dart`, que lanza `FormatException` ante identidades o preguntas inválidas. Se importa con el alias `identity_validation`. |
| `lib/core/persistence/progress_store.dart` | `ProgressSnapshot` (estado serializable), la interfaz `ProgressStore` y `LocalProgressStore`, que usa `SharedPreferencesAsync` con la clave `psps.progress.v1`. Codifica y decodifica JSON con versiones 1 a 3. |
| `lib/core/learning/learning_controller.dart` | `LearningController extends ChangeNotifier`. Centraliza el estado del avance: carga y valida, responde preguntas, guarda actividades, registra repasos, calcula estados y puntos, otorga logros y temas, y notifica a la UI. |
| `lib/core/learning/gamification.dart` | Reglas puras de gamificación: catálogo de diez logros (L-01 a L-09 y L-11), temas visuales (U-00 a U-03), puntos por actividad, evaluación de condiciones y mensajes de recompensa. No lee ni escribe almacenamiento. |
| `lib/features/search/content_search.dart` | `ContentSearch`: búsqueda local por palabra o frase sobre títulos y contenido de los subtemas. Normaliza mayúsculas y acentos, exige un mínimo de caracteres y devuelve resultados con fragmento y posición de la coincidencia. Es de solo lectura. |
| `lib/features/activities/activity_models.dart` | Modelos de CU-08: `ActivityDefinition`, `ActivityState`, `CompletionOutcome` y la interfaz `ActivityStore`. |
| `lib/features/activities/activity_engine.dart` | `ActivityEngine`: orquesta la consulta y la finalización de actividades, serializa escrituras y calcula los logros y temas que se otorgan por actividades (L-03, L-04, L-05 y U-01) sobre todas las actividades del catálogo actual; conserva los logros ya registrados y nunca otorga uno por la vista legada. |
| `lib/features/activities/activity_page.dart` | `Cu08ActivitiesPage`: lista las actividades por módulo y tema, muestra su estado y delega la apertura al callback `onOpenActivity`. No escribe ni recompensa por sí misma. |
| `lib/features/activities/activity_store.dart` | `LearningActivityStore`: adaptador entre la interfaz `ActivityStore` y el estado compartido del `LearningController`. No crea otra clave de almacenamiento. |

## 4. Reglas de dependencia

- `core` no importa `app` ni `features`.
- `features` puede importar `core`, pero no `app`.
- `app` importa `core` y `features`.
- `main.dart` importa `core` y `app`.
- Dentro de `lib/` los imports usan `package:psps/...` para mantener una ruta
  única y comprobable. La única excepción son las directivas `part` y `part of`
  de la library de UI, que son relativas porque `review_screens.dart` y
  `sprint2_screens.dart` forman parte de `app.dart`.
- Las pruebas, la integración y las verificaciones también importan mediante
  `package:psps/...`.

Contratos de compatibilidad que no deben alterarse sin una migración de datos:
nombre de paquete `psps`, `applicationId`/`namespace` Android
`mx.edu.uaz.psps`, clave de almacenamiento `psps.progress.v1` e identificadores
del catálogo.

## 5. Flujo de datos

1. `main()` llama a `WidgetsFlutterBinding.ensureInitialized()` y crea:
   `LearningController(modules: catalog, store: LocalProgressStore())`.
2. `LearningController.load()` valida el catálogo con `validateCatalog` y con el
   validador de identidades; si es válido, lee el `ProgressSnapshot` desde
   `LocalProgressStore.load()`, comprueba la coherencia de respuestas, repasos,
   actividades y recompensas, y deja `ready = true`. Un catálogo o un estado
   inválido produce un mensaje en `loadError` sin sobrescribir lo guardado.
   Las actividades de un tema son todas las de `Topic.practices`; los puntos
   son 10 por actividad completada (una sola vez por actividad, sin duplicados
   en `rewardedPractices`) y el estado de subtema, tema y módulo depende solo
   de las preguntas, porque las actividades son opcionales.
   **Conservación de logros al ampliar el catálogo.** Un logro guardado es
   válido si su condición se cumple con el catálogo actual o con
   `legacyView(modules)` evaluada con las mismas respuestas, actividades y
   repasos; el tema visual seleccionado es válido si lo desbloquea esa unión.
   Un logro que no se cumple en ninguna de las dos vistas sigue haciendo
   fallar la carga. Al guardar, `_withGamification` conserva con su fecha
   original los logros guardados que sigan siendo válidos por esa regla, junto
   con los que se cumplen con el catálogo actual. Un logro nuevo solo se
   otorga si se cumple con el catálogo actual: la vista legada nunca otorga
   logros (por ejemplo, L-05 «Realiza todas las actividades» exige todas las
   actividades del catálogo vigente a quien no lo tenía guardado). El formato
   de `ProgressSnapshot` no cambia (versión 3).
3. `LocalProgressStore` usa `SharedPreferencesAsync` y la clave
   `psps.progress.v1`. `ProgressSnapshot.encode()` escribe JSON con `version` 2
   cuando no hay datos de gamificación y 3 cuando los hay; `decode()` acepta las
   versiones 1, 2 y 3 y migra en memoria los formatos anteriores.
4. Las pantallas escuchan al controlador mediante `AnimatedBuilder` (en
   `PspsApp`, `HomeScreen` y `ScreenFrame`). Toda acción de escritura
   (`answer`, `saveOrder`, `reviewAnswer`, `selectTheme`) pasa por
   `_commit`: primero llama a `store.save`, y solo si la escritura tiene éxito
   actualiza `_state`, calcula recompensas nuevas y llama a `notifyListeners()`.
   Si falla, conserva el estado anterior, deja `saveError` y la UI muestra el
   aviso correspondiente.
5. `Gamification` calcula logros y temas a partir de los hechos del avance; el
   controlador los incorpora al snapshot. `LearningActivityStore` reutiliza ese
   mismo estado cuando el motor de CU-08 consulta o completa una actividad.
6. `PspsApp` reconstruye `MaterialApp` cuando cambia el tema seleccionado y
   muestra una pantalla de carga o de error de recuperación mientras
   `controller.ready` es falso.

## 6. Navegación

`PspsApp` construye un `MaterialApp` con `home: HomeScreen` y sin tabla de
rutas nombradas. La navegación se hace con `Navigator` y `MaterialPageRoute`:

- El ayudante `openScreen(context, widget)` ejecuta
  `Navigator.of(context).push(MaterialPageRoute<void>(builder: ...))` y es el
  mecanismo usado por la mayoría de las pantallas.
- `HomeScreen` mantiene dos pestañas en un `NavigationBar` (`Módulos` y
  `Mi progreso`); cambiar de pestaña es estado local, no una ruta.
- Desde Inicio se abre `ModuleScreen` al tocar un módulo. La pestaña Mi progreso
  abre `TopicScreen` directamente desde la lista de temas.
- `ModuleScreen` abre `TopicScreen` al tocar un subtema; `TopicScreen` abre
  `LessonScreen` (Estudiar subtema) o `PracticeScreen` (Realizar actividad)
  para cada actividad del tema, que se listan con su estado.
- `LessonScreen` abre `QuestionsScreen` con «Ir a preguntas».
- `ReviewEntry` abre `ReviewListScreen`, que a su vez abre
  `ReviewQuestionScreen`; durante el guardado del repaso `PopScope` bloquea la
  salida.
- El icono de búsqueda de `HomeScreen` abre `SearchScreen`; al tocar un
  resultado se abre `LessonScreen` y la acción «Explorar módulos» usa
  `Navigator.popUntil((route) => route.isFirst)`.
- `FeatureLinks` abre `ActivitiesScreen`, `PointsScreen` y `AchievementsScreen`.
  `ActivitiesScreen` integra `Cu08ActivitiesPage` y, mediante `onOpenActivity`,
  hace `push` de `PracticeScreen` con la actividad elegida (resuelta por su
  identificador dentro de `Topic.practices`) para el flujo normal de CU-02.
- Los botones de volver usan `Navigator.of(context).pop()`.

## 7. Mapeo CU-01 a CU-10

| Caso de uso | Interfaz principal | Lógica y datos | Pruebas representativas |
| --- | --- | --- | --- |
| CU-01 Estudiar subtemas | `LessonScreen` y `QuestionsScreen` en `lib/app/app.dart` | `LearningController.answer`, `Question`/`Lesson` en `lib/core/models/course.dart`, catálogo en `lib/core/content/catalog.dart` | `test/app_test.dart`, `test/progress_test.dart` |
| CU-02 Realizar actividades opcionales | `PracticeScreen` en `lib/app/app.dart` | `LearningController.saveOrder` y `practiceCompleted`, `Gamification.complete`, `Practice.presentationOrder` | `test/progress_test.dart`, `test/cu08_shared_store_test.dart` |
| CU-03 Consultar progreso | Pestaña Mi progreso de `HomeScreen` y `StatusBadge` en `lib/app/app.dart` | `LearningController.statusForQuestions`, `lessonStatus`, `topicStatus`, `moduleStatus`, `ProgressStatus` | `test/audit_evidence_test.dart`, `test/fix_ds103_iconos_progreso_test.dart` |
| CU-04 Completar contenidos | Estados mostrados en módulo, tema y subtema (`lib/app/app.dart`) | Agregación de estados en `LearningController`; estructura en `lib/core/models/course.dart` | `test/progress_test.dart` |
| CU-05 Explorar módulos | `HomeScreen`, `ModuleScreen` y `TopicScreen` en `lib/app/app.dart` | `CourseModule`/`Topic` y catálogo `lib/core/content/catalog.dart` | `test/module_exploration_test.dart`, `integration_test/cu05_offline_test.dart` |
| CU-06 Consultar logros | `AchievementsScreen` en `lib/app/sprint2_screens.dart` | `Gamification` y `LearningController.earnedAchievements`, `unlockedThemes`, `selectTheme` | `test/cu06_achievements_test.dart`, `test/sprint2_test.dart` |
| CU-07 Repasar respuestas incorrectas | `ReviewEntry`, `ReviewListScreen` y `ReviewQuestionScreen` en `lib/app/review_screens.dart` | `LearningController.needsReview`, `pendingReview`, `reviewAnswer`; datos en `ProgressSnapshot.reviewAnswers` | `test/review_test.dart`, `integration_test/cu07_offline_test.dart` |
| CU-08 Consultar actividades | `ActivitiesScreen` en `lib/app/sprint2_screens.dart` y `Cu08ActivitiesPage` en `lib/features/activities/activity_page.dart` | `ActivityEngine`, `ActivityDefinition`/`ActivityState` y `LearningActivityStore` | `test/cu08_activity_engine_test.dart`, `test/cu08_activity_page_test.dart`, `test/review_cu08_refresh_test.dart` |
| CU-09 Buscar contenidos | `SearchScreen` en `lib/app/sprint2_screens.dart` | `ContentSearch` en `lib/features/search/content_search.dart` | `test/cu09_search_test.dart`, `integration_test/cu09_busqueda_offline_test.dart` |
| CU-10 Consultar puntos | `PointsScreen` en `lib/app/sprint2_screens.dart` | `LearningController.points` y `Gamification.pointsPerPractice` | `test/points_consultation_test.dart`, `integration_test/cu10_offline_test.dart` |

## 8. Cómo añadir un nuevo caso de uso

1. **Definir el contrato y los datos.** Añadir o reutilizar entidades en
   `lib/core/models/`. Si el caso de uso necesita contenido nuevo, incorporarlo
   a `lib/core/content/catalog.dart` con identificadores estables y sin cambiar
   los existentes. Si cambia el formato persistido, ampliar
   `ProgressSnapshot` con una nueva versión y mantener la lectura de las
   anteriores en `decode()`.
2. **Ubicar la lógica.** Si es una regla transversal (progreso, puntos, logros)
   va en `lib/core/learning/`. Si es lógica propia del caso de uso, crear
   `lib/features/<nombre>/` con modelos y un motor o servicio puro, sin importar
   `lib/app/`. La lógica nueva no debe leer ni escribir almacenamiento
   directamente: usa el controlador o una interfaz de almacenamiento.
3. **Construir la interfaz.** Crear la pantalla con inyección explícita del
   `LearningController` (y del motor o callback que necesite). Si la pantalla
   debe compartir miembros privados de la library de UI, añadirla como `part`
   en `lib/app/`; en caso contrario, dejarla en el directorio de la feature o en
   `lib/app/` como archivo independiente y abrirla con `openScreen`.
4. **Conectar la navegación.** Añadir el punto de entrada en `HomeScreen`,
   `FeatureLinks` o la pantalla que corresponda, usando `openScreen` o
   `MaterialPageRoute` como el resto de la aplicación.
5. **Añadir pruebas.** Crear un archivo nuevo en `test/` (por ejemplo
   `test/cuXX_descripcion_test.dart`) y, si aplica, una prueba en
   `integration_test/`. No modificar aserciones ni pruebas existentes para
   acomodar el comportamiento nuevo.
6. **Validar y documentar.** Ejecutar `flutter analyze`, `flutter test` y
   `dart format` sobre los archivos nuevos o modificados.
   Actualizar este documento y la trazabilidad de `docs/audit/` si el caso de
   uso es nuevo.

## 9. Validación del proyecto

Comandos usados para comprobar esta estructura:

```sh
flutter pub get
flutter analyze
flutter test
flutter test tool/verifications/defects_sprint01_verification_test.dart
```

Resultados verificados tras la integración: `flutter analyze` sin incidencias,
148 pruebas aprobadas en `test/` (140 heredadas + 8 de `test/regression/`) y 5
en la verificación de defectos del Sprint 1. `dart format --set-exit-if-changed`
aún señala 7 archivos heredados sin formato (ver `docs/SPRINT3_PREPARATION.md`).
`integration_test/` contiene las 8 pruebas de integración y `test_driver/` los
drivers de evidencias.

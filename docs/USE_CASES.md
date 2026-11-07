# Casos de uso CU-01 a CU-10

Descripción del comportamiento **implementado** en `0.2.0+5`, tal como lo fijan el código y las pruebas. La trazabilidad completa (contratos de origen, pruebas y evidencias históricas, huecos) está en [audit/TRAZABILIDAD_CU01_CU10.md](audit/TRAZABILIDAD_CU01_CU10.md). Rutas según la estructura de [ARCHITECTURE.md](ARCHITECTURE.md).

Los documentos de requisitos originales (SRS v0.1, diseños de Sprint 2) están en el repositorio `TSP_PSPS`. Cuando esta descripción y un documento heredado difieran (p. ej., el logro L-10), prevalece el comportamiento probado y la adenda de integración del 29/10/2026.

## Reglas transversales

- **Offline:** contenido, búsqueda y progreso son locales; la app no usa red.
- **Persistencia:** un único estado JSON en `SharedPreferences`, clave `psps.progress.v1`, `version` 3. Se recuperan formatos 1 y 2 sin escribir hasta la siguiente acción. Si guardar falla, el estado anterior se conserva y se informa el error.
- **Primera respuesta:** cuenta la primera respuesta de cada pregunta; responder de nuevo actualiza la retroalimentación pero no cuenta otra vez (RP-02, H-01).
- **G-01:** 10 puntos por cada actividad completada por primera vez y guardada; nunca por repetir, consultar, repasar ni por logros.
- **Consultar no escribe:** progreso, actividades, logros, puntos y búsqueda no modifican el estado.

## CU-01 Estudiar subtemas

El estudiante abre un subtema, lee contenido y ejemplo, responde sus preguntas y recibe retroalimentación inmediata (correcta/incorrecta y explicación). Leer no cambia el avance; salir conserva lo respondido. Código: `LessonScreen`, `QuestionsScreen` (`lib/app/app.dart`), `LearningController.answer`.

## CU-02 Realizar actividades opcionales

Ordenar pasos en la secuencia correcta. El orden de presentación es mezclado y estable (D-S1-02). Al completar correctamente se registra automáticamente y se otorgan 10 puntos una sola vez; un orden parcial o incorrecto no da premio. Las actividades no bloquean temas ni módulos. Código: `PracticeScreen`, `LearningController.saveOrder`, `Practice.presentationOrder`.

## CU-03 Consultar progreso

Estados por subtema, tema y módulo: **Sin iniciar** (ninguna respuesta), **En progreso** (algunas), **Completado** (todas), cada uno con texto, ícono propio y color (D-S1-03). Código: `LearningController.statusForQuestions`, `StatusBadge`.

## CU-04 Completar contenidos

Subtema completo al responder todas sus preguntas (no se exige acertar); tema completo con todos sus subtemas; módulo completo con todos sus temas. Las actividades no cuentan para completar. Código: `lessonStatus`, `topicStatus`, `moduleStatus`.

## CU-05 Explorar módulos

Inicio muestra los 4 módulos; cada módulo sus temas y subtemas. Navegación libre: cualquier módulo es accesible sin completar los anteriores. El catálogo se valida antes de usarse (IDs únicos, preguntas válidas, D-S1-01). Código: `HomeScreen`, `ModuleScreen`, `TopicScreen`, `validateCatalog`.

## CU-06 Consultar logros

Diez logros: L-01 Primer paso, L-02 Subtema completo, L-03 Manos a la obra, L-04 Práctica constante, L-05 Todas las prácticas, L-06 a L-09 (un módulo completo cada uno), L-11 Recorrido completo. Se muestran con condición y fecha de obtención; el aviso de premio aparece una vez. Temas visuales: U-00 Bosque (inicial), U-01 Océano (L-03), U-02 Atardecer (cualquiera de L-06…L-09), U-03 Noche (L-11). Un tema bloqueado no se puede elegir; el elegido persiste. **L-10 no existe** en el catálogo vigente. Código: `Gamification` (`lib/core/learning/gamification.dart`), `AchievementsScreen`.

## CU-07 Repasar respuestas incorrectas

Desde un tema o módulo, **Repasar preguntas** lista las preguntas respondidas mal originalmente y aún no resueltas en repaso. Equivocarse mantiene la pregunta pendiente; acertar y guardar la retira. Sin opción seleccionada no se puede comprobar; salir sin comprobar no registra nada. El repaso no cambia respuestas originales, avance, puntos, logros ni tema. Código: `ReviewListScreen`, `ReviewQuestionScreen` (`lib/app/review_screens.dart`), `LearningController.reviewAnswer`.

## CU-08 Consultar actividades

Lista de actividades agrupadas por módulo y tema con estado **Pendiente** / **Realizada**. Consultar no escribe; abrir una actividad delega en CU-02 y al volver la lista se actualiza. Comparte el mismo estado que el resto de la app. Código: `lib/features/activities/`.

## CU-09 Buscar contenidos

Búsqueda local a partir de 3 caracteres, mientras se escribe. Ignora mayúsculas, acentos (á é í ó ú ü), saltos de línea y espacios externos; conserva la ñ. Busca en títulos (primero) y contenido de subtemas; no en preguntas, opciones, explicaciones ni actividades. Un resultado por subtema con ruta, fragmento resaltado y estado; abrirlo no cambia el avance. Código: `ContentSearch` (`lib/features/search/`), `SearchScreen`.

## CU-10 Consultar puntos

Muestra el total local de puntos (cero real si no hay recompensas). Mientras carga o si la lectura falla no muestra un cero falso; permite reintentar sin reiniciar datos. No hay historial de transacciones. Código: `PointsScreen`, `LearningController.points`.

## Fuera de alcance

CU-11 y CU-12 no están implementados (planificados para Sprint 3 o posteriores).

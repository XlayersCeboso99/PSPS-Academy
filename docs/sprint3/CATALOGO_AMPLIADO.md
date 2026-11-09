# Auditoría de regresión del catálogo ampliado

Fecha de revisión: 9 de noviembre de 2026. Paquete: `psps`. Base examinada: `319c8d4` (`feat(content): expand catalog to 40 questions and 20 activities`).

## Alcance y resultado

La ampliación incorpora veinte preguntas y diez actividades, conservando los cuatro módulos, diez temas y diez subtemas existentes. El inventario actual contiene cuarenta preguntas y veinte actividades; el inventario histórico contiene veinte preguntas y diez actividades. Los treinta identificadores históricos conservan su pertenencia a módulo, tema y subtema, así como su orden relativo; en particular, CT-05 permanece en m3.

Se reprodujeron individualmente las trece fallas de la línea base mediante `flutter test <archivo> --plain-name "<nombre completo de la prueba>" --reporter expanded`. Todas corresponden a la categoría **(a), dependencia de un conteo o estructura legítimamente ampliados**. No se identificó una regresión de comportamiento, categoría (b), en esas trece fallas. Esta conclusión se limita a las aserciones reproducidas y a la cobertura descrita en este informe.

La suite pasó de **209 pruebas: 196 aprobadas y 13 fallidas**, a **216 aprobadas y 0 fallidas**, con siete pruebas nuevas. No se modificaron archivos de `lib/`, dependencias ni proyectos de plataforma.

## Inventario de preguntas nuevas

La posición de respuesta se expresa desde 1. El tema evaluado describe el objetivo conceptual del reactivo; no constituye una validación curricular externa.

| Tema y módulo | ID | Pregunta | Respuesta correcta | Posición | Tema que evalúa |
| --- | --- | --- | --- | --- | --- |
| CT-01 · m1 | `CT-01.s1.q3` | Si una matriz tiene 3 filas y 4 columnas, ¿cuántas celdas contiene? | 12 | 3 | Número de celdas: filas por columnas. |
| CT-01 · m1 | `CT-01.s1.q4` | Para visitar todas las celdas de una matriz fila por fila, ¿qué estructura es la más adecuada? | Dos ciclos anidados: filas por fuera y columnas por dentro | 2 | Recorrido de una matriz por filas. |
| CT-02 · m1 | `CT-02.s1.q3` | Si la pila es [A, B, C] y C está en la cima, ¿qué queda después de dos operaciones pop? | [A] | 1 | Extracción sucesiva con LIFO. |
| CT-02 · m1 | `CT-02.s1.q4` | ¿Por qué una pila es adecuada para implementar «deshacer» en un editor? | Porque la última acción realizada es la primera que se revierte | 2 | Aplicación de LIFO a deshacer. |
| CT-03 · m1 | `CT-03.s1.q3` | En la cola [A, B, C], ¿dónde se agrega un nuevo elemento D con enqueue? | Al final, después de C | 2 | Inserción al final de una cola. |
| CT-03 · m1 | `CT-03.s1.q4` | Una impresora compartida atiende los trabajos en el orden en que llegan. ¿Qué estructura modela mejor esa espera? | Una cola | 1 | Aplicación de FIFO a trabajos pendientes. |
| CT-04 · m1 | `CT-04.s1.q3` | Al comparar 5 y 2 para ordenar de menor a mayor, ¿qué hace el método burbuja? | Los intercambia | 1 | Intercambio de vecinos fuera de orden. |
| CT-04 · m1 | `CT-04.s1.q4` | Si en una pasada completa del método burbuja no hubo ningún intercambio, ¿qué se puede concluir? | La lista ya está ordenada | 3 | Criterio de terminación de burbuja. |
| CT-05 · m3 | `CT-05.s1.q3` | ¿Qué instrucción consulta datos sin modificarlos? | SELECT | 2 | Consulta de datos frente a modificación. |
| CT-05 · m3 | `CT-05.s1.q4` | ¿Qué ocurre al ejecutar DELETE FROM estudiante; sin una condición WHERE? | Se eliminan todas las filas de la tabla | 3 | Alcance de DELETE sin filtro. |
| CT-06 · m2 | `CT-06.s1.q3` | Si el bloque try termina sin errores, ¿qué ocurre con catch y finally? | Catch no se ejecuta; finally sí | 2 | Flujo normal y limpieza de recursos. |
| CT-06 · m2 | `CT-06.s1.q4` | ¿Qué práctica es más adecuada al capturar una excepción en el ejemplo? | Informar el problema y dejar el sistema en un estado consistente | 3 | Manejo explícito de errores. |
| CT-07 · m2 | `CT-07.s1.q3` | En Java, ¿qué palabra usa una interfaz para ampliar otra interfaz? | extends | 1 | Herencia entre interfaces. |
| CT-07 · m2 | `CT-07.s1.q4` | Una clase concreta implementa Coloreada, no hereda area() de ninguna otra clase y solo define color(). ¿Qué ocurre en Java? | No compila, salvo que la clase se declare abstracta | 3 | Cumplimiento del contrato heredado. |
| CT-08 · m2 | `CT-08.s1.q3` | En el ejemplo, ¿qué es nombre? | Un atributo | 1 | Distinción entre estado y comportamiento. |
| CT-08 · m2 | `CT-08.s1.q4` | Si cambias el nombre del objeto 1 a «Ana María», ¿qué ocurre con el objeto 2? | Conserva su nombre, Luis | 2 | Estado independiente de las instancias del ejemplo. |
| CT-09 · m3 | `CT-09.s1.q3` | En el modelo, ¿qué es el identificador de un estudiante? | Un atributo | 1 | Atributos de una entidad. |
| CT-09 · m3 | `CT-09.s1.q4` | Cada estudiante tiene exactamente una credencial y cada credencial pertenece a un solo estudiante. ¿Cuál es la cardinalidad? | Uno a uno | 2 | Cardinalidad con participación singular en ambos extremos. |
| CT-10 · m4 | `CT-10.s1.q3` | ¿Por qué conviene que un botón conserve su nombre y ubicación en pantallas equivalentes? | Por consistencia: la persona lo reconoce sin volver a aprenderlo | 1 | Consistencia de controles. |
| CT-10 · m4 | `CT-10.s1.q4` | Si falla el guardado de una respuesta, ¿qué mensaje es más útil? | «No se pudo guardar tu respuesta. Intenta de nuevo.» con un botón Reintentar | 3 | Retroalimentación y recuperación ante errores. |

Las posiciones correctas de las veinte preguntas nuevas se distribuyen entre las tres opciones: posición 1, siete preguntas; posición 2, siete; posición 3, seis. La prueba exige diversidad de posiciones, sin imponer una distribución estadística particular.

## Inventario de actividades nuevas

Los pasos se muestran en el orden canónico de resolución. La presentación al estudiante utiliza una permutación distinta tanto de este orden como de su inverso.

| Tema y módulo | ID y título | Pasos en orden correcto |
| --- | --- | --- |
| CT-01 · m1 | `CT-01.a2` · Recorre la matriz | 1. matriz[0][0] → 4<br>2. matriz[0][1] → 7<br>3. matriz[1][0] → 2<br>4. matriz[1][1] → 9 |
| CT-02 · m1 | `CT-02.a2` · Deshaz una acción | 1. Push: escribir «Hola»<br>2. Push: aplicar negrita<br>3. Pop: se deshace la negrita<br>4. El texto queda como «Hola» sin formato |
| CT-03 · m1 | `CT-03.a2` · Atiende turnos | 1. Entran A, B y C<br>2. Sale A<br>3. Sale B<br>4. C sigue esperando su turno |
| CT-04 · m1 | `CT-04.a2` · Primera pasada | 1. [5, 1, 4, 2]<br>2. [1, 5, 4, 2]<br>3. [1, 4, 5, 2]<br>4. [1, 4, 2, 5] |
| CT-05 · m3 | `CT-05.a2` · Elimina con cuidado | 1. SELECT: confirmar la fila con id = 2<br>2. DELETE con WHERE id = 2<br>3. SELECT: comprobar que la fila ya no existe |
| CT-06 · m2 | `CT-06.a2` · Lectura sin errores | 1. Intentar leer el archivo<br>2. La lectura termina sin excepción<br>3. Se omite el bloque catch<br>4. Liberar los recursos en finally |
| CT-07 · m2 | `CT-07.a2` · Cumple el contrato | 1. Declarar class Circulo implements Coloreada<br>2. Implementar los métodos area() y color()<br>3. Compilar sin métodos del contrato pendientes<br>4. Asignar un Circulo a una variable de tipo Figura |
| CT-08 · m2 | `CT-08.a2` · Dos instancias | 1. Definir la clase Estudiante con el atributo nombre<br>2. Crear a Ana y a Luis como instancias<br>3. Cambiar el nombre de Ana<br>4. Verificar que Luis conserva su nombre |
| CT-09 · m3 | `CT-09.a2` · Modela una tutoría | 1. Identificar Profesor y Estudiante<br>2. Definir la relación «es tutor de»<br>3. Indicar la cardinalidad uno a muchos |
| CT-10 · m4 | `CT-10.a2` · Recupérate de un error | 1. La persona toca Guardar<br>2. La interfaz muestra «Guardando…»<br>3. Aparece un mensaje claro con la opción Reintentar<br>4. La persona reintenta y ve «Respuesta guardada» |

## Conservación de logros y datos

`legacyContentIds` congela los treinta IDs anteriores: `CT-01` a `CT-10`, con preguntas `.s1.q1` y `.s1.q2`, y actividad `.a1`. `legacyView(catalog)` restringe los datos actuales a ese conjunto, manteniendo sus padres. Se protege la correspondencia mediante el oráculo literal de `test/regression/legacy_catalog_fixture.dart`, utilizado por INV-01 y por MIG-01 en sus tres versiones. El oráculo conserva los treinta IDs explícitos y la jerarquía original, sin obtener sus valores esperados del catálogo que se examina.

Un logro **ya guardado** se acepta si cumple su condición con el catálogo actual **o** con la vista legada, conservando su fecha original, incluso si esta es nula por falta de fecha histórica. Los logros que aún no estaban guardados solo se reconocen u otorgan según el catálogo actual. La ampliación no convierte las diez actividades históricas en las veinte necesarias para un nuevo L-05, ni completa automáticamente un subtema con solo dos de sus cuatro preguntas. Los logros no se usan para otorgar puntos adicionales.

La prueba EXP-05 guarda un `ProgressSnapshot` v3 en un `ProgressStore` en memoria, con veinte respuestas, diez actividades resueltas, cien puntos, los diez IDs legados recompensados, L-01…L-09 y L-11 con fechas distintas y U-03 seleccionado. La carga utiliza el catálogo real de cuarenta preguntas y veinte actividades, sin inyectar una vista reducida. Se verifica `ready == true`, ausencia de errores y de escrituras durante la carga, fechas y tema íntegros. El avance actual es 20/40, aunque los logros obtenidos con el catálogo anterior se conservan.

Resolver `CT-01.a2` eleva el total a 110 puntos. Se compara el JSON completo con el estado anterior más esa actividad y su recompensa: versión 3, respuestas, repasos, órdenes anteriores, logros con sus fechas y U-03. `rewardedPractices` conserva exactamente los IDs anteriores y el nuevo en el orden del catálogo, que es el orden de serialización existente; no se presume un orden cronológico de inserción. Repetir la actividad antes y después de volver a abrir el estado no genera otra escritura ni otros diez puntos, y L-05 conserva su fecha original.

EXP-06 comprueba que un usuario nuevo no obtiene L-05 tras completar las diez actividades `.a1`, incluso después de reabrir el estado; tampoco lo obtiene antes de la última actividad restante. Lo obtiene al completar las veinte actividades actuales y conserva su fecha al recargar.

EXP-07 usa `SharedPreferencesAsyncPlatform` en memoria y los almacenes locales reales. Antes de empezar guarda una nota y un recordatorio válidos. Después de cada respuesta nueva y de cada actividad `.a2`, y tras reabrir el progreso, exige igualdad exacta de `psps.notes.v1` y `psps.reminder.v1`. Solo se agrega la clave de progreso esperada.

## Clasificación de las trece fallas

Las líneas citadas corresponden a la base `319c8d4`, antes de formatear o adaptar las pruebas. En la tabla, (a) significa supuesto del catálogo anterior y (b) regresión real. Las trece filas se ejecutaron individualmente con su nombre original completo mediante `--plain-name`.

| N.º | Archivo y prueba original | Evidencia de la falla | Clase | Adaptación y significado preservado |
| --- | --- | --- | --- | --- |
| 1 | `test/app_test.dart:53` · CU01: navigate, read without progress, answer incorrectly and finish subtopic | Esperaba `completed`; obtuvo `inProgress` tras dos respuestas de cuatro. | (a) | Responder todas las preguntas restantes mediante la interfaz; comprobar el estado parcial antes de cada respuesta, la cantidad final y la finalización exacta. Se conserva la primera respuesta incorrecta y la lectura sin avance. |
| 2 | `test/cu06_achievements_test.dart:89` · CP06-01: catalog G-02 (L-01 to L-11) and G-03 (U-00 to U-03) | Esperaba 10 actividades; obtuvo 20. | (a) | Comparar exactamente las actividades del controlador con todas las `topic.practices`, incluyendo orden e identidad. Permanecen los catálogos y condiciones de logros y temas visuales. |
| 3 | `test/cu06_achievements_test.dart:142` · CP06-03: L-01 with the first answer, even incorrect; L-02 with a full lesson; dated once | Esperaba `['L-02']`; obtuvo `[]` tras responder solo dos preguntas. | (a) | Responder las restantes; exigir ausencia de L-02 antes de la última, aviso exacto al finalizar y conservación de fecha sin doble escritura. |
| 4 | `test/cu06_achievements_test.dart:248` · CP06-08: each achievement shows name, met condition and date or «Fecha no disponible» (CA-06) | `earnedAchievements['L-02']` era nulo; el operador `!` produjo `TypeError`. | (a) | Completar las cuatro preguntas antes de consultar la fecha; conservar las verificaciones exactas de nombres, condición, fecha histórica ausente, fecha nueva y consulta sin escrituras. |
| 5 | `test/points_consultation_test.dart:385` · CP10-16: total has an accessible label and fits narrow enlarged text | Esperaba un texto `100 pts`; encontró cero coincidencias después de completar veinte actividades, cuyo total es 200. | (a) | Derivar el total del número de actividades por la recompensa unitaria; exigir el total exacto visible y semántico en pantalla estrecha con texto ampliado. |
| 6 | `test/progress_test.dart:33` · CU01/CU03: wrong answers count; viewing is read-only; repeats do not count twice | Esperaba `completed`; obtuvo `inProgress` al responder primera y última pregunta. | (a) | Responder todas las restantes; preservar error inicial, repetición sin doble conteo, estados exactos de subtema, tema y módulo, y comprobación del total de respuestas. |
| 7 | `test/regression/catalog_inventory_test.dart:16` · INV-01: migrated catalog keeps all historical IDs and parent links | Esperaba 20 preguntas; obtuvo 40. El recorrido antiguo de `topic.practice` seguía contando solo 10 actividades. | (a) | Separar oráculo histórico literal e inventario actual exacto 40/20; recorrer `topic.practices`, exigir unicidad global de IDs y patrón de los treinta IDs agregados. Conservar módulos, temas, subtemas y padres históricos exactos. |
| 8 | `test/regression/migration_characterization_test.dart:91` · MIG-01 v1: keyed JSON loads read-only until an action saves v3 | Esperaba 3/20 = 0.15; obtuvo 3/40 = 0.075. | (a) | Derivar numerador de la fixture y denominador del catálogo; mantener JSON literal, todos los valores migrados, la consulta sin escritura y el guardado v3 exacto. Añadir el oráculo de treinta IDs y padres. |
| 9 | `test/regression/migration_characterization_test.dart:91` · MIG-01 v2: keyed JSON loads read-only until an action saves v3 | Esperaba 0.15; obtuvo 0.075. | (a) | Aplicar el mismo cálculo derivado, conservando respuestas de repaso y las demás aserciones de migración v2. |
| 10 | `test/regression/migration_characterization_test.dart:91` · MIG-01 v3: keyed JSON loads read-only until an action saves v3 | Esperaba 0.15; obtuvo 0.075. | (a) | Aplicar el mismo cálculo derivado, conservando fechas, puntos, tema, consultas sin escritura y JSON v3 exacto. |
| 11 | `test/regression/migration_characterization_test.dart:266` · MIG-03 G-01: every catalog ID rewards once across draft reloads | Esperaba 10 actividades completas; obtuvo 20. | (a) | Derivar cantidad y puntos de todas las actividades actuales, y exigir igualdad exacta de sus IDs recompensados; conservar borradores, órdenes incorrectos, recargas y recompensa única para cada ID. |
| 12 | `test/sprint2_test.dart:64` · G02: ten approved achievements; activities never complete modules | Esperaba 100 puntos; obtuvo 200. | (a) | Derivar el total de actividades por puntos unitarios y exigir el mismo total antes y después de responder preguntas; conservar el conjunto exacto de diez logros, exclusión de L-10 y desbloqueos. |
| 13 | `test/sprint3/multi_activity_model_test.dart:228` · legacyView el conjunto congelado coincide con el catálogo real actual | Esperaba 20 preguntas; obtuvo 40 antes de llegar a la igualdad de IDs. | (a) | Comparar el conjunto congelado y la vista legada exactamente con el subconjunto histórico del catálogo actual; conservar conteos históricos 20/10/30 y comparaciones ordenadas. Renombrar la prueba para expresar la conservación de la vista legada. |

No se eliminó ninguna garantía de las aserciones existentes ni se sustituyó una igualdad por una desigualdad permisiva. La lista literal de INV-01 se trasladó al oráculo compartido, donde sigue comprobándose exactamente y además se contrasta con `legacyContentIds`. CP06-01 pasó de comprobar solo cantidad a comprobar todos los elementos en su orden. MIG-03 pasó de contar IDs recompensados a compararlos exactamente con el conjunto esperado. Los mínimos de cuarenta preguntas y veinte actividades de EXP-01 corresponden al requisito de calidad nuevo; INV-01 conserva los totales exactos del inventario publicado.

## Cobertura adicional y revisión de pruebas de integración

`test/sprint3/catalog_expansion_test.dart` incorpora siete pruebas:

| Prueba | Garantía |
| --- | --- |
| EXP-01 | Cuatro módulos, diez temas, al menos cuarenta preguntas y veinte actividades; IDs únicos en todos los niveles. |
| EXP-02 | Todas las cuarenta preguntas: tres opciones como mínimo, no vacías y distintas sin mayúsculas, diacríticos ni espacios extremos; índice correcto válido, explicación no vacía y distinta del enunciado, y ningún enunciado duplicado bajo la misma normalización. |
| EXP-03 | Todas las veinte actividades: título e instrucción no vacíos, títulos únicos, tres pasos como mínimo, pasos no vacíos y únicos; presentación como permutación completa, distinta del orden canónico y de su inverso. |
| EXP-04 | Las respuestas nuevas ocupan más de una posición. |
| EXP-05 | Compatibilidad del usuario legado completo y recompensa nueva idempotente con persistencia v3 exacta. |
| EXP-06 | L-05 para usuarios nuevos exige todas las actividades actuales. |
| EXP-07 | Responder y resolver contenido nuevo conserva las claves de notas y recordatorios. |

Se revisaron los ocho archivos de `integration_test/` y el archivo de `tool/verifications/` buscando cantidades globales antiguas, selección de una sola actividad y finalización de subtemas con dos preguntas.

| Archivo revisado | Resultado y cambio |
| --- | --- |
| `integration_test/evidence_test.dart` | **Modificado**: responder todas las preguntas del subtema, derivar el número recuperado de `lesson.questions.length` y abrir la actividad principal mediante su ID, evitando la etiqueta repetida «Realizar actividad» tras agregar `.a2`. Se conserva el recorrido de lectura, error, finalización, actividad y reapertura. |
| `integration_test/offline_test.dart` | Sin cambios: ya responde `catalog.first.questions` y deriva el total al reabrir. Una actividad da diez puntos por contrato, sin representar el total del catálogo. |
| `integration_test/cu05_offline_test.dart` | Sin cambios: la fixture recorre todas las preguntas del módulo que desea completar. |
| `integration_test/cu06_logros_offline_test.dart` | Sin cambios: prueba deliberadamente la primera actividad y su logro, con pasos derivados; los diez logros son el catálogo de recompensas, que no cambió. |
| `integration_test/cu07_offline_test.dart` | Sin cambios: el pendiente de repaso representa una respuesta incorrecta específica, no el tamaño de un subtema. |
| `integration_test/cu09_busqueda_offline_test.dart` | Sin cambios: conserva un estado de muestra con una pregunta y una actividad y compara datos antes/después. |
| `integration_test/cu10_offline_test.dart` | Sin cambios: `take(2)` selecciona intencionalmente dos actividades para verificar diez y veinte puntos; no pretende completar el catálogo. |
| `integration_test/sprint2_design_test.dart` | Sin cambios: el escenario de dos actividades mantiene veinte puntos; la finalización de módulos recorre `c.questions`. |
| `tool/verifications/defects_sprint01_verification_test.dart` | Sin cambios: los tamaños y pasos se derivan del contenido; la actividad principal, la pregunta aislada y el quinto módulo son fixtures deliberadas. La nueva EXP-03 amplía la comprobación del orden de presentación a las veinte actividades reales. |

No se ejecutaron pruebas de integración en dispositivo. El análisis estático incluye esos archivos.

## Revisión crítica del contenido nuevo

Los controles estructurales no detectaron enunciados repetidos, opciones equivalentes por normalización, índices fuera de rango, explicaciones vacías, títulos repetidos ni secuencias insuficientes. Las respuestas y secuencias se revisaron contra los ejemplos y reglas expresados en cada subtema. No se identificó una clave inequívocamente errónea dentro de esos ejemplos, pero quedan las siguientes precisiones editoriales y didácticas; no se modificó contenido.

| Contenido | Observación | Alcance y precisión sugerida |
| --- | --- | --- |
| `CT-07.s1.q4` | «Solo define color()» no especifica si `area()` ya fue implementado en una superclase. La respuesta marcada supone que no existe esa implementación heredada. Además, el enunciado parte de una clase concreta y la opción plantea declararla abstracta. | Explicitar que `area()` no se implementa ni se hereda. Es una ambigüedad del alcance del enunciado; la explicación es coherente con el ejemplo mostrado, que no presenta una superclase. |
| `CT-10.s1.q3` | «El mismo nombre y lugar en todas las pantallas» expresa la consistencia como una regla absoluta de ubicación. | Acotar a controles equivalentes dentro de contextos comparables; la pregunta no distingue cambios de disposición por tamaño de pantalla o contexto. La respuesta sobre reconocimiento sigue siendo pertinente. |
| `CT-06.s1.q4` | «La mejor práctica» agrupa informar, registrar y recuperar un estado válido sin delimitar cuándo el código puede recuperarse. | Presentarlo como objetivo del manejo en el ejemplo, evitando sugerir que toda excepción debe resolverse localmente. Entre las alternativas ofrecidas, la clave es consistente con el texto del subtema. |
| `CT-05.s1.q4` y `CT-05.a2` | La explicación de DELETE y la expresión «eliminar de forma segura» modelan una ejecución simple y exitosa. La actividad comprueba identidad antes y ausencia después, sin abordar fallos, concurrencia o reversión. | Delimitar el ejercicio a una tabla de ejemplo y al objetivo de filtrar por ID; no presentar esa secuencia introductoria como protocolo completo de seguridad de datos. |

**Atención de observaciones.** Se precisó la redacción de `CT-07.s1.q4` (se
indica que `area()` no se hereda de otra clase), `CT-10.s1.q3` (consistencia en
pantallas equivalentes) y `CT-06.s1.q4` (práctica adecuada en el contexto del
ejemplo). Los identificadores, las opciones y las respuestas correctas no
cambiaron. La observación sobre `CT-05` se mantiene como alcance didáctico: la
actividad es introductoria y no pretende describir un protocolo completo de
seguridad de datos.

Estas observaciones no demuestran una regresión del programa. La validación curricular y la eventual precisión del contenido requieren una revisión separada; la presente auditoría documenta las ambigüedades sin alterar `lib/`.

## Evidencia de validación

| Comprobación | Resultado observado |
| --- | --- |
| Línea base, `flutter test --reporter expanded` | 196 aprobadas, 13 fallidas: 209 pruebas. |
| Reproducción individual de las trece fallas con `--plain-name` | Trece salidas fallidas con la evidencia consignada en la tabla de clasificación. |
| `dart format` en todos los archivos Dart modificados | Archivos formateados. |
| `flutter test --no-pub --reporter expanded` después de los cambios | `216: All tests passed!` |
| `flutter analyze` | `No issues found!` |
| `flutter test tool/verifications/defects_sprint01_verification_test.dart --reporter expanded` | `5: All tests passed!` |
| `git diff --check` | Sin errores de espacios o parches. |

Las cinco verificaciones específicas se ejecutan por separado y no se incluyen en el total de 216 de `test/`. La evidencia valida el comportamiento automatizado descrito; no acredita ejecución móvil ni aprobación curricular.

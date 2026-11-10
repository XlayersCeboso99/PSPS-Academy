# Trazabilidad de CU-11 y CU-12 — Sprint 3, ID 21

## Propósito, alcance y evidencia

Este documento relaciona los requisitos y criterios identificados en el cambio de origen con los archivos públicos del paquete `psps` y las pruebas adaptadas al destino. La referencia documental y de código es el repositorio `PSPS_SOURCE`, rama `test/sprint3-cu11-cu12-id21`, commit `a285d4c`, en el intervalo `119ab3e..a285d4c`. Las rutas de las suites originales se ubican bajo `Sprint 2/psps_academy/`.

La correspondencia de producción se basa en el contrato de rutas de integración. La existencia de una prueba describe cobertura prevista; no acredita que el comportamiento se haya ejecutado o aprobado en el destino. En esta entrega, los componentes de notas y recordatorios todavía deben integrarse con las pruebas y todos los resultados funcionales permanecen pendientes.

Los identificadores CU-11, CA-12, A5, E1, E2, ID23, TU-S3-11, TW-S3-11, TU-S3-12 y TW-S3-12 aparecen en nombres de prueba del origen; CU-12, RF-13 y CA-13 también están expresamente asociados en el comentario de `ReminderController`. No se asignan identificadores de requisito adicionales sin evidencia. A5, E1 y E2 se interpretan dentro del contexto de CU-11; ID23 conserva la etiqueta original y no sustituye al ID 21 de esta entrega.

## Matriz de requisitos, criterios y pruebas

En esta tabla, las rutas abreviadas de prueba `cu11_notes_test.dart`, `cu12_reminders_test.dart`, `cu11_quality_test.dart`, `cu12_quality_test.dart` y `cu11_cu12_isolation_test.dart` corresponden, sin excepción, a `test/sprint3/`. Los nombres o identificadores indicados permiten localizar cada caso dentro de su suite. `lib/app/app.dart` es la fachada pública contratada para `PspsApp`, las pantallas y sus ámbitos de estado.

| Requisito o criterio | Comportamiento verificable | Archivo de producción destino | Prueba(s) destino | Resultado |
| --- | --- | --- | --- | --- |
| CU-11 / CA-12 | Crear, editar, restaurar y eliminar una nota por subtema, sin alterar el avance | `lib/features/notes/notes_controller.dart`; `lib/features/notes/notes_store.dart`; `lib/app/app.dart` | `cu11_notes_test.dart`: `CA-12 create, edit, restore and delete without changing progress`, `CU-11 normal entry points save, edit, discard and delete`; `cu11_quality_test.dart`: TU-S3-11-06; `cu11_cu12_isolation_test.dart`: `CU-11 aislamiento: guardar, editar y eliminar conserva avance y premios` | pendiente de ejecución en integración |
| CA-12 | Rechazar texto vacío y respetar el límite de 1000 caracteres Unicode | `lib/features/notes/notes_controller.dart`; `lib/app/app.dart` | `cu11_notes_test.dart`: `CA-12 validates empty input and Unicode length boundaries`, `ID23 delayed load preserves saved text and enforces editor limit` | pendiente de ejecución en integración |
| CU-11 / A5 | Abrir el editor desde Mis notas y conservar el texto ante un fallo de guardado | `lib/app/app.dart`; `lib/features/notes/notes_controller.dart` | `cu11_notes_test.dart`: `A5 opens subtopic editor from list; failed save retains text` | pendiente de ejecución en integración |
| CU-11 / E1 | Un fallo de creación, edición o eliminación conserva el estado anterior y permite reintentar | `lib/features/notes/notes_controller.dart`; `lib/app/app.dart` | `cu11_notes_test.dart`: `E1 failed save/delete preserves previous note and allows retry`; `cu11_quality_test.dart`: TU-S3-11-22, TW-S3-11-23 | pendiente de ejecución en integración |
| CU-11 / E2 | Ocultar notas de subtemas retirados sin borrarlas al guardar otras notas | `lib/features/notes/notes_controller.dart`; `lib/features/notes/notes_store.dart` | `cu11_notes_test.dart`: `E2 hidden orphan notes survive saving another subtopic` | pendiente de ejecución en integración |
| CU-11 / ID23 | Proteger el cierre durante carga o escritura; conservar texto, persistencia y lista al recrear la aplicación | `lib/features/notes/notes_controller.dart`; `lib/features/notes/notes_store.dart`; `lib/app/app.dart` | `cu11_notes_test.dart`: los cuatro casos con prefijo `ID23` | pendiente de ejecución en integración |
| CU-11 / TU-S3-11-19 | Ordenar por fecha descendente y resolver empates por ID sin escribir al consultar | `lib/features/notes/notes_controller.dart` | `cu11_quality_test.dart`: TU-S3-11-19; `cu11_notes_test.dart`: `notes sorted by most recently modified and concurrent writes guarded` | pendiente de ejecución en integración |
| CU-11 / TU-S3-11-24 | Rechazar JSON incompatible o fechas inválidas sin sobrescribir la copia dañada | `lib/features/notes/notes_store.dart`; `lib/features/notes/notes_controller.dart` | `cu11_quality_test.dart`: TU-S3-11-24; `cu11_notes_test.dart`: `unreadable stored notes block writes and can be loaded again` | pendiente de ejecución en integración |
| CU-11 / TU-S3-11-25 | Bloquear escrituras simultáneas mientras hay un guardado pendiente | `lib/features/notes/notes_controller.dart` | `cu11_quality_test.dart`: TU-S3-11-25; `cu11_notes_test.dart`: `notes sorted by most recently modified and concurrent writes guarded` | pendiente de ejecución en integración |
| CU-11 / TW-S3-11-18 | Acceder a Mis notas desde Mi progreso; informar un error de lectura y ofrecer Reintentar | `lib/app/app.dart`; `lib/features/notes/notes_controller.dart` | `cu11_quality_test.dart`: los dos casos TW-S3-11-18 | pendiente de ejecución en integración |
| CU-12 / RF-13 / CA-13 | Mantener un único recordatorio semanal local con días y hora configurables | `lib/features/reminders/reminder_controller.dart`; `lib/features/reminders/reminder_store.dart`; `lib/features/reminders/notification_port.dart`; `lib/app/app.dart` | `cu12_reminders_test.dart`: TU-S3-12-05, TU-S3-12-18, TU-S3-12-25, TW-S3-12-06 y 16 | pendiente de ejecución en integración |
| CU-12 / TU-S3-12-02 / TW-S3-12-01 | Iniciar apagado, con hora sugerida 18:00 y siete días seleccionados | `lib/features/reminders/reminder_store.dart`; `lib/features/reminders/reminder_controller.dart`; `lib/app/app.dart` | `cu12_reminders_test.dart`: TU-S3-12-02, TW-S3-12-01 | pendiente de ejecución en integración |
| CU-12 / TU-S3-12-12 / TU-S3-12-23 / TW-S3-12-13 | Denegar activación sin permiso, conservar la configuración anterior y ofrecer acceso a ajustes | `lib/features/reminders/reminder_controller.dart`; `lib/features/reminders/notification_port.dart`; `lib/app/app.dart` | `cu12_reminders_test.dart`: TU-S3-12-12; `cu12_quality_test.dart`: TU-S3-12-23, TW-S3-12-13 | pendiente de ejecución en integración |
| CU-12 / TU-S3-12-15 / TW-S3-12-06 y 16 | Desactivar y cancelar la programación anterior | `lib/features/reminders/reminder_controller.dart`; `lib/features/reminders/notification_port.dart`; `lib/app/app.dart` | `cu12_reminders_test.dart`: TU-S3-12-15, TW-S3-12-06 y 16; `cu11_cu12_isolation_test.dart`: `CU-12 aislamiento: guardar y desactivar conserva avance y premios` | pendiente de ejecución en integración |
| CU-12 / TU-S3-12-24 / TW-S3-12-04 / TW-S3-12-20 | Validar hora, minutos y días; impedir guardar sin días seleccionados | `lib/features/reminders/reminder_store.dart`; `lib/features/reminders/reminder_controller.dart`; `lib/app/app.dart` | `cu12_reminders_test.dart`: TU-S3-12-24, TW-S3-12-04; `cu12_quality_test.dart`: TU-S3-12-24, TW-S3-12-20 | pendiente de ejecución en integración |
| CU-12 / TU-S3-12-22 | Preservar la programación ante fallo de persistencia y bloquear doble guardado concurrente | `lib/features/reminders/reminder_controller.dart`; `lib/features/reminders/reminder_store.dart` | `cu12_reminders_test.dart`: TU-S3-12-22; `cu12_quality_test.dart`: TU-S3-12-22 | pendiente de ejecución en integración |
| CU-12 / TU-S3-12-28 | Recuperar la configuración previa ante fallo de programación o cancelación e informar recuperación incompleta | `lib/features/reminders/reminder_controller.dart`; `lib/features/reminders/notification_port.dart` | `cu12_reminders_test.dart`: TU-S3-12-28; `cu12_quality_test.dart`: TU-S3-12-28 | pendiente de ejecución en integración |
| CU-12 / TU-S3-12-29 | Reconciliar configuración guardada al cargar; bloquear datos corruptos hasta reintentar e informar permisos retirados | `lib/features/reminders/reminder_controller.dart`; `lib/features/reminders/reminder_store.dart`; `lib/features/reminders/notification_port.dart` | `cu12_reminders_test.dart`: TU-S3-12-29; `cu12_quality_test.dart`: los dos casos TU-S3-12-29 | pendiente de ejecución en integración |
| CU-11 / CU-12: persistencia independiente | Usar exactamente `psps.notes.v1` y `psps.reminder.v1`; conservar la cadena de `psps.progress.v1`, los puntos y los logros | `lib/features/notes/notes_store.dart`; `lib/features/reminders/reminder_store.dart`; `lib/core/persistence/progress_store.dart`; `lib/core/learning/learning_controller.dart` | `cu11_notes_test.dart`: `local store roundtrip preserves text, timestamp and progress key`; `cu12_reminders_test.dart`: `persistencia JSON v1 conserva otras claves de progreso`; `cu11_cu12_isolation_test.dart`: casos de guardar/eliminar notas, guardar/desactivar recordatorios y claves exactas | pendiente de ejecución en integración |
| CU-11: independencia ante corrupción | Un JSON de notas corrupto no impide cargar el avance válido y un avance corrupto no impide cargar, guardar o eliminar notas | `lib/features/notes/notes_store.dart`; `lib/features/notes/notes_controller.dart`; `lib/core/persistence/progress_store.dart`; `lib/core/learning/learning_controller.dart` | `cu11_cu12_isolation_test.dart`: `CU-11 aislamiento: notas corruptas no impiden cargar el avance`, `CU-11 aislamiento: avance corrupto no impide cargar y guardar notas` | pendiente de ejecución en integración |

## Inventario de pruebas por suite

El conteo corresponde a declaraciones `test(` y `testWidgets(`, incluidas aquellas cuyo nombre comienza en la línea siguiente. Un nombre que agrupa varios identificadores cuenta como una sola declaración. Los casos parametrizados mediante bucles internos tampoco incrementan el número de declaraciones.

| Suite de origen | Suite de destino | `test` origen / destino | `testWidgets` origen / destino | Total origen / destino | Procedencia de las pruebas | Resultado |
| --- | --- | --- | --- | --- | --- | --- |
| `test/cu11_notes_test.dart` | `test/sprint3/cu11_notes_test.dart` | 9 / 9 | 4 / 4 | 13 / 13 | `de25a9b`, `0f0a7a2` | pendiente de ejecución en integración |
| `test/cu12_reminders_test.dart` | `test/sprint3/cu12_reminders_test.dart` | 11 / 11 | 3 / 3 | 14 / 14 | `2529a9a` | pendiente de ejecución en integración |
| `test/sprint3/cu11_quality_test.dart` | `test/sprint3/cu11_quality_test.dart` | 5 / 5 | 3 / 3 | 8 / 8 | `6bb1782` | pendiente de ejecución en integración |
| `test/sprint3/cu12_quality_test.dart` | `test/sprint3/cu12_quality_test.dart` | 6 / 6 | 2 / 2 | 8 / 8 | `a285d4c` | pendiente de ejecución en integración |
| Sin antecedente: pruebas nuevas de aislamiento | `test/sprint3/cu11_cu12_isolation_test.dart` | — / 5 | — / 0 | — / 5 | Incorporación del destino para esta entrega | pendiente de ejecución en integración |
| **Total de suites portadas** | **Cuatro suites** | **31 / 31** | **12 / 12** | **43 / 43** | Instantánea `a285d4c` | pendiente de ejecución en integración |
| **Total del destino con aislamiento** | **Cinco suites** | **— / 36** | **— / 12** | **— / 48** | Portadas y nuevas | pendiente de ejecución en integración |

Las pruebas nuevas sustituyen `SharedPreferencesAsyncPlatform.instance` por `InMemorySharedPreferencesAsync.empty()` en cada caso y restauran la instancia anterior al finalizar. Usan los almacenes locales reales y un doble del puerto de notificaciones. Antes de verificar conservación, los casos de operaciones generan avance persistido con puntos mayores que cero y logros no vacíos; comparan la cadena completa antes y después de cada operación y vuelven a cargar `LearningController` para comprobar su estado persistido. La prueba de claves observa también las claves efectivamente escritas, además de las constantes públicas.

## Historial de origen

El listado siguiente corresponde a `git log --oneline 119ab3e..a285d4c`, del más reciente al más antiguo. Los commits de configuración y producción forman parte del intervalo de referencia; no todos introducen pruebas.

| Commit | Asunto original |
| --- | --- |
| `a285d4c` | test(id21): add CU-12 failure-path and widget regression tests |
| `6bb1782` | test(sprint3): add CU-11 quality and widget scenarios for ID 21 |
| `395d184` | ci(cu12): expand verification to full Flutter regression suite |
| `c587a3f` | ci(cu12): validate Flutter analyzer and CU-11/CU-12 tests |
| `09c0301` | fix(cu12): block edits after failed reminder reconciliation |
| `2529a9a` | test(cu12): add reminder controller and widget regression coverage |
| `e46f529` | feat(cu12): integrate reminder UI, Android scheduling setup and dependencies |
| `e5b26fd` | fix(cu12): use platform settings plugin instead of missing native channel |
| `d0290ac` | feat(cu12): add local reminder store, controller and notification adapter |
| `0f0a7a2` | fix(cu11): completar flujo local y proteger cierre durante operaciones |
| `de25a9b` | feat(cu11): guardar notas personales por subtema sin conexion |

La procedencia individual de cada suite se obtuvo consultando el mismo intervalo con su ruta original. Todas las copias corresponden al contenido final de `a285d4c`, no a versiones intermedias.

## Adaptación y límites de la evidencia

Las cuatro suites conservan sus nombres, escenarios, datos, dobles y aserciones. La adaptación se limita a los imports del paquete según el contrato de rutas, los imports relativos `../support.dart` y `../app_test.dart`, y el formato Dart. No hay escenarios omitidos o sustituidos. Los helpers `MemoryStore` y `tapVisible` del destino proporcionan el mismo comportamiento que sus equivalentes del origen; no se modificaron ni se creó un helper adicional.

Los casos `ID23` que recrean controladores o el árbol de widgets comprueban persistencia y ciclo de vida dentro del proceso de prueba. Los casos TU-S3-12-29 verifican la reconciliación al llamar a `load()` mediante un puerto simulado. Ninguno acredita un reinicio físico del teléfono, una alarma real del sistema ni la entrega efectiva de una notificación.

La revisión estática registra igualdad de conteos, ausencia de imports de las antiguas carpetas `data`, `domain`, `ui` y `platform`, y formato de los cinco archivos. La compilación y ejecución de `flutter test test/sprint3` quedan pendientes de integrar los componentes de producción y resolver las dependencias del destino. El formateador puede advertir que todavía no resuelve `package:flutter_lints/flutter.yaml` porque no existe la configuración local de paquetes; esa advertencia no equivale a un resultado funcional.

## Pruebas que requieren dispositivo

| Comprobación | Procedimiento y evidencia esperada | Estado |
| --- | --- | --- |
| Notificación real disparada a la hora | Configurar un día y una hora próximos, dejar la aplicación fuera de primer plano y registrar la hora programada y la hora de entrega visible del aviso | **NO ejecutada** |
| Reinicio del teléfono | Guardar un recordatorio habilitado, reiniciar el teléfono y comprobar la conservación de la configuración y la entrega posterior del aviso | **NO ejecutada** |
| Permisos del sistema | Conceder, denegar y retirar permisos mediante los diálogos y ajustes reales; comprobar la respuesta de la aplicación y la ausencia de programación cuando corresponda | **NO ejecutada** |
| Apertura desde la notificación | Pulsar una notificación real con la aplicación cerrada y en segundo plano; comprobar la apertura y el destino de navegación previsto | **NO ejecutada** |

Estas comprobaciones requieren registrar dispositivo, versión del sistema, configuración, pasos, evidencia y resultado cuando se realicen. Hasta contar con esa evidencia, su estado no constituye aceptación de CU-12, RF-13 o CA-13 en una plataforma física.

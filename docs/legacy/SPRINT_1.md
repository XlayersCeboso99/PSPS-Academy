# PSPS — Incremento de demostración del sprint 1

Versión de la aplicación: **0.1.0+1**. Preparado el 7 de octubre de 2026 para el cierre del Sprint 1 (8 de octubre de 2026). La verificación posterior del 10 de octubre de 2026 se documenta en WP.14, WP.15 y `Sprint 1/Pruebas/evidencias`.

## Alcance utilizado

Se usa la numeración del SRS v0.1 (revisión del 7 de octubre de 2026), coincidente con los diagramas y wireframes. El PDF de casos de uso del 22 de septiembre contiene una numeración anterior. Esta decisión es una referencia de implementación; no constituye aprobación documental de la cliente.

| Caso | Función implementada | Evidencia |
| --- | --- | --- |
| CU-01 | Consultar contenido y ejemplos, avanzar/retroceder, responder preguntas, recibir retroalimentación y conservar respuestas | Prueba de widgets del recorrido; pruebas de dominio |
| CU-02 | Ordenar los elementos de una actividad opcional; registro automático de realización y recompensa de demostración | Prueba de widgets de actividad; pruebas de dominio |
| CU-03 | Ver estados con texto y colores gris/naranja/verde, además del resumen de avance | Pruebas de dominio; revisión de pantallas; prueba de pantalla estrecha |
| CU-04 | Completar subtemas, temas y módulos automáticamente según preguntas respondidas | Prueba de agregación de varios temas, incluyendo respuestas incorrectas |
| CU-05, soporte de navegación | Pantalla principal de módulos y entrada a temas/subtemas | Prueba de widgets del recorrido |
| RF-08, transversal | Guardar respuestas y secuencias de actividad en el dispositivo; reconstruir avance y puntos al abrir | Pruebas de recuperación; recarga comprobada en vista previa web; integración Android aprobada |

La estructura provisional contiene cuatro módulos, los diez temas CT-01 a CT-10, un subtema por tema, veinte preguntas y diez actividades. Cada subtema tiene dos elementos de lectura y dos preguntas. La lógica admite varios subtemas por tema. La agrupación y el contenido no sustituyen la validación D-01.

## Reglas implementadas

- Leer o consultar el progreso no escribe avance.
- Una respuesta comprobada cuenta como respondida, sea correcta o incorrecta.
- Sin respuestas: gris. Algunas respuestas: naranja. Todas las respuestas: verde.
- Tema completo: todos sus subtemas completos. Módulo completo: todos sus temas completos.
- Las actividades no condicionan la finalización del contenido.
- En esta demostración, una actividad se completa al ordenar correctamente sus tres elementos. No existe botón «Finalizar». El borrador se guarda tras cada cambio.
- Se conservan la respuesta original y su retroalimentación; revisarla no aumenta el conteo.
- La recompensa provisional es diez puntos por actividad realizada, una sola vez. Los puntos se reconstruyen desde los registros de actividades, evitando otorgarlos dos veces.
- Un fallo de escritura no publica el cambio como guardado. La persona puede reintentar la misma acción.
- Ante datos inválidos al iniciar, se conserva la copia y se muestra un error recuperable; no se borran automáticamente.

## Decisiones y pendientes

**Acordado por el equipo:** empezar desde cero, Flutter, entrega del sprint el 8 de octubre, versión offline sin servidor por ahora, contenido de demostración y Android disponible. No hay acceso a Mac.

**Provisional:** agrupación de materias, lecciones, preguntas, secuencias y diez puntos por actividad. El catálogo de logros y desbloqueos no se proporcionó. No se implementó la consulta CU-06 ni se atribuyen logros aprobados. CU-02 se demuestra con realización y puntos; su parte de logros requiere el catálogo validado.

**Servidor:** pendiente para una etapa posterior. `ProgressStore` separa almacenamiento y lógica para permitir una evolución posterior; todavía no existe sincronización, autenticación ni resolución de conflictos.

**iOS:** se generó el proyecto de plataforma. Compilación, firma, instalación y pruebas están pendientes por falta de macOS/Xcode. No se presenta iOS como verificado. Ver [requisitos oficiales de Flutter para iOS](https://docs.flutter.dev/platform-integration/ios/setup).

**Calendario:** el Project Plan ubica Sprint 01 del 21 de septiembre al 2 de octubre. La extensión al 8 de octubre se tramita con la solicitud de cambio CR-01, pendiente de la decisión de la cliente; no se atribuye una aprobación del cambio.

## Verificación realizada

| Comprobación | Resultado |
| --- | --- |
| Flutter | 3.47.2, canal stable |
| Dart | 3.13.2 |
| Entorno Android | SDK 36.1.0, licencias aceptadas, JDK Temurin 25.0.3 |
| Git | 2.56.0.windows.1 |
| `flutter pub get` | Completado |
| `flutter analyze` | Sin incidencias |
| `flutter test` | 10 pruebas aprobadas: 7 de lógica y 3 de interfaz |
| `flutter build apk --debug` | APK Android generado |
| Vista previa web | Inicio, módulo, contenido, respuesta incorrecta, finalización de subtema y recuperación de 2/20 respuestas tras recarga comprobados |
| Pantallas pequeñas | Prueba de 390 × 844 para el recorrido; 320 × 640 con texto ampliado 1.4 para inicio/progreso |
| Prueba de integración Android | 1 prueba aprobada en Android 16 (API 36), modelo 24049RN28L; almacenamiento real conserva respuestas, módulo completado y puntos después de recrear el controlador y la interfaz |
| Aplicación normal en Android | Instalada y ejecutada mediante Flutter en el mismo dispositivo después de la prueba de integración |
| Prueba manual Android sin conexión | Pendiente de instalación y recorrido en modo avión |
| iOS | Sin compilar ni probar |

La compilación Android inicialmente falló porque Java no reconocía la cadena de certificados de las descargas. Se compiló utilizando el almacén de certificados confiables de Windows; no se desactivó la validación TLS. El script de construcción limita esa configuración al proceso y restaura la variable anterior.

Estas evidencias no equivalen a aceptación del cliente ni a una declaración de terminado en ambas plataformas. El requisito completo de gamificación también conserva los pendientes descritos.

La instalación por USB fue rechazada en el primer intento. Se habilitó la instalación vía USB en el teléfono y se reintentó; la segunda ejecución completó la instalación y aprobó la prueba. La prueba usa una clave de almacenamiento exclusiva, que se elimina al terminar, y no modifica el progreso normal del estudiante. No sustituye la comprobación manual en modo avión ni una prueba de cierre completo del proceso.

## Arquitectura

- `lib/data/catalog.dart`: material educativo de demostración con identificadores estables.
- `lib/domain/course.dart`: módulos, temas, subtemas, preguntas y actividades.
- `lib/domain/learning_controller.dart`: evaluación de estados, reglas de finalización y recompensas provisionales.
- `lib/data/progress_store.dart`: almacenamiento local versionado mediante SharedPreferencesAsync.
- `lib/ui/app.dart`: pantallas y navegación; estados comunicados con texto e iconos además de color.
- `test/`: pruebas de lógica, recuperación, errores de guardado e interacción.
- `integration_test/`: comprobación con almacenamiento real del dispositivo, usando una clave de prueba distinta del avance del estudiante.

El almacenamiento es apropiado para esta demostración pequeña; no es respaldo ni almacenamiento transaccional de datos críticos. Desinstalar o borrar los datos de la aplicación puede eliminar el avance. No existe recuperación desde servidor. Ver [documentación de shared_preferences](https://pub.dev/packages/shared_preferences).

## Revisión sugerida con el equipo

1. Instalar el APK en Android, recorrerlo en modo avión y comprobar persistencia después de cerrar/reabrir.
2. Validar contenidos y agrupación D-01; acordar puntos, logros y desbloqueos D-02.
3. Registrar el alcance real del sprint y la extensión del Sprint 1 tramitada en CR-01.
4. Gestionar el acceso a macOS/Xcode para verificar iOS posteriormente.
5. Incorporar el código y los resultados reales al repositorio del equipo, sin registrar firmas o aceptaciones que no hayan ocurrido.

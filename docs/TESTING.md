# Pruebas de PSPS Academy

Ejecutar los comandos desde la raíz del proyecto con Flutter y Dart disponibles
en `PATH`. La línea base migrada conserva 140 pruebas; `test/regression/` añade
8, para un total esperado de **148** en `flutter test`. No se suman a ese total
los archivos cargados por el runner ni las suites separadas de dispositivo y
verificación histórica.

## Suites y ejecución local

| Ruta | Alcance | Ejecución | Requiere dispositivo |
| --- | --- | --- | --- |
| `test/` | Pruebas unitarias y de widgets de CU-01…CU-10, incluidos los casos de regresión nuevos | `flutter test` | No |
| `test/sprint3/` | CU-11 y CU-12 (ID 21: escenarios funcionales, de calidad, de fallo y de widgets), aislamiento respecto del avance, modelo de varias actividades por tema, conservación de logros y calidad del catálogo ampliado | `flutter test test/sprint3` | No |
| `test/regression/` | Caracterización de formatos persistidos, recompensas, repaso, tema e inventario de IDs | `flutter test test/regression` | No |
| `tool/verifications/` | Cinco verificaciones históricas de defectos del Sprint 1; fuera del descubrimiento automático de `test/` | `flutter test tool/verifications/defects_sprint01_verification_test.dart` | No |
| `integration_test/` | Ocho objetivos sobre almacenamiento nativo, navegación y recorridos offline | Elegir un objetivo y un dispositivo; ver abajo | Sí |

Validación de cambios en las pruebas nuevas:

```powershell
flutter pub get
flutter analyze
flutter test
dart format --set-exit-if-changed test/regression
git diff --check
```

`flutter analyze` debe terminar sin incidencias y todas las pruebas deben
aprobar. Las regresiones simulan almacenamiento: usan `MemoryStore` o un doble
de `SharedPreferencesAsync` inyectado en el `LocalProgressStore` real. No leen
preferencias del usuario ni prueban el plugin nativo. En las fixtures se mantiene
literalmente la clave contractual `psps.progress.v1`, sin renombrarla a v2/v3;
la versión cambia dentro del JSON.

## Caracterización de la migración

Los comentarios de cada caso citan las pruebas existentes y delimitan la
variante añadida; no se modifican sus aserciones ni el código de producción.

| Caso nuevo | Comportamiento fijado |
| --- | --- |
| `MIG-01 v1`, `MIG-01 v2`, `MIG-01 v3` | JSON literal con respuestas correctas/incorrectas, actividad completa, borrador y orden incorrecto; recuperación de repasos, 10 puntos derivados y fechas históricas; cargas/consultas sin escritura; una acción explícita guarda v3 y conserva los demás campos |
| `MIG-02 R-06` | v3 con L-10 y tres repasos acertados falla al cargar, conserva el JSON original y rechaza acciones; la misma fixture sin L-10 sí carga |
| `MIG-03 G-01` | Los diez IDs recuperan borradores y órdenes incorrectos sin premio; completar cada ID suma 10 una sola vez, incluso tras repetir y reabrir |
| `MIG-04` | Error de repaso y tres aciertos conservan todos los campos salvo `reviewAnswers`, incluidos respuestas originales, actividades, 20 puntos, IDs recompensados, logros/fechas y tema; sin L-10; repetir el tercer acierto tras reabrir no escribe |
| `MIG-05 G-03` | Selección de tema disponible tras migrar v2; recreación con el mismo store; reselección y petición de tema bloqueado sin escrituras |
| `INV-01` | Snapshot literal de IDs, orden y padres: 4 módulos, 10 temas, 10 subtemas, 20 preguntas y 10 actividades disponibles |

**R-06 sigue pendiente de decisión de producto.** El rechazo de L-10 es el
comportamiento observado y caracterizado, no una política de recuperación
aprobada. Las pruebas no eliminan L-10 de los datos del usuario ni cambian la
implementación. Recrear un controlador en estas pruebas no equivale a cerrar
un proceso, reiniciar Android o actualizar una APK.

## Integración en Android y aislamiento

Enumerar los dispositivos con `flutter devices`. Para los seis objetivos que
admite, usar el script existente, que crea una copia temporal del proyecto y
sustituye allí `applicationId`, `namespace` y paquete de `MainActivity` por
`mx.edu.uaz.psps.integration`. La aplicación normal usa `mx.edu.uaz.psps`.

```powershell
.\tool\verify_sprint2_android.ps1 -DeviceId '<id-dispositivo>' -Target 'integration_test/sprint2_design_test.dart'
.\tool\verify_sprint2_android.ps1 -DeviceId '<id-dispositivo>' -Target 'integration_test/cu06_logros_offline_test.dart' -EvidenceDirectory '.\build\cu06_evidence'
```

Los valores entre `<...>` deben sustituirse por los del entorno. `-DeviceId`
es obligatorio; el objetivo predeterminado es `sprint2_design_test.dart`. El
script admite además `cu05_offline_test.dart`, `cu06_logros_offline_test.dart`,
`cu07_offline_test.dart`, `cu09_busqueda_offline_test.dart` y
`cu10_offline_test.dart`, todos dentro de `integration_test/`. Usa
`test_driver/design_driver.dart`, `flutter drive --keep-app-running` y guarda
evidencias en `build/design_evidence` por defecto. Conserva la copia temporal y
la aplicación de pruebas para inspección; no es una prueba de actualización de
la aplicación normal.

Cada objetivo usa una clave exclusiva en lugar de `psps.progress.v1`:

| Objetivo dentro de `integration_test/` | Clave |
| --- | --- |
| `offline_test.dart` | `psps.integration.sprint1` |
| `evidence_test.dart` | `psps.audit.20261010` |
| `sprint2_design_test.dart` | `psps.integration.sprint2.design` |
| `cu05_offline_test.dart` | `psps.integration.cu05.offline` |
| `cu06_logros_offline_test.dart` | `psps.integration.cu06.offline` |
| `cu07_offline_test.dart` | `psps.integration.cu07.offline` |
| `cu09_busqueda_offline_test.dart` | `psps.integration.cu09.offline` |
| `cu10_offline_test.dart` | `psps.integration.cu10.offline` |

`offline_test.dart` se puede ejecutar sobre una instalación de ensayo con
`flutter test integration_test/offline_test.dart -d <id-dispositivo>`; este
comando directo no cambia el paquete Android. `evidence_test.dart` requiere el
flujo en dos fases: `PSPS_PHASE=prepare` y después `PSPS_PHASE=verify`, pasado
con `--dart-define`, usando `test_driver/evidence_driver.dart`. Entre fases hay
que detener realmente el proceso y conservar los datos. No está admitido por
el parámetro `-Target` del script de Sprint 2.

Para acreditar funcionamiento offline, registrar modo avión, Wi-Fi y datos
apagados y ausencia de red predeterminada al inicio y al final del recorrido;
ejecutar un archivo llamado `offline` no demuestra por sí solo esa condición.

## Pendientes tras la migración

- Ejecutar las pruebas de dispositivo sobre la aplicación migrada, incluidos
  H01-01…04 y DS103-01…03, conservando SHA de fuentes/APK, versión, dispositivo,
  resultados y estado antes/después.
- Probar cierre real del proceso, reapertura y reinicio de Android para avance,
  repaso y tema visual; las pruebas locales solo recrean controladores.
- Ensayar actualización sobre una APK anterior sin desinstalar, en una
  instalación propia de ensayo con paquete/firma compatibles y datos de
  progreso conocidos. Verificar respuestas, borradores, repasos, puntos,
  logros/fechas y tema bajo la clave normal antes/después. El runner con
  paquete `.integration` no cubre esta actualización.
- Decidir y aprobar la política para estados históricos con L-10 (R-06) antes
  de cambiar el resultado esperado de `MIG-02`.
- Verificar iOS con macOS/Xcode y un destino compatible; no se considera
  validado por las pruebas locales o de Android.

Referencias de alcance: [decisiones D-03/D-05](audit/DECISIONES_ARQUITECTURA.md),
[regresiones propuestas, sección 7](audit/TRAZABILIDAD_CU01_CU10.md) y
[riesgos R-02, R-06 y R-13](audit/RIESGOS_MIGRACION.md).

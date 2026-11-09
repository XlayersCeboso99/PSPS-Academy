# Preparación del puerto HarmonyOS NEXT

Fecha de verificación: **9 de noviembre de 2026**. Base de trabajo: `319c8d458f2ad5adf43a6a7ffc27b2ebc7e6f018`.

## Estado y alcance de la evidencia

El puerto está **preparado, no compilado como HAP y no probado en un dispositivo Huawei**. Se implementó el adaptador Dart y se prepararon el overlay ArkTS, el manifiesto alternativo y el procedimiento de integración. No existe un directorio `ohos/` generado en esta entrega. No se instalaron ni descargaron DevEco Studio, Flutter-OH ni las herramientas nativas ausentes.

Las verificaciones ejecutadas usaron Windows, Flutter **3.47.9**, revisión `c197ca5199`, y Dart **3.13.7**, según `flutter --version`. Las pruebas de canal sustituyen el extremo nativo por un manejador simulado; no ejecutan las APIs de HarmonyOS. El análisis con lenguaje 3.9 descrito más adelante verifica sintaxis del paquete, usando el framework y las bibliotecas del SDK instalado.

En este informe, **verificado localmente** significa comando o inspección ejecutados en esta máquina; **verificado documentalmente** significa contraste con documentación pública enlazada; **no verificado** significa que falta resolver, compilar o ejecutar en el entorno objetivo; **incompatible** identifica una restricción concreta de versión o la ausencia de implementación OHOS en el paquete inspeccionado. Ningún estado documental equivale a una prueba en dispositivo.

## Arquitectura y contrato del puerto

La inspección del código confirma que catálogo, reglas, controladores y serialización permanecen compartidos. No se modificaron el catálogo, `lib/core/`, `ReminderController`, `NotificationPort`, `FlutterNotificationPort`, Android ni iOS. La persistencia de configuración, progreso y notas sigue usando `shared_preferences`; su ejecución OHOS dependerá de la adaptación indicada en la matriz y está pendiente de validación.

El único punto de selección es `notification_port_factory.dart`: `String.fromEnvironment('PSPS_TARGET') == 'ohos'` construye `OhosNotificationPort`; sin esa definición conserva `FlutterNotificationPort`. La selección no depende de `dart:io`. Ambos casos se comprobaron con ejecuciones de pruebas distintas, con y sin `--dart-define=PSPS_TARGET=ohos`.

`OhosNotificationPort` implementa la interfaz existente mediante `MethodChannel('mx.edu.uaz.psps/reminders')`. Este contrato quedó verificado localmente:

| Dirección | Método | Argumentos / resultado |
| --- | --- | --- |
| Dart → ArkTS | `initialize` | Sin argumentos; prepara almacenamiento y entrega aperturas pendientes |
| Dart → ArkTS | `hasPermission` | Sin argumentos; booleano |
| Dart → ArkTS | `requestPermission` | Sin argumentos; booleano |
| Dart → ArkTS | `scheduleDay` | Mapa exacto: `weekday`, `hour`, `minute`, `title`, `body`; resultado vacío |
| Dart → ArkTS | `cancelDay` | Mapa exacto: `weekday`; resultado vacío |
| Dart → ArkTS | `openNotificationSettings` | Sin argumentos; booleano |
| ArkTS → Dart | `opened` | Sin argumentos; ejecuta `onOpened` |

Los `PlatformException` se propagan conservando código, mensaje y detalles. No se ocultan errores de programación o persistencia: el controlador existente mantiene su mecanismo de recuperación. Los métodos booleanos devuelven `false` ante resultado nulo. El callback se instala antes de enviar `initialize`; las pruebas incluyen una apertura recibida durante esa inicialización.

El overlay implementa el diseño nativo mediante un `ReminderRequestAlarm` por día, con `daysOfWeek: [weekday]`. Las llamadas están serializadas y el mapa `day.<weekday> → reminderId` se conserva en ArkData preferences, archivo lógico `psps_ohos_reminders`. El reemplazo cancela el anterior antes de publicar; al retirar un día cancela y elimina su clave. El identificador de notificación también es estable por día. **La secuencia se verificó por inspección del código ArkTS; no se ejecutó en HarmonyOS.**

Las APIs públicas `publishReminder(): Promise<number>`, `cancelReminder(): Promise<void>`, los campos de alarma y los días lunes=1 a domingo=7 se comprobaron en la [referencia de recordatorios de Huawei](https://developer.huawei.com/consumer/en/doc/harmonyos-references/js-apis-reminderagentmanager/). Esa referencia también documenta el `WantAgent` específico de recordatorios, con `pkgName`, `abilityName` y `parameters` desde API 12. El overlay usa esa estructura para abrir la ability con un marcador, sin usar APIs Android.

La consulta de autorización, su solicitud después de cargar la interfaz y los ajustes desde API 13 se contrastaron con la [referencia de NotificationKit](https://developer.huawei.com/consumer/en/doc/harmonyos-references/js-apis-notificationmanager/). El overlay prevé API 13 como mínimo; devuelve `false` si falta la capacidad de ajustes, y transmite otros fallos. La denegación documentada `1600004` conduce a volver a consultar la autorización.

El permiso `ohos.permission.PUBLISH_AGENT_REMINDER` es de concesión por sistema según la [lista oficial de permisos](https://developer.huawei.com/consumer/en/doc/harmonyos-guides/permissions-for-all/). Se prepararon `reason`, `usedScene` y su recurso de cadena. Las APIs consultadas no enumeran un permiso adicional para consultar o solicitar notificaciones de la propia aplicación. La compatibilidad del esquema completo del manifiesto queda pendiente del SDK elegido.

El fragmento de `EntryAbility` conserva el registro generado y añade el plugin. Retiene el Want inicial y el de `onNewWant`; `onForeground` solo intenta entregar lo pendiente para evitar repetir el evento en cada reanudación. Las firmas exactas del embedding `@ohos/flutter_ohos`, sus exports y el registro se marcan **«verificar al generar el proyecto»**, porque no hay embedding instalado para contrastarlas o compilarlas.

## Matriz de dependencias

La fuente local de las restricciones es `%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\<paquete>-<versión>\pubspec.yaml`. Se inspeccionaron sus secciones `environment` y `flutter.plugin.platforms`; no se dedujo compatibilidad nativa a partir de que una dependencia resuelva en Windows.

| Dependencia | Restricción inspeccionada | Estado para Flutter-OH 3.35.7 / Dart 3.9 | Fuente y acción |
| --- | --- | --- | --- |
| `flutter` | Instalado: 3.47.9 / Dart 3.13.7 | **No verificado** con el objetivo 3.35.7 / 3.9.x | `flutter --version`; rama objetivo en [repositorio Flutter-OH](https://gitcode.com/CPF-Flutter/flutter_flutter/tree/oh-3.35.7-release). APIs del framework objetivo pendientes |
| `cupertino_icons 1.0.9` | Dart `^3.9.0` | Restricción **verificada** compatible; recursos OHOS **no verificados** | Pubspec local; no se requiere bajar la versión por Dart |
| `shared_preferences 2.5.6` de pub.dev | Dart `^3.11.0`, Flutter `>=3.41.0` | **Incompatible** con el SDK objetivo | Pubspec local; sustituir por la adaptación 2.5.4 OHOS |
| `shared_preferences` OHOS | Tag `shared_preferences-v2.5.4-ohos-1.0.1`, path `packages/shared_preferences/shared_preferences` | Adaptación **verificada documentalmente**; resolución, API `SharedPreferencesAsync` y ejecución **no verificadas** | [Repositorio de paquetes OHOS](https://gitcode.com/oh-flutter/flutter_packages), tabla 3.35 → 2.5.4. No se descargó el tag |
| `flutter_local_notifications 20.1.0` | Dart `^3.8.0`, Flutter `>=3.32.0`; sin plataforma `ohos` | Versiones **verificadas** compatibles; adaptador nativo de este paquete **incompatible** con OHOS | Pubspec local; el puerto OHOS evita invocarlo y usa el canal propio |
| `flutter_timezone 5.1.0` | Dart `>=3.4.0 <4.0.0`, Flutter `>=3.22.0`; sin `ohos` | Versiones **verificadas** compatibles; implementación OHOS ausente | Pubspec local; no se invoca desde el puerto OHOS |
| `timezone 0.10.1` | Dart `>=2.19.0 <3.0.0`; biblioteca Dart | Resuelve localmente; ejecución con Dart 3.9 **no verificada** | Pubspec local y [migración oficial Dart 3](https://dart.dev/resources/dart-3-migration): Pub reinterpreta ese límite superior para paquetes null-safe |
| `app_settings 7.0.0` | Dart `>=2.18.0 <4.0.0`, Flutter `>=3.3.0`; sin `ohos` | Versiones **verificadas** compatibles; implementación OHOS ausente | Pubspec local; ajustes OHOS mediante NotificationKit |
| `flutter_lints 6.0.0` | Dart `^3.8.0` | Restricción **verificada** compatible | Pubspec local; no se requiere bajar esta versión por Dart |
| `flutter_test`, `flutter_driver`, `integration_test` | Dependencias del SDK Flutter | **No verificado** con la distribución Flutter-OH | Localmente se usaron los paquetes del SDK 3.47.9; resolver de nuevo en 3.35.7 |

El override en `pubspec.ohos.yaml` conserva las dependencias declaradas y cambia la fuente efectiva de `shared_preferences` al git `https://gitcode.com/openharmony-tpc/flutter_packages.git`, con el path y tag anteriores. El acceso web directo al tag no produjo contenido utilizable; la tabla del repositorio respalda la adaptación, pero no acredita una descarga ni un build del tag exacto. La variante no se copió sobre el manifiesto normal en esta rama.

También se inspeccionaron transitivas del lockfile normal: `shared_preferences_android 2.4.28` exige Dart `^3.12.0` / Flutter `>=3.44.0`; `shared_preferences_foundation 2.5.7`, Dart `^3.10.0` / Flutter `>=3.38.0`. **Esas versiones son incompatibles con el objetivo** y deberán resolverse a versiones anteriores compatibles en el checkout OHOS, aunque no sean el backend de ese destino. `shared_preferences_platform_interface 2.4.2` declara Dart `^3.9.0` / Flutter `>=3.35.0`. No se seleccionan versiones transitivas inferiores sin resolverlas con el SDK objetivo; no se ha demostrado que el grafo completo de la variante sea resoluble.

## Requisitos y procedimiento de integración

Requisitos pendientes: DevEco Studio, SDK HarmonyOS con APIs utilizadas (mínimo previsto API 13), herramientas `hvigor`, `ohpm`, `hdc`, `ohsdkmgr`, Flutter-OH **3.35.7** de `oh-3.35.7-release`, firma de depuración y equipo Huawei compatible. La rama es el objetivo de esta preparación; no se afirma que sea la última distribución disponible. Instalar DevEco desde la [distribución oficial de Huawei](https://developer.huawei.com/consumer/en/deveco-studio/) y seguir los requisitos del repositorio Flutter-OH. Ninguna instalación se realizó aquí.

En un checkout dedicado, usar el terminal configurado para Flutter-OH y confirmar primero `flutter --version`. La secuencia prevista es:

```powershell
flutter --version
flutter doctor -v
flutter create --platforms ohos --org mx.edu.uaz . --no-pub

# Copiar el plugin, fusionar EntryAbility, permiso y recurso de cadena:
# seguir ohos_overlay/README.md; no reemplazar archivos generados con snippets.

Copy-Item pubspec.ohos.yaml pubspec.yaml -Force
flutter pub get
flutter analyze
flutter test test/ohos/ohos_notification_port_test.dart --dart-define=PSPS_TARGET=ohos
flutter build hap --debug --dart-define=PSPS_TARGET=ohos
```

La forma base de generación es `flutter create --platforms ohos --org mx.edu.uaz .`; aquí se añade `--no-pub` para posponer la resolución del manifiesto normal incompatible hasta copiar la variante. Revisar el diff producido por la generación. Configurar registro, SDK y firma en DevEco antes del build; contrastar allí todas las firmas marcadas. Los comandos son instrucciones pendientes, no un registro de ejecución.

Para arquitectura explícita, la forma prevista es `flutter build hap --debug --target-platform ohos-arm64 --dart-define=PSPS_TARGET=ohos`. Para probar, `flutter run --dart-define=PSPS_TARGET=ohos`; alternativamente, `flutter install -t <deviceId> <hap>` con el dispositivo y artefacto reales. Las formas de los comandos proceden del antecedente de Flutter-OH y requieren confirmación con `flutter help` en esa distribución. No se generó, instaló ni ejecutó un HAP durante esta preparación.

El detalle de la fusión está en [el README del overlay](../../ohos_overlay/README.md). `bundleName` y firma OHOS deben decidirse en ese entorno; el código toma la identity de la ability del contexto. Esto no exige cambiar el `applicationId` Android. La migración entre instalaciones Android y HarmonyOS NEXT no aplica al alcance actual: se trata de una instalación nueva. La persistencia local en el destino sí debe probarse.

## Verificación real de lenguaje Dart 3.9

Se copiaron los archivos versionados y los nuevos archivos Dart a una carpeta temporal **fuera del repositorio**, sin `.git`: `%TEMP%\psps-ohos-dart39-c231ac06316f414184b9bd929d422a2f`. Allí se cambió únicamente el mínimo del manifiesto normal a `sdk: ^3.9.0` y se ejecutaron `flutter pub get` y `flutter analyze`. La copia no usa `pubspec.ohos.yaml` ni el override remoto. Los manifiestos y lockfiles normales del repositorio permanecieron intactos.

`flutter pub get` terminó con código **0**. Salida literal:

```text
Resolving dependencies...
Downloading packages...
  app_settings 7.0.0 (9.0.1 available)
  cupertino_icons 1.0.9 (2.0.0 available)
  dbus 0.7.15 (0.8.0 available)
  equatable 2.1.0 (3.0.0 available)
  flutter_local_notifications 20.1.0 (23.0.0 available)
  flutter_local_notifications_linux 7.0.0 (9.0.0 available)
  flutter_local_notifications_platform_interface 10.0.0 (13.0.0 available)
  flutter_local_notifications_windows 2.0.1 (4.0.0 available)
  flutter_timezone 5.1.0 (5.1.1 available)
  material_color_utilities 0.13.0 (0.13.1 available)
  meta 1.18.3 (1.19.0 available)
  petitparser 7.0.2 (7.1.0 available)
  shared_preferences_android 2.4.28 (2.5.4 available)
  shared_preferences_foundation 2.5.7 (2.6.1 available)
  test_api 0.7.12 (0.7.15 available)
  timezone 0.10.1 (0.11.2 available)
  vector_math 2.4.2 (2.4.4 available)
  vm_service 15.3.0 (15.4.0 available)
  web 1.1.1 (1.1.2 available)
  xml 6.6.1 (7.1.0 available)
Got dependencies!
20 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
```

Se inspeccionó `.dart_tool/package_config.json`: la entrada de `psps` contenía `languageVersion: "3.9"`. El análisis inicial detectó únicamente un import redundante en el adaptador nuevo; se retiró y se sincronizó la copia. El análisis final terminó con código **0**; salida literal (se omiten solo espacios finales):

```text
Analyzing psps-ohos-dart39-c231ac06316f414184b9bd929d422a2f...
No issues found! (ran in 14.3s)
```

Como control adicional, se creó solo en la copia `lib/language_version_probe.dart`, con un enum y `final LanguageProbe languageProbe = .value;`. `flutter analyze --no-pub lib/language_version_probe.dart` terminó con código **1**, con este diagnóstico literal:

```text
  error - This requires the 'dot-shorthands' language feature to be enabled. Try updating your pubspec.yaml to set the minimum SDK constraint to 3.10.0 or higher, and running 'pub get' - lib\language_version_probe.dart:2:37 - experiment_not_enabled
```

El archivo de control se eliminó después. Esto confirma que el analizador respeta la versión de lenguaje del paquete para una característica posterior, aunque el ejecutable sea Dart 3.13.7. No se encontraron incompatibilidades de sintaxis en `lib/`; **no se necesitó modificar sintaxis de archivos existentes**. La única edición existente en `lib/` es la selección de la fábrica.

**Límite esencial:** `^3.9.0` permite ejecutar Pub con Dart 3.13.7; no obliga al resolvedor a seleccionar dependencias ejecutables en Dart 3.9. Cada dependencia mantiene además su propia versión de lenguaje. Por ello este resultado no verifica el grafo bajo un ejecutable Dart 3.9, las APIs del framework Flutter 3.35, el embedding OHOS ni la compilación HAP.

## Pruebas locales y comparación con la base

| Comprobación ejecutada | Resultado observado |
| --- | --- |
| `flutter pub get --enforce-lockfile` en la rama normal | Código 0; resolución generada sin cambiar el lockfile |
| `dart format` sobre los tres archivos Dart tocados | Sin cambios pendientes de formato |
| `flutter analyze` con manifiesto normal | Código 0; `No issues found! (ran in 7.2s)` |
| `flutter test --no-pub test/ohos/ohos_notification_port_test.dart` | Código 0; **11 aprobadas**; fábrica por defecto incluida |
| `flutter test --no-pub --dart-define=PSPS_TARGET=ohos test/ohos/ohos_notification_port_test.dart test/sprint3/cu12_reminders_test.dart` | Código 0; **25 aprobadas**; fábrica OHOS y regresión CU-12 incluidas |
| `flutter test --no-pub` en la rama | Código 1; **207 aprobadas, 13 fallidas** |
| `flutter test --no-pub --reporter json` en copia archivada de `HEAD` base, sin puerto | Código 1; **196 aprobadas, 13 fallidas**, mismos casos |

Los 13 fallos preexistentes afectan a `app_test` CU01; `cu06_achievements_test` CP06-01/03/08; `progress_test` CU01/CU03; `points_consultation_test` CP10-16; regresión INV-01, MIG-01 v1/v2/v3 y MIG-03; Sprint 2 G02; y `multi_activity_model_test` legacyView. La base ya contiene 40 preguntas y 20 prácticas, mientras varias expectativas siguen vinculadas al catálogo anterior. Esas pruebas se conservaron intactas. No se observó ningún fallo adicional por el puerto; la suite global **no está en verde en esta base**.

La comparación de base se ejecutó en `%TEMP%\psps-ohos-baseline-3fe87e7809904625a37c2a3a18fef0f9`, creada mediante `git archive HEAD`, con su manifiesto normal y `flutter pub get --offline --enforce-lockfile`. El resultado no presupone correcciones futuras.

El ciclo de prueba del controlador activa lunes/martes/viernes a las 18:30 (`{1,2,5}`), cambia a solo martes (`{2}`) y desactiva. Se comprueba una llamada `scheduleDay` por día activo en cada reconciliación, los argumentos completos y las cancelaciones de todos los días inactivos. El backend simulado conserva un mapa por día y demuestra el contrato de reemplazo sin duplicados **en Dart**, sin acreditar la persistencia o el planificador nativos.

## Riesgos, bloqueos y validación pendiente

1. **Entorno objetivo ausente:** faltan Flutter-OH y herramientas DevEco; bloquea compilar ArkTS/HAP y probar hardware. Las firmas del embedding, manifiesto y registro están pendientes.
2. **Diferencia de SDK:** bajar la versión de lenguaje no detecta APIs Flutter incorporadas después de 3.35 ni valida las transitivas con Dart 3.9. Resolver y analizar con el SDK objetivo sigue siendo obligatorio.
3. **Persistencia no transaccional:** el servicio de recordatorios y ArkData no comparten una transacción. Una terminación entre publicación y guardado, o fallo simultáneo del guardado y su compensación, puede dejar un ID huérfano. El código intenta compensar, pero no garantiza recuperación de IDs perdidos; resolver y probar antes de distribución. El uso de preferences se contrastó con la [guía de persistencia de Huawei](https://developer.huawei.com/consumer/en/doc/harmonyos-guides/data-persistence-by-preferences/).
4. **Autorización y entrega:** la UI debe estar cargada antes de solicitar permiso. Deben comprobarse denegación, retorno de ajustes, reinicios, cambio horario, políticas del sistema y entrega de `opened` con proceso detenido. No se garantiza puntualidad ni entrega sin pruebas.
5. **Regresión general heredada:** los 13 fallos de base impiden afirmar suite global aprobada; su corrección queda fuera de los archivos de este puerto.

Pruebas pendientes en un dispositivo Huawei, todas **no ejecutadas**:

- Generar y firmar HAP en Flutter-OH 3.35.7, registrar el plugin y confirmar ausencia de `MissingPluginException`.
- Comprobar arranque, catálogo offline, navegación, reglas y controladores compartidos con el framework objetivo.
- Guardar, cerrar y reabrir progreso, notas y configuración mediante `SharedPreferencesAsync` del tag OHOS, sin perder claves ajenas.
- Autorizar y denegar notificaciones; volver desde ajustes; probar capacidad ausente y fallos del servicio.
- Activar L/M/V 18:30; inspeccionar IDs reales y disparos semanales; cambiar a M y desactivar; comprobar que no quedan duplicados ni avisos retirados.
- Repetir cambios rápidos y comprobar serialización, límites del servicio y cancelación de un ID ya eliminado.
- Reiniciar aplicación y teléfono; simular fallo de guardado/publicación/cancelación y muerte del proceso entre publicar y persistir; comprobar recuperación o identificar IDs huérfanos.
- Tocar un recordatorio con la aplicación cerrada, en segundo plano y activa; verificar apertura de `EntryAbility` y una única navegación por Want, sin repetición al reanudar.
- Probar día/hora ya transcurridos, lunes/domingo, cambio de zona horaria, reloj y horario estacional donde corresponda.
- Confirmar textos, accesibilidad, identidad OHOS, firma y comportamiento sin conexión antes de distribuir.

## Archivos entregados

- `lib/features/reminders/adapters/ohos_notification_port.dart`: adaptador de canal.
- `lib/features/reminders/adapters/notification_port_factory.dart`: selección explícita de destino.
- `test/ohos/ohos_notification_port_test.dart`: contrato, errores, aperturas, fábrica y ciclo del controlador.
- `ohos_overlay/entry/src/main/ets/plugins/ReminderPlugin.ets`: plugin ArkTS preparado.
- `ohos_overlay/entry/src/main/ets/entryability/EntryAbility.snippet.ets`: registro y ciclo de apertura.
- `ohos_overlay/entry/src/main/module.json5.snippet`: permiso y escena de uso.
- `ohos_overlay/entry/src/main/resources/base/element/string.json.snippet`: motivo del permiso.
- `ohos_overlay/README.md`: aplicación del overlay.
- `pubspec.ohos.yaml`: variante independiente para el entorno objetivo.
- `docs/platforms/HARMONYOS_NEXT.md`: informe de preparación y evidencia.

No se ejecutó `flutter build apk --debug`, ya que no forma parte de esta comprobación; el adaptador Android/iOS permanece sin cambios. No se realizó publicación remota.

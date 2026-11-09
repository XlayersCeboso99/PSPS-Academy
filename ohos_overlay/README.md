# Overlay de recordatorios para HarmonyOS NEXT

Estado al 9 de noviembre de 2026: preparado, **no compilado ni probado en dispositivo**. Este directorio contiene código ArkTS y fragmentos para integrar después de generar `ohos/` con Flutter-OH. No es un proyecto OHOS autónomo. El análisis y las pruebas Dart ejecutados en Windows no compilan estos archivos.

## Aplicación en un entorno Flutter-OH dedicado

1. Instalar DevEco Studio, SDK HarmonyOS, herramientas `hvigor`, `ohpm`, `hdc`, `ohsdkmgr` y Flutter-OH de la rama `oh-3.35.7-release`. Confirmar mediante `flutter --version` que ese terminal usa Flutter-OH 3.35.7 / Dart 3.9.x. Estas herramientas no se instalaron durante la preparación.
2. En un checkout separado, generar la plataforma con `flutter create --platforms ohos --org mx.edu.uaz . --no-pub`. `--no-pub` evita resolver el manifiesto normal, que exige Dart 3.13, antes de copiar la variante. La forma base documentada es `flutter create --platforms ohos --org mx.edu.uaz .`. Revisar el diff generado para preservar Android/iOS y decidir el `bundleName` OHOS sin modificar el `applicationId` Android.
3. Copiar únicamente el plugin completo:

   ```powershell
   New-Item -ItemType Directory -Force ohos/entry/src/main/ets/plugins
   Copy-Item ohos_overlay/entry/src/main/ets/plugins/ReminderPlugin.ets ohos/entry/src/main/ets/plugins/ReminderPlugin.ets
   ```

4. Fusionar `entry/src/main/ets/entryability/EntryAbility.snippet.ets` dentro del `EntryAbility.ets` generado. Conservar la clase y los registros generados, añadir una única instancia de `ReminderPlugin(this.context)` y los hooks indicados. **Verificar al generar el proyecto** los exports de `@ohos/flutter_ohos`, `getUniqueClassName`, `FlutterPluginBinding`, `MethodCall.argument<T>`, `MethodResult`, `MethodChannel.invokeMethod`, `configureFlutterEngine` y `getPlugins().add`. Las firmas preparadas no se han contrastado con un embedding instalado.
5. Fusionar `module.json5.snippet` dentro de `module` en `ohos/entry/src/main/module.json5`. Fusionar `resources/base/element/string.json.snippet` en el recurso `string.json` generado, conservando las demás cadenas. Si se renombra `EntryAbility`, actualizar `usedScene.abilities`. No copiar los archivos `.snippet` como archivos de compilación.
6. Seleccionar un SDK y destino compatibles con las APIs usadas, como mínimo API 13 para este overlay. Los ajustes emplean `notificationManager.openNotificationSettings(context)`; si `SystemCapability.Notification.NotificationSettings` no está disponible, el método devuelve `false`. Otros errores nativos se transmiten al controlador mediante `MethodResult.error`.
7. Copiar la variante y resolver desde cero con Flutter-OH:

   ```powershell
   Copy-Item pubspec.ohos.yaml pubspec.yaml -Force
   flutter pub get
   flutter analyze
   flutter test test/ohos/ohos_notification_port_test.dart --dart-define=PSPS_TARGET=ohos
   flutter build hap --debug --dart-define=PSPS_TARGET=ohos
   ```

   El override de `shared_preferences` apunta al tag `shared_preferences-v2.5.4-ohos-1.0.1`. La resolución con ese tag no se ejecutó aquí. No reutilizar el lockfile Android/iOS como prueba de compatibilidad: contiene transitivas que exigen Dart/Flutter posteriores. Cualquier ajuste de versiones debe quedar limitado al checkout OHOS.

8. Configurar firma y dispositivo en DevEco Studio. Ejecutar `flutter run --dart-define=PSPS_TARGET=ohos`, o instalar el HAP mediante `flutter install -t <deviceId> <hap>` con los valores reales del entorno; estas operaciones siguen pendientes. Si se requiere arquitectura explícita, la forma prevista es `flutter build hap --debug --target-platform ohos-arm64 --dart-define=PSPS_TARGET=ohos`.

## Contrato y límites de integración

El canal `mx.edu.uaz.psps/reminders` acepta `initialize`, `hasPermission`, `requestPermission`, `scheduleDay`, `cancelDay` y `openNotificationSettings`. `scheduleDay` recibe `weekday`, `hour`, `minute`, `title`, `body`; `cancelDay` recibe `weekday`. Los días son lunes=1 a domingo=7. `opened` viaja de nativo a Dart sin argumentos.

El plugin serializa las llamadas, persiste `day.<weekday> → reminderId` en `psps_ohos_reminders` mediante ArkData preferences y cancela el ID anterior antes de publicar el nuevo. `1700003` se trata como cancelación idempotente. Si falla la persistencia del ID nuevo, se intenta cancelar la publicación y se propaga el error. **Este algoritmo se ha revisado como código, pero su comportamiento nativo no está probado.**

El `WantAgent` de `reminderAgentManager` incluye el marcador `psps.reminder.opened` y toma bundle/ability del contexto, sin reutilizar identificadores Android. `onCreate` y `onNewWant` entregan cada Want una vez; `onForeground` solo drena aperturas pendientes. El plugin espera `initialize` para emitir `opened`, de modo que Dart ya tenga su callback instalado. La entrega real desde una notificación requiere prueba de inicio en frío y reanudación.

No hay transacción atómica entre el servicio de recordatorios y preferences. Una terminación entre publicar y persistir, o un fallo simultáneo de persistencia y compensación, puede dejar un ID huérfano; probar y resolver este riesgo antes de publicar. La reconciliación del controlador solo conoce los IDs que conserva el plugin. Tampoco hay garantía comprobada de entrega de `opened` ante muerte del proceso.

Las firmas públicas de Huawei se comprobaron mediante documentación web, no mediante compilación: [recordatorios](https://developer.huawei.com/consumer/en/doc/harmonyos-references/js-apis-reminderagentmanager/), [notificaciones](https://developer.huawei.com/consumer/en/doc/harmonyos-references/js-apis-notificationmanager/) y [preferences](https://developer.huawei.com/consumer/en/doc/harmonyos-guides/data-persistence-by-preferences/). El informe completo, la matriz de dependencias y los resultados literales de validación están en [HARMONYOS_NEXT.md](../docs/platforms/HARMONYOS_NEXT.md).

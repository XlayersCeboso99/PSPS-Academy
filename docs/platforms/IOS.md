# iOS — Preparación de PSPS Academy (Sprint 3)

Rama: `port/ios-sprint03` (creada a partir de `feature/sprint03-catalog-expansion`).
Estado: **preparado, no compilado**. Los cambios se elaboraron en Windows, donde
no es posible ejecutar Xcode ni `flutter build ios`; la compilación, la firma y
las pruebas en simulador o iPhone quedan pendientes de realizarse en macOS.

## 1. Qué contiene la rama

| Elemento | Estado |
| --- | --- |
| Lógica educativa, catálogo (40 preguntas, 20 actividades), CU-01…CU-12 | Código Dart compartido, idéntico al de Android. |
| Persistencia local | `shared_preferences` (`shared_preferences_foundation`, iOS ≥ 13). Claves `psps.progress.v1`, `psps.notes.v1`, `psps.reminder.v1`. |
| Notificaciones locales (CU-12) | `flutter_local_notifications 20.1.0` mediante `FlutterNotificationPort` (`lib/features/reminders/adapters/`). Programación semanal con IDs fijos `1201`–`1207` (uno por día), reemplazo sin duplicados y cancelación de días retirados. |
| Zona horaria | `flutter_timezone 5.1.0` + `timezone`. |
| Abrir ajustes de notificaciones | `app_settings 7.0.0` (`AppSettingsType.notification`). |
| Permiso | Se solicita al activar el recordatorio (`requestPermissions(alert, sound)`); no al iniciar la app. |
| Apertura desde la notificación | `onDidReceiveNotificationResponse` → la app vuelve a la pantalla de inicio. Con la app cerrada, iOS la abre en la pantalla de inicio. |
| `ios/Runner/AppDelegate.swift` | Delegado de `UNUserNotificationCenter` y `setPluginRegistrantCallback`, según el ejemplo UIScene del plugin. **Único cambio nativo iOS de esta rama.** |
| `Info.plist` | Sin cambios: las notificaciones locales programadas no requieren claves adicionales. |
| Destino mínimo | `IPHONEOS_DEPLOYMENT_TARGET = 15.0` (las dependencias exigen como máximo iOS 13). |
| Identificador | `mx.edu.uaz.psps` (sin cambios). |

Dependencias nativas comprobadas en sus podspec / `Package.swift`:
`flutter_local_notifications` iOS 11.0, `flutter_timezone` iOS 11.0,
`app_settings` iOS 11.0 (podspec) / 12.0 (SwiftPM), `shared_preferences_foundation`
iOS 13.0. Todas publican podspec y `Package.swift`, de modo que el proyecto puede
resolverse con CocoaPods o con Swift Package Manager.

## 2. Requisitos en la Mac

- macOS con Xcode estable reciente y sus *Command Line Tools* (`xcode-select -p`).
- Flutter **3.47.9** (canal stable), el mismo que usa el CI (`flutter --version`).
- CocoaPods (`pod --version`) — solo si Flutter decide usar CocoaPods; con Swift
  Package Manager habilitado no es necesario.
- Una cuenta de Apple Developer (o Apple ID personal) para firmar.

## 3. Pasos exactos

```bash
git clone https://github.com/XlayersCeboso99/PSPS-Academy.git
cd PSPS-Academy
git checkout port/ios-sprint03

flutter --version            # debe indicar 3.47.9
flutter doctor -v            # sección Xcode sin errores
flutter pub get --enforce-lockfile

# Verificación de que el código compartido sigue sano en esta máquina
flutter analyze
flutter test

# Compilación sin firma (comprueba proyecto, plugins y Swift)
flutter build ios --debug --no-codesign
```

Si `flutter build ios` indica que debe ejecutarse `pod install`, hacerlo así:

```bash
cd ios && pod install --repo-update && cd ..
flutter build ios --debug --no-codesign
```

Para abrir en Xcode: `open ios/Runner.xcworkspace` (no `Runner.xcodeproj`).

## 4. Firma (pendiente)

El proyecto no tiene `DEVELOPMENT_TEAM` configurado. En Xcode:

1. Seleccionar el destino **Runner** → *Signing & Capabilities*.
2. Activar *Automatically manage signing* y elegir el *Team*.
3. Conservar el *Bundle Identifier* `mx.edu.uaz.psps`. Si ese identificador ya
   está registrado por otra cuenta, usar uno temporal solo para pruebas locales
   y **no** confirmarlo en Git (cambiar el identificador afecta la continuidad
   de los datos instalados).
4. Repetir para **RunnerTests** si se ejecutarán sus pruebas.
5. No se requiere la capacidad *Push Notifications*: CU-12 usa solo
   notificaciones locales.

No confirmar en Git el `DEVELOPMENT_TEAM` personal salvo acuerdo del equipo.

## 5. Pruebas en simulador (siguiente actividad)

```bash
open -a Simulator
flutter devices
flutter test integration_test/offline_test.dart -d <id-del-simulador>
flutter run -d <id-del-simulador>
```

Lista de comprobación manual de CU-11/CU-12 en iOS:

- [ ] Crear, editar y eliminar una nota; cerrar y reabrir la app: la nota persiste.
- [ ] Activar el recordatorio: aparece la solicitud de permiso del sistema.
- [ ] Denegar el permiso: la app muestra el aviso y el botón «Abrir ajustes del teléfono» abre los ajustes de notificaciones de PSPS.
- [ ] Conceder el permiso y programar un día/hora próximos: la notificación aparece (también con la app en primer plano).
- [ ] Tocar la notificación: la app se abre en la pantalla de inicio.
- [ ] Cambiar días y hora: no quedan avisos duplicados ni días retirados.
- [ ] Desactivar el recordatorio: no vuelve a aparecer.
- [ ] Progreso, puntos y logros no cambian por usar notas o recordatorios.

Las pruebas en iPhone físico quedan para una actividad posterior.

## 6. Limitaciones conocidas

- No se ha ejecutado ninguna compilación de iOS. Cualquier error de Swift,
  de resolución de paquetes o de firma se descubrirá en la Mac.
- iOS limita a 64 las notificaciones locales pendientes por app; CU-12 usa como
  máximo 7.
- `app_settings` 8.x y posteriores eliminan el soporte de CocoaPods; por eso se
  fijó la 7.0.0.

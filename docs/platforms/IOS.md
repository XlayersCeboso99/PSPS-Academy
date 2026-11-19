# iOS — Preparación de PSPS Academy (Sprint 3)

Rama: `port/ios-sprint03` (creada a partir de `feature/sprint03-catalog-expansion`).
Estado: **listo para compilar en Mac.** La compilación iOS para simulador (sin firma) y una prueba de integración en simulador pasaron en el CI de macOS (Xcode 26.6, iOS 26.4) el 11/11/2026. Quedan pendientes la firma, el iPhone físico y las pruebas manuales de CU-11/CU-12 (sección 6).

## 1. Paridad con Android (auditoría del 10/11/2026)

Comparación de `origin/port/ios-sprint03` (`5129cd0`) con `origin/feature/sprint03-catalog-expansion` (`904d26b`).

| Ruta | SHA del árbol en Android | SHA del árbol en iOS |
| --- | --- | --- |
| `lib/` | `79030e367a` | `79030e367a` |
| `test/` | `358367b4e6` | `358367b4e6` |
| `integration_test/` | `3c89eda04f` | `3c89eda04f` |
| `test_driver/` | `b48043e598` | `b48043e598` |
| `pubspec.yaml` / `pubspec.lock` | `c365aba9b0` / `a355857ed5` | idénticos |
| `tool/verifications/` | `c614965729` | `c614965729` |

El código Dart, las pruebas y las dependencias son idénticos byte a byte. Fuera de `ios/`, las ramas solo difieren en los scripts Android de `fix/android-setup` y en este documento.

Inventario contado con una sonda independiente que recorre el catálogo real y calcula el SHA-256 de su contenido canónico (ids, textos, opciones, respuesta correcta, explicación, instrucciones y pasos):

| Rama | Módulos | Temas | Subtemas | Preguntas | Actividades | Ids únicos | SHA-256 del contenido |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Android (catálogo ampliado) | 4 | 10 | 10 | 40 | 20 | 84/84 | `e9a644db…0e5904` |
| iOS | 4 | 10 | 10 | 40 | 20 | 84/84 | `e9a644db…0e5904` |
| `main` (referencia anterior) | 4 | 10 | 10 | 20 | 10 | 54/54 | `ee3ff9a7…f8b2daff` |

Los 54 identificadores de `main` siguen presentes en el catálogo ampliado. CU-01 a CU-12 comparten la misma implementación en ambas plataformas; la única diferencia funcional de iOS es `AppDelegate.swift` (CU-12).

## 2. Revisión técnica de `ios/`

Se generó un proyecto nuevo con `flutter create --platforms=ios --org mx.edu.uaz --project-name psps` (Flutter 3.47.9) y se comparó archivo por archivo con `ios/`:

| Archivo | Resultado |
| --- | --- |
| `Runner.xcodeproj/project.pbxproj`, `Runner.xcscheme`, `Runner.xcworkspace`, `SceneDelegate.swift`, `Debug/Release.xcconfig`, `AppFrameworkInfo.plist`, `LaunchScreen`/`Main.storyboard`, iconos, `RunnerTests` | Idénticos a la plantilla de 3.47.9. |
| `Runner/AppDelegate.swift` | Plantilla + delegado de `UNUserNotificationCenter` y `setPluginRegistrantCallback` (CU-12), según la guía UIScene de `flutter_local_notifications`. |
| `Runner/Info.plist` | Plantilla; solo cambia `CFBundleDisplayName` = `PSPS` (Android muestra «PSPS Academy»). Las notificaciones locales no requieren claves ni `UIBackgroundModes`. |
| `ios/.gitignore` | **Faltaba** (corregido en `fix/ios-preflight`): sin él, `xcuserdata`, `DerivedData`, `Flutter/Flutter.podspec` y `App.framework` aparecían como cambios al abrir Xcode. |

Configuración: iOS 15.0, Swift 5, `mx.edu.uaz.psps`, ciclo de vida UIScene (`FlutterSceneDelegate` + `FlutterImplicitEngineDelegate`), plugins registrados en `didInitializeImplicitFlutterEngine`.

**Gestor de dependencias: Swift Package Manager.** En Flutter 3.47.9 estable, `enable-swift-package-manager` está activado por defecto (`packages/flutter_tools/lib/src/features.dart`). El proyecto ya referencia `FlutterGeneratedPluginSwiftPackage`, y los cinco plugins nativos publican `Package.swift`, así que **no hace falta `Podfile` ni CocoaPods**:

| Plugin | Versión | iOS mínimo (SwiftPM) |
| --- | --- | --- |
| `flutter_local_notifications` | 20.1.0 | 11.0 |
| `flutter_timezone` | 5.1.0 | 11.0 |
| `app_settings` | 7.0.0 | 12.0 |
| `shared_preferences_foundation` | 2.5.7 | 13.0 |
| `integration_test` (solo pruebas) | SDK | — |

CU-12 en iOS: el permiso se pide solo al activar el recordatorio (`requestPermissions(alert, sound)`); la programación es semanal (`DateTimeComponents.dayOfWeekAndTime`, ids `1201`–`1207`, máximo 7 de los 64 avisos pendientes que permite iOS); con la app abierta el aviso se muestra porque `AppDelegate` es el delegado del centro de notificaciones; al tocarlo, `onDidReceiveNotificationResponse` vuelve a Inicio, y con la app cerrada iOS la abre en Inicio, como pide la especificación. «Abrir ajustes» usa `AppSettingsType.notification`.

## 3. Verificación automática

Windows 11, Flutter 3.47.9 / Dart 3.13.7, rama `port/ios-sprint03` (`5129cd0`):

| Comando | Resultado |
| --- | --- |
| `flutter pub get --enforce-lockfile` | correcto |
| `flutter analyze` | sin problemas |
| `flutter test` | 216 pruebas aprobadas |
| `flutter test test/sprint3` | 68 aprobadas |
| Inventario (`catalog_expansion_test`, `catalog_integrity_test`, `multi_activity_model_test`) | 23 aprobadas |
| Regresión (`test/regression`, `tool/verifications/…sprint01…`) | 13 aprobadas |

CI de macOS (`.github/workflows/ios-build.yml`): se ejecuta en cada *push* a `port/ios-sprint03` o `fix/ios-**`, y en cada PR hacia `port/ios-sprint03`. Ejecuta `pub get` bloqueado, `analyze` y `test`, `flutter build ios --simulator --debug` sin firma (resuelve los plugins con SwiftPM) e `integration_test/offline_test.dart` en un simulador iPhone arrancado. Publica todos los registros y `Runner.app` como artefactos (`ios-build-logs`, `ios-simulator-logs`).

### Resultados reales del CI de macOS

Entorno del runner: macOS 26.7.2, **Xcode 26.6** (17F113), Flutter 3.47.9 / Dart 3.13.7, simulador **iPhone 17 Pro con iOS 26.4**.

| Ejecución | Commit | `build-simulator` | `simulator-integration` |
| --- | --- | --- | --- |
| [42941222430](https://github.com/XlayersCeboso99/PSPS-Academy/actions/runs/42941222430) | `5af9f42` | **Aprobado** | **Cancelado** por límite de 45 min (ver abajo) |
| [42947500910](https://github.com/XlayersCeboso99/PSPS-Academy/actions/runs/42947500910) | `c6ca070` | **Aprobado** | **Aprobado** |

Lo que demuestra `build-simulator` (ambas ejecuciones):

- `flutter pub get --enforce-lockfile`, `flutter analyze` (sin problemas) y `flutter test` (216 aprobadas) también en macOS.
- `flutter build ios --simulator --debug`: `✓ Built build/ios/iphonesimulator/Runner.app` (Xcode 89,5 s), sin errores ni advertencias de Swift; `AppDelegate.swift` compila en arm64.
- Gestor de dependencias: `Podfile present: no`. Paquetes resueltos por SwiftPM: `app_settings-7.0.0`, `flutter_local_notifications-20.1.0`, `flutter_timezone-5.1.0`, `shared_preferences_foundation-2.5.7`, `integration_test` y `FlutterFramework`. `GeneratedPluginRegistrant.m` registra los cinco plugins.

Lo que demuestra `simulator-integration` (ejecución 42947500910):

- *Smoke test* de arranque: el `Runner.app` compilado se instaló, se lanzó (PID 13417) y siguió vivo 60 s sin informes de fallo. La captura muestra la pantalla de inicio con «0 de 40 preguntas recorridas» y «4 módulos · 10 temas». En el registro del sistema no hay excepciones de Dart ni `MissingPluginException`.
- `flutter test integration_test/offline_test.dart`: `RF08: real device storage survives controller recreation`, **`+1: All tests passed!`** en 11 s. La prueba usa `SharedPreferences` nativo y abre `PspsApp`, que inicializa `flutter_timezone` y `flutter_local_notifications` en iOS.

Ejecución 42941222430: el simulador arrancó (2 min 41 s de migración de datos inicial) y la app de prueba compiló (`Xcode build done. 163.9s`), pero `flutter test` no imprimió nada más durante 37 min, hasta que el job se canceló. La ejecución siguiente, con **el mismo código de la app** (solo cambió el workflow), pasó en 11 s. El bloqueo no se debe al código; la causa probable es el primer lanzamiento en un simulador recién creado, aunque no está demostrada. El workflow ahora lanza la app una vez antes de la prueba, limita el paso a 20 min y siempre guarda una captura, el registro del simulador y los informes de fallo.

Evidencias: artefactos `ios-build-logs` (registros, `dependency-manager.log`, `Runner-simulator.app.zip`) e `ios-simulator-logs` (`integration-offline.log`, `launch-console.log`, `launch-60s.png`, `final-screen.png`, `simulator-runner.log`), con una retención de 14 días en GitHub Actions.

## 4. Requisitos en la Mac

- macOS con Xcode estable reciente y sus *Command Line Tools* (`xcode-select -p`); abrir Xcode una vez para aceptar la licencia e instalar un *runtime* de iOS Simulator.
- Flutter **3.47.9** estable (`flutter --version`).
- **No** se necesita CocoaPods. Si `flutter config --list` muestra `enable-swift-package-manager: false`, reactívalo con `flutter config --enable-swift-package-manager`; desactivarlo haría que Flutter genere un `Podfile` y pida CocoaPods.
- Para iPhone físico: un Apple ID (cuenta gratuita sirve para pruebas locales) y un cable.

## 5. Pasos en la Mac

```bash
git clone https://github.com/XlayersCeboso99/PSPS-Academy.git
cd PSPS-Academy
git checkout port/ios-sprint03

flutter --version                      # 3.47.9
flutter doctor -v                      # sección Xcode sin errores
flutter pub get --enforce-lockfile
flutter analyze
flutter test

# 1. Compilación sin firma para simulador (igual que el CI)
flutter build ios --simulator --debug

# 2. Simulador: primero ejecutar la app (también calienta el simulador recién creado)
open -a Simulator                      # o: xcrun simctl boot "iPhone 17 Pro"
flutter devices                        # copia el id del simulador
flutter run -d <id-del-simulador>      # q para salir
flutter test integration_test/offline_test.dart -d <id-del-simulador>

# 3. Compilación para dispositivo sin firma (comprueba el SDK iphoneos)
flutter build ios --debug --no-codesign
```

Si `flutter test` se queda sin salida después de `Xcode build done` durante más de 5 minutos (lo que ocurrió una vez en el CI con un simulador recién creado), interrúmpelo con Ctrl+C, abre la app una vez con `flutter run` y repite la prueba.

Para abrir en Xcode: `open ios/Runner.xcworkspace`. Tras la primera compilación, `git status` no debe mostrar archivos nuevos en `ios/`. Si aparece un `ios/Podfile`, SwiftPM está desactivado: no lo confirmes en Git.

### Firma (solo para iPhone físico)

1. En Xcode, destino **Runner** → *Signing & Capabilities* → *Automatically manage signing* y elegir el *Team*.
2. Conservar `mx.edu.uaz.psps`. Si otra cuenta ya lo registró, usa un identificador temporal solo en local y **no** lo confirmes en Git: cambiarlo rompe la continuidad de los datos instalados.
3. No se necesita la capacidad *Push Notifications*: CU-12 solo usa notificaciones locales.
4. No confirmes en Git el `DEVELOPMENT_TEAM` personal.
5. En el iPhone: *Ajustes → Privacidad y seguridad → Modo de desarrollador* y confiar en el certificado de desarrollador la primera vez.

## 6. Pendientes que requieren Xcode, simulador o iPhone

- [ ] Compilación para dispositivo (`iphoneos`) y firma con un *Team* real.
- [ ] Crear, editar y eliminar una nota; cerrar y reabrir la app: la nota persiste. Probar el límite de 1 000 caracteres.
- [ ] Activar el recordatorio: aparece la solicitud de permiso del sistema.
- [ ] Denegar el permiso: aparece el aviso y «Abrir ajustes del teléfono» abre los ajustes de notificaciones de PSPS.
- [ ] Conceder el permiso y programar un día/hora próximos: la notificación aparece, también con la app en primer plano.
- [ ] Tocar la notificación con la app en segundo plano y con la app cerrada: se abre en Inicio.
- [ ] Cambiar días y hora: sin duplicados ni días retirados. Desactivar: no vuelve a aparecer.
- [ ] Progreso, puntos, logros y temas visuales no cambian por usar notas o recordatorios.
- [ ] Recorrido visual de CU-01 a CU-10 en iPhone y iPad (orientaciones vertical y horizontal).

Las notificaciones programadas no se pueden probar de forma fiable en el CI: requieren aceptar el permiso del sistema y esperar la hora.

## 7. Limitaciones conocidas

- `app_settings` 8.x elimina el soporte de CocoaPods; se fijó la 7.0.0, que soporta ambos gestores.
- `app_settings` y `flutter_timezone` aplican el plugin de Kotlin en Android (aviso de Flutter sobre *Built-in Kotlin*); no afecta a iOS.
- No hay pruebas de integración específicas de CU-11/CU-12 en dispositivo: se cubren con pruebas de widgets y con la lista manual de la sección 6.

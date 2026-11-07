# Reproducir la verificación del Sprint 1

Pasos para repetir las comprobaciones registradas en WP.14 (casos de prueba ejecutados) y WP.15 (reporte de pruebas). Los resultados de la ejecución del 10 de octubre de 2026 están en `evidencias/`.

## Requisitos

- Flutter 3.47.2 (canal stable) con Dart 3.13.2.
- Android SDK con licencias aceptadas y un teléfono Android con depuración USB activa.
- Git para obtener el código.

Todos los comandos se ejecutan desde la carpeta de la app:

```powershell
cd "Sprint 1/psps_academy"
flutter pub get
```

> Si la ruta contiene acentos, `flutter analyze` puede fallar con `FormatException` (incidencia I-01 de WP.15). Usa una ruta sin acentos.

## 1. Análisis estático y compilación

```powershell
flutter analyze
flutter build apk --debug
```

Esperado: `No issues found!` y `Built build\app\outputs\flutter-apk\app-debug.apk` (ver `analyze_final.log` y `build.log`). En Windows, si Gradle falla por certificados, usa `.\tool\build_android.ps1`.

## 2. Pruebas unitarias y de interfaz

```powershell
flutter test
```

Esperado: 12 pruebas aprobadas (7 de lógica y 5 de interfaz). Ver `flutter_test_final.log`.

## 3. Prueba de integración con almacenamiento nativo

```powershell
flutter devices
flutter test integration_test/offline_test.dart -d <ID_ANDROID>
```

Esperado: 1 prueba aprobada (RF-08). Usa la clave de prueba `psps.integration.sprint1` y la elimina al terminar; no modifica el avance del estudiante. Ver `integration.log`.

## 4. Recorrido sin conexión con cierre del proceso (TI-06)

La prueba tiene dos fases sobre la clave exclusiva `psps.audit.20261010`, que no toca el avance normal del estudiante.

1. Anota el estado de modo avión, Wi-Fi y datos. Activa modo avión y apaga Wi-Fi y datos móviles. El teléfono sigue conectado por USB.
2. Fase **prepare**: recorre el contenido, completa un subtema y una actividad, y guarda capturas.

   ```powershell
   $env:PSPS_EVIDENCE_DIR = "..\Pruebas\evidencias"
   flutter drive --driver=test_driver/evidence_driver.dart --target=integration_test/evidence_test.dart -d <ID_ANDROID> --dart-define=PSPS_PHASE=prepare --keep-app-running
   ```

3. Detén el proceso y comprueba que ya no existe (el segundo comando no debe devolver nada):

   ```powershell
   adb -s <ID_ANDROID> shell am force-stop mx.edu.uaz.psps
   adb -s <ID_ANDROID> shell pidof mx.edu.uaz.psps
   ```

4. Fase **verify**: vuelve a abrir la app sin desinstalarla y comprueba que se recuperan 2/20 respuestas, 1 actividad y 10 puntos.

   ```powershell
   flutter drive --driver=test_driver/evidence_driver.dart --target=integration_test/evidence_test.dart -d <ID_ANDROID> --dart-define=PSPS_PHASE=verify --keep-app-running
   ```

5. Restaura modo avión, Wi-Fi y datos a como estaban. Reinstala la app normal si es necesario.

Sin `--keep-app-running`, `flutter drive` desinstala la app al terminar y la fase verify recupera 0 respuestas (incidencia I-03 de WP.15).

Ver `offline_prepare_final.log`, `offline_verify_final.log`, `dispositivo.json` y las capturas E01 a E08.

## 5. Inspecciones

Las inspecciones de código y configuración (INS-01 a INS-04) y los hallazgos H-01 a H-06 están en `evidencias/inspecciones.md`.

## Alcance

Estas pruebas no sustituyen la validación de la cliente. iOS, logros y desbloqueos, rendimiento (TI-07) y validación de catálogo (TU-06) siguen pendientes, según WP.15.

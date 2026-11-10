# Configuración del entorno de desarrollo

Instrucciones reproducibles para preparar una máquina nueva. Verificadas en Windows 11 el 06/11/2026 con Flutter 3.47.9 (Dart 3.13.7), Android SDK 36 / plataforma android-37 y el JDK de Android Studio.

## 1. Instalar Flutter

1. Descarga el SDK estable desde <https://docs.flutter.dev/get-started/install> para tu sistema y descomprímelo en una ruta sin espacios (por ejemplo `C:\src\flutter` o `~/development/flutter`).
2. Agrega `flutter/bin` al `PATH`.
3. Comprueba:

   ```bash
   flutter --version   # Dart debe ser >= 3.13.2 (restricción de pubspec.yaml)
   flutter doctor -v
   ```

`flutter doctor` debe mostrar en verde **Flutter** y **Android toolchain**. Los avisos de Visual Studio (Windows de escritorio) no afectan a este proyecto.

## 2. Android

1. Instala Android Studio (incluye JDK compatible) o el Android SDK de línea de comandos.
2. Instala desde el SDK Manager: *Android SDK Platform* reciente, *Build-Tools*, *Platform-Tools* y *Command-line Tools*.
3. Acepta licencias: `flutter doctor --android-licenses`.
4. Dispositivo físico: activa *Opciones de desarrollador* → *Depuración USB*, conéctalo y acepta la huella del equipo. Emulador: créalo en *Device Manager*.
5. `flutter devices` debe listarlo.

El proyecto usa Gradle 9.3.1 (descargado por el *wrapper*), AGP 9.1.0, Kotlin 2.4.0 y Java 17. `android/gradlew`, `gradlew.bat`, `gradle-wrapper.jar` y `local.properties` **no se versionan**: Flutter los regenera en la primera compilación (comprobado en la migración).

### Diagnóstico automático (Windows)

Requisitos que el repositorio no puede instalar por ti: **Flutter**, **Android SDK** (con Platform-Tools), **JDK 17+** (el de Android Studio sirve) y un **dispositivo con depuración USB o un emulador**. No hace falta tener `adb` en el `PATH`.

```powershell
powershell -ExecutionPolicy Bypass -File tool\doctor_android.ps1          # solo diagnostica, no cambia nada
powershell -ExecutionPolicy Bypass -File tool\doctor_android.ps1 -Repair  # repara ADB, pidiendo confirmación
powershell -ExecutionPolicy Bypass -File tool\run_android.ps1             # diagnostica, elige el dispositivo y ejecuta
powershell -ExecutionPolicy Bypass -File tool\run_android.ps1 -DeviceId <id>
```

(Si tu política de ejecución ya permite scripts locales, basta `.\tool\run_android.ps1`.)

El diagnóstico usa el SDK y el JDK que Flutter tiene configurados (`flutter config --machine`), consulta el servidor ADB con su protocolo nativo **sin reiniciarlo** y revisa versiones de ADB duplicadas, servicios que lanzan su propio ADB y el estado de cada dispositivo (`device`, `unauthorized`, `offline`). `-Repair` solo detiene un servicio o reinicia el servidor ADB tras confirmación; nunca borra archivos del SDK, desinstala aplicaciones, cambia variables globales ni el tipo de inicio de un servicio. `run_android.ps1` fija `ANDROID_HOME` solo para su propio proceso.

### `adb server version (40) doesn't match this client (41)` / `Android null (unsupported)`

Significa que **otro programa** ejecuta un ADB antiguo en el puerto 5037. Cada vez que Flutter (ADB 1.0.41) lo reemplaza, el otro programa lo vuelve a lanzar: aparecen `connection reset`, dos `adb.exe` y los dispositivos como `Android null`, o `flutter run` termina con `Lost connection to device`. No es un problema del proyecto, y matar los procesos solo lo arregla unos segundos.

Causa encontrada el 09/11/2026: el servicio de Windows **SuperDisplay** (`MirrorService.exe`, inicio automático, cuenta LocalSystem) incluye `C:\Program Files\SuperDisplay\adb\adb.exe` 1.0.40 (2019). `doctor_android.ps1` detecta este caso y, en general, cualquier servicio con un `adb.exe` junto a su ejecutable. Soluciones, de menor a mayor impacto:

1. Mientras desarrollas, detén el servicio desde PowerShell **como administrador**: `Stop-Service SuperDisplay` (al terminar: `Start-Service SuperDisplay`). `doctor_android.ps1 -Repair` lo hace por ti si la consola es de administrador.
2. Si no usas SuperDisplay a diario, cambia su inicio a *Manual* en `services.msc`.
3. Opcional, bajo tu responsabilidad: haz una copia de `C:\Program Files\SuperDisplay\adb\` y sustituye `adb.exe`, `AdbWinApi.dll` y `AdbWinUsbApi.dll` por los de `platform-tools` del SDK, para que ambos usen la misma versión.

Otros programas que suelen traer su propio ADB: herramientas de *mirroring* (Vysor, scrcpy antiguos), gestores de teléfonos y el SDK de Visual Studio/Xamarin (`C:\Program Files (x86)\Android\android-sdk`). Además, si varias herramientas o agentes ejecutan `adb` o `flutter devices` a la vez con versiones distintas, se producen los mismos reinicios.

## 3. Obtener el proyecto

```bash
git clone https://github.com/XlayersCeboso99/PSPS-Academy.git
cd PSPS-Academy
flutter pub get
```

`pubspec.lock` está versionado: `flutter pub get` debe resolver exactamente esas versiones. No ejecutes `flutter pub upgrade` salvo en una rama dedicada.

## 4. Ejecutar

```bash
flutter run -d <identificador>
```

En Windows, `tool\run_android.ps1` hace el diagnóstico, elige el dispositivo y ejecuta `flutter pub get --enforce-lockfile` y `flutter run` (ver la sección 2).

Con VS Code o Android Studio abre la carpeta raíz del repositorio, elige el dispositivo y ejecuta `lib/main.dart`.

## 5. Compilar un APK de depuración

```bash
flutter build apk --debug
```

Resultado: `build/app/outputs/flutter-apk/app-debug.apk` (no se versiona).

### Error PKIX / `certificate_unknown` en Windows

Si Gradle no puede descargar dependencias por certificados (redes con inspección TLS), usa:

```powershell
.\tool\build_android.ps1
```

El script usa temporalmente el almacén de certificados de Windows; no desactiva la validación ni modifica Java de forma permanente. Para instalar en un dispositivo: `.\tool\instalar_android.ps1` (o `tool\instalar_android.bat`).

## 6. iOS (no verificado)

Requiere macOS con Xcode, CocoaPods y una cuenta de firma. El proyecto `ios/` existe pero nunca se ha compilado ni probado en este equipo; `flutter build ios` queda pendiente para el Sprint 3.

## 7. Datos locales

La app guarda todo en `SharedPreferences`: el avance bajo `psps.progress.v1` (JSON versionado 1–3), las notas bajo `psps.notes.v1` y el recordatorio bajo `psps.reminder.v1`. Para empezar de cero en un dispositivo, borra los datos de la app desde los ajustes de Android. **No** cambies el `applicationId` (`mx.edu.uaz.psps`): una instalación con otro identificador no ve los datos previos.

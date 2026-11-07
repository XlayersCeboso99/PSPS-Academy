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

La app guarda todo en `SharedPreferences` bajo la clave `psps.progress.v1` (JSON versionado 1–3). Para empezar de cero en un dispositivo, borra los datos de la app desde los ajustes de Android. **No** cambies el `applicationId` (`mx.edu.uaz.psps`): una instalación con otro identificador no ve los datos previos.

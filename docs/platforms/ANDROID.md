# Android — CU-11, CU-12 y catálogo del Sprint 3

Identificador: `mx.edu.uaz.psps` (sin cambios). SDK de compilación, mínimo y
objetivo: los que define Flutter 3.47.9 (`flutter.compileSdkVersion`,
`flutter.minSdkVersion`, `flutter.targetSdkVersion`).

## 1. Configuración nativa añadida

| Archivo | Cambio | Motivo |
| --- | --- | --- |
| `android/app/src/main/AndroidManifest.xml` | `POST_NOTIFICATIONS` | Android 13+ exige permiso en tiempo de ejecución para mostrar notificaciones. La app lo solicita solo al activar el recordatorio. |
| | `RECEIVE_BOOT_COMPLETED` | Restaurar los avisos programados tras reiniciar el teléfono. |
| | `ScheduledNotificationReceiver` (no exportado) | Recibe la alarma y publica la notificación. |
| | `ScheduledNotificationBootReceiver` (no exportado) con `BOOT_COMPLETED`, `MY_PACKAGE_REPLACED`, `QUICKBOOT_POWERON` | Reprograma tras reinicio o actualización de la app. |
| `android/app/build.gradle.kts` | `isCoreLibraryDesugaringEnabled = true` y `desugar_jdk_libs 2.1.4` | Requisito de `flutter_local_notifications` para APIs de fecha en versiones antiguas de Android. |

No se usa `SCHEDULE_EXACT_ALARM` ni `USE_EXACT_ALARM`: el aviso se programa con
`AndroidScheduleMode.inexactAllowWhileIdle`, por lo que Android puede retrasarlo
unos minutos para ahorrar batería. La pantalla de CU-12 lo indica al usuario.

Canal de notificación: `psps_recordatorio` («Recordatorio de estudio»),
importancia predeterminada. IDs de notificación `1201` (lunes) a `1207`
(domingo); reprogramar un día reemplaza su aviso.

## 2. Compilar e instalar

```powershell
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter test tool/verifications/defects_sprint01_verification_test.dart
flutter build apk --debug
```

Resultado: `build/app/outputs/flutter-apk/app-debug.apk`.

Para **actualizar** una instalación existente conservando los datos del
estudiante, instalar con reemplazo y sin desinstalar:

```powershell
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

`flutter install` y `flutter run` pueden desinstalar la versión previa si la
firma no coincide; no usarlos sobre un teléfono con datos reales que deban
conservarse. Las pruebas de `integration_test/` escriben en el almacenamiento de
la app: ejecutarlas solo en un dispositivo o perfil de pruebas.

## 3. Resultados registrados

| Verificación | Resultado | Fecha |
| --- | --- | --- |
| `flutter analyze` | Sin incidencias | 09/11/2026 |
| `flutter test` (rama de integración CU-11/CU-12) | 196 aprobadas | 09/11/2026 |
| `flutter test` (con catálogo ampliado) | 216 aprobadas | 09/11/2026 |
| Verificaciones del Sprint 1 | 5 aprobadas | 09/11/2026 |
| `flutter build apk --debug` | Compila (tras fijar `app_settings 7.0.0`) | 09/11/2026 |
| Pruebas en dispositivo | **No ejecutadas** (ver §4) | — |

## 4. Pruebas que requieren teléfono (pendientes)

No se ejecutaron: el dispositivo de pruebas dejó de estar disponible para
`adb` durante la sesión. Ninguna de estas comprobaciones debe darse por
aprobada hasta registrarla con evidencia.

**Actualización y datos**

- [ ] Instalar con `adb install -r` sobre una instalación del Sprint 2 con avance, puntos, logros y tema: todo se conserva.
- [ ] Con el catálogo ampliado, los logros obtenidos antes (incluido L-05) se conservan con su fecha y los puntos no cambian hasta completar actividades nuevas.
- [ ] Reiniciar el teléfono: avance, notas y recordatorio persisten.

**CU-11**

- [ ] Agregar, editar y eliminar una nota sin conexión; reabrir la app y comprobar la lista «Mis notas».
- [ ] Salir con cambios sin guardar muestra la confirmación.

**CU-12**

- [ ] Android 13+: al activar, aparece la solicitud de permiso del sistema; al negarla, se muestra el aviso y «Abrir ajustes del teléfono» abre los ajustes de notificaciones de PSPS.
- [ ] Programar para dentro de 2–3 minutos: la notificación aparece (puede retrasarse por ahorro de batería).
- [ ] Tocar la notificación abre la app en Inicio, tanto con la app abierta como cerrada.
- [ ] Cambiar días y hora: no quedan avisos duplicados ni días retirados (`adb shell dumpsys alarm | findstr psps` como apoyo).
- [ ] Reiniciar el teléfono: el aviso sigue programado.
- [ ] Desactivar: no vuelve a aparecer.
- [ ] Usar notas y recordatorios no altera progreso, puntos ni logros.

**Integración automatizada** (en dispositivo de pruebas):

```powershell
flutter test integration_test/offline_test.dart -d <id>
```

y el resto de objetivos según [../TESTING.md](../TESTING.md).

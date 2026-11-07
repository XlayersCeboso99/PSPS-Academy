# Riesgos de la migración

Responsable: coordinador (Claude Code), con hallazgos de `TRAZABILIDAD_CU01_CU10.md` (Codex) e `INVENTARIO_ORIGINAL.md` (OpenCode). Fecha: 06/11/2026.
Estado: **Mitigado** (acción aplicada y verificada), **Aceptado** (se documenta, sin acción en esta migración), **Abierto** (requiere decisión o prueba futura).

| ID | Riesgo | Evidencia | Mitigación | Estado |
| --- | --- | --- | --- | --- |
| R-01 | Migrar desde `main` y perder CU-05…CU-10. | `main` (53355a9) está 33 commits detrás de `develop`. | Origen `develop@119ab3e` (D-01). | Mitigado |
| R-02 | Perder datos del usuario al actualizar la app. | Clave `psps.progress.v1`; `applicationId mx.edu.uaz.psps`. | No se cambian paquete, clave, IDs de catálogo ni versión (D-03). Una actualización real sobre APK firmado previo **no** se probó. | Abierto (prueba en dispositivo) |
| R-03 | Romper imports al reorganizar. | ~120 imports `package:psps/...` en pruebas. | Reorganización solo por `git mv` + imports; criterio: 140 pruebas y `analyze` limpio (D-04, D-05). Resultado: los 140 nombres de prueba originales presentes y aprobados, `analyze` limpio. | Mitigado |
| R-04 | Romper la *library* `app.dart` con `part`. | `part`/`part of` y miembros privados compartidos. | Se mueve la *library* completa a `lib/app/` sin dividirla. | Mitigado por diseño |
| R-05 | Documentación heredada contradictoria (L-10 «Aprendo del error», once logros). | Adenda 29/10 INT-01 retira L-10; `CU07_REPASO.md` y `DISENO_SPRINT2.md` (hoy en `docs/legacy/`) aún lo citan. | Se mueven a `docs/legacy/` con aviso; `docs/USE_CASES.md` describe el comportamiento del código (diez logros). | Mitigado (documental) |
| R-06 | Estado v3 guardado con `L-10` se rechazaría al cargar. | `LearningController.load` exige `eligible.containsAll(achievements.keys)` (inferido en la auditoría y luego ejecutado en `MIG-02`). | Sin cambio de comportamiento en la migración; confirmado por ejecución en `MIG-02` (carga rechazada, datos intactos). | Abierto (decisión de producto) |
| R-07 | RP-01: el código admite catálogo/módulo/tema vacíos que el SRS prohíbe. | `DS101-04`, `CP05-12`. | Se conserva el comportamiento; decisión pendiente para Sprint 3. | Abierto |
| R-08 | Faltan `gradlew`, `gradlew.bat` y `gradle-wrapper.jar` (ignorados por `.gitignore` original). | `.gitignore` del origen. | Flutter los regenera al compilar; comprobado: `flutter build apk --debug` regeneró el wrapper y compiló, también tras `flutter clean`. | Mitigado |
| R-09 | Errores PKIX al descargar Gradle en Windows. | `README` original y `tool/build_android.ps1`. | Se conserva el script; se documenta en `docs/SETUP.md`. | Aceptado |
| R-10 | Secretos en el repositorio. | Búsqueda de `api_key/secret/password/BEGIN PRIVATE/storePassword` y de `*.jks`, `*.keystore`, `key.properties`, `local.properties`, `google-services.json`: solo cadenas de prueba (`'secretopregunta'`…) en `test/cu09_search_test.dart` y `test/sprint2_test.dart`. | Ninguna acción; `.gitignore` mantiene exclusiones de keystores. | Mitigado |
| R-11 | Release firmado con claves *debug*. | `buildTypes.release.signingConfig = debug` en `android/app/build.gradle.kts`. | Sin cambio (fuera de alcance); pendiente para publicación en tienda. | Aceptado |
| R-12 | iOS y HarmonyOS NEXT declarados como objetivo sin verificación. | No hay macOS/Xcode ni toolchain HarmonyOS en el entorno. | README y SETUP declaran «no verificado». | Aceptado |
| R-13 | Pruebas de dispositivo (integration_test) sin ejecutar tras la migración. | `flutter doctor` no lista ningún dispositivo Android conectado. | Registradas como pendientes en `docs/TESTING.md`. | Abierto |
| R-14 | CI no verificado. | No existe remoto ni ejecución de GitHub Actions. | Workflow incluido; su ejecución queda pendiente de publicar el repo. | Abierto |
| R-15 | Modificar el original por accidente. | Agentes con acceso de lectura a `PSPS_SOURCE`. | Trabajo con snapshot `git archive`; tareas con prohibición explícita; `git status` del original verificado vacío al cierre. | Mitigado |

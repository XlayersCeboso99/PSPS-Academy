# PSPS Academy — Aprende Ingeniería de Software

PSPS Academy es una aplicación educativa móvil, desarrollada con Flutter, para estudiar y practicar Ingeniería de Software **sin conexión a internet**. El estudiante recorre módulos, temas y subtemas, responde preguntas con retroalimentación inmediata, realiza actividades de ordenamiento, repasa sus errores, gana puntos y logros y desbloquea temas visuales. Todo el avance se guarda en el dispositivo.

> **Estado:** versión `0.2.0+5`, migrada sin cambios funcionales desde el repositorio del curso `TSP_PSPS` (ver [Procedencia](#procedencia)). Base preparada para el Sprint 3.

## Objetivo educativo

Ofrecer a estudiantes de Ingeniería de Software un recorrido breve y autónomo por fundamentos (estructuras y algoritmos, programación orientada a objetos, datos y relaciones, diseño centrado en las personas), con práctica inmediata y seguimiento visible del progreso, incluso sin red. Los contenidos actuales son **demostrativos**.

## Funcionalidades disponibles

| CU | Funcionalidad |
| --- | --- |
| CU-01 | Estudiar subtemas: contenido, ejemplo y preguntas con retroalimentación inmediata. |
| CU-02 | Realizar actividades opcionales de ordenamiento de pasos. |
| CU-03 | Consultar progreso (Sin iniciar / En progreso / Completado, con texto, ícono y color). |
| CU-04 | Completar contenidos: el estado se agrega de subtema a tema y a módulo. |
| CU-05 | Explorar libremente los módulos, temas y subtemas. |
| CU-06 | Consultar logros (10 logros) y elegir temas visuales desbloqueados. |
| CU-07 | Repasar respuestas originalmente incorrectas sin alterar avance ni recompensas. |
| CU-08 | Consultar actividades por módulo y tema (Pendiente / Realizada). |
| CU-09 | Buscar contenidos por palabra clave (títulos y contenido; sin acentos ni mayúsculas). |
| CU-10 | Consultar puntos (10 por cada actividad completada por primera vez). |

Catálogo actual: 4 módulos, 10 temas, 20 preguntas y 10 actividades. Detalle de reglas en [docs/USE_CASES.md](docs/USE_CASES.md).

## Tecnologías

- Flutter (canal estable) y Dart `^3.13.2`; verificado con Flutter 3.47.9 / Dart 3.13.7.
- `shared_preferences` (`SharedPreferencesAsync`) para persistencia local; sin backend ni red.
- Material 3; pruebas con `flutter_test`, `integration_test` y `flutter_driver`; análisis con `flutter_lints`.
- Android: Gradle 9.3.1 (Kotlin DSL), AGP 9.1.0, Kotlin 2.4.0, Java 17.

## Requisitos de desarrollo

- Flutter estable compatible con Dart 3.13 (`flutter --version`).
- Android SDK con licencias aceptadas y JDK 17+ (el de Android Studio sirve).
- Git.
- Opcional: dispositivo Android con depuración USB o un emulador.

Guía completa de instalación de Flutter y del entorno: [docs/SETUP.md](docs/SETUP.md).

## Descargar y ejecutar

```bash
git clone https://github.com/XlayersCeboso99/PSPS-Academy.git
cd PSPS-Academy
flutter pub get
flutter devices                # identifica tu dispositivo
flutter run -d <identificador> # Android
```

APK de depuración (no se versiona):

```bash
flutter build apk --debug
# build/app/outputs/flutter-apk/app-debug.apk
```

En Windows, si Gradle falla por `PKIX`/`certificate_unknown`, usa `.\tool\build_android.ps1` (ver [docs/SETUP.md](docs/SETUP.md)).

## Pruebas

```bash
flutter analyze
flutter test                                                         # pruebas unitarias y de widgets
flutter test tool/verifications/defects_sprint01_verification_test.dart
```

Las pruebas de integración en dispositivo, sus claves de almacenamiento aisladas y lo que falta verificar se describen en [docs/TESTING.md](docs/TESTING.md).

## Organización de carpetas

```text
lib/
  main.dart            arranque: crea LearningController y PspsApp
  app/                 interfaz (library app.dart + part review_screens / sprint2_screens)
  core/
    models/            modelo del curso (módulos, temas, subtemas, preguntas, prácticas)
    content/           catálogo educativo y validaciones
    persistence/       almacenamiento local del progreso
    learning/          LearningController y gamificación (puntos, logros, temas)
  features/
    activities/        CU-08 consultar actividades
    search/            CU-09 búsqueda de contenidos
test/                  pruebas unitarias y de widgets (+ test/regression/)
integration_test/      pruebas en dispositivo
test_driver/           drivers que exportan capturas
tool/                  scripts Android y verificaciones heredadas
android/ ios/ web/     proyectos de plataforma
docs/                  documentación vigente, auditoría y documentos heredados
```

Detalle y reglas de dependencia: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Soporte multiplataforma (estado real)

| Plataforma | Estado |
| --- | --- |
| Android | Compila (`flutter build apk --debug` verificado el 06/11/2026). Pruebas en dispositivo tras la migración: **pendientes**. |
| iOS | Proyecto presente, **no verificado** (requiere macOS/Xcode y firma). |
| HarmonyOS NEXT | Objetivo del proyecto, **sin soporte todavía**; el Flutter oficial no ofrece ese destino. Ver [docs/SPRINT3_PREPARATION.md](docs/SPRINT3_PREPARATION.md). |
| Web | Carpeta presente por la plantilla de Flutter; no es objetivo del proyecto. |

## Procedencia

Migrado desde [`XlayersCeboso99/TSP_PSPS`](https://github.com/XlayersCeboso99/TSP_PSPS), rama `develop`, commit `119ab3eed0467c62d6b6c3c73b0705ff302a16b1`, carpeta `Sprint 2/psps_academy`. El historial anterior, los PDF del curso (manual de usuario, guía de operación, reportes de pruebas) y las evidencias de los sprints 1 y 2 permanecen en ese repositorio. Detalles: [docs/MIGRATION_REPORT.md](docs/MIGRATION_REPORT.md).

## Limitaciones conocidas

- Contenido educativo demostrativo; se edita en `lib/core/content/catalog.dart`.
- Sin servidor, cuentas ni sincronización entre dispositivos.
- La compilación *release* usa la firma *debug*; no apta para publicación en tienda.
- iOS y HarmonyOS NEXT no verificados.
- El catálogo admite módulos/temas vacíos que el SRS (RP-01) prohíbe; decisión pendiente.
- Lista completa: [docs/MIGRATION_REPORT.md](docs/MIGRATION_REPORT.md#pendientes).

## Contribuir

Flujo de ramas, commits y revisión: [CONTRIBUTING.md](CONTRIBUTING.md). Cambios: [CHANGELOG.md](CHANGELOG.md).

## Licencia y atribuciones

Proyecto académico del equipo PSPS (curso TSP). El repositorio de origen no declara una licencia; hasta que el equipo elija una, todos los derechos quedan reservados a sus autores. Los íconos de la plantilla de Flutter y las dependencias (`shared_preferences`, `cupertino_icons`, SDK de Flutter) se distribuyen bajo licencia BSD-3-Clause / MIT de sus autores.

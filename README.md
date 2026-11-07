# PSPS Academy — Aprende Ingeniería de Software

Versión de desarrollo **0.2.0-dev.2+3**, construida sobre el sprint 1 e incorporando el diseño del sprint 2: repaso CU-07, actividades CU-08, búsqueda CU-09, puntos CU-10, logros CU-06 y temas visuales G-03. Permite estudiar y practicar sin conexión. Incluye proyectos Android/iOS; iOS aún no está verificado.

La guía vigente de este incremento está en [DISEÑO DEL SPRINT 2](docs/DISENO_SPRINT2.md), con decisiones de interfaz, compatibilidad y comprobaciones.

## Repaso CU-07

Entra a un tema o módulo y pulsa **Repasar preguntas**. Verás únicamente sus preguntas originalmente incorrectas y todavía no resueltas en repaso. Selecciona una, elige una opción y comprueba la respuesta. Si te equivocas, puedes reintentar; si aciertas y se guarda el resultado, desaparece de pendientes. Salir sin comprobar no registra una respuesta.

El repaso funciona offline, se conserva al reiniciar y no modifica respuestas originales, avance, estados ni puntos. Acertar en el repaso 3 preguntas que habías respondido mal otorga el logro L-10 «Aprendo del error» (CU-06). Los datos de la versión anterior se recuperan sin restablecer el progreso. Consulta [alcance y pruebas de CU-07](docs/CU07_REPASO.md).

Incluye cuatro módulos, diez temas, veinte preguntas con retroalimentación, diez actividades de ordenamiento, estados de progreso y almacenamiento local. Aplica el catálogo del equipo: diez puntos por primera actividad completada, once logros (L-01 a L-11) y cuatro temas de color. Los contenidos educativos siguen siendo demostrativos. El servidor y las pruebas iOS están pendientes.

## Ejecutar

Necesitas Flutter 3.47.2 con Dart 3.13.2 o una versión compatible con el proyecto.

```powershell
cd "Sprint 1/psps_academy"
flutter pub get
flutter devices
flutter run -d chrome
```

Para Android, conecta tu teléfono, activa depuración USB y acepta los avisos de autorización e instalación. Usa el identificador mostrado por `flutter devices`:

```powershell
flutter run -d <identificador>
```

Para abrir el proyecto en Visual Studio Code, abre esta carpeta (`Sprint 1/psps_academy`), selecciona el dispositivo y ejecuta la aplicación.

## Construir el APK

```powershell
flutter build apk --debug
```

El resultado está en `build/app/outputs/flutter-apk/app-debug.apk`. El APK no se versiona en el repositorio (pesa unos 170 MB); se genera con el comando anterior.

Si en Windows una descarga de Gradle falla por `PKIX` o `certificate_unknown`, utiliza el script local, que usa los certificados de confianza de Windows:

```powershell
.\tool\build_android.ps1
```

El script aplica la configuración únicamente durante su ejecución. No omite la validación de certificados ni modifica permanentemente Java.

## Verificar

```powershell
flutter analyze
flutter test
.\tool\verify_sprint2_android.ps1 -DeviceId <identificador>
```

El script de integración crea una copia temporal con un ID de aplicación distinto; usa además una clave de datos de prueba. Es necesario aislar ambos porque Flutter puede desinstalar la app que usa como ejecutor. Las pruebas unitarias y de interfaz emplean almacenamiento simulado; la integración comprueba el almacenamiento nativo real y exporta capturas. El estado efectivo de las verificaciones se registra en la documentación del sprint.

## Documentación

- Manual de usuario: `PSPS_ManualDeUsuario_TSP_Ago26.pdf`
- Guía de operación: `PSPS_GuiaDeOperacion_TSP_Ago26.pdf`
- Casos de prueba ejecutados: `PSPS_CasosDePruebaEjecutados_WP14.pdf`
- Reporte de pruebas: `PSPS_ReporteDePruebas_WP15.pdf`
- [Evidencias de la verificación](../Pruebas/evidencias) y [cómo reproducirla](../Pruebas/REPRODUCIR.md)
- [Guía de instalación y exposición](docs/GUIA_DEMO.md)
- [Alcance, pruebas y pendientes del sprint](docs/SPRINT_1.md)

Las lecciones se editan en `lib/data/catalog.dart`; las reglas de recorrido están en `lib/domain/learning_controller.dart`. Los IDs se mantienen estables para asociar el estado guardado con el contenido.

La versión iOS requiere compilación, firma y pruebas con macOS/Xcode; todavía no está verificada.

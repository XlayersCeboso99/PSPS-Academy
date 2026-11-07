# CU-07 — Repasar preguntas respondidas incorrectamente

Versión: 0.2.0-dev.1+2. Fecha: 23 de octubre de 2026.
Rama local: `feature/CU-07-repaso`, basada en `develop` (5a816f1).

## Alcance

Implementación de RF-10 / CA-10 del documento `PSPS_CasosDeUso_Sprint02_TSP_Ago26.pdf`, siguiendo el diseño `PSPS_DisenoCU07_Sprint02_TSP_Ago26.docx` compartido en el chat de Francisco Valdez. Esta entrega implementa CU-07; no representa la terminación de todo el sprint 2 ni la aprobación del equipo o del cliente.

- Acceso desde tema o módulo, con contador de pendientes del contexto seleccionado.
- Lista de preguntas originalmente incorrectas, excluyendo las ya resueltas en repaso.
- Selección, comprobación, explicación, reintento y confirmación después del guardado.
- Estado vacío y retorno al contexto de origen.
- Guardado local independiente de la respuesta original; funciona sin servidor.
- Salir sin comprobar no guarda una selección. Durante un guardado se bloquea la salida para evitar interrumpir la confirmación.
- Un fallo de guardado conserva la pregunta pendiente y permite volver a comprobar. Un fallo de lectura informa el problema y permite reintentar sin sobrescribir el estado guardado.
- El repaso no modifica avance, colores/estados, respuestas originales ni puntos. Desde la entrega de CU-06 (`feature/CU-06-logros`), acertar en el repaso 3 preguntas respondidas mal otorga L-10 «Aprendo del error», conforme al catálogo G-02 acordado en MR-09.

## Cómo demostrarlo

1. Abre un módulo y un tema. Estudia el subtema y responde incorrectamente una pregunta.
2. Vuelve al tema y pulsa **Repasar preguntas**. También puedes entrar desde el módulo para ver sus pendientes de todos los temas.
3. Abre una pregunta. **Comprobar respuesta** permanece deshabilitado hasta elegir una opción.
4. Comprueba una respuesta incorrecta: aparece la explicación y **Reintentar**; sigue pendiente.
5. Reintenta y responde correctamente. La app confirma el resultado únicamente después de guardarlo.
6. Vuelve a pendientes: la pregunta desaparece. Si era la última, aparece **No tienes preguntas pendientes**.
7. Cierra y abre la app: la resolución del repaso permanece. La respuesta original, el avance y los puntos conservan sus valores anteriores.

## Datos existentes

Se conserva la clave local `psps.progress.v1` para recuperar instalaciones anteriores. El lector admite el formato 1 y el formato 2; la siguiente escritura guarda formato 2 con `reviewAnswers`. Las escrituras normales también preservan ese campo. El último intento incorrecto se conserva, pero la pregunta sigue pendiente hasta un acierto guardado.

La versión antigua del sprint 1 no entiende el formato 2: evita regresar a ese APK después de usar esta versión. No desinstales ni borres datos si quieres conservar tu avance. No hay sincronización entre dispositivos.

## Verificación

- `flutter analyze`: sin incidencias.
- `flutter test`: 24 pruebas aprobadas (12 anteriores y 12 nuevas).
- Las nuevas pruebas cubren filtros por tema/módulo, reintentos, invariantes de avance/puntos, migración del formato anterior, persistencia al recargar, conservación del repaso tras otras escrituras, datos inválidos y fallos de lectura/guardado. La interfaz se verifica también a 390 × 844.
- `integration_test/offline_test.dart`: aprobada en Android físico modelo 24049RN28L el 23/10/2026. Usa una clave separada para proteger el progreso personal y comprueba almacenamiento nativo, error, reintento, acierto y recuperación del repaso al recrear el controlador. Registro: `prueba-android.log` en la carpeta de entrega. No se realizó una prueba con el teléfono en modo avión ni una validación iOS.
- Compilación del APK debug realizada en Windows. iOS requiere macOS/Xcode y no está verificado.

Para reproducir desde la carpeta Flutter:

```powershell
flutter pub get
flutter analyze
flutter test
flutter test integration_test/offline_test.dart -d <identificador-android>
.\tool\build_android.ps1
```

Si OneDrive bloquea archivos generados durante compilaciones sucesivas, realiza la compilación en una copia del proyecto fuera de su carpeta sincronizada. No borres el progreso del teléfono para solucionar problemas de compilación de la computadora.

## Archivos principales

| Archivo | Responsabilidad |
| --- | --- |
| `lib/data/progress_store.dart` | Formato persistente y lectura compatible con datos anteriores. |
| `lib/domain/learning_controller.dart` | Filtro de pendientes y guardado independiente del repaso. |
| `lib/ui/review_screens.dart` | Lista, pregunta y retroalimentación del repaso. |
| `lib/ui/app.dart` | Acceso desde módulo y tema. |
| `test/review_test.dart` | Pruebas unitarias y de interfaz de CU-07. |
| `integration_test/offline_test.dart` | Verificación del almacenamiento nativo y recorrido en Android. |

El contenido educativo y el sistema de puntos anterior permanecen como en la base del equipo. La incorporación del resto del catálogo de gamificación corresponde a sus propios casos de uso.

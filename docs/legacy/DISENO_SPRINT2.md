# Diseño del sprint 2 incorporado a PSPS Academy

Versión de desarrollo: **0.2.0-dev.2+3**. Fecha de entrega: **24/10/2026**.

## Qué se incorporó

| Diseño | Implementación |
| --- | --- |
| CU-05 — Explorar módulos | Acceso libre a los cuatro módulos, diez temas y subtemas existentes; estado por texto, ícono y color. |
| CU-06 — Consultar logros | Logros obtenidos con nombre, «Condición cumplida» y fecha fiable; estado vacío A1, próximos logros y temas visuales. Entrega específica en `feature/CU-06-logros` (ver `Sprint 2/Pruebas/CU06/README.md`). |
| CU-07 — Repaso | Pendientes por módulo/tema, pregunta, error/reintento, acierto guardado y estado vacío. Etiquetas y jerarquía del mockup adaptadas al tema visual común. |
| CU-08 — Actividades | Lista agrupada por módulo y tema, etiquetas Pendiente/Realizada, apertura de la actividad y estado sin actividad configurada. |
| CU-09 — Buscar | Lupa en Inicio, mínimo de tres caracteres, búsqueda local mientras se escribe, títulos primero, fragmento resaltado, estado y ruta de cada subtema; apertura y cero resultados. Admite frases aunque cambien de renglón. Entrega específica en `feature/CU-09-busqueda` (ver `Sprint 2/Pruebas/CU09/README.md`). |
| CU-10 — Puntos | Total local, 0 si no hay finalizaciones, sin historial ni fechas de transacciones. |
| G-01 | Diez puntos por primera actividad válida guardada; ningún duplicado al repetir o consultar. |
| G-02 | Once logros, L-01 a L-11, con las condiciones del catálogo acordado en MR-09. L-10 «Aprendo del error» se obtiene al acertar en el repaso 3 preguntas respondidas mal; el repaso no da puntos. |
| G-03 | Bosque inicial; Océano por primera actividad; Atardecer por primer módulo; Noche por recorrido completo. Elección persistente y contenido siempre libre. |

Las pantallas de consulta no guardan ni generan recompensas. Los cambios y sus avisos se publican después de guardar; si falla la escritura, permanecen el estado y la selección anteriores. Un error de carga se muestra sin sustituir datos por ceros ni sobreescribir el almacenamiento.

## Decisiones para armonizar los borradores

- Se conservan las pestañas Módulos y Mi progreso. Ambas ofrecen accesos a Actividades, Puntos y Logros. La lupa está en la barra de Inicio. Se evita introducir varios menús incompatibles de los distintos borradores.
- Se usa una sola familia de componentes, con Bosque como tema inicial. El repaso conserva la estructura y las acciones de las cinco pantallas de CU-07; su color sigue el tema seleccionado, en vez de fijar un azul distinto del resto de la app.
- Siguiendo el borrador específico CU-09, la búsqueda ignora mayúsculas y acentos de á/é/í/ó/ú/ü, conserva ñ y elimina espacios externos. Esto es una decisión de implementación para revisión; no se presenta como aprobación documental de O-01.
- Se buscan títulos, área del módulo, tema, contenido y ejemplos. Las preguntas, opciones, explicaciones de respuestas y actividades quedan fuera del índice.
- La actividad existente de cada tema representa la lista actual del catálogo. Un tema con una actividad sin pasos configurados muestra el estado sin actividades; no se inventaron ejercicios nuevos para llenar el diseño.
- Los borradores y SDS del ZIP no constituyen por sí mismos aprobación formal. Esta versión permite revisar y probar el diseño; no declara cerrado el sprint, sus firmas ni su aceptación.

## Datos y compatibilidad

Se mantiene la clave local `psps.progress.v1`, y se admiten los formatos 1 (sprint 1), 2 (repaso) y 3 (gamificación). La lectura de formatos anteriores recupera respuestas, actividades y repaso sin escribir en disco. Se calculan los puntos ya ganados una sola vez y se reconocen los logros correspondientes sin fecha histórica inventada. La siguiente acción explícita guarda el formato 3 completo.

El formato 3 persiste respuestas, actividades, repaso, total de puntos, IDs de actividades recompensadas, logros con fecha o valor nulo histórico y tema seleccionado. Las inconsistencias se reportan como error y se conserva el archivo anterior. Repetir una actividad no crea puntos, fechas ni avisos nuevos. El repaso preserva estos campos.

Actualiza el APK **sin desinstalar** para conservar el avance. Las versiones antiguas no entienden el formato 3: no regreses al APK anterior después de guardar con esta versión. Todo permanece en ese dispositivo; no hay servidor ni sincronización.

## Cómo revisar la app

1. En Inicio, abre Actividades y verifica su agrupación. Abrir una actividad pendiente no la completa.
2. Abre Puntos y Logros: consultar no cambia el estado.
3. Completa una actividad nueva: suma 10 puntos y permite Océano. Reabrirla no suma otra vez.
4. En Logros, selecciona un tema disponible. Cierra y abre la app para comprobar su conservación.
5. Usa la lupa y busca `clase`: se presentan CT-08 en títulos y CT-07 en contenido. Abre un resultado: no cambia el avance.
6. Busca `interaccion`, con o sin acento, y luego una palabra inexistente. Comprueba la búsqueda local y el estado vacío.
7. En un módulo con respuestas incorrectas, abre Repasar preguntas y recorre selección, error, reintento y acierto. La pregunta resuelta sale de pendientes sin puntos. Al resolver la tercera aparece el aviso del logro L-10 «Aprendo del error».

## Verificación reproducible

Resultados del 24/10/2026: análisis sin incidencias, **40 pruebas automáticas aprobadas** y recorrido integral aprobado en Android físico modelo 24049RN28L. Se exportaron **14 capturas** de la aplicación de pruebas, incluyendo los estados de búsqueda y repaso y el tema Noche. La prueba Android comprueba migración, consultas, búsqueda, repaso y persistencia al recargar. El recorrido general original no se ejecutó en modo avión. La verificación posterior de CU-07 en modo avión, sin red activa y con cinco capturas se registra en Pruebas/CU07/README.md; no amplía esa comprobación a todo el sprint.

```powershell
flutter pub get
flutter analyze
flutter test
.\tool\verify_sprint2_android.ps1 -DeviceId <identificador-android> -EvidenceDirectory <carpeta-de-evidencias>
.\tool\build_android.ps1
```

La prueba de diseño utiliza una app temporal con ID literal `mx.edu.uaz.psps.integration`, una clave de datos separada, una migración de ejemplo y capturas del Android real. El script hace la copia, cambia ID, namespace y actividad antes de invocar Flutter y utiliza --keep-app-running para evitar desinstalaciones automáticas; no modifica el proyecto normal. No ejecutes las pruebas de dispositivo directamente sobre el ID normal: Flutter puede desinstalar su aplicación al terminar. Sus imágenes muestran **datos de prueba**, no el avance personal del estudiante. Los resultados efectivos y las capturas se entregan en `entrega/Sprint2-Diseno/evidencias` dentro de App TSP. No se considera comprobado iOS desde Windows.

Si OneDrive bloquea archivos de compilación, usa una copia temporal fuera de la carpeta sincronizada. El código entregado permanece en `cu07-repaso/Sprint 1/psps_academy`.

## Fuentes del ZIP proporcionado

- PSPS_SDS_v0.2_Sprint02_TSP_Ago26.pdf.
- PSPS_CasosDeUso_Sprint02_TSP_Ago26.pdf.
- PSPS_BorradorDiseñoCU07_Sprint02_TSP_Ago26.pdf.
- PSPS_BorradorDiseno_CU08_Sprint02_TSP_Ago26.pdf.
- PSPS_Borrador_DiseñoCU09_RevisionCU06_Sprint02_TSP_Ago26.pdf.
- PSPS_BorradorDiseno_CU10_Sprint02_TSP_Ago26.pdf.
- PSPS_CatalogoGamificacion_Consolidado_Sprint02_TSP_Ago26.pdf.

Se priorizan las reglas conciliadas del SDS y el catálogo acordado en el contexto del equipo frente a propuestas anteriores incompatibles. La autorización para implementar todo el diseño proviene de la solicitud del usuario en esta sesión.

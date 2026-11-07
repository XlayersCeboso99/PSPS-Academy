# Guía de la demostración PSPS

Para el uso cotidiano consulta el Manual de usuario (PSPS_ManualDeUsuario_TSP_Ago26.pdf). La Guía de operación (PSPS_GuiaDeOperacion_TSP_Ago26.pdf) describe la instalación, actualización y conservación del avance de la versión 0.1.0+1.

## Instalar en Android

El APK `PSPS-Sprint1-debug.apk` se entrega aparte del repositorio (pesa unos 170 MB) o se genera con `flutter build apk --debug`. Es una versión de demostración firmada con una clave de desarrollo; no es una publicación de tienda.

1. Copia el APK a tu Android o ábrelo desde esta computadora mediante el medio que prefieras.
2. Abre el archivo en el teléfono. Si Android solicita permiso para instalar desde la aplicación que abre el archivo, habilítalo y sigue el aviso de instalación.
3. Abre **PSPS**. La primera ejecución ya contiene todas las lecciones de la demostración y empieza sin avance.

Para instalar por cable desde el proyecto: activa depuración USB, acepta la autorización del equipo y, si el fabricante lo exige, habilita «Instalar vía USB». Ejecuta `flutter install --debug -d <identificador>` después de compilar el APK. El identificador aparece en `flutter devices`.

## Estudiar

1. En **Módulos**, entra a un módulo y elige un tema.
2. Pulsa **Estudiar subtema**. Lee la explicación y utiliza **Siguiente** para ver el ejemplo; **Anterior** permite volver.
3. Pulsa **Ir a preguntas**, selecciona una opción y luego **Comprobar**.
4. Revisa la explicación de la respuesta. Una respuesta incorrecta también cuenta para tu recorrido.
5. Continúa con **Siguiente pregunta**. Al responder todas, el subtema y el tema se completan. El módulo se completa cuando todos sus temas están completos.

Leer sin responder no cambia el avance. Los estados incluyen texto: **Sin iniciar**, **En progreso** y **Completado**.

## Practicar

Desde la pantalla de un tema, pulsa **Realizar actividad**. Toca los elementos en el orden indicado para llenar los pasos. Si el orden es incorrecto, toca un paso elegido para retirarlo y acomodarlo de nuevo.

La actividad se registra automáticamente cuando los tres pasos están en el orden esperado. No hace falta pulsar «Finalizar». La recompensa de demostración es diez puntos una sola vez. Reabrir la actividad no duplica esa recompensa. Puedes completar el módulo sin hacer las actividades.

## Consultar y conservar el avance

La pestaña **Mi progreso** muestra preguntas respondidas, estados por tema, actividades realizadas y puntos de práctica. Los datos se guardan en este dispositivo; no se comparten con otro teléfono ni se sincronizan con un servidor.

Si el guardado falla, vuelve a intentar la acción. Si al abrir aparece un error de recuperación, pulsa **Reintentar**. No borres los datos de la aplicación si deseas conservar el avance. Desinstalarla puede perderlo.

## Recorrido sugerido para la exposición

1. Mostrar los cuatro módulos y abrir **Estructuras y algoritmos**.
2. Entrar a **Arreglos bidimensionales** y consultar el contenido. Volver al módulo para mostrar que sigue **Sin iniciar**.
3. Responder la primera pregunta con **Solo el valor**. Mostrar la retroalimentación y el estado **En progreso**.
4. Responder la segunda pregunta, revisar **Completado** y regresar al módulo.
5. Completar la actividad **Encuentra una celda** y mostrar los puntos de práctica.
6. Entrar a **Mi progreso**, cerrar la aplicación y volver a abrirla para comprobar que se conserva el avance.
7. Activar modo avión y repetir el recorrido con otro tema. Desactivar modo avión al terminar la prueba.

El contenido y los puntos son de demostración. Los logros, los desbloqueos, el servidor y la comprobación en iOS están pendientes. La guía describe esta versión 0.1.0, no la aplicación final del proyecto.

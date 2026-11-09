import 'package:psps/core/models/course.dart';

// Seed content for the sprint demonstration. D-01 (curriculum grouping and
// lesson details) still requires validation; IDs remain stable for persistence.
Topic _topic(
  String id,
  String title,
  String lessonTitle,
  String content,
  String example,
  List<(String, List<String>, int, String)> questions,
  String practiceTitle,
  String instruction,
  List<String> steps, {
  List<(String, String, List<String>)> extraPractices = const [],
}) => Topic(
  id: id,
  title: title,
  lessons: [
    Lesson(
      id: '$id.s1',
      title: lessonTitle,
      content: content,
      example: example,
      questions: [
        for (var i = 0; i < questions.length; i++)
          Question(
            id: '$id.s1.q${i + 1}',
            prompt: questions[i].$1,
            options: questions[i].$2,
            correctIndex: questions[i].$3,
            explanation: questions[i].$4,
          ),
      ],
    ),
  ],
  practice: Practice(
    id: '$id.a1',
    title: practiceTitle,
    instruction: instruction,
    steps: steps,
  ),
  extraPractices: [
    for (var i = 0; i < extraPractices.length; i++)
      Practice(
        id: '$id.a${i + 2}',
        title: extraPractices[i].$1,
        instruction: extraPractices[i].$2,
        steps: extraPractices[i].$3,
      ),
  ],
);

final catalog = <CourseModule>[
  CourseModule(
    id: 'm1',
    title: 'Estructuras y algoritmos',
    area: 'Fundamentos de programación',
    description: 'Organiza datos y descubre cómo procesarlos.',
    topics: [
      _topic(
        'CT-01',
        'Arreglos bidimensionales',
        'Datos en filas y columnas',
        'Un arreglo bidimensional organiza elementos en filas y columnas. Para consultar una celda necesitas dos índices: uno para la fila y otro para la columna. En este ejemplo, ambos índices empiezan en cero.',
        'matriz = [[4, 7], [2, 9]]\nmatriz[1][0] → 2\n\nFila 1, columna 0: segunda fila, primera columna.',
        [
          (
            '¿Qué necesitas para identificar una celda?',
            ['Solo el valor', 'Fila y columna', 'Solo la longitud'],
            1,
            'Cada celda se identifica mediante un par de índices: fila y columna.',
          ),
          (
            'En el ejemplo, ¿cuánto vale matriz[0][1]?',
            ['4', '2', '7'],
            2,
            'La fila 0 es [4, 7]. En esa fila, la columna 1 contiene 7.',
          ),
          (
            'Si una matriz tiene 3 filas y 4 columnas, ¿cuántas celdas contiene?',
            ['7', '34', '12'],
            2,
            'El total de celdas es filas × columnas: 3 × 4 = 12.',
          ),
          (
            'Para visitar todas las celdas de una matriz fila por fila, ¿qué estructura es la más adecuada?',
            [
              'Un solo ciclo sobre las columnas',
              'Dos ciclos anidados: filas por fuera y columnas por dentro',
              'Una condición if sin ciclos',
            ],
            1,
            'El ciclo externo avanza por las filas y el interno visita cada columna de la fila actual; así cada celda se visita una sola vez.',
          ),
        ],
        'Encuentra una celda',
        'Ordena los pasos para consultar una celda de la matriz.',
        [
          'Identificar el índice de fila',
          'Identificar el índice de columna',
          'Leer el valor en esa posición',
        ],
        extraPractices: [
          (
            'Recorre la matriz',
            'Ordena las celdas de matriz = [[4, 7], [2, 9]] tal como se visitan al recorrerla fila por fila.',
            [
              'matriz[0][0] → 4',
              'matriz[0][1] → 7',
              'matriz[1][0] → 2',
              'matriz[1][1] → 9',
            ],
          ),
        ],
      ),
      _topic(
        'CT-02',
        'Pilas',
        'El último en entrar sale primero',
        'Una pila sigue el principio LIFO: el último elemento insertado es el primero en salir. Push agrega un elemento en la cima; pop retira el de la cima. Es útil para deshacer acciones o administrar llamadas a funciones.',
        'Pila inicial: []\npush(A) → [A]\npush(B) → [A, B]\npop() → B\nPila restante: [A]',
        [
          (
            'Después de insertar A y luego B, ¿cuál sale primero?',
            ['B', 'A', 'Ambos a la vez'],
            0,
            'B está en la cima porque fue el último en entrar.',
          ),
          (
            '¿Qué operación inserta en la cima?',
            ['Pop', 'Push', 'Ordenar'],
            1,
            'Push inserta. Pop retira el elemento de la cima.',
          ),
          (
            'Si la pila es [A, B, C] y C está en la cima, ¿qué queda después de dos operaciones pop?',
            ['[A]', '[C]', '[A, B]'],
            0,
            'El primer pop retira C y el segundo retira B; solo queda A.',
          ),
          (
            '¿Por qué una pila es adecuada para implementar «deshacer» en un editor?',
            [
              'Porque conserva las acciones en orden alfabético',
              'Porque la última acción realizada es la primera que se revierte',
              'Porque elimina todas las acciones a la vez',
            ],
            1,
            'Deshacer revierte primero lo más reciente, que es exactamente el comportamiento LIFO de una pila.',
          ),
        ],
        'Simula una pila',
        'Ordena la secuencia para insertar A, insertar B y retirar B.',
        ['Push de A', 'Push de B', 'Pop devuelve B'],
        extraPractices: [
          (
            'Deshaz una acción',
            'Un editor guarda cada acción en una pila. Ordena lo que ocurre al escribir «Hola», aplicar negrita y después deshacer.',
            [
              'Push: escribir «Hola»',
              'Push: aplicar negrita',
              'Pop: se deshace la negrita',
              'El texto queda como «Hola» sin formato',
            ],
          ),
        ],
      ),
      _topic(
        'CT-03',
        'Colas',
        'El primero en entrar sale primero',
        'Una cola sigue el principio FIFO: el primer elemento en entrar es el primero en salir. Enqueue agrega al final y dequeue retira del frente. Una fila de atención es una analogía útil.',
        'Cola inicial: []\nenqueue(A) → [A]\nenqueue(B) → [A, B]\ndequeue() → A\nCola restante: [B]',
        [
          (
            '¿Qué principio utiliza una cola?',
            ['LIFO', 'FIFO', 'Orden aleatorio'],
            1,
            'FIFO significa primero en entrar, primero en salir.',
          ),
          (
            'Al retirar de la cola [A, B], ¿qué elemento sale?',
            ['B', 'Ninguno', 'A'],
            2,
            'A llegó antes y ocupa el frente de la cola.',
          ),
          (
            'En la cola [A, B, C], ¿dónde se agrega un nuevo elemento D con enqueue?',
            [
              'Al frente, antes de A',
              'Al final, después de C',
              'En medio, entre A y B',
            ],
            1,
            'Enqueue agrega al final; D esperará a que salgan A, B y C.',
          ),
          (
            'Una impresora compartida atiende los trabajos en el orden en que llegan. ¿Qué estructura modela mejor esa espera?',
            ['Una cola', 'Una pila', 'Un arreglo bidimensional'],
            0,
            'Los trabajos se atienden por orden de llegada (FIFO), igual que en una cola.',
          ),
        ],
        'Atiende una cola',
        'Ordena los eventos de una cola en la que A llega antes que B.',
        ['Entra A', 'Entra B', 'Sale A'],
        extraPractices: [
          (
            'Atiende turnos',
            'Ordena los eventos de una ventanilla a la que llegan A, B y C, en ese orden, y en la que se atiende a dos personas.',
            [
              'Entran A, B y C',
              'Sale A',
              'Sale B',
              'C sigue esperando su turno',
            ],
          ),
        ],
      ),
      _topic(
        'CT-04',
        'Algoritmos de ordenamiento',
        'Comparar e intercambiar',
        'Ordenar consiste en reorganizar elementos siguiendo un criterio, como de menor a mayor. El método burbuja compara elementos vecinos e intercambia los que están en el orden incorrecto. Repite las pasadas hasta ordenar la lista.',
        'Lista: [3, 1, 2]\nComparar 3 y 1 → [1, 3, 2]\nComparar 3 y 2 → [1, 2, 3]',
        [
          (
            '¿Qué pares compara el método burbuja?',
            ['Elementos vecinos', 'Solo el primero y el último', 'Ningún par'],
            0,
            'Burbuja compara posiciones adyacentes y las intercambia si hace falta.',
          ),
          (
            '¿Cuál es el orden ascendente de [3, 1, 2]?',
            ['[3, 2, 1]', '[1, 2, 3]', '[2, 1, 3]'],
            1,
            'En orden ascendente cada elemento es menor o igual que el siguiente.',
          ),
          (
            'Al comparar 5 y 2 para ordenar de menor a mayor, ¿qué hace el método burbuja?',
            ['Los intercambia', 'Los deja igual', 'Elimina el 5'],
            0,
            'Como 5 es mayor que 2 y deben quedar de menor a mayor, se intercambian.',
          ),
          (
            'Si en una pasada completa del método burbuja no hubo ningún intercambio, ¿qué se puede concluir?',
            [
              'La lista está vacía',
              'Hay que reiniciar desde el último elemento',
              'La lista ya está ordenada',
            ],
            2,
            'Si ningún par de vecinos estaba fuera de orden, toda la lista está ordenada y el algoritmo puede terminar.',
          ),
        ],
        'Ordena con burbuja',
        'Ordena los estados después de comparar los vecinos de izquierda a derecha.',
        ['[3, 1, 2]', '[1, 3, 2]', '[1, 2, 3]'],
        extraPractices: [
          (
            'Primera pasada',
            'Ordena los estados de [5, 1, 4, 2] durante la primera pasada del método burbuja, comparando vecinos de izquierda a derecha.',
            ['[5, 1, 4, 2]', '[1, 5, 4, 2]', '[1, 4, 5, 2]', '[1, 4, 2, 5]'],
          ),
        ],
      ),
    ],
  ),
  CourseModule(
    id: 'm2',
    title: 'Programación y objetos',
    area: 'Diseño de software',
    description: 'Modela responsabilidades y maneja situaciones inesperadas.',
    topics: [
      _topic(
        'CT-06',
        'Manejo de excepciones',
        'Responder a los errores',
        'Una excepción representa una situación que interrumpe el flujo normal. Try delimita la operación que puede fallar y catch maneja una excepción compatible. Finally permite ejecutar limpieza tanto si hubo una excepción como si no.',
        'try {\n  leerArchivo();\n} catch (error) {\n  mostrarMensaje();\n} finally {\n  liberarRecursos();\n}',
        [
          (
            '¿Dónde se maneja una excepción capturada?',
            ['En el nombre del archivo', 'En catch', 'En un comentario'],
            1,
            'Catch ejecuta el manejo correspondiente a la excepción capturada.',
          ),
          (
            '¿Para qué se usa finally?',
            [
              'Para ignorar todo error',
              'Para declarar una clase',
              'Para realizar limpieza',
            ],
            2,
            'Finally ejecuta limpieza al salir del bloque, haya o no una excepción.',
          ),
          (
            'Si el bloque try termina sin errores, ¿qué ocurre con catch y finally?',
            [
              'Se ejecutan ambos',
              'Catch no se ejecuta; finally sí',
              'No se ejecuta ninguno',
            ],
            1,
            'Catch solo se ejecuta cuando se captura una excepción; finally se ejecuta en ambos casos.',
          ),
          (
            '¿Cuál es la mejor práctica al capturar una excepción?',
            [
              'Capturarla en un catch vacío para ocultarla',
              'Cerrar la aplicación ante cualquier error',
              'Informar el problema y dejar el sistema en un estado consistente',
            ],
            2,
            'Un catch vacío oculta fallos y dificulta corregirlos. Manejar una excepción implica comunicar o registrar el error y recuperar un estado válido.',
          ),
        ],
        'Maneja un fallo',
        'Ordena un flujo en el que falla la lectura y después se liberan los recursos.',
        [
          'Intentar leer el archivo',
          'Capturar el error y mostrar un mensaje',
          'Liberar los recursos en finally',
        ],
        extraPractices: [
          (
            'Lectura sin errores',
            'Ordena el flujo cuando la lectura del archivo termina sin excepciones.',
            [
              'Intentar leer el archivo',
              'La lectura termina sin excepción',
              'Se omite el bloque catch',
              'Liberar los recursos en finally',
            ],
          ),
        ],
      ),
      _topic(
        'CT-07',
        'Herencia en interfaces',
        'Extender un contrato',
        'Una interfaz declara un contrato. En lenguajes que permiten extender interfaces, una interfaz hija puede ampliar los requisitos de otra. Una clase que implementa ese contrato debe satisfacer sus miembros, incluidos los heredados. Este ejemplo usa sintaxis de Java.',
        'interface Figura { double area(); }\ninterface Coloreada extends Figura {\n  String color();\n}\n// Una clase concreta que implementa Coloreada\n// proporciona area() y color().',
        [
          (
            '¿Qué describe una interfaz?',
            [
              'Un contrato',
              'Una tabla de base de datos',
              'Una copia de un objeto',
            ],
            0,
            'El contrato indica qué operaciones debe proporcionar una implementación.',
          ),
          (
            'En el ejemplo, ¿qué debe proporcionar una clase concreta?',
            ['Solo color()', 'area() y color()', 'Ningún método'],
            1,
            'Coloreada amplía Figura; el contrato incluye area() y color().',
          ),
          (
            'En Java, ¿qué palabra usa una interfaz para ampliar otra interfaz?',
            ['extends', 'implements', 'new'],
            0,
            'Una interfaz amplía otra con extends; una clase usa implements para cumplir un contrato.',
          ),
          (
            'Si una clase concreta implementa Coloreada pero solo define color(), ¿qué ocurre en Java?',
            [
              'Compila sin problema',
              'El compilador genera area() automáticamente',
              'No compila, salvo que la clase se declare abstracta',
            ],
            2,
            'Una clase concreta debe implementar todos los métodos del contrato, incluidos los heredados de Figura. Solo una clase abstracta puede dejarlos pendientes.',
          ),
        ],
        'Amplía un contrato',
        'Ordena los pasos para extender e implementar una interfaz.',
        [
          'Declarar la interfaz Figura',
          'Extender Figura con Coloreada',
          'Implementar area() y color() en una clase',
        ],
        extraPractices: [
          (
            'Cumple el contrato',
            'Ordena los pasos para crear una clase Circulo que cumpla con la interfaz Coloreada y usarla como Figura.',
            [
              'Declarar class Circulo implements Coloreada',
              'Implementar los métodos area() y color()',
              'Compilar sin métodos del contrato pendientes',
              'Asignar un Circulo a una variable de tipo Figura',
            ],
          ),
        ],
      ),
      _topic(
        'CT-08',
        'Clases y objetos',
        'Del modelo a la instancia',
        'Una clase describe atributos y comportamientos. Un objeto es una instancia de esa clase con su propio estado. Dos objetos pueden compartir la definición de clase y tener valores distintos.',
        'Clase: Estudiante\nAtributo: nombre\nComportamiento: estudiar()\n\nObjeto 1: nombre = Ana\nObjeto 2: nombre = Luis',
        [
          (
            '¿Qué es un objeto?',
            [
              'Una palabra reservada',
              'Una instancia de una clase',
              'Siempre un número',
            ],
            1,
            'Un objeto es una instancia concreta de una clase.',
          ),
          (
            '¿Pueden dos objetos de la misma clase tener nombres distintos?',
            ['No', 'Solo si cambian de clase', 'Sí'],
            2,
            'Cada objeto puede mantener su propio estado aunque comparta la misma clase.',
          ),
          (
            'En el ejemplo, ¿qué es nombre?',
            ['Un atributo', 'Un comportamiento', 'Una clase'],
            0,
            'nombre forma parte del estado de cada estudiante: es un atributo. estudiar() es un comportamiento.',
          ),
          (
            'Si cambias el nombre del objeto 1 a «Ana María», ¿qué ocurre con el objeto 2?',
            [
              'También cambia a «Ana María»',
              'Conserva su nombre, Luis',
              'Deja de existir',
            ],
            1,
            'Cada instancia mantiene su propio estado; modificar un objeto no altera a otro de la misma clase.',
          ),
        ],
        'Construye un objeto',
        'Ordena los pasos para modelar y utilizar un estudiante.',
        [
          'Definir la clase Estudiante',
          'Crear una instancia con su nombre',
          'Invocar estudiar() en la instancia',
        ],
        extraPractices: [
          (
            'Dos instancias',
            'Ordena los pasos para comprobar que dos objetos de la misma clase mantienen estados independientes.',
            [
              'Definir la clase Estudiante con el atributo nombre',
              'Crear a Ana y a Luis como instancias',
              'Cambiar el nombre de Ana',
              'Verificar que Luis conserva su nombre',
            ],
          ),
        ],
      ),
    ],
  ),
  CourseModule(
    id: 'm3',
    title: 'Datos y relaciones',
    area: 'Bases de datos',
    description: 'Consulta información y representa sus relaciones.',
    topics: [
      _topic(
        'CT-05',
        'Lenguaje de manipulación de datos (DML)',
        'Trabajar con registros',
        'SQL permite trabajar con datos de tablas. INSERT agrega filas, UPDATE modifica filas y DELETE las elimina. SELECT consulta datos. En UPDATE y DELETE, una condición WHERE delimita las filas afectadas.',
        "INSERT INTO estudiante (id, nombre) VALUES (1, 'Ana');\nUPDATE estudiante SET nombre = 'Ana María' WHERE id = 1;\nSELECT nombre FROM estudiante WHERE id = 1;",
        [
          (
            '¿Qué instrucción agrega una fila?',
            ['INSERT', 'UPDATE', 'DELETE'],
            0,
            'INSERT agrega registros nuevos a una tabla.',
          ),
          (
            '¿Para qué sirve WHERE en un UPDATE?',
            [
              'Para crear otra tabla',
              'Para seleccionar las filas que se modificarán',
              'Para duplicar todas las filas',
            ],
            1,
            'WHERE filtra las filas afectadas; sin esa condición pueden modificarse todas.',
          ),
          (
            '¿Qué instrucción consulta datos sin modificarlos?',
            ['DELETE', 'SELECT', 'UPDATE'],
            1,
            'SELECT solo lee filas; INSERT, UPDATE y DELETE modifican la tabla.',
          ),
          (
            '¿Qué ocurre al ejecutar DELETE FROM estudiante; sin una condición WHERE?',
            [
              'No se elimina nada',
              'Solo se elimina la primera fila',
              'Se eliminan todas las filas de la tabla',
            ],
            2,
            'Sin WHERE la instrucción afecta a todas las filas. Por eso conviene revisar la condición antes de ejecutar UPDATE o DELETE.',
          ),
        ],
        'Trabaja con un registro',
        'Ordena las acciones para crear, modificar y comprobar un registro.',
        [
          'INSERT: agregar a Ana',
          'UPDATE: cambiar su nombre',
          'SELECT: consultar el resultado',
        ],
        extraPractices: [
          (
            'Elimina con cuidado',
            'Ordena los pasos para eliminar de forma segura al estudiante con id = 2.',
            [
              'SELECT: confirmar la fila con id = 2',
              'DELETE con WHERE id = 2',
              'SELECT: comprobar que la fila ya no existe',
            ],
          ),
        ],
      ),
      _topic(
        'CT-09',
        'Modelos entidad-relación',
        'Representar un dominio',
        'Un modelo entidad-relación representa entidades, atributos y relaciones de un dominio. Una entidad puede ser Estudiante; un atributo puede ser su identificador. La cardinalidad expresa cuántas ocurrencias pueden participar en una relación.',
        'Estudiante ── se inscribe en ── Curso\n\nUn estudiante puede cursar varios cursos.\nUn curso puede tener varios estudiantes.\nRelación: muchos a muchos.',
        [
          (
            'En el ejemplo, ¿cuál es una entidad?',
            ['Se inscribe en', 'Estudiante', 'Muchos'],
            1,
            'Estudiante es una entidad. «Se inscribe en» describe la relación.',
          ),
          (
            'Si hay varios estudiantes por curso y varios cursos por estudiante, ¿cuál es la cardinalidad?',
            ['Uno a uno', 'Uno a muchos', 'Muchos a muchos'],
            2,
            'Ambos extremos permiten múltiples ocurrencias: muchos a muchos.',
          ),
          (
            'En el modelo, ¿qué es el identificador de un estudiante?',
            ['Un atributo', 'Una relación', 'Una cardinalidad'],
            0,
            'El identificador describe a la entidad Estudiante; por eso es un atributo.',
          ),
          (
            'Cada estudiante tiene exactamente una credencial y cada credencial pertenece a un solo estudiante. ¿Cuál es la cardinalidad?',
            ['Uno a muchos', 'Uno a uno', 'Muchos a muchos'],
            1,
            'Cada ocurrencia de un lado se asocia con una sola del otro, en ambos sentidos: uno a uno.',
          ),
        ],
        'Modela una relación',
        'Ordena los pasos para representar las inscripciones.',
        [
          'Identificar Estudiante y Curso',
          'Definir la relación de inscripción',
          'Indicar la cardinalidad muchos a muchos',
        ],
        extraPractices: [
          (
            'Modela una tutoría',
            'Un profesor es tutor de varios estudiantes y cada estudiante tiene un solo tutor. Ordena los pasos para modelarlo.',
            [
              'Identificar Profesor y Estudiante',
              'Definir la relación «es tutor de»',
              'Indicar la cardinalidad uno a muchos',
            ],
          ),
        ],
      ),
    ],
  ),
  CourseModule(
    id: 'm4',
    title: 'Diseño para las personas',
    area: 'Interacción humano-computadora',
    description: 'Construye interfaces claras y fáciles de comprender.',
    topics: [
      _topic(
        'CT-10',
        'Principios básicos de interacción humano-computadora',
        'Dar claridad y retroalimentación',
        'Una interfaz debe comunicar qué puede hacer la persona y qué ocurrió después de una acción. Las etiquetas claras, la consistencia y la retroalimentación ayudan a comprenderla. Comunica los estados con texto además de color para que no dependan únicamente de la percepción visual.',
        'Acción: guardar una respuesta\nMientras espera: «Guardando…»\nResultado: «Respuesta guardada»\nSi falla: mensaje claro y opción de reintentar.',
        [
          (
            '¿Qué ayuda a entender el resultado de una acción?',
            [
              'Ocultar el estado',
              'Cambiar controles sin explicación',
              'Mostrar retroalimentación',
            ],
            2,
            'La retroalimentación permite saber qué sucedió y qué hacer después.',
          ),
          (
            '¿Cómo conviene comunicar un estado completado?',
            [
              'Con texto e indicador visual',
              'Solo con color verde',
              'Sin ninguna señal',
            ],
            0,
            'El texto y el indicador visual comunican el estado sin depender solo del color.',
          ),
          (
            '¿Por qué conviene que un mismo botón tenga el mismo nombre y lugar en todas las pantallas?',
            [
              'Por consistencia: la persona lo reconoce sin volver a aprenderlo',
              'Para que la interfaz use menos colores',
              'Porque así ya no se necesita retroalimentación',
            ],
            0,
            'La consistencia reduce el esfuerzo: lo aprendido en una pantalla sirve en las demás.',
          ),
          (
            'Si falla el guardado de una respuesta, ¿qué mensaje es más útil?',
            [
              '«Error 0x80»',
              'Ningún mensaje; volver al inicio',
              '«No se pudo guardar tu respuesta. Intenta de nuevo.» con un botón Reintentar',
            ],
            2,
            'Un buen mensaje de error explica qué pasó en lenguaje claro y ofrece una forma de recuperarse.',
          ),
        ],
        'Diseña una interacción',
        'Ordena las etapas de una interacción que comunica su resultado.',
        [
          'La persona ejecuta una acción',
          'La interfaz indica que se está procesando',
          'La interfaz muestra el resultado',
        ],
        extraPractices: [
          (
            'Recupérate de un error',
            'Ordena las etapas de una interacción en la que el guardado falla y la persona se recupera.',
            [
              'La persona toca Guardar',
              'La interfaz muestra «Guardando…»',
              'Aparece un mensaje claro con la opción Reintentar',
              'La persona reintenta y ve «Respuesta guardada»',
            ],
          ),
        ],
      ),
    ],
  ),
];

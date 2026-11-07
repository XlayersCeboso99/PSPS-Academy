import '../domain/course.dart';

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
  List<String> steps,
) => Topic(
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
        ],
        'Encuentra una celda',
        'Ordena los pasos para consultar una celda de la matriz.',
        [
          'Identificar el índice de fila',
          'Identificar el índice de columna',
          'Leer el valor en esa posición',
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
        ],
        'Simula una pila',
        'Ordena la secuencia para insertar A, insertar B y retirar B.',
        ['Push de A', 'Push de B', 'Pop devuelve B'],
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
        ],
        'Atiende una cola',
        'Ordena los eventos de una cola en la que A llega antes que B.',
        ['Entra A', 'Entra B', 'Sale A'],
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
        ],
        'Ordena con burbuja',
        'Ordena los estados después de comparar los vecinos de izquierda a derecha.',
        ['[3, 1, 2]', '[1, 3, 2]', '[1, 2, 3]'],
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
        ],
        'Maneja un fallo',
        'Ordena un flujo en el que falla la lectura y después se liberan los recursos.',
        [
          'Intentar leer el archivo',
          'Capturar el error y mostrar un mensaje',
          'Liberar los recursos en finally',
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
        ],
        'Amplía un contrato',
        'Ordena los pasos para extender e implementar una interfaz.',
        [
          'Declarar la interfaz Figura',
          'Extender Figura con Coloreada',
          'Implementar area() y color() en una clase',
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
        ],
        'Construye un objeto',
        'Ordena los pasos para modelar y utilizar un estudiante.',
        [
          'Definir la clase Estudiante',
          'Crear una instancia con su nombre',
          'Invocar estudiar() en la instancia',
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
        ],
        'Trabaja con un registro',
        'Ordena las acciones para crear, modificar y comprobar un registro.',
        [
          'INSERT: agregar a Ana',
          'UPDATE: cambiar su nombre',
          'SELECT: consultar el resultado',
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
        ],
        'Modela una relación',
        'Ordena los pasos para representar las inscripciones.',
        [
          'Identificar Estudiante y Curso',
          'Definir la relación de inscripción',
          'Indicar la cardinalidad muchos a muchos',
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
        ],
        'Diseña una interacción',
        'Ordena las etapas de una interacción que comunica su resultado.',
        [
          'La persona ejecuta una acción',
          'La interfaz indica que se está procesando',
          'La interfaz muestra el resultado',
        ],
      ),
    ],
  ),
];

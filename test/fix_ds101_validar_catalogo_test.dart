import 'package:flutter_test/flutter_test.dart';
import 'package:psps/data/catalog.dart';
import 'package:psps/data/progress_store.dart';
import 'package:psps/domain/catalog_validation.dart';
import 'package:psps/domain/course.dart';
import 'package:psps/domain/learning_controller.dart';
import 'package:psps/ui/app.dart';

import 'support.dart';

// D-S1-01 · RP-01 · TU-06 (WP.15 H-02): el catálogo se valida antes de usarse;
// si es inválido se muestra «Contenido no disponible» y no se escribe nada.

Lesson lessonWith(String id, List<Question> questions) => Lesson(
  id: id,
  title: 'Subtema $id',
  content: 'Contenido',
  example: 'Ejemplo',
  questions: questions,
);

Question question(String id, {int correct = 0, int options = 2}) => Question(
  id: id,
  prompt: 'Pregunta $id',
  options: [for (var i = 0; i < options; i++) 'Opción $i'],
  correctIndex: correct,
  explanation: 'Explicación',
);

CourseModule moduleWith(String id, List<Topic> topics) => CourseModule(
  id: id,
  title: 'Módulo $id',
  area: 'Área',
  description: 'Solo para pruebas.',
  topics: topics,
);

Topic topicWith(
  String id,
  List<Lesson> lessons, {
  List<String> steps = const ['Uno', 'Dos'],
  String? practiceId,
}) => Topic(
  id: id,
  title: 'Tema $id',
  lessons: lessons,
  practice: Practice(
    id: practiceId ?? '$id.a1',
    title: 'Actividad $id',
    instruction: 'Ordena',
    steps: steps,
  ),
);

final invalid = [
  moduleWith('m1', [
    topicWith('T-01', [lessonWith('T-01.s1', [question('T-01.s1.q1')])]),
  ]),
  moduleWith('m2', [
    // Tema repetido.
    topicWith('T-01', [lessonWith('T-02.s1', [question('T-02.s1.q1')])]),
    topicWith(
      'T-03',
      [
        lessonWith('T-03.s1', []),
        lessonWith('T-03.s2', [
          question('T-03.s2.q1', correct: 5),
          question('T-03.s2.q2', options: 1),
          question(' '),
        ]),
      ],
      steps: ['Solo uno'],
    ),
  ]),
];

void main() {
  test('DS101-01: the product catalog is valid', () {
    expect(validateCatalog(catalog), isEmpty);
  });

  test('DS101-02: each kind of invalid content is reported', () {
    final errors = validateCatalog(invalid);
    expect(errors, contains('Identificador repetido: T-01'));
    expect(errors, contains('El subtema T-03.s1 no tiene preguntas'));
    expect(
      errors,
      contains('La pregunta T-03.s2.q1 tiene la respuesta correcta fuera de rango'),
    );
    expect(
      errors,
      contains('La pregunta T-03.s2.q2 tiene menos de dos opciones'),
    );
    expect(errors, contains('Pregunta sin identificador'));
    expect(errors, contains('La actividad T-03.a1 tiene menos de dos elementos'));
  });

  test(
    'DS101-03: an invalid catalog is not used and saved progress is not touched',
    () async {
      final saved = ProgressSnapshot(answers: {'T-01.s1.q1': 0}).encode();
      final store = MemoryStore()..raw = saved;
      final c = LearningController(modules: invalid, store: store);
      await c.load();
      expect(c.ready, isFalse);
      expect(c.loadError, LearningController.contentUnavailable);
      expect(c.catalogErrors, isNotEmpty);
      expect(store.raw, saved);
      expect(store.writes, 0);
      expect(await c.answer(invalid.first.questions.first, 0), isFalse);
      expect(store.writes, 0);
    },
  );

  test('DS101-04: empty structures keep their empty states (CU-05, CU-08)', () async {
    for (final modules in [
      <CourseModule>[],
      [moduleWith('m5', const [])],
      [
        moduleWith('m6', [topicWith('T-09', const [], steps: const [], practiceId: '')]),
      ],
    ]) {
      expect(validateCatalog(modules), isEmpty);
      final c = LearningController(modules: modules, store: MemoryStore());
      await c.load();
      expect(c.ready, isTrue);
    }
  });

  testWidgets('DS101-05: the app shows «Contenido no disponible»', (
    tester,
  ) async {
    final store = MemoryStore();
    final c = LearningController(modules: invalid, store: store);
    await c.load();
    await tester.pumpWidget(PspsApp(controller: c));
    await tester.pumpAndSettle();
    expect(find.text(LearningController.contentUnavailable), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text(LearningController.contentUnavailable), findsOneWidget);
    expect(store.writes, 0);
  });
}

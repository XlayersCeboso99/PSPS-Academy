import 'package:flutter_test/flutter_test.dart';
import 'package:psps/data/catalog.dart';
import 'package:psps/data/catalog_validation.dart';
import 'package:psps/data/progress_store.dart';
import 'package:psps/domain/course.dart';
import 'package:psps/domain/learning_controller.dart';
import 'package:psps/ui/app.dart';

import 'support.dart';

List<CourseModule> withQuestion(Question question) => [
  CourseModule(
    id: 'm',
    title: 'Módulo fixture',
    area: 'Materia fixture',
    description: '',
    topics: [
      Topic(
        id: 't',
        title: 'Tema fixture',
        lessons: [
          Lesson(
            id: 'l',
            title: 'Subtema fixture',
            content: '',
            example: '',
            questions: [question, question],
          ),
        ],
        practice: const Practice(
          id: 'p',
          title: '',
          instruction: '',
          steps: [],
        ),
      ),
    ],
  ),
];

void main() {
  test(
    'CAT-01: duplicate question identities cannot merge unrelated progress',
    () {
      expect(
        () => validateCatalog(withQuestion(catalog.first.questions.first)),
        throwsFormatException,
      );
    },
  );
  test('CAT-02: out-of-range correct answers are rejected', () {
    const q = Question(
      id: 'q',
      prompt: 'Pregunta fixture',
      options: ['A', 'B'],
      correctIndex: 2,
      explanation: '',
    );
    expect(() => validateCatalog(withQuestion(q)), throwsFormatException);
  });
  testWidgets(
    'CAT-03: invalid catalog shows an error and preserves saved data',
    (tester) async {
      final store = MemoryStore()..raw = ProgressSnapshot(points: 0).encode();
      final before = store.raw;
      final c = LearningController(
        modules: [catalog.first, catalog.first],
        store: store,
      );
      await c.load();
      await tester.pumpWidget(PspsApp(controller: c));
      await tester.pumpAndSettle();
      expect(find.textContaining('Contenido no disponible'), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(c.ready, isFalse);
      expect(store.raw, before);
      expect(store.writes, 0);
    },
  );
}

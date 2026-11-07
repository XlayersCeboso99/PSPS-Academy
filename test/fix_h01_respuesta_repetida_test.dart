import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psps/data/catalog.dart';
import 'package:psps/domain/course.dart';
import 'package:psps/domain/learning_controller.dart';
import 'package:psps/ui/app.dart';

import 'support.dart';

// H-01 (auditoría del Sprint 01, WP.15) · RP-02: las respuestas posteriores
// actualizan la retroalimentación y no incrementan las preguntas respondidas.

final module = catalog.first;
final topic = module.topics.first;
final lesson = topic.lessons.first;
final q = lesson.questions.first;
final wrong = (q.correctIndex + 1) % q.options.length;

Future<void> tapText(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.scrollUntilVisible(
    finder,
    160,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(tester.element(finder), alignment: .3);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<(LearningController, MemoryStore)> open(WidgetTester tester) async {
  final store = MemoryStore();
  final c = LearningController(modules: catalog, store: store);
  await c.load();
  await tester.pumpWidget(
    MaterialApp(
      home: QuestionsScreen(
        controller: c,
        module: module,
        topic: topic,
        lesson: lesson,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (c, store);
}

FilledButton button(WidgetTester tester, String label) =>
    tester.widget<FilledButton>(find.widgetWithText(FilledButton, label));

void main() {
  testWidgets(
    'H01-01: wrong, then «Responder de nuevo» with the right option shows correct feedback; counts once',
    (tester) async {
      final (c, store) = await open(tester);
      await tapText(tester, q.options[wrong]);
      await tapText(tester, 'Comprobar');
      expect(find.text('Sigue aprendiendo'), findsOneWidget);
      expect(c.answeredCount, 1);
      expect(store.writes, 1);

      await tapText(tester, 'Responder de nuevo');
      expect(find.text('Sigue aprendiendo'), findsNothing);
      expect(button(tester, 'Comprobar de nuevo').onPressed, isNull);
      await tapText(tester, q.options[q.correctIndex]);
      expect(button(tester, 'Comprobar de nuevo').onPressed, isNotNull);
      await tapText(tester, 'Comprobar de nuevo');

      expect(find.text('¡Respuesta correcta!'), findsOneWidget);
      expect(find.text(q.explanation), findsOneWidget);
      expect(c.answerFor(q), wrong, reason: 'first answer is kept');
      expect(c.answeredCount, 1);
      expect(store.writes, 1, reason: 'a new attempt is not saved');
      expect(c.needsReview(q), isTrue, reason: 'CU-07 still lists it');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('H01-02: correct, then a wrong new attempt shows the correction', (
    tester,
  ) async {
    final (c, store) = await open(tester);
    await tapText(tester, q.options[q.correctIndex]);
    await tapText(tester, 'Comprobar');
    expect(find.text('¡Respuesta correcta!'), findsOneWidget);
    await tapText(tester, 'Responder de nuevo');
    await tapText(tester, q.options[wrong]);
    await tapText(tester, 'Comprobar de nuevo');
    expect(find.text('Sigue aprendiendo'), findsOneWidget);
    expect(
      find.text('Respuesta correcta: ${q.options[q.correctIndex]}'),
      findsOneWidget,
    );
    expect(c.answerFor(q), q.correctIndex);
    expect(c.answeredCount, 1);
    expect(store.writes, 1);
  });

  testWidgets(
    'H01-03: cancel restores the saved feedback; next question starts clean',
    (tester) async {
      final (c, _) = await open(tester);
      await tapText(tester, q.options[wrong]);
      await tapText(tester, 'Comprobar');
      await tapText(tester, 'Responder de nuevo');
      expect(find.text('Siguiente pregunta'), findsNothing);
      await tapText(tester, 'Cancelar nuevo intento');
      expect(find.text('Sigue aprendiendo'), findsOneWidget);
      await tapText(tester, 'Siguiente pregunta');
      expect(find.text('Responder de nuevo'), findsNothing);
      expect(
        button(tester, 'Comprobar').onPressed,
        isNull,
        reason: 'second question has no selection yet',
      );
      expect(c.answeredCount, 1);
    },
  );

  test('H01-04: answering an answered question again never saves or counts', () async {
    final store = MemoryStore();
    final c = LearningController(modules: catalog, store: store);
    await c.load();
    await c.answer(q, wrong);
    final writes = store.writes;
    expect(await c.answer(q, q.correctIndex), isTrue);
    expect(c.answerFor(q), wrong);
    expect(c.answeredCount, 1);
    expect(store.writes, writes);
    expect(c.lessonStatus(lesson), ProgressStatus.inProgress);
  });
}

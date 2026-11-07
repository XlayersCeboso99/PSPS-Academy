import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psps/data/catalog.dart';
import 'package:psps/data/progress_store.dart';
import 'package:psps/domain/learning_controller.dart';
import 'package:psps/ui/app.dart';

import 'app_test.dart' show tapVisible;
import 'support.dart';

void main() {
  final module = catalog.first;
  final topic = module.topics.first;
  final q = topic.lessons.first.questions.first;
  final wrong = (q.correctIndex + 1) % q.options.length;
  late MemoryStore store;
  late LearningController c;

  setUp(() async {
    store = MemoryStore();
    c = LearningController(modules: catalog, store: store);
    await c.load();
  });

  test(
    'TU07-01: only original mistakes in the requested scope appear',
    () async {
      final correct = topic.lessons.first.questions.last;
      final otherTopic = module.topics[1].lessons.first.questions.first;
      final otherModule = catalog[1].questions.first;
      for (final item in [q, otherTopic, otherModule]) {
        await c.answer(item, (item.correctIndex + 1) % item.options.length);
      }
      await c.answer(correct, correct.correctIndex);
      expect(c.pendingReview(topic.lessons.expand((l) => l.questions)), [q]);
      expect(c.pendingReview(module.questions), [q, otherTopic]);
      expect(c.pendingReview(catalog[1].questions), [otherModule]);
    },
  );

  test(
    'TU07-02/03/04: retry resolves only review; all progress is preserved',
    () async {
      await c.answer(q, wrong);
      final p = topic.practice;
      await c.saveOrder(p, List.generate(p.steps.length, (i) => i));
      final original = ProgressSnapshot.decode(store.raw!);
      final status = c.moduleStatus(module);
      final topicStatus = c.topicStatus(topic);
      final lessonStatus = c.lessonStatus(topic.lessons.first);
      final count = c.answeredCount;
      final progress = c.progress;
      final points = c.points;
      expect(await c.reviewAnswer(q, wrong), isTrue);
      expect(c.pendingReview(module.questions), contains(q));
      expect(await c.reviewAnswer(q, q.correctIndex), isTrue);
      expect(c.pendingReview(module.questions), isNot(contains(q)));
      final after = ProgressSnapshot.decode(store.raw!);
      expect(after.answers, original.answers);
      expect(after.practices, original.practices);
      expect(c.moduleStatus(module), status);
      expect(c.topicStatus(topic), topicStatus);
      expect(c.lessonStatus(topic.lessons.first), lessonStatus);
      expect(c.answeredCount, count);
      expect(c.progress, progress);
      expect(c.points, points);
      final writes = store.writes;
      expect(await c.reviewAnswer(q, wrong), isFalse);
      expect(store.writes, writes);
    },
  );

  test(
    'TI07-01: last review answer survives reload and subsequent normal writes',
    () async {
      await c.answer(q, wrong);
      await c.reviewAnswer(q, wrong);
      var restored = LearningController(modules: catalog, store: store);
      await restored.load();
      expect(restored.reviewAnswerFor(q), wrong);
      expect(restored.needsReview(q), isTrue);
      await restored.reviewAnswer(q, q.correctIndex);
      final next = module.questions.last;
      await restored.answer(next, next.correctIndex);
      await restored.saveOrder(topic.practice, [0]);
      restored = LearningController(modules: catalog, store: store);
      await restored.load();
      expect(restored.ready, isTrue);
      expect(restored.reviewAnswerFor(q), q.correctIndex);
      expect(restored.needsReview(q), isFalse);
      expect(restored.answerFor(q), wrong);
    },
  );

  test(
    'existing version 1 data migrates without resetting original progress',
    () async {
      store.raw = jsonEncode({
        'version': 1,
        'answers': {q.id: wrong},
        'practices': {
          topic.practice.id: [0],
        },
      });
      await c.load();
      expect(c.ready, isTrue);
      expect(c.needsReview(q), isTrue);
      expect(await c.reviewAnswer(q, q.correctIndex), isTrue);
      expect(jsonDecode(store.raw!)['version'], 3);
      expect(c.answerFor(q), wrong);
      expect(c.orderFor(topic.practice), [0]);
    },
  );

  test(
    'TI07-03: failed save keeps pending and original disk data; retry works',
    () async {
      await c.answer(q, wrong);
      final before = store.raw;
      store.failSave = true;
      expect(await c.reviewAnswer(q, q.correctIndex), isFalse);
      expect(c.needsReview(q), isTrue);
      expect(c.reviewAnswerFor(q), isNull);
      expect(store.raw, before);
      store.failSave = false;
      expect(await c.reviewAnswer(q, q.correctIndex), isTrue);
      expect(c.needsReview(q), isFalse);
    },
  );

  test(
    'invalid or unreadable review data is reported and never overwritten',
    () async {
      for (final raw in [
        ProgressSnapshot(
          answers: {q.id: wrong},
          reviewAnswers: {q.id: 999},
        ).encode(),
        ProgressSnapshot(reviewAnswers: {q.id: q.correctIndex}).encode(),
        ProgressSnapshot(
          answers: {q.id: wrong},
          reviewAnswers: {'unknown': 0},
        ).encode(),
        '{"version":2,"answers":{},"practices":{}}',
      ]) {
        store.raw = raw;
        await c.load();
        expect(c.ready, isFalse);
        expect(c.loadError, isNotNull);
        expect(await c.reviewAnswer(q, q.correctIndex), isFalse);
        expect(store.raw, raw);
        expect(store.writes, 0);
      }
      store.failLoad = true;
      await c.load();
      expect(c.loadError, isNotNull);
    },
  );

  test(
    'unanswered, correct original and invalid selections cannot be reviewed',
    () async {
      expect(await c.reviewAnswer(q, q.correctIndex), isFalse);
      await c.answer(q, q.correctIndex);
      expect(await c.reviewAnswer(q, wrong), isFalse);
      final other = module.questions.last;
      await c.answer(other, (other.correctIndex + 1) % other.options.length);
      expect(await c.reviewAnswer(other, -1), isFalse);
      expect(await c.reviewAnswer(other, other.options.length), isFalse);
      expect(c.reviewAnswerFor(other), isNull);
    },
  );

  testWidgets(
    'TW07-01/02: select, fail, retry and save correct with feedback',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await c.answer(q, wrong);
      await tester.pumpWidget(
        MaterialApp(
          home: ReviewListScreen(controller: c, module: module, topic: topic),
        ),
      );
      await tapVisible(tester, find.text(q.prompt));
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Comprobar respuesta'),
            )
            .onPressed,
        isNull,
      );
      await tapVisible(tester, find.text(q.options[wrong]));
      await tapVisible(tester, find.text('Comprobar respuesta'));
      expect(find.text('Sigue intentándolo'), findsOneWidget);
      expect(c.needsReview(q), isTrue);
      await tapVisible(tester, find.text('Volver a intentar'));
      await tapVisible(tester, find.text(q.options[q.correctIndex]));
      await tapVisible(tester, find.text('Comprobar respuesta'));
      expect(find.text('¡Pregunta resuelta en el repaso!'), findsOneWidget);
      await tapVisible(tester, find.text('Continuar repaso'));
      expect(find.text('No tienes preguntas pendientes'), findsOneWidget);
      expect(c.answerFor(q), wrong);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed storage never shows successful resolution and permits retry',
    (tester) async {
      await c.answer(q, wrong);
      store.failSave = true;
      await tester.pumpWidget(
        MaterialApp(
          home: ReviewQuestionScreen(controller: c, question: q),
        ),
      );
      await tapVisible(tester, find.text(q.options[q.correctIndex]));
      await tapVisible(tester, find.text('Comprobar respuesta'));
      expect(
        find.textContaining('No se pudo guardar el repaso.'),
        findsOneWidget,
      );
      expect(find.text('¡Pregunta resuelta en el repaso!'), findsNothing);
      store.failSave = false;
      await tapVisible(tester, find.text('Comprobar respuesta'));
      expect(find.text('¡Pregunta resuelta en el repaso!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('leaving with an unsubmitted option stores no review answer', (
    tester,
  ) async {
    await c.answer(q, wrong);
    final writes = store.writes;
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewListScreen(controller: c, module: module),
      ),
    );
    await tapVisible(tester, find.text(q.prompt));
    await tapVisible(tester, find.text(q.options[q.correctIndex]));
    await tapVisible(tester, find.text('Volver a la lista'));
    expect(c.reviewAnswerFor(q), isNull);
    expect(store.writes, writes);
    expect(find.text(q.prompt), findsOneWidget);
  });

  testWidgets('TW07-03: both entry points open contextual empty states', (
    tester,
  ) async {
    for (final screen in [
      ModuleScreen(controller: c, module: module),
      TopicScreen(controller: c, module: module, topic: topic),
    ]) {
      await tester.pumpWidget(MaterialApp(key: UniqueKey(), home: screen));
      await tapVisible(tester, find.text('Repasar preguntas (0)'));
      expect(find.text('No tienes preguntas pendientes'), findsOneWidget);
      expect(find.textContaining(module.title), findsOneWidget);
      expect(store.writes, 0);
    }
  });

  testWidgets('recovery error shows retry, never a misleading empty list', (
    tester,
  ) async {
    store.failLoad = true;
    await c.load();
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewListScreen(controller: c, module: module),
      ),
    );
    expect(find.text(c.loadError!), findsOneWidget);
    expect(find.text('No tienes preguntas pendientes'), findsNothing);
    store.failLoad = false;
    await tapVisible(tester, find.text('Volver a intentar'));
    expect(find.text('No tienes preguntas pendientes'), findsOneWidget);
  });
}

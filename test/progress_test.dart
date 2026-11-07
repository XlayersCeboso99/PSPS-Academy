import 'package:flutter_test/flutter_test.dart';
import 'package:psps/data/catalog.dart';
import 'package:psps/data/progress_store.dart';
import 'package:psps/domain/course.dart';
import 'package:psps/domain/learning_controller.dart';

import 'support.dart';

void main() {
  late MemoryStore store;
  late LearningController controller;
  setUp(() async {
    store = MemoryStore();
    controller = LearningController(modules: catalog, store: store);
    await controller.load();
  });

  test('CU01/CU03: wrong answers count; viewing is read-only; repeats do not count twice', () async {
    final lesson = catalog.first.topics.first.lessons.first;
    expect(controller.lessonStatus(lesson), ProgressStatus.notStarted);
    expect(controller.moduleStatus(catalog.first), ProgressStatus.notStarted);
    expect(store.writes, 0);
    final first = lesson.questions.first;
    final wrong = (first.correctIndex + 1) % first.options.length;
    await controller.answer(first, wrong);
    expect(controller.lessonStatus(lesson), ProgressStatus.inProgress);
    expect(controller.answeredCount, 1);
    await controller.answer(first, first.correctIndex);
    expect(controller.answerFor(first), wrong);
    expect(controller.answeredCount, 1);
    expect(store.writes, 1);
    await controller.answer(lesson.questions.last, 0);
    expect(controller.lessonStatus(lesson), ProgressStatus.completed);
    expect(
      controller.topicStatus(catalog.first.topics.first),
      ProgressStatus.completed,
    );
    expect(controller.moduleStatus(catalog.first), ProgressStatus.inProgress);
  });

  test(
    'CU04: module completion aggregates all topics, independent of practices',
    () async {
      final module = catalog.first;
      for (final q in module.questions) {
        await controller.answer(q, (q.correctIndex + 1) % q.options.length);
      }
      expect(controller.moduleStatus(module), ProgressStatus.completed);
      expect(controller.completedPractices, 0);
      expect(controller.points, 0);
      expect(controller.moduleStatus(catalog[1]), ProgressStatus.notStarted);
    },
  );

  test('CU02: incomplete and incorrect orders give no reward; automatic completion is idempotent', () async {
    final practice = catalog.first.topics.first.practice;
    await controller.saveOrder(practice, [0]);
    expect(controller.practiceCompleted(practice), false);
    await controller.saveOrder(practice, [2, 1, 0]);
    expect(controller.practiceCompleted(practice), false);
    expect(controller.points, 0);
    await controller.saveOrder(practice, [0, 1, 2]);
    expect(controller.practiceCompleted(practice), true);
    expect(controller.points, 10);
    await controller.saveOrder(practice, [0, 1, 2]);
    await controller.saveOrder(practice, []);
    expect(controller.points, 10);
    expect(controller.answeredCount, 0);
    expect(controller.moduleStatus(catalog.first), ProgressStatus.notStarted);
  });

  test(
    'RF08: restore answers, partial activities and rewards after reopening',
    () async {
      final q = catalog.first.questions.first;
      await controller.answer(q, 0);
      final p = catalog.first.topics.first.practice;
      final p2 = catalog.first.topics[1].practice;
      await controller.saveOrder(p, [0, 1, 2]);
      await controller.saveOrder(p2, [1]);
      final reopened = LearningController(modules: catalog, store: store);
      await reopened.load();
      expect(reopened.answerFor(q), 0);
      expect(reopened.answeredCount, 1);
      expect(reopened.points, 10);
      expect(reopened.orderFor(p2), [1]);
      expect(reopened.practiceCompleted(p), true);
    },
  );

  test(
    'RF08: save failure does not publish progress, retry recovers',
    () async {
      store.failSave = true;
      final q = catalog.first.questions.first;
      expect(await controller.answer(q, 0), false);
      expect(controller.answeredCount, 0);
      expect(controller.saveError, isNotNull);
      store.failSave = false;
      expect(await controller.answer(q, 0), true);
      expect(controller.answeredCount, 1);
    },
  );

  test('corrupt data are preserved and loading can be retried', () async {
    store.raw = '{invalid';
    await controller.load();
    expect(controller.loadError, isNotNull);
    expect(store.raw, '{invalid');
    store.raw = ProgressSnapshot().encode();
    await controller.load();
    expect(controller.loadError, isNull);
  });

  test('catalog has ten required topics and unique IDs', () {
    final topics = catalog.expand((m) => m.topics).toList();
    expect(topics.map((t) => t.id).toSet(), {
      for (var i = 1; i <= 10; i++) 'CT-${i.toString().padLeft(2, '0')}',
    });
    final ids = [
      ...controller.questions.map((q) => q.id),
      ...controller.lessons.map((l) => l.id),
      ...controller.practices.map((p) => p.id),
    ];
    expect(ids.toSet().length, ids.length);
    for (final q in controller.questions) {
      expect(q.correctIndex, inInclusiveRange(0, q.options.length - 1));
    }
  });
}

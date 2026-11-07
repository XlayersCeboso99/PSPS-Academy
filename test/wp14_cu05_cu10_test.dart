import 'package:flutter_test/flutter_test.dart';
import 'package:psps/data/catalog.dart';
import 'package:psps/data/progress_store.dart';
import 'package:psps/domain/course.dart';
import 'package:psps/domain/learning_controller.dart';

import 'support.dart';

List<int> ordered(Practice p) => List.generate(p.steps.length, (i) => i);

Future<(LearningController, MemoryStore)> subject({
  List<CourseModule>? modules,
}) async {
  final store = MemoryStore();
  final c = LearningController(modules: modules ?? catalog, store: store);
  await c.load();
  return (c, store);
}

CourseModule moduleWith(String id, List<Topic> topics) => CourseModule(
  id: id,
  title: id,
  area: 'Materia fixture',
  description: '',
  topics: topics,
);

void main() {
  test(
    'TG-S2-006: consulting and reviewing preserve a confirmed total of 20',
    () async {
      final (c, store) = await subject();
      for (final p in c.practices.take(2)) {
        await c.saveOrder(p, ordered(p));
      }
      final q = c.questions.first;
      await c.answer(q, (q.correctIndex + 1) % q.options.length);
      final achievements = Map<String, String?>.from(c.earnedAchievements);
      final answered = c.answeredCount;
      expect(c.points, 20);
      expect(await c.reviewAnswer(q, q.correctIndex), isTrue);
      expect(c.points, 20);
      expect(c.earnedAchievements, achievements);
      expect(c.answeredCount, answered);
      expect(ProgressSnapshot.decode(store.raw!).points, 20);
    },
  );
  test(
    'TG-S2-007: reopening restores 10 and the rewarded ID without duplication',
    () async {
      final (c, store) = await subject();
      final p = c.practices.first;
      await c.saveOrder(p, ordered(p));
      final before = store.raw;
      final writes = store.writes;
      final restored = LearningController(modules: catalog, store: store);
      await restored.load();
      expect(restored.ready, isTrue);
      expect(restored.points, 10);
      await restored.saveOrder(p, ordered(p));
      expect(restored.points, 10);
      expect(ProgressSnapshot.decode(store.raw!).rewardedPractices, [p.id]);
      expect(store.raw, before);
      expect(store.writes, writes);
    },
  );
  test('TU-S2-001: CT-01 to CT-10 appear once in the local catalog', () async {
    final (c, store) = await subject();
    expect(c.ready, isTrue);
    final ids = c.modules.expand((m) => m.topics).map((t) => t.id).toList();
    expect(ids.length, 10);
    expect(ids.toSet(), {
      for (var i = 1; i <= 10; i++) 'CT-${i.toString().padLeft(2, '0')}',
    });
    expect(store.writes, 0);
  });

  test(
    'TU-S2-002: independent module/topic/subtopic relationships are preserved',
    () async {
      final t1 = catalog.first.topics.first;
      final t2 = catalog.last.topics.first;
      final (c, _) = await subject(
        modules: [
          moduleWith('M1', [t1]),
          moduleWith('M2', [t2]),
        ],
      );
      expect(c.ready, isTrue);
      expect(c.modules[0].topics, [t1]);
      expect(c.modules[0].topics.single.lessons, t1.lessons);
      expect(
        c.modules[0].topics.single.lessons.map((l) => l.id),
        isNot(contains(t2.lessons.first.id)),
      );
      expect(c.modules[1].topics, [t2]);
    },
  );

  test(
    'TU-S2-003: catalog queries preserve three answers and 20 saved points',
    () async {
      final (c, store) = await subject();
      for (final q in c.questions.take(3)) {
        await c.answer(q, q.correctIndex);
      }
      for (final p in c.practices.take(2)) {
        await c.saveOrder(p, ordered(p));
      }
      final raw = store.raw;
      final writes = store.writes;
      for (final m in c.modules) {
        c.moduleStatus(m);
        for (final t in m.topics) {
          c.topicStatus(t);
        }
      }
      expect(c.answeredCount, 3);
      expect(c.points, 20);
      expect(store.raw, raw);
      expect(store.writes, writes);
    },
  );

  test(
    'TU-S2-004: later modules are accessible with no prior progress',
    () async {
      final (c, store) = await subject();
      expect(c.modules.last.topics, isNotEmpty);
      expect(c.moduleStatus(c.modules.last), ProgressStatus.notStarted);
      expect(c.answeredCount, 0);
      expect(store.writes, 0);
    },
  );

  test('TU-S2-005: ambiguous catalog relationships are reported without modifying saved data', () async {
    // The production model embeds children instead of storing parent foreign
    // keys. Reusing the same child IDs under two parents is its invalid analogue.
    final topic = catalog.first.topics.first;
    final (c, store) = await subject(
      modules: [
        moduleWith('M1', [topic]),
        moduleWith('M2', [topic]),
      ],
    );
    expect(c.ready, isFalse);
    expect(c.loadError, contains('Contenido no disponible'));
    expect(store.raw, isNull);
    expect(store.writes, 0);
  });

  test('TU-S2-030: absent local rewards return zero without a write', () async {
    final (c, store) = await subject();
    expect(c.points, 0);
    expect(store.raw, isNull);
    expect(store.writes, 0);
  });

  test(
    'TU-S2-031: two distinct confirmed activities produce a saved total of 20',
    () async {
      final (c, store) = await subject();
      for (final p in c.practices.take(2)) {
        await c.saveOrder(p, ordered(p));
      }
      expect(c.points, 20);
      expect(ProgressSnapshot.decode(store.raw!).points, 20);
    },
  );

  test(
    'TU-S2-032: repeated total queries do not change 30 saved points',
    () async {
      final (c, store) = await subject();
      for (final p in c.practices.take(3)) {
        await c.saveOrder(p, ordered(p));
      }
      final before = store.raw;
      final writes = store.writes;
      expect([c.points, c.points, c.points], [30, 30, 30]);
      expect(store.raw, before);
      expect(store.writes, writes);
    },
  );

  test('TU-S2-033: the points query returns a total without requiring history or dates', () async {
    final (c, store) = await subject();
    await c.saveOrder(c.practices.first, ordered(c.practices.first));
    final before = store.raw;
    final int total = c.points;
    expect(total, 10);
    expect(store.raw, before);
  });

  test(
    'TU-S2-034: reading failure remains distinguishable from a zero balance',
    () async {
      final (c, store) = await subject();
      await c.saveOrder(c.practices.first, ordered(c.practices.first));
      final before = store.raw;
      store.failLoad = true;
      await c.load();
      expect(c.ready, isFalse);
      expect(c.loadError, isNotNull);
      expect(store.raw, before);
      store.failLoad = false;
      await c.load();
      expect(c.ready, isTrue);
      expect(c.points, 10);
    },
  );
}

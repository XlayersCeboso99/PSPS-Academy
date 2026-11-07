import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psps/data/catalog.dart';
import 'package:psps/data/progress_store.dart';
import 'package:psps/domain/course.dart';
import 'package:psps/domain/learning_controller.dart';
import 'package:psps/ui/app.dart';

import 'support.dart';

List<int> completeOrder(Practice practice) =>
    List.generate(practice.steps.length, (i) => i);

Future<(LearningController, MemoryStore)> pointsFixture() async {
  final store = MemoryStore();
  final controller = LearningController(modules: catalog, store: store);
  await controller.load();
  expect(controller.ready, isTrue);
  return (controller, store);
}

Future<void> showPoints(
  WidgetTester tester,
  LearningController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(home: PointsScreen(controller: controller)),
  );
  await tester.pumpAndSettle();
}

Future<void> openPoints(WidgetTester tester) async {
  final link = find.text('Puntos');
  if (link.evaluate().isEmpty) {
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      link,
      150,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(link);
  await tester.tap(link);
  await tester.pumpAndSettle();
}

class DelayedStore extends MemoryStore {
  final entered = Completer<void>();
  final release = Completer<void>();

  @override
  Future<void> save(ProgressSnapshot state) async {
    entered.complete();
    await release.future;
    await super.save(state);
  }
}

void main() {
  test(
    'CP10-01: absent rewards mean zero without creating a saved value',
    () async {
      final (controller, store) = await pointsFixture();
      expect(controller.points, 0);
      expect(store.raw, isNull);
      expect(store.writes, 0);
    },
  );

  test('CP10-02: every eligible activity has a unique nonempty ID', () async {
    final (controller, _) = await pointsFixture();
    final practices = controller.practices.toList();
    expect(practices, isNotEmpty);
    expect(practices.every((practice) => practice.id.isNotEmpty), isTrue);
    expect(
      practices.map((practice) => practice.id).toSet().length,
      practices.length,
    );
  });

  test(
    'CP10-03: three total queries return 30 and preserve the entire snapshot',
    () async {
      final (controller, store) = await pointsFixture();
      for (final practice in controller.practices.take(3)) {
        expect(
          await controller.saveOrder(practice, completeOrder(practice)),
          isTrue,
        );
      }
      final before = store.raw;
      final writes = store.writes;
      final achievements = Map<String, String?>.from(
        controller.earnedAchievements,
      );
      expect(
        [controller.points, controller.points, controller.points],
        [30, 30, 30],
      );
      expect(controller.earnedAchievements, achievements);
      expect(store.raw, before);
      expect(store.writes, writes);
    },
  );

  test(
    'CP10-04: incomplete activity does not earn points or complete progress',
    () async {
      final (controller, store) = await pointsFixture();
      final practice = controller.practices.first;
      expect(practice.steps.length, greaterThan(1));
      await controller.saveOrder(practice, [0]);
      expect(controller.points, 0);
      expect(controller.practiceCompleted(practice), isFalse);
      expect(ProgressSnapshot.decode(store.raw!).rewardedPractices, isEmpty);
      expect(controller.answeredCount, 0);
    },
  );

  test(
    'CP10-05: one reward per saved ID; two distinct activities earn 20',
    () async {
      final (controller, store) = await pointsFixture();
      final practices = controller.practices.take(2).toList();
      await controller.saveOrder(
        practices.first,
        completeOrder(practices.first),
      );
      expect(controller.points, 10);
      final writes = store.writes;
      await controller.saveOrder(
        practices.first,
        completeOrder(practices.first),
      );
      expect(controller.points, 10);
      expect(store.writes, writes);
      await controller.saveOrder(practices.last, completeOrder(practices.last));
      final saved = ProgressSnapshot.decode(store.raw!);
      expect(saved.points, 20);
      expect(
        saved.rewardedPractices.toSet(),
        practices.map((p) => p.id).toSet(),
      );
      expect(controller.progress, 0);
    },
  );

  test(
    'CP10-06: failed save awards nothing; retry commits exactly once',
    () async {
      final (controller, store) = await pointsFixture();
      final practice = controller.practices.first;
      store.failSave = true;
      expect(
        await controller.saveOrder(practice, completeOrder(practice)),
        isFalse,
      );
      expect(controller.points, 0);
      expect(controller.completedPractices, 0);
      expect(store.raw, isNull);
      expect(controller.newAchievements, isEmpty);
      store.failSave = false;
      expect(
        await controller.saveOrder(practice, completeOrder(practice)),
        isTrue,
      );
      expect(controller.points, 10);
      await controller.saveOrder(practice, completeOrder(practice));
      expect(controller.points, 10);
      expect(store.writes, 1);
    },
  );

  test(
    'CP10-07: pending storage does not expose a reward or accept a duplicate',
    () async {
      final store = DelayedStore();
      final controller = LearningController(modules: catalog, store: store);
      await controller.load();
      final practice = controller.practices.first;
      final saving = controller.saveOrder(practice, completeOrder(practice));
      await store.entered.future;
      expect(controller.points, 0);
      expect(
        await controller.saveOrder(practice, completeOrder(practice)),
        isFalse,
      );
      store.release.complete();
      expect(await saving, isTrue);
      expect(controller.points, 10);
      expect(store.writes, 1);
    },
  );

  test(
    'CP10-08: questions, module completion and review give no G-01 points',
    () async {
      final (controller, _) = await pointsFixture();
      for (final question in controller.questions) {
        await controller.answer(
          question,
          (question.correctIndex + 1) % question.options.length,
        );
      }
      expect(controller.progress, 1);
      expect(controller.points, 0);
      final question = controller.questions.first;
      await controller.reviewAnswer(question, question.correctIndex);
      expect(controller.points, 0);
      expect(controller.completedPractices, 0);
    },
  );

  test(
    'CP10-09: v1/v2 recover historical points in memory without a write',
    () async {
      final (controller, store) = await pointsFixture();
      final practice = controller.practices.first;
      for (final version in [1, 2]) {
        store.raw = jsonEncode({
          'version': version,
          'answers': {},
          'practices': {practice.id: completeOrder(practice)},
          if (version == 2) 'reviewAnswers': {},
        });
        final before = store.raw;
        await controller.load();
        expect(controller.ready, isTrue);
        expect(controller.points, 10);
        expect(controller.earnedAchievements['L-03'], isNull);
        expect(store.raw, before);
        expect(store.writes, 0);
      }
    },
  );

  test(
    'CP10-10: inconsistent stored total is rejected and preserved',
    () async {
      final (controller, store) = await pointsFixture();
      store.raw = ProgressSnapshot(points: 10).encode();
      final before = store.raw;
      await controller.load();
      expect(controller.ready, isFalse);
      expect(controller.loadError, isNotNull);
      expect(store.raw, before);
      expect(store.writes, 0);
    },
  );

  testWidgets(
    'CP10-11: zero total is visible with G-01 and academic distinction',
    (tester) async {
      final (controller, store) = await pointsFixture();
      await showPoints(tester, controller);
      expect(find.text('0 pts'), findsOneWidget);
      expect(
        find.textContaining('guardada por primera vez otorga 10 puntos'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.textContaining('no una calificación académica'),
        120,
      );
      expect(
        find.textContaining('no una calificación académica'),
        findsOneWidget,
      );
      expect(store.writes, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'CP10-12: entering and leaving from Home and Progress preserves 20',
    (tester) async {
      final (controller, store) = await pointsFixture();
      for (final practice in controller.practices.take(2)) {
        await controller.saveOrder(practice, completeOrder(practice));
      }
      final before = store.raw;
      final writes = store.writes;
      await tester.pumpWidget(PspsApp(controller: controller));
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await openPoints(tester);
        expect(find.text('20 pts'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Mi progreso'));
      await tester.pumpAndSettle();
      await openPoints(tester);
      expect(find.text('20 pts'), findsOneWidget);
      expect(store.raw, before);
      expect(store.writes, writes);
    },
  );

  testWidgets('CP10-13: pending load is distinct from a zero balance', (
    tester,
  ) async {
    final store = MemoryStore();
    final controller = LearningController(modules: catalog, store: store);
    await showPoints(tester, controller);
    expect(find.text('Recuperando tus datos…'), findsOneWidget);
    expect(find.text('0 pts'), findsNothing);
    await controller.load();
    await tester.pumpAndSettle();
    expect(find.text('0 pts'), findsOneWidget);
    expect(store.writes, 0);
  });

  testWidgets('CP10-14: failed reading hides the total and retry restores 20', (
    tester,
  ) async {
    final (controller, store) = await pointsFixture();
    for (final practice in controller.practices.take(2)) {
      await controller.saveOrder(practice, completeOrder(practice));
    }
    final before = store.raw;
    final writes = store.writes;
    store.failLoad = true;
    await controller.load();
    await showPoints(tester, controller);
    expect(find.text(controller.loadError!), findsOneWidget);
    expect(find.byKey(const ValueKey('cu10.total')), findsNothing);
    expect(find.text('0 pts'), findsNothing);
    store.failLoad = false;
    await tester.tap(find.text('Reintentar carga'));
    await tester.pumpAndSettle();
    expect(find.text('20 pts'), findsOneWidget);
    expect(store.raw, before);
    expect(store.writes, writes);
  });

  testWidgets('CP10-15: visible total updates only after a successful save', (
    tester,
  ) async {
    final (controller, store) = await pointsFixture();
    final practice = controller.practices.first;
    await showPoints(tester, controller);
    store.failSave = true;
    await controller.saveOrder(practice, completeOrder(practice));
    await tester.pumpAndSettle();
    expect(find.text('0 pts'), findsOneWidget);
    store.failSave = false;
    await controller.saveOrder(practice, completeOrder(practice));
    await tester.pumpAndSettle();
    expect(find.text('10 pts'), findsOneWidget);
    expect(store.writes, 1);
  });

  testWidgets(
    'CP10-16: total has an accessible label and fits narrow enlarged text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      try {
        final (controller, _) = await pointsFixture();
        for (final practice in controller.practices) {
          await controller.saveOrder(practice, completeOrder(practice));
        }
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.6)),
              child: child!,
            ),
            home: PointsScreen(controller: controller),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('100 pts'), findsOneWidget);
        final node = tester.getSemantics(
          find.byKey(const ValueKey('cu10.total')),
        );
        expect(node.label, 'Total de puntos acumulados');
        expect(node.value, '100 puntos');
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psps/data/catalog.dart';
import 'package:psps/data/progress_store.dart';
import 'package:psps/domain/course.dart';
import 'package:psps/domain/learning_controller.dart';
import 'package:psps/ui/app.dart';

import 'support.dart';

Map<String, Object> visibleState(LearningController controller) => {
  'answers': {
    for (final question in controller.questions)
      question.id: controller.answerFor(question),
  },
  'activities': {
    for (final practice in controller.practices)
      practice.id: controller.orderFor(practice),
  },
  'review': {
    for (final question in controller.questions)
      question.id: controller.reviewAnswerFor(question),
  },
  'points': controller.points,
  'achievements': Map<String, String?>.from(controller.earnedAchievements),
  'theme': controller.selectedTheme,
  'states': {
    for (final module in controller.modules)
      module.id: controller.moduleStatus(module).name,
  },
};

Future<(LearningController, MemoryStore)> fixture({
  List<CourseModule>? modules,
  ProgressSnapshot? state,
}) async {
  final store = MemoryStore()..raw = state?.encode();
  final controller = LearningController(
    modules: modules ?? catalog,
    store: store,
  );
  await controller.load();
  expect(controller.ready, isTrue);
  return (controller, store);
}

Future<void> showApp(WidgetTester tester, LearningController controller) async {
  await tester.pumpWidget(PspsApp(controller: controller));
  await tester.pumpAndSettle();
}

Future<void> reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
  }
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await Scrollable.ensureVisible(tester.element(finder), alignment: .25);
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await reveal(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  test(
    'CP05-01: catalog contains CT-01 through CT-10 once in its hierarchy',
    () {
      final topicIds = catalog
          .expand((module) => module.topics)
          .map((t) => t.id);
      expect(topicIds.toSet(), {
        for (var i = 1; i <= 10; i++) 'CT-${i.toString().padLeft(2, '0')}',
      });
      expect(topicIds.length, 10);
      final modules = catalog.map((module) => module.id);
      expect(modules.toSet().length, modules.length);
      final lessons = catalog
          .expand((module) => module.topics)
          .expand((topic) => topic.lessons)
          .map((lesson) => lesson.id);
      expect(lessons.toSet().length, lessons.length);
      expect(catalog.every((module) => module.area.isNotEmpty), isTrue);
    },
  );

  test(
    'CP05-02: consulting the hierarchy preserves progress and rewards',
    () async {
      final question = catalog.first.questions.first;
      final practice = catalog.first.topics.first.practice;
      final (controller, store) = await fixture(
        state: ProgressSnapshot(
          answers: {
            question.id: (question.correctIndex + 1) % question.options.length,
          },
          practices: {
            practice.id: List.generate(practice.steps.length, (index) => index),
          },
        ),
      );
      final before = visibleState(controller);
      final raw = store.raw;
      for (final module in controller.modules) {
        controller.moduleStatus(module);
        for (final topic in module.topics) {
          controller.topicStatus(topic);
          for (final lesson in topic.lessons) {
            controller.lessonStatus(lesson);
          }
        }
      }
      expect(visibleState(controller), before);
      expect(store.raw, raw);
      expect(store.writes, 0);
    },
  );

  testWidgets('CP05-03: Home lists every module and its subject area', (
    tester,
  ) async {
    final (controller, store) = await fixture();
    await showApp(tester, controller);
    expect(find.text('4 módulos · 10 temas · A tu ritmo'), findsOneWidget);
    for (final module in catalog) {
      final card = find.byKey(ValueKey('cu05.module.${module.id}'));
      await reveal(tester, card);
      expect(
        find.descendant(of: card, matching: find.text(module.title)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text(module.area)),
        findsOneWidget,
      );
    }
    expect(store.writes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'CP05-04: the last module is accessible without completing the first',
    (tester) async {
      final (controller, store) = await fixture();
      await showApp(tester, controller);
      await tap(tester, find.byKey(ValueKey('cu05.module.${catalog.last.id}')));
      expect(find.text(catalog.last.title), findsOneWidget);
      expect(find.text('Recorrido del módulo'), findsOneWidget);
      expect(controller.moduleStatus(catalog.first), ProgressStatus.notStarted);
      expect(controller.answeredCount, 0);
      expect(controller.completedPractices, 0);
      expect(store.writes, 0);
    },
  );

  testWidgets('CP05-05: each module shows only its own topics and subtopics', (
    tester,
  ) async {
    final (controller, store) = await fixture();
    await showApp(tester, controller);
    for (final module in catalog) {
      await tap(tester, find.byKey(ValueKey('cu05.module.${module.id}')));
      for (final topic in module.topics) {
        await reveal(tester, find.text(topic.title));
        for (final lesson in topic.lessons) {
          await reveal(
            tester,
            find.byKey(ValueKey('cu05.lesson.${lesson.id}')),
          );
          expect(find.text(lesson.title), findsOneWidget);
        }
      }
      for (final other in catalog.where(
        (candidate) => candidate.id != module.id,
      )) {
        for (final topic in other.topics) {
          expect(find.text(topic.title), findsNothing);
        }
      }
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
    expect(controller.answeredCount, 0);
    expect(store.writes, 0);
  });

  testWidgets('CP05-06: opening a topic and its content does not complete it', (
    tester,
  ) async {
    final (controller, store) = await fixture();
    final module = catalog.first;
    final topic = module.topics.first;
    final lesson = topic.lessons.first;
    await showApp(tester, controller);
    await tap(tester, find.byKey(ValueKey('cu05.module.${module.id}')));
    await tap(tester, find.byKey(ValueKey('cu05.lesson.${lesson.id}')));
    expect(find.text('Explora el tema'), findsOneWidget);
    await tap(tester, find.byKey(ValueKey('cu05.study.${lesson.id}')));
    expect(find.byType(LessonScreen), findsOneWidget);
    expect(controller.lessonStatus(lesson), ProgressStatus.notStarted);
    expect(controller.answeredCount, 0);
    expect(controller.points, 0);
    expect(store.writes, 0);
  });

  testWidgets(
    'CP05-07: module badges distinguish all three states by text and icon',
    (tester) async {
      final (controller, store) = await fixture(
        state: ProgressSnapshot(
          answers: {
            for (final question in catalog.first.questions)
              question.id: question.correctIndex,
            catalog[1].questions.first.id:
                catalog[1].questions.first.correctIndex,
          },
        ),
      );
      await showApp(tester, controller);
      for (final (module, status, icon) in [
        (catalog[0], ProgressStatus.completed, Icons.check_circle_rounded),
        (catalog[1], ProgressStatus.inProgress, Icons.timelapse_rounded),
        (catalog[2], ProgressStatus.notStarted, Icons.circle_outlined),
      ]) {
        final card = find.byKey(ValueKey('cu05.module.${module.id}'));
        await reveal(tester, card);
        expect(
          find.descendant(of: card, matching: find.text(status.label)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: card, matching: find.byIcon(icon)),
          findsOneWidget,
        );
      }
      expect(store.writes, 0);
    },
  );

  testWidgets(
    'CP05-08: changing modules and reopening preserves the saved state',
    (tester) async {
      final question = catalog.first.questions.first;
      final practice = catalog.first.topics.first.practice;
      final (controller, store) = await fixture(
        state: ProgressSnapshot(
          answers: {
            question.id: (question.correctIndex + 1) % question.options.length,
          },
          practices: {
            practice.id: List.generate(practice.steps.length, (index) => index),
          },
        ),
      );
      final before = visibleState(controller);
      final raw = store.raw;
      await showApp(tester, controller);
      for (final module in [catalog.first, catalog.last, catalog[1]]) {
        await tap(tester, find.byKey(ValueKey('cu05.module.${module.id}')));
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
      await tester.pumpWidget(const SizedBox.shrink());
      final restored = LearningController(modules: catalog, store: store);
      await restored.load();
      await showApp(tester, restored);
      expect(visibleState(restored), before);
      expect(store.raw, raw);
      expect(store.writes, 0);
      expect(restored.newAchievements, isEmpty);
    },
  );

  testWidgets(
    'CP05-09: failed loading is reported and retry does not overwrite saved data',
    (tester) async {
      final store = MemoryStore()..failLoad = true;
      final controller = LearningController(modules: catalog, store: store);
      await controller.load();
      await showApp(tester, controller);
      expect(find.text(controller.loadError!), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(store.writes, 0);
      store.failLoad = false;
      await tap(tester, find.text('Reintentar'));
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(controller.answeredCount, 0);
      expect(store.writes, 0);
    },
  );

  testWidgets(
    'CP05-10: narrow screens and enlarged text allow free exploration',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final (controller, store) = await fixture();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.4)),
            child: child!,
          ),
          home: HomeScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(ValueKey('cu05.module.${catalog.last.id}')));
      expect(find.text(catalog.last.title), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(store.writes, 0);
    },
  );

  testWidgets(
    'CP05-11: the module list uses catalog counts and supports a fifth module',
    (tester) async {
      final extra = CourseModule(
        id: 'm5',
        title: 'Módulo de prueba',
        area: 'Área de prueba',
        description:
            'Fixture de prueba; no agrega contenido al catálogo del producto.',
        topics: const [],
      );
      final (controller, store) = await fixture(modules: [...catalog, extra]);
      await showApp(tester, controller);
      expect(find.text('5 módulos · 10 temas · A tu ritmo'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('cu05.module.m5')));
      expect(find.text(extra.title), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(store.writes, 0);
    },
  );

  testWidgets(
    'CP05-12: an empty catalog is reported without invented modules',
    (tester) async {
      final (controller, store) = await fixture(modules: []);
      await showApp(tester, controller);
      expect(find.text('0 módulos · 0 temas · A tu ritmo'), findsOneWidget);
      await reveal(tester, find.text('No hay módulos disponibles.'));
      expect(find.text('No hay módulos disponibles.'), findsOneWidget);
      expect(controller.answeredCount, 0);
      expect(store.writes, 0);
      expect(tester.takeException(), isNull);
    },
  );
}

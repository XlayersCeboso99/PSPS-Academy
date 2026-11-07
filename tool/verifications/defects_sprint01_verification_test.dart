import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psps/data/catalog.dart';
import 'package:psps/domain/course.dart';
import 'package:psps/domain/learning_controller.dart';
import 'package:psps/ui/app.dart';

import '../../test/support.dart';

// Reproduction criteria come from PSPS_CorreccionDefectos_H01_TSP_Ago26.pdf.
// D-S1 IDs are provisional; no claim is made that they identify MR-07's originals.
void main() {
  testWidgets(
    'VER-H-01: answered questions offer the documented repeat action',
    (tester) async {
      tester.view.physicalSize = const Size(600, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = LearningController(modules: catalog, store: MemoryStore());
      await c.load();
      final m = catalog.first, t = m.topics.first, original = t.lessons.first;
      final q = original.questions.first;
      final l = Lesson(
        id: original.id,
        title: original.title,
        content: original.content,
        example: original.example,
        questions: [q],
      );
      await c.answer(q, (q.correctIndex + 1) % q.options.length);
      await tester.pumpWidget(
        MaterialApp(
          home: QuestionsScreen(controller: c, module: m, topic: t, lesson: l),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Responder de nuevo'), findsOneWidget);
      await tester.tap(find.text('Responder de nuevo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(q.options[q.correctIndex]));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Comprobar de nuevo'));
      await tester.pumpAndSettle();
      expect(find.text('¡Respuesta correcta!'), findsOneWidget);
      expect(c.answeredCount, 1);
      expect(c.answerFor(q), (q.correctIndex + 1) % q.options.length);
    },
  );

  test(
    'VER-D-S1-01: duplicate catalog IDs are rejected before content is exposed',
    () async {
      final c = LearningController(
        modules: [catalog.first, catalog.first],
        store: MemoryStore(),
      );
      await c.load();
      expect(c.ready, isFalse);
      expect(c.loadError, contains('Contenido no disponible'));
    },
  );

  testWidgets(
    'VER-D-S1-02: activity presentation is not the canonical or reversed order',
    (tester) async {
      tester.view.physicalSize = const Size(600, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = LearningController(modules: catalog, store: MemoryStore());
      await c.load();
      final topic = catalog.first.topics.first;
      await tester.pumpWidget(
        MaterialApp(
          home: PracticeScreen(controller: c, topic: topic),
        ),
      );
      await tester.pumpAndSettle();
      final displayed = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(OutlinedButton),
              matching: find.byType(Text),
            ),
          )
          .map((text) => text.data)
          .whereType<String>()
          .where(topic.practice.steps.contains)
          .toList();
      expect(displayed.length, topic.practice.steps.length);
      expect(displayed, isNot(topic.practice.steps));
      expect(displayed, isNot(topic.practice.steps.reversed.toList()));
    },
  );

  testWidgets(
    'VER-D-S1-03: progress list uses a clock for a partially answered topic',
    (tester) async {
      final c = LearningController(modules: catalog, store: MemoryStore());
      await c.load();
      final topic = catalog.first.topics.first;
      await c.answer(topic.lessons.first.questions.first, 0);
      await tester.pumpWidget(PspsApp(controller: c));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mi progreso'));
      await tester.pumpAndSettle();
      final tile = find.ancestor(
        of: find.text(topic.title),
        matching: find.byType(ListTile),
      );
      if (tile.evaluate().isEmpty) {
        await tester.scrollUntilVisible(find.text(topic.title), 140);
      }
      expect(
        find.descendant(
          of: tile,
          matching: find.byIcon(Icons.timelapse_rounded),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'VER-D-S1-04: the fifth module does not overflow the icon array',
    (tester) async {
      final fifth = CourseModule(
        id: 'm5',
        title: 'Quinto fixture',
        area: 'Área fixture',
        description: '',
        topics: const [],
      );
      final c = LearningController(
        modules: [...catalog, fifth],
        store: MemoryStore(),
      );
      await c.load();
      await tester.pumpWidget(PspsApp(controller: c));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('cu05.module.m5')),
        160,
      );
      expect(find.text('Quinto fixture'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

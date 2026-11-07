import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psps/data/catalog.dart';
import 'package:psps/domain/course.dart';
import 'package:psps/domain/learning_controller.dart';
import 'package:psps/ui/app.dart';

import 'support.dart';

// D-S1-03 · RNF-05 · CA-04 ampliado: en «Mi progreso», «En progreso» usaba el
// mismo ícono que «Sin iniciar».

Future<void> reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await Scrollable.ensureVisible(tester.element(finder), alignment: .3);
  await tester.pumpAndSettle();
}

void main() {
  test('DS103-01: each state has its own icon', () {
    final icons = ProgressStatus.values.map(statusIcon).toSet();
    expect(icons.length, ProgressStatus.values.length);
  });

  testWidgets('DS103-02: badges use the same icon as the lists', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              for (final s in ProgressStatus.values) StatusBadge(s),
            ],
          ),
        ),
      ),
    );
    for (final s in ProgressStatus.values) {
      expect(
        find.descendant(
          of: find.widgetWithText(StatusBadge, s.label),
          matching: find.byIcon(statusIcon(s)),
        ),
        findsOneWidget,
        reason: s.name,
      );
    }
  });

  testWidgets(
    'DS103-03: «Mi progreso» shows circle, clock and check for the three states',
    (tester) async {
      final c = LearningController(modules: catalog, store: MemoryStore());
      await c.load();
      final topics = catalog.first.topics;
      // CT-01 en progreso: una de sus preguntas.
      await c.answer(topics[0].lessons.first.questions.first, 0);
      // Tercer tema completado: todas sus preguntas.
      for (final q in topics[2].lessons.expand((l) => l.questions)) {
        await c.answer(q, 0);
      }
      final expected = {
        topics[0].id: ProgressStatus.inProgress,
        topics[1].id: ProgressStatus.notStarted,
        topics[2].id: ProgressStatus.completed,
      };
      for (final entry in expected.entries) {
        expect(
          c.topicStatus(topics.firstWhere((t) => t.id == entry.key)),
          entry.value,
        );
      }
      await tester.pumpWidget(PspsApp(controller: c));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mi progreso'));
      await tester.pumpAndSettle();
      for (final entry in expected.entries) {
        final tile = find.byKey(ValueKey('ds103.topic.${entry.key}'));
        await reveal(tester, tile);
        expect(
          find.descendant(of: tile, matching: find.byIcon(statusIcon(entry.value))),
          findsOneWidget,
          reason: entry.key,
        );
        expect(
          find.descendant(of: tile, matching: find.text(entry.value.label)),
          findsOneWidget,
          reason: entry.key,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );
}

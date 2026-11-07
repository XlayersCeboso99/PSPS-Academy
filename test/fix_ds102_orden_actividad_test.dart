import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psps/data/catalog.dart';
import 'package:psps/domain/course.dart';
import 'package:psps/domain/learning_controller.dart';
import 'package:psps/ui/app.dart';

import 'support.dart';

// D-S1-02 · CA-03: los elementos de la actividad ya no aparecen siempre en
// orden inverso (se resolvía tocando de abajo hacia arriba).

Practice practiceOf(int n, [String id = 'P-01']) => Practice(
  id: id,
  title: 'Actividad',
  instruction: 'Ordena',
  steps: [for (var i = 0; i < n; i++) 'Paso $i'],
);

void main() {
  test(
    'DS102-01: every catalog activity is shuffled, never correct nor reversed, and stable',
    () {
      final practices = catalog.expand((m) => m.topics).map((t) => t.practice);
      for (final p in practices.where((p) => p.steps.isNotEmpty)) {
        final n = p.steps.length;
        final order = p.presentationOrder;
        final identity = List<int>.generate(n, (i) => i);
        expect(order.length, n, reason: p.id);
        expect(order.toSet(), identity.toSet(), reason: p.id);
        expect(order, isNot(identity), reason: p.id);
        if (n >= 3) {
          expect(order, isNot(identity.reversed.toList()), reason: p.id);
        }
        expect(p.presentationOrder, order, reason: 'same order on reopen');
      }
    },
  );

  test('DS102-02: small activities and many identifiers', () {
    expect(practiceOf(0).presentationOrder, isEmpty);
    expect(practiceOf(1).presentationOrder, [0]);
    expect(practiceOf(2).presentationOrder, [1, 0]);
    for (var k = 0; k < 200; k++) {
      for (final n in [3, 4, 5, 7]) {
        final order = practiceOf(n, 'X-$k').presentationOrder;
        final identity = List<int>.generate(n, (i) => i);
        expect(order.toSet(), identity.toSet());
        expect(order, isNot(identity));
        expect(order, isNot(identity.reversed.toList()));
      }
    }
  });

  testWidgets(
    'DS102-03: the screen lists the available elements in presentation order',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = LearningController(modules: catalog, store: MemoryStore());
      await c.load();
      final topic = catalog.first.topics.first;
      final p = topic.practice;
      await tester.pumpWidget(
        MaterialApp(home: PracticeScreen(controller: c, topic: topic)),
      );
      await tester.pumpAndSettle();
      final shown = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(OutlinedButton),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data)
          .toList();
      expect(shown, [for (final i in p.presentationOrder) p.steps[i]]);
      expect(shown, isNot(p.steps));
      expect(shown, isNot(p.steps.reversed.toList()));
    },
  );

  testWidgets('DS102-04: choosing the correct order still completes the activity', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = LearningController(modules: catalog, store: MemoryStore());
    await c.load();
    final topic = catalog.first.topics.first;
    await tester.pumpWidget(
      MaterialApp(home: PracticeScreen(controller: c, topic: topic)),
    );
    await tester.pumpAndSettle();
    for (final step in topic.practice.steps) {
      await tester.tap(find.widgetWithText(OutlinedButton, step));
      await tester.pumpAndSettle();
    }
    expect(c.practiceCompleted(topic.practice), isTrue);
    expect(find.text('¡Actividad realizada!'), findsOneWidget);
  });
}

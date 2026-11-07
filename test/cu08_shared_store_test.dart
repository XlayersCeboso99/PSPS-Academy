import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psps/data/catalog.dart';
import 'package:psps/data/activity_store.dart';
import 'package:psps/domain/learning_controller.dart';
import 'package:psps/features/cu08/activity_models.dart';
import 'package:psps/ui/app.dart';

import 'support.dart';

void main() {
  test(
    'CU08 shared store preserves answers review theme and existing rewards',
    () async {
      final memory = MemoryStore();
      final c = LearningController(modules: catalog, store: memory);
      await c.load();
      final q = c.questions.first;
      await c.answer(q, (q.correctIndex + 1) % q.options.length);
      await c.reviewAnswer(q, q.correctIndex);
      final p = c.practices.first;
      final adapter = LearningActivityStore(c);
      final before = await adapter.load();
      final writes = memory.writes;
      await adapter.load();
      expect(memory.writes, writes);
      await adapter.save(before.copyWith(completedActivityIds: {p.id}));
      expect(c.points, 10);
      expect(c.answerFor(q), (q.correctIndex + 1) % q.options.length);
      expect(c.reviewAnswerFor(q), q.correctIndex);
      await c.selectTheme('U-01');
      final rewards = Map<String, String?>.from(c.earnedAchievements);
      await adapter.save(await adapter.load());
      expect(c.earnedAchievements, rewards);
      expect(c.selectedTheme, 'U-01');
      final restored = LearningController(modules: catalog, store: memory);
      await restored.load();
      expect(restored.points, 10);
      expect(restored.selectedTheme, 'U-01');
      expect(restored.reviewAnswerFor(q), q.correctIndex);
    },
  );

  test(
    'CU08 shared save failure propagates without confirmed completion',
    () async {
      final memory = MemoryStore();
      final c = LearningController(modules: catalog, store: memory);
      await c.load();
      memory.failSave = true;
      final adapter = LearningActivityStore(c);
      await expectLater(
        adapter.save(
          ActivityState(completedActivityIds: {c.practices.first.id}),
        ),
        throwsStateError,
      );
      expect(c.completedPractices, 0);
      expect(c.points, 0);
    },
  );

  testWidgets(
    'CU08 real route delegates to CU02 then refreshes shared completion',
    (tester) async {
      final memory = MemoryStore();
      final c = LearningController(modules: catalog, store: memory);
      await c.load();
      final p = c.practices.first;
      await tester.pumpWidget(
        MaterialApp(home: ActivitiesScreen(controller: c)),
      );
      await tester.pumpAndSettle();
      final finder = find.text(p.title);
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();
      expect(find.byType(PracticeScreen), findsOneWidget);
      await c.saveOrder(p, List.generate(p.steps.length, (i) => i));
      final context = tester.element(find.byType(PracticeScreen));
      Navigator.of(context).pop();
      await tester.pumpAndSettle();
      expect(find.text('Realizada'), findsOneWidget);
      expect(c.points, 10);
      expect(tester.takeException(), isNull);
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psps/data/catalog.dart';
import 'package:psps/domain/course.dart';
import 'package:psps/domain/learning_controller.dart';
import 'package:psps/ui/app.dart';

import 'support.dart';

void main() {
  testWidgets('TU-02: correct answer displays feedback and records progress', (
    tester,
  ) async {
    final c = LearningController(modules: catalog, store: MemoryStore());
    await c.load();
    final lesson = catalog.first.topics.first.lessons.first;
    await tester.pumpWidget(
      MaterialApp(
        home: LessonScreen(
          controller: c,
          module: catalog.first,
          topic: catalog.first.topics.first,
          lesson: lesson,
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> tap(String label) async {
      final f = find.text(label);
      await tester.scrollUntilVisible(
        f,
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(f);
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    await tap('Siguiente');
    await tap('Ir a preguntas');
    final q = lesson.questions.first;
    await tap(q.options[q.correctIndex]);
    await tap('Comprobar');
    expect(c.answerFor(q), q.correctIndex);
    expect(c.answeredCount, 1);
    expect(find.text('¡Respuesta correcta!'), findsOneWidget);
    expect(find.text(q.explanation), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'TU-08: all progress badges display text icon and distinct color',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatusBadge(ProgressStatus.notStarted),
                StatusBadge(ProgressStatus.inProgress),
                StatusBadge(ProgressStatus.completed),
              ],
            ),
          ),
        ),
      );
      for (final state in ProgressStatus.values) {
        expect(find.text(state.label), findsOneWidget);
      }
      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      expect(icons.length, 3);
      expect(icons.map((i) => i.color).toSet().length, 3);
      expect(icons.map((i) => i.icon).toSet().length, 3);
      expect(tester.takeException(), isNull);
    },
  );
}

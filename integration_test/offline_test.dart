import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:psps/data/catalog.dart';
import 'package:psps/data/progress_store.dart';
import 'package:psps/domain/learning_controller.dart';
import 'package:psps/domain/course.dart';
import 'package:psps/ui/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('RF08: real device storage survives controller recreation', (
    tester,
  ) async {
    const testKey = 'psps.integration.sprint1';
    final preferences = SharedPreferencesAsync();
    await preferences.remove(testKey);
    addTearDown(() => preferences.remove(testKey));
    final store = LocalProgressStore(preferences: preferences, key: testKey);
    final first = LearningController(modules: catalog, store: store);
    await first.load();
    for (final q in catalog.first.questions) {
      await first.answer(q, (q.correctIndex + 1) % q.options.length);
    }
    await first.saveOrder(catalog.first.topics.first.practice, [0, 1, 2]);
    final reviewed = catalog.first.questions.first;
    expect(await first.reviewAnswer(reviewed, reviewed.correctIndex), isTrue);
    await tester.pumpWidget(PspsApp(controller: first));
    await tester.pumpAndSettle();
    expect(first.moduleStatus(catalog.first), ProgressStatus.completed);
    await tester.pumpWidget(const SizedBox.shrink());
    first.dispose();
    final restored = LearningController(
      modules: catalog,
      store: LocalProgressStore(
        preferences: SharedPreferencesAsync(),
        key: testKey,
      ),
    );
    await restored.load();
    await tester.pumpWidget(PspsApp(controller: restored));
    await tester.pumpAndSettle();
    expect(restored.moduleStatus(catalog.first), ProgressStatus.completed);
    expect(restored.answeredCount, catalog.first.questions.length);
    expect(restored.points, 10);
    expect(restored.reviewAnswerFor(reviewed), reviewed.correctIndex);
    expect(restored.needsReview(reviewed), isFalse);
    expect(
      restored.answerFor(reviewed),
      (reviewed.correctIndex + 1) % reviewed.options.length,
    );
    expect(find.text('PSPS Academy'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Exercise CU-07 on the device using the isolated integration storage key.
    final pendingQuestion = catalog.first.questions.last;
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewListScreen(controller: restored, module: catalog.first),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> tap(String label) async {
      final finder = find.text(label);
      if (finder.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          finder,
          160,
          scrollable: find.byType(Scrollable).first,
        );
      }
      await Scrollable.ensureVisible(tester.element(finder), alignment: .35);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    await tap(pendingQuestion.prompt);
    await tap(
      pendingQuestion.options[(pendingQuestion.correctIndex + 1) %
          pendingQuestion.options.length],
    );
    await tap('Comprobar respuesta');
    expect(find.text('Sigue intentándolo'), findsOneWidget);
    await tap('Volver a intentar');
    await tap(pendingQuestion.options[pendingQuestion.correctIndex]);
    await tap('Comprobar respuesta');
    expect(find.text('¡Pregunta resuelta en el repaso!'), findsOneWidget);
    final afterReview = LearningController(
      modules: catalog,
      store: LocalProgressStore(key: testKey),
    );
    await afterReview.load();
    expect(afterReview.ready, isTrue);
    expect(afterReview.needsReview(pendingQuestion), isFalse);
    expect(
      afterReview.reviewAnswerFor(pendingQuestion),
      pendingQuestion.correctIndex,
    );
    expect(
      afterReview.answerFor(pendingQuestion),
      (pendingQuestion.correctIndex + 1) % pendingQuestion.options.length,
    );
    expect(afterReview.answeredCount, restored.answeredCount);
    expect(afterReview.points, restored.points);
    expect(
      afterReview.moduleStatus(catalog.first),
      restored.moduleStatus(catalog.first),
    );
    expect(tester.takeException(), isNull);
  });
}

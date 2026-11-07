import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:psps/data/catalog.dart';
import 'package:psps/data/progress_store.dart';
import 'package:psps/domain/learning_controller.dart';
import 'package:psps/ui/app.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'TI-07-02: review in airplane mode preserves native progress and rewards',
    (tester) async {
      const key = 'psps.integration.cu07.offline';
      final prefs = SharedPreferencesAsync();
      await prefs.remove(key);
      addTearDown(() => prefs.remove(key));
      final module = catalog.first;
      final q = module.questions.first;
      final p = module.topics.first.practice;
      final wrong = (q.correctIndex + 1) % q.options.length;
      final store = LocalProgressStore(key: key);
      await store.save(
        ProgressSnapshot(
          answers: {q.id: wrong},
          practices: {p.id: List.generate(p.steps.length, (i) => i)},
        ),
      );
      final c = LearningController(modules: catalog, store: store);
      await c.load();
      expect(c.ready, isTrue);
      final before = await store.load();
      final points = c.points;
      final achievements = Map<String, String?>.from(c.earnedAchievements);
      final status = c.moduleStatus(module);
      await tester.pumpWidget(PspsApp(controller: c));
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
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

      await tap(module.title);
      await tap('Repasar preguntas (1)');
      await binding.takeScreenshot('CU07-AV01-pendientes');
      await tap(q.prompt);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Comprobar respuesta'),
            )
            .onPressed,
        isNull,
      );
      await tap(q.options[wrong]);
      await tap('Comprobar respuesta');
      expect(c.needsReview(q), isTrue);
      await binding.takeScreenshot('CU07-AV02-error');
      await tap('Volver a intentar');
      await tap(q.options[q.correctIndex]);
      await tap('Comprobar respuesta');
      expect(find.text('¡Pregunta resuelta en el repaso!'), findsOneWidget);
      await binding.takeScreenshot('CU07-AV03-acierto-guardado');
      await tap('Continuar repaso');
      expect(find.text('No tienes preguntas pendientes'), findsOneWidget);
      await binding.takeScreenshot('CU07-AV04-sin-pendientes');

      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose();
      final restored = LearningController(
        modules: catalog,
        store: LocalProgressStore(
          preferences: SharedPreferencesAsync(),
          key: key,
        ),
      );
      await restored.load();
      final after = await restored.store.load();
      expect(restored.ready, isTrue);
      expect(restored.needsReview(q), isFalse);
      expect(restored.reviewAnswerFor(q), q.correctIndex);
      expect(after.answers, before.answers);
      expect(after.practices, before.practices);
      expect(restored.points, points);
      expect(restored.earnedAchievements, achievements);
      expect(restored.moduleStatus(module), status);
      expect(restored.newAchievements, isEmpty);
      await tester.pumpWidget(PspsApp(key: UniqueKey(), controller: restored));
      await tester.pumpAndSettle();
      await tap(module.title);
      await tap('Repasar preguntas (0)');
      expect(find.text('No tienes preguntas pendientes'), findsOneWidget);
      await binding.takeScreenshot('CU07-AV05-estado-recuperado');
      expect(tester.takeException(), isNull);
    },
  );
}

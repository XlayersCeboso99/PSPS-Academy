import 'dart:convert';
import 'dart:io';

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
    'Sprint 2: design, local search, rewards, review and theme persistence',
    (tester) async {
      const key = 'psps.integration.sprint2.design';
      final prefs = SharedPreferencesAsync();
      await prefs.remove(key);
      addTearDown(() => prefs.remove(key));
      final q = catalog.first.questions.first;
      final p = catalog.first.topics.first.practice;
      // Migration fixture belongs only to this test, never to the student's key.
      await prefs.setString(
        key,
        jsonEncode({
          'version': 2,
          'answers': {q.id: (q.correctIndex + 1) % q.options.length},
          'practices': {p.id: List.generate(p.steps.length, (i) => i)},
          'reviewAnswers': {},
        }),
      );
      final c = LearningController(
        modules: catalog,
        store: LocalProgressStore(key: key),
      );
      await c.load();
      expect(c.ready, isTrue);
      expect(c.points, 10);
      expect(c.earnedAchievements, {'L-01': null, 'L-03': null});
      await tester.pumpWidget(PspsApp(controller: c));
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();

      Future<void> tap(Finder finder) async {
        if (finder.evaluate().isEmpty) {
          await tester.scrollUntilVisible(
            finder,
            180,
            scrollable: find.byType(Scrollable).first,
          );
        }
        await Scrollable.ensureVisible(tester.element(finder), alignment: .35);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      Future<void> shot(String name) async {
        await tester.pumpAndSettle();
        final bytes = await binding.takeScreenshot(name);
        await File('${Directory.systemTemp.path}/$name.png')
            .writeAsBytes(bytes);
      }

      Future<void> back() async {
        await tester.pageBack();
        await tester.pumpAndSettle();
      }

      Future<void> typeQuery(String text) async {
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), text);
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          text,
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
      }

      await shot('S2-01-inicio');
      await tap(find.text('Actividades'));
      expect(find.text('Realizada'), findsOneWidget);
      await shot('S2-02-actividades');
      final pendingPractice = c.practices.skip(1).first;
      await tap(find.text(pendingPractice.title));
      for (final step in pendingPractice.steps) {
        await tap(find.text(step));
      }
      expect(c.practiceCompleted(pendingPractice), isTrue);
      expect(c.points, 20);
      await back();
      expect(find.text('Realizada'), findsNWidgets(2));
      await shot('S2-15-cu08-regreso-realizada');
      await back();
      await tap(find.text('Puntos'));
      expect(find.text('20 pts'), findsOneWidget);
      await shot('S2-03-puntos');
      await back();
      await tap(find.text('Logros'));
      expect(find.text('Primer paso'), findsOneWidget);
      await shot('S2-04-logros');
      await tap(find.text('Usar Océano'));
      expect(c.selectedTheme, 'U-01');
      await shot('S2-05-temas');
      await back();

      await tap(find.byTooltip('Buscar contenidos'));
      await typeQuery('clase');
      expect(find.text('Del modelo a la instancia'), findsOneWidget);
      await shot('S2-06-busqueda');
      final count = c.answeredCount;
      await tap(find.text('Del modelo a la instancia'));
      expect(c.answeredCount, count);
      await shot('S2-07-contenido');
      await back();
      await typeQuery('compiladores');
      await shot('S2-08-sin-resultados');
      await tap(find.text('Explorar módulos'));

      await tap(find.text(catalog.first.title));
      await tap(find.text('Repasar preguntas (1)'));
      await shot('S2-09-pendientes');
      await tap(find.text(q.prompt));
      await tap(find.text(q.options[(q.correctIndex + 1) % q.options.length]));
      await tap(find.text('Comprobar respuesta'));
      await shot('S2-10-repaso-error');
      await tap(find.text('Volver a intentar'));
      await tap(find.text(q.options[q.correctIndex]));
      await tap(find.text('Comprobar respuesta'));
      await shot('S2-11-repaso-acierto');
      await tap(find.text('Continuar repaso'));
      expect(find.text('No tienes preguntas pendientes'), findsOneWidget);
      await shot('S2-12-sin-pendientes');
      expect(c.points, 20);
      expect(c.earnedAchievements.length, 2);
      expect(c.answeredCount, count);

      // Complete the fixture to verify the final theme; no extra student data.
      for (final question in c.questions) {
        await c.answer(question, 0);
      }
      expect(c.unlockedThemes, contains('U-03'));
      await c.selectTheme('U-03');
      final restored = LearningController(
        modules: catalog,
        store: LocalProgressStore(key: key),
      );
      await restored.load();
      expect(restored.ready, isTrue);
      expect(restored.selectedTheme, 'U-03');
      expect(restored.points, 20);
      expect(restored.needsReview(q), isFalse);
      expect(restored.earnedAchievements, c.earnedAchievements);
      await tester.pumpWidget(PspsApp(key: UniqueKey(), controller: restored));
      await tester.pumpAndSettle();
      await shot('S2-13-noche');
      await tap(find.text('Logros'));
      await shot('S2-14-logros-noche');
      expect(tester.takeException(), isNull);
    },
  );
}

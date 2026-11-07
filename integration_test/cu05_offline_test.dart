import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:psps/data/catalog.dart';
import 'package:psps/data/progress_store.dart';
import 'package:psps/domain/learning_controller.dart';
import 'package:psps/ui/app.dart';

// Execute through tool/verify_sprint2_android.ps1 in an isolated test package.
// The runner must verify airplane mode and the absence of an active network.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('TI05-01: explore freely without changing native saved state', (
    tester,
  ) async {
    const key = 'psps.integration.cu05.offline';
    final preferences = SharedPreferencesAsync();
    await preferences.remove(key);
    addTearDown(() => preferences.remove(key));
    final first = catalog.first;
    final question = first.questions.first;
    final practice = first.topics.first.practice;
    final store = LocalProgressStore(key: key);
    await store.save(
      ProgressSnapshot(
        answers: {
          question.id: (question.correctIndex + 1) % question.options.length,
          for (final question in catalog[1].questions)
            question.id: question.correctIndex,
        },
        practices: {
          practice.id: List.generate(practice.steps.length, (index) => index),
        },
      ),
    );
    final rawBefore = await preferences.getString(key);
    final controller = LearningController(modules: catalog, store: store);
    await controller.load();
    expect(controller.ready, isTrue);
    final points = controller.points;
    final achievements = Map<String, String?>.from(
      controller.earnedAchievements,
    );
    final states = {
      for (final module in catalog) module.id: controller.moduleStatus(module),
    };
    await tester.pumpWidget(PspsApp(controller: controller));
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();

    Future<void> reveal(Finder finder) async {
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

    Future<void> tap(Finder finder) async {
      await reveal(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    Future<void> back() async {
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    Future<void> unchanged() async {
      expect(await preferences.getString(key), rawBefore);
      expect(controller.points, points);
      expect(controller.earnedAchievements, achievements);
      expect({
        for (final module in catalog)
          module.id: controller.moduleStatus(module),
      }, states);
      expect(controller.newAchievements, isEmpty);
    }

    await reveal(find.byKey(ValueKey('cu05.module.${first.id}')));
    await binding.takeScreenshot('CU05-AV01-modulos');
    await tap(find.byKey(ValueKey('cu05.module.${catalog.last.id}')));
    expect(find.text(catalog.last.title), findsOneWidget);
    await binding.takeScreenshot('CU05-AV02-acceso-libre');
    await unchanged();
    await back();
    await tap(find.byKey(ValueKey('cu05.module.${first.id}')));
    final lesson = first.topics.first.lessons.first;
    await reveal(find.byKey(ValueKey('cu05.lesson.${lesson.id}')));
    await binding.takeScreenshot('CU05-AV03-estructura');
    await tap(find.byKey(ValueKey('cu05.lesson.${lesson.id}')));
    expect(find.text('Explora el tema'), findsOneWidget);
    await binding.takeScreenshot('CU05-AV04-tema');
    await tap(find.byKey(ValueKey('cu05.study.${lesson.id}')));
    expect(find.byType(LessonScreen), findsOneWidget);
    await binding.takeScreenshot('CU05-AV05-contenido-sin-avance');
    await unchanged();
    await back();
    await back();
    await back();
    await tap(find.byKey(ValueKey('cu05.module.${catalog[1].id}')));
    await unchanged();

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    final restored = LearningController(
      modules: catalog,
      store: LocalProgressStore(key: key),
    );
    await restored.load();
    expect(restored.ready, isTrue);
    expect(restored.points, points);
    expect(restored.earnedAchievements, achievements);
    expect({
      for (final module in catalog) module.id: restored.moduleStatus(module),
    }, states);
    expect(await preferences.getString(key), rawBefore);
    await tester.pumpWidget(PspsApp(key: UniqueKey(), controller: restored));
    await tester.pumpAndSettle();
    await reveal(find.byKey(ValueKey('cu05.module.${first.id}')));
    await binding.takeScreenshot('CU05-AV06-estado-recuperado');
    expect(tester.takeException(), isNull);
  });
}

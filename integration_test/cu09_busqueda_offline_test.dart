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
  testWidgets('TI09-01: search and open content offline without changes', (
    tester,
  ) async {
    const key = 'psps.integration.cu09.offline';
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
    final answered = controller.answeredCount;
    final points = controller.points;
    final achievements = Map<String, String?>.from(
      controller.earnedAchievements,
    );
    await tester.pumpWidget(PspsApp(controller: controller));
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();

    Future<void> reveal(Finder finder) async {
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

    Future<void> type(String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.pumpAndSettle();
    }

    Future<void> unchanged() async {
      expect(await preferences.getString(key), rawBefore);
      expect(controller.answeredCount, answered);
      expect(controller.points, points);
      expect(controller.earnedAchievements, achievements);
    }

    // M-09A: magnifier on Home.
    expect(find.byTooltip('Buscar contenidos'), findsOneWidget);
    await binding.takeScreenshot('CU09-AV01-inicio-lupa');
    await tester.tap(find.byTooltip('Buscar contenidos'));
    await tester.pumpAndSettle();

    // A2: fewer than three characters.
    await type('cl');
    expect(find.text('Escribe al menos 3 letras'), findsOneWidget);
    await binding.takeScreenshot('CU09-AV02-texto-corto');

    // CA-11: results by title first, then by content.
    await type('clase');
    expect(find.text('2 resultados para «clase»'), findsOneWidget);
    await binding.takeScreenshot('CU09-AV03-resultados');
    final lesson = catalog
        .expand((m) => m.topics)
        .firstWhere((t) => t.id == 'CT-08')
        .lessons
        .first;
    final result = find.text(lesson.title);
    await reveal(result);
    await tester.tap(result);
    await tester.pumpAndSettle();
    expect(find.byType(LessonScreen), findsOneWidget);
    await binding.takeScreenshot('CU09-AV04-contenido-abierto');
    await unchanged();
    await tester.pageBack();
    await tester.pumpAndSettle();

    // A1: no results and return to the modules.
    await type('compiladores');
    expect(
      find.text('No se encontraron temas con «compiladores»'),
      findsOneWidget,
    );
    await binding.takeScreenshot('CU09-AV05-sin-resultados');
    await reveal(find.text('Explorar módulos'));
    await tester.tap(find.text('Explorar módulos'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    await unchanged();

    // Recreate controller and interface on native storage.
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    final restored = LearningController(
      modules: catalog,
      store: LocalProgressStore(key: key),
    );
    await restored.load();
    expect(restored.ready, isTrue);
    expect(restored.answeredCount, answered);
    expect(restored.points, points);
    expect(restored.earnedAchievements, achievements);
    expect(await preferences.getString(key), rawBefore);
    expect(tester.takeException(), isNull);
  });
}

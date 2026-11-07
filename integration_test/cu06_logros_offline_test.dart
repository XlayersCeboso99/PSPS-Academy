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
  testWidgets('TI06-01: obtain, consult and keep achievements offline', (
    tester,
  ) async {
    const key = 'psps.integration.cu06.offline';
    final preferences = SharedPreferencesAsync();
    await preferences.remove(key);
    addTearDown(() => preferences.remove(key));
    final topic = catalog.first.topics.first;
    final practice = topic.practice;
    final controller = LearningController(
      modules: catalog,
      store: LocalProgressStore(key: key),
    );
    await controller.load();
    expect(controller.ready, isTrue);
    expect(controller.earnedAchievements, isEmpty);
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

    // Native writes are real asynchronous I/O: wait until the save finishes.
    Future<void> settle() async {
      for (var i = 0; i < 50 && controller.saving; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    Future<void> tap(Finder finder) async {
      await reveal(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();
      await settle();
    }

    Future<void> back() async {
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    // A1: «Logros» from «Mi progreso» without achievements.
    await tester.tap(find.text('Mi progreso'));
    await tester.pumpAndSettle();
    await tap(find.text('Logros'));
    expect(find.text('Aún no tienes logros'), findsOneWidget);
    expect(await preferences.getString(key), isNull);
    await binding.takeScreenshot('CU06-AV01-sin-logros');
    await back();

    // Complete the first activity through CU-02 and receive the notice once.
    await tap(find.text('Actividades'));
    await tap(find.text(practice.title));
    for (final step in practice.steps) {
      await tap(find.text(step));
    }
    expect(controller.practiceCompleted(practice), isTrue);
    expect(
      find.text(
        '¡Logro obtenido: Manos a la obra! Desbloqueaste el tema Océano.',
      ),
      findsOneWidget,
    );
    await binding.takeScreenshot('CU06-AV02-aviso-logro');
    await back();
    await back();

    // CA-06: name, met condition and date.
    await tap(find.text('Logros'));
    final earned = find.byKey(const ValueKey('cu06.achievement.L-03'));
    await reveal(earned);
    expect(
      find.text('Condición cumplida: Realiza tu primera actividad.'),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: earned,
        matching: find.textContaining('Obtenido el'),
      ),
      findsOneWidget,
    );
    await binding.takeScreenshot('CU06-AV03-logro-obtenido');
    final consulted = await preferences.getString(key);

    // CA-07: locked theme cannot be used; the chosen theme is applied.
    await reveal(find.byKey(const ValueKey('cu06.theme.U-03')));
    expect(find.text('Usar Noche'), findsNothing);
    await tap(find.text('Usar Océano'));
    expect(controller.selectedTheme, 'U-01');
    await reveal(find.byKey(const ValueKey('cu06.theme.U-01')));
    await binding.takeScreenshot('CU06-AV04-tema-en-uso');
    expect(await preferences.getString(key), isNot(consulted));
    final rawAfter = await preferences.getString(key);
    await back();
    await tap(find.text('Logros'));
    expect(await preferences.getString(key), rawAfter);
    await back();

    // CA-06b: recreate controller and interface on native storage.
    final points = controller.points;
    final achievements = Map<String, String?>.from(
      controller.earnedAchievements,
    );
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
    expect(restored.selectedTheme, 'U-01');
    expect(restored.newAchievements, isEmpty);
    expect(await preferences.getString(key), rawAfter);
    await tester.pumpWidget(PspsApp(key: UniqueKey(), controller: restored));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mi progreso'));
    await tester.pumpAndSettle();
    await reveal(find.text('Logros'));
    await tester.tap(find.text('Logros'));
    await tester.pumpAndSettle();
    await reveal(find.byKey(const ValueKey('cu06.achievement.L-03')));
    await binding.takeScreenshot('CU06-AV05-logros-recuperados');
    expect(tester.takeException(), isNull);
  });
}

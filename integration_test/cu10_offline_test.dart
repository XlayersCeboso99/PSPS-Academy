import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:psps/data/catalog.dart';
import 'package:psps/data/progress_store.dart';
import 'package:psps/domain/learning_controller.dart';
import 'package:psps/ui/app.dart';

// Run in the isolated Android package through verify_sprint2_android.ps1.
// Verify airplane mode and absence of a network before and after execution.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'TI10-01: consult native totals offline without duplicate rewards',
    (tester) async {
      const key = 'psps.integration.cu10.offline';
      final preferences = SharedPreferencesAsync();
      await preferences.remove(key);
      addTearDown(() => preferences.remove(key));
      final controller = LearningController(
        modules: catalog,
        store: LocalProgressStore(key: key),
      );
      await controller.load();
      expect(controller.ready, isTrue);
      await tester.pumpWidget(PspsApp(controller: controller));
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();

      Future<void> points() async {
        final link = find.text('Puntos');
        if (link.evaluate().isEmpty) {
          tester
              .state<ScrollableState>(find.byType(Scrollable).first)
              .position
              .jumpTo(0);
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            link,
            150,
            scrollable: find.byType(Scrollable).first,
          );
        }
        await tester.ensureVisible(find.text('Puntos'));
        await tester.tap(find.text('Puntos'));
        await tester.pumpAndSettle();
      }

      Future<void> back() async {
        await tester.pageBack();
        await tester.pumpAndSettle();
      }

      await points();
      expect(find.text('0 pts'), findsOneWidget);
      expect(await preferences.getString(key), isNull);
      await binding.takeScreenshot('CU10-AV01-cero');
      await back();

      // Exercise the real controller and native store; arranging the activity UI
      // belongs to CU-02. CU-10 remains a read-only screen.
      final practices = controller.practices.take(2).toList();
      for (var i = 0; i < practices.length; i++) {
        final practice = practices[i];
        expect(
          await controller.saveOrder(
            practice,
            List.generate(practice.steps.length, (i) => i),
          ),
          isTrue,
        );
        await tester.pumpAndSettle();
        await points();
        expect(find.text('${(i + 1) * 10} pts'), findsOneWidget);
        await binding.takeScreenshot(
          i == 0 ? 'CU10-AV02-diez' : 'CU10-AV04-veinte',
        );
        final before = await preferences.getString(key);
        await back();
        if (i == 0) {
          expect(
            await controller.saveOrder(
              practice,
              List.generate(practice.steps.length, (i) => i),
            ),
            isTrue,
          );
          await tester.pumpAndSettle();
          await points();
          expect(find.text('10 pts'), findsOneWidget);
          expect(await preferences.getString(key), before);
          await binding.takeScreenshot('CU10-AV03-repeticion-sin-premio');
          await back();
        }
      }

      final saved = await preferences.getString(key);
      final achievements = Map<String, String?>.from(
        controller.earnedAchievements,
      );
      for (var i = 0; i < 3; i++) {
        await points();
        expect(find.text('20 pts'), findsOneWidget);
        await back();
      }
      expect(await preferences.getString(key), saved);
      expect(controller.earnedAchievements, achievements);
      expect(controller.answeredCount, 0);
      expect(controller.progress, 0);

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      final restored = LearningController(
        modules: catalog,
        store: LocalProgressStore(key: key),
      );
      await restored.load();
      expect(restored.ready, isTrue);
      expect(restored.points, 20);
      expect(restored.earnedAchievements, achievements);
      await tester.pumpWidget(PspsApp(key: UniqueKey(), controller: restored));
      await tester.pumpAndSettle();
      await points();
      expect(find.text('20 pts'), findsOneWidget);
      expect(await preferences.getString(key), saved);
      await binding.takeScreenshot('CU10-AV05-total-recuperado');

      await preferences.setString(key, 'fixture de estado incompatible');
      await restored.load();
      await tester.pumpAndSettle();
      expect(find.text(restored.loadError!), findsOneWidget);
      expect(find.byKey(const ValueKey('cu10.total')), findsNothing);
      expect(find.text('0 pts'), findsNothing);
      expect(
        await preferences.getString(key),
        'fixture de estado incompatible',
      );
      await binding.takeScreenshot('CU10-AV06-error-sin-reinicio');
      await preferences.setString(key, saved!);
      await tester.tap(find.text('Reintentar carga'));
      await tester.pumpAndSettle();
      expect(find.text('20 pts'), findsOneWidget);
      expect(await preferences.getString(key), saved);
      expect(tester.takeException(), isNull);
    },
  );
}

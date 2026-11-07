import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psps/data/catalog.dart';
import 'package:psps/domain/course.dart';
import 'package:psps/domain/learning_controller.dart';
import 'package:psps/ui/app.dart';

import 'support.dart';

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
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

void main() {
  testWidgets(
    'CU01: navigate, read without progress, answer incorrectly and finish subtopic',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = LearningController(modules: catalog, store: MemoryStore());
      await c.load();
      await tester.pumpWidget(PspsApp(controller: c));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Estructuras y algoritmos'));
      await tapVisible(tester, find.text('Datos en filas y columnas'));
      await tapVisible(tester, find.text('Estudiar subtema'));
      await tapVisible(tester, find.text('Siguiente'));
      expect(c.answeredCount, 0);
      await tapVisible(tester, find.text('Ir a preguntas'));
      final before = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Comprobar'),
      );
      expect(before.onPressed, isNull);
      await tapVisible(tester, find.text('Solo el valor'));
      await tapVisible(tester, find.text('Comprobar'));
      expect(find.text('Sigue aprendiendo'), findsOneWidget);
      expect(c.answeredCount, 1);
      await tapVisible(tester, find.text('Siguiente pregunta'));
      await tapVisible(tester, find.text('7'));
      await tapVisible(tester, find.text('Comprobar'));
      expect(
        c.lessonStatus(catalog.first.topics.first.lessons.first),
        ProgressStatus.completed,
      );
      await tester.scrollUntilVisible(
        find.text('¡Subtema completado!'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('¡Subtema completado!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'CU02: select activity steps, complete automatically, reopen without duplicate points',
    (tester) async {
      final c = LearningController(modules: catalog, store: MemoryStore());
      await c.load();
      final t = catalog.first.topics.first;
      await tester.pumpWidget(
        MaterialApp(
          home: PracticeScreen(controller: c, topic: t),
        ),
      );
      await tester.pumpAndSettle();
      for (final step in t.practice.steps) {
        await tapVisible(tester, find.widgetWithText(OutlinedButton, step));
      }
      expect(find.text('¡Actividad realizada!'), findsOneWidget);
      expect(c.points, 10);
      expect(c.answeredCount, 0);
      await tester.pumpWidget(
        MaterialApp(
          home: PracticeScreen(
            key: const ValueKey('reopen'),
            controller: c,
            topic: t,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(c.points, 10);
      expect(find.text('¡Actividad realizada!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('RNF05: narrow screen and larger text remain navigable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = LearningController(modules: catalog, store: MemoryStore());
    await c.load();
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.4)),
          child: child!,
        ),
        home: HomeScreen(controller: c),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tapVisible(tester, find.text('Mi progreso'));
    expect(find.text('Cada paso cuenta.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

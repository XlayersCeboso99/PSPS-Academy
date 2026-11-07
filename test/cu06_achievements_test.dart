import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psps/data/catalog.dart';
import 'package:psps/data/progress_store.dart';
import 'package:psps/domain/course.dart';
import 'package:psps/domain/gamification.dart';
import 'package:psps/domain/learning_controller.dart';
import 'package:psps/ui/app.dart';

import 'support.dart';

// CU-06 Consultar los logros obtenidos · RF-06 · CA-06, CA-06b y CA-07.
// Catálogo G-02/G-03 acordado por el equipo en MR-09; diseño SDS v0.2 §9.
// Los IDs CP06 identifican estas pruebas ejecutables (WP.14 de CU-06).

List<int> solved(Practice p) => List.generate(p.steps.length, (i) => i);
int wrong(Question q) => (q.correctIndex + 1) % q.options.length;
String two(int n) => n.toString().padLeft(2, '0');

Future<(LearningController, MemoryStore)> fixture([String? raw]) async {
  final store = MemoryStore()..raw = raw;
  final controller = LearningController(modules: catalog, store: store);
  await controller.load();
  expect(controller.ready, isTrue);
  return (controller, store);
}

Future<void> reveal(WidgetTester tester, Finder finder) async {
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

Future<void> tap(WidgetTester tester, Finder finder) async {
  await reveal(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> showAchievements(
  WidgetTester tester,
  LearningController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      home: AchievementsScreen(controller: controller),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('CP06-01: catalog G-02 (L-01 to L-11) and G-03 (U-00 to U-03)', () {
    expect(
      {for (final a in Gamification.achievements) a.id: a.condition},
      {
        'L-01': 'Responde tu primera pregunta.',
        'L-02': 'Responde todas las preguntas de un subtema.',
        'L-03': 'Realiza tu primera actividad.',
        'L-04': 'Realiza 5 actividades.',
        'L-05': 'Realiza las 10 actividades.',
        'L-06': 'Completa el módulo «Estructuras y algoritmos».',
        'L-07': 'Completa el módulo «Programación y objetos».',
        'L-08': 'Completa el módulo «Datos y relaciones».',
        'L-09': 'Completa el módulo «Diseño para las personas».',
        'L-11': 'Completa los 4 módulos.',
      },
    );
    expect(Gamification.achievements.map((a) => a.id), [
      for (var i = 1; i <= 11; i++)
        if (i != 10) 'L-${two(i)}',
    ]);
    final modules = {for (final m in catalog) m.id: m.title};
    final byModule = Gamification.achievements.where(
      (x) => x.rule == AchievementRule.completedModule,
    );
    for (final a in byModule) {
      expect(a.condition, contains(modules[a.moduleId]), reason: a.id);
    }
    expect(
      LearningController(modules: catalog, store: MemoryStore()).practices,
      hasLength(10),
    );
    expect(Gamification.themes.map((t) => t.id), [
      'U-00',
      'U-01',
      'U-02',
      'U-03',
    ]);
    final ids = Gamification.achievements.map((a) => a.id).toSet();
    for (final t in Gamification.themes) {
      expect(ids.containsAll(t.unlockedBy), isTrue, reason: t.id);
    }
    expect(Gamification.unlocked(const []), {'U-00'});
  });

  testWidgets('CP06-02: A1 without achievements; consulting writes nothing', (
    tester,
  ) async {
    final (c, store) = await fixture();
    await showAchievements(tester, c);
    expect(find.text('0 de 10 logros obtenidos'), findsOneWidget);
    expect(find.text('Aún no tienes logros'), findsOneWidget);
    expect(
      find.text('Realiza actividades y completa temas para obtenerlos.'),
      findsOneWidget,
    );
    final night = find.byKey(const ValueKey('cu06.theme.U-03'));
    await reveal(tester, night);
    expect(
      find.descendant(of: night, matching: find.text('Bloqueado')),
      findsOneWidget,
    );
    expect(find.text('Usar Noche'), findsNothing);
    expect(c.earnedAchievements, isEmpty);
    expect(store.writes, 0);
    expect(tester.takeException(), isNull);
  });

  test('CP06-03: L-01 with the first answer, even incorrect; L-02 with a full lesson; dated once', () async {
    final (c, store) = await fixture();
    final lesson = catalog.first.topics.first.lessons.first;
    final q = lesson.questions.first;
    expect(await c.answer(q, wrong(q)), isTrue);
    expect(c.earnedAchievements.keys.toSet(), {'L-01'});
    expect(DateTime.tryParse(c.earnedAchievements['L-01']!), isNotNull);
    expect(
      Gamification.rewardMessage(c.newAchievements, c.newThemes),
      '¡Logro obtenido: Primer paso!',
    );
    final other = lesson.questions[1];
    await c.answer(other, other.correctIndex);
    expect(c.newAchievements.map((a) => a.id), ['L-02']);
    final date = c.earnedAchievements['L-01'];
    final writes = store.writes;
    expect(await c.answer(q, q.correctIndex), isTrue);
    expect(store.writes, writes);
    expect(c.newAchievements, isEmpty);
    expect(c.earnedAchievements['L-01'], date);
  });

  test('CP06-04: L-03, L-04 and L-05 by activities; Ocean unlocked; achievements give no points', () async {
    final (c, _) = await fixture();
    final practices = c.practices.toList();
    await c.saveOrder(practices.first, solved(practices.first));
    expect(c.newAchievements.map((a) => a.id), ['L-03']);
    expect(c.newThemes.map((t) => t.id), ['U-01']);
    expect(
      Gamification.rewardMessage(c.newAchievements, c.newThemes),
      '¡Logro obtenido: Manos a la obra! Desbloqueaste el tema Océano.',
    );
    for (final p in practices.skip(1).take(3)) {
      await c.saveOrder(p, solved(p));
    }
    expect(c.earnedAchievements, isNot(contains('L-04')));
    await c.saveOrder(practices[4], solved(practices[4]));
    expect(c.newAchievements.map((a) => a.id), ['L-04']);
    for (final p in practices.skip(5)) {
      await c.saveOrder(p, solved(p));
    }
    expect(c.earnedAchievements.keys.toSet(), {'L-03', 'L-04', 'L-05'});
    expect(c.points, practices.length * Gamification.pointsPerPractice);
  });

  test('CP06-05: one achievement per module and L-11 with all; Sunset and Night unlock', () async {
    final (c, _) = await fixture();
    for (final q in catalog.first.questions) {
      await c.answer(q, q.correctIndex);
    }
    expect(c.earnedAchievements, contains('L-06'));
    expect(c.newThemes.map((t) => t.id), ['U-02']);
    expect(c.earnedAchievements, isNot(contains('L-11')));
    for (final q in catalog.skip(1).expand((m) => m.questions)) {
      await c.answer(q, wrong(q));
    }
    expect(
      c.earnedAchievements.keys,
      containsAll(['L-07', 'L-08', 'L-09', 'L-11']),
    );
    expect(c.unlockedThemes, {'U-00', 'U-02', 'U-03'});
    expect(c.points, 0);
  });

  test('CP06-06: three correct reviews never grant rewards', () async {
    final (c, store) = await fixture();
    final qs = c.questions.take(3).toList();
    for (final q in qs) {
      await c.answer(q, wrong(q));
    }
    final rewards = Map<String, String?>.from(c.earnedAchievements);
    final points = c.points;
    for (final q in qs) {
      expect(await c.reviewAnswer(q, q.correctIndex), isTrue);
      expect(c.newAchievements, isEmpty);
      expect(c.newThemes, isEmpty);
    }
    expect(c.earnedAchievements, rewards);
    expect(c.points, points);
    final restored = LearningController(modules: catalog, store: store);
    await restored.load();
    expect(restored.earnedAchievements, rewards);
  });

  test(
    'CP06-07: if saving fails nothing is awarded; retry awards once',
    () async {
      final (c, store) = await fixture();
      final p = c.practices.first;
      store.failSave = true;
      expect(await c.saveOrder(p, solved(p)), isFalse);
      expect(c.earnedAchievements, isEmpty);
      expect(c.newAchievements, isEmpty);
      expect(c.unlockedThemes, {'U-00'});
      store.failSave = false;
      expect(await c.saveOrder(p, solved(p)), isTrue);
      expect(c.newAchievements.map((a) => a.id), ['L-03']);
      expect(await c.saveOrder(p, solved(p)), isTrue);
      expect(c.newAchievements, isEmpty);
    },
  );

  testWidgets(
    'CP06-08: each achievement shows name, met condition and date or «Fecha no disponible» (CA-06)',
    (tester) async {
      final lesson = catalog.first.topics.first.lessons.first;
      final q = lesson.questions.first;
      final p = catalog.first.topics.first.practice;
      final (c, store) = await fixture(
        jsonEncode({
          'version': 2,
          'answers': {q.id: wrong(q)},
          'practices': {p.id: solved(p)},
          'reviewAnswers': {},
        }),
      );
      expect(c.earnedAchievements, {'L-01': null, 'L-03': null});
      final other = lesson.questions[1];
      await c.answer(other, other.correctIndex);
      final d = DateTime.parse(c.earnedAchievements['L-02']!).toLocal();
      final writes = store.writes;
      final raw = store.raw;
      await showAchievements(tester, c);
      expect(find.text('3 de 10 logros obtenidos'), findsOneWidget);
      final first = find.byKey(const ValueKey('cu06.achievement.L-01'));
      for (final text in [
        'Primer paso',
        'Condición cumplida: Responde tu primera pregunta.',
        'Fecha no disponible',
      ]) {
        expect(
          find.descendant(of: first, matching: find.text(text)),
          findsOneWidget,
        );
      }
      final dated = find.byKey(const ValueKey('cu06.achievement.L-02'));
      await reveal(tester, dated);
      expect(
        find.descendant(
          of: dated,
          matching: find.text(
            'Obtenido el ${two(d.day)}/${two(d.month)}/${d.year}',
          ),
        ),
        findsOneWidget,
      );
      expect(store.writes, writes);
      expect(store.raw, raw);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('CP06-09: the reward notice appears once (CA-06b)', (
    tester,
  ) async {
    final (c, _) = await fixture();
    final p = c.practices.first;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () => reportSave(
                    context,
                    c.saveOrder(p, solved(p)),
                    controller: c,
                  ),
                  child: const Text('Completar actividad'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    const notice =
        '¡Logro obtenido: Manos a la obra! Desbloqueaste el tema Océano.';
    await tester.tap(find.text('Completar actividad'));
    await tester.pumpAndSettle();
    expect(find.text(notice), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text(notice), findsNothing);
    await tester.tap(find.text('Completar actividad'));
    await tester.pumpAndSettle();
    expect(find.text(notice), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets(
    'CP06-10: locked theme cannot be used; chosen one is «En uso», persists and changes nothing else (CA-07)',
    (tester) async {
      final (c, store) = await fixture();
      final p = c.practices.first;
      await c.saveOrder(p, solved(p));
      final points = c.points;
      final achievements = Map<String, String?>.from(c.earnedAchievements);
      await showAchievements(tester, c);
      final night = find.byKey(const ValueKey('cu06.theme.U-03'));
      await reveal(tester, night);
      expect(
        find.descendant(
          of: night,
          matching: find.text('Obtén el logro «Recorrido completo».'),
        ),
        findsOneWidget,
      );
      expect(find.text('Usar Noche'), findsNothing);
      await tap(tester, find.text('Usar Océano'));
      expect(c.selectedTheme, 'U-01');
      final ocean = find.byKey(const ValueKey('cu06.theme.U-01'));
      await reveal(tester, ocean);
      expect(
        find.descendant(of: ocean, matching: find.text('En uso')),
        findsOneWidget,
      );
      expect(c.points, points);
      expect(c.earnedAchievements, achievements);
      expect(c.answeredCount, 0);
      final restored = LearningController(modules: catalog, store: store);
      await restored.load();
      expect(restored.selectedTheme, 'U-01');
      expect(restored.points, points);
      expect(restored.earnedAchievements, achievements);
      expect(tester.takeException(), isNull);
    },
  );

  test('CP06-11: stored review does not create achievements on load', () async {
    final qs = catalog.expand((m) => m.questions).take(3).toList();
    const date = '2026-10-22T16:00:00.000Z';
    final raw = ProgressSnapshot(
      answers: {for (final q in qs) q.id: wrong(q)},
      reviewAnswers: {for (final q in qs) q.id: q.correctIndex},
      points: 0,
      rewardedPractices: const [],
      achievements: const {'L-01': date, 'L-02': date},
    ).encode();
    final (c, store) = await fixture(raw);
    expect(c.earnedAchievements, {'L-01': date, 'L-02': date});
    expect(store.writes, 0);
    expect(store.raw, raw);
    final p = c.practices.first;
    await c.saveOrder(p, solved(p));
    expect(c.newAchievements.map((a) => a.id), ['L-03']);
    expect(c.earnedAchievements['L-10'], isNull);
    expect(c.earnedAchievements['L-01'], date);
  });

  test('CP06-12: an achievement saved without its condition is rejected without overwriting', () async {
    final raw = ProgressSnapshot(
      points: 0,
      rewardedPractices: const [],
      achievements: const {'L-05': null},
    ).encode();
    final store = MemoryStore()..raw = raw;
    final c = LearningController(modules: catalog, store: store);
    await c.load();
    expect(c.ready, isFalse);
    expect(c.loadError, isNotNull);
    expect(store.raw, raw);
    expect(store.writes, 0);
  });

  testWidgets(
    'CP06-13: «Logros» opens from «Mi progreso» on a narrow screen with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final (c, store) = await fixture();
      await tester.pumpWidget(PspsApp(controller: c));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mi progreso'));
      await tester.pumpAndSettle();
      await tap(tester, find.text('Logros'));
      expect(find.byType(AchievementsScreen), findsOneWidget);
      expect(find.text('Aún no tienes logros'), findsOneWidget);
      expect(store.writes, 0);
      expect(tester.takeException(), isNull);
    },
  );
}

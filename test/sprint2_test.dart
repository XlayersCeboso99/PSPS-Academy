import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psps/data/catalog.dart';
import 'package:psps/data/progress_store.dart';
import 'package:psps/domain/content_search.dart';
import 'package:psps/domain/course.dart';
import 'package:psps/domain/gamification.dart';
import 'package:psps/domain/learning_controller.dart';
import 'package:psps/ui/app.dart';

import 'app_test.dart' show tapVisible;
import 'support.dart';

void main() {
  late MemoryStore store;
  late LearningController c;
  setUp(() async {
    store = MemoryStore();
    c = LearningController(modules: catalog, store: store);
    await c.load();
  });

  test(
    'G01/G02: first saved activity gives 10, achievement and Ocean only once',
    () async {
      final p = c.practices.first;
      await c.saveOrder(p, [0]);
      expect(c.points, 0);
      expect(c.earnedAchievements, isEmpty);
      store.failSave = true;
      expect(
        await c.saveOrder(p, List.generate(p.steps.length, (i) => i)),
        isFalse,
      );
      expect(c.points, 0);
      expect(c.newAchievements, isEmpty);
      expect(c.unlockedThemes, {'U-00'});
      store.failSave = false;
      await c.saveOrder(p, List.generate(p.steps.length, (i) => i));
      expect(c.points, 10);
      expect(c.earnedAchievements.keys, contains('L-03'));
      expect(c.newAchievements.map((a) => a.id), ['L-03']);
      expect(c.newThemes.map((a) => a.id), ['U-01']);
      final date = c.earnedAchievements['L-03'];
      final writes = store.writes;
      await c.saveOrder(p, [0]);
      expect(c.points, 10);
      expect(c.newAchievements, isEmpty);
      expect(c.newThemes, isEmpty);
      expect(store.writes, writes);
      expect(c.earnedAchievements['L-03'], date);
    },
  );

  test(
    'G02: ten approved achievements; activities never complete modules',
    () async {
      for (final p in c.practices) {
        await c.saveOrder(p, List.generate(p.steps.length, (i) => i));
      }
      expect(c.earnedAchievements.keys.toSet(), {'L-03', 'L-04', 'L-05'});
      expect(c.points, 100);
      expect(c.answeredCount, 0);
      for (final q in c.questions) {
        await c.answer(q, (q.correctIndex + 1) % q.options.length);
      }
      expect(
        c.earnedAchievements.keys.toSet(),
        Gamification.achievements.map((a) => a.id).toSet(),
      );
      expect(c.earnedAchievements, isNot(contains('L-10')));
      expect(c.unlockedThemes, {'U-00', 'U-01', 'U-02', 'U-03'});
      expect(c.points, 100);
    },
  );

  test('G03: locked theme rejected; selection atomic and persistent', () async {
    expect(await c.selectTheme('U-03'), isFalse);
    expect(store.writes, 0);
    final p = c.practices.first;
    await c.saveOrder(p, List.generate(p.steps.length, (i) => i));
    store.failSave = true;
    expect(await c.selectTheme('U-01'), isFalse);
    expect(c.selectedTheme, 'U-00');
    store.failSave = false;
    expect(await c.selectTheme('U-01'), isTrue);
    final restored = LearningController(modules: catalog, store: store);
    await restored.load();
    expect(restored.ready, isTrue);
    expect(restored.selectedTheme, 'U-01');
    expect(restored.points, 10);
    expect(restored.earnedAchievements, c.earnedAchievements);
  });

  test(
    'migration v1 and v2 recovers history without fake dates or writes',
    () async {
      final p = c.practices.first;
      final q = c.questions.first;
      for (final version in [1, 2]) {
        store.raw = jsonEncode({
          'version': version,
          'answers': {q.id: 0},
          'practices': {p.id: List.generate(p.steps.length, (i) => i)},
          if (version == 2) 'reviewAnswers': {},
        });
        final before = store.raw;
        final writes = store.writes;
        await c.load();
        expect(c.ready, isTrue);
        expect(c.points, 10);
        expect(c.earnedAchievements, {'L-01': null, 'L-03': null});
        expect(store.raw, before);
        expect(store.writes, writes);
        await c.selectTheme('U-01');
        expect(jsonDecode(store.raw!)['version'], 3);
        await c.load();
        expect(c.points, 10);
        expect(c.earnedAchievements, {'L-01': null, 'L-03': null});
      }
    },
  );

  test(
    'review preserves rewards, dates and selected theme byte for byte',
    () async {
      final q = c.questions.first;
      final p = c.practices.first;
      await c.answer(q, (q.correctIndex + 1) % q.options.length);
      await c.saveOrder(p, List.generate(p.steps.length, (i) => i));
      await c.selectTheme('U-01');
      final before = ProgressSnapshot.decode(store.raw!);
      await c.reviewAnswer(q, q.correctIndex);
      final after = ProgressSnapshot.decode(store.raw!);
      expect(after.points, before.points);
      expect(after.achievements, before.achievements);
      expect(after.rewardedPractices, before.rewardedPractices);
      expect(after.selectedTheme, before.selectedTheme);
      expect(c.newAchievements, isEmpty);
      expect(c.newThemes, isEmpty);
    },
  );

  test('inconsistent stored points are rejected without overwrite', () async {
    store.raw = ProgressSnapshot(points: 10).encode();
    final before = store.raw;
    await c.load();
    expect(c.ready, isFalse);
    expect(c.loadError, isNotNull);
    expect(store.raw, before);
    expect(await c.selectTheme('U-00'), isFalse);
  });

  test('CU09: minimum length, title rank, case and accents', () {
    final search = ContentSearch(catalog);
    expect(search.search(' cl '), isEmpty);
    final results = search.search('clase');
    expect(results.map((r) => r.topic.id), ['CT-08', 'CT-07']);
    expect(results.first.field, MatchField.title);
    expect(results.last.field, MatchField.content);
    expect(
      search.search('CLASE').map((r) => r.lesson.id),
      results.map((r) => r.lesson.id),
    );
    expect(
      search.search('interaccion').map((r) => r.topic.id),
      contains('CT-10'),
    );
    expect(search.search('compiladores'), isEmpty);
    expect(ContentSearch.normalize('DISEÑO ÁÉÍÓÚÜ'), 'diseño aeiouu');
  });

  test(
    'CU09: no answers/activities indexed; snippets highlight correct range',
    () {
      const question = Question(
        id: 'q',
        prompt: 'secretopregunta',
        options: ['secretopcion'],
        correctIndex: 0,
        explanation: 'secretoexplicacion',
      );
      const lesson = Lesson(
        id: 'l',
        title: 'Título',
        content: 'Contenido con interacción',
        example: 'Ejemplo local',
        questions: [question],
      );
      const topic = Topic(
        id: 't',
        title: 'Tema',
        lessons: [lesson],
        practice: Practice(
          id: 'p',
          title: 'secretopractica',
          instruction: 'instruccionoculta',
          steps: ['a'],
        ),
      );
      final search = ContentSearch([
        const CourseModule(
          id: 'm',
          title: 'Módulo',
          area: 'Área',
          description: 'Descripción',
          topics: [topic],
        ),
      ]);
      for (final word in [
        'secretopregunta',
        'secretopcion',
        'secretoexplicacion',
        'secretopractica',
        'instruccionoculta',
      ]) {
        expect(search.search(word), isEmpty);
      }
      final r = search.search('interaccion').single;
      expect(
        r.snippet.substring(r.matchStart, r.matchStart + r.matchLength),
        'interacción',
      );
    },
  );

  testWidgets('CU06/CU08/CU10: consultation never writes or grants rewards', (
    tester,
  ) async {
    await c.answer(c.questions.first, 0);
    final p = c.practices.first;
    await c.saveOrder(p, List.generate(p.steps.length, (i) => i));
    final before = store.raw;
    final writes = store.writes;
    for (final screen in [
      PointsScreen(controller: c),
      ActivitiesScreen(controller: c),
      AchievementsScreen(controller: c),
    ]) {
      await tester.pumpWidget(MaterialApp(key: UniqueKey(), home: screen));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(store.raw, before);
      expect(store.writes, writes);
    }
    expect(find.text('Primer paso'), findsOneWidget);
    expect(find.text('Manos a la obra'), findsOneWidget);
  });

  testWidgets('CU08: grouped activity opens without completion', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: ActivitiesScreen(controller: c)));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text(c.practices.first.title));
    expect(find.text('TU SECUENCIA'), findsOneWidget);
    expect(c.completedPractices, 0);
    expect(c.points, 0);
    expect(store.writes, 0);
  });

  testWidgets(
    'CU08: topic with no configured activity has explicit empty state',
    (tester) async {
      final empty = LearningController(
        modules: [
          const CourseModule(
            id: 'm',
            title: 'Módulo vacío',
            area: 'Área',
            description: '',
            topics: [
              Topic(
                id: 't',
                title: 'Tema vacío',
                lessons: [],
                practice: Practice(
                  id: 'p',
                  title: '',
                  instruction: '',
                  steps: [],
                ),
              ),
            ],
          ),
        ],
        store: store,
      );
      await empty.load();
      await tester.pumpWidget(
        MaterialApp(home: ActivitiesScreen(controller: empty)),
      );
      expect(
        find.text('Este tema no tiene actividades disponibles'),
        findsOneWidget,
      );
      expect(empty.completedPractices, 0);
      expect(empty.earnedAchievements, isEmpty);
    },
  );

  testWidgets('CU09: type keyword and open result without changing progress', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: SearchScreen(controller: c)));
    expect(find.text('Escribe al menos 3 letras'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'clase');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Del modelo a la instancia'));
    expect(find.text('Siguiente'), findsOneWidget);
    expect(c.answeredCount, 0);
    expect(store.writes, 0);
  });

  testWidgets('CU09: no results returns to home through Explore', (
    tester,
  ) async {
    await tester.pumpWidget(PspsApp(controller: c));
    await tapVisible(tester, find.byTooltip('Buscar contenidos'));
    await tester.enterText(find.byType(TextField), 'compiladores');
    await tester.pumpAndSettle();
    expect(
      find.text('No se encontraron temas con «compiladores»'),
      findsOneWidget,
    );
    await tapVisible(tester, find.text('Explorar módulos'));
    expect(find.text('PSPS Academy'), findsOneWidget);
    expect(store.writes, 0);
  });

  testWidgets(
    'empty points and achievements; locked themes cannot be selected',
    (tester) async {
      await tester.pumpWidget(MaterialApp(home: PointsScreen(controller: c)));
      expect(find.text('0 pts'), findsOneWidget);
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: AchievementsScreen(controller: c),
        ),
      );
      expect(find.text('Aún no tienes logros'), findsOneWidget);
      expect(find.text('Usar Noche'), findsNothing);
      expect(store.writes, 0);
    },
  );

  testWidgets('load error never displays zero points or resets saved data', (
    tester,
  ) async {
    store.failLoad = true;
    await c.load();
    for (final screen in [
      PointsScreen(controller: c),
      ActivitiesScreen(controller: c),
      AchievementsScreen(controller: c),
    ]) {
      await tester.pumpWidget(MaterialApp(key: UniqueKey(), home: screen));
      expect(find.text(c.loadError!), findsOneWidget);
      expect(find.text('0 pts'), findsNothing);
      expect(store.writes, 0);
    }
  });

  testWidgets(
    'G03: changing theme updates app and keeps all modules accessible',
    (tester) async {
      for (final q in c.questions) {
        await c.answer(q, 0);
      }
      await tester.pumpWidget(PspsApp(controller: c));
      await tapVisible(tester, find.text('Logros'));
      await tapVisible(tester, find.text('Usar Noche'));
      expect(c.selectedTheme, 'U-03');
      expect(
        Theme.of(tester.element(find.byType(Scaffold).last)).brightness,
        Brightness.dark,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text(catalog.last.title));
      expect(find.text('Recorrido del módulo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

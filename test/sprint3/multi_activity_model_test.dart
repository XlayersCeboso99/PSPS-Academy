import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psps/app/app.dart';
import 'package:psps/core/content/catalog.dart';
import 'package:psps/core/content/catalog_legacy.dart';
import 'package:psps/core/learning/gamification.dart';
import 'package:psps/core/learning/learning_controller.dart';
import 'package:psps/core/models/course.dart';
import 'package:psps/core/persistence/progress_store.dart';

import '../support.dart';

Question _q(String id) => Question(
  id: id,
  prompt: 'Pregunta $id',
  options: const ['A', 'B'],
  correctIndex: 0,
  explanation: 'Explicación $id',
);

Practice _p(String id) => Practice(
  id: id,
  title: 'Actividad $id',
  instruction: 'Ordena los pasos de $id.',
  steps: ['$id paso 1', '$id paso 2', '$id paso 3'],
);

Topic _t(String id, List<String> questions, List<String> extras) => Topic(
  id: id,
  title: 'Tema $id',
  lessons: [
    Lesson(
      id: '$id.s1',
      title: 'Subtema $id',
      content: 'Contenido',
      example: 'Ejemplo',
      questions: [for (final q in questions) _q('$id.s1.$q')],
    ),
  ],
  practice: _p('$id.a1'),
  extraPractices: [for (final a in extras) _p('$id.$a')],
);

CourseModule _m(List<Topic> topics) => CourseModule(
  id: 'm1',
  title: 'Estructuras y algoritmos',
  area: 'Área',
  description: 'Descripción',
  topics: topics,
);

/// Catálogo «publicado» antes de ampliarlo: 3 preguntas y 2 actividades.
final legacyCatalog = [
  _m([
    _t('T1', ['q1', 'q2'], []),
    _t('T2', ['q1'], []),
  ]),
];

/// Contenido congelado de [legacyCatalog].
const testLegacyIds = {'T1.s1.q1', 'T1.s1.q2', 'T2.s1.q1', 'T1.a1', 'T2.a1'};

/// El mismo catálogo ampliado: preguntas y actividades nuevas en cada tema.
final extendedCatalog = [
  _m([
    _t('T1', ['q1', 'q2', 'q3'], ['a2']),
    _t('T2', ['q1', 'q2'], ['a2']),
  ]),
];

const solved = [0, 1, 2];
const date = '2026-10-01T10:00:00.000Z';

LearningController _controller(List<CourseModule> modules, MemoryStore store) =>
    LearningController(
      modules: modules,
      store: store,
      legacyIds: testLegacyIds,
    );

/// Avance v3 guardado con el catálogo legado completo.
ProgressSnapshot _legacySnapshot({Map<String, String?>? achievements}) =>
    ProgressSnapshot(
      answers: {'T1.s1.q1': 0, 'T1.s1.q2': 0, 'T2.s1.q1': 0},
      practices: {'T1.a1': solved, 'T2.a1': solved},
      points: 20,
      rewardedPractices: ['T1.a1', 'T2.a1'],
      achievements:
          achievements ??
          {
            'L-01': date,
            'L-02': date,
            'L-03': date,
            'L-05': date,
            'L-06': date,
            'L-11': date,
          },
      selectedTheme: 'U-02',
    );

void main() {
  group('Modelo de varias actividades por tema', () {
    test('practices incluye la actividad principal y las adicionales', () {
      final topic = extendedCatalog.first.topics.first;
      expect(topic.practices.map((p) => p.id), ['T1.a1', 'T1.a2']);
      expect(legacyCatalog.first.topics.first.practices.map((p) => p.id), [
        'T1.a1',
      ]);
    });

    test('completar las 2 actividades de un tema da 20 puntos una sola vez '
        'por actividad', () async {
      final store = MemoryStore();
      final c = _controller(extendedCatalog, store);
      await c.load();
      expect(c.ready, isTrue);
      final topic = c.modules.first.topics.first;
      final [a1, a2] = topic.practices;

      expect(await c.saveOrder(a1, solved), isTrue);
      expect(c.points, 10);
      expect(await c.saveOrder(a2, solved), isTrue);
      expect(c.points, 20);
      expect(c.completedPractices, 2);

      // Repetir no suma ni duplica.
      final writes = store.writes;
      expect(await c.saveOrder(a1, solved), isTrue);
      expect(await c.saveOrder(a2, solved), isTrue);
      expect(c.points, 20);
      expect(store.writes, writes);

      final saved = ProgressSnapshot.decode(store.raw!);
      expect(saved.points, 20);
      expect(saved.rewardedPractices, unorderedEquals(['T1.a1', 'T1.a2']));
      expect(
        saved.rewardedPractices.toSet().length,
        saved.rewardedPractices.length,
      );

      // El avance sigue cargando con la regla de puntos = actividades × 10.
      final reopened = _controller(extendedCatalog, store);
      await reopened.load();
      expect(reopened.ready, isTrue);
      expect(reopened.points, 20);
    });

    test('las actividades son opcionales: no cambian el estado de subtema, '
        'tema ni módulo', () async {
      final c = _controller(extendedCatalog, MemoryStore());
      await c.load();
      final module = c.modules.first;
      final topic = module.topics.first;
      final lesson = topic.lessons.first;
      for (final p in c.practices) {
        expect(await c.saveOrder(p, solved), isTrue);
      }
      expect(c.completedPractices, 4);
      expect(c.lessonStatus(lesson), ProgressStatus.notStarted);
      expect(c.topicStatus(topic), ProgressStatus.notStarted);
      expect(c.moduleStatus(module), ProgressStatus.notStarted);

      await c.answer(lesson.questions.first, 0);
      expect(c.lessonStatus(lesson), ProgressStatus.inProgress);
      expect(c.topicStatus(topic), ProgressStatus.inProgress);
      expect(c.moduleStatus(module), ProgressStatus.inProgress);
    });

    test('L-05 cuenta todas las actividades del catálogo actual', () async {
      final c = _controller(extendedCatalog, MemoryStore());
      await c.load();
      final practices = c.practices.toList();
      expect(practices, hasLength(4));
      for (final p in practices.take(3)) {
        await c.saveOrder(p, solved);
      }
      expect(c.earnedAchievements.containsKey('L-05'), isFalse);
      await c.saveOrder(practices.last, solved);
      expect(c.earnedAchievements['L-05'], isNotNull);
      expect(
        Gamification.achievements.firstWhere((a) => a.id == 'L-05').condition,
        'Realiza todas las actividades.',
      );
    });
  });

  group('legacyView', () {
    test('restringe la vista al contenido legado', () {
      final view = legacyView(extendedCatalog, legacyIds: testLegacyIds);
      expect(view.map((m) => m.id), ['m1']);
      expect(view.first.topics.map((t) => t.id), ['T1', 'T2']);
      expect(view.first.questions.map((q) => q.id), [
        'T1.s1.q1',
        'T1.s1.q2',
        'T2.s1.q1',
      ]);
      expect(view.first.topics.expand((t) => t.practices).map((p) => p.id), [
        'T1.a1',
        'T2.a1',
      ]);
      expect(view.first.topics.every((t) => t.extraPractices.isEmpty), isTrue);
    });

    test('omite módulos sin contenido legado', () {
      final withNewModule = [
        ...extendedCatalog,
        CourseModule(
          id: 'm9',
          title: 'Nuevo',
          area: 'Área',
          description: 'Descripción',
          topics: [
            _t('T9', ['q1'], []),
          ],
        ),
      ];
      final view = legacyView(withNewModule, legacyIds: testLegacyIds);
      expect(view.map((m) => m.id), ['m1']);
    });

    test(
      'el conjunto congelado coincide exactamente con la vista legada real',
      () {
        final questions = catalog
            .expand((m) => m.questions)
            .map((q) => q.id)
            .where(legacyContentIds.contains);
        final practices = catalog
            .expand((m) => m.topics)
            .expand((t) => t.practices)
            .where((p) => p.steps.isNotEmpty)
            .map((p) => p.id)
            .where(legacyContentIds.contains);
        expect(questions, hasLength(20));
        expect(practices, hasLength(10));
        expect({...questions, ...practices}, legacyContentIds);
        expect(legacyContentIds, hasLength(30));
        // La vista legada conserva exactamente el contenido histórico.
        final view = legacyView(catalog);
        expect(view.expand((m) => m.questions).map((q) => q.id), questions);
        expect(
          view
              .expand((m) => m.topics)
              .expand((t) => t.practices)
              .map((p) => p.id),
          practices,
        );
      },
    );
  });

  group('Conservación de logros al ampliar el catálogo', () {
    test('un avance v3 con L-02/L-05/L-06 sigue cargando y conserva sus '
        'fechas tras una acción nueva', () async {
      final store = MemoryStore()..raw = _legacySnapshot().encode();

      // Comprobación previa: el catálogo legado lo carga sin migración.
      final before = _controller(legacyCatalog, store);
      await before.load();
      expect(before.ready, isTrue);

      final c = _controller(extendedCatalog, store);
      await c.load();
      expect(c.ready, isTrue, reason: c.loadError);
      expect(c.loadError, isNull);
      expect(c.points, 20);
      expect(c.selectedTheme, 'U-02');
      for (final id in ['L-01', 'L-02', 'L-03', 'L-05', 'L-06', 'L-11']) {
        expect(c.earnedAchievements[id], date, reason: id);
      }
      // Ninguno de estos se cumple con el catálogo ampliado.
      final current = Gamification.eligible(
        extendedCatalog,
        {'T1.s1.q1': 0, 'T1.s1.q2': 0, 'T2.s1.q1': 0},
        {'T1.a1': solved, 'T2.a1': solved},
      );
      expect(current.intersection({'L-02', 'L-05', 'L-06', 'L-11'}), isEmpty);

      final newQuestion =
          c.modules.first.topics.first.lessons.first.questions.last;
      expect(await c.answer(newQuestion, 0), isTrue);
      expect(c.newAchievements, isEmpty);
      final saved = ProgressSnapshot.decode(store.raw!);
      for (final id in ['L-01', 'L-02', 'L-03', 'L-05', 'L-06', 'L-11']) {
        expect(saved.achievements[id], date, reason: id);
      }
      expect(saved.points, 20);

      // Y sigue cargando después de guardar.
      final reopened = _controller(extendedCatalog, store);
      await reopened.load();
      expect(reopened.ready, isTrue);
      expect(reopened.earnedAchievements['L-05'], date);
    });

    test('completar una actividad nueva conserva los logros legados', () async {
      final store = MemoryStore()..raw = _legacySnapshot().encode();
      final c = _controller(extendedCatalog, store);
      await c.load();
      final extra = c.modules.first.topics.first.extraPractices.single;
      expect(await c.saveOrder(extra, solved), isTrue);
      expect(c.points, 30);
      final saved = ProgressSnapshot.decode(store.raw!);
      expect(saved.achievements['L-05'], date);
      expect(saved.achievements['L-02'], date);
      expect(
        saved.rewardedPractices,
        unorderedEquals(['T1.a1', 'T2.a1', 'T1.a2']),
      );
    });

    test('un usuario nuevo que solo completa las actividades legadas no '
        'recibe L-05 si hay actividades nuevas', () async {
      final store = MemoryStore();
      final c = _controller(extendedCatalog, store);
      await c.load();
      for (final p in c.practices.where((p) => testLegacyIds.contains(p.id))) {
        expect(await c.saveOrder(p, solved), isTrue);
      }
      for (final q in c.questions.where((q) => testLegacyIds.contains(q.id))) {
        expect(await c.answer(q, 0), isTrue);
      }
      // En la vista legada sí se cumplirían; no se otorgan por ella.
      final legacyEligible = Gamification.eligible(
        legacyView(extendedCatalog, legacyIds: testLegacyIds),
        ProgressSnapshot.decode(store.raw!).answers,
        ProgressSnapshot.decode(store.raw!).practices,
      );
      expect(legacyEligible, containsAll(['L-02', 'L-05', 'L-06']));
      expect(c.earnedAchievements.keys, isNot(contains('L-05')));
      expect(c.earnedAchievements.keys, isNot(contains('L-02')));
      expect(c.earnedAchievements.keys, isNot(contains('L-06')));
      expect(c.earnedAchievements.keys, containsAll(['L-01', 'L-03']));
    });

    test('un logro guardado que no se cumple ni en la vista actual ni en la '
        'legada sigue haciendo fallar la carga', () async {
      final store = MemoryStore()
        ..raw = _legacySnapshot(
          achievements: {'L-01': date, 'L-03': date, 'L-04': date},
        ).encode();
      final raw = store.raw;
      final c = _controller(extendedCatalog, store);
      await c.load();
      expect(c.ready, isFalse);
      expect(c.loadError, isNotNull);
      expect(store.raw, raw);
      expect(store.writes, 0);
    });

    test(
      'un tema visual que no desbloquea la unión sigue rechazándose',
      () async {
        final store = MemoryStore()
          ..raw = ProgressSnapshot(
            answers: {'T1.s1.q1': 0},
            points: 0,
            achievements: {'L-01': date},
            selectedTheme: 'U-02',
          ).encode();
        final c = _controller(extendedCatalog, store);
        await c.load();
        expect(c.ready, isFalse);
      },
    );
  });

  testWidgets('TopicScreen lista todas las actividades y abre cada una', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = _controller(extendedCatalog, MemoryStore());
    await c.load();
    final module = c.modules.first;
    final topic = module.topics.first;
    await tester.pumpWidget(
      MaterialApp(
        home: TopicScreen(controller: c, module: module, topic: topic),
      ),
    );
    await tester.pumpAndSettle();
    for (final p in topic.practices) {
      expect(find.text(p.title), findsOneWidget);
      expect(find.byKey(ValueKey('topic.practice.${p.id}')), findsOneWidget);
    }
    final second = topic.practices.last;
    await tester.ensureVisible(
      find.byKey(ValueKey('topic.practice.${second.id}')),
    );
    await tester.tap(find.byKey(ValueKey('topic.practice.${second.id}')));
    await tester.pumpAndSettle();
    expect(find.text(second.instruction), findsOneWidget);
  });
}

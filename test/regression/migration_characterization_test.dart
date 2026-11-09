import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:psps/core/content/catalog.dart';
import 'package:psps/core/persistence/progress_store.dart';
import 'package:psps/core/learning/learning_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support.dart';
import 'legacy_catalog_fixture.dart';

const _key = 'psps.progress.v1';
const _otherKey = 'psps.regression.unrelated';
const _date = '2026-10-22T16:00:00.000Z';

// JSON literal e IDs históricos: no generar las fixtures con el encoder o con
// los IDs del catálogo que se pretende proteger contra cambios accidentales.
const _fixtures = {
  1: '''{
    "version": 1,
    "answers": {"CT-01.s1.q1": 0, "CT-02.s1.q1": 1, "CT-03.s1.q1": 1},
    "practices": {"CT-01.a1": [0, 1, 2], "CT-02.a1": [0], "CT-03.a1": [2, 1, 0]}
  }''',
  2: '''{
    "version": 2,
    "answers": {"CT-01.s1.q1": 0, "CT-02.s1.q1": 1, "CT-03.s1.q1": 1},
    "practices": {"CT-01.a1": [0, 1, 2], "CT-02.a1": [0], "CT-03.a1": [2, 1, 0]},
    "reviewAnswers": {"CT-01.s1.q1": 1, "CT-02.s1.q1": 2}
  }''',
  3: '''{
    "version": 3,
    "answers": {"CT-01.s1.q1": 0, "CT-02.s1.q1": 1, "CT-03.s1.q1": 1},
    "practices": {"CT-01.a1": [0, 1, 2], "CT-02.a1": [0], "CT-03.a1": [2, 1, 0]},
    "reviewAnswers": {"CT-01.s1.q1": 1, "CT-02.s1.q1": 2},
    "points": 10,
    "rewardedPractices": ["CT-01.a1"],
    "achievements": {"L-01": "2026-10-22T16:00:00.000Z", "L-03": null},
    "selectedTheme": "U-01"
  }''',
};

// Simula solo la frontera de preferencias; LocalProgressStore, su clave por
// defecto, el decoder y LearningController siguen siendo código real.
// Fake rechaza cualquier operación no prevista (p. ej. clear/remove).
class _Preferences extends Fake implements SharedPreferencesAsync {
  _Preferences([String? raw]) : values = {_otherKey: 'conservar', _key: ?raw};

  final Map<String, String> values;
  final List<String> reads = [];
  final List<String> writes = [];

  @override
  Future<String?> getString(String key) async {
    reads.add(key);
    return values[key];
  }

  @override
  Future<void> setString(String key, String value) async {
    writes.add(key);
    values[key] = value;
  }
}

Future<LearningController> _open(ProgressStore store) async {
  final controller = LearningController(modules: catalog, store: store);
  addTearDown(controller.dispose);
  await controller.load();
  return controller;
}

Map<String, dynamic> _json(String raw) =>
    jsonDecode(raw) as Map<String, dynamic>;

void _expectRecovered(LearningController c, int version) {
  final fixture = _json(_fixtures[version]!);
  expect(c.ready, isTrue);
  expect(c.loadError, isNull);
  expect({
    for (final q in c.questions)
      if (c.answerFor(q) != null) q.id: c.answerFor(q),
  }, fixture['answers']);
  expect({
    for (final p in c.practices)
      if (c.orderFor(p).isNotEmpty) p.id: c.orderFor(p),
  }, fixture['practices']);
  expect({
    for (final q in c.questions)
      if (c.reviewAnswerFor(q) != null) q.id: c.reviewAnswerFor(q),
  }, fixture['reviewAnswers'] ?? {});
  expect(c.answeredCount, 3);
  expect(
    c.progress,
    (fixture['answers'] as Map).length /
        catalog.expand((m) => m.questions).length,
  );
  expect(c.completedPractices, 1);
  expect(c.points, 10);
  expect(c.earnedAchievements, {
    'L-01': version == 3 ? _date : null,
    'L-03': null,
  });
  expect(c.selectedTheme, version == 3 ? 'U-01' : 'U-00');
  expect(c.unlockedThemes, {'U-00', 'U-01'});
  expect(c.pendingReview(c.questions).map((q) => q.id), [
    if (version == 1) 'CT-01.s1.q1',
    'CT-02.s1.q1',
  ]);
  for (final m in c.modules) {
    c.moduleStatus(m);
    for (final t in m.topics) {
      c.topicStatus(t);
      for (final l in t.lessons) {
        c.lessonStatus(l);
      }
    }
  }
  expect(c.newAchievements, isEmpty);
  expect(c.newThemes, isEmpty);
}

void main() {
  // sprint2_test.dart: 'migration v1 and v2 recovers history without fake dates
  // or writes' y points_consultation_test.dart CP10-09 ya cubren MemoryStore.
  // Variante: clave real, JSON fijo mixto (acierto/error, completa/borrador/orden
  // incorrecto), repasos no vacíos y v3 con fecha histórica y tema conservados.
  for (final version in [1, 2, 3]) {
    test(
      'MIG-01 v$version: keyed JSON loads read-only until an action saves v3',
      () async {
        expect(LocalProgressStore.storageKey, _key);
        expectHistoricalCatalog(catalog);
        final raw = _fixtures[version]!;
        final preferences = _Preferences(raw);
        final store = LocalProgressStore(preferences: preferences);
        final c = await _open(store);

        for (var consultation = 0; consultation < 2; consultation++) {
          _expectRecovered(c, version);
          await c.load();
        }
        _expectRecovered(c, version);
        expect(preferences.reads, [_key, _key, _key]);
        expect(preferences.writes, isEmpty);
        expect(preferences.values, {_key: raw, _otherKey: 'conservar'});

        final q = c.questions.singleWhere((q) => q.id == 'CT-02.s1.q1');
        expect(await c.reviewAnswer(q, q.correctIndex), isTrue);
        final fixture = _json(raw);
        final expected = {
          'version': 3,
          'answers': fixture['answers'],
          'practices': fixture['practices'],
          'reviewAnswers': {
            ...?fixture['reviewAnswers'] as Map<String, dynamic>?,
            'CT-02.s1.q1': 0,
          },
          'points': 10,
          'rewardedPractices': ['CT-01.a1'],
          'achievements': {'L-01': version == 3 ? _date : null, 'L-03': null},
          'selectedTheme': version == 3 ? 'U-01' : 'U-00',
        };
        expect(_json(preferences.values[_key]!), expected);
        expect(preferences.writes, [_key]);
        expect(preferences.values[_otherKey], 'conservar');

        final saved = preferences.values[_key];
        final reopened = await _open(store);
        expect(reopened.ready, isTrue);
        expect(reopened.reviewAnswerFor(q), 0);
        expect(reopened.answerFor(q), 1);
        expect(reopened.points, 10);
        expect(reopened.earnedAchievements, expected['achievements']);
        expect(reopened.selectedTheme, expected['selectedTheme']);
        expect(preferences.values[_key], saved);
        expect(preferences.writes, [_key]);
      },
    );
  }

  test(
    'MIG-02 R-06: persisted L-10 rejects v3 without overwriting data',
    () async {
      // Caracterización del comportamiento ACTUAL, pendiente de decisión de
      // producto (R-06): incluso con tres repasos acertados se rechaza L-10.
      // CP06-11/12 cubren repaso sin L-10 y otro logro sin condición; aquí el
      // mismo estado SIN L-10 sí carga, para aislar el motivo del rechazo.
      const raw = '''{
      "version": 3,
      "answers": {"CT-01.s1.q1": 0, "CT-02.s1.q1": 1, "CT-03.s1.q1": 0},
      "practices": {"CT-01.a1": [0, 1, 2], "CT-02.a1": [0]},
      "reviewAnswers": {"CT-01.s1.q1": 1, "CT-02.s1.q1": 0, "CT-03.s1.q1": 1},
      "points": 10,
      "rewardedPractices": ["CT-01.a1"],
      "achievements": {"L-01": "2026-10-22T16:00:00.000Z", "L-03": null,
                       "L-10": "2026-10-22T16:00:00.000Z"},
      "selectedTheme": "U-01"
    }''';
      final preferences = _Preferences(raw);
      final store = LocalProgressStore(preferences: preferences);
      final c = await _open(store);
      for (var retry = 0; retry < 2; retry++) {
        expect(c.ready, isFalse);
        expect(c.loadError, contains('Tus datos guardados se conservan'));
        expect(await c.selectTheme('U-00'), isFalse);
        final q = c.questions.first;
        expect(await c.answer(q, q.correctIndex), isFalse);
        expect(await c.reviewAnswer(q, q.correctIndex), isFalse);
        expect(await c.saveOrder(c.practices.first, [0, 1, 2]), isFalse);
        await c.load();
      }
      expect(preferences.writes, isEmpty);
      expect(preferences.values, {_key: raw, _otherKey: 'conservar'});
      final decoded = await store.load();
      expect(decoded.achievements['L-10'], _date);
      expect(decoded.reviewAnswers, hasLength(3));

      final compatible = _json(raw);
      (compatible['achievements'] as Map).remove('L-10');
      final control = _Preferences(jsonEncode(compatible));
      final accepted = await _open(LocalProgressStore(preferences: control));
      expect(accepted.ready, isTrue);
      expect(accepted.pendingReview(accepted.questions), isEmpty);
      expect(accepted.points, 10);
      expect(accepted.earnedAchievements.keys, ['L-01', 'L-03']);
      expect(control.writes, isEmpty);
      expect(preferences.values[_key], raw);
    },
  );

  test(
    'MIG-03 G-01: every catalog ID rewards once across draft reloads',
    () async {
      // progress_test.dart CU02 y wp14_cu05_cu10_test.dart TG-S2-007 ya cubren
      // repetición/reapertura del primer ID. Variante: TODOS los IDs, con
      // reaperturas de borrador y de orden incorrecto antes de completarlos.
      final preferences = _Preferences();
      final store = LocalProgressStore(preferences: preferences);
      var c = await _open(store);
      final rewarded = <String>[];
      for (final practice in c.practices.toList()) {
        final order = List.generate(practice.steps.length, (i) => i);
        for (final draft in [order.take(1).toList(), order.reversed.toList()]) {
          expect(await c.saveOrder(practice, draft), isTrue);
          final raw = preferences.values[_key];
          final writes = preferences.writes.length;
          c = await _open(store);
          expect(c.ready, isTrue);
          expect(c.orderFor(practice), draft);
          expect(c.practiceCompleted(practice), isFalse);
          expect(c.points, rewarded.length * 10);
          expect(_json(raw!)['rewardedPractices'], rewarded);
          expect(preferences.values[_key], raw);
          expect(preferences.writes, hasLength(writes));
        }
        expect(await c.saveOrder(practice, order), isTrue);
        rewarded.add(practice.id);
        expect(c.points, rewarded.length * 10);
        expect(_json(preferences.values[_key]!)['rewardedPractices'], rewarded);
        final saved = preferences.values[_key];
        final writes = preferences.writes.length;
        expect(await c.saveOrder(practice, order), isTrue);
        c = await _open(store);
        expect(c.ready, isTrue);
        expect(await c.saveOrder(practice, order), isTrue);
        expect(c.points, rewarded.length * 10);
        expect(preferences.values[_key], saved);
        expect(preferences.writes, hasLength(writes));
        expect(c.newAchievements, isEmpty);
        expect(c.newThemes, isEmpty);
      }
      final practices = catalog
          .expand((m) => m.topics)
          .expand((t) => t.practices)
          .toList();
      expect(c.completedPractices, practices.length);
      expect(c.points, practices.length * LearningController.pointsPerPractice);
      expect(rewarded.toSet(), practices.map((p) => p.id).toSet());
      expect(preferences.writes.toSet(), {_key});
      expect(preferences.values[_otherKey], 'conservar');
    },
  );

  test(
    'MIG-04: third correct review preserves the entire reward snapshot',
    () async {
      // CP06-06 cubre tres aciertos y sprint2_test.dart un acierto con tema.
      // Variante faltante: comparar TODO el JSON salvo reviewAnswers en CADA
      // transición (incluido error de repaso), con 20 puntos, fechas y tema;
      // reabrir y repetir el tercer acierto tampoco escribe ni concede L-10.
      final store = MemoryStore();
      final c = await _open(store);
      final questions = c.questions.take(3).toList();
      for (final q in questions) {
        expect(
          await c.answer(q, (q.correctIndex + 1) % q.options.length),
          isTrue,
        );
      }
      for (final p in c.practices.take(2)) {
        expect(
          await c.saveOrder(p, List.generate(p.steps.length, (i) => i)),
          isTrue,
        );
      }
      expect(await c.selectTheme('U-01'), isTrue);
      final before = _json(store.raw!)..remove('reviewAnswers');
      expect(before['points'], 20);
      expect(before['rewardedPractices'], hasLength(2));
      expect((before['achievements'] as Map).values, everyElement(isNotNull));
      final expectedReview = <String, int>{};
      final writesBefore = store.writes;
      final first = questions.first;
      final attempts = [
        (first, (first.correctIndex + 1) % first.options.length),
        for (final q in questions) (q, q.correctIndex),
      ];
      for (final (q, answer) in attempts) {
        expect(await c.reviewAnswer(q, answer), isTrue);
        expectedReview[q.id] = answer;
        final after = _json(store.raw!);
        expect(after.remove('reviewAnswers'), expectedReview);
        expect(after, before);
        expect(c.earnedAchievements, isNot(contains('L-10')));
        expect(c.newAchievements, isEmpty);
        expect(c.newThemes, isEmpty);
      }
      expect(store.writes, writesBefore + 4);
      final raw = store.raw;
      final reopened = await _open(store);
      expect(reopened.ready, isTrue);
      expect(
        await reopened.reviewAnswer(
          questions.last,
          questions.last.correctIndex,
        ),
        isFalse,
      );
      final restored = _json(store.raw!);
      expect(restored.remove('reviewAnswers'), expectedReview);
      expect(restored, before);
      expect(reopened.pendingReview(questions), isEmpty);
      expect(reopened.earnedAchievements, isNot(contains('L-10')));
      expect(store.writes, writesBefore + 4);
      expect(store.raw, raw);
    },
  );

  test(
    'MIG-05 G-03: migrated theme persists and reselection is read-only',
    () async {
      // sprint2_test.dart G03 y CP06-10 ya cubren selección/fallo/recreación.
      // Variante: desbloqueo histórico v2 bajo la clave real; tras recrear,
      // reseleccionar el mismo tema y pedir uno bloqueado no escriben.
      final preferences = _Preferences(_fixtures[2]);
      final store = LocalProgressStore(preferences: preferences);
      final c = await _open(store);
      expect(c.ready, isTrue);
      expect(await c.selectTheme('U-01'), isTrue);
      final raw = preferences.values[_key]!;
      final changed = _json(raw)..remove('selectedTheme');
      expect(preferences.writes, [_key]);
      final reopened = await _open(store);
      expect(reopened.ready, isTrue);
      expect(reopened.selectedTheme, 'U-01');
      expect(await reopened.selectTheme('U-01'), isTrue);
      expect(await reopened.selectTheme('U-03'), isFalse);
      expect(reopened.selectedTheme, 'U-01');
      expect(
        _json(preferences.values[_key]!)..remove('selectedTheme'),
        changed,
      );
      expect(preferences.values[_key], raw);
      expect(preferences.values[_otherKey], 'conservar');
      expect(preferences.writes, [_key]);
    },
  );
}

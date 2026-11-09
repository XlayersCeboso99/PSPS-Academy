import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:psps/core/content/catalog.dart';
import 'package:psps/core/content/catalog_legacy.dart';
import 'package:psps/core/learning/learning_controller.dart';
import 'package:psps/core/models/course.dart';
import 'package:psps/core/persistence/progress_store.dart';
import 'package:psps/features/notes/notes_store.dart';
import 'package:psps/features/reminders/reminder_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../support.dart';

final _topics = catalog.expand((m) => m.topics).toList();
final _lessons = _topics.expand((t) => t.lessons).toList();
final _questions = _lessons.expand((l) => l.questions).toList();
final _practices = _topics.expand((t) => t.practices).toList();
final _legacyQuestions = _questions
    .where((q) => legacyContentIds.contains(q.id))
    .toList();
final _legacyPractices = _practices
    .where((p) => legacyContentIds.contains(p.id))
    .toList();

String _normalize(String text) {
  const accents = 'áàâäãåéèêëíìîïóòôöõúùûüñç';
  const plain = 'aaaaaaeeeeiiiiooooouuuunc';
  return text
      .toLowerCase()
      .trim()
      .split('')
      .map((char) {
        final index = accents.indexOf(char);
        return index < 0 ? char : plain[index];
      })
      .join()
      .replaceAll(RegExp(r'[\u0300-\u036f]'), '');
}

List<int> _solved(Practice practice) =>
    List.generate(practice.steps.length, (index) => index);

Future<LearningController> _open(ProgressStore store) async {
  final controller = LearningController(modules: catalog, store: store);
  addTearDown(controller.dispose);
  await controller.load();
  expect(controller.ready, isTrue, reason: controller.loadError);
  expect(controller.loadError, isNull);
  return controller;
}

void main() {
  test('EXP-01: expanded inventory has unique IDs across every level', () {
    expect(catalog, hasLength(4));
    expect(_topics, hasLength(10));
    expect(_questions.length, greaterThanOrEqualTo(40));
    expect(_practices.length, greaterThanOrEqualTo(20));
    final ids = [
      ...catalog.map((m) => m.id),
      ..._topics.map((t) => t.id),
      ..._lessons.map((l) => l.id),
      ..._questions.map((q) => q.id),
      ..._practices.map((p) => p.id),
    ];
    expect(ids.toSet(), hasLength(ids.length));
  });

  test(
    'EXP-02: every question has distinct options and an explained answer',
    () {
      final prompts = <String>{};
      for (final question in _questions) {
        final options = question.options.map(_normalize).toList();
        expect(options.length, greaterThanOrEqualTo(3), reason: question.id);
        expect(options, everyElement(isNotEmpty), reason: question.id);
        expect(options.toSet(), hasLength(options.length), reason: question.id);
        expect(
          question.correctIndex,
          inInclusiveRange(0, options.length - 1),
          reason: question.id,
        );
        final prompt = _normalize(question.prompt);
        final explanation = _normalize(question.explanation);
        expect(prompt, isNotEmpty, reason: question.id);
        expect(explanation, isNotEmpty, reason: question.id);
        expect(explanation, isNot(prompt), reason: question.id);
        expect(
          prompts.add(prompt),
          isTrue,
          reason: 'Enunciado duplicado: ${question.id}',
        );
      }
    },
  );

  test(
    'EXP-03: every activity has unique steps and a shuffled presentation',
    () {
      final titles = <String>{};
      for (final practice in _practices) {
        expect(_normalize(practice.title), isNotEmpty, reason: practice.id);
        expect(
          _normalize(practice.instruction),
          isNotEmpty,
          reason: practice.id,
        );
        expect(
          titles.add(_normalize(practice.title)),
          isTrue,
          reason: practice.id,
        );
        final steps = practice.steps.map(_normalize).toList();
        expect(steps.length, greaterThanOrEqualTo(3), reason: practice.id);
        expect(steps, everyElement(isNotEmpty), reason: practice.id);
        expect(steps.toSet(), hasLength(steps.length), reason: practice.id);
        final canonical = _solved(practice);
        expect(
          practice.presentationOrder,
          unorderedEquals(canonical),
          reason: practice.id,
        );
        expect(
          practice.presentationOrder,
          isNot(orderedEquals(canonical)),
          reason: practice.id,
        );
        expect(
          practice.presentationOrder,
          isNot(orderedEquals(canonical.reversed)),
          reason: practice.id,
        );
      }
    },
  );

  test('EXP-04: new correct answers use more than one option position', () {
    final added = _questions.where((q) => !legacyContentIds.contains(q.id));
    expect(added, isNotEmpty);
    expect(added.map((q) => q.correctIndex).toSet().length, greaterThan(1));
  });

  test(
    'EXP-05: real expanded catalog preserves a complete v3 legacy user',
    () async {
      expect(_legacyQuestions, hasLength(20));
      expect(_legacyPractices, hasLength(10));
      final dates = {
        for (final id in [1, 2, 3, 4, 5, 6, 7, 8, 9, 11])
          'L-${id.toString().padLeft(2, '0')}': DateTime.utc(
            2026,
            10,
            22,
            16,
            id,
          ).toIso8601String(),
      };
      final before = ProgressSnapshot(
        answers: {for (final q in _legacyQuestions) q.id: q.correctIndex},
        practices: {for (final p in _legacyPractices) p.id: _solved(p)},
        points: 100,
        rewardedPractices: _legacyPractices.map((p) => p.id).toList(),
        achievements: dates,
        selectedTheme: 'U-03',
      );
      final store = MemoryStore();
      await store.save(before);
      final originalJson = store.raw;
      final originalWrites = store.writes;
      final controller = await _open(store);
      expect(controller.answeredCount, before.answers.length);
      expect(controller.completedPractices, before.practices.length);
      expect(controller.progress, before.answers.length / _questions.length);
      expect(controller.points, 100);
      expect(controller.earnedAchievements, dates);
      expect(controller.selectedTheme, 'U-03');
      expect(controller.newAchievements, isEmpty);
      expect(controller.newThemes, isEmpty);
      expect(store.raw, originalJson);
      expect(store.writes, originalWrites);

      final added = _practices.firstWhere((p) => p.id.endsWith('.a2'));
      expect(await controller.saveOrder(added, _solved(added)), isTrue);
      expect(controller.points, 110);
      expect(controller.earnedAchievements, dates);
      expect(controller.earnedAchievements['L-05'], dates['L-05']);
      expect(controller.selectedTheme, 'U-03');
      final expected = jsonDecode(before.encode()) as Map<String, dynamic>;
      expected['points'] = 110;
      (expected['practices'] as Map)[added.id] = _solved(added);
      // El formato guarda los IDs recompensados en el orden del catálogo.
      // Se conservan todos los anteriores y se agrega exactamente el nuevo.
      expected['rewardedPractices'] = [
        for (final practice in _practices)
          if (before.rewardedPractices.contains(practice.id) ||
              practice.id == added.id)
            practice.id,
      ];
      expect(jsonDecode(store.raw!), expected);
      expect(expected['version'], 3);
      expect(store.writes, originalWrites + 1);

      final saved = store.raw;
      expect(await controller.saveOrder(added, _solved(added)), isTrue);
      final reopened = await _open(store);
      expect(await reopened.saveOrder(added, _solved(added)), isTrue);
      expect(reopened.points, 110);
      expect(reopened.earnedAchievements, dates);
      expect(reopened.selectedTheme, 'U-03');
      expect(reopened.newAchievements, isEmpty);
      expect(reopened.newThemes, isEmpty);
      expect(store.raw, saved);
      expect(store.writes, originalWrites + 1);
      expect(jsonDecode(store.raw!), expected);
    },
  );

  test(
    'EXP-06: a new user earns L-05 only with all current activities',
    () async {
      final store = MemoryStore();
      var controller = await _open(store);
      for (final practice in _legacyPractices) {
        expect(await controller.saveOrder(practice, _solved(practice)), isTrue);
      }
      expect(controller.completedPractices, _legacyPractices.length);
      expect(controller.earnedAchievements, isNot(contains('L-05')));
      controller = await _open(store);
      expect(controller.earnedAchievements, isNot(contains('L-05')));
      final added = _practices
          .where((p) => !legacyContentIds.contains(p.id))
          .toList();
      for (final practice in added) {
        expect(controller.earnedAchievements, isNot(contains('L-05')));
        expect(await controller.saveOrder(practice, _solved(practice)), isTrue);
      }
      expect(controller.completedPractices, _practices.length);
      expect(controller.earnedAchievements['L-05'], isNotNull);
      expect(
        DateTime.tryParse(controller.earnedAchievements['L-05']!),
        isNotNull,
      );
      final date = controller.earnedAchievements['L-05'];
      controller = await _open(store);
      expect(controller.earnedAchievements['L-05'], date);
    },
  );

  test(
    'EXP-07: new content writes preserve notes and reminder JSON exactly',
    () async {
      final previous = SharedPreferencesAsyncPlatform.instance;
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      addTearDown(() => SharedPreferencesAsyncPlatform.instance = previous);
      final preferences = SharedPreferencesAsync();
      final lesson = _lessons.first;
      await LocalNotesStore().save({
        lesson.id: PersonalNote(
          lessonId: lesson.id,
          text: 'Nota previa a la ampliación',
          modifiedAt: DateTime.utc(2026, 10, 22),
        ),
      });
      await LocalReminderStore().save(
        const ReminderSettings(
          enabled: true,
          hour: 19,
          minute: 15,
          weekdays: {1, 4},
        ),
      );
      final notes = await preferences.getString('psps.notes.v1');
      final reminder = await preferences.getString('psps.reminder.v1');
      expect(notes, isNotNull);
      expect(reminder, isNotNull);
      final controller = await _open(LocalProgressStore());
      Future<void> expectIsolated() async {
        expect(await preferences.getString('psps.notes.v1'), notes);
        expect(await preferences.getString('psps.reminder.v1'), reminder);
        expect(await preferences.getKeys(), {
          'psps.notes.v1',
          'psps.reminder.v1',
          'psps.progress.v1',
        });
      }

      for (final question in _questions.where(
        (q) => !legacyContentIds.contains(q.id),
      )) {
        expect(
          await controller.answer(question, question.correctIndex),
          isTrue,
        );
        await expectIsolated();
      }
      for (final practice in _practices.where(
        (p) => !legacyContentIds.contains(p.id),
      )) {
        expect(await controller.saveOrder(practice, _solved(practice)), isTrue);
        await expectIsolated();
      }
      final reopened = await _open(LocalProgressStore());
      expect(
        reopened.answeredCount,
        _questions.length - _legacyQuestions.length,
      );
      expect(
        reopened.completedPractices,
        _practices.length - _legacyPractices.length,
      );
      await expectIsolated();
    },
  );
}

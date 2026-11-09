import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psps/core/content/catalog.dart';
import 'package:psps/core/learning/learning_controller.dart';
import 'package:psps/core/persistence/progress_store.dart';
import 'package:psps/features/notes/notes_controller.dart';
import 'package:psps/features/notes/notes_store.dart';
import 'package:psps/features/reminders/reminder_controller.dart';
import 'package:psps/features/reminders/reminder_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
// La interfaz de plataforma es una dependencia transitiva de shared_preferences.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const _progressKey = 'psps.progress.v1';

class _Notifications implements NotificationPort {
  final Set<int> scheduled = {};

  @override
  Future<void> initialize({required VoidCallback onOpened}) async {}

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> scheduleDay({
    required int weekday,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    scheduled.add(weekday);
  }

  @override
  Future<void> cancelDay(int weekday) async {
    scheduled.remove(weekday);
  }

  @override
  Future<bool> openNotificationSettings() async => true;
}

Future<LearningController> _openLearning() async {
  final learning = LearningController(
    modules: catalog,
    store: LocalProgressStore(),
  );
  addTearDown(learning.dispose);
  await learning.load();
  return learning;
}

Future<LearningController> _seedProgress() async {
  final learning = await _openLearning();
  expect(learning.ready, isTrue);
  final lesson = catalog.first.topics.first.lessons.first;
  expect(
    await learning.answer(
      lesson.questions.first,
      lesson.questions.first.correctIndex,
    ),
    isTrue,
  );
  final practice = learning.practices.first;
  expect(
    await learning.saveOrder(
      practice,
      List<int>.generate(practice.steps.length, (index) => index),
    ),
    isTrue,
  );
  expect(learning.points, greaterThan(0));
  expect(learning.earnedAchievements, isNotEmpty);
  return learning;
}

Future<void> _expectProgressUnchanged(
  SharedPreferencesAsync preferences,
  LearningController learning,
  String before,
  int points,
  Map<String, String?> achievements,
) async {
  expect(await preferences.getString(_progressKey), before);
  expect(learning.points, points);
  expect(learning.earnedAchievements, achievements);
  await learning.load();
  expect(learning.ready, isTrue);
  expect(learning.loadError, isNull);
  expect(learning.points, points);
  expect(learning.earnedAchievements, achievements);
  expect(await preferences.getString(_progressKey), before);
}

void main() {
  late SharedPreferencesAsync preferences;
  final lesson = catalog.first.topics.first.lessons.first;

  setUp(() {
    final previousPlatform = SharedPreferencesAsyncPlatform.instance;
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    addTearDown(() {
      SharedPreferencesAsyncPlatform.instance = previousPlatform;
    });
    preferences = SharedPreferencesAsync();
  });

  test(
    'CU-11 aislamiento: guardar, editar y eliminar conserva avance y premios',
    () async {
      final learning = await _seedProgress();
      final before = (await preferences.getString(_progressKey))!;
      final points = learning.points;
      final achievements = Map<String, String?>.of(learning.earnedAchievements);
      final notes = NotesController(modules: catalog, store: LocalNotesStore());
      addTearDown(notes.dispose);
      await notes.load();
      expect(notes.ready, isTrue);

      expect(await notes.saveNote(lesson, 'Primera nota'), isTrue);
      expect(notes.noteFor(lesson)!.text, 'Primera nota');
      await _expectProgressUnchanged(
        preferences,
        learning,
        before,
        points,
        achievements,
      );
      expect(await notes.saveNote(lesson, 'Nota editada'), isTrue);
      expect(notes.noteFor(lesson)!.text, 'Nota editada');
      await _expectProgressUnchanged(
        preferences,
        learning,
        before,
        points,
        achievements,
      );
      expect(await notes.deleteNote(lesson), isTrue);
      expect(await LocalNotesStore().load(), isEmpty);
      await _expectProgressUnchanged(
        preferences,
        learning,
        before,
        points,
        achievements,
      );
    },
  );

  test(
    'CU-12 aislamiento: guardar y desactivar conserva avance y premios',
    () async {
      final learning = await _seedProgress();
      final before = (await preferences.getString(_progressKey))!;
      final points = learning.points;
      final achievements = Map<String, String?>.of(learning.earnedAchievements);
      final notifications = _Notifications();
      final reminder = ReminderController(
        store: LocalReminderStore(),
        port: notifications,
      );
      addTearDown(reminder.dispose);
      await reminder.load();
      expect(reminder.ready, isTrue);

      expect(
        await reminder.apply(
          const ReminderSettings(
            enabled: true,
            hour: 19,
            minute: 15,
            weekdays: {1, 4},
          ),
        ),
        ReminderResult.saved,
      );
      expect(notifications.scheduled, {1, 4});
      expect((await LocalReminderStore().load()).enabled, isTrue);
      await _expectProgressUnchanged(
        preferences,
        learning,
        before,
        points,
        achievements,
      );
      expect(
        await reminder.apply(ReminderSettings.initial),
        ReminderResult.disabled,
      );
      expect(notifications.scheduled, isEmpty);
      expect((await LocalReminderStore().load()).enabled, isFalse);
      await _expectProgressUnchanged(
        preferences,
        learning,
        before,
        points,
        achievements,
      );
    },
  );

  test(
    'CU-11/CU-12 claves exactas y separadas de persistencia local',
    () async {
      expect(LocalProgressStore.storageKey, _progressKey);
      expect(LocalNotesStore.storageKey, 'psps.notes.v1');
      expect(LocalReminderStore.storageKey, 'psps.reminder.v1');

      await LocalNotesStore().save({
        lesson.id: PersonalNote(
          lessonId: lesson.id,
          text: 'Nota independiente',
          modifiedAt: DateTime.utc(2026, 11, 9),
        ),
      });
      expect(await preferences.getKeys(), {'psps.notes.v1'});
      final notesBefore = await preferences.getString('psps.notes.v1');
      expect(notesBefore, isNotNull);
      await LocalReminderStore().save(
        const ReminderSettings(enabled: true, weekdays: {2}),
      );
      expect(await preferences.getKeys(), {
        'psps.notes.v1',
        'psps.reminder.v1',
      });
      expect(await preferences.getString('psps.notes.v1'), notesBefore);
      expect(await preferences.getString('psps.reminder.v1'), isNotNull);
      expect(await preferences.getString(_progressKey), isNull);
    },
  );

  test(
    'CU-11 aislamiento: notas corruptas no impiden cargar el avance',
    () async {
      final learning = await _seedProgress();
      final before = (await preferences.getString(_progressKey))!;
      final points = learning.points;
      final achievements = Map<String, String?>.of(learning.earnedAchievements);
      await preferences.setString('psps.notes.v1', '{notas-corruptas');
      final notes = NotesController(modules: catalog, store: LocalNotesStore());
      addTearDown(notes.dispose);
      await notes.load();
      expect(notes.ready, isFalse);
      expect(notes.loadError, isNotNull);
      expect(await notes.saveNote(lesson, 'No sobrescribir'), isFalse);

      final reopened = await _openLearning();
      await _expectProgressUnchanged(
        preferences,
        reopened,
        before,
        points,
        achievements,
      );
      expect(await preferences.getString('psps.notes.v1'), '{notas-corruptas');
    },
  );

  test(
    'CU-11 aislamiento: avance corrupto no impide cargar y guardar notas',
    () async {
      final original = NotesController(
        modules: catalog,
        store: LocalNotesStore(),
      );
      addTearDown(original.dispose);
      await original.load();
      expect(await original.saveNote(lesson, 'Nota recuperable'), isTrue);
      final notesBefore = await preferences.getString('psps.notes.v1');
      await preferences.setString(_progressKey, '{avance-corrupto');

      final learning = await _openLearning();
      expect(learning.ready, isFalse);
      expect(learning.loadError, isNotNull);
      final notes = NotesController(modules: catalog, store: LocalNotesStore());
      addTearDown(notes.dispose);
      await notes.load();
      expect(notes.ready, isTrue);
      expect(notes.loadError, isNull);
      expect(notes.noteFor(lesson)!.text, 'Nota recuperable');
      expect(await preferences.getString('psps.notes.v1'), notesBefore);
      expect(
        await notes.saveNote(lesson, 'Nota editada con avance corrupto'),
        isTrue,
      );
      expect(notes.noteFor(lesson)!.text, 'Nota editada con avance corrupto');
      expect(await preferences.getString(_progressKey), '{avance-corrupto');
      expect(await notes.deleteNote(lesson), isTrue);
      expect(await LocalNotesStore().load(), isEmpty);
      expect(await preferences.getString(_progressKey), '{avance-corrupto');
    },
  );
}

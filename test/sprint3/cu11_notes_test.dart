import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psps/core/content/catalog.dart';
import 'package:psps/features/notes/notes_store.dart';
import 'package:psps/core/learning/learning_controller.dart';
import 'package:psps/features/notes/notes_controller.dart';
import 'package:psps/app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_test.dart' show tapVisible;
import '../support.dart';

class MemoryPreferences implements SharedPreferencesAsync {
  final Map<String, String> values = {};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MemoryNotesStore implements NotesStore {
  Map<String, PersonalNote> notes = {};
  bool failSave = false;
  bool failLoad = false;
  Completer<void>? pending;
  Completer<void>? pendingLoad;

  @override
  Future<Map<String, PersonalNote>> load() async {
    if (pendingLoad != null) await pendingLoad!.future;
    if (failLoad) throw StateError('Read failed');
    return Map.of(notes);
  }

  @override
  Future<void> save(Map<String, PersonalNote> value) async {
    if (pending != null) await pending!.future;
    if (failSave) throw StateError('Write failed');
    notes = Map.of(value);
  }
}

void main() {
  final module = catalog.first;
  final topic = module.topics.first;
  final lesson = topic.lessons.first;
  late MemoryNotesStore store;
  late NotesController notes;

  setUp(() async {
    store = MemoryNotesStore();
    notes = NotesController(modules: catalog, store: store);
    await notes.load();
  });

  test(
    'local store roundtrip preserves text, timestamp and progress key',
    () async {
      final preferences = MemoryPreferences();
      preferences.values['psps.progress.v1'] = 'Existing progress';
      final local = LocalNotesStore(preferences: preferences);
      expect(await local.load(), isEmpty);
      final modified = DateTime.utc(2026, 11, 8, 18, 30);
      await local.save({
        lesson.id: PersonalNote(
          lessonId: lesson.id,
          text: 'Nota con ñ y 👩‍💻\nSegunda línea',
          modifiedAt: modified,
        ),
      });
      final loaded = await LocalNotesStore(preferences: preferences).load();
      expect(loaded[lesson.id]!.text, 'Nota con ñ y 👩‍💻\nSegunda línea');
      expect(loaded[lesson.id]!.modifiedAt, modified);
      expect(preferences.values['psps.progress.v1'], 'Existing progress');
      await local.save({});
      expect(await local.load(), isEmpty);
    },
  );

  test('ID23 closing the app during notes load completes safely', () async {
    store.pendingLoad = Completer<void>();
    final controller = NotesController(modules: catalog, store: store);
    final loading = controller.load();
    controller.dispose();
    store.pendingLoad!.complete();
    await expectLater(loading, completes);
  });

  test(
    'ID23 closing the app during save preserves the completed write',
    () async {
      store.pending = Completer<void>();
      final saving = notes.saveNote(lesson, 'Nota al cerrar');
      notes.dispose();
      store.pending!.complete();
      expect(await saving, isTrue);
      expect(store.notes[lesson.id]!.text, 'Nota al cerrar');
    },
  );

  test(
    'unreadable stored notes block writes and can be loaded again',
    () async {
      final preferences = MemoryPreferences();
      preferences.values[LocalNotesStore.storageKey] = '{broken';
      final controller = NotesController(
        modules: catalog,
        store: LocalNotesStore(preferences: preferences),
      );
      await controller.load();
      expect(controller.ready, isFalse);
      expect(controller.loadError, isNotNull);
      expect(await controller.saveNote(lesson, 'Overwrite'), isFalse);
      expect(preferences.values[LocalNotesStore.storageKey], '{broken');
      preferences.values[LocalNotesStore.storageKey] =
          '{"version":1,"notes":{}}';
      await controller.load();
      expect(controller.ready, isTrue);
    },
  );

  test(
    'CA-12 create, edit, restore and delete without changing progress',
    () async {
      final progressStore = MemoryStore();
      final learning = LearningController(
        modules: catalog,
        store: progressStore,
      );
      await learning.load();
      await learning.answer(lesson.questions.first, 0);
      final before = progressStore.raw;
      expect(await notes.saveNote(lesson, 'a'), isTrue);
      final firstDate = notes.noteFor(lesson)!.modifiedAt;
      expect(await notes.saveNote(lesson, 'Mi nota editada'), isTrue);
      expect(notes.noteFor(lesson)!.modifiedAt.isBefore(firstDate), isFalse);
      final restored = NotesController(modules: catalog, store: store);
      await restored.load();
      expect(restored.noteFor(lesson)!.text, 'Mi nota editada');
      expect(await restored.deleteNote(lesson), isTrue);
      await restored.load();
      expect(restored.noteFor(lesson), isNull);
      expect(progressStore.raw, before);
    },
  );

  test('CA-12 validates empty input and Unicode length boundaries', () async {
    expect(await notes.saveNote(lesson, ' \n '), isFalse);
    expect(await notes.saveNote(lesson, 'a' * 1000), isTrue);
    expect(await notes.saveNote(lesson, 'a' * 1001), isFalse);
    expect(await notes.saveNote(lesson, '👩‍💻' * 1000), isTrue);
    expect(await notes.saveNote(lesson, '👩‍💻' * 1001), isFalse);
  });

  test(
    'E1 failed save/delete preserves previous note and allows retry',
    () async {
      await notes.saveNote(lesson, 'Original');
      store.failSave = true;
      expect(await notes.saveNote(lesson, 'Cambio'), isFalse);
      expect(notes.noteFor(lesson)!.text, 'Original');
      expect(await notes.deleteNote(lesson), isFalse);
      expect(store.notes[lesson.id]!.text, 'Original');
      store.failSave = false;
      expect(await notes.saveNote(lesson, 'Cambio'), isTrue);
      expect(notes.noteFor(lesson)!.text, 'Cambio');
    },
  );

  test('E2 hidden orphan notes survive saving another subtopic', () async {
    store.notes['retired-subtopic'] = PersonalNote(
      lessonId: 'retired-subtopic',
      text: 'Conservar',
      modifiedAt: DateTime.utc(2026, 1, 1),
    );
    await notes.load();
    expect(notes.visibleNotes, isEmpty);
    await notes.saveNote(lesson, 'Visible');
    expect(notes.visibleNotes.single.lesson, lesson);
    expect(store.notes['retired-subtopic']!.text, 'Conservar');
  });

  test(
    'notes sorted by most recently modified and concurrent writes guarded',
    () async {
      final other = module.topics[1].lessons.first;
      store.notes = {
        lesson.id: PersonalNote(
          lessonId: lesson.id,
          text: 'Vieja',
          modifiedAt: DateTime.utc(2026),
        ),
        other.id: PersonalNote(
          lessonId: other.id,
          text: 'Nueva',
          modifiedAt: DateTime.utc(2026, 2),
        ),
      };
      await notes.load();
      expect(notes.visibleNotes.first.lesson, other);
      store.pending = Completer<void>();
      final write = notes.saveNote(lesson, 'Actualizada');
      expect(await notes.saveNote(other, 'No guardar en paralelo'), isFalse);
      store.pending!.complete();
      expect(await write, isTrue);
      expect(notes.visibleNotes.first.lesson, lesson);
      expect(notes.noteFor(other)!.text, 'Nueva');
    },
  );

  testWidgets('CU-11 normal entry points save, edit, discard and delete', (
    tester,
  ) async {
    final learning = LearningController(modules: catalog, store: MemoryStore());
    await learning.load();
    await tester.pumpWidget(
      PspsApp(controller: learning, notesController: notes),
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Mis notas'));
    expect(
      find.text('Aún no tienes notas. Agrega una desde cualquier subtema'),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text(module.title));
    await tapVisible(tester, find.byKey(ValueKey('cu05.lesson.${lesson.id}')));
    await tapVisible(tester, find.text('Estudiar subtema'));
    await tapVisible(tester, find.text('Agregar nota'));
    expect(find.text('0/1000'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Guardar'))
          .onPressed,
      isNull,
    );
    await tester.enterText(find.byType(TextField), 'Primera nota');
    await tapVisible(tester, find.text('Guardar'));
    expect(find.text('Ver mi nota'), findsOneWidget);
    await tapVisible(tester, find.text('Ver mi nota'));
    await tester.enterText(find.byType(TextField), 'Sin guardar');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar los cambios?'), findsOneWidget);
    await tapVisible(tester, find.text('Seguir editando'));
    expect(find.text('Sin guardar'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Descartar'));
    expect(notes.noteFor(lesson)!.text, 'Primera nota');
    await tapVisible(tester, find.text('Ver mi nota'));
    await tapVisible(tester, find.text('Eliminar nota'));
    await tapVisible(tester, find.text('Cancelar'));
    expect(notes.noteFor(lesson), isNotNull);
    await tapVisible(tester, find.text('Eliminar nota'));
    await tapVisible(tester, find.text('Eliminar'));
    expect(notes.noteFor(lesson), isNull);
    expect(find.text('Agregar nota'), findsOneWidget);
  });

  testWidgets('A5 opens subtopic editor from list; failed save retains text', (
    tester,
  ) async {
    await notes.saveNote(lesson, 'Guardada');
    final learning = LearningController(modules: catalog, store: MemoryStore());
    await learning.load();
    await tester.pumpWidget(
      PspsApp(controller: learning, notesController: notes),
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Mis notas'));
    await tapVisible(tester, find.text(lesson.title));
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Cambio pendiente');
    store.failSave = true;
    await tapVisible(tester, find.text('Guardar'));
    expect(
      find.text('No se pudo guardar la nota. Intenta de nuevo.'),
      findsOneWidget,
    );
    expect(find.text('Cambio pendiente'), findsOneWidget);
    expect(notes.noteFor(lesson)!.text, 'Guardada');
    store.failSave = false;
    await tapVisible(tester, find.text('Guardar'));
    expect(find.text('Ver mi nota'), findsOneWidget);
  });

  testWidgets(
    'ID23 delayed load preserves saved text and enforces editor limit',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      store.notes[lesson.id] = PersonalNote(
        lessonId: lesson.id,
        text: 'Nota existente',
        modifiedAt: DateTime.utc(2026),
      );
      store.pendingLoad = Completer<void>();
      final loading = notes.load();
      final learning = LearningController(
        modules: catalog,
        store: MemoryStore(),
      );
      await learning.load();
      await tester.pumpWidget(
        PspsApp(controller: learning, notesController: notes),
      );
      await tester.pumpAndSettle();
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .push(
            MaterialPageRoute<void>(
              builder: (_) => NoteEditorScreen(lesson: lesson),
            ),
          );
      await tester.pumpAndSettle();
      expect(find.text('Cargando tus notas…'), findsOneWidget);
      store.pendingLoad!.complete();
      await loading;
      await tester.pumpAndSettle();
      expect(find.text('Nota existente'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'ñ' * 1001);
      await tester.pumpAndSettle();
      expect(find.text('1000/1000'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byType(TextField))
            .controller!
            .text
            .length,
        1000,
      );
      await tapVisible(tester, find.text('Guardar'));
      expect(notes.noteFor(lesson)!.text, 'ñ' * 1000);
      await tapVisible(tester, find.text('Mis notas'));
      expect(find.text(lesson.title), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('ID23 local persistence survives app relaunch and list updates', (
    tester,
  ) async {
    final preferences = MemoryPreferences();
    final progressStore = MemoryStore();
    var learning = LearningController(modules: catalog, store: progressStore);
    await learning.load();
    await learning.answer(lesson.questions.first, 0);
    final progressBefore = progressStore.raw;
    var controller = NotesController(
      modules: catalog,
      store: LocalNotesStore(preferences: preferences),
    );
    await controller.load();
    await controller.saveNote(lesson, 'Texto inicial');
    await tester.pumpWidget(
      PspsApp(controller: learning, notesController: controller),
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Mis notas'));
    await tapVisible(tester, find.text(lesson.title));
    await tester.enterText(find.byType(TextField), 'Texto editado');
    await tapVisible(tester, find.text('Guardar'));
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Texto editado'), findsOneWidget);
    expect(find.text('Texto inicial'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    learning.dispose();
    controller = NotesController(
      modules: catalog,
      store: LocalNotesStore(preferences: preferences),
    );
    learning = LearningController(modules: catalog, store: progressStore);
    await learning.load();
    await controller.load();
    await tester.pumpWidget(
      PspsApp(controller: learning, notesController: controller),
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Mis notas'));
    expect(find.text('Texto editado'), findsOneWidget);
    await tapVisible(tester, find.text(lesson.title));
    await tapVisible(tester, find.text('Eliminar nota'));
    await tapVisible(tester, find.text('Eliminar'));
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      find.text('Aún no tienes notas. Agrega una desde cualquier subtema'),
      findsOneWidget,
    );
    expect(progressStore.raw, progressBefore);
    expect(await LocalNotesStore(preferences: preferences).load(), isEmpty);
  });
}

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

/// Dobles de prueba independientes; no escriben en el avance ni en el equipo.
class _NotesStore implements NotesStore {
  Map<String, PersonalNote> values = {};
  bool failLoad = false;
  bool failSave = false;
  Completer<void>? pendingSave;
  int writes = 0;

  @override
  Future<Map<String, PersonalNote>> load() async {
    if (failLoad) throw StateError('Lectura simulada');
    return Map<String, PersonalNote>.of(values);
  }

  @override
  Future<void> save(Map<String, PersonalNote> value) async {
    if (pendingSave != null) await pendingSave!.future;
    if (failSave) throw StateError('Escritura simulada');
    values = Map<String, PersonalNote>.of(value);
    writes++;
  }
}

class _Preferences implements SharedPreferencesAsync {
  final Map<String, String> entries = {};

  @override
  Future<String?> getString(String key) async => entries[key];

  @override
  Future<void> setString(String key, String value) async {
    entries[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final first = catalog.first.topics.first.lessons.first;
  final second = catalog.first.topics[1].lessons.first;

  late _NotesStore store;
  late NotesController notes;

  setUp(() async {
    store = _NotesStore();
    notes = NotesController(modules: catalog, store: store);
    await notes.load();
  });

  test('TU-S3-11-06 | editar reemplaza nota sin crear duplicados', () async {
    expect(await notes.saveNote(first, 'Primera versión'), isTrue);
    final initial = notes.noteFor(first)!.modifiedAt;
    expect(await notes.saveNote(first, 'Segunda versión'), isTrue);

    expect(store.values.length, 1);
    expect(store.values[first.id]!.text, 'Segunda versión');
    expect(notes.noteFor(first)!.modifiedAt.isBefore(initial), isFalse);
    expect(store.writes, 2);
  });

  test('TU-S3-11-19 | notas con misma fecha se ordenan por ID', () async {
    final sameDate = DateTime.utc(2026, 11, 9, 8);
    store.values = {
      second.id: PersonalNote(
        lessonId: second.id,
        text: 'Segunda',
        modifiedAt: sameDate,
      ),
      first.id: PersonalNote(
        lessonId: first.id,
        text: 'Primera',
        modifiedAt: sameDate,
      ),
    };
    await notes.load();

    final sorted = notes.visibleNotes.map((item) => item.lesson.id).toList();
    expect(sorted, [first.id, second.id]..sort());
    expect(store.writes, 0, reason: 'Listar notas es solo lectura');
  });

  test(
    'TU-S3-11-22 | fallo al crear no crea nota parcial y permite reintento',
    () async {
      store.failSave = true;
      expect(await notes.saveNote(first, 'Texto importante'), isFalse);
      expect(store.values, isEmpty);
      expect(notes.noteFor(first), isNull);
      expect(notes.saveError, contains('No se pudo guardar'));

      store.failSave = false;
      expect(await notes.saveNote(first, 'Texto importante'), isTrue);
      expect(notes.noteFor(first)!.text, 'Texto importante');
    },
  );

  test(
    'TU-S3-11-24 | JSON dañado o fecha inválida no se sobrescribe',
    () async {
      final prefs = _Preferences();
      final local = LocalNotesStore(preferences: prefs);
      for (final raw in [
        '{"version":2,"notes":{}}',
        '{"version":1,"notes":{"CT-01.s1":{"text":42,"modifiedAt":"2026-11-09"}}}',
        '{"version":1,"notes":{"CT-01.s1":{"text":"Texto","modifiedAt":"no-es-fecha"}}}',
      ]) {
        prefs.entries[LocalNotesStore.storageKey] = raw;
        final fresh = NotesController(modules: catalog, store: local);
        await fresh.load();
        expect(fresh.ready, isFalse);
        expect(fresh.loadError, isNotNull);
        expect(await fresh.saveNote(first, 'No sobrescribir'), isFalse);
        expect(prefs.entries[LocalNotesStore.storageKey], raw);
        fresh.dispose();
      }
    },
  );

  test('TU-S3-11-25 | guardado pendiente bloquea otra escritura', () async {
    store.pendingSave = Completer<void>();
    final firstWrite = notes.saveNote(first, 'Guardado lento');
    expect(notes.saving, isTrue);
    expect(await notes.saveNote(second, 'No simultáneo'), isFalse);
    expect(store.values, isEmpty);

    store.pendingSave!.complete();
    expect(await firstWrite, isTrue);
    expect(notes.saving, isFalse);
    expect(store.values.keys.toSet(), {first.id});
  });

  testWidgets('TW-S3-11-18 | Mis notas accesible desde Mi progreso', (
    tester,
  ) async {
    final learning = LearningController(modules: catalog, store: MemoryStore());
    await learning.load();
    await tester.pumpWidget(
      PspsApp(controller: learning, notesController: notes),
    );
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Mi progreso'));
    await tapVisible(tester, find.text('Mis notas'));
    expect(
      find.text('Aún no tienes notas. Agrega una desde cualquier subtema'),
      findsOneWidget,
    );
    expect(store.writes, 0, reason: 'Consultar no debe escribir');
  });

  testWidgets('TW-S3-11-23 | fallo al eliminar conserva la nota y el editor', (
    tester,
  ) async {
    await notes.saveNote(first, 'Nota que debe conservarse');
    store.failSave = true;
    await tester.pumpWidget(
      NotesScope(
        controller: notes,
        child: MaterialApp(home: NoteEditorScreen(lesson: first)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Eliminar nota'));
    await tester.pumpAndSettle();
    expect(find.text('¿Eliminar esta nota?'), findsOneWidget);
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(
      find.text('No se pudo eliminar la nota. Intenta de nuevo.'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsOneWidget);
    expect(notes.noteFor(first)!.text, 'Nota que debe conservarse');
  });

  testWidgets('TW-S3-11-18 | error de lectura ofrece Reintentar', (
    tester,
  ) async {
    store.failLoad = true;
    await notes.load();
    final learning = LearningController(modules: catalog, store: MemoryStore());
    await learning.load();
    await tester.pumpWidget(
      NotesScope(
        controller: notes,
        child: MaterialApp(home: NotesScreen(controller: learning)),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('No se pudieron cargar tus notas. Intenta de nuevo.'),
      findsOneWidget,
    );

    store.failLoad = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(notes.ready, isTrue);
    expect(
      find.text('Aún no tienes notas. Agrega una desde cualquier subtema'),
      findsOneWidget,
    );
  });
}

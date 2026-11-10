import 'package:flutter/widgets.dart';

import 'package:psps/core/models/course.dart';
import 'package:psps/features/notes/notes_store.dart';

class NotedLesson {
  const NotedLesson(this.module, this.topic, this.lesson, this.note);
  final CourseModule module;
  final Topic topic;
  final Lesson lesson;
  final PersonalNote note;
}

class NotesController extends ChangeNotifier {
  NotesController({required this.modules, required this.store});
  final List<CourseModule> modules;
  final NotesStore store;
  static const maxLength = 1000;
  Map<String, PersonalNote> _notes = {};
  bool ready = false;
  bool loading = false;
  bool saving = false;
  String? loadError;
  String? saveError;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  PersonalNote? noteFor(Lesson lesson) => _notes[lesson.id];

  List<NotedLesson> get visibleNotes {
    final result = [
      for (final module in modules)
        for (final topic in module.topics)
          for (final lesson in topic.lessons)
            if (_notes.containsKey(lesson.id))
              NotedLesson(module, topic, lesson, _notes[lesson.id]!),
    ];
    result.sort((a, b) {
      final date = b.note.modifiedAt.compareTo(a.note.modifiedAt);
      return date == 0 ? a.lesson.id.compareTo(b.lesson.id) : date;
    });
    return result;
  }

  Future<void> load() async {
    if (_disposed || loading || saving) return;
    loading = true;
    ready = false;
    loadError = null;
    notifyListeners();
    try {
      final notes = await store.load();
      for (final note in notes.values) {
        if (note.text.trim().isEmpty ||
            note.text.characters.length > maxLength) {
          throw const FormatException('Texto de nota inválido');
        }
      }
      _notes = Map.of(notes);
      ready = true;
    } catch (_) {
      loadError = 'No se pudieron cargar tus notas. Intenta de nuevo.';
    } finally {
      loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> saveNote(Lesson lesson, String text) async {
    if (text.trim().isEmpty || text.characters.length > maxLength) return false;
    return _commit(
      lesson,
      PersonalNote(
        lessonId: lesson.id,
        text: text,
        modifiedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<bool> deleteNote(Lesson lesson) => _commit(lesson, null);

  Future<bool> _commit(Lesson lesson, PersonalNote? note) async {
    if (_disposed ||
        !ready ||
        saving ||
        !modules
            .expand((m) => m.topics)
            .expand((t) => t.lessons)
            .any((item) => identical(item, lesson))) {
      return false;
    }
    saving = true;
    saveError = null;
    notifyListeners();
    final next = Map<String, PersonalNote>.of(_notes);
    if (note == null) {
      next.remove(lesson.id);
    } else {
      next[lesson.id] = note;
    }
    try {
      await store.save(next);
      _notes = next;
      return true;
    } catch (_) {
      saveError = note == null
          ? 'No se pudo eliminar la nota. Intenta de nuevo.'
          : 'No se pudo guardar la nota. Intenta de nuevo.';
      return false;
    } finally {
      saving = false;
      if (!_disposed) notifyListeners();
    }
  }
}

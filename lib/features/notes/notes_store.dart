import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PersonalNote {
  const PersonalNote({
    required this.lessonId,
    required this.text,
    required this.modifiedAt,
  });

  final String lessonId;
  final String text;
  final DateTime modifiedAt;
}

abstract interface class NotesStore {
  Future<Map<String, PersonalNote>> load();
  Future<void> save(Map<String, PersonalNote> notes);
}

class LocalNotesStore implements NotesStore {
  LocalNotesStore({this.preferences});

  final SharedPreferencesAsync? preferences;
  static const storageKey = 'psps.notes.v1';

  @override
  Future<Map<String, PersonalNote>> load() async {
    final raw = await (preferences ?? SharedPreferencesAsync()).getString(
      storageKey,
    );
    if (raw == null) return {};
    final data = jsonDecode(raw);
    if (data is! Map || data['version'] != 1 || data['notes'] is! Map) {
      throw const FormatException('Notas locales incompatibles');
    }
    return (data['notes'] as Map).map((id, value) {
      if (id is! String ||
          value is! Map ||
          value['text'] is! String ||
          value['modifiedAt'] is! String) {
        throw const FormatException('Nota local inválida');
      }
      return MapEntry(
        id,
        PersonalNote(
          lessonId: id,
          text: value['text'] as String,
          modifiedAt: DateTime.parse(value['modifiedAt'] as String),
        ),
      );
    });
  }

  @override
  Future<void> save(Map<String, PersonalNote> notes) =>
      (preferences ?? SharedPreferencesAsync()).setString(
        storageKey,
        jsonEncode({
          'version': 1,
          'notes': {
            for (final entry in notes.entries)
              entry.key: {
                'text': entry.value.text,
                'modifiedAt': entry.value.modifiedAt.toUtc().toIso8601String(),
              },
          },
        }),
      );
}

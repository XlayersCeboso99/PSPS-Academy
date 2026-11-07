import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ProgressSnapshot {
  ProgressSnapshot({
    Map<String, int>? answers,
    Map<String, List<int>>? practices,
    Map<String, int>? reviewAnswers,
    this.points,
    List<String>? rewardedPractices,
    Map<String, String?>? achievements,
    this.selectedTheme = 'U-00',
  }) : answers = Map.unmodifiable(answers ?? {}),
       rewardedPractices = List.unmodifiable(rewardedPractices ?? []),
       achievements = Map.unmodifiable(achievements ?? {}),
       reviewAnswers = Map.unmodifiable(reviewAnswers ?? {}),
       practices = Map.unmodifiable(
         (practices ?? {}).map(
           (key, value) => MapEntry(key, List<int>.unmodifiable(value)),
         ),
       );
  final Map<String, int> answers;
  final Map<String, int> reviewAnswers;
  final Map<String, List<int>> practices;
  // Null only when decoding pre-gamification formats; migrated in memory.
  final int? points;
  final List<String> rewardedPractices;
  final Map<String, String?> achievements;
  final String selectedTheme;

  String encode() => jsonEncode({
    'version': points == null ? 2 : 3,
    'answers': answers,
    'practices': practices,
    'reviewAnswers': reviewAnswers,
    if (points != null) ...{
      'points': points,
      'rewardedPractices': rewardedPractices,
      'achievements': achievements,
      'selectedTheme': selectedTheme,
    },
  });

  factory ProgressSnapshot.decode(String raw) {
    final json = jsonDecode(raw);
    if (json is! Map ||
        ![1, 2, 3].contains(json['version']) ||
        json['answers'] is! Map ||
        json['practices'] is! Map ||
        (json['version'] != 1 && json['reviewAnswers'] is! Map) ||
        (json['version'] == 3 &&
            (json['points'] is! int ||
                json['rewardedPractices'] is! List ||
                json['achievements'] is! Map ||
                json['selectedTheme'] is! String))) {
      throw const FormatException('Estado local incompatible');
    }
    return ProgressSnapshot(
      answers: Map<String, int>.from(json['answers'] as Map),
      points: json['version'] == 3 ? json['points'] as int : null,
      rewardedPractices: json['version'] == 3
          ? List<String>.from(json['rewardedPractices'] as List)
          : [],
      achievements: json['version'] == 3
          ? Map<String, String?>.from(json['achievements'] as Map)
          : {},
      selectedTheme: json['version'] == 3
          ? json['selectedTheme'] as String
          : 'U-00',
      reviewAnswers: json['version'] == 1
          ? {}
          : Map<String, int>.from(json['reviewAnswers'] as Map),
      practices: (json['practices'] as Map).map(
        (key, value) => MapEntry(key as String, List<int>.from(value as List)),
      ),
    );
  }
}

abstract interface class ProgressStore {
  Future<ProgressSnapshot> load();
  Future<void> save(ProgressSnapshot state);
}

class LocalProgressStore implements ProgressStore {
  LocalProgressStore({
    SharedPreferencesAsync? preferences,
    this.key = storageKey,
  }) : _preferences = preferences ?? SharedPreferencesAsync();
  final SharedPreferencesAsync _preferences;
  static const storageKey = 'psps.progress.v1';
  final String key;

  @override
  Future<ProgressSnapshot> load() async {
    final raw = await _preferences.getString(key);
    return raw == null ? ProgressSnapshot() : ProgressSnapshot.decode(raw);
  }

  @override
  Future<void> save(ProgressSnapshot state) =>
      _preferences.setString(key, state.encode());
}

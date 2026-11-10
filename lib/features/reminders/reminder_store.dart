import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Configuración única de CU-12. Los días siguen DateTime.monday = 1 ... sunday = 7.
class ReminderSettings {
  const ReminderSettings({
    this.enabled = false,
    this.hour = 18,
    this.minute = 0,
    this.weekdays = const {1, 2, 3, 4, 5, 6, 7},
  });

  static const initial = ReminderSettings();
  final bool enabled;
  final int hour;
  final int minute;
  final Set<int> weekdays;

  bool get isValid =>
      hour >= 0 &&
      hour <= 23 &&
      minute >= 0 &&
      minute <= 59 &&
      weekdays.every((day) => day >= 1 && day <= 7) &&
      (!enabled || weekdays.isNotEmpty);

  bool sameAs(ReminderSettings other) =>
      enabled == other.enabled &&
      hour == other.hour &&
      minute == other.minute &&
      weekdays.length == other.weekdays.length &&
      weekdays.containsAll(other.weekdays);

  Map<String, Object> toJson() => {
    'version': 1,
    'enabled': enabled,
    'hour': hour,
    'minute': minute,
    'weekdays': weekdays.toList()..sort(),
  };

  factory ReminderSettings.fromJson(Object? raw) {
    if (raw is! Map ||
        raw['version'] != 1 ||
        raw['enabled'] is! bool ||
        raw['hour'] is! int ||
        raw['minute'] is! int ||
        raw['weekdays'] is! List) {
      throw const FormatException('Configuración de recordatorio inválida');
    }
    final days = raw['weekdays'] as List;
    if (days.any((day) => day is! int)) {
      throw const FormatException('Días de recordatorio inválidos');
    }
    final setting = ReminderSettings(
      enabled: raw['enabled'] as bool,
      hour: raw['hour'] as int,
      minute: raw['minute'] as int,
      weekdays: Set<int>.from(days),
    );
    if (!setting.isValid) {
      throw const FormatException('Hora o días del recordatorio inválidos');
    }
    return setting;
  }
}

abstract interface class ReminderStore {
  Future<ReminderSettings> load();
  Future<void> save(ReminderSettings settings);
}

class LocalReminderStore implements ReminderStore {
  LocalReminderStore({this.preferences});

  static const storageKey = 'psps.reminder.v1';
  final SharedPreferencesAsync? preferences;

  SharedPreferencesAsync get _prefs => preferences ?? SharedPreferencesAsync();

  @override
  Future<ReminderSettings> load() async {
    final raw = await _prefs.getString(storageKey);
    if (raw == null) return ReminderSettings.initial;
    return ReminderSettings.fromJson(jsonDecode(raw));
  }

  @override
  Future<void> save(ReminderSettings settings) async {
    if (!settings.isValid) {
      throw const FormatException('Configuración de recordatorio inválida');
    }
    await _prefs.setString(storageKey, jsonEncode(settings.toJson()));
  }
}

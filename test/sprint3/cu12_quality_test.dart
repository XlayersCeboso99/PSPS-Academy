import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psps/features/reminders/reminder_store.dart';
import 'package:psps/features/reminders/reminder_controller.dart';
import 'package:psps/app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryStore implements ReminderStore {
  ReminderSettings current = ReminderSettings.initial;
  bool failLoad = false;
  bool failSave = false;
  Completer<void>? pendingSave;
  int writes = 0;

  @override
  Future<ReminderSettings> load() async {
    if (failLoad) throw StateError('No se pudo leer');
    return current;
  }

  @override
  Future<void> save(ReminderSettings next) async {
    if (pendingSave != null) await pendingSave!.future;
    if (failSave) throw StateError('No se pudo guardar');
    current = next;
    writes++;
  }
}

class _FakePort implements NotificationPort {
  bool allowed = true;
  bool permissionRequest = true;
  bool failCancel = false;
  bool failSchedule = false;
  bool failSettings = false;
  int requests = 0;
  final Map<int, String> scheduled = {};
  VoidCallback? opened;

  @override
  Future<void> initialize({required VoidCallback onOpened}) async {
    opened = onOpened;
  }

  @override
  Future<bool> hasPermission() async => allowed;

  @override
  Future<bool> requestPermission() async {
    requests++;
    allowed = permissionRequest;
    return allowed;
  }

  @override
  Future<void> scheduleDay({
    required int weekday,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    if (failSchedule) throw StateError('Programación fallida');
    scheduled[weekday] = '$hour:$minute';
  }

  @override
  Future<void> cancelDay(int weekday) async {
    if (failCancel) throw StateError('Cancelación fallida');
    scheduled.remove(weekday);
  }

  @override
  Future<bool> openNotificationSettings() async {
    if (failSettings) throw StateError('Ajustes no disponibles');
    return true;
  }
}

class _Preferences implements SharedPreferencesAsync {
  final Map<String, String> raw = {};
  @override
  Future<String?> getString(String key) async => raw[key];
  @override
  Future<void> setString(String key, String value) async {
    raw[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _MemoryStore store;
  late _FakePort port;
  late ReminderController reminder;

  setUp(() async {
    store = _MemoryStore();
    port = _FakePort();
    reminder = ReminderController(store: store, port: port);
    await reminder.load();
  });

  test('TU-S3-12-24 | límites de hora y día inválidos sin escritura', () async {
    for (final invalid in [
      const ReminderSettings(enabled: true, hour: -1),
      const ReminderSettings(enabled: true, hour: 24),
      const ReminderSettings(enabled: true, minute: 60),
      const ReminderSettings(enabled: true, weekdays: {0}),
      const ReminderSettings(enabled: true, weekdays: {8}),
      const ReminderSettings(enabled: true, weekdays: {}),
    ]) {
      expect(await reminder.apply(invalid), ReminderResult.invalid);
    }
    expect(store.writes, 0);
    expect(port.scheduled, isEmpty);
  });

  test(
    'TU-S3-12-23 | permiso denegado no cambia recordatorio existente',
    () async {
      final original = const ReminderSettings(
        enabled: true,
        hour: 17,
        weekdays: {2, 4},
      );
      expect(await reminder.apply(original), ReminderResult.saved);
      final previous = Map<int, String>.of(port.scheduled);
      port.allowed = false;
      port.permissionRequest = false;
      expect(
        await reminder.apply(
          const ReminderSettings(enabled: true, hour: 20, weekdays: {1}),
        ),
        ReminderResult.permissionDenied,
      );
      expect(reminder.settings.sameAs(original), isTrue);
      expect(store.current.sameAs(original), isTrue);
      expect(port.scheduled, previous);
      expect(port.requests, 1);
    },
  );

  test('TU-S3-12-28 | falla cancelar: se restaura estado anterior', () async {
    final original = const ReminderSettings(
      enabled: true,
      hour: 18,
      weekdays: {1, 3},
    );
    expect(await reminder.apply(original), ReminderResult.saved);
    port.failCancel = true;
    final result = await reminder.apply(
      const ReminderSettings(enabled: true, hour: 19, weekdays: {3}),
    );
    expect(result, ReminderResult.scheduleFailed);
    expect(reminder.settings.sameAs(original), isTrue);
    expect(store.current.sameAs(original), isTrue);
    expect(
      reminder.warning,
      isNotNull,
      reason: 'No afirmar que el sistema restauró lo que no pudo cancelar',
    );
    port.failCancel = false;
    await reminder.load();
    expect(port.scheduled.keys.toSet(), {1, 3});
  });

  test(
    'TU-S3-12-29 | lectura corrupta bloquea cambios hasta reintentar',
    () async {
      final local = _Preferences();
      local.raw[LocalReminderStore.storageKey] =
          '{"version":1,"enabled":true,"hour":18,"minute":0,"weekdays":[0]}';
      final fresh = ReminderController(
        store: LocalReminderStore(preferences: local),
        port: _FakePort(),
      );
      await fresh.load();
      expect(fresh.ready, isFalse);
      expect(fresh.loadError, isNotNull);
      expect(
        await fresh.apply(const ReminderSettings(enabled: true)),
        ReminderResult.busy,
      );
      expect(
        local.raw[LocalReminderStore.storageKey],
        contains('"weekdays":[0]'),
      );
      local.raw[LocalReminderStore.storageKey] =
          '{"version":1,"enabled":false,"hour":18,"minute":0,"weekdays":[1]}';
      await fresh.load();
      expect(fresh.ready, isTrue);
      fresh.dispose();
    },
  );

  test(
    'TU-S3-12-22 | doble guardado simultáneo no duplica escritura',
    () async {
      store.pendingSave = Completer<void>();
      final pending = reminder.apply(
        const ReminderSettings(enabled: true, weekdays: {3}),
      );
      expect(reminder.saving, isTrue);
      expect(
        await reminder.apply(
          const ReminderSettings(enabled: true, weekdays: {4}),
        ),
        ReminderResult.busy,
      );
      store.pendingSave!.complete();
      expect(await pending, ReminderResult.saved);
      expect(store.writes, 1);
      expect(port.scheduled.keys.toSet(), {3});
    },
  );

  test('TU-S3-12-29 | permiso retirado informa sin reprogramar', () async {
    store.current = const ReminderSettings(enabled: true, weekdays: {1, 5});
    port.allowed = false;
    await reminder.load();
    expect(reminder.ready, isTrue);
    expect(reminder.warning, contains('desactivadas'));
    expect(port.scheduled, isEmpty);
  });

  testWidgets('TW-S3-12-13 | permiso ausente ofrece ajustes del teléfono', (
    tester,
  ) async {
    port.allowed = false;
    await reminder.load();
    await tester.pumpWidget(
      ReminderScope(
        controller: reminder,
        child: const MaterialApp(home: ReminderScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Abrir ajustes del teléfono'), findsOneWidget);
    expect(reminder.settings.enabled, isFalse);
  });

  testWidgets('TW-S3-12-20 | muestra error si no se seleccionan días', (
    tester,
  ) async {
    await tester.pumpWidget(
      ReminderScope(
        controller: reminder,
        child: const MaterialApp(home: ReminderScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cu12.enabled')));
    await tester.pump();
    for (var day = 1; day <= 7; day++) {
      await tester.ensureVisible(find.byKey(ValueKey('cu12.day.$day')));
      await tester.tap(find.byKey(ValueKey('cu12.day.$day')));
      await tester.pump();
    }
    expect(find.text('Elige al menos un día'), findsOneWidget);
    final save = tester.widget<FilledButton>(
      find.byKey(const ValueKey('cu12.save')),
    );
    expect(save.onPressed, isNull);
    expect(store.writes, 0);
  });
}

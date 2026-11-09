import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psps/features/reminders/reminder_store.dart';
import 'package:psps/features/reminders/reminder_controller.dart';
import 'package:psps/app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryReminderStore implements ReminderStore {
  ReminderSettings value = ReminderSettings.initial;
  bool failSave = false;
  bool failLoad = false;
  int saves = 0;

  @override
  Future<ReminderSettings> load() async {
    if (failLoad) throw StateError('read error');
    return value;
  }

  @override
  Future<void> save(ReminderSettings next) async {
    saves++;
    if (failSave) throw StateError('write error');
    value = next;
  }
}

class FakeReminderPort implements NotificationPort {
  bool allowed = true;
  bool requestAllowed = true;
  bool failSchedule = false;
  bool failCancel = false;
  int requests = 0;
  int launches = 0;
  final Map<int, String> scheduled = {};

  @override
  Future<void> initialize({required VoidCallback onOpened}) async {
    launches++;
  }

  @override
  Future<bool> hasPermission() async => allowed;

  @override
  Future<bool> requestPermission() async {
    requests++;
    allowed = requestAllowed;
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
    if (failSchedule) throw StateError('cannot schedule');
    scheduled[weekday] = '$hour:$minute:$title:$body';
  }

  @override
  Future<void> cancelDay(int weekday) async {
    if (failCancel) throw StateError('cannot cancel');
    scheduled.remove(weekday);
  }

  @override
  Future<bool> openNotificationSettings() async => true;
}

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

void main() {
  late MemoryReminderStore store;
  late FakeReminderPort port;
  late ReminderController controller;

  setUp(() async {
    store = MemoryReminderStore();
    port = FakeReminderPort();
    controller = ReminderController(store: store, port: port);
    await controller.load();
  });

  test('TU-S3-12-02 valores iniciales: apagado, 18:00 y siete días', () {
    expect(controller.ready, isTrue);
    expect(controller.settings.enabled, isFalse);
    expect(controller.settings.hour, 18);
    expect(controller.settings.minute, 0);
    expect(controller.settings.weekdays.length, 7);
    expect(port.scheduled, isEmpty);
  });

  test('TU-S3-12-05 guarda un día y hora válidos', () async {
    final outcome = await controller.apply(
      const ReminderSettings(
        enabled: true,
        hour: 19,
        minute: 30,
        weekdays: {1, 3},
      ),
    );
    expect(outcome, ReminderResult.saved);
    expect(port.scheduled.keys.toSet(), {1, 3});
    expect(store.value.hour, 19);
    expect(store.value.minute, 30);
  });

  test('TU-S3-12-12 permiso denegado conserva estado y no programa', () async {
    port.allowed = false;
    port.requestAllowed = false;
    final outcome = await controller.apply(
      const ReminderSettings(enabled: true, hour: 20, weekdays: {4}),
    );
    expect(outcome, ReminderResult.permissionDenied);
    expect(store.saves, 0);
    expect(controller.settings.enabled, isFalse);
    expect(port.requests, 1);
    expect(port.scheduled, isEmpty);
  });

  test('TU-S3-12-15 desactivar elimina programación anterior', () async {
    await controller.apply(
      const ReminderSettings(enabled: true, hour: 17, weekdays: {2, 5}),
    );
    final outcome = await controller.apply(ReminderSettings.initial);
    expect(outcome, ReminderResult.disabled);
    expect(controller.settings.enabled, isFalse);
    expect(port.scheduled, isEmpty);
  });

  test('TU-S3-12-18 reemplaza sin duplicados por ID de día', () async {
    await controller.apply(
      const ReminderSettings(enabled: true, hour: 18, weekdays: {1, 3}),
    );
    await controller.apply(
      const ReminderSettings(enabled: true, hour: 21, weekdays: {3, 6}),
    );
    expect(port.scheduled.keys.toSet(), {3, 6});
    expect(port.scheduled[3], startsWith('21:0:'));
    expect(port.scheduled.length, 2);
  });

  test('TU-S3-12-22 error al guardar no toca programación previa', () async {
    await controller.apply(
      const ReminderSettings(enabled: true, hour: 18, weekdays: {1}),
    );
    final previous = Map<int, String>.of(port.scheduled);
    store.failSave = true;
    final result = await controller.apply(
      const ReminderSettings(enabled: true, hour: 19, weekdays: {4}),
    );
    expect(result, ReminderResult.saveFailed);
    expect(port.scheduled, previous);
    expect(controller.settings.hour, 18);
    expect(store.value.hour, 18);
  });

  test(
    'TU-S3-12-24 configuración inválida no modifica almacenamiento',
    () async {
      expect(
        await controller.apply(
          const ReminderSettings(enabled: true, weekdays: {}),
        ),
        ReminderResult.invalid,
      );
      expect(
        await controller.apply(const ReminderSettings(enabled: true, hour: 24)),
        ReminderResult.invalid,
      );
      expect(store.saves, 0);
    },
  );

  test('TU-S3-12-25 máximo un recordatorio lógico de siete días', () async {
    await controller.apply(
      const ReminderSettings(enabled: true, weekdays: {1, 2, 3, 4, 5, 6, 7}),
    );
    await controller.apply(
      const ReminderSettings(enabled: true, weekdays: {1}),
    );
    expect(port.scheduled.keys.toSet(), {1});
    expect(port.scheduled.length, 1);
  });

  test(
    'TU-S3-12-28 recupera configuración anterior si programación falla',
    () async {
      await controller.apply(
        const ReminderSettings(enabled: true, hour: 18, weekdays: {1}),
      );
      port.failSchedule = true;
      final outcome = await controller.apply(
        const ReminderSettings(enabled: true, hour: 19, weekdays: {2}),
      );
      expect(outcome, ReminderResult.scheduleFailed);
      expect(store.value.hour, 18);
      expect(controller.settings.hour, 18);
      port.failSchedule = false;
      await controller.load();
      expect(port.scheduled.keys.toSet(), {1});
    },
  );

  test('TU-S3-12-29 al reiniciar reconcilia configuración guardada', () async {
    store.value = const ReminderSettings(enabled: true, weekdays: {2, 4});
    port.scheduled[7] = 'stale';
    await controller.load();
    expect(port.scheduled.keys.toSet(), {2, 4});
    store.value = ReminderSettings.initial;
    await controller.load();
    expect(port.scheduled, isEmpty);
  });

  test('persistencia JSON v1 conserva otras claves de progreso', () async {
    final memory = MemoryPreferences();
    memory.values['psps.progress.v1'] = 'existing-progress';
    final local = LocalReminderStore(preferences: memory);
    await local.save(
      const ReminderSettings(
        enabled: true,
        hour: 9,
        minute: 5,
        weekdays: {1, 5},
      ),
    );
    final restored = await LocalReminderStore(preferences: memory).load();
    expect(restored.enabled, true);
    expect(restored.weekdays, {1, 5});
    expect(memory.values['psps.progress.v1'], 'existing-progress');
    memory.values[LocalReminderStore.storageKey] = '{broken';
    await expectLater(local.load(), throwsFormatException);
  });

  testWidgets('TW-S3-12-01 comienza apagado y muestra hora sugerida', (
    tester,
  ) async {
    await tester.pumpWidget(
      ReminderScope(
        controller: controller,
        child: const MaterialApp(home: ReminderScreen()),
      ),
    );
    expect(find.text('Recordarme estudiar'), findsOneWidget);
    expect(find.text('18:00'), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      false,
    );
  });

  testWidgets('TW-S3-12-04 sin días no permite guardar', (tester) async {
    await tester.pumpWidget(
      ReminderScope(
        controller: controller,
        child: const MaterialApp(home: ReminderScreen()),
      ),
    );
    await tester.tap(find.text('Recordarme estudiar'));
    await tester.pump();
    for (var i = 1; i <= 7; i++) {
      await tester.tap(find.byKey(ValueKey('cu12.day.$i')));
      await tester.pump();
    }
    expect(find.text('Elige al menos un día'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('cu12.save')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('TW-S3-12-06 y 16 guardar y desactivar', (tester) async {
    await tester.pumpWidget(
      ReminderScope(
        controller: controller,
        child: const MaterialApp(home: ReminderScreen()),
      ),
    );
    await tester.tap(find.text('Recordarme estudiar'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('cu12.save')));
    await tester.pumpAndSettle();
    expect(store.value.enabled, true);
    await tester.tap(find.text('Recordarme estudiar'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('cu12.save')));
    await tester.pumpAndSettle();
    expect(store.value.enabled, false);
    expect(port.scheduled, isEmpty);
  });
}

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psps/features/reminders/adapters/flutter_notification_port.dart';
import 'package:psps/features/reminders/adapters/notification_port_factory.dart';
import 'package:psps/features/reminders/adapters/ohos_notification_port.dart';
import 'package:psps/features/reminders/reminder_controller.dart';
import 'package:psps/features/reminders/reminder_store.dart';

class _MemoryStore implements ReminderStore {
  ReminderSettings value = ReminderSettings.initial;

  @override
  Future<ReminderSettings> load() async => value;

  @override
  Future<void> save(ReminderSettings settings) async => value = settings;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('mx.edu.uaz.psps/reminders');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late OhosNotificationPort port;
  late List<MethodCall> calls;

  setUp(() {
    port = OhosNotificationPort();
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'hasPermission' ||
        'requestPermission' ||
        'openNotificationSettings' => true,
        _ => null,
      };
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    channel.setMethodCallHandler(null);
  });

  test(
    'fábrica conserva Android/iOS por defecto y selecciona ohos explícito',
    () {
      const target = String.fromEnvironment('PSPS_TARGET');
      expect(
        createNotificationPort(),
        target == 'ohos'
            ? isA<OhosNotificationPort>()
            : isA<FlutterNotificationPort>(),
      );
    },
  );

  test('nombres, argumentos y resultados exactos del contrato', () async {
    await port.initialize(onOpened: () {});
    expect(await port.hasPermission(), isTrue);
    expect(await port.requestPermission(), isTrue);
    await port.scheduleDay(
      weekday: 3,
      hour: 18,
      minute: 30,
      title: 'Estudio',
      body: 'PSPS',
    );
    await port.cancelDay(3);
    expect(await port.openNotificationSettings(), isTrue);

    expect(calls.map((call) => call.method), [
      'initialize',
      'hasPermission',
      'requestPermission',
      'scheduleDay',
      'cancelDay',
      'openNotificationSettings',
    ]);
    expect(calls.map((call) => call.arguments), [
      null,
      null,
      null,
      {
        'weekday': 3,
        'hour': 18,
        'minute': 30,
        'title': 'Estudio',
        'body': 'PSPS',
      },
      {'weekday': 3},
      null,
    ]);
  });

  test('permiso denegado y ajustes no disponibles devuelven false', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => false);
    expect(await port.hasPermission(), isFalse);
    expect(await port.requestPermission(), isFalse);
    expect(await port.openNotificationSettings(), isFalse);
    messenger.setMockMethodCallHandler(channel, (_) async => null);
    expect(await port.hasPermission(), isFalse);
    expect(await port.requestPermission(), isFalse);
    expect(await port.openNotificationSettings(), isFalse);
  });

  final operations = <String, Future<Object?> Function(OhosNotificationPort)>{
    'initialize': (port) => port.initialize(onOpened: () {}),
    'hasPermission': (port) => port.hasPermission(),
    'requestPermission': (port) => port.requestPermission(),
    'scheduleDay': (port) => port.scheduleDay(
      weekday: 1,
      hour: 18,
      minute: 30,
      title: 'Estudio',
      body: 'PSPS',
    ),
    'cancelDay': (port) => port.cancelDay(1),
    'openNotificationSettings': (port) => port.openNotificationSettings(),
  };
  for (final operation in operations.entries) {
    test(
      '${operation.key} propaga PlatformException sin perder datos',
      () async {
        messenger.setMockMethodCallHandler(channel, (_) async {
          throw PlatformException(
            code: '1700001',
            message: 'Notification is not enabled',
            details: {'native': true},
          );
        });
        await expectLater(
          operation.value(port),
          throwsA(
            isA<PlatformException>()
                .having((error) => error.code, 'code', '1700001')
                .having(
                  (error) => error.message,
                  'message',
                  'Notification is not enabled',
                )
                .having((error) => error.details, 'details', {'native': true}),
          ),
        );
      },
    );
  }

  Future<void> receiveNative(String method) async {
    final completed = Completer<void>();
    messenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(MethodCall(method)),
      (_) => completed.complete(),
    );
    await completed.future;
  }

  test(
    'opened invoca el callback incluso durante initialize en frío',
    () async {
      var openings = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'initialize') await receiveNative('opened');
        return null;
      });
      await port.initialize(onOpened: () => openings++);
      expect(openings, 1);
      await receiveNative('opened');
      await receiveNative('unrelated');
      expect(openings, 2);
      await port.initialize(onOpened: () => openings += 10);
      expect(openings, 12);
      await receiveNative('opened');
      expect(openings, 22);
    },
  );

  test('controlador: L/M/V 18:30, solo M y desactivar sin duplicados', () async {
    // Simula el contrato de reemplazo nativo; no ejecuta reminderAgentManager.
    final pending = <int, Map<Object?, Object?>>{};
    final store = _MemoryStore();
    var openings = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'scheduleDay') {
        final args = call.arguments as Map<Object?, Object?>;
        pending[args['weekday']! as int] = args;
      } else if (call.method == 'cancelDay') {
        pending.remove((call.arguments as Map)['weekday']);
      }
      return call.method == 'hasPermission' ? true : null;
    });
    final controller = ReminderController(
      store: store,
      port: port,
      onOpened: () => openings++,
    );
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.ready, isTrue);
    expect(pending, isEmpty);
    expect(calls.where((call) => call.method == 'cancelDay').length, 7);
    calls.clear();

    Future<void> applyAndCheck(
      ReminderSettings settings,
      ReminderResult result,
      List<int> schedules,
      List<int> cancellations,
    ) async {
      calls.clear();
      expect(await controller.apply(settings), result);
      final scheduled = calls.where((call) => call.method == 'scheduleDay');
      final cancelled = calls.where((call) => call.method == 'cancelDay');
      expect(
        scheduled.map((call) => (call.arguments as Map)['weekday']),
        schedules,
      );
      expect(
        cancelled.map((call) => (call.arguments as Map)['weekday']),
        cancellations,
      );
      for (final call in scheduled) {
        expect(call.arguments, {
          'weekday': (call.arguments as Map)['weekday'],
          'hour': 18,
          'minute': 30,
          'title': 'Es hora de estudiar',
          'body': 'Tu recorrido en PSPS te espera',
        });
      }
      expect(pending.keys.toSet(), schedules.toSet());
      expect(pending.length, schedules.length);
      expect(store.value.sameAs(settings), isTrue);
    }

    await applyAndCheck(
      const ReminderSettings(
        enabled: true,
        hour: 18,
        minute: 30,
        weekdays: {1, 2, 5},
      ),
      ReminderResult.saved,
      [1, 2, 5],
      [3, 4, 6, 7],
    );
    await applyAndCheck(
      const ReminderSettings(
        enabled: true,
        hour: 18,
        minute: 30,
        weekdays: {2},
      ),
      ReminderResult.saved,
      [2],
      [1, 3, 4, 5, 6, 7],
    );
    await applyAndCheck(
      const ReminderSettings(hour: 18, minute: 30, weekdays: {2}),
      ReminderResult.disabled,
      [],
      [1, 2, 3, 4, 5, 6, 7],
    );
    await receiveNative('opened');
    expect(openings, 1);
  });
}

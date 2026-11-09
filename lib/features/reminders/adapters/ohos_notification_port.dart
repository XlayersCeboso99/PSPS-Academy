import 'package:flutter/services.dart';

import 'package:psps/features/reminders/notification_port.dart';

/// Puerto HarmonyOS NEXT. El overlay ArkTS implementa el otro extremo del canal.
/// Los errores nativos se propagan para permitir el rollback del controlador.
class OhosNotificationPort implements NotificationPort {
  static const _channel = MethodChannel('mx.edu.uaz.psps/reminders');

  @override
  Future<void> initialize({required VoidCallback onOpened}) async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'opened') onOpened();
    });
    // El nativo retiene las aperturas en frío hasta recibir initialize.
    await _channel.invokeMethod<void>('initialize');
  }

  @override
  Future<bool> hasPermission() async =>
      await _channel.invokeMethod<bool>('hasPermission') ?? false;

  @override
  Future<bool> requestPermission() async =>
      await _channel.invokeMethod<bool>('requestPermission') ?? false;

  @override
  Future<void> scheduleDay({
    required int weekday,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) => _channel.invokeMethod<void>('scheduleDay', {
    'weekday': weekday,
    'hour': hour,
    'minute': minute,
    'title': title,
    'body': body,
  });

  @override
  Future<void> cancelDay(int weekday) =>
      _channel.invokeMethod<void>('cancelDay', {'weekday': weekday});

  @override
  Future<bool> openNotificationSettings() async =>
      await _channel.invokeMethod<bool>('openNotificationSettings') ?? false;
}

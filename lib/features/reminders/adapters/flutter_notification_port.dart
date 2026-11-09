import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:psps/features/reminders/notification_port.dart';

/// Adaptador móvil. HarmonyOS NEXT requiere su propio puerto ArkTS: no se
/// interpreta Flutter Android como compatibilidad de HarmonyOS NEXT.
class FlutterNotificationPort implements NotificationPort {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  @override
  Future<void> initialize({required VoidCallback onOpened}) async {
    if (_initialized) return;
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw UnsupportedError('Las notificaciones requieren Android o iOS');
    }
    tzdata.initializeTimeZones();
    final local = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(local.identifier));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (_) => onOpened(),
    );
    _initialized = true;
  }

  @override
  Future<bool> hasPermission() async {
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.areNotificationsEnabled() ??
          false;
    }
    if (Platform.isIOS) {
      return (await _plugin
                  .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin
                  >()
                  ?.checkPermissions())
              ?.isEnabled ??
          false;
    }
    return false;
  }

  @override
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    if (Platform.isIOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, sound: true, badge: false) ??
          false;
    }
    return false;
  }

  @override
  Future<void> scheduleDay({
    required int weekday,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    if (!_initialized) throw StateError('Puerto no inicializado');
    if (weekday < 1 || weekday > 7) throw RangeError.range(weekday, 1, 7);
    final now = tz.TZDateTime.now(tz.local);
    final delta = (weekday - now.weekday + 7) % 7;
    var when = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + delta,
      hour,
      minute,
    );
    if (!when.isAfter(now)) {
      when = tz.TZDateTime(
        tz.local,
        when.year,
        when.month,
        when.day + 7,
        hour,
        minute,
      );
    }
    await _plugin.zonedSchedule(
      id: 1200 + weekday,
      title: title,
      body: body,
      scheduledDate: when,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'psps_recordatorio',
          'Recordatorio de estudio',
          channelDescription: 'Avisos semanales de estudio de PSPS Academy',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'psps:study',
    );
  }

  @override
  Future<void> cancelDay(int weekday) => _plugin.cancel(id: 1200 + weekday);

  @override
  Future<bool> openNotificationSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.notification);
    return true;
  }
}

import 'package:flutter/foundation.dart';

/// Contrato reemplazable por un fake en pruebas. No hay dependencias nativas
/// en el controlador, solo en el adaptador de Android/iOS.
abstract interface class NotificationPort {
  Future<void> initialize({required VoidCallback onOpened});
  Future<bool> hasPermission();
  Future<bool> requestPermission();
  Future<void> scheduleDay({
    required int weekday,
    required int hour,
    required int minute,
    required String title,
    required String body,
  });
  Future<void> cancelDay(int weekday);
  Future<bool> openNotificationSettings();
}

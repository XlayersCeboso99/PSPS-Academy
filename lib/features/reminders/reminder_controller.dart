import 'package:flutter/foundation.dart';

import 'package:psps/features/reminders/notification_port.dart';
import 'package:psps/features/reminders/reminder_store.dart';

export 'package:psps/features/reminders/notification_port.dart';

enum ReminderResult {
  saved,
  disabled,
  permissionDenied,
  saveFailed,
  scheduleFailed,
  invalid,
  busy,
}

/// CU-12 / RF-13 / CA-13: un solo recordatorio semanal, totalmente local.
/// Siempre se almacena la configuración antes de programar las notificaciones.
/// Ante fallo se intenta restaurar tanto el almacenamiento como el sistema.
class ReminderController extends ChangeNotifier {
  ReminderController({required this.store, required this.port, this.onOpened});

  final ReminderStore store;
  final NotificationPort port;
  final VoidCallback? onOpened;
  ReminderSettings settings = ReminderSettings.initial;
  bool ready = false;
  bool loading = false;
  bool saving = false;
  bool permissionGranted = false;
  String? loadError;
  String? saveError;
  String? warning;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    if (_disposed || loading || saving) return;
    loading = true;
    ready = false;
    loadError = null;
    saveError = null;
    warning = null;
    _notify();
    try {
      await port.initialize(onOpened: () => onOpened?.call());
      // No tocar la programación hasta validar el JSON almacenado.
      final saved = await store.load();
      if (!saved.isValid) throw const FormatException('Recordatorio inválido');
      settings = saved;
      permissionGranted = await port.hasPermission();
      ready = true;
      if (saved.enabled && !permissionGranted) {
        warning = 'Las notificaciones están desactivadas en el teléfono.';
      } else {
        // Fuente de verdad: la configuración local, no los avisos pendientes.
        await _reconcile(saved);
      }
    } catch (_) {
      ready = false;
      loadError = 'No se pudo cargar o sincronizar el recordatorio. Reintenta.';
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<ReminderResult> apply(ReminderSettings next) async {
    if (_disposed || !ready || saving || loading) return ReminderResult.busy;
    if (!next.isValid) return ReminderResult.invalid;
    saving = true;
    saveError = null;
    warning = null;
    _notify();

    final previous = settings;
    try {
      if (next.enabled) {
        var allowed = await port.hasPermission();
        if (!allowed) allowed = await port.requestPermission();
        permissionGranted = allowed;
        if (!allowed) {
          saveError = 'Sin permiso de notificaciones no podemos recordarte.';
          return ReminderResult.permissionDenied;
        }
      }

      try {
        await store.save(next);
      } catch (_) {
        saveError = 'No se pudo guardar el recordatorio. Intenta de nuevo.';
        return ReminderResult.saveFailed;
      }

      try {
        await _reconcile(next);
        settings = next;
        return next.enabled ? ReminderResult.saved : ReminderResult.disabled;
      } catch (_) {
        // Revertir ambos recursos, sin anunciar que se guardó el cambio.
        var storeRestored = false;
        var scheduleRestored = false;
        try {
          await store.save(previous);
          storeRestored = true;
        } catch (_) {
          // Si el rollback del almacenamiento falla, bloquear nuevos cambios
          // hasta que load() relea la fuente de verdad.
        }
        if (storeRestored) {
          try {
            await _reconcile(previous);
            scheduleRestored = true;
          } catch (_) {
            // En el siguiente inicio se intentará la reconciliación.
          }
        }
        if (!storeRestored) {
          ready = false;
          loadError =
              'No se pudo recuperar el recordatorio. Reabre esta pantalla.';
          saveError = loadError;
        } else if (!scheduleRestored) {
          warning =
              'Revisa la programación; se intentará recuperar al iniciar.';
          saveError = 'No se pudo restaurar la programación anterior.';
        } else {
          saveError =
              'No se pudo programar. Se mantiene la configuración anterior.';
        }
        return ReminderResult.scheduleFailed;
      }
    } catch (_) {
      saveError = 'No se pudo consultar el permiso de notificaciones.';
      return ReminderResult.permissionDenied;
    } finally {
      saving = false;
      _notify();
    }
  }

  Future<void> _reconcile(ReminderSettings value) async {
    if (value.enabled) {
      // Primero se reemplazan las IDs fijas de cada día. Solo después se
      // cancelan los días retirados. Nunca se crean duplicados.
      for (final day in value.weekdays.toList()..sort()) {
        await port.scheduleDay(
          weekday: day,
          hour: value.hour,
          minute: value.minute,
          title: 'Es hora de estudiar',
          body: 'Tu recorrido en PSPS te espera',
        );
      }
    }
    for (var day = 1; day <= 7; day++) {
      if (!value.enabled || !value.weekdays.contains(day)) {
        await port.cancelDay(day);
      }
    }
  }

  Future<bool> openSettings() async {
    try {
      return await port.openNotificationSettings();
    } catch (_) {
      return false;
    }
  }
}

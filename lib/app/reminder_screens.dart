part of 'app.dart';

class ReminderScope extends InheritedNotifier<ReminderController> {
  const ReminderScope({
    super.key,
    required ReminderController controller,
    required super.child,
  }) : super(notifier: controller);

  static ReminderController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ReminderScope>()?.notifier;
}

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});
  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  ReminderController? reminder;
  bool loadedDraft = false;
  bool enabled = false;
  int hour = 18;
  int minute = 0;
  Set<int> days = {1, 2, 3, 4, 5, 6, 7};

  static const labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  static const names = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reminder ??= ReminderScope.maybeOf(context);
    if (reminder!.ready && !loadedDraft) _resetDraft();
  }

  void _resetDraft() {
    final settings = reminder!.settings;
    enabled = settings.enabled;
    hour = settings.hour;
    minute = settings.minute;
    days = {...settings.weekdays};
    loadedDraft = true;
  }

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Future<void> _selectTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (!mounted || selected == null) return;
    setState(() {
      hour = selected.hour;
      minute = selected.minute;
    });
  }

  Future<void> _save() async {
    final c = reminder!;
    if (c.saving || !c.ready || (enabled && days.isEmpty)) return;
    if (enabled && !c.permissionGranted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Permiso de notificaciones'),
          content: const Text(
            'Para recordarte estudiar, PSPS necesita mostrar notificaciones. '
            'El permiso se solicita al activar el recordatorio.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Ahora no'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    final result = await c.apply(
      ReminderSettings(
        enabled: enabled,
        hour: hour,
        minute: minute,
        weekdays: days,
      ),
    );
    if (!mounted) return;
    setState(() {
      if (c.ready) _resetDraft();
    });
    if (result == ReminderResult.saved || result == ReminderResult.disabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == ReminderResult.disabled
                ? 'Recordatorio desactivado'
                : 'Recordatorio guardado',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ReminderScope.maybeOf(context)!;
    if (!c.ready) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recordatorio de estudio')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(c.loadError ?? 'Cargando recordatorio…'),
                if (c.loading) const CircularProgressIndicator(),
                if (c.loadError != null)
                  FilledButton(
                    onPressed: () async {
                      await c.load();
                      if (!mounted) return;
                      setState(() {
                        loadedDraft = false;
                        if (c.ready) _resetDraft();
                      });
                    },
                    child: const Text('Reintentar'),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    if (!loadedDraft) _resetDraft();
    return Scaffold(
      appBar: AppBar(title: const Text('Recordatorio de estudio')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SwitchListTile(
                  key: const ValueKey('cu12.enabled'),
                  title: const Text('Recordarme estudiar'),
                  subtitle: const Text('Notificaciones locales, sin Internet'),
                  value: enabled,
                  onChanged: c.saving
                      ? null
                      : (value) => setState(() => enabled = value),
                ),
                const SizedBox(height: 20),
                ListTile(
                  title: const Text('Hora del recordatorio'),
                  subtitle: Text(timeLabel),
                  trailing: const Icon(Icons.schedule),
                  onTap: !enabled || c.saving ? null : _selectTime,
                ),
                const SizedBox(height: 12),
                const Text('Días de la semana'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < 7; i++)
                      FilterChip(
                        key: ValueKey('cu12.day.${i + 1}'),
                        label: Text(labels[i]),
                        tooltip: names[i],
                        selected: days.contains(i + 1),
                        onSelected: !enabled || c.saving
                            ? null
                            : (selected) {
                                setState(() {
                                  if (selected) {
                                    days.add(i + 1);
                                  } else {
                                    days.remove(i + 1);
                                  }
                                });
                              },
                      ),
                  ],
                ),
                if (enabled && days.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Elige al menos un día'),
                  ),
                if (c.warning != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(c.warning!),
                  ),
                if (c.saveError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(c.saveError!),
                  ),
                if (!c.permissionGranted)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: OutlinedButton(
                      onPressed: c.openSettings,
                      child: const Text('Abrir ajustes del teléfono'),
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const ValueKey('cu12.save'),
                  onPressed: c.saving || (enabled && days.isEmpty)
                      ? null
                      : _save,
                  child: Text(c.saving ? 'Guardando…' : 'Guardar'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Los avisos aparecen los días elegidos aunque ya hayas '
                  'estudiado. Android puede retrasarlos por restricciones de batería. '
                  'Las preferencias se guardan únicamente en este dispositivo.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import 'activity_engine.dart';
import 'activity_models.dart';

/// CU-08. Al abrir una actividad se delega el flujo a CU-02.
/// Esta pantalla no escribe ni otorga puntos/logros.
class Cu08ActivitiesPage extends StatefulWidget {
  const Cu08ActivitiesPage({
    super.key,
    required this.catalog,
    required this.engine,
    required this.onOpenActivity,
  });

  final List<ActivityDefinition> catalog;
  final ActivityEngine engine;
  final FutureOr<void> Function(ActivityDefinition) onOpenActivity;

  @override
  State<Cu08ActivitiesPage> createState() => _Cu08ActivitiesPageState();
}

class _Cu08ActivitiesPageState extends State<Cu08ActivitiesPage> {
  late Future<Set<String>> _completed;
  StreamSubscription<void>? _updates;

  @override
  void initState() {
    super.initState();
    _refresh();
    _watch();
  }

  void _watch() {
    _updates?.cancel();
    _updates = widget.engine.changes.listen((_) {
      if (mounted) setState(_refresh);
    });
  }

  @override
  void didUpdateWidget(Cu08ActivitiesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.engine, oldWidget.engine)) {
      _watch();
      _refresh();
    }
  }

  @override
  void dispose() {
    _updates?.cancel();
    super.dispose();
  }

  void _refresh() {
    _completed = widget.engine.readCompletedIds();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Actividades')),
    body: FutureBuilder<Set<String>>(
      future: _completed,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No fue posible recuperar el estado local.'),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(_refresh),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        if (widget.catalog.isEmpty) {
          return const Center(child: Text('No hay actividades disponibles.'));
        }
        final completed = snapshot.data ?? const <String>{};
        final grouped = <String, List<ActivityDefinition>>{};
        final headings = <String, String>{};
        for (final activity in widget.catalog) {
          final key = '${activity.moduleId}::${activity.topicId}';
          headings.putIfAbsent(
            key,
            () => '${activity.moduleName} · ${activity.topicName}',
          );
          grouped.putIfAbsent(key, () => []).add(activity);
        }
        return ListView(
          children: [
            for (final group in grouped.entries) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  headings[group.key]!,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final activity in group.value)
                ListTile(
                  title: Text(activity.title),
                  subtitle: Text(
                    completed.contains(activity.id) ? 'Realizada' : 'Pendiente',
                  ),
                  leading: Icon(
                    completed.contains(activity.id)
                        ? Icons.check_circle_outline
                        : Icons.radio_button_unchecked,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await widget.onOpenActivity(activity);
                    if (mounted) setState(_refresh);
                  },
                ),
            ],
          ],
        );
      },
    ),
  );
}

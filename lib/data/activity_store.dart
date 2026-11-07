import '../domain/learning_controller.dart';
import '../features/cu08/activity_models.dart';

/// Puente al estado compartido de la app. No crea otra clave o almacenamiento.
class LearningActivityStore implements ActivityStore {
  LearningActivityStore(this.controller);
  final LearningController controller;

  @override
  Future<ActivityState> load() async {
    if (!controller.ready) throw StateError('Avance no disponible');
    return ActivityState(
      completedActivityIds: {
        for (final p in controller.practices)
          if (controller.practiceCompleted(p)) p.id,
      },
      achievedAt: {
        for (final e in controller.earnedAchievements.entries)
          e.key: e.value == null ? null : DateTime.parse(e.value!),
      },
    );
  }

  @override
  Future<void> save(ActivityState state) async {
    final before = await load();
    if (!state.completedActivityIds.containsAll(before.completedActivityIds)) {
      throw StateError('No se pueden retirar actividades realizadas');
    }
    final added = state.completedActivityIds.difference(
      before.completedActivityIds,
    );
    if (added.isEmpty) return;
    if (added.length != 1) {
      throw StateError('Solo se guarda una actividad por operación');
    }
    final practices = controller.practices.where((p) => p.id == added.single);
    if (practices.length != 1) throw StateError('Actividad fuera del catálogo');
    final practice = practices.single;
    // C05 ya verificó los elementos. C06/C07 compartidos calculan y guardan
    // las recompensas conservando respuestas, repaso y tema seleccionado.
    final saved = await controller.saveOrder(
      practice,
      List.generate(practice.steps.length, (i) => i),
    );
    if (!saved) throw StateError('No se pudo guardar la actividad');
  }
}

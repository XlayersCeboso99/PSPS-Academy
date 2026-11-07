import 'dart:async';

import 'activity_models.dart';

/// Orquestación C05 -> C06 -> C07. No incluye almacenamiento ficticio.
/// El adaptador real debe conectarse a la persistencia existente de PSPS.
class ActivityEngine {
  ActivityEngine({
    required Iterable<ActivityDefinition> activities,
    required this.store,
    DateTime Function()? clock,
  }) : _activities = {for (final a in activities) a.id: a},
       _clock = clock ?? DateTime.now {
    if (_activities.length != activities.length) {
      throw ArgumentError('Los IDs del catálogo deben ser únicos.');
    }
    if (_activities.isEmpty) {
      throw ArgumentError('El catálogo de actividades no puede estar vacío.');
    }
    if (_activities.keys.any((id) => id.trim().isEmpty)) {
      throw ArgumentError('Cada actividad requiere un identificador válido.');
    }
    if (_activities.values.any((a) => a.requiredElementIds.isEmpty)) {
      throw ArgumentError('Cada actividad requiere elementos obligatorios.');
    }
  }

  final Map<String, ActivityDefinition> _activities;
  final ActivityStore store;
  final DateTime Function() _clock;
  Future<void> _writeQueue = Future<void>.value();
  final _changes = StreamController<void>.broadcast(sync: true);
  Stream<void> get changes => _changes.stream;

  Set<String> get eligibleActivityIds => Set.unmodifiable(_activities.keys);

  int pointsFor(ActivityState state) =>
      state.completedActivityIds.intersection(eligibleActivityIds).length * 10;

  /// Consulta CU-08: lee estados y no realiza escrituras ni recompensa.
  Future<Set<String>> readCompletedIds() async {
    final state = await store.load();
    return Set.unmodifiable(state.completedActivityIds);
  }

  /// Invocar DESDE CU-02 después de que C05 compruebe todos los elementos.
  /// Si la escritura falla, propaga el error: no se informa recompensa.
  /// La cola impide doble clic concurrente en esta misma instancia.
  /// El repositorio C07 debe controlar también concurrencia entre instancias.
  Future<CompletionOutcome> completeActivity({
    required String activityId,
    required Set<String> verifiedElementIds,
  }) async {
    final preceding = _writeQueue;
    final gate = Completer<void>();
    _writeQueue = gate.future;
    await preceding;
    try {
      final definition = _activities[activityId];
      if (definition == null) {
        throw ArgumentError.value(activityId, 'activityId', 'ID desconocido');
      }
      final before = await store.load();
      final originalCount = pointsFor(before);
      if (before.completedActivityIds.contains(activityId)) {
        return CompletionOutcome(
          justCompleted: false,
          pointsAdded: 0,
          newAchievementIds: const {},
          newThemeIds: const {},
          totalPoints: originalCount,
        );
      }
      if (!verifiedElementIds.containsAll(definition.requiredElementIds)) {
        return CompletionOutcome(
          justCompleted: false,
          pointsAdded: 0,
          newAchievementIds: const {},
          newThemeIds: const {},
          totalPoints: originalCount,
        );
      }

      final completed = {...before.completedActivityIds, activityId};
      final achievements = {...before.achievedAt};
      final count = completed.intersection(eligibleActivityIds).length;
      final newlyAchieved = <String>{};
      void grant(String id, bool condition) {
        if (condition && !achievements.containsKey(id)) {
          achievements[id] = _clock().toUtc();
          newlyAchieved.add(id);
        }
      }

      // ÚNICAMENTE logros que se disparan por actividades según MR-09.
      grant('L-03', count >= 1);
      grant('L-04', count >= 5);
      grant('L-05', count == _activities.length && _activities.isNotEmpty);
      final newThemes = <String>{};
      if (newlyAchieved.contains('L-03')) newThemes.add('U-01');

      final updated = before.copyWith(
        completedActivityIds: completed,
        achievedAt: achievements,
      );
      // La confirmación solo sucede DESPUÉS de save exitoso.
      await store.save(updated);
      _changes.add(null);
      final currentPoints = pointsFor(updated);
      return CompletionOutcome(
        justCompleted: true,
        pointsAdded: currentPoints - originalCount,
        newAchievementIds: Set.unmodifiable(newlyAchieved),
        newThemeIds: Set.unmodifiable(newThemes),
        totalPoints: currentPoints,
      );
    } finally {
      gate.complete();
    }
  }
}

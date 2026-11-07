/// Modelo de CU-08 (consulta de actividades) y puente C05/C06.
/// Fuente de reglas: PSPS MR-09, 20/10/2026; CU-08/RF-09/CA-09A.
class ActivityDefinition {
  const ActivityDefinition({
    required this.id,
    required this.title,
    required this.moduleId,
    required this.moduleName,
    required this.topicId,
    required this.topicName,
    required this.requiredElementIds,
  });

  final String id;
  final String title;
  final String moduleId;
  final String moduleName;
  final String topicId;
  final String topicName;
  final Set<String> requiredElementIds;
}

class ActivityState {
  ActivityState({
    required Set<String> completedActivityIds,
    Map<String, DateTime?>? achievedAt,
  }) : completedActivityIds = Set.unmodifiable(completedActivityIds),
       achievedAt = Map.unmodifiable(achievedAt ?? const {});

  final Set<String> completedActivityIds;

  /// L-03, L-04 y L-05 se registran solo cuando surgen por actividades.
  /// El adaptador C07 debe conservar cualquier otro logro y estado v2.
  final Map<String, DateTime?> achievedAt;

  ActivityState copyWith({
    Set<String>? completedActivityIds,
    Map<String, DateTime?>? achievedAt,
  }) => ActivityState(
    completedActivityIds: completedActivityIds ?? this.completedActivityIds,
    achievedAt: achievedAt ?? this.achievedAt,
  );
}

class CompletionOutcome {
  const CompletionOutcome({
    required this.justCompleted,
    required this.pointsAdded,
    required this.newAchievementIds,
    required this.newThemeIds,
    required this.totalPoints,
  });

  final bool justCompleted;
  final int pointsAdded;
  final Set<String> newAchievementIds;
  final Set<String> newThemeIds;
  final int totalPoints;
}

/// C07 debe implementar lectura y guardado local del MISMO estado de la app.
/// Debe preservar answers, practices, reviewed, theme y demás campos de v2.
/// La operación save debe fallar si no pudo confirmar la escritura.
abstract class ActivityStore {
  Future<ActivityState> load();
  Future<void> save(ActivityState state);
}

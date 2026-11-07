import 'course.dart';

// C06 Gamificación (SDS v0.2, sección 9). Catálogo acordado por el equipo en
// MR-09: «G-02 Logros y G-03 Desbloqueos» (S2-37, opción b) y «Propuesta G-01
// Puntos» (S2-24). Dart puro: no lee ni escribe almacenamiento.

/// Tipo de regla con que se evalúa un logro (SDS 9.2, R-06).
enum AchievementRule {
  answeredQuestions,
  completedLessons,
  completedPractices,
  allPractices,
  completedModule,
  allModules,
  reviewedQuestions,
}

/// Logro del catálogo G-02.
class Achievement {
  const Achievement(
    this.id,
    this.name,
    this.condition, {
    required this.rule,
    this.threshold = 1,
    this.moduleId,
  });
  final String id;
  final String name;

  /// Texto que ve el estudiante en CU-06 («Condición cumplida: …»).
  final String condition;
  final AchievementRule rule;
  final int threshold;

  /// Solo para [AchievementRule.completedModule].
  final String? moduleId;
}

/// Tema de color del catálogo G-03 (opción b). No bloquea contenido.
class VisualTheme {
  const VisualTheme(
    this.id,
    this.name,
    this.condition, {
    this.unlockedBy = const {},
  });
  final String id;
  final String name;

  /// Texto de la condición de desbloqueo.
  final String condition;

  /// Logros que lo desbloquean (basta uno). Vacío: disponible desde el inicio.
  final Set<String> unlockedBy;
}

/// Datos del avance que usan las reglas (SDS 9.2, ProgressFacts).
class ProgressFacts {
  const ProgressFacts({
    required this.answeredQuestions,
    required this.completedLessons,
    required this.completedPractices,
    required this.totalPractices,
    required this.completedModules,
    required this.totalModules,
    required this.reviewedQuestions,
  });
  final int answeredQuestions;
  final int completedLessons;
  final int completedPractices;
  final int totalPractices;
  final Set<String> completedModules;
  final int totalModules;
  final int reviewedQuestions;
}

abstract final class Gamification {
  /// G-01 (P-01): puntos por la primera finalización guardada de una actividad.
  static const pointsPerPractice = 10;
  static const defaultThemeId = 'U-00';

  /// G-02: 10 logros (L-01 a L-09 y L-11). Condiciones tal como en el catálogo.
  static const achievements = [
    Achievement(
      'L-01',
      'Primer paso',
      'Responde tu primera pregunta.',
      rule: AchievementRule.answeredQuestions,
    ),
    Achievement(
      'L-02',
      'Subtema completo',
      'Responde todas las preguntas de un subtema.',
      rule: AchievementRule.completedLessons,
    ),
    Achievement(
      'L-03',
      'Manos a la obra',
      'Realiza tu primera actividad.',
      rule: AchievementRule.completedPractices,
    ),
    Achievement(
      'L-04',
      'Práctica constante',
      'Realiza 5 actividades.',
      rule: AchievementRule.completedPractices,
      threshold: 5,
    ),
    Achievement(
      'L-05',
      'Todas las prácticas',
      'Realiza las 10 actividades.',
      rule: AchievementRule.allPractices,
    ),
    Achievement(
      'L-06',
      'Estructuras en orden',
      'Completa el módulo «Estructuras y algoritmos».',
      rule: AchievementRule.completedModule,
      moduleId: 'm1',
    ),
    Achievement(
      'L-07',
      'Mente orientada a objetos',
      'Completa el módulo «Programación y objetos».',
      rule: AchievementRule.completedModule,
      moduleId: 'm2',
    ),
    Achievement(
      'L-08',
      'Datos bien relacionados',
      'Completa el módulo «Datos y relaciones».',
      rule: AchievementRule.completedModule,
      moduleId: 'm3',
    ),
    Achievement(
      'L-09',
      'Pensando en las personas',
      'Completa el módulo «Diseño para las personas».',
      rule: AchievementRule.completedModule,
      moduleId: 'm4',
    ),
    Achievement(
      'L-11',
      'Recorrido completo',
      'Completa los 4 módulos.',
      rule: AchievementRule.allModules,
    ),
  ];

  /// G-03 (opción b): temas de color.
  static const themes = [
    VisualTheme('U-00', 'Bosque', 'Disponible desde el inicio.'),
    VisualTheme(
      'U-01',
      'Océano',
      'Obtén el logro «Manos a la obra».',
      unlockedBy: {'L-03'},
    ),
    VisualTheme(
      'U-02',
      'Atardecer',
      'Completa tu primer módulo.',
      unlockedBy: {'L-06', 'L-07', 'L-08', 'L-09'},
    ),
    VisualTheme(
      'U-03',
      'Noche',
      'Obtén el logro «Recorrido completo».',
      unlockedBy: {'L-11'},
    ),
  ];

  static bool complete(Practice p, Map<String, List<int>> orders) {
    final order = orders[p.id] ?? [];
    return p.steps.isNotEmpty &&
        order.length == p.steps.length &&
        List.generate(order.length, (i) => order[i] == i).every((v) => v);
  }

  static Set<String> completedPracticeIds(
    List<CourseModule> modules,
    Map<String, List<int>> orders,
  ) => {
    for (final m in modules)
      for (final t in m.topics)
        if (complete(t.practice, orders)) t.practice.id,
  };

  /// Calcula los hechos del avance a partir del estado guardado.
  static ProgressFacts facts(
    List<CourseModule> modules,
    Map<String, int> answers,
    Map<String, List<int>> orders, [
    Map<String, int> reviewAnswers = const {},
  ]) {
    bool done(Iterable<Question> scope) =>
        scope.isNotEmpty && scope.every((q) => answers.containsKey(q.id));
    final lessons = modules.expand((m) => m.topics).expand((t) => t.lessons);
    final questions = lessons.expand((l) => l.questions);
    final activities = modules
        .expand((m) => m.topics)
        .map((t) => t.practice)
        .where((p) => p.steps.isNotEmpty);
    return ProgressFacts(
      answeredQuestions: questions
          .where((q) => answers.containsKey(q.id))
          .length,
      completedLessons: lessons.where((l) => done(l.questions)).length,
      completedPractices: completedPracticeIds(modules, orders).length,
      totalPractices: activities.length,
      completedModules: {
        for (final m in modules)
          if (done(m.questions)) m.id,
      },
      totalModules: modules.length,
      // L-10: preguntas respondidas mal en el estudio y acertadas en el repaso.
      reviewedQuestions: questions
          .where(
            (q) =>
                answers.containsKey(q.id) &&
                answers[q.id] != q.correctIndex &&
                reviewAnswers[q.id] == q.correctIndex,
          )
          .length,
    );
  }

  /// ¿Se cumple la condición del logro con este avance?
  static bool isAchieved(Achievement a, ProgressFacts f) => switch (a.rule) {
    AchievementRule.answeredQuestions => f.answeredQuestions >= a.threshold,
    AchievementRule.completedLessons => f.completedLessons >= a.threshold,
    AchievementRule.completedPractices => f.completedPractices >= a.threshold,
    AchievementRule.allPractices =>
      f.totalPractices > 0 && f.completedPractices >= f.totalPractices,
    AchievementRule.completedModule => f.completedModules.contains(a.moduleId),
    AchievementRule.allModules =>
      f.totalModules > 0 && f.completedModules.length >= f.totalModules,
    AchievementRule.reviewedQuestions => f.reviewedQuestions >= a.threshold,
  };

  /// IDs de los logros cuya condición se cumple.
  static Set<String> achievedIds(ProgressFacts f) => {
    for (final a in achievements)
      if (isAchieved(a, f)) a.id,
  };

  static Set<String> eligible(
    List<CourseModule> modules,
    Map<String, int> answers,
    Map<String, List<int>> orders, [
    Map<String, int> reviewAnswers = const {},
  ]) => achievedIds(facts(modules, answers, orders, reviewAnswers));

  static Set<String> unlocked(Iterable<String> earned) {
    final ids = earned.toSet();
    return {
      for (final t in themes)
        if (t.unlockedBy.isEmpty || t.unlockedBy.any(ids.contains)) t.id,
    };
  }

  /// Texto del aviso de recompensas nuevas (catálogo G-02 2.1.4 y G-03 3.2.3).
  static String rewardMessage(
    List<Achievement> newAchievements,
    List<VisualTheme> newThemes,
  ) {
    final parts = <String>[
      if (newAchievements.length == 1)
        '¡Logro obtenido: ${newAchievements.first.name}!'
      else if (newAchievements.length > 1)
        '¡Logros obtenidos: ${newAchievements.map((a) => a.name).join(', ')}!',
      if (newThemes.length == 1)
        'Desbloqueaste el tema ${newThemes.first.name}.'
      else if (newThemes.length > 1)
        'Desbloqueaste los temas ${newThemes.map((t) => t.name).join(', ')}.',
    ];
    return parts.join(' ');
  }
}

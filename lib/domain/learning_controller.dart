import 'package:flutter/foundation.dart';

import '../data/progress_store.dart';
import 'catalog_validation.dart';
import '../data/catalog_validation.dart' as identity_validation;
import 'course.dart';
import 'gamification.dart';

class LearningController extends ChangeNotifier {
  LearningController({required this.modules, required this.store});
  final List<CourseModule> modules;
  final ProgressStore store;
  ProgressSnapshot _state = ProgressSnapshot();
  bool ready = false;
  bool saving = false;
  String? loadError;
  String? saveError;

  Iterable<Lesson> get lessons =>
      modules.expand((m) => m.topics).expand((t) => t.lessons);
  Iterable<Question> get questions => lessons.expand((l) => l.questions);
  Iterable<Practice> get practices => modules
      .expand((m) => m.topics)
      .map((t) => t.practice)
      .where((p) => p.steps.isNotEmpty);
  int get answeredCount => questions.where((q) => answerFor(q) != null).length;
  int get questionCount => questions.length;
  double get progress => questionCount == 0 ? 0 : answeredCount / questionCount;
  int get completedPractices => practices.where(practiceCompleted).length;
  static const pointsPerPractice = Gamification.pointsPerPractice;
  int get points => _state.points ?? 0;
  Map<String, String?> get earnedAchievements => _state.achievements;
  String get selectedTheme => _state.selectedTheme;
  Set<String> get unlockedThemes =>
      Gamification.unlocked(earnedAchievements.keys);
  List<Achievement> newAchievements = [];
  List<VisualTheme> newThemes = [];
  int? answerFor(Question question) => _state.answers[question.id];
  int? reviewAnswerFor(Question question) => _state.reviewAnswers[question.id];

  bool needsReview(Question question) =>
      answerFor(question) != null &&
      answerFor(question) != question.correctIndex &&
      reviewAnswerFor(question) != question.correctIndex;

  List<Question> pendingReview(Iterable<Question> scope) =>
      scope.where(needsReview).toList(growable: false);
  List<int> orderFor(Practice practice) => _state.practices[practice.id] ?? [];

  bool practiceCompleted(Practice practice) {
    return Gamification.complete(practice, _state.practices);
  }

  ProgressStatus statusForQuestions(Iterable<Question> questions) {
    final all = questions.toList();
    final answered = all.where((q) => answerFor(q) != null).length;
    if (answered == 0) return ProgressStatus.notStarted;
    return answered == all.length
        ? ProgressStatus.completed
        : ProgressStatus.inProgress;
  }

  ProgressStatus lessonStatus(Lesson lesson) =>
      statusForQuestions(lesson.questions);
  ProgressStatus topicStatus(Topic topic) =>
      statusForQuestions(topic.lessons.expand((l) => l.questions));
  ProgressStatus moduleStatus(CourseModule module) =>
      statusForQuestions(module.questions);

  /// D-S1-01 · RP-01: mensaje cuando el catálogo no pasa la validación.
  static const contentUnavailable =
      'Contenido no disponible. El catálogo de la aplicación tiene errores; tu avance guardado no se modificó.';

  /// Problemas encontrados en el catálogo en la última carga (vacío si es
  /// válido).
  List<String> catalogErrors = const [];

  Future<void> load() async {
    ready = false;
    loadError = null;
    notifyListeners();
    // Validar antes de leer o escribir el avance: un catálogo inválido no se
    // usa y el almacenamiento no se toca.
    catalogErrors = validateCatalog(modules);
    if (catalogErrors.isNotEmpty) {
      loadError = contentUnavailable;
      notifyListeners();
      return;
    }
    try {
      identity_validation.validateCatalog(modules);
    } on FormatException {
      loadError = 'Contenido no disponible. El catálogo contiene identificadores o preguntas inválidos. Tus datos guardados se conservan.';
      notifyListeners();
      return;
    }
    try {
      final state = await store.load();
      final byId = {for (final q in questions) q.id: q};
      for (final entry in state.reviewAnswers.entries) {
        final q = byId[entry.key];
        if (q == null ||
            entry.value < 0 ||
            entry.value >= q.options.length ||
            state.answers[q.id] == null ||
            state.answers[q.id] == q.correctIndex) {
          throw const FormatException('Repaso fuera del catálogo');
        }
      }
      // Reject inconsistent data without silently discarding the saved copy.
      for (final q in questions) {
        final answer = state.answers[q.id];
        if (answer != null && (answer < 0 || answer >= q.options.length)) {
          throw const FormatException('Respuesta fuera del catálogo');
        }
      }
      for (final p in practices) {
        final order = state.practices[p.id] ?? [];
        if (order.length > p.steps.length ||
            order.toSet().length != order.length ||
            order.any((i) => i < 0 || i >= p.steps.length)) {
          throw const FormatException('Actividad fuera del catálogo');
        }
      }
      final completed = Gamification.completedPracticeIds(
        modules,
        state.practices,
      );
      final eligible = Gamification.eligible(
        modules,
        state.answers,
        state.practices,
        state.reviewAnswers,
      );
      if (state.points != null) {
        final rewarded = state.rewardedPractices.toSet();
        if (rewarded.length != state.rewardedPractices.length ||
            !setEquals(rewarded, completed) ||
            state.points != rewarded.length * pointsPerPractice ||
            // Ningún logro guardado sin su condición. Un logro que el avance
            // ya cumple y no está guardado (p. ej. L-10, agregado después del
            // formato 3) se reconoce como avance previo, sin fecha (CU-06).
            !eligible.containsAll(state.achievements.keys) ||
            state.achievements.values.any(
              (date) => date != null && DateTime.tryParse(date) == null,
            ) ||
            !Gamification.unlocked(eligible).contains(state.selectedTheme)) {
          throw const FormatException('Gamificación inconsistente');
        }
      }
      // Recover old achievements without inventing historical dates or writing
      // on a read. The next explicit action persists the complete snapshot.
      _state = _withGamification(state, historical: true);
      newAchievements = [];
      newThemes = [];
      ready = true;
    } catch (_) {
      loadError = 'No pudimos recuperar tu avance. Tus datos guardados se conservan. Intenta de nuevo.';
    }
    notifyListeners();
  }

  Future<bool> answer(Question question, int index) async {
    if (!questions.any((q) => identical(q, question)) ||
        index < 0 ||
        index >= question.options.length) {
      return false;
    }
    if (answerFor(question) != null) {
      newAchievements = [];
      newThemes = [];
      return true;
    }
    return _commit(
      ProgressSnapshot(
        answers: {..._state.answers, question.id: index},
        practices: _state.practices,
        reviewAnswers: _state.reviewAnswers,
      ),
      award: true,
    );
  }

  Future<bool> saveOrder(Practice practice, List<int> order) async {
    if (!practices.any((p) => identical(p, practice)) ||
        order.length > practice.steps.length ||
        order.toSet().length != order.length ||
        order.any((i) => i < 0 || i >= practice.steps.length)) {
      return false;
    }
    if (practiceCompleted(practice)) {
      newAchievements = [];
      newThemes = [];
      return true;
    }
    return _commit(
      ProgressSnapshot(
        answers: _state.answers,
        practices: {..._state.practices, practice.id: order},
        reviewAnswers: _state.reviewAnswers,
      ),
      award: true,
    );
  }

  Future<bool> reviewAnswer(Question question, int index) async {
    if (!questions.any((q) => identical(q, question)) ||
        !needsReview(question) ||
        index < 0 ||
        index >= question.options.length) {
      return false;
    }
    return _commit(
      ProgressSnapshot(
        answers: _state.answers,
        practices: _state.practices,
        reviewAnswers: {..._state.reviewAnswers, question.id: index},
      ),
      // El repaso conserva las recompensas originales.
    );
  }

  ProgressSnapshot _withGamification(
    ProgressSnapshot state, {
    bool historical = false,
    String? theme,
  }) {
    final eligible = Gamification.eligible(
      modules,
      state.answers,
      state.practices,
      state.reviewAnswers,
    );
    final existing = historical ? state.achievements : _state.achievements;
    final completed = Gamification.completedPracticeIds(
      modules,
      state.practices,
    );
    return ProgressSnapshot(
      answers: state.answers,
      practices: state.practices,
      reviewAnswers: state.reviewAnswers,
      points: completed.length * pointsPerPractice,
      rewardedPractices: completed.toList(),
      achievements: {
        for (final id in eligible)
          id: existing.containsKey(id)
              ? existing[id]
              : (historical ? null : DateTime.now().toUtc().toIso8601String()),
      },
      selectedTheme:
          theme ?? (historical ? state.selectedTheme : selectedTheme),
    );
  }

  Future<bool> selectTheme(String id) async {
    if (!ready || saving || !unlockedThemes.contains(id)) return false;
    if (id == selectedTheme) return true;
    return _commit(_state, theme: id);
  }

  Future<bool> _commit(
    ProgressSnapshot next, {
    bool award = false,
    String? theme,
  }) async {
    if (!ready || saving) return false;
    saving = true;
    saveError = null;
    newAchievements = [];
    newThemes = [];
    notifyListeners();
    try {
      // Publish progress only after the storage operation succeeds.
      final prepared = _withGamification(next, theme: theme);
      await store.save(prepared);
      if (award) {
        newAchievements = Gamification.achievements
            .where(
              (a) =>
                  prepared.achievements.containsKey(a.id) &&
                  !earnedAchievements.containsKey(a.id),
            )
            .toList();
        final beforeThemes = unlockedThemes;
        newThemes = Gamification.themes
            .where(
              (t) =>
                  Gamification.unlocked(prepared.achievements.keys)
                      .contains(t.id) &&
                  !beforeThemes.contains(t.id),
            )
            .toList();
      }
      _state = prepared;
      return true;
    } catch (_) {
      saveError = 'No se pudo guardar el cambio. Intenta de nuevo.';
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}

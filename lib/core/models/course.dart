enum ProgressStatus {
  notStarted('Sin iniciar'),
  inProgress('En progreso'),
  completed('Completado');

  const ProgressStatus(this.label);
  final String label;
}

class Question {
  const Question({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
  final String id;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;
}

class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.content,
    required this.example,
    required this.questions,
  });
  final String id;
  final String title;
  final String content;
  final String example;
  final List<Question> questions;
}

class Practice {
  const Practice({
    required this.id,
    required this.title,
    required this.instruction,
    required this.steps,
  });
  final String id;
  final String title;
  final String instruction;
  // Canonical order; the interface presents these in a different order.
  final List<String> steps;

  /// D-S1-02 · CA-03: orden en que se presentan los elementos. Es una mezcla
  /// estable (la misma cada vez que se abre la actividad) que nunca coincide
  /// con el orden correcto ni, con 3 o más elementos, con el inverso.
  List<int> get presentationOrder {
    final n = steps.length;
    final identity = List<int>.generate(n, (i) => i);
    if (n < 2) return identity;
    if (n == 2) return [1, 0];
    // Semilla FNV-1a de 32 bits a partir del identificador: igual en todas
    // las plataformas y ejecuciones.
    var seed = 0x811c9dc5;
    for (final unit in id.codeUnits) {
      seed = ((seed ^ unit) * 0x01000193) & 0xffffffff;
    }
    final order = [...identity];
    for (var i = n - 1; i > 0; i--) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      final j = seed % (i + 1);
      final swap = order[i];
      order[i] = order[j];
      order[j] = swap;
    }
    bool same(List<int> other) =>
        List.generate(n, (i) => order[i] == other[i]).every((v) => v);
    if (same(identity) || same(identity.reversed.toList())) {
      // Rotación: 1, 2, …, n-1, 0. No es el orden correcto ni el inverso.
      return [...identity.skip(1), 0];
    }
    return order;
  }
}

class Topic {
  const Topic({
    required this.id,
    required this.title,
    required this.lessons,
    required this.practice,
  });
  final String id;
  final String title;
  final List<Lesson> lessons;
  final Practice practice;
}

class CourseModule {
  const CourseModule({
    required this.id,
    required this.title,
    required this.area,
    required this.description,
    required this.topics,
  });
  final String id;
  final String title;
  final String area;
  final String description;
  final List<Topic> topics;
  Iterable<Question> get questions =>
      topics.expand((t) => t.lessons).expand((l) => l.questions);
}

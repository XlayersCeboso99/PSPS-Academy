import '../domain/course.dart';

/// Validate identity and question data before the catalog reaches the UI.
/// An empty catalog and topics without optional activities remain supported.
void validateCatalog(List<CourseModule> modules) {
  final moduleIds = <String>{};
  final topicIds = <String>{};
  final lessonIds = <String>{};
  final questionIds = <String>{};
  final practiceIds = <String>{};

  void unique(String id, Set<String> ids, String kind) {
    if (id.trim().isEmpty || !ids.add(id)) {
      throw FormatException('Identificador inválido o repetido de $kind');
    }
  }

  for (final module in modules) {
    unique(module.id, moduleIds, 'módulo');
    for (final topic in module.topics) {
      unique(topic.id, topicIds, 'tema');
      if (topic.practice.steps.isNotEmpty) {
        unique(topic.practice.id, practiceIds, 'actividad');
      }
      for (final lesson in topic.lessons) {
        unique(lesson.id, lessonIds, 'subtema');
        for (final question in lesson.questions) {
          unique(question.id, questionIds, 'pregunta');
          if (question.options.length < 2 ||
              question.correctIndex < 0 ||
              question.correctIndex >= question.options.length) {
            throw const FormatException(
              'Opciones o respuesta correcta inválidas',
            );
          }
        }
      }
    }
  }
}

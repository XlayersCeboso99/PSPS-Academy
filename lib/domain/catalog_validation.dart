import 'course.dart';

/// D-S1-01 · RP-01 · TU-06: valida el catálogo antes de usarlo.
///
/// Devuelve la lista de problemas; vacía significa que el catálogo es válido.
/// No modifica el catálogo ni el estado guardado.
///
/// Se rechaza lo que haría cálculos de avance incorrectos: identificadores
/// vacíos o repetidos (el avance se guarda por identificador), subtemas sin
/// preguntas, preguntas con menos de dos opciones o con la respuesta correcta
/// fuera de rango y actividades configuradas con menos de dos elementos.
/// Las estructuras vacías (catálogo, módulo sin temas, tema sin subtemas o
/// sin actividad) no se rechazan: se muestran con su estado vacío (CU-05,
/// CU-08).
List<String> validateCatalog(List<CourseModule> modules) {
  final errors = <String>[];
  final ids = <String>{};

  void checkId(String id, String kind) {
    if (id.trim().isEmpty) {
      errors.add('$kind sin identificador');
    } else if (!ids.add(id)) {
      errors.add('Identificador repetido: $id');
    }
  }

  for (final module in modules) {
    checkId(module.id, 'Módulo');
    for (final topic in module.topics) {
      checkId(topic.id, 'Tema');
      for (final lesson in topic.lessons) {
        checkId(lesson.id, 'Subtema');
        if (lesson.questions.isEmpty) {
          errors.add('El subtema ${lesson.id} no tiene preguntas');
        }
        for (final question in lesson.questions) {
          checkId(question.id, 'Pregunta');
          if (question.options.length < 2) {
            errors.add('La pregunta ${question.id} tiene menos de dos opciones');
          }
          if (question.correctIndex < 0 ||
              question.correctIndex >= question.options.length) {
            errors.add(
              'La pregunta ${question.id} tiene la respuesta correcta fuera de rango',
            );
          }
        }
      }
      final practice = topic.practice;
      if (practice.steps.isNotEmpty) {
        checkId(practice.id, 'Actividad');
        if (practice.steps.length < 2) {
          errors.add('La actividad ${practice.id} tiene menos de dos elementos');
        }
      }
    }
  }
  return errors;
}

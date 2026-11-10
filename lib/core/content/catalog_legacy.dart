import 'package:psps/core/models/course.dart';

/// Contenido del catálogo publicado hasta el Sprint 3 (20 preguntas y 10
/// actividades), congelado literalmente.
///
/// Sirve para conservar los logros obtenidos con ese catálogo cuando se
/// amplía: un logro ya guardado sigue siendo válido si se cumple con el
/// catálogo actual o con [legacyView]. No se usa para otorgar logros nuevos.
/// No debe modificarse al agregar contenido.
const Set<String> legacyContentIds = {
  // Preguntas.
  'CT-01.s1.q1',
  'CT-01.s1.q2',
  'CT-02.s1.q1',
  'CT-02.s1.q2',
  'CT-03.s1.q1',
  'CT-03.s1.q2',
  'CT-04.s1.q1',
  'CT-04.s1.q2',
  'CT-05.s1.q1',
  'CT-05.s1.q2',
  'CT-06.s1.q1',
  'CT-06.s1.q2',
  'CT-07.s1.q1',
  'CT-07.s1.q2',
  'CT-08.s1.q1',
  'CT-08.s1.q2',
  'CT-09.s1.q1',
  'CT-09.s1.q2',
  'CT-10.s1.q1',
  'CT-10.s1.q2',
  // Actividades.
  'CT-01.a1',
  'CT-02.a1',
  'CT-03.a1',
  'CT-04.a1',
  'CT-05.a1',
  'CT-06.a1',
  'CT-07.a1',
  'CT-08.a1',
  'CT-09.a1',
  'CT-10.a1',
};

/// Vista de [modules] restringida al contenido legado ([legacyIds], por
/// defecto [legacyContentIds]).
///
/// Conserva los mismos módulos, temas y subtemas con sus identificadores,
/// pero solo con las preguntas legadas y sin actividades adicionales. La
/// actividad principal se conserva si es legada; si no, se sustituye por una
/// actividad vacía (sin elementos), que las reglas tratan como inexistente.
/// Se omiten los módulos, temas y subtemas que no contienen contenido legado
/// (por ejemplo, un módulo agregado después), para que no cambien los
/// totales con que se evaluaban los logros.
List<CourseModule> legacyView(
  List<CourseModule> modules, {
  Set<String> legacyIds = legacyContentIds,
}) {
  final view = <CourseModule>[];
  for (final module in modules) {
    final topics = <Topic>[];
    for (final topic in module.topics) {
      final lessons = <Lesson>[
        for (final lesson in topic.lessons)
          if (lesson.questions.any((q) => legacyIds.contains(q.id)))
            Lesson(
              id: lesson.id,
              title: lesson.title,
              content: lesson.content,
              example: lesson.example,
              questions: [
                for (final q in lesson.questions)
                  if (legacyIds.contains(q.id)) q,
              ],
            ),
      ];
      final legacyPractice = legacyIds.contains(topic.practice.id);
      if (lessons.isEmpty && !legacyPractice) continue;
      topics.add(
        Topic(
          id: topic.id,
          title: topic.title,
          lessons: lessons,
          practice: legacyPractice
              ? topic.practice
              : Practice(
                  id: topic.practice.id,
                  title: topic.practice.title,
                  instruction: topic.practice.instruction,
                  steps: const [],
                ),
        ),
      );
    }
    if (topics.isEmpty) continue;
    view.add(
      CourseModule(
        id: module.id,
        title: module.title,
        area: module.area,
        description: module.description,
        topics: topics,
      ),
    );
  }
  return view;
}

import 'package:flutter_test/flutter_test.dart';
import 'package:psps/core/content/catalog.dart';

void main() {
  test(
    'INV-01: migrated catalog keeps all historical IDs and parent links',
    () {
      // progress_test.dart ('catalog has ten required topics and unique IDs') y
      // module_exploration_test.dart CP05-01 ya comprueban unicidad y CT-01…10.
      // Variante: snapshot literal de TODOS los IDs, sus padres y su orden real
      // (CT-05 pertenece a m3), sin regenerar el oráculo desde el catálogo.
      final topics = catalog.expand((m) => m.topics).toList();
      final lessons = topics.expand((t) => t.lessons).toList();
      final questions = lessons.expand((l) => l.questions).toList();
      final practices = topics.map((t) => t.practice).toList();
      expect(
        {
          'modules': catalog.length,
          'topics': topics.length,
          'lessons': lessons.length,
          'questions': questions.length,
          'practices': practices.length,
          'availablePractices': practices
              .where((p) => p.steps.isNotEmpty)
              .length,
        },
        {
          'modules': 4,
          'topics': 10,
          'lessons': 10,
          'questions': 20,
          'practices': 10,
          'availablePractices': 10,
        },
      );
      expect(catalog.map((m) => m.id), ['m1', 'm2', 'm3', 'm4']);
      expect(
        [
          for (final m in catalog)
            for (final t in m.topics)
              for (final l in t.lessons)
                [
                  m.id,
                  t.id,
                  l.id,
                  l.questions.map((q) => q.id).toList(),
                  t.practice.id,
                ],
        ],
        [
          [
            'm1',
            'CT-01',
            'CT-01.s1',
            ['CT-01.s1.q1', 'CT-01.s1.q2'],
            'CT-01.a1',
          ],
          [
            'm1',
            'CT-02',
            'CT-02.s1',
            ['CT-02.s1.q1', 'CT-02.s1.q2'],
            'CT-02.a1',
          ],
          [
            'm1',
            'CT-03',
            'CT-03.s1',
            ['CT-03.s1.q1', 'CT-03.s1.q2'],
            'CT-03.a1',
          ],
          [
            'm1',
            'CT-04',
            'CT-04.s1',
            ['CT-04.s1.q1', 'CT-04.s1.q2'],
            'CT-04.a1',
          ],
          [
            'm2',
            'CT-06',
            'CT-06.s1',
            ['CT-06.s1.q1', 'CT-06.s1.q2'],
            'CT-06.a1',
          ],
          [
            'm2',
            'CT-07',
            'CT-07.s1',
            ['CT-07.s1.q1', 'CT-07.s1.q2'],
            'CT-07.a1',
          ],
          [
            'm2',
            'CT-08',
            'CT-08.s1',
            ['CT-08.s1.q1', 'CT-08.s1.q2'],
            'CT-08.a1',
          ],
          [
            'm3',
            'CT-05',
            'CT-05.s1',
            ['CT-05.s1.q1', 'CT-05.s1.q2'],
            'CT-05.a1',
          ],
          [
            'm3',
            'CT-09',
            'CT-09.s1',
            ['CT-09.s1.q1', 'CT-09.s1.q2'],
            'CT-09.a1',
          ],
          [
            'm4',
            'CT-10',
            'CT-10.s1',
            ['CT-10.s1.q1', 'CT-10.s1.q2'],
            'CT-10.a1',
          ],
        ],
      );
    },
  );
}

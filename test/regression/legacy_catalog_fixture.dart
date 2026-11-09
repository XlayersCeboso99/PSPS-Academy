import 'package:flutter_test/flutter_test.dart';
import 'package:psps/core/content/catalog_legacy.dart';
import 'package:psps/core/models/course.dart';

// Oráculo literal anterior a la ampliación: no se deriva del catálogo probado.
const historicalCatalogRows = [
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
];

void expectHistoricalCatalog(List<CourseModule> modules) {
  expect(modules.map((m) => m.id), ['m1', 'm2', 'm3', 'm4']);
  expect([
    for (final module in modules)
      for (final topic in module.topics)
        for (final lesson in topic.lessons)
          [
            module.id,
            topic.id,
            lesson.id,
            lesson.questions
                .map((q) => q.id)
                .where(legacyContentIds.contains)
                .toList(),
            topic.practice.id,
          ],
  ], historicalCatalogRows);
  final historicalIds = <String>{
    for (final row in historicalCatalogRows) ...[
      ...row[3] as List<String>,
      row[4] as String,
    ],
  };
  expect(historicalIds, hasLength(30));
  expect(legacyContentIds, historicalIds);
}

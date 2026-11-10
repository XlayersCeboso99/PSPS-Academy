import 'package:flutter_test/flutter_test.dart';
import 'package:psps/core/content/catalog.dart';
import 'package:psps/core/content/catalog_legacy.dart';

import 'legacy_catalog_fixture.dart';

void main() {
  test(
    'INV-01: migrated catalog keeps all historical IDs and parent links',
    () {
      // El inventario histórico usa un oráculo literal independiente; el actual
      // incluye todas las actividades del tema, no solo la principal.
      expectHistoricalCatalog(catalog);
      final topics = catalog.expand((m) => m.topics).toList();
      final lessons = topics.expand((t) => t.lessons).toList();
      final questions = lessons.expand((l) => l.questions).toList();
      final practices = topics.expand((t) => t.practices).toList();
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
          'questions': 40,
          'practices': 20,
          'availablePractices': 20,
        },
      );
      final ids = [
        ...catalog.map((m) => m.id),
        ...topics.map((t) => t.id),
        ...lessons.map((l) => l.id),
        ...questions.map((q) => q.id),
        ...practices.map((p) => p.id),
      ];
      expect(ids.toSet(), hasLength(ids.length));
      final contentIds = [
        ...questions.map((q) => q.id),
        ...practices.map((p) => p.id),
      ];
      final added = contentIds.where((id) => !legacyContentIds.contains(id));
      expect(added, hasLength(contentIds.length - legacyContentIds.length));
      for (final id in added) {
        expect(id, matches(RegExp(r'^CT-\d{2}\.(s1\.q[34]|a2)$')), reason: id);
      }
    },
  );
}

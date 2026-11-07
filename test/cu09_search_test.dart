import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psps/data/catalog.dart';
import 'package:psps/domain/content_search.dart';
import 'package:psps/domain/course.dart';
import 'package:psps/domain/learning_controller.dart';
import 'package:psps/ui/app.dart';

import 'support.dart';

// CU-09 Buscar contenidos por palabra clave · RF-11 · CA-11.
// Diseño: borrador S2-36 (M-09A a M-09D y reglas 2.3). Los IDs CP09
// identifican estas pruebas ejecutables (WP.14 de CU-09); entre paréntesis,
// el caso propuesto en el diseño (TU-09 / TW-09).

const fixtureQuestion = Question(
  id: 'X-01.s1.q1',
  prompt: 'secretopregunta',
  options: ['secretopcion', 'otra'],
  correctIndex: 0,
  explanation: 'secretoexplicacion',
);

const fixtureModule = CourseModule(
  id: 'mx',
  title: 'Módulo de prueba',
  area: 'Área de prueba',
  description: 'Solo para pruebas.',
  topics: [
    Topic(
      id: 'X-01',
      title: 'Tema de prueba',
      lessons: [
        Lesson(
          id: 'X-01.s1',
          title: 'Subtema de prueba',
          content: 'Contenido sobre la interacción con el usuario.',
          example: 'Primera línea\nsegunda línea',
          questions: [fixtureQuestion],
        ),
      ],
      practice: Practice(
        id: 'X-01.a1',
        title: 'secretopractica',
        instruction: 'instruccionoculta',
        steps: ['uno', 'dos'],
      ),
    ),
  ],
);

final search = ContentSearch(catalog);

List<String> topics(String query) =>
    search.search(query).map((r) => r.topic.id).toList();

Topic topicById(String id) =>
    catalog.expand((m) => m.topics).firstWhere((t) => t.id == id);

Future<(LearningController, MemoryStore)> fixture([
  List<CourseModule>? modules,
]) async {
  final store = MemoryStore();
  final controller = LearningController(
    modules: modules ?? catalog,
    store: store,
  );
  await controller.load();
  expect(controller.ready, isTrue);
  return (controller, store);
}

Future<void> reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await Scrollable.ensureVisible(tester.element(finder), alignment: .25);
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await reveal(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pumpAndSettle();
}

void main() {
  test('CP09-01 (TU-09-01): «clase» finds CT-08 by title, then CT-07 by content', () {
    final results = search.search('clase');
    expect(results.map((r) => r.topic.id), ['CT-08', 'CT-07']);
    expect(results.map((r) => r.field), [
      MatchField.title,
      MatchField.content,
    ]);
    expect(results.first.module.id, 'm2');
  });

  test('CP09-02 (TU-09-02): case and outer spaces do not change results', () {
    for (final query in ['CLASE', 'Clase', '  clase  ', 'cLaSe']) {
      expect(topics(query), topics('clase'), reason: query);
    }
  });

  test('CP09-03 (TU-09-03): accents are ignored and ñ is kept', () {
    expect(topics('interaccion'), contains('CT-10'));
    expect(topics('INTERACCIÓN'), topics('interaccion'));
    expect(topics('interacción'), topics('interaccion'));
    expect(ContentSearch.normalize('Diseño'), 'diseño');
    expect(ContentSearch.normalize('ÁÉÍÓÚÜ'), 'aeiouu');
  });

  test('CP09-04 (TU-09-04): fewer than 3 characters does not search (A2)', () {
    for (final query in ['', 'c', 'cl', '  cl  ', '   ']) {
      expect(search.search(query), isEmpty, reason: query);
      expect(ContentSearch.canSearch(query), isFalse, reason: query);
    }
    expect(ContentSearch.canSearch('cla'), isTrue);
  });

  test('CP09-05 (TU-09-05): a word that is not in the catalog has no results', () {
    expect(search.search('compiladores'), isEmpty);
  });

  test(
    'CP09-06 (TU-09-06): questions, options, explanations and activities are not searched',
    () {
      final local = ContentSearch(const [fixtureModule]);
      for (final word in [
        'secretopregunta',
        'secretopcion',
        'secretoexplicacion',
        'secretopractica',
        'instruccionoculta',
      ]) {
        expect(local.search(word), isEmpty, reason: word);
      }
    },
  );

  test(
    'CP09-07: one result per lesson; a title match is listed only under titles',
    () {
      for (final query in ['pila', 'clase', 'datos', 'objeto', 'interfaz']) {
        final ids = search.search(query).map((r) => r.lesson.id).toList();
        expect(ids.toSet().length, ids.length, reason: query);
      }
      final pila = search.search('pila').where((r) => r.topic.id == 'CT-02');
      expect(pila.single.field, MatchField.title);
    },
  );

  test(
    'CP09-08: phrases match across repeated spaces and line breaks; snippets are one line',
    () {
      expect(topics('pila   restante'), contains('CT-02'));
      expect(topics('estudiante atributo'), contains('CT-08'));
      final local = ContentSearch(const [fixtureModule]);
      expect(local.search('primera línea segunda').single.lesson.id, 'X-01.s1');
      for (final query in ['clase', 'estudiante atributo', 'pila']) {
        for (final r in search.search(query)) {
          expect(r.snippet.contains('\n'), isFalse, reason: query);
        }
      }
    },
  );

  test('CP09-09: the highlighted range is the match; snippet is short', () {
    for (final query in ['clase', 'interaccion', 'pila restante']) {
      final term = ContentSearch.term(query);
      for (final r in search.search(query)) {
        final marked = r.snippet.substring(
          r.matchStart,
          r.matchStart + r.matchLength,
        );
        expect(ContentSearch.normalize(marked), term, reason: query);
        expect(r.snippet.length, lessThanOrEqualTo(term.length + 92));
      }
    }
  });

  testWidgets(
    'CP09-10 (TW-09-01): type «clase», see route and status, open CT-08 without progress',
    (tester) async {
      final (c, store) = await fixture();
      await tester.pumpWidget(MaterialApp(home: SearchScreen(controller: c)));
      await tester.pumpAndSettle();
      expect(find.text('Escribe al menos 3 letras'), findsOneWidget);
      await type(tester, 'clase');
      expect(find.text('2 resultados para «clase»'), findsOneWidget);
      expect(find.text('EN TÍTULOS'), findsOneWidget);
      expect(find.text('EN EL CONTENIDO'), findsOneWidget);
      final topic = topicById('CT-08');
      final lesson = topic.lessons.first;
      final result = find.byKey(ValueKey('cu09.result.${lesson.id}'));
      expect(
        find.descendant(
          of: result,
          matching: find.text('Programación y objetos › Clases y objetos'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: result, matching: find.text('Sin iniciar')),
        findsOneWidget,
      );
      await tap(tester, find.text(lesson.title));
      expect(find.byType(LessonScreen), findsOneWidget);
      expect(find.text('${topic.title} / ${lesson.title}'), findsOneWidget);
      expect(c.answeredCount, 0);
      expect(store.writes, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'CP09-11 (TW-09-02): no results (A1), search can be changed, Explore returns home',
    (tester) async {
      final (c, store) = await fixture();
      await tester.pumpWidget(PspsApp(controller: c));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Buscar contenidos'));
      await tester.pumpAndSettle();
      await type(tester, 'compiladores');
      expect(
        find.text('No se encontraron temas con «compiladores»'),
        findsOneWidget,
      );
      await type(tester, 'pila');
      expect(find.byKey(const ValueKey('cu09.empty')), findsNothing);
      expect(find.textContaining('para «pila»'), findsOneWidget);
      await type(tester, 'compiladores');
      await tap(tester, find.text('Explorar módulos'));
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(SearchScreen), findsNothing);
      expect(store.writes, 0);
    },
  );

  testWidgets('CP09-12: cancel goes back without changes (A3)', (tester) async {
    final (c, store) = await fixture();
    await tester.pumpWidget(PspsApp(controller: c));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Buscar contenidos'));
    await tester.pumpAndSettle();
    await type(tester, 'clase');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(c.answeredCount, 0);
    expect(c.points, 0);
    expect(store.writes, 0);
  });

  testWidgets('CP09-13: one result uses the singular and shows the progress status', (
    tester,
  ) async {
    final (c, store) = await fixture(const [fixtureModule]);
    await c.answer(fixtureQuestion, 1);
    final writes = store.writes;
    await tester.pumpWidget(MaterialApp(home: SearchScreen(controller: c)));
    await tester.pumpAndSettle();
    await type(tester, 'interaccion');
    expect(find.text('1 resultado para «interaccion»'), findsOneWidget);
    expect(find.text('Completado'), findsOneWidget);
    expect(store.writes, writes);
  });

  testWidgets('CP09-14: empty catalog reports the error and allows retry (E1)', (
    tester,
  ) async {
    final (c, store) = await fixture(const []);
    await tester.pumpWidget(MaterialApp(home: SearchScreen(controller: c)));
    await tester.pumpAndSettle();
    expect(find.text('No pudimos recuperar el catálogo local.'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cu09.error')), findsOneWidget);
    expect(store.writes, 0);
  });

  testWidgets(
    'CP09-15: results fit a 320 x 640 screen with enlarged text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final (c, store) = await fixture();
      await tester.pumpWidget(MaterialApp(home: SearchScreen(controller: c)));
      await tester.pumpAndSettle();
      await type(tester, 'clase');
      final first = find.byKey(
        ValueKey('cu09.result.${topicById('CT-08').lessons.first.id}'),
      );
      await reveal(tester, first);
      expect(tester.takeException(), isNull);
      expect(store.writes, 0);
    },
  );
}

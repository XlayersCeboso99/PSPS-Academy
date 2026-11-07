import 'course.dart';

// C02 · CU-09 Buscar contenidos por palabra clave (RF-11, CA-11).
// Diseño: borrador S2-36, sección 2.3. Dart puro y solo lectura: busca en el
// catálogo cargado en memoria, sin red y sin escribir en el estado local.

enum MatchField { title, content }

class SearchResult {
  const SearchResult({
    required this.module,
    required this.topic,
    required this.lesson,
    required this.field,
    required this.snippet,
    required this.matchStart,
    required this.matchLength,
  });
  final CourseModule module;
  final Topic topic;
  final Lesson lesson;
  final MatchField field;
  final String snippet;
  final int matchStart;
  final int matchLength;
}

class ContentSearch {
  const ContentSearch(this.modules);
  final List<CourseModule> modules;

  /// Mínimo de caracteres para buscar (flujo alterno A2).
  static const minLength = 3;

  /// Caracteres de contexto antes y después de la coincidencia (unos 90).
  static const _before = 30;
  static const _after = 60;

  /// Regla 2.3.2: minúsculas y sin acentos (á é í ó ú ü), conservando la ñ.
  /// Los saltos de línea y tabuladores cuentan como espacio para que una frase
  /// coincida aunque cambie de renglón. Cada reemplazo conserva la longitud,
  /// así las posiciones sirven para resaltar el texto original.
  static String normalize(String text) {
    var value = text.toLowerCase();
    const from = 'áéíóúü\n\r\t';
    const to = 'aeiouu   ';
    for (var i = 0; i < from.length; i++) {
      value = value.replaceAll(from[i], to[i]);
    }
    return value;
  }

  /// Texto que se busca: sin espacios en los extremos y con los espacios
  /// internos repetidos reducidos a uno (palabra o frase).
  static String term(String query) =>
      normalize(query.trim()).replaceAll(RegExp(r' {2,}'), ' ');

  /// ¿El texto es suficiente para buscar? (A2).
  static bool canSearch(String query) => term(query).runes.length >= minLength;

  List<SearchResult> search(String query) {
    final needle = term(query);
    if (needle.runes.length < minLength) return [];
    final results = <SearchResult>[];
    for (final m in modules) {
      for (final t in m.topics) {
        for (final l in t.lessons) {
          // Regla 2.3.3: nombre y materia del módulo, tema y subtema; luego
          // contenido y ejemplo. Preguntas, opciones, explicaciones y
          // actividades no se buscan (2.3.4).
          final titles = '${m.title} › ${m.area} › ${t.title} › ${l.title}';
          final content = '${l.content}\n${l.example}';
          final titleMatch = normalize(titles).contains(needle);
          final source = titleMatch ? titles : content;
          final at = normalize(source).indexOf(needle);
          if (at < 0) continue;
          final start = (at - _before).clamp(0, source.length);
          final end = (at + needle.length + _after).clamp(0, source.length);
          final prefix = start > 0 ? '…' : '';
          final suffix = end < source.length ? '…' : '';
          final fragment = source
              .substring(start, end)
              .replaceAll(RegExp(r'[\n\r\t]'), ' ');
          results.add(
            SearchResult(
              module: m,
              topic: t,
              lesson: l,
              field: titleMatch ? MatchField.title : MatchField.content,
              snippet: '$prefix$fragment$suffix',
              matchStart: at - start + prefix.length,
              matchLength: needle.length,
            ),
          );
        }
      }
    }
    // Regla 2.3.5 y 2.3.6: un resultado por subtema; primero títulos y después
    // contenido, cada grupo en el orden del catálogo.
    return [
      for (final r in results)
        if (r.field == MatchField.title) r,
      for (final r in results)
        if (r.field == MatchField.content) r,
    ];
  }
}

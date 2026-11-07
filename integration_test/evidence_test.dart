import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:psps/data/catalog.dart';
import 'package:psps/data/progress_store.dart';
import 'package:psps/domain/course.dart';
import 'package:psps/domain/learning_controller.dart';
import 'package:psps/ui/app.dart';

// Run prepare, stop the Android process, then run verify without clearing data.
// This exclusive key never writes the student's normal progress.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const key = 'psps.audit.20261010';
  const phase = String.fromEnvironment('PSPS_PHASE', defaultValue: 'prepare');
  testWidgets('TI-06 $phase: offline journey and real process persistence', (
    tester,
  ) async {
    final prefs = SharedPreferencesAsync();
    if (phase == 'prepare') await prefs.remove(key);
    final c = LearningController(
      modules: catalog,
      store: LocalProgressStore(preferences: prefs, key: key),
    );
    await c.load();
    await tester.pumpWidget(PspsApp(controller: c));
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    Future<void> shot(String name) async {
      await tester.pumpAndSettle();
      await binding.takeScreenshot(name);
    }

    Future<void> tap(Finder f) async {
      if (f.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          f,
          160,
          scrollable: find.byType(Scrollable).first,
        );
      }
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    Future<void> textTap(String label) => tap(find.text(label));
    final topic = catalog.first.topics.first;
    final lesson = topic.lessons.first;
    if (phase == 'prepare') {
      expect(c.answeredCount, 0);
      await shot('E01_inicio_offline');
      await textTap('Estructuras y algoritmos');
      await shot('E02_modulo');
      await textTap('Datos en filas y columnas');
      await textTap('Estudiar subtema');
      await shot('E03_contenido');
      await textTap('Siguiente');
      expect(c.answeredCount, 0);
      await textTap('Ir a preguntas');
      final q1 = lesson.questions.first;
      await textTap(q1.options[(q1.correctIndex + 1) % q1.options.length]);
      await textTap('Comprobar');
      expect(find.text('Sigue aprendiendo'), findsOneWidget);
      expect(c.answeredCount, 1);
      await shot('E04_respuesta_incorrecta');
      await textTap('Siguiente pregunta');
      final q2 = lesson.questions.last;
      await textTap(q2.options[q2.correctIndex]);
      await textTap('Comprobar');
      expect(find.text('¡Respuesta correcta!'), findsOneWidget);
      expect(c.lessonStatus(lesson), ProgressStatus.completed);
      await shot('E05_subtema_completado');
      // Return through the actual navigation stack to the topic screen.
      await tap(find.byType(BackButton));
      await tap(find.byType(BackButton));
      await textTap('Realizar actividad');
      for (final step in topic.practice.steps) {
        await tap(find.widgetWithText(OutlinedButton, step));
      }
      expect(find.text('¡Actividad realizada!'), findsOneWidget);
      expect(c.points, 10);
      await shot('E06_actividad_realizada');
    } else {
      expect(c.answeredCount, 2);
      expect(c.lessonStatus(lesson), ProgressStatus.completed);
      expect(c.completedPractices, 1);
      expect(c.points, 10);
      await textTap('Mi progreso');
      await shot('E07_progreso_tras_reabrir');
      await textTap(topic.title);
      await textTap('Consultar actividad realizada');
      expect(find.text('¡Actividad realizada!'), findsOneWidget);
      expect(c.points, 10);
      await shot('E08_actividad_sin_duplicar');
      await prefs.remove(key);
    }
    expect(tester.takeException(), isNull);
  });
}

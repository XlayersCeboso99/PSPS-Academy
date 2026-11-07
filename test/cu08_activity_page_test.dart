import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psps/features/cu08/activity_engine.dart';
import 'package:psps/features/cu08/activity_models.dart';
import 'package:psps/features/cu08/activity_page.dart';

class ReadOnlyStore implements ActivityStore {
  ReadOnlyStore(this.state);
  final ActivityState state;
  int writes = 0;

  @override
  Future<ActivityState> load() async => state;

  @override
  Future<void> save(ActivityState next) async {
    writes++;
  }
}

void main() {
  testWidgets('CU-08: estados visibles, sin escribir, navegación delegada', (
    tester,
  ) async {
    final activities = [
      const ActivityDefinition(
        id: 'A-01',
        title: 'Actividad 1',
        moduleId: 'm1',
        moduleName: 'Estructuras y algoritmos',
        topicId: 't1',
        topicName: 'Arreglos',
        requiredElementIds: {'e1'},
      ),
      const ActivityDefinition(
        id: 'A-02',
        title: 'Actividad 2',
        moduleId: 'm1',
        moduleName: 'Estructuras y algoritmos',
        topicId: 't1',
        topicName: 'Arreglos',
        requiredElementIds: {'e1'},
      ),
    ];
    final store = ReadOnlyStore(ActivityState(completedActivityIds: {'A-01'}));
    final engine = ActivityEngine(activities: activities, store: store);
    String? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Cu08ActivitiesPage(
          catalog: activities,
          engine: engine,
          onOpenActivity: (item) => opened = item.id,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Realizada'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('Estructuras y algoritmos · Arreglos'), findsOneWidget);
    await tester.tap(find.text('Actividad 2'));
    expect(opened, 'A-02');
    expect(store.writes, 0);
  });
}

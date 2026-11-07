import 'package:flutter_test/flutter_test.dart';
import 'package:psps/features/cu08/activity_engine.dart';
import 'package:psps/features/cu08/activity_models.dart';

class FakeStore implements ActivityStore {
  FakeStore(this.state);
  ActivityState state;
  bool throwOnSave = false;
  int writes = 0;

  @override
  Future<ActivityState> load() async => state;

  @override
  Future<void> save(ActivityState next) async {
    if (throwOnSave) throw StateError('Error simulado de escritura');
    state = next;
    writes++;
  }
}

List<ActivityDefinition> catalog(int count) => [
  for (int i = 1; i <= count; i++)
    ActivityDefinition(
      id: 'A-$i',
      title: 'Actividad $i',
      moduleId: 'm1',
      moduleName: 'Módulo 1',
      topicId: 't1',
      topicName: 'Tema 1',
      requiredElementIds: const {'e1', 'e2'},
    ),
];

void main() {
  test('CU-08 lee sin modificar estado ni otorgar recompensas', () async {
    final store = FakeStore(ActivityState(completedActivityIds: {'A-1'}));
    final engine = ActivityEngine(activities: catalog(2), store: store);
    expect(await engine.readCompletedIds(), contains('A-1'));
    expect(store.writes, 0);
  });

  test('La primera actividad guardada suma 10, otorga L-03 y U-01', () async {
    final store = FakeStore(ActivityState(completedActivityIds: {}));
    final engine = ActivityEngine(activities: catalog(5), store: store);
    final result = await engine.completeActivity(
      activityId: 'A-1',
      verifiedElementIds: {'e1', 'e2'},
    );
    expect(result.justCompleted, isTrue);
    expect(result.pointsAdded, 10);
    expect(result.totalPoints, 10);
    expect(result.newAchievementIds, contains('L-03'));
    expect(result.newThemeIds, contains('U-01'));
    expect(store.writes, 1);
  });

  test('Repetir el mismo ID nunca vuelve a recompensar', () async {
    final store = FakeStore(
      ActivityState(
        completedActivityIds: {'A-1'},
        achievedAt: {'L-03': DateTime.utc(2026, 10, 20)},
      ),
    );
    final engine = ActivityEngine(activities: catalog(5), store: store);
    final result = await engine.completeActivity(
      activityId: 'A-1',
      verifiedElementIds: {'e1', 'e2'},
    );
    expect(result.pointsAdded, 0);
    expect(result.newAchievementIds, isEmpty);
    expect(store.writes, 0);
  });

  test('Intento incompleto no guarda ni otorga puntos', () async {
    final store = FakeStore(ActivityState(completedActivityIds: {}));
    final engine = ActivityEngine(activities: catalog(2), store: store);
    final result = await engine.completeActivity(
      activityId: 'A-1',
      verifiedElementIds: {'e1'},
    );
    expect(result.pointsAdded, 0);
    expect(store.writes, 0);
  });

  test('La quinta actividad distinta concede L-04', () async {
    final store = FakeStore(
      ActivityState(
        completedActivityIds: {'A-1', 'A-2', 'A-3', 'A-4'},
        achievedAt: {'L-03': DateTime.utc(2026, 10, 20)},
      ),
    );
    final engine = ActivityEngine(activities: catalog(6), store: store);
    final result = await engine.completeActivity(
      activityId: 'A-5',
      verifiedElementIds: {'e1', 'e2'},
    );
    expect(result.newAchievementIds, contains('L-04'));
    expect(result.newAchievementIds, isNot(contains('L-05')));
  });

  test('Al realizar todas las actividades del catálogo concede L-05', () async {
    final store = FakeStore(
      ActivityState(
        completedActivityIds: {'A-1'},
        achievedAt: {'L-03': DateTime.utc(2026, 10, 20)},
      ),
    );
    final engine = ActivityEngine(activities: catalog(2), store: store);
    final result = await engine.completeActivity(
      activityId: 'A-2',
      verifiedElementIds: {'e1', 'e2'},
    );
    expect(result.newAchievementIds, contains('L-05'));
  });

  test(
    'Fallo de escritura: no confirma recompensa ni muta el estado',
    () async {
      final store = FakeStore(ActivityState(completedActivityIds: {}));
      store.throwOnSave = true;
      final engine = ActivityEngine(activities: catalog(2), store: store);
      await expectLater(
        engine.completeActivity(
          activityId: 'A-1',
          verifiedElementIds: {'e1', 'e2'},
        ),
        throwsStateError,
      );
      expect(store.state.completedActivityIds, isEmpty);
      expect(store.writes, 0);
    },
  );

  test(
    'Dos finalizaciones concurrentes del mismo ID no duplican puntos',
    () async {
      final store = FakeStore(ActivityState(completedActivityIds: {}));
      final engine = ActivityEngine(activities: catalog(2), store: store);
      final results = await Future.wait([
        engine.completeActivity(
          activityId: 'A-1',
          verifiedElementIds: {'e1', 'e2'},
        ),
        engine.completeActivity(
          activityId: 'A-1',
          verifiedElementIds: {'e1', 'e2'},
        ),
      ]);
      expect(results.map((r) => r.pointsAdded).reduce((a, b) => a + b), 10);
      expect(store.writes, 1);
    },
  );
}

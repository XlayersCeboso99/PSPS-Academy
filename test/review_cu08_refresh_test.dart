import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psps/features/cu08/activity_engine.dart';
import 'package:psps/features/cu08/activity_models.dart';
import 'package:psps/features/cu08/activity_page.dart';

class ReviewStore implements ActivityStore {
  ActivityState state = ActivityState(completedActivityIds: {});
  @override
  Future<ActivityState> load() async => state;
  @override
  Future<void> save(ActivityState value) async {
    state = value;
  }
}

void main() {
  testWidgets(
    'Revision CU08: al volver de CU02 muestra la actividad realizada',
    (tester) async {
      const activity = ActivityDefinition(
        id: 'A-1',
        title: 'Actividad de prueba',
        moduleId: 'm1',
        moduleName: 'Modulo',
        topicId: 't1',
        topicName: 'Tema',
        requiredElementIds: {'e1'},
      );
      final store = ReviewStore();
      final engine = ActivityEngine(activities: [activity], store: store);
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          home: Cu08ActivitiesPage(
            catalog: const [activity],
            engine: engine,
            onOpenActivity: (item) {
              nav.currentState!.push(
                MaterialPageRoute<void>(
                  builder: (context) => Scaffold(
                    body: Center(
                      child: FilledButton(
                        onPressed: () async {
                          await engine.completeActivity(
                            activityId: item.id,
                            verifiedElementIds: {'e1'},
                          );
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        child: const Text('Completar en CU02'),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pendiente'), findsOneWidget);
      await tester.tap(find.text('Actividad de prueba'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Completar en CU02'));
      await tester.pumpAndSettle();
      expect(store.state.completedActivityIds, contains('A-1'));
      expect(
        find.text('Realizada'),
        findsOneWidget,
        reason: 'La consulta debe actualizarse tras volver de completar la actividad.',
      );
    },
  );
}

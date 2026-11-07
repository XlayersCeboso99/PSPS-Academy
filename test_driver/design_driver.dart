import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final folder = Directory(
    Platform.environment['PSPS_EVIDENCE_DIR'] ?? 'build/design_evidence',
  );
  await folder.create(recursive: true);
  await integrationDriver(
    writeResponseOnFailure: true,
    onScreenshot:
        (String name, List<int> bytes, [Map<String, Object?>? args]) async {
          await File('${folder.path}/$name.png').writeAsBytes(bytes);
          return true;
        },
    responseDataCallback: (data) async {
      final names = (data?['screenshots'] as List<dynamic>? ?? []).map(
        (dynamic shot) => (shot as Map<String, dynamic>)['screenshotName'],
      );
      await File('${folder.path}/capturas.txt').writeAsString(names.join('\n'));
    },
  );
}

import 'package:flutter/material.dart';

import 'data/catalog.dart';
import 'data/progress_store.dart';
import 'domain/learning_controller.dart';
import 'ui/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = LearningController(
    modules: catalog,
    store: LocalProgressStore(),
  );
  controller.load();
  runApp(PspsApp(controller: controller));
}

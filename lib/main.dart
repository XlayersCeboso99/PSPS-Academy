import 'package:flutter/material.dart';

import 'package:psps/core/content/catalog.dart';
import 'package:psps/core/persistence/progress_store.dart';
import 'package:psps/core/learning/learning_controller.dart';
import 'package:psps/app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = LearningController(
    modules: catalog,
    store: LocalProgressStore(),
  );
  controller.load();
  runApp(PspsApp(controller: controller));
}

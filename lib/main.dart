import 'package:flutter/widgets.dart';

import 'app.dart';

import 'dart:async';
import 'dart:io';

import 'application/scenarios/scenario_repository.dart';
import 'infrastructure/local/android_scenario_files.dart';
import 'infrastructure/local/file_document_store.dart';
import 'presentation/editor/editor_controller.dart';
import 'presentation/scenarios/workspace_controller.dart';
import 'presentation/training/training_controller.dart';
import 'application/training/training_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final files = AndroidScenarioFiles(), controller = EditorController();
  final store = FileDocumentStore(
    () async => Directory(await files.privateDirectory()),
  );
  final workspace = WorkspaceController(
    repository: ScenarioRepository(store),
    readSession: () => controller.value,
    loadSession: controller.loadScenario,
  );
  controller.files = files;
  controller.attachWorkspace(workspace);
  unawaited(workspace.initialize());
  final training = TrainingController(
    TrainingRepository(
      FileDocumentStore(
        () async => Directory('${await files.privateDirectory()}/training_v1'),
      ),
    ),
    scenarios: workspace.repository,
  );
  runApp(HeroClixApp(controller: controller, trainingController: training));
}

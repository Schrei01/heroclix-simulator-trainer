import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:heroclix_simulator_trainer/application/ports/local_document_store.dart';
import 'package:heroclix_simulator_trainer/application/ports/scenario_files.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_document.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_repository.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/editor_controller.dart';
import 'package:heroclix_simulator_trainer/presentation/scenarios/workspace_controller.dart';

final class MemoryStore implements LocalDocumentStore {
  final documents = <String, String>{};
  bool failRead = false, failWrite = false, failDelete = false;
  OSError? writeError;
  Completer<void>? gate;
  int writes = 0;
  @override
  Future<List<String>> listIds() async {
    if (failRead) throw const FileSystemException('Lectura simulada');
    return documents.keys.where(ScenarioDocument.validId).toList();
  }

  @override
  Future<String?> read(String id) async {
    if (failRead) throw const FileSystemException('Lectura simulada');
    return documents[id];
  }

  @override
  Future<void> write(String id, String document) async {
    final barrier = gate;
    if (barrier != null) await barrier.future;
    if (failWrite) {
      throw FileSystemException('Escritura simulada', '', writeError);
    }
    documents[id] = document;
    writes++;
  }

  @override
  Future<void> delete(String id) async {
    if (failDelete) throw const FileSystemException('Borrado simulado');
    documents.remove(id);
  }
}

final class FakeScenarioFiles implements ScenarioFiles {
  Completer<void>? savedSignal;
  PickedScenario? picked;
  Uint8List? savedBytes, sharedBytes;
  String? savedName, savedMime, sharedName, sharedMime;
  bool fail = false;
  @override
  Future<String> privateDirectory() async => throw UnimplementedError();
  @override
  Future<PickedScenario?> pickJson() async {
    if (fail) throw const FormatException('Proveedor no disponible');
    return picked;
  }

  @override
  Future<bool> saveFile(Uint8List bytes, String name, String mime) async {
    if (fail) throw const FormatException('Proveedor no disponible');
    savedBytes = bytes;
    savedName = name;
    savedMime = mime;
    if (savedSignal != null && !savedSignal!.isCompleted) {
      savedSignal!.complete();
    }
    return true;
  }

  @override
  Future<void> shareFile(Uint8List bytes, String name, String mime) async {
    if (fail) throw const FormatException('Proveedor no disponible');
    sharedBytes = bytes;
    sharedName = name;
    sharedMime = mime;
  }
}

Future<EditorController> persistentController(
  MemoryStore store, {
  FakeScenarioFiles? files,
  bool persistWorkingSession = true,
}) async {
  final controller = EditorController();
  final workspace = WorkspaceController(
    persistWorkingSession: persistWorkingSession,
    repository: ScenarioRepository(store),
    readSession: () => controller.value,
    loadSession: controller.loadScenario,
  );
  controller.files = files ?? FakeScenarioFiles();
  controller.attachWorkspace(workspace);
  await workspace.initialize();
  return controller;
}

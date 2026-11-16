import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/application/board/board_session.dart';
import 'package:heroclix_simulator_trainer/application/board/sight_probe.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_viewport.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_dimensions.dart';
import 'package:heroclix_simulator_trainer/domain/characters/character_repository.dart';
import 'package:heroclix_simulator_trainer/domain/characters/team.dart';
import 'package:heroclix_simulator_trainer/domain/rules/line_of_sight.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/terrain.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/editor_controller.dart';

import 'support/scenario_fakes.dart';
import 'support/vision_contract.dart';

BoardSession visionSession([VisionSnapshot? data]) {
  final world = data ?? vs();
  var characters = const CharacterRepository.empty();
  for (final figure in world.characters) {
    characters = characters.add(figure, world.dimensions);
  }
  return BoardSession.restore(
    dimensions: world.dimensions,
    teams: const [Team.blue, Team.red],
    characters: characters,
    terrain: world.terrain,
    walls: world.walls,
    nextCharacter: world.characters.length + 1,
    nextTeam: 3,
  );
}

void chooseVision(
  EditorController controller, {
  String source = 'A1',
  String target = 'D1',
}) {
  controller.setSightEndpoint(ProbeEndpoint.figure('figure-1'), asOrigin: true);
  controller.setSightEndpoint(
    ProbeEndpoint.figure('figure-2'),
    asOrigin: false,
  );
  controller.updateVision((v) => v.enabled = true);
}

void main() {
  test(
    'terreno invalida reglas aunque geometría sea la misma; undo/redo también',
    () {
      final controller = EditorController();
      addTearDown(controller.dispose);
      controller.loadScenario(visionSession());
      chooseVision(controller);
      final geometry = controller.sight.trace,
          previous = controller.vision.result;
      controller.attempt(
        (s) => s.paintTerrain([vc('B1')], TerrainType.hindering),
      );
      expect(controller.sight.trace, same(geometry));
      expect(controller.vision.result, isNot(same(previous)));
      expect(controller.vision.result!.status, VisionStatus.hindered);
      controller.attempt(
        (s) => s.paintTerrain([vc('B1')], TerrainType.blocking),
      );
      expect(controller.vision.result!.status, VisionStatus.blocked);
      controller.undo();
      expect(controller.vision.result!.status, VisionStatus.hindered);
      controller.redo();
      expect(controller.vision.result!.status, VisionStatus.blocked);
    },
  );
  test('borrar extremo retira dictamen anterior sin inventar otra coordenada; undo restaura', () {
    final controller = EditorController();
    addTearDown(controller.dispose);
    controller.loadScenario(visionSession());
    chooseVision(controller);
    controller.deleteCharacter('figure-1');
    expect(controller.vision.result!.status, VisionStatus.notEvaluated);
    expect(controller.vision.result!.origin, isNull);
    expect(controller.vision.result!.trace, isNull);
    controller.undo();
    expect(controller.vision.result!.status, VisionStatus.clear);
  });
  test('mover figura y reducir tablero recalcula o invalida sin resultado obsoleto', () {
    final controller = EditorController();
    addTearDown(controller.dispose);
    controller.loadScenario(visionSession());
    chooseVision(controller);
    controller.moveCharacter('figure-2', vc('D4'));
    expect(controller.vision.result!.destination!.cell, vc('D4'));
    controller.setSightEndpoint(ProbeEndpoint.cell(vc('D1')), asOrigin: false);
    controller.deleteCharacter('figure-2');
    controller.changeDimensions(BoardDimensions(rows: 2, columns: 2));
    expect(controller.vision.result!.status, VisionStatus.notEvaluated);
    controller.undo();
    expect(controller.vision.result!.status, VisionStatus.clear);
  });
  test('cámara, selección y visibilidad reutilizan resultado y no escriben escenario', () async {
    final store = MemoryStore(), controller = await persistentController(store);
    addTearDown(controller.dispose);
    controller.loadScenario(visionSession());
    controller.workspace!.edited(controller.value);
    await controller.workspace!.save();
    chooseVision(controller);
    final before = controller.vision.result, writes = store.writes;
    controller.resizeViewport(ViewportSize(500, 600));
    controller.zoom(1.25);
    controller.selectCharacter('figure-1');
    controller.updateVision((v) => v.showCauses = false);
    controller.updateSight((p) => p.showCells = false);
    expect(controller.vision.result, same(before));
    expect(controller.history.canUndo, isFalse);
    expect(store.writes, writes);
    expect(controller.workspace!.dirty, isFalse);
  });
  test('efectos declarados producen No evaluado y al retirarlos se vuelve a calcular', () {
    final controller = EditorController();
    addTearDown(controller.dispose);
    controller.loadScenario(visionSession());
    chooseVision(controller);
    controller.updateVision((v) => v.specialEffects = true);
    expect(controller.vision.result!.status, VisionStatus.notEvaluated);
    controller.updateVision((v) => v.specialEffects = false);
    expect(controller.vision.result!.status, VisionStatus.clear);
  });
  test(
    'cambiar versión de metadatos invalida reglas aun con mundo idéntico',
    () async {
      final controller = await persistentController(MemoryStore());
      addTearDown(controller.dispose);
      controller.loadScenario(visionSession());
      controller.workspace!.edited(controller.value);
      chooseVision(controller);
      expect(
        await controller.workspace!.save(rulesVersion: '2099-01-01'),
        isTrue,
      );
      expect(controller.vision.result!.status, VisionStatus.notEvaluated);
      expect(
        await controller.workspace!.save(
          rulesVersion: VisionContext.supportedVersion,
        ),
        isTrue,
      );
      expect(controller.vision.result!.status, VisionStatus.clear);
    },
  );
  test(
    'cargar documento limpia extremos, dictamen y declaración de efectos',
    () {
      final controller = EditorController();
      addTearDown(controller.dispose);
      controller.loadScenario(visionSession());
      chooseVision(controller);
      controller.updateVision((v) => v.specialEffects = true);
      controller.loadScenario(BoardSession.initial());
      expect(controller.sight.origin, isNull);
      expect(controller.vision.result, isNull);
      expect(controller.vision.specialEffects, isFalse);
    },
  );
}

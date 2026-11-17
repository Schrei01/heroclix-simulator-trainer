import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/application/board/board_session.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_dimensions.dart';
import 'package:heroclix_simulator_trainer/domain/characters/character.dart';
import 'package:heroclix_simulator_trainer/domain/characters/vision_ability.dart';
import 'package:heroclix_simulator_trainer/domain/characters/character_repository.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/edge_wall.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/terrain.dart';
import 'package:heroclix_simulator_trainer/domain/rules/line_of_sight.dart';
import 'package:heroclix_simulator_trainer/domain/rules/target_analysis_service.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/editor_controller.dart';

import 'support/vision_contract.dart';
import 'support/target_contract.dart';
import 'support/advanced_vision_contract.dart';
import 'vision_state_test.dart' show visionSession, chooseVision;
import 'support/scenario_fakes.dart';

void main() {
  test(
    'altura de región conserva tipo de terreno, historial y nivel oficial 1',
    () {
      final c = EditorController();
      addTearDown(c.dispose);
      c.loadScenario(visionSession(vs(terrain: {'B2': TerrainType.hindering})));
      c.attempt((s) => s.paintElevation([vc('A1'), vc('B2')], 2));
      expect(c.value.terrain.at(vc('B2')).type, TerrainType.hindering);
      expect(c.value.terrain.at(vc('A1')).level, 2);
      final cleared = c.value.clearTerrain();
      expect(cleared.terrain.at(vc('B2')).type, TerrainType.clear);
      expect(cleared.terrain.at(vc('B2')).level, 2);
      c.undo();
      expect(c.value.terrain.at(vc('B2')).level, 1);
      c.redo();
      expect(c.value.terrain.at(vc('A1')).level, 2);
      expect(() => c.value.paintElevation([vc('A1')], 0), throwsRangeError);
    },
  );
  test(
    'transición valida vecinos niveles muros, reducción y retirada al aplanar',
    () {
      final edge = EdgeWall.between(vc('B1'), vc('C1'));
      var s = BoardSession.initial().paintElevation([vc('B1')], 2);
      s = s.setTransition(edge, remove: false);
      expect(s.terrain.transitions, contains(edge));
      expect(
        () => s.editWalls([edge], erase: false),
        throwsA(isA<PlacementException>()),
      );
      expect(
        () => s.changeDimensions(BoardDimensions(rows: 4, columns: 2)),
        throwsA(isA<PlacementException>()),
      );
      expect(s.paintElevation([vc('B1')], 1).terrain.transitions, isEmpty);
      expect(
        () => BoardSession.initial().setTransition(edge, remove: false),
        throwsArgumentError,
      );
    },
  );
  test(
    'base completa exige un nivel y ocupación libre al editar, pintar o mover',
    () {
      final s = BoardSession.initial().createCharacter(
        CharacterDraft(
          name: 'Base',
          teamId: 'team-1',
          position: vc('A1'),
          footprint: Footprint.square2,
        ),
      );
      expect(
        () => s.paintElevation([vc('A1')], 2),
        throwsA(isA<PlacementException>()),
      );
      final high = s.paintElevation([vc('D4')], 2);
      expect(
        high
            .validateFigurePlacement(
              high.characters.byId('figure-1')!,
              vc('C3'),
            )
            .isValid,
        false,
      );
      expect(
        () => high.moveCharacter('figure-1', vc('C3')),
        throwsA(isA<PlacementException>()),
      );
      expect(
        () => s.createCharacter(
          CharacterDraft(name: 'Otra', teamId: 'team-2', position: vc('B2')),
        ),
        throwsA(isA<PlacementException>()),
      );
    },
  );
  test('editar capacidades invalida visión y undo restaura la ficha', () {
    final c = EditorController();
    addTearDown(c.dispose);
    c.loadScenario(visionSession(vs(terrain: {'B1': TerrainType.blocking})));
    c.selectCharacter('figure-1');
    c.setTool(EditorTool.targets);
    c.selectTarget('figure-2');
    expect(c.tactical.selected!.status, TargetStatus.blocked);
    final calls = c.tactical.cache.evaluations,
        f = c.value.characters.byId('figure-1')!;
    c.saveCharacter(
      CharacterDraft(
        name: f.name,
        teamId: f.teamId,
        position: f.position,
        abilities: [VisionAbility.blocking],
      ),
      id: f.id,
    );
    expect(c.tactical.selected!.status, TargetStatus.inRangeClear);
    expect(c.tactical.cache.evaluations, greaterThan(calls));
    c.undo();
    expect(c.tactical.selected!.status, TargetStatus.blocked);
  });
  test(
    'Visión automática no depende de alcance; Objetivos usa par coherente',
    () {
      final c = EditorController();
      addTearDown(c.dispose);
      c.loadScenario(
        visionSession(
          ranged(
            vs(
              target: 'B3',
              targetBase: Footprint.rectangle(width: 1, height: 2),
              walls: [EdgeWall.between(vc('A2'), vc('B2'))],
            ),
            2,
          ),
        ),
      );
      chooseVision(c);
      expect(c.vision.result!.status, VisionStatus.clear);
      c.setTool(EditorTool.targets);
      c.selectTarget('figure-2');
      expect(c.tactical.selected!.status, TargetStatus.blocked);
      expect(c.vision.result, same(c.tactical.selected!.vision));
      c.setTool(EditorTool.vision);
      expect(c.vision.result!.status, VisionStatus.clear);
    },
  );
  test(
    'laboratorio transitorio no escribe ni cambia ficha; carga lo limpia',
    () async {
      final store = MemoryStore();
      final controller = await persistentController(store);
      addTearDown(controller.dispose);
      controller.loadScenario(
        visionSession(
          capable(vs(terrain: {'B1': TerrainType.blocking}), [
            VisionAbility.blocking,
          ]),
        ),
      );
      controller.workspace!.edited(controller.value);
      await controller.workspace!.save();
      chooseVision(controller);
      final writes = store.writes;
      controller.updateVision((v) => v.laboratoryAbilities = {});
      expect(controller.vision.result!.status, VisionStatus.blocked);
      expect(
        controller.value.characters.byId('figure-1')!.abilities,
        contains(VisionAbility.blocking),
      );
      expect(store.writes, writes);
      expect(controller.workspace!.dirty, false);
      controller.loadScenario(visionSession());
      expect(controller.vision.laboratoryAbilities, isNull);
    },
  );
}

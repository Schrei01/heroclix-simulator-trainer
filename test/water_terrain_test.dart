import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/application/board/board_session.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_codec.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_document.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_repository.dart';
import 'package:heroclix_simulator_trainer/domain/movement/movement.dart';
import 'package:heroclix_simulator_trainer/domain/rules/line_of_sight.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/terrain.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/edge_wall.dart';

import 'character_editor_test.dart' show press, data;
import 'editor_brush_teams_test.dart' show stroke;
import 'editor_increments_test.dart' show tapCell;
import 'editor_test.dart' show openEditor, cellPosition;
import 'support/movement_contract.dart' show mw, me;
import 'support/scenario_fakes.dart';
import 'support/vision_contract.dart' show vc, ve, vs;

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets(
    'Agua pinta por trazo, conserva altura y personajes; un Deshacer',
    (t) async {
      final c = await openEditor(t);
      c.attempt((s) => s.paintElevation([vc('B1')], 2));
      c.saveCharacter(data('B1'));
      await press(t, 'tool-terrain');
      await press(t, 'terrain-water');
      expect(c.value.terrainType, TerrainType.water);
      expect(c.value.rectangleBrush, isFalse);
      final before = c.value, undoCount = c.history.undoCount;
      await stroke(t, c, ['A1', 'D1']);
      for (final at in ['A1', 'B1', 'C1', 'D1']) {
        expect(c.value.terrain.at(vc(at)).type, TerrainType.water);
      }
      expect(c.value.terrain.at(vc('B1')).level, 2);
      expect(c.value.characters, same(before.characters));
      expect(c.history.undoCount, undoCount + 1);
      c.undo();
      expect(c.value.terrain, same(before.terrain));
      c.redo();
      expect(c.value.terrain.at(vc('C1')).type, TerrainType.water);

      await press(t, 'terrain-clear');
      await tapCell(t, c, 'B1');
      expect(c.value.terrain.at(vc('B1')).type, TerrainType.clear);
      expect(c.value.terrain.at(vc('B1')).level, 2);
      await press(t, 'terrain-water');
      await tapCell(t, c, 'B1');
      await press(t, 'tool-erase');
      await stroke(t, c, ['A1', 'D1']);
      expect(c.value.characters.length, 0);
      for (final at in ['A1', 'B1', 'C1', 'D1']) {
        expect(c.value.terrain.at(vc(at)), CellTerrain.clear);
      }
    },
  );

  testWidgets('Agua cancela el trazo con cancelar gesto o segundo dedo', (
    t,
  ) async {
    final c = await openEditor(t);
    await press(t, 'tool-terrain');
    await press(t, 'terrain-water');
    var first = await t.startGesture(cellPosition(t, c, 'A1'));
    await first.moveTo(cellPosition(t, c, 'D1'));
    await t.pump();
    await first.cancel();
    await t.pumpAndSettle();
    expect(c.value.terrain.isEmpty, isTrue);

    first = await t.startGesture(cellPosition(t, c, 'A1'), pointer: 1);
    await first.moveTo(cellPosition(t, c, 'C1'));
    await t.pump();
    final second = await t.startGesture(cellPosition(t, c, 'C3'), pointer: 2);
    await first.up();
    await second.up();
    await t.pumpAndSettle();
    expect(c.value.terrain.isEmpty, isTrue);
    expect(c.draft.value, isNull);
  });

  testWidgets('Agua también rellena rectángulo tras confirmar vista previa', (
    t,
  ) async {
    final c = await openEditor(t);
    await press(t, 'tool-terrain');
    await press(t, 'terrain-water');
    c.configureLayers(rectangle: true);
    await t.pumpAndSettle();
    await stroke(t, c, ['A1', 'C3']);
    expect(c.value.terrain.isEmpty, isTrue);
    expect(c.draft.value!.cells.length, 9);
    await press(t, 'apply-layer-preview');
    expect(c.value.terrain.cells.length, 9);
    expect(
      c.value.terrain.cells.values.every((v) => v.type == TerrainType.water),
      isTrue,
    );
  });

  test(
    'biblioteca y JSON conservan agua, elevaciones, transición y figura',
    () async {
      final session = BoardSession.initial()
          .paintElevation([vc('B1')], 2)
          .paintTerrain([vc('A1'), vc('B1')], TerrainType.water)
          .setTransition(EdgeWall.between(vc('A1'), vc('B1')), remove: false)
          .createCharacter(data('B1'));
      final document = ScenarioDocument.fresh(name: 'Agua', session: session);
      const codec = ScenarioCodec();
      final raw = codec.encode(document);
      expect(raw, contains('"water"'));
      final repository = ScenarioRepository(MemoryStore());
      await repository.save(codec.decode(raw));
      final saved = (await repository.open(document.id)).session;
      expect(saved.terrain.cells, session.terrain.cells);
      expect(saved.terrain.transitions, session.terrain.transitions);
      expect(saved.characters.all.single.position, vc('B1'));
    },
  );

  test(
    '§16.6 agua en origen, interior y destino mantiene visión despejada',
    () {
      final result = ve(
        vs(
          terrain: {
            'A1': TerrainType.water,
            'B1': TerrainType.water,
            'D1': TerrainType.water,
          },
        ),
      );
      expect(result.status, VisionStatus.clear);
      expect(
        result.observations.any((o) => o.rules.contains(VisionRule.water)),
        isTrue,
      );
      expect(
        ve(vs(terrain: {'B1': TerrainType.water, 'C1': TerrainType.blocking}))
            .status,
        VisionStatus.blocked,
      );
      expect(
        ve(vs(terrain: {'B1': TerrainType.water, 'C1': TerrainType.hindering}))
            .status,
        VisionStatus.hindered,
      );
    },
  );

  test(
    '§16.6 entrar, atravesar y salir del agua cuesta una casilla por paso',
    () {
      final result = me(
        mw(
          terrain: {
            'A1': TerrainType.water,
            'B1': TerrainType.water,
            'C1': TerrainType.water,
          },
        ),
        'A1 B1 C1 D1',
      );
      expect(result.status, MovementStatus.valid);
      expect(result.cost, 3);
      expect(result.events.any((e) => e.rule == '16.6'), isTrue);
    },
  );
}

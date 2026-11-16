import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/application/board/board_session.dart';
import 'package:heroclix_simulator_trainer/application/board/sight_probe.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_dimensions.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_viewport.dart';
import 'package:heroclix_simulator_trainer/domain/characters/character.dart';
import 'package:heroclix_simulator_trainer/domain/rules/target_analysis_service.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/terrain.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/editor_controller.dart';

import 'support/vision_contract.dart';
import 'support/scenario_fakes.dart';

import 'package:heroclix_simulator_trainer/domain/rules/line_of_sight.dart';

import 'vision_state_test.dart' show visionSession;

EditorController targetController() {
  final c = EditorController();
  c.loadScenario(
    visionSession(
      vs(
        extras: [
          vf(3, 'A3'),
          vf(4, 'D4', team: 'team-2'),
        ],
      ),
    ),
  );
  c.selectCharacter('figure-1');
  c.setTool(EditorTool.targets);
  return c;
}

void setRange(EditorController c, int range) {
  final f = c.value.characters.byId('figure-1')!;
  expect(
    c.saveCharacter(
      CharacterDraft(
        name: f.name,
        teamId: f.teamId,
        position: f.position,
        footprint: f.footprint,
        speed: f.speed,
        range: range,
      ),
      id: f.id,
    ),
    isNull,
  );
}

void main() {
  test(
    'cámara filtro y objetivos no escriben; el alcance sí se guarda',
    () async {
      final store = MemoryStore();
      final controller = await persistentController(store);
      addTearDown(controller.dispose);
      controller.loadScenario(visionSession());
      controller.workspace!.edited(controller.value);
      await controller.workspace!.save();
      final writes = store.writes;
      controller.selectCharacter('figure-1');
      controller.setTool(EditorTool.targets);
      controller.selectTarget('figure-2');
      controller.zoom(1.25);
      controller.updateTactical((t) => t.filter = TargetFilter.all);
      expect(store.writes, writes);
      expect(controller.workspace!.dirty, false);
      setRange(controller, 2);
      expect(controller.workspace!.dirty, true);
      await controller.workspace!.save();
      expect(store.writes, greaterThan(writes));
    },
  );
  test(
    'cambiar versión del documento invalida el análisis de objetivos',
    () async {
      final c = await persistentController(MemoryStore());
      addTearDown(c.dispose);
      c.loadScenario(visionSession());
      c.workspace!.edited(c.value);
      c.selectCharacter('figure-1');
      c.setTool(EditorTool.targets);
      expect(c.tactical.visible.single.status, TargetStatus.inRangeClear);
      await c.workspace!.save(rulesVersion: '2099-01-01');
      expect(c.tactical.visible.single.status, TargetStatus.notEvaluated);
      await c.workspace!.save(rulesVersion: VisionContext.supportedVersion);
      expect(c.tactical.visible.single.status, TargetStatus.inRangeClear);
    },
  );
  test('por defecto enemigos; filtro cámara y selección no repiten visión', () {
    final c = targetController();
    addTearDown(c.dispose);
    expect(c.tactical.visible.map((t) => t.target.id), [
      'figure-2',
      'figure-4',
    ]);
    final calls = c.tactical.cache.evaluations;
    c.updateTactical((t) => t.filter = TargetFilter.allies);
    expect(c.tactical.visible.single.target.id, 'figure-3');
    c.updateTactical((t) => t.filter = TargetFilter.all);
    expect(c.tactical.visible.length, 3);
    c.resizeViewport(ViewportSize(800, 600));
    c.zoom(1.25);
    c.selectCharacter('figure-2');
    expect(c.tactical.cache.evaluations, calls);
    expect(c.history.canUndo, false);
  });
  test('cambiar alcance actualiza todos los objetivos sin repetir visión; undo y redo', () {
    final c = targetController();
    addTearDown(c.dispose);
    final calls = c.tactical.cache.evaluations;
    setRange(c, 2);
    expect(
      c.tactical.visible.every((t) => t.range == RangeStatus.outside),
      true,
    );
    expect(c.tactical.cache.evaluations, calls);
    setRange(c, 3);
    expect(
      c.tactical.visible.every((t) => t.range == RangeStatus.within),
      true,
    );
    expect(c.undo(), isNull);
    expect(
      c.tactical.visible.every((t) => t.range == RangeStatus.outside),
      true,
    );
    expect(c.redo(), isNull);
    expect(
      c.tactical.visible.every((t) => t.range == RangeStatus.within),
      true,
    );
    expect(c.tactical.cache.evaluations, calls);
  });
  test('mover figuras y editar terreno invalida resultados y actualiza línea elegida', () {
    final c = targetController();
    addTearDown(c.dispose);
    c.selectTarget('figure-2');
    final calls = c.tactical.cache.evaluations;
    c.moveCharacter('figure-2', vc('D2'));
    expect(c.sight.trace!.path.destination, vc('D2'));
    expect(c.tactical.selected!.target.position, vc('D2'));
    expect(c.tactical.cache.evaluations, greaterThan(calls));
    c.moveCharacter('figure-2', vc('D1'));
    c.attempt(
      (s) => s.replaceLayers(
        characters: s.characters,
        walls: s.walls,
        terrain: s.terrain.put(
          vc('B1'),
          CellTerrain(type: TerrainType.blocking),
          s.dimensions,
        ),
      ),
    );
    expect(c.tactical.selected!.status, TargetStatus.blocked);
    c.undo();
    expect(c.tactical.selected!.status, TargetStatus.inRangeClear);
  });
  test('borrado de objetivo u origen retira estado anterior y recargar limpia consulta', () {
    final c = targetController();
    addTearDown(c.dispose);
    c.selectTarget('figure-2');
    c.deleteCharacter('figure-2');
    expect(c.tactical.selected, isNull);
    expect(c.sight.trace, isNull);
    c.undo();
    c.selectTarget('figure-2');
    c.deleteCharacter('figure-1');
    expect(c.tactical.report!.error, isNotNull);
    expect(c.tactical.selected, isNull);
    c.loadScenario(visionSession());
    expect(c.tactical.sourceId, isNull);
    expect(c.tactical.enabled, false);
    expect(c.tactical.measurement, isNull);
  });
  test('cambiar origen no deja la línea del origen anterior', () {
    final c = targetController();
    addTearDown(c.dispose);
    c.selectTarget('figure-2');
    c.setTargetSource('figure-4');
    expect(c.tactical.selected, isNull);
    expect(c.sight.trace, isNull);
    expect(c.tactical.sourceId, 'figure-4');
    c.selectTarget('figure-1');
    expect(c.sight.trace!.path.origin, vc('D4'));
  });
  test(
    'medición admite casillas vacías y detecta extremos fuera del tablero',
    () {
      final c = EditorController();
      addTearDown(c.dispose);
      c.setTool(EditorTool.distance);
      c.setSightEndpoint(ProbeEndpoint.cell(vc('A1')), asOrigin: true);
      c.setSightEndpoint(ProbeEndpoint.cell(vc('D3')), asOrigin: false);
      expect(c.tactical.measurement!.squares, 3);
      c.changeDimensions(BoardDimensions(rows: 2, columns: 2));
      expect(c.tactical.measurement!.squares, isNull);
      expect(c.tactical.measurement!.reason, contains('fuera'));
    },
  );
  test(
    'efectos especiales no aprueban objetivos y al desactivarlos se recalcula',
    () {
      final c = targetController();
      addTearDown(c.dispose);
      c.updateVision((v) => v.specialEffects = true);
      expect(
        c.tactical.visible.every((t) => t.status == TargetStatus.notEvaluated),
        true,
      );
      c.updateVision((v) => v.specialEffects = false);
      expect(
        c.tactical.visible.every((t) => t.status != TargetStatus.notEvaluated),
        true,
      );
    },
  );
}

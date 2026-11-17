import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/application/board/board_edit.dart';
import 'package:heroclix_simulator_trainer/application/board/board_session.dart';
import 'package:heroclix_simulator_trainer/domain/characters/movement_ability.dart';
import 'package:heroclix_simulator_trainer/domain/movement/movement.dart';
import 'package:heroclix_simulator_trainer/domain/rules/line_of_sight.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/edge_wall.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/editor_controller.dart';

import 'support/movement_contract.dart';
import 'support/vision_contract.dart';
import 'support/scenario_fakes.dart';
import 'vision_state_test.dart' show visionSession;

void main() {
  EditorController setup() {
    final c = EditorController();
    addTearDown(c.dispose);
    c.loadScenario(visionSession(mw()));
    c.setTool(EditorTool.movement);
    c.beginMovement('figure-1');
    return c;
  }

  test(
    'ensayo y cancelar conservan identidad, posición, contenido e historial',
    () {
      final c = setup(), initial = c.value;
      c.movementCell(vc('B1'));
      expect(c.movement.result!.status, MovementStatus.valid);
      expect(c.value.characters.byId('figure-1')!.position, vc('A1'));
      c.updateMovement((m) => m.reset());
      expect(c.movement.route, [vc('A1')]);
      c.updateMovement((m) => m.clear());
      expect(BoardEdit.sameContent(initial, c.value), true);
      expect(c.history.canUndo, false);
    },
  );
  test(
    'confirmar válido es una operación; deshacer/rehacer conserva capacidades',
    () {
      final c = setup();
      c.loadScenario(visionSession(mw(abilities: [MovementAbility.elevated])));
      c.beginMovement('figure-1');
      c.movementCell(vc('B1'));
      c.movementCell(vc('C1'));
      expect(c.confirmMovement(), isNull);
      expect(c.value.characters.byId('figure-1')!.position, vc('C1'));
      expect(c.history.undoCount, 1);
      expect(c.movement.sourceId, isNull);
      c.undo();
      expect(c.value.characters.byId('figure-1')!.position, vc('A1'));
      c.redo();
      expect(c.value.characters.byId('figure-1')!.position, vc('C1'));
      expect(c.value.characters.byId('figure-1')!.movementAbilities, {
        MovementAbility.elevated,
      });
    },
  );
  test('inválida y no evaluada no se confirman ni alteran escenario', () {
    final c = setup(), initial = c.value;
    c.movementCell(vc('D4'));
    expect(c.movement.result!.status, MovementStatus.invalid);
    expect(c.confirmMovement(), isNotNull);
    c.updateMovement((m) => m.reset());
    c.movementCell(vc('B1'));
    c.updateMovement((m) => m.setEffects(true));
    expect(c.movement.result!.status, MovementStatus.notEvaluated);
    expect(c.confirmMovement(), isNotNull);
    expect(BoardEdit.sameContent(initial, c.value), true);
    expect(c.history.canUndo, false);
  });
  test('comparación recalcula visión/alcance en snapshot futuro sin mutar original', () {
    final c = setup();
    c.loadScenario(
      visionSession(
        mw(
          extras: [vf(2, 'D1', team: 'team-2')],
          walls: [EdgeWall.between(vc('B1'), vc('C1'))],
        ),
      ),
    );
    c.beginMovement('figure-1');
    final initial = c.movement.original!;
    c.movementCell(vc('B2'));
    expect(c.movement.result!.status, MovementStatus.valid);
    expect(
      c.movement.before!.targets.single.vision.status,
      VisionStatus.blocked,
    );
    expect(c.movement.after!.targets.single.vision.status, VisionStatus.clear);
    expect(c.movement.before!.targets.single.distance.squares, 3);
    expect(c.movement.after!.targets.single.distance.squares, 2);
    expect(initial.characters.byId('figure-1')!.position, vc('A1'));
    expect(BoardEdit.sameContent(initial, c.value), true);
  });
  test('cámara conserva ensayo; editar contenido, cargar y salir de herramienta lo limpian', () {
    final c = setup();
    c.movementCell(vc('B1'));
    c.zoom(1.2);
    expect(c.movement.route.length, 2);
    c.moveCharacter('figure-1', vc('A2'));
    expect(c.movement.result, isNull);
    expect(c.confirmMovement(), isNotNull);
    c.beginMovement('figure-1');
    c.setTool(EditorTool.select);
    expect(c.movement.sourceId, isNull);
    c.beginMovement('figure-1');
    c.loadScenario(visionSession(mw()));
    expect(c.movement.sourceId, isNull);
  });
  test(
    'rutas alternativas y comparación no escriben; confirmar ensucia escenario',
    () async {
      final store = MemoryStore(), c = await persistentController(store);
      addTearDown(c.dispose);
      c.loadScenario(visionSession(mw()));
      c.workspace!.edited(c.value);
      await c.workspace!.save();
      final writes = store.writes;
      c.setTool(EditorTool.movement);
      c.beginMovement('figure-1');
      c.updateMovement((m) => m.search(vc('C1')));
      expect(c.movement.alternatives!.routes, isNotEmpty);
      c.updateMovement((m) => m.choose(m.alternatives!.routes.first));
      expect(store.writes, writes);
      expect(c.workspace!.dirty, false);
      expect(c.confirmMovement(), isNull);
      expect(c.workspace!.dirty, true);
    },
  );
}

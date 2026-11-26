import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:heroclix_simulator_trainer/application/board/board_session.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_codec.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_document.dart';
import 'package:heroclix_simulator_trainer/domain/characters/character.dart';
import 'package:heroclix_simulator_trainer/domain/characters/movement_ability.dart';
import 'package:heroclix_simulator_trainer/domain/movement/movement.dart';
import 'package:heroclix_simulator_trainer/domain/movement/route_planner.dart';
import 'package:heroclix_simulator_trainer/domain/rules/line_of_sight.dart';
import 'package:heroclix_simulator_trainer/domain/rules/line_of_sight_service.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/terrain.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/edge_wall.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/editor_controller.dart';

import 'support/movement_contract.dart' show mw, me;
import 'support/vision_contract.dart' show vc, vf;
import 'vision_state_test.dart' show visionSession;
import 'vision_editor_test.dart' show openRules;
import 'character_editor_test.dart' show press;
import 'editor_brush_teams_test.dart' show stroke;

const destroy = MovementAbility.destroyBlocking;
EdgeWall wall(String a, String b) => EdgeWall.between(vc(a), vc(b));

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  test('cero pasos no destruye; quitar un paso cancela el plan sin mutar', () {
    final c = EditorController();
    addTearDown(c.dispose);
    c.loadScenario(
      visionSession(
        mw(abilities: [destroy], terrain: {'B1': TerrainType.blocking}),
      ),
    );
    c.setTool(EditorTool.movement);
    c.beginMovement('figure-1');
    expect(c.movement.result!.changes, isNull);
    expect(c.movement.result!.canConfirm, isFalse);
    c.movementCell(vc('B1'));
    expect(c.movement.result!.changes, isNotNull);
    c.updateMovement((m) => m.removeLast());
    expect(c.movement.result!.changes, isNull);
    expect(c.value.terrain.at(vc('B1')).type, TerrainType.blocking);
  });

  test(
    'escenario editado invalida confirmación, sin aplicar el plan antiguo',
    () {
      final c = EditorController();
      addTearDown(c.dispose);
      c.loadScenario(
        visionSession(
          mw(abilities: [destroy], terrain: {'B1': TerrainType.blocking}),
        ),
      );
      c.setTool(EditorTool.movement);
      c.beginMovement('figure-1');
      c.movementCell(vc('B1'));
      c.attempt((s) => s.paintTerrain([vc('D4')], TerrainType.water));
      expect(c.confirmMovement(), isNotNull);
      expect(c.value.terrain.at(vc('B1')).type, TerrainType.blocking);
      expect(c.value.terrain.debrisCells, isEmpty);
      expect(c.value.characters.byId('figure-1')!.position, vc('A1'));
    },
  );

  test(
    'editar altura o tipo global preserva debris y su terreno subyacente',
    () {
      final s = BoardSession.initial().paintTerrain([
        vc('B1'),
      ], TerrainType.water);
      var terrain = s.terrain.withDebris([vc('B1')], s.dimensions);
      terrain = terrain
          .paintElevation([vc('B1')], 3, s.dimensions)
          .setEnvironment(MapEnvironment.indoor);
      expect(terrain.debrisCells, {vc('B1')});
      terrain = terrain.withDebris([vc('B1')], s.dimensions, remove: true);
      expect(terrain.at(vc('B1')).type, TerrainType.water);
      expect(terrain.at(vc('B1')).level, 3);
      expect(terrain.isIndoor(vc('B1')), isTrue);
    },
  );

  test('Borrar todo limpia una casilla que solo contiene debris o Indoor', () {
    final s = BoardSession.initial();
    final value = s
        .replaceLayers(
          terrain: s.terrain.withDebris([vc('B1')], s.dimensions),
          walls: s.walls,
          characters: s.characters,
        )
        .paintIndoor([vc('B1')]);
    final erased = value.eraseCells([vc('B1')]);
    expect(erased.terrain.isEmpty, isTrue);
  });

  test('§27.5b/c atravesar B no lo destruye', () {
    for (final ability in [
      MovementAbility.blocking,
      MovementAbility.outdoorBlocking,
    ]) {
      final w = mw(abilities: [ability], terrain: {'B1': TerrainType.blocking});
      final r = me(w, 'A1 B1 C1');
      expect(r.status, MovementStatus.valid);
      expect(r.changes, isNull);
      expect(w.terrain.at(vc('B1')).type, TerrainType.blocking);
      expect(me(w, 'A1 B1').status, MovementStatus.invalid);
    }
  });

  test('§10.4/27.5d destino B se destruye antes de aterrizar, debris obstaculizado', () {
    final w = mw(abilities: [destroy], terrain: {'B1': TerrainType.blocking});
    final r = me(w, 'A1 B1');
    expect(r.canConfirm, isTrue);
    expect(r.changes!.blocking, {vc('B1')});
    expect(r.changes!.terrain.baseAt(vc('B1')).type, TerrainType.clear);
    expect(r.changes!.terrain.at(vc('B1')).type, TerrainType.hindering);
    expect(r.changes!.debris, {vc('B1')});
    expect(w.terrain.at(vc('B1')).type, TerrainType.blocking);
  });

  test('§16.9b muro desaparece y genera debris en ambos lados; no destruye vecinos B', () {
    final w = mw(
      abilities: [destroy],
      walls: [wall('A1', 'B1')],
      terrain: {'B2': TerrainType.blocking},
    );
    final r = me(w, 'A1 B1');
    expect(r.changes!.destroyedWalls, {wall('A1', 'B1')});
    expect(r.changes!.walls.isEmpty, isTrue);
    expect(r.changes!.debris, {vc('A1'), vc('B1')});
    expect(r.changes!.terrain.at(vc('B2')).type, TerrainType.blocking);
  });

  test(
    'muro cruzado y B en destino: unión de debris, mantiene altura e Indoor',
    () {
      final c = EditorController();
      addTearDown(c.dispose);
      c.loadScenario(
        visionSession(
          mw(
            abilities: [destroy, MovementAbility.elevated],
            terrain: {'B1': TerrainType.blocking},
            elevations: {'B1': 2},
            walls: [wall('A1', 'B1')],
          ),
        ).paintIndoor([vc('A1'), vc('B1')]),
      );
      c.setTool(EditorTool.movement);
      c.beginMovement('figure-1');
      c.movementCell(vc('B1'));
      expect(c.confirmMovement(), isNull);
      expect(c.value.terrain.debrisCells, {vc('A1'), vc('B1')});
      expect(c.value.terrain.at(vc('B1')).level, 2);
      expect(c.value.terrain.isIndoor(vc('B1')), isTrue);
    },
  );

  test('diagonal prefiere lado libre y no destruye B tocado por vértice', () {
    final r = me(
      mw(abilities: [destroy], terrain: {'A2': TerrainType.blocking}),
      'A1 B2',
    );
    expect(r.status, MovementStatus.valid);
    expect(r.changes, isNull);
  });

  test(
    '§16.8a diagonal por dos lados bloqueados elige solo un lado consistente',
    () {
      final w = mw(
        abilities: [destroy],
        terrain: {'A2': TerrainType.blocking, 'B1': TerrainType.blocking},
      );
      final r = me(w, 'A1 B2');
      expect(r.status, MovementStatus.valid);
      expect(r.changes!.blocking.length, 1);
      expect(r.changes!.blocking, {vc('A2')});
      expect(r.changes!.terrain.at(vc('B1')).type, TerrainType.blocking);
    },
  );

  test('diagonal destruye únicamente los muros del lado menos destructivo', () {
    final w = mw(
      abilities: [destroy],
      walls: [wall('A1', 'A2'), wall('A2', 'B2')],
    );
    expect(me(w, 'A1 B2').changes, isNull);
    final all = mw(
      abilities: [destroy],
      walls: [wall('A1', 'A2'), wall('A2', 'B2'), wall('A1', 'B1')],
    );
    final r = me(all, 'A1 B2');
    expect(r.changes!.destroyedWalls, {wall('A1', 'B1')});
    expect(r.changes!.terrain.debrisCells, {vc('A1'), vc('B1')});
    expect(r.changes!.walls.edges.length, 2);
  });

  test('base 2×2 convierte todas las casillas B recorridas y valida la huella final', () {
    final r = me(
      mw(
        abilities: [destroy],
        base: Footprint.square2,
        terrain: {'C1': TerrainType.blocking, 'C2': TerrainType.blocking},
      ),
      'A1 B1',
    );
    expect(r.status, MovementStatus.valid);
    expect(r.changes!.blocking, {vc('C1'), vc('C2')});
  });

  test('ruta que vuelve sobre muro destruido lo elimina una sola vez', () {
    final r = me(
      mw(abilities: [destroy], walls: [wall('A1', 'B1')]),
      'A1 B1 A1 B1',
    );
    expect(r.status, MovementStatus.valid);
    expect(r.cost, 3);
    expect(r.changes!.destroyedWalls.length, 1);
    expect(r.changes!.debris.length, 2);
  });

  test('ruta inválida o efecto sin soporte no ofrece cambios aplicables', () {
    final w = mw(
      abilities: [destroy],
      speed: 1,
      terrain: {'B1': TerrainType.blocking},
    );
    final invalid = me(w, 'A1 B1 C1');
    expect(invalid.status, MovementStatus.invalid);
    expect(invalid.changes, isNull);
    final unknown = me(
      w,
      'A1 B1',
      context: const MovementContext(specialEffects: true),
    );
    expect(unknown.status, MovementStatus.notEvaluated);
    expect(unknown.changes, isNull);
    expect(w.terrain.at(vc('B1')).type, TerrainType.blocking);
  });

  test('buscar alternativas con destrucción admite B como destino y prefijos no confirmables', () {
    final w = mw(abilities: [destroy], terrain: {'B1': TerrainType.blocking});
    final search = const RoutePlanner().search(w, 'figure-1', vc('B1'));
    expect(search.routes, isNotEmpty);
    expect(search.routes.first.canConfirm, isTrue);
    expect(search.routes.first.changes!.blocking, contains(vc('B1')));
    expect(w.terrain.at(vc('B1')).type, TerrainType.blocking);
  });

  test('confirmación aplica posición, muros y terreno como un único Deshacer/Rehacer', () {
    final c = EditorController();
    addTearDown(c.dispose);
    c.loadScenario(
      visionSession(
        mw(
          abilities: [destroy],
          terrain: {'B1': TerrainType.blocking},
          walls: [wall('A1', 'B1')],
        ),
      ),
    );
    final original = c.value;
    c.setTool(EditorTool.movement);
    c.beginMovement('figure-1');
    c.movementCell(vc('B1'));
    expect(c.value.terrain, same(original.terrain));
    expect(c.value.walls, same(original.walls));
    expect(c.confirmMovement(), isNull);
    expect(c.value.characters.byId('figure-1')!.position, vc('B1'));
    expect(c.value.terrain.at(vc('B1')).type, TerrainType.hindering);
    expect(c.value.walls.isEmpty, isTrue);
    expect(c.history.undoCount, 1);
    final after = c.value;
    c.undo();
    expect(c.value.terrain, same(original.terrain));
    expect(c.value.walls, same(original.walls));
    expect(c.value.characters.byId('figure-1')!.position, vc('A1'));
    c.redo();
    expect(c.value.terrain, same(after.terrain));
    expect(c.value.walls, same(after.walls));
  });

  test(
    'comparación futura usa debris y muros retirados, sin mutar el escenario',
    () {
      final c = EditorController();
      addTearDown(c.dispose);
      c.loadScenario(
        visionSession(
          mw(
            abilities: [destroy],
            walls: [wall('A1', 'B1')],
            extras: [vf(2, 'D1', team: 'team-2')],
          ),
        ),
      );
      c.setTool(EditorTool.movement);
      c.beginMovement('figure-1');
      c.movementCell(vc('B1'));
      expect(c.movement.after, isNotNull);
      final effects = c.movement.result!.changes!;
      final w = VisionSnapshot(
        dimensions: c.value.dimensions,
        characters: [vf(1, 'D1')],
        terrain: effects.terrain,
        walls: effects.walls,
      );
      final vision = const LineOfSightService().evaluate(
        w,
        VisionEndpoint(vc('D1')),
        VisionEndpoint(vc('A1')),
        VisionContext(),
      );
      expect(vision.status, VisionStatus.hindered);
      expect(c.value.walls.isEmpty, isFalse);
    },
  );

  test(
    'retirar debris sobre agua recupera agua; B destruido permanece despejado',
    () {
      final c = EditorController();
      addTearDown(c.dispose);
      c.loadScenario(
        visionSession(
          mw(
            abilities: [destroy],
            terrain: {'B1': TerrainType.water, 'C1': TerrainType.blocking},
            walls: [wall('A1', 'B1')],
          ),
        ),
      );
      c.setTool(EditorTool.movement);
      c.beginMovement('figure-1');
      c.movementCell(vc('B1'));
      c.movementCell(vc('C1'));
      expect(c.confirmMovement(), isNull);
      c.attempt((s) => s.removeDebris([vc('A1'), vc('B1'), vc('C1')]));
      expect(c.value.terrain.at(vc('B1')).type, TerrainType.water);
      expect(c.value.terrain.at(vc('C1')).type, TerrainType.clear);
    },
  );

  test(
    'JSON 5 conserva debris, terreno subyacente, altura y límites canónicos',
    () {
      const codec = ScenarioCodec();
      final s = BoardSession.initial()
          .paintTerrain([vc('B1')], TerrainType.water)
          .paintElevation([vc('B1')], 2)
          .paintIndoor([vc('B1')]);
      final doc = ScenarioDocument.fresh(
        session: s.replaceLayers(
          terrain: s.terrain.withDebris([vc('B1')], s.dimensions),
          walls: s.walls,
          characters: s.characters,
        ),
      );
      final copy = codec.decode(codec.encode(doc)).session;
      expect(copy.terrain.debrisCells, {vc('B1')});
      expect(copy.terrain.at(vc('B1')).type, TerrainType.hindering);
      expect(copy.terrain.baseAt(vc('B1')).type, TerrainType.water);
      expect(copy.terrain.at(vc('B1')).level, 2);
      expect(copy.terrain.isIndoor(vc('B1')), isTrue);
      for (final cells in [
        ['B1', 'B1'],
        ['b1'],
        ['Z99'],
      ]) {
        final raw = codec.toMap(doc)..['debrisCells'] = cells;
        expect(() => codec.decode(jsonEncode(raw)), throwsFormatException);
      }
    },
  );

  testWidgets(
    'trazo solo simula; confirmar crea Db y borrar escombros preserva agua',
    (t) async {
      final c = await openRules(
        t,
        data: mw(abilities: [destroy], terrain: {'B1': TerrainType.blocking}),
      );
      await press(t, 'tool-movement');
      await stroke(t, c, ['A1', 'C1']);
      expect(
        find.byKey(const ValueKey('movement-effects-summary')),
        findsOneWidget,
      );
      expect(c.value.terrain.at(vc('B1')).type, TerrainType.blocking);
      await press(t, 'movement-apply');
      expect(c.value.terrain.debrisCells, {vc('B1')});
      await press(t, 'tool-erase');
      await stroke(t, c, ['B1']);
      expect(c.value.terrain.debrisCells, isEmpty);
    },
  );
}

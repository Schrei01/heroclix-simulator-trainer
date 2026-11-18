import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:heroclix_simulator_trainer/application/board/board_session.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_codec.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_document.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_repository.dart';
import 'package:heroclix_simulator_trainer/domain/characters/movement_ability.dart';
import 'package:heroclix_simulator_trainer/domain/characters/character.dart';
import 'package:heroclix_simulator_trainer/domain/movement/movement.dart';
import 'package:heroclix_simulator_trainer/domain/rules/line_of_sight.dart';
import 'package:heroclix_simulator_trainer/domain/rules/line_of_sight_service.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/terrain.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/edge_wall.dart';

import 'character_editor_test.dart' show press, data;
import 'editor_test.dart' show openEditor, cellPosition;
import 'editor_brush_teams_test.dart' show stroke;
import 'editor_increments_test.dart' show tapCell;
import 'vision_editor_test.dart' show openRules;
import 'support/vision_contract.dart' show vc, vf, vs;
import 'support/movement_contract.dart' show mw, me;
import 'support/scenario_fakes.dart';

VisionSnapshot indoors(
  VisionSnapshot w, {
  bool entire = false,
  List<String> cells = const [],
}) => VisionSnapshot(
  dimensions: w.dimensions,
  characters: w.characters,
  walls: w.walls,
  terrain: entire
      ? w.terrain.setEnvironment(MapEnvironment.indoor)
      : w.terrain.paintIndoor(cells.map(vc), w.dimensions),
);

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets('trazo desde base 2×2 mantiene el ancla y no duplica pasos', (
    t,
  ) async {
    final c = await openRules(t, data: mw(base: Footprint.square2));
    await press(t, 'tool-movement');
    await stroke(t, c, ['B2', 'D2']);
    expect(c.movement.route, ['A1', 'B1', 'C1'].map(vc).toList());
    expect(c.movement.result!.status, MovementStatus.valid);
    expect(c.value.characters.byId('figure-1')!.position, vc('A1'));
  });

  testWidgets(
    'trazo diagonal valida muro y no permite confirmar ruta bloqueada',
    (t) async {
      final c = await openRules(
        t,
        data: mw(
          walls: [
            EdgeWall.between(vc('A1'), vc('B1')),
            EdgeWall.between(vc('A1'), vc('A2')),
          ],
        ),
      );
      await press(t, 'tool-movement');
      await stroke(t, c, ['A1', 'D4']);
      expect(c.movement.route, ['A1', 'B2', 'C3', 'D4'].map(vc).toList());
      expect(c.movement.result!.status, MovementStatus.invalid);
      expect(
        t
            .widget<IconButton>(find.byKey(const ValueKey('movement-apply')))
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets('cancelar trazo conserva el efecto especial y No evaluada', (
    t,
  ) async {
    final c = await openRules(t, data: mw());
    await press(t, 'tool-movement');
    await tapCell(t, c, 'A1');
    c.updateMovement((m) => m.setEffects(true));
    await t.pumpAndSettle();
    final gesture = await t.startGesture(cellPosition(t, c, 'A1'));
    await gesture.moveTo(cellPosition(t, c, 'D1'));
    await t.pump();
    await gesture.cancel();
    await t.pumpAndSettle();
    expect(c.movement.specialEffects, isTrue);
    expect(c.movement.result!.status, MovementStatus.notEvaluated);
    expect(c.movement.route, [vc('A1')]);
  });
  testWidgets(
    'selector sustituye estado y aplica tipo a todo el mapa con Deshacer',
    (t) async {
      final c = await openEditor(t);
      c.attempt((s) => s.paintIndoor([vc('B1')]));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('autosave-status')), findsNothing);
      await press(t, 'map-environment');
      await press(t, 'map-environment-indoor');
      await t.pumpAndSettle();
      expect(c.value.terrain.environment, MapEnvironment.indoor);
      expect(c.value.terrain.isIndoor(vc('J10')), isTrue);
      expect(c.value.terrain.indoorCells, isEmpty);
      c.undo();
      expect(c.value.terrain.environment, MapEnvironment.outdoor);
      expect(c.value.terrain.indoorCells, {vc('B1')});
      await t.pumpAndSettle();
      await press(t, 'map-environment');
      await press(t, 'map-environment-outdoor');
      await t.pumpAndSettle();
      expect(c.value.terrain.indoorCells, isEmpty);
    },
  );

  testWidgets(
    'Indoor por trazo coexiste con terreno y altura; borrado propio y total',
    (t) async {
      final c = await openEditor(t);
      c.attempt(
        (s) => s
            .paintTerrain([vc('A1')], TerrainType.water)
            .paintTerrain([vc('B1')], TerrainType.blocking)
            .paintElevation([vc('C1')], 2),
      );
      c.saveCharacter(data('C1'));
      await press(t, 'tool-terrain');
      await press(t, 'terrain-blocking');
      await press(t, 'terrain-indoor');
      await stroke(t, c, ['A1', 'D1']);
      expect(c.value.terrain.indoorCells, {
        vc('A1'),
        vc('B1'),
        vc('C1'),
        vc('D1'),
      });
      expect(c.value.terrain.at(vc('A1')).type, TerrainType.water);
      expect(c.value.terrain.at(vc('B1')).type, TerrainType.blocking);
      expect(c.value.terrain.at(vc('C1')).level, 2);
      c.undo();
      expect(c.value.terrain.indoorCells, isEmpty);
      c.redo();
      await press(t, 'terrain-clear');
      await tapCell(t, c, 'A1');
      expect(c.value.terrain.isIndoor(vc('A1')), isTrue);
      await press(t, 'tool-erase');
      await press(t, 'erase-layer');
      await t.tap(find.text('Borrar Indoor').last);
      await t.pumpAndSettle();
      await stroke(t, c, ['B1', 'C1']);
      expect(c.value.terrain.isIndoor(vc('B1')), isFalse);
      expect(c.value.terrain.at(vc('B1')).type, TerrainType.blocking);
      expect(c.value.characters.length, 1);
      await press(t, 'tool-erase');
      await stroke(t, c, ['A1', 'D1']);
      expect(c.value.terrain.indoorCells, isEmpty);
      expect(c.value.characters.length, 0);
    },
  );

  test(
    'JSON 4 y biblioteca conservan zonas y mapa Indoor; 3 migra con respaldo',
    () async {
      const codec = ScenarioCodec();
      final s = BoardSession.initial().paintIndoor([vc('B1')]).paintTerrain([
        vc('B1'),
      ], TerrainType.water);
      final doc = ScenarioDocument.fresh(session: s);
      final decoded = codec.decode(codec.encode(doc));
      expect(decoded.session.terrain.isIndoor(vc('B1')), isTrue);
      expect(decoded.session.terrain.isIndoor(vc('A1')), isFalse);
      expect(
        codec
            .decode(
              codec.encode(
                doc.revised(session: s.setEnvironment(MapEnvironment.indoor)),
              ),
            )
            .session
            .terrain
            .isIndoor(vc('J10')),
        isTrue,
      );
      final old = codec.toMap(doc)..['schemaVersion'] = 3;
      old.remove('environment');
      old.remove('indoorCells');
      final raw = jsonEncode(old), store = MemoryStore();
      store.documents[doc.id] = raw;
      final repository = ScenarioRepository(store),
          migrated = await repository.open(doc.id);
      expect(migrated.session.terrain.isIndoor(vc('B1')), isFalse);
      await repository.save(migrated);
      expect(store.documents['schema3-${doc.id}'], raw);
      expect(jsonDecode(store.documents[doc.id]!)['schemaVersion'], 4);
    },
  );

  test('JSON rechaza tipo, duplicados y casillas Indoor fuera de límites', () {
    const codec = ScenarioCodec();
    final doc = ScenarioDocument.fresh();
    for (final list in [
      ['A1', 'A1'],
      ['Z99'],
      [5],
    ]) {
      final raw = codec.toMap(doc)..['indoorCells'] = list;
      expect(() => codec.fromMap(raw), throwsFormatException);
    }
    expect(
      () => codec.fromMap(codec.toMap(doc)..['environment'] = 'unknown'),
      throwsFormatException,
    );
  });

  test(
    '§15.1 Indoor y amarillo no bloquean visión ni añaden costo; muro sí',
    () {
      final w = indoors(vs(), cells: ['B1', 'C1']);
      final result = const LineOfSightService().evaluate(
        w,
        VisionEndpoint(vc('A1')),
        VisionEndpoint(vc('D1')),
        VisionContext(),
      );
      expect(result.status, VisionStatus.clear);
      expect(
        result.observations.any(
          (e) => e.rules.contains(VisionRule.environment),
        ),
        isTrue,
      );
      final route = me(indoors(mw(), cells: ['B1', 'C1']), 'A1 B1 C1 D1');
      expect(route.status, MovementStatus.valid);
      expect(route.cost, 3);
      final wall = indoors(
        mw(walls: [EdgeWall.between(vc('A1'), vc('B1'))]),
        cells: ['B1'],
      );
      expect(me(wall, 'A1 B1').status, MovementStatus.invalid);
    },
  );

  test(
    '§27.5c atraviesa B Outdoor y muro exterior, no Indoor ni límite amarillo',
    () {
      final block = mw(
        abilities: [MovementAbility.outdoorBlocking],
        terrain: {'B1': TerrainType.blocking},
      );
      expect(me(block, 'A1 B1 C1').status, MovementStatus.valid);
      expect(me(block, 'A1 B1').status, MovementStatus.invalid);
      expect(
        me(indoors(block, cells: ['B1']), 'A1 B1 C1').status,
        MovementStatus.invalid,
      );
      expect(
        me(indoors(block, entire: true), 'A1 B1 C1').status,
        MovementStatus.invalid,
      );
      final wall = mw(
        abilities: [MovementAbility.outdoorBlocking],
        walls: [EdgeWall.between(vc('A1'), vc('B1'))],
      );
      expect(me(wall, 'A1 B1').status, MovementStatus.valid);
      for (final cells in [
        ['A1'],
        ['B1'],
      ]) {
        expect(
          me(indoors(wall, cells: cells), 'A1 B1').status,
          MovementStatus.invalid,
        );
      }
      expect(
        me(
          indoors(
            mw(
              abilities: [MovementAbility.blocking],
              terrain: {'B1': TerrainType.blocking},
            ),
            cells: ['B1'],
          ),
          'A1 B1 C1',
        ).status,
        MovementStatus.valid,
      );
    },
  );

  testWidgets(
    'Movimiento abre directo, exige figura y trazo rellena pasos sin mover',
    (t) async {
      final c = await openRules(t, data: mw());
      c.selectCharacter('figure-1');
      await press(t, 'tool-movement');
      expect(find.text('Ensayo de movimiento'), findsNothing);
      expect(c.movement.sourceId, isNull);
      await tapCell(t, c, 'C1');
      expect(c.movement.sourceId, isNull);
      await stroke(t, c, ['A1', 'D1']);
      expect(c.movement.route, ['A1', 'B1', 'C1', 'D1'].map(vc).toList());
      expect(c.value.characters.byId('figure-1')!.position, vc('A1'));
      expect(c.history.undoCount, 0);
      await press(t, 'movement-apply');
      expect(c.value.characters.byId('figure-1')!.position, vc('D1'));
      c.undo();
      expect(c.value.characters.byId('figure-1')!.position, vc('A1'));
    },
  );

  testWidgets('pasos por toque, continuar trazo y elegir otra figura', (
    t,
  ) async {
    final c = await openRules(t, data: mw(extras: [vf(2, 'D4')]));
    await press(t, 'tool-movement');
    for (final cell in ['A1', 'B1', 'C1']) {
      await tapCell(t, c, cell);
    }
    await stroke(t, c, ['C1', 'D1', 'D2']);
    expect(c.movement.route, ['A1', 'B1', 'C1', 'D1', 'D2'].map(vc).toList());
    await press(t, 'movement-choose');
    await tapCell(t, c, 'D4');
    expect(c.movement.sourceId, 'figure-2');
    expect(c.movement.route, [vc('D4')]);
  });

  testWidgets('cancelar gesto o segundo dedo restaura ensayo anterior', (
    t,
  ) async {
    final c = await openRules(t, data: mw());
    await press(t, 'tool-movement');
    await tapCell(t, c, 'A1');
    await tapCell(t, c, 'B1');
    var first = await t.startGesture(cellPosition(t, c, 'B1'), pointer: 1);
    await first.moveTo(cellPosition(t, c, 'D1'));
    await t.pump();
    await first.cancel();
    await t.pumpAndSettle();
    expect(c.movement.route, [vc('A1'), vc('B1')]);
    first = await t.startGesture(cellPosition(t, c, 'B1'), pointer: 1);
    await first.moveTo(cellPosition(t, c, 'D1'));
    await t.pump();
    final second = await t.startGesture(cellPosition(t, c, 'C3'), pointer: 2);
    await first.up();
    await second.up();
    await t.pumpAndSettle();
    expect(c.movement.route, [vc('A1'), vc('B1')]);
    expect(c.value.characters.byId('figure-1')!.position, vc('A1'));
  });
}

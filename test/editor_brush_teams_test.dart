import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:heroclix_simulator_trainer/application/board/board_session.dart';
import 'package:heroclix_simulator_trainer/domain/board/cell_coordinate.dart';
import 'package:heroclix_simulator_trainer/domain/characters/character.dart';
import 'package:heroclix_simulator_trainer/domain/characters/team.dart';
import 'package:heroclix_simulator_trainer/domain/characters/vision_ability.dart';
import 'package:heroclix_simulator_trainer/domain/characters/movement_ability.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/terrain.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/edge_wall.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/editor_controller.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/character_dialog.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/tool_hint.dart';

import 'editor_test.dart' show openEditor, cellPosition;
import 'character_editor_test.dart' show press, data;
import 'editor_increments_test.dart' show tapCell;

CellCoordinate bc(String s) => CellCoordinate.parse(s);
EdgeWall be(String a, String b) => EdgeWall.between(bc(a), bc(b));
Future<void> stroke(
  WidgetTester t,
  EditorController c,
  List<String> cells,
) async {
  final g = await t.startGesture(cellPosition(t, c, cells.first));
  for (final cell in cells.skip(1)) {
    await g.moveTo(cellPosition(t, c, cell));
    await t.pump();
  }
  await g.up();
  await t.pumpAndSettle();
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'Personajes: cada par de toques cicla equipos, vuelve al primero y conserva toda la ficha',
    (t) async {
      final c = await openEditor(t);
      await press(t, 'tool-characters');
      await tapCell(t, c, 'A1');
      expect(c.value.selectedCharacter!.teamId, 'team-1');
      c.saveCharacter(
        CharacterDraft(
          name: 'Ejemplo',
          teamId: 'team-1',
          position: bc('A1'),
          footprint: Footprint.square2,
          speed: 9,
          range: 6,
          abilities: [VisionAbility.blocking],
          movementAbilities: [MovementAbility.characters],
        ),
        id: 'figure-1',
      );
      await t.pumpAndSettle();
      final figure = c.value.selectedCharacter!;
      for (final next in ['team-2', 'team-1']) {
        final before = c.value.selectedCharacter!.teamId,
            count = c.history.undoCount;
        await tapCell(t, c, 'A1');
        expect(c.value.selectedCharacter!.teamId, before);
        await tapCell(t, c, 'B2');
        expect(c.value.selectedCharacter!.teamId, next);
        expect(c.history.undoCount, count + 1);
      }
      c.addTeam('Tercero', 0xff81c784, TeamPattern.dots);
      for (final next in ['team-2', 'team-3', 'team-1']) {
        await tapCell(t, c, 'A1');
        await tapCell(t, c, 'A1');
        final f = c.value.selectedCharacter!;
        expect(f.teamId, next);
        expect(
          (
            f.id,
            f.label,
            f.name,
            f.position,
            f.footprint,
            f.speed,
            f.range,
            f.size,
          ),
          (
            figure.id,
            figure.label,
            figure.name,
            figure.position,
            figure.footprint,
            figure.speed,
            figure.range,
            figure.size,
          ),
        );
        expect(f.abilities, figure.abilities);
        expect(f.movementAbilities, figure.movementAbilities);
      }
      expect(c.value.nextCharacter, 2);
      expect(find.byType(CharacterDialog), findsNothing);
      c.undo();
      expect(c.value.characters.byId('figure-1')!.teamId, 'team-3');
      c.redo();
      expect(c.value.characters.byId('figure-1')!.teamId, 'team-1');
    },
  );
  test('un solo equipo no cambia identidad ni contenido', () {
    final s = BoardSession.initial().createCharacter(data('A1'));
    final one = BoardSession.restore(
      dimensions: s.dimensions,
      teams: [s.teams.first],
      characters: s.characters,
      terrain: s.terrain,
      walls: s.walls,
      nextCharacter: s.nextCharacter,
      nextTeam: s.nextTeam,
    );
    expect(one.cycleCharacterTeam('figure-1'), same(one));
  });
  testWidgets(
    'trazo elevado interpola, previsualiza y sube una vez cada nivel original aunque regrese',
    (t) async {
      final c = await openEditor(t);
      c.attempt(
        (s) => s
            .paintElevation([bc('B1')], 2)
            .paintElevation([bc('C1')], 3)
            .paintTerrain([bc('B1')], TerrainType.hindering)
            .setTransition(be('A1', 'B1'), remove: false),
      );
      await press(t, 'tool-terrain');
      await press(t, 'terrain-elevated');
      final before = c.value, count = c.history.undoCount;
      final g = await t.startGesture(cellPosition(t, c, 'A1'));
      await g.moveTo(cellPosition(t, c, 'C1'));
      await t.pump();
      await g.moveTo(cellPosition(t, c, 'A1'));
      await t.pump();
      expect(c.draft.value!.cells, {bc('A1'), bc('B1'), bc('C1')});
      expect(c.draft.value!.brush, TerrainBrush.elevated);
      expect(c.value.terrain, same(before.terrain));
      expect(find.textContaining('Elevar +1'), findsOneWidget);
      await g.up();
      await t.pumpAndSettle();
      expect(['A1', 'B1', 'C1'].map((s) => c.value.terrain.at(bc(s)).level), [
        2,
        3,
        4,
      ]);
      expect(c.value.terrain.at(bc('B1')).type, TerrainType.hindering);
      expect(c.value.terrain.transitions, {be('A1', 'B1')});
      expect(c.history.undoCount, count + 1);
      c.undo();
      expect(c.value.terrain, same(before.terrain));
      c.redo();
      await t.pumpAndSettle();
      await stroke(t, c, ['A1', 'B1']);
      expect(c.value.terrain.at(bc('A1')).level, 3);
      expect(c.value.terrain.at(bc('B1')).level, 4);
    },
  );
  test('elevación por trazo valida la base solo al final y E40 falla sin cambios parciales', () {
    final s = BoardSession.initial().createCharacter(
      data('A1', footprint: Footprint.square2),
    );
    expect(() => s.raiseElevations([bc('A1')]), throwsA(isA<Exception>()));
    final raised = s.raiseElevations([
      bc('A1'),
      bc('B1'),
      bc('A2'),
      bc('B2'),
      bc('A1'),
    ]);
    expect(raised.characters, same(s.characters));
    expect(
      raised.characters.all.single.occupiedCells
          .map((c) => raised.terrain.at(c).level)
          .toSet(),
      {2},
    );
    final capped = raised.paintElevation([bc('D4')], 40);
    expect(
      () => capped.raiseElevations([bc('C4'), bc('D4')]),
      throwsArgumentError,
    );
    expect(capped.terrain.at(bc('C4')).level, 1);
  });
  testWidgets(
    'Borrar total por trazo limpia capas, quita bases completas y conserva lo ajeno; un Deshacer',
    (t) async {
      final c = await openEditor(t);
      c.attempt(
        (s) => s
            .paintElevation([bc('A1')], 3)
            .paintElevation([bc('D1')], 2)
            .paintElevation([bc('F4')], 4)
            .paintTerrain([bc('A1'), bc('B1'), bc('F4')], TerrainType.hindering)
            .paintTerrain([bc('D1')], TerrainType.blocking)
            .editWalls([be('A1', 'B1'), be('E4', 'E5')], erase: false)
            .setTransition(be('A1', 'A2'), remove: false)
            .setTransition(be('C1', 'D1'), remove: false)
            .setTransition(be('F4', 'G4'), remove: false),
      );
      c.saveCharacter(data('B1', footprint: Footprint.square2));
      c.saveCharacter(data('E4'));
      await press(t, 'tool-erase');
      expect(c.value.eraseLayer, EraseLayer.all);
      final before = c.value, count = c.history.undoCount;
      await stroke(t, c, ['A1', 'C1']);
      expect(find.byKey(const ValueKey('confirm-erase-figure')), findsNothing);
      for (final at in ['A1', 'B1', 'C1']) {
        expect(c.value.terrain.at(bc(at)), CellTerrain.clear);
      }
      expect(c.value.characters.byId('figure-1'), isNull);
      expect(
        c.value.characters.byId('figure-2'),
        same(before.characters.byId('figure-2')),
      );
      expect(c.value.walls.edges.keys, {be('E4', 'E5').id});
      expect(c.value.terrain.transitions, {be('F4', 'G4')});
      expect(c.value.terrain.at(bc('D1')), before.terrain.at(bc('D1')));
      expect(c.value.terrain.at(bc('F4')), before.terrain.at(bc('F4')));
      expect(c.value.nextCharacter, 3);
      expect(c.history.undoCount, count + 1);
      c.undo();
      expect(c.value.terrain, same(before.terrain));
      expect(c.value.characters, same(before.characters));
      expect(c.value.walls, same(before.walls));
      c.redo();
      expect(c.value.characters.length, 1);
    },
  );
  testWidgets('borrar vacío no crea historial', (t) async {
    final c = await openEditor(t);
    await press(t, 'tool-erase');
    final count = c.history.undoCount;
    await stroke(t, c, ['A1', 'C1']);
    expect(c.history.undoCount, count);
    expect(c.value.terrain.isEmpty, isTrue);
  });
  for (final erase in [false, true]) {
    testWidgets(
      'cancelar o añadir segundo dedo descarta el trazo ${erase ? 'de borrado' : 'de altura'}',
      (t) async {
        final c = await openEditor(t);
        c.attempt((s) => s.paintTerrain([bc('B2')], TerrainType.hindering));
        if (erase) {
          await press(t, 'tool-erase');
        } else {
          await press(t, 'tool-terrain');
          await press(t, 'terrain-elevated');
        }
        final before = c.value, count = c.history.undoCount;
        var g = await t.startGesture(cellPosition(t, c, 'B2'));
        await g.moveTo(cellPosition(t, c, 'C2'));
        await g.cancel();
        await t.pumpAndSettle();
        expect(c.draft.value, isNull);
        expect(c.value.terrain, same(before.terrain));
        g = await t.startGesture(cellPosition(t, c, 'B2'), pointer: 2);
        final second = await t.startGesture(
          cellPosition(t, c, 'D2'),
          pointer: 3,
        );
        await t.pump();
        await g.up();
        await second.up();
        await t.pumpAndSettle();
        expect(c.draft.value, isNull);
        expect(c.value.terrain, same(before.terrain));
        expect(c.history.undoCount, count);
      },
    );
  }
  testWidgets(
    'ayuda vertical lateral dura cuatro segundos, se renueva y no usa SnackBar',
    (t) async {
      final c = await openEditor(t);
      c.setTool(EditorTool.characters);
      await t.pump();
      final key = find.byKey(const ValueKey('tool-hint-vertical'));
      expect(key, findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(t.widget<RotatedBox>(key).quarterTurns, 3);
      final map = t.getRect(find.byKey(const ValueKey('board-viewport'))),
          hint = t.getRect(key);
      expect(hint.right, closeTo(map.right - 8, 1));
      expect(hint.height, greaterThan(hint.width));
      expect(
        t
            .widget<IgnorePointer>(
              find
                  .ancestor(of: key, matching: find.byType(IgnorePointer))
                  .first,
            )
            .ignoring,
        isTrue,
      );
      final camera = c.value.camera;
      await t.pump(const Duration(seconds: 3));
      expect(key, findsOneWidget);
      await t.pump(const Duration(seconds: 1));
      expect(key, findsNothing);
      expect(c.value.camera, camera);
      c.setTool(EditorTool.characters);
      await t.pump();
      expect(key, findsOneWidget);
      await t.pump(ToolHint.duration);
      expect(key, findsNothing);
    },
  );
  for (final (size, scale) in [
    (const Size(360, 800), 1.0),
    (const Size(800, 360), 1.0),
    (const Size(320, 320), 3.0),
  ]) {
    testWidgets('ayuda y paleta sin desbordes en $size texto $scale', (
      t,
    ) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      t.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final c = await openEditor(t);
      await press(t, 'tool-terrain');
      await press(t, 'terrain-elevated');
      expect(find.byKey(const ValueKey('tool-hint-vertical')), findsOneWidget);
      expect(c.value.tool, EditorTool.terrain);
      expect(t.takeException(), isNull);
    });
  }
}

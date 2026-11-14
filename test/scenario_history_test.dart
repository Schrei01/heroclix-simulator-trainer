import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/application/board/board_edit.dart';
import 'package:heroclix_simulator_trainer/application/board/board_session.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_dimensions.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_viewport.dart';
import 'package:heroclix_simulator_trainer/domain/board/cell_coordinate.dart';
import 'package:heroclix_simulator_trainer/domain/characters/team.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/edge_wall.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/terrain.dart';

import 'scenario_codec_test.dart' show character, cell;

void main() {
  test('deshacer/rehacer secuencia de figuras, movimiento, terreno, muro, limpiezas, tamaño y equipo', () {
    final history = EditorHistory();
    final initial = BoardSession.initial().resizeViewport(
      ViewportSize(400, 800),
    );
    var state = initial;
    final operations = <BoardSession Function(BoardSession)>[
      (s) => s.createCharacter(character('A1')),
      (s) => s.moveCharacter('figure-1', cell('C1')),
      (s) => s.paintTerrain([cell('A1'), cell('B1')], TerrainType.hindering),
      (s) =>
          s.editWalls([EdgeWall.between(cell('A1'), cell('B1'))], erase: false),
      (s) => s.clearTerrain(),
      (s) => s.clearCharacters(),
      (s) => s.clearWalls(),
      (s) => s.changeDimensions(BoardDimensions(rows: 8, columns: 12)),
      (s) => s.addTeam(
        name: 'Verde',
        color: 0xff81c784,
        pattern: TeamPattern.dots,
      ),
    ];
    for (final operation in operations) {
      final after = operation(state);
      history.record(BoardEdit.between(state, after));
      state = after;
    }
    final finalState = state;
    for (var i = 0; i < operations.length; i++) {
      state = history.undo(state);
    }
    expect(BoardEdit.sameContent(state, initial), isTrue);
    expect(history.canUndo, isFalse);
    expect(state.nextCharacter, 2);
    expect(state.nextTeam, 4);
    expect(state.viewport, initial.viewport);
    for (var i = 0; i < operations.length; i++) {
      state = history.redo(state);
    }
    expect(BoardEdit.sameContent(state, finalState), isTrue);
    expect(history.canRedo, isFalse);
    state = history.undo(state);
    final edited = state.paintTerrain([cell('D4')], TerrainType.blocking);
    history.record(BoardEdit.between(state, edited));
    expect(history.canRedo, isFalse);
  });
  test('límite acotado, cámara/selección fuera del historial y abrir reinicia pilas', () {
    final history = EditorHistory(limit: 3);
    var state = BoardSession.initial().resizeViewport(ViewportSize(400, 800));
    for (final label in ['A1', 'B1', 'C1', 'D1', 'A2']) {
      final after = state.paintTerrain([cell(label)], TerrainType.hindering);
      history.record(BoardEdit.between(state, after));
      state = after;
    }
    expect(history.undoCount, 3);
    final camera = state.zoom(2).camera;
    state = state.withCamera(camera).toggleCell(CellCoordinate.parse('B2'));
    for (var i = 0; i < 3; i++) {
      state = history.undo(state);
      expect(state.camera, camera);
    }
    expect(state.terrain.cells.length, 2);
    expect(state.selectedCell, isNull);
    history.clear();
    expect(history.canRedo, isFalse);
    expect(history.canUndo, isFalse);
  });
}

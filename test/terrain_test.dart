import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/application/board/board_edit.dart';
import 'package:heroclix_simulator_trainer/application/board/board_session.dart';
import 'package:heroclix_simulator_trainer/application/board/layer_codec.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_dimensions.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_viewport.dart';
import 'package:heroclix_simulator_trainer/domain/board/cell_coordinate.dart';
import 'package:heroclix_simulator_trainer/domain/characters/character.dart';
import 'package:heroclix_simulator_trainer/domain/characters/character_repository.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/terrain.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/edge_wall.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/editing_geometry.dart';

CellCoordinate c(String value) => CellCoordinate.parse(value);
CharacterDraft figure(String cell, {Footprint footprint = Footprint.single}) =>
    CharacterDraft(
      name: 'Figura',
      teamId: 'team-1',
      position: c(cell),
      footprint: footprint,
    );
EdgeWall wall(String a, String b) => EdgeWall.between(c(a), c(b));

void main() {
  test('despejado por defecto, obstaculizado ocupado sin pérdida y capas independientes', () {
    final original = BoardSession.initial().createCharacter(figure('B2'));
    expect(original.terrain.at(c('A1')), CellTerrain.clear);
    expect(original.terrain.at(c('A1')).elevation, 0);
    final state = original
        .editWalls([wall('A1', 'B1')], erase: false)
        .paintTerrain([c('B2'), c('C2')], TerrainType.hindering);
    expect(state.characters, same(original.characters));
    expect(original.terrain.isEmpty, isTrue);
    expect(state.terrain.at(c('B2')).type, TerrainType.hindering);
    final clear = state.paintTerrain([c('B2')], TerrainType.clear);
    expect(clear.terrain.at(c('B2')), CellTerrain.clear);
    expect(clear.characters, same(original.characters));
    expect(clear.walls, same(state.walls));
    expect(() => state.terrain.cells.clear(), throwsUnsupportedError);
  });
  test('bloqueado ocupado se rechaza; documentos antiguos conservan datos para corregirlos', () {
    final before = BoardSession.initial().createCharacter(
      figure('B2', footprint: Footprint.square2),
    );
    final targets = [c('C3'), c('D4')];
    expect(before.blockingConflicts(targets, TerrainType.blocking), [c('C3')]);
    expect(
      () => before.paintTerrain(targets, TerrainType.blocking),
      throwsA(isA<PlacementException>()),
    );
    expect(before.terrain.isEmpty, isTrue);
    // Fixture heredada: la restauración conserva datos; editar ya no permite crearlos.
    final study = before.replaceLayers(
      terrain: before.terrain.paint(
        targets,
        TerrainType.blocking,
        before.dimensions,
      ),
      walls: before.walls,
      characters: before.characters,
    );
    expect(study.studyConflicts, {c('C3')});
    expect(study.characters, same(before.characters));
    expect(study.clearTerrain().studyConflicts, isEmpty);
    expect(
      study.deleteCharacter(study.selectedCharacterId!).studyConflicts,
      isEmpty,
    );
  });
  test(
    'bloqueado rechaza creación, movimiento, duplicación y edición de figuras',
    () {
      final before = BoardSession.initial().paintTerrain([
        c('A1'),
      ], TerrainType.blocking);
      expect(
        () => before.createCharacter(figure('A1')),
        throwsA(isA<PlacementException>()),
      );
      final state = before.createCharacter(figure('B1'));
      final id = state.selectedCharacterId!;
      expect(
        state
            .validateFigurePlacement(state.selectedCharacter!, c('A1'))
            .isValid,
        isFalse,
      );
      expect(
        () => state.moveCharacter(id, c('A1')),
        throwsA(isA<PlacementException>()),
      );
      expect(state.selectedCharacter!.position, c('B1'));
      expect(
        () => state.editCharacter(id, figure('A1')),
        throwsA(isA<PlacementException>()),
      );
      expect(
        () => state.duplicateCharacter(id, c('A1')),
        throwsA(isA<PlacementException>()),
      );
      expect(state.selectedCharacter!.position, c('B1'));
      expect(state.studyConflicts, isEmpty);
    },
  );
  test('muro compartido normalizado, sin duplicación, borrar solo el muro', () {
    final a = wall('A1', 'B1'), b = wall('B1', 'A1');
    expect(a, b);
    expect(a.id, 'v:1:0');
    expect(wall('A1', 'A2').id, 'h:0:1');
    expect(wall('A2', 'A1'), wall('A1', 'A2'));
    final before = BoardSession.initial()
        .createCharacter(figure('A1'))
        .paintTerrain([c('A1')], TerrainType.hindering);
    final state = before.editWalls([a, b], erase: false);
    expect(state.walls.edges.length, 1);
    expect(state.walls.contains(b), isTrue);
    final erased = state.editWalls([b], erase: true);
    expect(erased.walls.isEmpty, isTrue);
    expect(erased.characters, same(state.characters));
    expect(erased.terrain, same(state.terrain));
    expect(() => wall('A1', 'B2'), throwsArgumentError);
    expect(() => state.walls.edges.clear(), throwsUnsupportedError);
  });
  test('bordes externos inválidos y hit tests fuera no generan cambios ni error de UI', () {
    final state = BoardSession.initial().changeDimensions(
      BoardDimensions(rows: 4, columns: 4),
    );
    for (final edge in [
      EdgeWall(axis: EdgeAxis.vertical, column: 0, row: 0),
      EdgeWall(axis: EdgeAxis.vertical, column: 4, row: 0),
      EdgeWall(axis: EdgeAxis.horizontal, column: 0, row: 0),
      EdgeWall(axis: EdgeAxis.horizontal, column: 0, row: 4),
    ]) {
      expect(edge.isInternal(state.dimensions), isFalse);
      expect(() => state.editWalls([edge], erase: false), throwsArgumentError);
    }
    const geometry = EditingGeometry();
    for (final point in [
      const BoardPoint(-1, 64),
      const BoardPoint(32, 64),
      const BoardPoint(288, 64),
      const BoardPoint(64, 64),
    ]) {
      expect(geometry.edgeAt(point, state.dimensions), isNull);
    }
    expect(
      geometry.edgeAt(const BoardPoint(96, 64), state.dimensions),
      wall('A1', 'B1'),
    );
    expect(
      geometry.edgeAt(const BoardPoint(64, 96), state.dimensions),
      wall('A1', 'A2'),
    );
  });
  test('todos los muros internos de 40×40 tienen IDs únicos y ambas direcciones equivalentes', () {
    final dims = BoardDimensions(rows: 40, columns: 40);
    final edges = <EdgeWall>{};
    for (var row = 0; row < 40; row++) {
      for (var col = 0; col < 40; col++) {
        final a = CellCoordinate(column: col, row: row);
        for (final b in [
          if (col < 39) CellCoordinate(column: col + 1, row: row),
          if (row < 39) CellCoordinate(column: col, row: row + 1),
        ]) {
          final edge = EdgeWall.between(a, b);
          expect(edge, EdgeWall.between(b, a));
          expect(edge.isInternal(dims), isTrue);
          edges.add(edge);
        }
      }
    }
    expect(edges.length, 3120);
    expect(edges.map((edge) => edge.id).toSet().length, 3120);
  });
  test('trazos rápidos interpolados cubren todas las celdas incluso entrando/saliendo del mapa', () {
    const geometry = EditingGeometry();
    final dims = BoardDimensions(rows: 40, columns: 40);
    final across = geometry.cellsAlong(
      const BoardPoint(-100, 64),
      const BoardPoint(3000, 64),
      dims,
    );
    expect(across.length, 40);
    expect(across.first, c('A1'));
    expect(across.last, c('AN1'));
    final down = geometry.cellsAlong(
      const BoardPoint(64, 2591),
      const BoardPoint(64, 33),
      dims,
    );
    expect(down.length, 40);
    expect(down.first, c('A40'));
    expect(down.last, c('A1'));
    final diagonal = geometry.cellsAlong(
      const BoardPoint(64, 64),
      const BoardPoint(2560, 2560),
      dims,
    );
    expect(diagonal.length, 40);
    expect(
      geometry.cellsAlong(
        const BoardPoint(-100, -100),
        const BoardPoint(-50, -50),
        dims,
      ),
      isEmpty,
    );
    expect(geometry.rectangle(c('D4'), c('B2')).toSet().length, 9);
    expect(
      geometry.rectangle(c('B2'), c('D4')).toSet(),
      geometry.rectangle(c('D4'), c('B2')).toSet(),
    );
  });
  test('limpiar una capa conserva las otras y no recicla IDs de figuras', () {
    final state = BoardSession.initial()
        .createCharacter(figure('A1'))
        .paintTerrain([c('A1')], TerrainType.hindering)
        .editWalls([wall('A1', 'B1')], erase: false);
    final terrain = state.clearTerrain();
    expect(terrain.terrain.isEmpty, isTrue);
    expect(terrain.characters, same(state.characters));
    expect(terrain.walls, same(state.walls));
    final walls = state.clearWalls();
    expect(walls.walls.isEmpty, isTrue);
    expect(walls.terrain, same(state.terrain));
    expect(walls.characters, same(state.characters));
    final figures = state.clearCharacters();
    expect(figures.characters.isEmpty, isTrue);
    expect(figures.terrain, same(state.terrain));
    expect(figures.walls, same(state.walls));
    expect(figures.createCharacter(figure('A1')).selectedCharacter!.label, 'B');
  });
  test('comandos reversibles de trazo, muro y limpieza conservan cámara; estado ajeno se rechaza', () {
    var before = BoardSession.initial().resizeViewport(ViewportSize(400, 800));
    for (final operation in <BoardSession Function(BoardSession)>[
      (s) => s.paintTerrain([c('A1'), c('B1')], TerrainType.hindering),
      (s) => s.editWalls([wall('A1', 'B1')], erase: false),
      (s) => s.createCharacter(figure('C3')),
      (s) => s.clearTerrain(),
      (s) => s.clearWalls(),
      (s) => s.clearCharacters(),
    ]) {
      final after = operation(before),
          command = BoardEdit.between(before, operation(before));
      final applied = command.apply(before).zoom(2);
      if (after.characters.length > before.characters.length) {
        final following = applied.createCharacter(figure('D4'));
        expect(following.selectedCharacter!.label, 'B');
        expect(following.characters.length, 2);
      }
      final undone = command.reverse(applied);
      expect(undone.terrain, same(before.terrain));
      expect(undone.walls, same(before.walls));
      expect(undone.characters, same(before.characters));
      expect(undone.camera, applied.camera);
      final replay = command.apply(undone);
      expect(replay.terrain.cells, after.terrain.cells);
      expect(replay.walls.edges, after.walls.edges);
      before = after;
    }
    final changed = before.paintTerrain([c('D4')], TerrainType.blocking);
    final command = BoardEdit.between(before, changed);
    expect(() => command.reverse(before), throwsStateError);
  });
  test(
    'reducir no descarta terreno ni convierte muros internos en externos',
    () {
      final state = BoardSession.initial().paintTerrain([
        c('D4'),
      ], TerrainType.hindering);
      expect(
        () => state.changeDimensions(BoardDimensions(rows: 3, columns: 3)),
        throwsA(isA<PlacementException>()),
      );
      final withWall = BoardSession.initial().editWalls([
        wall('C1', 'D1'),
      ], erase: false);
      expect(
        () => withWall.changeDimensions(BoardDimensions(rows: 4, columns: 3)),
        throwsA(isA<PlacementException>()),
      );
      final bigger = state.changeDimensions(
        BoardDimensions(rows: 8, columns: 12),
      );
      expect(bigger.terrain, same(state.terrain));
    },
  );
  test('fragmento serializable de capas reproduce terreno/elevación/muros de forma determinista', () {
    const codec = LayerCodec();
    var state = BoardSession.initial()
        .paintTerrain([c('B2'), c('A1')], TerrainType.hindering)
        .editWalls([wall('A1', 'B1'), wall('B2', 'B3')], erase: false);
    state = state.replaceLayers(
      terrain: state.terrain.put(
        c('D4'),
        CellTerrain(type: TerrainType.blocking, elevation: 3),
        state.dimensions,
      ),
      walls: state.walls,
      characters: state.characters,
    );
    final json = jsonEncode(codec.encode(state));
    final decoded = codec.decode(jsonDecode(json), state.dimensions);
    final restored = state.replaceLayers(
      terrain: decoded.terrain,
      walls: decoded.walls,
      characters: state.characters,
    );
    expect(jsonEncode(codec.encode(restored)), json);
    expect(restored.terrain.at(c('D4')).elevation, 3);
    expect(() => CellTerrain(elevation: -1), throwsRangeError);
    expect(() => CellTerrain(elevation: 41), throwsRangeError);
    expect(state.terrain.at(c('D4')).type, TerrainType.blocking);
  });
  test('fragmento rechaza datos corruptos, versión desconocida, duplicados, bordes externos e IDs falsos', () {
    const codec = LayerCodec();
    final state = BoardSession.initial()
        .changeDimensions(BoardDimensions(rows: 4, columns: 4))
        .paintTerrain([c('A1')], TerrainType.hindering)
        .editWalls([wall('A1', 'B1')], erase: false);
    Map<String, dynamic> fresh() =>
        jsonDecode(jsonEncode(codec.encode(state))) as Map<String, dynamic>;
    final corrupt = <Map<String, dynamic>>[];
    var map = fresh();
    map['layerSchemaVersion'] = 999;
    corrupt.add(map);
    map = fresh();
    map['terrain'].add(map['terrain'].first);
    corrupt.add(map);
    map = fresh();
    map['walls'].add(map['walls'].first);
    corrupt.add(map);
    map = fresh();
    map['walls'][0]['id'] = 'v:99:99';
    corrupt.add(map);
    map = fresh();
    map['walls'][0] = {
      'id': 'v:0:0',
      'axis': 'vertical',
      'column': 0,
      'row': 0,
    };
    corrupt.add(map);
    map = fresh();
    map['terrain'][0]['cell'] = 'E1';
    corrupt.add(map);
    map = fresh();
    map['terrain'][0]['type'] = 'lava';
    corrupt.add(map);
    map = fresh();
    map['terrain'][0]['elevation'] = 1.5;
    corrupt.add(map);
    map = fresh();
    map['terrain'] = List.filled(17, map['terrain'].first);
    corrupt.add(map);
    map = fresh();
    map['unknown'] = true;
    corrupt.add(map);
    for (final value in corrupt) {
      expect(
        () => codec.decode(value, state.dimensions),
        throwsFormatException,
      );
    }
    expect(() => codec.decode(null, state.dimensions), throwsFormatException);
  });
}

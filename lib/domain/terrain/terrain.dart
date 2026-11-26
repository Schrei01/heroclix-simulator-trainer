import '../board/board_dimensions.dart';
import '../board/cell_coordinate.dart';
import 'edge_wall.dart';

enum TerrainType { clear, hindering, blocking, water }

enum MapEnvironment { outdoor, indoor }

/// El 0 histórico es un alias de suelo (nivel oficial 1), nunca un nivel oficial 0.
final class CellTerrain {
  factory CellTerrain({
    TerrainType type = TerrainType.clear,
    int elevation = 0,
  }) {
    RangeError.checkValueInInterval(elevation, 0, 40, 'elevation');
    return CellTerrain._(type, elevation);
  }
  const CellTerrain._(this.type, this.elevation);
  static const clear = CellTerrain._(TerrainType.clear, 0);
  final TerrainType type;
  final int elevation;
  int get level => elevation == 0 ? 1 : elevation;
  @override
  bool operator ==(Object other) =>
      other is CellTerrain &&
      type == other.type &&
      elevation == other.elevation;
  @override
  int get hashCode => Object.hash(type, elevation);
}

final class TerrainLayer {
  const TerrainLayer.empty({this.environment = MapEnvironment.outdoor})
    : cells = const {},
      transitions = const {},
      indoorCells = const {},
      debrisCells = const {};
  TerrainLayer._(
    Map<CellCoordinate, CellTerrain> values, [
    Iterable<EdgeWall> steps = const [],
    this.environment = MapEnvironment.outdoor,
    Iterable<CellCoordinate> inside = const [],
    Iterable<CellCoordinate> debris = const [],
  ]) : cells = Map.unmodifiable(values),
       transitions = Set.unmodifiable(steps),
       indoorCells = Set.unmodifiable(inside),
       debrisCells = Set.unmodifiable(debris);
  final Map<CellCoordinate, CellTerrain> cells;
  final Set<EdgeWall> transitions;
  final MapEnvironment environment;
  final Set<CellCoordinate> indoorCells;
  final Set<CellCoordinate> debrisCells;
  bool isIndoor(CellCoordinate cell) =>
      environment == MapEnvironment.indoor || indoorCells.contains(cell);
  TerrainLayer _with(
    Map<CellCoordinate, CellTerrain> values, [
    Iterable<EdgeWall> steps = const [],
    Iterable<CellCoordinate>? inside,
    Iterable<CellCoordinate>? debris,
  ]) => TerrainLayer._(
    values,
    steps,
    environment,
    inside ?? indoorCells,
    debris ?? debrisCells,
  );
  TerrainLayer setEnvironment(MapEnvironment next) =>
      next == environment && indoorCells.isEmpty
      ? this
      : TerrainLayer._(cells, transitions, next, const [], debrisCells);
  TerrainLayer paintIndoor(
    Iterable<CellCoordinate> targets,
    BoardDimensions dimensions, {
    bool remove = false,
  }) {
    final inside = {...indoorCells};
    for (final cell in targets) {
      if (!dimensions.contains(cell)) {
        throw ArgumentError('Casilla Indoor fuera del tablero.');
      }
      if (remove) {
        inside.remove(cell);
      } else if (environment == MapEnvironment.outdoor) {
        inside.add(cell);
      }
    }
    if (inside.length == indoorCells.length &&
        inside.every(indoorCells.contains)) {
      return this;
    }
    return _with(cells, transitions, inside);
  }

  CellTerrain baseAt(CellCoordinate cell) => cells[cell] ?? CellTerrain.clear;
  CellTerrain at(CellCoordinate cell) => debrisCells.contains(cell)
      ? CellTerrain(
          type: TerrainType.hindering,
          elevation: baseAt(cell).elevation,
        )
      : baseAt(cell);

  TerrainLayer withDebris(
    Iterable<CellCoordinate> targets,
    BoardDimensions dimensions, {
    bool remove = false,
  }) {
    final debris = {...debrisCells};
    for (final cell in targets) {
      if (!dimensions.contains(cell)) {
        throw ArgumentError('Escombros fuera del tablero.');
      }
      if (remove) {
        debris.remove(cell);
      } else {
        debris.add(cell);
      }
    }
    return _with(cells, transitions, indoorCells, debris);
  }

  TerrainLayer destroyBlocking(
    Iterable<CellCoordinate> targets,
    BoardDimensions dimensions,
  ) {
    final values = {...cells}, debris = {...debrisCells};
    for (final cell in targets) {
      if (!dimensions.contains(cell)) {
        throw ArgumentError('Destrucción fuera del tablero.');
      }
      if (at(cell).type != TerrainType.blocking) continue;
      final cleared = CellTerrain(elevation: baseAt(cell).elevation);
      values.remove(cell);
      if (cleared != CellTerrain.clear) values[cell] = cleared;
      debris.add(cell);
    }
    return _with(values, transitions, indoorCells, debris);
  }

  bool get isEmpty =>
      cells.isEmpty &&
      transitions.isEmpty &&
      indoorCells.isEmpty &&
      debrisCells.isEmpty &&
      environment == MapEnvironment.outdoor;
  TerrainLayer paint(
    Iterable<CellCoordinate> targets,
    TerrainType type,
    BoardDimensions dimensions,
  ) {
    final values = {...cells}, debris = {...debrisCells};
    for (final cell in targets) {
      debris.remove(cell);
      if (!dimensions.contains(cell)) {
        throw RangeError(
          'Casilla de terreno fuera del tablero: ${cell.label}.',
        );
      }
      final value = CellTerrain(type: type, elevation: at(cell).elevation);
      if (value == CellTerrain.clear) {
        values.remove(cell);
      } else {
        values[cell] = value;
      }
    }
    return _with(values, transitions, indoorCells, debris);
  }

  TerrainLayer put(
    CellCoordinate cell,
    CellTerrain terrain,
    BoardDimensions dimensions,
  ) {
    if (!dimensions.contains(cell)) {
      throw RangeError('Terreno fuera del tablero.');
    }
    return _with(
      {...cells}
        ..remove(cell)
        ..addAll(terrain == CellTerrain.clear ? {} : {cell: terrain}),
      transitions,
    );
  }

  TerrainLayer paintElevation(
    Iterable<CellCoordinate> targets,
    int level,
    BoardDimensions dimensions,
  ) {
    RangeError.checkValueInInterval(level, 1, 40, 'level');
    final values = {...cells};
    for (final cell in targets) {
      if (!dimensions.contains(cell)) {
        throw RangeError('Casilla fuera del tablero.');
      }
      final value = CellTerrain(
        type: baseAt(cell).type,
        elevation: level == 1 ? 0 : level,
      );
      if (value == CellTerrain.clear) {
        values.remove(cell);
      } else {
        values[cell] = value;
      }
    }
    final result = TerrainLayer._(values);
    return _with(
      result.cells,
      transitions.where(
        (e) =>
            e.isInternal(dimensions) &&
            result.at(e.firstCell).level != result.at(e.secondCell).level,
      ),
    );
  }

  TerrainLayer setTransition(
    EdgeWall edge,
    BoardDimensions dimensions, {
    required bool remove,
  }) {
    if (!edge.isInternal(dimensions)) {
      throw ArgumentError('Transición fuera del tablero.');
    }
    if (!remove && at(edge.firstCell).level == at(edge.secondCell).level) {
      throw ArgumentError(
        'Una transición de altura debe unir niveles distintos.',
      );
    }
    return _with(
      cells,
      {...transitions}
        ..remove(edge)
        ..addAll(remove ? [] : [edge]),
    );
  }

  /// Cada casilla se incrementa una sola vez respecto al comienzo del trazo.
  TerrainLayer raiseElevations(
    Iterable<CellCoordinate> targets,
    BoardDimensions dimensions,
  ) {
    final values = {...cells};
    for (final cell in targets.toSet()) {
      if (!dimensions.contains(cell)) {
        throw ArgumentError('Casilla fuera del tablero.');
      }
      final before = at(cell);
      if (before.level >= 40) {
        throw ArgumentError('La elevación máxima es E40.');
      }
      values[cell] = CellTerrain(
        type: baseAt(cell).type,
        elevation: before.level + 1,
      );
    }
    final result = TerrainLayer._(values);
    return _with(
      result.cells,
      transitions.where(
        (e) => result.at(e.firstCell).level != result.at(e.secondCell).level,
      ),
    );
  }

  TerrainLayer eraseCells(
    Iterable<CellCoordinate> targets,
    BoardDimensions dimensions,
  ) {
    final cleared = targets.toSet();
    for (final cell in cleared) {
      if (!dimensions.contains(cell)) {
        throw ArgumentError('Casilla fuera del tablero.');
      }
    }
    return _with(
      {...cells}..removeWhere((cell, _) => cleared.contains(cell)),
      transitions.where(
        (e) =>
            !cleared.contains(e.firstCell) && !cleared.contains(e.secondCell),
      ),
      indoorCells.difference(cleared),
      debrisCells.difference(cleared),
    );
  }
}

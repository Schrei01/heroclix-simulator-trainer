import '../board/board_dimensions.dart';
import '../board/cell_coordinate.dart';

enum TerrainType { clear, hindering, blocking }

/// Elevación preparada como dato; no habilita análisis de altura.
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
  @override
  bool operator ==(Object other) =>
      other is CellTerrain &&
      type == other.type &&
      elevation == other.elevation;
  @override
  int get hashCode => Object.hash(type, elevation);
}

final class TerrainLayer {
  const TerrainLayer.empty() : cells = const {};
  TerrainLayer._(Map<CellCoordinate, CellTerrain> values)
    : cells = Map.unmodifiable(values);
  final Map<CellCoordinate, CellTerrain> cells;
  CellTerrain at(CellCoordinate cell) => cells[cell] ?? CellTerrain.clear;
  bool get isEmpty => cells.isEmpty;
  TerrainLayer paint(
    Iterable<CellCoordinate> targets,
    TerrainType type,
    BoardDimensions dimensions,
  ) {
    final values = {...cells};
    for (final cell in targets) {
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
    return TerrainLayer._(values);
  }

  TerrainLayer put(
    CellCoordinate cell,
    CellTerrain terrain,
    BoardDimensions dimensions,
  ) {
    if (!dimensions.contains(cell)) {
      throw RangeError('Terreno fuera del tablero.');
    }
    return TerrainLayer._(
      {...cells}
        ..remove(cell)
        ..addAll(terrain == CellTerrain.clear ? {} : {cell: terrain}),
    );
  }
}

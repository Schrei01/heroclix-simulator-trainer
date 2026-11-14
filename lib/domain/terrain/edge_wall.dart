import '../board/board_dimensions.dart';
import '../board/cell_coordinate.dart';

enum EdgeAxis { horizontal, vertical }

/// Segmento de longitud uno, expresado por su vértice de menor índice.
final class EdgeWall {
  factory EdgeWall({
    required EdgeAxis axis,
    required int column,
    required int row,
  }) {
    if (column < 0 || row < 0) {
      throw ArgumentError('Borde con índices negativos.');
    }
    return EdgeWall._(axis, column, row);
  }
  const EdgeWall._(this.axis, this.column, this.row);
  factory EdgeWall.between(CellCoordinate a, CellCoordinate b) {
    final dx = b.column - a.column, dy = b.row - a.row;
    if (dx.abs() + dy.abs() != 1) {
      throw ArgumentError('El muro requiere dos casillas vecinas ortogonales.');
    }
    return dx != 0
        ? EdgeWall(
            axis: EdgeAxis.vertical,
            column: dx > 0 ? b.column : a.column,
            row: a.row,
          )
        : EdgeWall(
            axis: EdgeAxis.horizontal,
            column: a.column,
            row: dy > 0 ? b.row : a.row,
          );
  }
  final EdgeAxis axis;
  final int column, row;
  String get id => '${axis == EdgeAxis.vertical ? 'v' : 'h'}:$column:$row';
  bool isInternal(BoardDimensions dimensions) => axis == EdgeAxis.vertical
      ? column > 0 && column < dimensions.columns && row < dimensions.rows
      : row > 0 && row < dimensions.rows && column < dimensions.columns;
  @override
  bool operator ==(Object other) =>
      other is EdgeWall &&
      axis == other.axis &&
      column == other.column &&
      row == other.row;
  @override
  int get hashCode => Object.hash(axis, column, row);
}

final class WallLayer {
  const WallLayer.empty() : edges = const {};
  WallLayer._(Map<String, EdgeWall> values) : edges = Map.unmodifiable(values);
  final Map<String, EdgeWall> edges;
  bool get isEmpty => edges.isEmpty;
  bool contains(EdgeWall edge) => edges.containsKey(edge.id);
  WallLayer edit(
    Iterable<EdgeWall> targets,
    BoardDimensions dimensions, {
    required bool erase,
  }) {
    final values = {...edges};
    for (final edge in targets) {
      if (!edge.isInternal(dimensions)) {
        throw ArgumentError('Solo se admiten muros en bordes internos.');
      }
      if (erase) {
        values.remove(edge.id);
      } else {
        values[edge.id] = edge;
      }
    }
    return WallLayer._(values);
  }
}

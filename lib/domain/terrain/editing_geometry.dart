import 'dart:math' as math;

import '../board/board_dimensions.dart';
import '../board/board_viewport.dart';
import '../board/cell_coordinate.dart';
import 'edge_wall.dart';

/// Geometría de edición, sin interpretación reglamentaria.
final class EditingGeometry {
  const EditingGeometry();
  Iterable<CellCoordinate> rectangle(CellCoordinate a, CellCoordinate b) sync* {
    for (
      var row = math.min(a.row, b.row);
      row <= math.max(a.row, b.row);
      row++
    ) {
      for (
        var col = math.min(a.column, b.column);
        col <= math.max(a.column, b.column);
        col++
      ) {
        yield CellCoordinate(column: col, row: row);
      }
    }
  }

  /// Divide el trazo en todos sus cruces de cuadrícula: no depende de la frecuencia de eventos.
  Set<CellCoordinate> cellsAlong(
    BoardPoint a,
    BoardPoint b,
    BoardDimensions dimensions,
  ) {
    if (!a.x.isFinite || !a.y.isFinite || !b.x.isFinite || !b.y.isFinite) {
      return {};
    }
    const geometry = BoardGeometry();
    const gutter = BoardGeometry.gutter, size = BoardGeometry.cellExtent;
    final times = <double>{0, 1};
    final dx = b.x - a.x, dy = b.y - a.y;
    void crossing(double value) {
      if (value > 0 && value < 1) times.add(value);
    }

    if (dx != 0) {
      for (var col = 0; col <= dimensions.columns; col++) {
        crossing((gutter + col * size - a.x) / dx);
      }
    }
    if (dy != 0) {
      for (var row = 0; row <= dimensions.rows; row++) {
        crossing((gutter + row * size - a.y) / dy);
      }
    }
    final sorted = times.toList()..sort();
    final cells = <CellCoordinate>{};
    void sample(double t) {
      final cell = geometry.cellAt(
        BoardPoint(a.x + dx * t, a.y + dy * t),
        dimensions,
      );
      if (cell != null) cells.add(cell);
    }

    sample(0);
    for (var i = 1; i < sorted.length; i++) {
      sample((sorted[i - 1] + sorted[i]) / 2);
    }
    sample(1);
    return cells;
  }

  /// Franja de 0,22 casillas; empate en vértice favorece borde vertical.
  EdgeWall? edgeAt(
    BoardPoint point,
    BoardDimensions dimensions, {
    EdgeAxis? axis,
  }) {
    if (!point.x.isFinite || !point.y.isFinite) return null;
    const size = BoardGeometry.cellExtent, gutter = BoardGeometry.gutter;
    final x = (point.x - gutter) / size, y = (point.y - gutter) / size;
    if (x < 0 || y < 0 || x >= dimensions.columns || y >= dimensions.rows) {
      return null;
    }
    final vx = x.round(), hy = y.round();
    final verticalDistance = (x - vx).abs(),
        horizontalDistance = (y - hy).abs();
    final candidates = <(double, EdgeWall)>[
      (
        verticalDistance,
        EdgeWall(axis: EdgeAxis.vertical, column: vx, row: y.floor()),
      ),
      (
        horizontalDistance,
        EdgeWall(axis: EdgeAxis.horizontal, column: x.floor(), row: hy),
      ),
    ];
    if (horizontalDistance + 1e-9 < verticalDistance) {
      final first = candidates.removeAt(0);
      candidates.add(first);
    }
    // Un borde externo cercano no se interpreta como otro borde interno.
    final candidate = axis == null
        ? candidates.first
        : candidates.firstWhere((candidate) => candidate.$2.axis == axis);
    return candidate.$1 <= .22 && candidate.$2.isInternal(dimensions)
        ? candidate.$2
        : null;
  }
}

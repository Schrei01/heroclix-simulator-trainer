import 'dart:math' as math;

import 'board_dimensions.dart';
import 'cell_coordinate.dart';

final class BoardPoint {
  const BoardPoint(this.x, this.y);

  final double x;
  final double y;
}

final class ViewportSize {
  factory ViewportSize(double width, double height) {
    if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
      throw ArgumentError('El viewport debe tener tamaño positivo y finito.');
    }
    return ViewportSize._(width, height);
  }

  const ViewportSize._(this.width, this.height);

  final double width;
  final double height;

  BoardPoint get center => BoardPoint(width / 2, height / 2);

  @override
  bool operator ==(Object other) =>
      other is ViewportSize && width == other.width && height == other.height;

  @override
  int get hashCode => Object.hash(width, height);
}

/// Unidades de escena para dibujar: nunca son las coordenadas de una casilla.
final class BoardGeometry {
  const BoardGeometry();

  static const cellExtent = 64.0;
  static const gutter = 32.0;

  double width(BoardDimensions dimensions) =>
      dimensions.columns * cellExtent + 2 * gutter;

  double height(BoardDimensions dimensions) =>
      dimensions.rows * cellExtent + 2 * gutter;

  BoardPoint cellCenter(CellCoordinate cell, BoardDimensions dimensions) {
    if (!dimensions.contains(cell)) {
      throw RangeError('Casilla fuera del tablero');
    }
    return BoardPoint(
      gutter + (cell.column + 0.5) * cellExtent,
      gutter + (cell.row + 0.5) * cellExtent,
    );
  }

  CellCoordinate? cellAt(BoardPoint scenePoint, BoardDimensions dimensions) {
    if (!scenePoint.x.isFinite || !scenePoint.y.isFinite) return null;
    double snap(double value) {
      final nearest = value.roundToDouble();
      return (value - nearest).abs() < 1e-9 ? nearest : value;
    }

    final column = snap((scenePoint.x - gutter) / cellExtent);
    final row = snap((scenePoint.y - gutter) / cellExtent);
    // Bordes compartidos: gana la casilla de la derecha/abajo.
    // El borde exterior derecho/inferior queda fuera del área seleccionable.
    if (column < 0 ||
        row < 0 ||
        column >= dimensions.columns ||
        row >= dimensions.rows) {
      return null;
    }
    return CellCoordinate(column: column.floor(), row: row.floor());
  }
}

final class BoardCamera {
  factory BoardCamera({
    required double scale,
    required double offsetX,
    required double offsetY,
  }) {
    if (!scale.isFinite ||
        scale <= 0 ||
        !offsetX.isFinite ||
        !offsetY.isFinite) {
      throw ArgumentError(
        'La cámara requiere valores finitos y escala positiva.',
      );
    }
    return BoardCamera._(scale, offsetX, offsetY);
  }

  const BoardCamera._(this.scale, this.offsetX, this.offsetY);

  static const identity = BoardCamera._(1, 0, 0);
  static const minimumScale = 0.02;
  static const maximumScale = 6.0;

  final double scale;
  final double offsetX;
  final double offsetY;

  BoardPoint sceneToViewport(BoardPoint point) =>
      BoardPoint(point.x * scale + offsetX, point.y * scale + offsetY);

  BoardPoint viewportToScene(BoardPoint point) =>
      BoardPoint((point.x - offsetX) / scale, (point.y - offsetY) / scale);

  static BoardCamera fit(BoardDimensions dimensions, ViewportSize viewport) {
    const geometry = BoardGeometry();
    final scale = math
        .min(
          math.max(1, viewport.width - 24) / geometry.width(dimensions),
          math.max(1, viewport.height - 24) / geometry.height(dimensions),
        )
        .clamp(minimumScale, maximumScale)
        .toDouble();
    return BoardCamera(
      scale: scale,
      offsetX: (viewport.width - geometry.width(dimensions) * scale) / 2,
      offsetY: (viewport.height - geometry.height(dimensions) * scale) / 2,
    );
  }

  BoardCamera centered(BoardDimensions dimensions, ViewportSize viewport) {
    const geometry = BoardGeometry();
    return BoardCamera(
      scale: scale,
      offsetX: (viewport.width - geometry.width(dimensions) * scale) / 2,
      offsetY: (viewport.height - geometry.height(dimensions) * scale) / 2,
    );
  }

  BoardCamera zoomed(double factor, BoardPoint anchor) {
    if (!factor.isFinite || factor <= 0) throw ArgumentError.value(factor);
    final sceneAnchor = viewportToScene(anchor);
    final nextScale = (scale * factor)
        .clamp(minimumScale, maximumScale)
        .toDouble();
    return BoardCamera(
      scale: nextScale,
      offsetX: anchor.x - sceneAnchor.x * nextScale,
      offsetY: anchor.y - sceneAnchor.y * nextScale,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BoardCamera &&
      scale == other.scale &&
      offsetX == other.offsetX &&
      offsetY == other.offsetY;

  @override
  int get hashCode => Object.hash(scale, offsetX, offsetY);
}

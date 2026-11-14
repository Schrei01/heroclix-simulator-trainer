import '../../domain/board/board_dimensions.dart';
import '../../domain/board/board_viewport.dart';
import '../../domain/board/cell_coordinate.dart';

/// Única fuente de verdad de la sesión de edición, independiente de Flutter.
/// No existen todavía terreno, bordes, ocupantes ni reglas del juego.
final class BoardSession {
  const BoardSession._({
    required this.dimensions,
    required this.camera,
    this.selectedCell,
    this.viewport,
    this.showGrid = true,
    this.showCoordinates = true,
  });

  factory BoardSession.initial() => const BoardSession._(
    dimensions: BoardDimensions.initial,
    camera: BoardCamera.identity,
  );

  final BoardDimensions dimensions;
  final BoardCamera camera;
  final CellCoordinate? selectedCell;
  final ViewportSize? viewport;
  final bool showGrid;
  final bool showCoordinates;

  BoardSession _copy({
    BoardDimensions? dimensions,
    BoardCamera? camera,
    CellCoordinate? selectedCell,
    ViewportSize? viewport,
    bool clearSelection = false,
    bool? showGrid,
    bool? showCoordinates,
  }) => BoardSession._(
    dimensions: dimensions ?? this.dimensions,
    camera: camera ?? this.camera,
    selectedCell: clearSelection ? null : selectedCell ?? this.selectedCell,
    viewport: viewport ?? this.viewport,
    showGrid: showGrid ?? this.showGrid,
    showCoordinates: showCoordinates ?? this.showCoordinates,
  );

  BoardSession resizeViewport(ViewportSize next) {
    if (next == viewport) return this;
    final previous = viewport;
    if (previous == null) {
      return _copy(viewport: next, camera: BoardCamera.fit(dimensions, next));
    }
    // Al girar o redimensionar se conserva el punto lógico central y el zoom.
    final center = camera.viewportToScene(previous.center);
    return _copy(
      viewport: next,
      camera: BoardCamera(
        scale: camera.scale,
        offsetX: next.width / 2 - center.x * camera.scale,
        offsetY: next.height / 2 - center.y * camera.scale,
      ),
    );
  }

  BoardSession withCamera(BoardCamera next) =>
      next == camera ? this : _copy(camera: next);

  BoardSession toggleCell(CellCoordinate? cell) {
    if (cell != null && !dimensions.contains(cell)) {
      throw RangeError('Casilla fuera del tablero');
    }
    if (cell == null || cell == selectedCell) return clearSelection();
    return _copy(selectedCell: cell);
  }

  BoardSession tapViewport(BoardPoint point) => toggleCell(
    const BoardGeometry().cellAt(camera.viewportToScene(point), dimensions),
  );

  BoardSession clearSelection() =>
      selectedCell == null ? this : _copy(clearSelection: true);

  BoardSession changeDimensions(BoardDimensions next) {
    if (next == dimensions) return this;
    return _copy(
      dimensions: next,
      clearSelection: true,
      camera: viewport == null
          ? BoardCamera.identity
          : BoardCamera.fit(next, viewport!),
    );
  }

  BoardSession toggleGrid() => _copy(showGrid: !showGrid);
  BoardSession toggleCoordinates() => _copy(showCoordinates: !showCoordinates);

  BoardSession zoom(double factor) => viewport == null
      ? this
      : withCamera(camera.zoomed(factor, viewport!.center));

  BoardSession centerCamera() => viewport == null
      ? this
      : withCamera(camera.centered(dimensions, viewport!));

  BoardSession resetCamera() => viewport == null
      ? this
      : withCamera(BoardCamera.fit(dimensions, viewport!));
}

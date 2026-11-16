import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/application/board/board_session.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_dimensions.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_viewport.dart';
import 'package:heroclix_simulator_trainer/domain/board/cell_coordinate.dart';

void main() {
  test(
    'seleccionar, deseleccionar y tocar fuera no mutan el snapshot anterior',
    () {
      final initial = BoardSession.initial().resizeViewport(
        ViewportSize(400, 500),
      );
      final cell = CellCoordinate.parse('D4');
      final point = initial.camera.sceneToViewport(
        const BoardGeometry().cellCenter(cell, initial.dimensions),
      );
      final selected = initial.tapViewport(point);
      expect(initial.selectedCell, isNull);
      expect(selected.selectedCell, cell);
      expect(selected.tapViewport(point).selectedCell, isNull);
      expect(
        selected.tapViewport(const BoardPoint(-1000, -1000)).selectedCell,
        isNull,
      );
      expect(
        () => initial.toggleCell(CellCoordinate.parse('E1')),
        throwsRangeError,
      );
    },
  );

  test('zoom, pan, giro y capas visibles conservan la selección lógica', () {
    var state = BoardSession.initial().resizeViewport(ViewportSize(360, 600));
    final cell = CellCoordinate.parse('C2');
    state = state.toggleCell(cell).zoom(2);
    state = state.withCamera(
      BoardCamera(
        scale: state.camera.scale,
        offsetX: state.camera.offsetX - 91,
        offsetY: state.camera.offsetY + 74,
      ),
    );
    final oldCenter = state.camera.viewportToScene(state.viewport!.center);
    final oldScale = state.camera.scale;
    state = state.resizeViewport(ViewportSize(800, 250));
    final newCenter = state.camera.viewportToScene(state.viewport!.center);
    expect(newCenter.x, closeTo(oldCenter.x, 1e-9));
    expect(newCenter.y, closeTo(oldCenter.y, 1e-9));
    expect(state.camera.scale, oldScale);
    state = state.toggleGrid().toggleCoordinates();
    expect(state.showGrid, isFalse);
    expect(state.showCoordinates, isFalse);
    expect(state.selectedCell, cell);
    expect(state.centerCamera().selectedCell, cell);
    expect(state.resetCamera().selectedCell, cell);
  });

  test(
    'cambiar dimensiones vacía selección y ajusta cámara, sin perder opciones',
    () {
      final original = BoardSession.initial()
          .resizeViewport(ViewportSize(400, 600))
          .toggleCell(CellCoordinate.parse('B2'))
          .toggleCoordinates();
      expect(
        original.changeDimensions(BoardDimensions.initial),
        same(original),
      );
      final next = original.changeDimensions(
        BoardDimensions(rows: 8, columns: 12),
      );
      expect(next.dimensions.cellCount, 96);
      expect(next.selectedCell, isNull);
      expect(next.showCoordinates, isFalse);
      expect(next.camera, BoardCamera.fit(next.dimensions, next.viewport!));
      expect(original.selectedCell, CellCoordinate.parse('B2'));
    },
  );
}

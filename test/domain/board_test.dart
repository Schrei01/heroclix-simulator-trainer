import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_dimensions.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_viewport.dart';
import 'package:heroclix_simulator_trainer/domain/board/cell_coordinate.dart';

void main() {
  group('dimensiones y coordenadas lógicas', () {
    test(
      'tamaños cuadrados y rectangulares tienen el número correcto de celdas',
      () {
        for (final (rows, columns, total) in [
          (4, 4, 16),
          (8, 12, 96),
          (16, 24, 384),
          (40, 40, 1600),
          (2, 2, 4),
        ]) {
          expect(
            BoardDimensions(rows: rows, columns: columns).cellCount,
            total,
          );
        }
      },
    );

    test('cada eje valida independientemente sus límites', () {
      for (final bad in [-1, 0, 1, 41, 100]) {
        expect(() => BoardDimensions(rows: bad, columns: 4), throwsRangeError);
        expect(() => BoardDimensions(rows: 4, columns: bad), throwsRangeError);
      }
      expect(() => CellCoordinate(column: -1, row: 0), throwsRangeError);
      expect(() => CellCoordinate(column: 0, row: -1), throwsRangeError);
    });

    test('A1, D4, Z1 y AA1 tienen conversión bidireccional', () {
      for (final (label, column, row) in [
        ('A1', 0, 0),
        ('D4', 3, 3),
        ('Z1', 25, 0),
        ('AA1', 26, 0),
        ('AN40', 39, 39),
      ]) {
        final cell = CellCoordinate(column: column, row: row);
        expect(cell.label, label);
        expect(CellCoordinate.parse(label), cell);
      }
      expect(CellCoordinate.parse(' aa1 '), CellCoordinate(column: 26, row: 0));
      for (final label in ['', '1A', 'A0', 'A-1', 'AA', 'A1.5', 'A01']) {
        expect(() => CellCoordinate.parse(label), throwsFormatException);
      }
    });

    test(
      'el tablero valida una coordenada sin confundirla con su etiqueta',
      () {
        expect(
          BoardDimensions.initial.contains(CellCoordinate.parse('J10')),
          isTrue,
        );
        expect(
          BoardDimensions.initial.contains(CellCoordinate.parse('K10')),
          isFalse,
        );
        expect(
          BoardDimensions.initial.contains(CellCoordinate.parse('A11')),
          isFalse,
        );
      },
    );
  });

  group('escena, cámara y selección exacta', () {
    const geometry = BoardGeometry();
    final large = BoardDimensions(rows: 40, columns: 40);

    test('las 1600 casillas hacen ida/vuelta con zoom y pan distintos', () {
      for (final camera in [
        BoardCamera.identity,
        BoardCamera(scale: 0.13, offsetX: -52.7, offsetY: 81.2),
        BoardCamera(scale: 3.75, offsetX: -1960, offsetY: -805),
      ]) {
        for (var row = 0; row < 40; row++) {
          for (var column = 0; column < 40; column++) {
            final cell = CellCoordinate(column: column, row: row);
            final scene = geometry.cellCenter(cell, large);
            final screen = camera.sceneToViewport(scene);
            final restored = camera.viewportToScene(screen);
            expect(restored.x, closeTo(scene.x, 1e-8));
            expect(restored.y, closeTo(scene.y, 1e-8));
            expect(geometry.cellAt(restored, large), cell);
          }
        }
      }
    });

    test(
      'un borde compartido elige derecha/abajo y el exterior se excluye',
      () {
        final dimensions = BoardDimensions(rows: 4, columns: 4);
        expect(
          geometry.cellAt(const BoardPoint(32, 32), dimensions),
          CellCoordinate.parse('A1'),
        );
        expect(
          geometry.cellAt(const BoardPoint(96, 64), dimensions),
          CellCoordinate.parse('B1'),
        );
        expect(
          geometry.cellAt(const BoardPoint(96, 96), dimensions),
          CellCoordinate.parse('B2'),
        );
        expect(geometry.cellAt(const BoardPoint(288, 64), dimensions), isNull);
        expect(geometry.cellAt(const BoardPoint(64, 288), dimensions), isNull);
        expect(
          geometry.cellAt(const BoardPoint(31.99, 64), dimensions),
          isNull,
        );
        expect(
          geometry.cellAt(const BoardPoint(double.nan, 64), dimensions),
          isNull,
        );
        final camera = BoardCamera(scale: 0.3, offsetX: 7.8, offsetY: -61.2);
        final boundary = camera.sceneToViewport(const BoardPoint(96, 96));
        expect(
          geometry.cellAt(camera.viewportToScene(boundary), dimensions),
          CellCoordinate.parse('B2'),
        );
      },
    );

    test('zoom anclado y centrar no cambian las coordenadas de la escena', () {
      final viewport = ViewportSize(800, 350);
      final fitted = BoardCamera.fit(large, viewport);
      final before = fitted.viewportToScene(viewport.center);
      final zoomed = fitted.zoomed(2, viewport.center);
      final after = zoomed.viewportToScene(viewport.center);
      expect(after.x, closeTo(before.x, 1e-9));
      expect(after.y, closeTo(before.y, 1e-9));
      expect(zoomed.scale, closeTo(fitted.scale * 2, 1e-9));
      expect(zoomed.centered(large, viewport).scale, zoomed.scale);
      expect(
        zoomed.zoomed(100000, viewport.center).scale,
        BoardCamera.maximumScale,
      );
      expect(
        zoomed.zoomed(0.000001, viewport.center).scale,
        BoardCamera.minimumScale,
      );
    });

    test('ajustar conserva celdas cuadradas y encaja el mapa completo', () {
      final viewport = ViewportSize(360, 500);
      final camera = BoardCamera.fit(large, viewport);
      expect(
        geometry.width(large) * camera.scale,
        lessThanOrEqualTo(viewport.width),
      );
      expect(
        geometry.height(large) * camera.scale,
        lessThanOrEqualTo(viewport.height),
      );
      final a = camera.sceneToViewport(
        geometry.cellCenter(CellCoordinate.parse('A1'), large),
      );
      final b = camera.sceneToViewport(
        geometry.cellCenter(CellCoordinate.parse('B1'), large),
      );
      final c = camera.sceneToViewport(
        geometry.cellCenter(CellCoordinate.parse('A2'), large),
      );
      expect(b.x - a.x, closeTo(c.y - a.y, 1e-9));
    });

    test('cámaras y viewports inválidos fallan de forma explícita', () {
      expect(() => ViewportSize(0, 100), throwsArgumentError);
      expect(() => ViewportSize(100, double.infinity), throwsArgumentError);
      expect(
        () => BoardCamera(scale: 0, offsetX: 0, offsetY: 0),
        throwsArgumentError,
      );
      expect(
        () => BoardCamera(scale: 1, offsetX: double.nan, offsetY: 0),
        throwsArgumentError,
      );
      expect(
        () => geometry.cellCenter(
          CellCoordinate.parse('K1'),
          BoardDimensions.initial,
        ),
        throwsRangeError,
      );
    });
  });
}

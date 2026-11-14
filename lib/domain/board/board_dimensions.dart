import 'cell_coordinate.dart';

/// Tamaño lógico; no contiene información de pantalla ni reglas del juego.
final class BoardDimensions {
  factory BoardDimensions({required int rows, required int columns}) {
    RangeError.checkValueInInterval(rows, minimum, maximum, 'rows');
    RangeError.checkValueInInterval(columns, minimum, maximum, 'columns');
    return BoardDimensions._(rows, columns);
  }

  const BoardDimensions._(this.rows, this.columns);

  static const minimum = 2;
  static const maximum = 40;
  static const initial = BoardDimensions._(4, 4);

  final int rows;
  final int columns;

  int get cellCount => rows * columns;

  bool contains(CellCoordinate cell) =>
      cell.column < columns && cell.row < rows;

  @override
  bool operator ==(Object other) =>
      other is BoardDimensions &&
      rows == other.rows &&
      columns == other.columns;

  @override
  int get hashCode => Object.hash(rows, columns);
}

/// Índices desde cero; la representación pública usa A1, Z1, AA1, etc.
final class CellCoordinate {
  factory CellCoordinate({required int column, required int row}) {
    if (column < 0) throw RangeError.value(column, 'column');
    if (row < 0) throw RangeError.value(row, 'row');
    return CellCoordinate._(column, row);
  }

  const CellCoordinate._(this.column, this.row);

  factory CellCoordinate.parse(String label) {
    final match = RegExp(r'^([A-Z]+)([1-9][0-9]*)$')
        .firstMatch(label.trim().toUpperCase());
    if (match == null) throw FormatException('Coordenada inválida', label);
    final letters = match.group(1)!;
    var column = 0;
    for (final code in letters.codeUnits) {
      column = column * 26 + code - 64;
      if (column > 0x7fffffff) {
        throw FormatException('Columna fuera de límites', label);
      }
    }
    final row = int.tryParse(match.group(2)!);
    if (row == null || row <= 0) {
      throw FormatException('Fila fuera de límites', label);
    }
    return CellCoordinate(column: column - 1, row: row - 1);
  }

  final int column;
  final int row;

  static String columnLabel(int column) {
    if (column < 0) throw RangeError.value(column, 'column');
    var remaining = column + 1;
    var result = '';
    while (remaining > 0) {
      remaining--;
      result = String.fromCharCode(65 + remaining % 26) + result;
      remaining ~/= 26;
    }
    return result;
  }

  String get label => '${columnLabel(column)}${row + 1}';

  @override
  bool operator ==(Object other) =>
      other is CellCoordinate && column == other.column && row == other.row;

  @override
  int get hashCode => Object.hash(column, row);

  @override
  String toString() => label;
}

import '../board/board_dimensions.dart';
import '../board/cell_coordinate.dart';

final class Footprint {
  factory Footprint.rectangle({required int width, required int height}) {
    RangeError.checkValueInInterval(width, 1, BoardDimensions.maximum, 'width');
    RangeError.checkValueInInterval(
      height,
      1,
      BoardDimensions.maximum,
      'height',
    );
    return Footprint._(width, height);
  }
  const Footprint._(this.width, this.height);
  static const single = Footprint._(1, 1);
  static const square2 = Footprint._(2, 2);
  final int width;
  final int height;
  String get label => '$width × $height';
  Iterable<CellCoordinate> cellsAt(CellCoordinate position) sync* {
    for (var row = 0; row < height; row++) {
      for (var column = 0; column < width; column++) {
        yield CellCoordinate(
          column: position.column + column,
          row: position.row + row,
        );
      }
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Footprint && width == other.width && height == other.height;
  @override
  int get hashCode => Object.hash(width, height);
}

/// Datos editables; velocidad y alcance son anotaciones, no permisos de acción.
final class CharacterDraft {
  factory CharacterDraft({
    required String name,
    required String teamId,
    required CellCoordinate position,
    Footprint footprint = Footprint.single,
    int speed = 6,
    int range = 4,
  }) {
    final cleaned = name.trim();
    if (cleaned.isEmpty || cleaned.length > 80) {
      throw ArgumentError('El nombre debe tener de 1 a 80 caracteres.');
    }
    if (teamId.isEmpty) throw ArgumentError('Selecciona un equipo.');
    RangeError.checkValueInInterval(speed, 0, 99, 'speed');
    RangeError.checkValueInInterval(range, 0, 99, 'range');
    return CharacterDraft._(cleaned, teamId, position, footprint, speed, range);
  }
  const CharacterDraft._(
    this.name,
    this.teamId,
    this.position,
    this.footprint,
    this.speed,
    this.range,
  );
  final String name;
  final String teamId;
  final CellCoordinate position;
  final Footprint footprint;
  final int speed;
  final int range;
  CharacterDraft at(CellCoordinate position) => CharacterDraft(
    name: name,
    teamId: teamId,
    position: position,
    footprint: footprint,
    speed: speed,
    range: range,
  );
}

final class Character {
  Character({required this.id, required this.label, required this.data}) {
    if (id.isEmpty || label.isEmpty) {
      throw ArgumentError('Figura sin identidad.');
    }
  }
  final String id;
  final String label;
  final CharacterDraft data;
  String get name => data.name;
  String get teamId => data.teamId;
  CellCoordinate get position => data.position;
  Footprint get footprint => data.footprint;
  int get speed => data.speed;
  int get range => data.range;
  Iterable<CellCoordinate> get occupiedCells => footprint.cellsAt(position);
  Character revised(CharacterDraft data) =>
      Character(id: id, label: label, data: data);
}

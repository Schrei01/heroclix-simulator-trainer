import '../board/board_dimensions.dart';
import '../board/cell_coordinate.dart';
import 'character.dart';

final class PlacementValidation {
  const PlacementValidation.valid() : isValid = true, reason = '';
  const PlacementValidation.invalid(this.reason) : isValid = false;
  final bool isValid;
  final String reason;
}

final class PlacementException implements Exception {
  const PlacementException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Colección local inmutable, con un índice de ocupación derivado una sola vez.
final class CharacterRepository {
  const CharacterRepository.empty() : _byId = const {}, _occupants = const {};
  CharacterRepository._(Map<String, Character> values)
    : _byId = Map.unmodifiable(values),
      _occupants = Map.unmodifiable({
        for (final figure in values.values)
          for (final cell in figure.occupiedCells) cell: figure.id,
      });

  final Map<String, Character> _byId;
  final Map<CellCoordinate, String> _occupants;
  Iterable<Character> get all => _byId.values;
  int get length => _byId.length;
  bool get isEmpty => _byId.isEmpty;
  Character? byId(String id) => _byId[id];
  Character? at(CellCoordinate cell) => _byId[_occupants[cell]];

  /// Única implementación de límites y colisiones para alta, edición y arrastre.
  PlacementValidation validatePlacement({
    required BoardDimensions dimensions,
    required CellCoordinate? position,
    required Footprint footprint,
    String? excludingId,
  }) {
    if (position == null) {
      return const PlacementValidation.invalid(
        'El destino está fuera del tablero.',
      );
    }
    for (final cell in footprint.cellsAt(position)) {
      if (!dimensions.contains(cell)) {
        return const PlacementValidation.invalid(
          'La base completa debe caber dentro del tablero.',
        );
      }
      final occupant = _occupants[cell];
      if (occupant != null && occupant != excludingId) {
        return PlacementValidation.invalid(
          '${cell.label} está ocupada por la ficha ${_byId[occupant]!.label}.',
        );
      }
    }
    return const PlacementValidation.valid();
  }

  void _validate(
    Character figure,
    BoardDimensions dimensions, {
    String? excludingId,
  }) {
    final result = validatePlacement(
      dimensions: dimensions,
      position: figure.position,
      footprint: figure.footprint,
      excludingId: excludingId,
    );
    if (!result.isValid) throw PlacementException(result.reason);
  }

  CharacterRepository add(Character figure, BoardDimensions dimensions) {
    if (_byId.containsKey(figure.id) ||
        all.any((item) => item.label == figure.label)) {
      throw const PlacementException(
        'La identidad o etiqueta de la figura ya existe.',
      );
    }
    _validate(figure, dimensions);
    return CharacterRepository._({..._byId, figure.id: figure});
  }

  CharacterRepository update(Character figure, BoardDimensions dimensions) {
    final previous = _byId[figure.id];
    if (previous == null) {
      throw const PlacementException('La figura ya no existe.');
    }
    if (previous.label != figure.label) {
      throw const PlacementException('La etiqueta de la ficha es estable.');
    }
    _validate(figure, dimensions, excludingId: figure.id);
    return CharacterRepository._({..._byId, figure.id: figure});
  }

  CharacterRepository move(
    String id,
    CellCoordinate position,
    BoardDimensions dimensions,
  ) {
    final previous = _byId[id];
    if (previous == null) {
      throw const PlacementException('La figura ya no existe.');
    }
    return update(previous.revised(previous.data.at(position)), dimensions);
  }

  CharacterRepository remove(String id) {
    if (!_byId.containsKey(id)) return this;
    return CharacterRepository._({..._byId}..remove(id));
  }
}

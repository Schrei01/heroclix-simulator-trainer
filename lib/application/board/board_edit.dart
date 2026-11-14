import 'board_session.dart';
import '../../domain/board/board_dimensions.dart';
import '../../domain/characters/character_repository.dart';
import '../../domain/terrain/terrain.dart';
import '../../domain/terrain/edge_wall.dart';

/// Un comando por operación terminada. No hay historial ni botones undo en 03.
final class BoardEdit {
  BoardEdit.between(BoardSession before, BoardSession after)
    : dimensions = before.dimensions,
      _beforeTerrain = before.terrain,
      _afterTerrain = after.terrain,
      _beforeWalls = before.walls,
      _afterWalls = after.walls,
      _beforeCharacters = before.characters,
      _afterCharacters = after.characters,
      _afterNextCharacter = after.nextCharacter;
  final BoardDimensions dimensions;
  final TerrainLayer _beforeTerrain, _afterTerrain;
  final WallLayer _beforeWalls, _afterWalls;
  final CharacterRepository _beforeCharacters, _afterCharacters;
  final int _afterNextCharacter;
  bool get changesLayers =>
      _beforeTerrain != _afterTerrain ||
      _beforeWalls != _afterWalls ||
      _beforeCharacters != _afterCharacters;
  BoardSession reverse(BoardSession current) {
    if (current.dimensions != dimensions ||
        current.terrain != _afterTerrain ||
        current.walls != _afterWalls ||
        current.characters != _afterCharacters) {
      throw StateError('El comando no corresponde al estado actual.');
    }
    return current.replaceLayers(
      terrain: _beforeTerrain,
      walls: _beforeWalls,
      characters: _beforeCharacters,
    );
  }

  BoardSession apply(BoardSession current) {
    if (current.dimensions != dimensions ||
        current.terrain != _beforeTerrain ||
        current.walls != _beforeWalls ||
        current.characters != _beforeCharacters) {
      throw StateError('El comando no corresponde al estado actual.');
    }
    return current.replaceLayers(
      terrain: _afterTerrain,
      walls: _afterWalls,
      characters: _afterCharacters,
      minimumNextCharacter: _afterNextCharacter,
    );
  }
}

import '../../domain/board/board_dimensions.dart';
import '../../domain/board/board_viewport.dart';
import '../../domain/board/cell_coordinate.dart';
import '../../domain/characters/character.dart';
import '../../domain/characters/character_repository.dart';
import '../../domain/characters/team.dart';

enum EditorTool { select, characters }

/// Única fuente de verdad de la sesión de edición, independiente de Flutter.
/// Figuras y cámara locales; no evalúa reglas del juego.
final class BoardSession {
  const BoardSession._({
    required this.dimensions,
    required this.camera,
    this.selectedCell,
    this.viewport,
    this.showGrid = true,
    this.showCoordinates = true,
    this.characters = const CharacterRepository.empty(),
    this.teams = const [Team.blue, Team.red],
    this.selectedCharacterId,
    this.tool = EditorTool.select,
    this.nextCharacter = 1,
    this.nextTeam = 3,
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
  final CharacterRepository characters;
  final List<Team> teams;
  final String? selectedCharacterId;
  final EditorTool tool;
  final int nextCharacter;
  final int nextTeam;
  Character? get selectedCharacter => selectedCharacterId == null
      ? null
      : characters.byId(selectedCharacterId!);
  Team teamById(String id) => teams.firstWhere((team) => team.id == id);

  BoardSession _copy({
    BoardDimensions? dimensions,
    BoardCamera? camera,
    CellCoordinate? selectedCell,
    ViewportSize? viewport,
    bool clearSelection = false,
    bool? showGrid,
    bool? showCoordinates,
    CharacterRepository? characters,
    List<Team>? teams,
    String? selectedCharacterId,
    bool clearCharacter = false,
    EditorTool? tool,
    int? nextCharacter,
    int? nextTeam,
  }) => BoardSession._(
    dimensions: dimensions ?? this.dimensions,
    camera: camera ?? this.camera,
    selectedCell: clearSelection ? null : selectedCell ?? this.selectedCell,
    viewport: viewport ?? this.viewport,
    showGrid: showGrid ?? this.showGrid,
    showCoordinates: showCoordinates ?? this.showCoordinates,
    characters: characters ?? this.characters,
    teams: teams ?? this.teams,
    selectedCharacterId: clearSelection || clearCharacter
        ? null
        : selectedCharacterId ?? this.selectedCharacterId,
    tool: tool ?? this.tool,
    nextCharacter: nextCharacter ?? this.nextCharacter,
    nextTeam: nextTeam ?? this.nextTeam,
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
    if (cell == null) return clearSelection();
    final figure = characters.at(cell);
    if (figure != null) return selectCharacter(figure.id);
    if (cell == selectedCell) return clearSelection();
    return _copy(selectedCell: cell, clearCharacter: true);
  }

  BoardSession tapViewport(BoardPoint point) => toggleCell(
    const BoardGeometry().cellAt(camera.viewportToScene(point), dimensions),
  );

  BoardSession clearSelection() =>
      selectedCell == null && selectedCharacterId == null
      ? this
      : _copy(clearSelection: true);

  BoardSession selectCharacter(String id) {
    final figure = characters.byId(id);
    if (figure == null) {
      throw const PlacementException('La figura ya no existe.');
    }
    return _copy(selectedCharacterId: id, selectedCell: figure.position);
  }

  BoardSession setTool(EditorTool next) => _copy(tool: next);
  void _validateTeam(String id) {
    if (!teams.any((team) => team.id == id)) {
      throw const PlacementException('El equipo no existe.');
    }
  }

  BoardSession createCharacter(CharacterDraft data) {
    _validateTeam(data.teamId);
    final figure = Character(
      id: 'figure-$nextCharacter',
      label: CellCoordinate.columnLabel(nextCharacter - 1),
      data: data,
    );
    return _copy(
      characters: characters.add(figure, dimensions),
      selectedCharacterId: figure.id,
      selectedCell: figure.position,
      nextCharacter: nextCharacter + 1,
    );
  }

  BoardSession editCharacter(String id, CharacterDraft data) {
    _validateTeam(data.teamId);
    final original = characters.byId(id);
    if (original == null) {
      throw const PlacementException('La figura ya no existe.');
    }
    return _copy(
      characters: characters.update(original.revised(data), dimensions),
      selectedCharacterId: id,
      selectedCell: data.position,
    );
  }

  BoardSession duplicateCharacter(String id, CellCoordinate position) {
    final original = characters.byId(id);
    if (original == null) {
      throw const PlacementException('La figura ya no existe.');
    }
    return createCharacter(original.data.at(position));
  }

  BoardSession moveCharacter(String id, CellCoordinate position) => _copy(
    characters: characters.move(id, position, dimensions),
    selectedCharacterId: id,
    selectedCell: position,
  );
  BoardSession deleteCharacter(String id) => _copy(
    characters: characters.remove(id),
    clearSelection: selectedCharacterId == id,
  );
  BoardSession addTeam({
    required String name,
    required int color,
    required TeamPattern pattern,
  }) {
    if (teams.any(
      (team) => team.name.toLowerCase() == name.trim().toLowerCase(),
    )) {
      throw const PlacementException('Ya existe un equipo con ese nombre.');
    }
    final team = Team(
      id: 'team-$nextTeam',
      code: 'T$nextTeam',
      name: name,
      color: color,
      pattern: pattern,
    );
    return _copy(
      teams: List.unmodifiable([...teams, team]),
      nextTeam: nextTeam + 1,
    );
  }

  CellCoordinate? firstFreeCell(Footprint footprint) {
    for (var row = 0; row < dimensions.rows; row++) {
      for (var col = 0; col < dimensions.columns; col++) {
        final cell = CellCoordinate(column: col, row: row);
        if (characters
            .validatePlacement(
              dimensions: dimensions,
              position: cell,
              footprint: footprint,
            )
            .isValid) {
          return cell;
        }
      }
    }
    return null;
  }

  BoardSession changeDimensions(BoardDimensions next) {
    if (next == dimensions) return this;
    for (final figure in characters.all) {
      final validation = characters.validatePlacement(
        dimensions: next,
        position: figure.position,
        footprint: figure.footprint,
        excludingId: figure.id,
      );
      if (!validation.isValid) {
        throw PlacementException(
          'No se puede reducir: la ficha ${figure.label} quedaría fuera del tablero.',
        );
      }
    }
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

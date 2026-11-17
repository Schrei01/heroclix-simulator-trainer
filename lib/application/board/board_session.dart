import '../../domain/board/board_dimensions.dart';
import '../../domain/board/board_viewport.dart';
import '../../domain/board/cell_coordinate.dart';
import '../../domain/characters/character.dart';
import '../../domain/characters/character_repository.dart';
import '../../domain/characters/team.dart';
import '../../domain/terrain/terrain.dart';
import '../../domain/terrain/edge_wall.dart';

enum EditorTool {
  select,
  characters,
  terrain,
  walls,
  erase,
  vision,
  distance,
  targets,
  movement,
  positionAnalysis,
}

enum EraseLayer { figures, terrain, elevation, transitions, walls }

enum TerrainBrush {
  blocking,
  hindering,
  elevated,
  transition,
  clear;

  TerrainType? get type => switch (this) {
    blocking => TerrainType.blocking,
    hindering => TerrainType.hindering,
    clear => TerrainType.clear,
    _ => null,
  };
}

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
    this.terrain = const TerrainLayer.empty(),
    this.walls = const WallLayer.empty(),
    this.terrainType = TerrainType.hindering,
    this.terrainBrush = TerrainBrush.hindering,
    this.rectangleBrush = false,
    this.eraseWalls = false,
    this.eraseLayer = EraseLayer.figures,
  });

  factory BoardSession.initial() => const BoardSession._(
    dimensions: BoardDimensions.initial,
    camera: BoardCamera.identity,
  );

  final BoardDimensions dimensions;

  /// Reconstrucción del documento; la cámara y herramientas se reinician.
  static BoardSession restore({
    required BoardDimensions dimensions,
    required List<Team> teams,
    required CharacterRepository characters,
    required TerrainLayer terrain,
    required WallLayer walls,
    required int nextCharacter,
    required int nextTeam,
  }) {
    if (teams.isEmpty ||
        teams.length > 32 ||
        nextCharacter < 1 ||
        nextTeam < 1 ||
        characters.all.any(
          (figure) => !teams.any((team) => team.id == figure.teamId),
        )) {
      throw ArgumentError('Equipos o identidades del escenario inválidos.');
    }
    return BoardSession._(
      dimensions: dimensions,
      camera: BoardCamera.identity,
      teams: List.unmodifiable(teams),
      characters: characters,
      terrain: terrain,
      walls: walls,
      nextCharacter: nextCharacter,
      nextTeam: nextTeam,
    ).replaceLayers(terrain: terrain, walls: walls, characters: characters);
  }

  BoardSession restoreContent(BoardSession source) => _copy(
    dimensions: source.dimensions,
    teams: source.teams,
    characters: source.characters,
    terrain: source.terrain,
    walls: source.walls,
    clearSelection: true,
    nextCharacter: source.nextCharacter > nextCharacter
        ? source.nextCharacter
        : nextCharacter,
    nextTeam: source.nextTeam > nextTeam ? source.nextTeam : nextTeam,
    camera: dimensions == source.dimensions
        ? camera
        : viewport == null
        ? BoardCamera.identity
        : BoardCamera.fit(source.dimensions, viewport!),
  );
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
  final TerrainLayer terrain;
  final WallLayer walls;
  final TerrainType terrainType;
  final TerrainBrush terrainBrush;
  final bool rectangleBrush, eraseWalls;
  final EraseLayer eraseLayer;
  bool get editsLayers =>
      (tool == EditorTool.terrain && terrainBrush.type != null) ||
      tool == EditorTool.walls ||
      tool == EditorTool.erase;
  Set<CellCoordinate> get studyConflicts => {
    for (final entry in terrain.cells.entries)
      if (entry.value.type == TerrainType.blocking &&
          characters.at(entry.key) != null)
        entry.key,
  };
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
    TerrainLayer? terrain,
    WallLayer? walls,
    TerrainType? terrainType,
    TerrainBrush? terrainBrush,
    bool? rectangleBrush,
    bool? eraseWalls,
    EraseLayer? eraseLayer,
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
    terrain: terrain ?? this.terrain,
    walls: walls ?? this.walls,
    terrainType: terrainType ?? this.terrainType,
    terrainBrush: terrainBrush ?? this.terrainBrush,
    rectangleBrush: rectangleBrush ?? this.rectangleBrush,
    eraseWalls: eraseWalls ?? this.eraseWalls,
    eraseLayer: eraseLayer ?? this.eraseLayer,
  );

  BoardSession resizeViewport(ViewportSize next) {
    if (next == viewport) return this;
    final previous = viewport;
    if (previous == null) {
      return _copy(viewport: next, camera: BoardCamera.fit(dimensions, next));
    }
    if (camera == BoardCamera.fit(dimensions, previous)) {
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
    if (nextCharacter >= 1000000000) {
      throw const PlacementException(
        'Se agotó el contador de identidades. Crea un escenario nuevo si necesitas continuar.',
      );
    }
    _validateTeam(data.teamId);
    _checkFigureTerrain(data);
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
    _checkFigureTerrain(data);
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

  BoardSession moveCharacter(String id, CellCoordinate position) {
    final figure = characters.byId(id);
    if (figure == null) {
      throw const PlacementException('La figura ya no existe.');
    }
    _checkFigureTerrain(figure.data.at(position));
    return _copy(
      characters: characters.move(id, position, dimensions),
      selectedCharacterId: id,
      selectedCell: position,
    );
  }

  BoardSession deleteCharacter(String id) => _copy(
    characters: characters.remove(id),
    clearSelection: selectedCharacterId == id,
  );
  BoardSession addTeam({
    required String name,
    required int color,
    required TeamPattern pattern,
  }) {
    if (nextTeam >= 1000000000) {
      throw const PlacementException(
        'Se agotó el contador de equipos de este escenario.',
      );
    }
    if (teams.length >= 32) {
      throw const PlacementException(
        'El escenario admite como máximo 32 equipos.',
      );
    }
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
                .isValid &&
            footprint
                    .cellsAt(cell)
                    .map((c) => terrain.at(c).level)
                    .toSet()
                    .length ==
                1 &&
            !footprint
                .cellsAt(cell)
                .any((cell) => terrain.at(cell).type == TerrainType.blocking)) {
          return cell;
        }
      }
    }
    return null;
  }

  BoardSession changeDimensions(BoardDimensions next) {
    if (next == dimensions) return this;
    if (terrain.cells.keys.any((cell) => !next.contains(cell)) ||
        walls.edges.values.any((edge) => !edge.isInternal(next)) ||
        terrain.transitions.any((edge) => !edge.isInternal(next))) {
      throw const PlacementException(
        'El tamaño dejaría terreno o muros fuera de sus límites. Limpia esos elementos antes de reducir.',
      );
    }
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

  BoardSession configureLayers({
    TerrainType? type,
    TerrainBrush? brush,
    bool? rectangle,
    bool? removeWalls,
    EraseLayer? erase,
  }) => _copy(
    terrainType: brush?.type ?? type,
    terrainBrush:
        brush ??
        (type == null
            ? null
            : TerrainBrush.values.firstWhere((b) => b.type == type)),
    rectangleBrush: rectangle,
    eraseWalls: removeWalls,
    eraseLayer: erase,
  );

  List<CellCoordinate> blockingConflicts(
    Iterable<CellCoordinate> cells,
    TerrainType type,
  ) => type != TerrainType.blocking
      ? const []
      : cells
            .where((cell) => characters.at(cell) != null)
            .toList(growable: false);

  void _checkFigureTerrain(CharacterDraft data) {
    final levels = data.footprint
        .cellsAt(data.position)
        .map((c) => terrain.at(c).level)
        .toSet();
    if (levels.length > 1) {
      throw const PlacementException(
        'Una base normal debe ocupar un único nivel de elevación.',
      );
    }
    if (data.footprint
        .cellsAt(data.position)
        .any((cell) => terrain.at(cell).type == TerrainType.blocking)) {
      throw const PlacementException(
        'La base toca terreno bloqueado. Elige una casilla despejada u obstaculizada.',
      );
    }
  }

  PlacementValidation validateFigurePlacement(
    Character figure,
    CellCoordinate? position,
  ) {
    final result = characters.validatePlacement(
      dimensions: dimensions,
      position: position,
      footprint: figure.footprint,
      excludingId: figure.id,
    );
    if (!result.isValid) return result;
    if (figure.footprint
            .cellsAt(position!)
            .map((c) => terrain.at(c).level)
            .toSet()
            .length >
        1) {
      return const PlacementValidation.invalid(
        'La base debe ocupar un único nivel de elevación.',
      );
    }
    if (figure.footprint
        .cellsAt(position)
        .any((cell) => terrain.at(cell).type == TerrainType.blocking)) {
      return const PlacementValidation.invalid(
        'No se pueden colocar personajes sobre terreno bloqueado.',
      );
    }
    return result;
  }

  BoardSession paintTerrain(Iterable<CellCoordinate> cells, TerrainType type) {
    final targets = cells.toSet();
    if (blockingConflicts(targets, type).isNotEmpty) {
      throw const PlacementException(
        'No se puede pintar bloqueado sobre un personaje. Retira o mueve la figura primero.',
      );
    }
    return _copy(terrain: terrain.paint(targets, type, dimensions));
  }

  BoardSession editWalls(Iterable<EdgeWall> edges, {required bool erase}) {
    if (!erase && edges.any(terrain.transitions.contains)) {
      throw const PlacementException(
        'Retira la transición antes de añadir un muro en ese borde.',
      );
    }
    return _copy(walls: walls.edit(edges, dimensions, erase: erase));
  }

  BoardSession paintElevation(Iterable<CellCoordinate> cells, int level) {
    final next = terrain.paintElevation(cells, level, dimensions);
    for (final f in characters.all) {
      if (f.occupiedCells.map((c) => next.at(c).level).toSet().length > 1) {
        throw const PlacementException(
          'La edición dejaría una base en niveles distintos. Pinta su región completa.',
        );
      }
    }
    return _copy(terrain: next);
  }

  BoardSession setTransition(EdgeWall edge, {required bool remove}) {
    if (!remove && walls.contains(edge)) {
      throw const PlacementException(
        'Un muro no puede compartir una transición.',
      );
    }
    return _copy(
      terrain: terrain.setTransition(edge, dimensions, remove: remove),
    );
  }

  BoardSession clearTerrain() => _copy(
    terrain: terrain.paint(terrain.cells.keys, TerrainType.clear, dimensions),
  );
  BoardSession clearWalls() => _copy(walls: const WallLayer.empty());
  BoardSession clearCharacters() => _copy(
    characters: const CharacterRepository.empty(),
    clearSelection: true,
  );

  /// Puerta para comandos reversibles; no restaura cámara ni recicla identidades.
  BoardSession replaceLayers({
    required TerrainLayer terrain,
    required WallLayer walls,
    required CharacterRepository characters,
    int minimumNextCharacter = 1,
  }) {
    if (minimumNextCharacter < 1) {
      throw RangeError.value(minimumNextCharacter, 'minimumNextCharacter');
    }
    if (terrain.cells.keys.any((cell) => !dimensions.contains(cell)) ||
        walls.edges.values.any((edge) => !edge.isInternal(dimensions)) ||
        characters.all.any(
          (figure) =>
              figure.occupiedCells.any((cell) => !dimensions.contains(cell)),
        ) ||
        terrain.transitions.any(
          (e) =>
              !e.isInternal(dimensions) ||
              walls.contains(e) ||
              terrain.at(e.firstCell).level == terrain.at(e.secondCell).level,
        )) {
      throw const PlacementException(
        'Las capas no caben en el tablero actual.',
      );
    }
    return _copy(
      terrain: terrain,
      walls: walls,
      characters: characters,
      nextCharacter: nextCharacter < minimumNextCharacter
          ? minimumNextCharacter
          : nextCharacter,
      clearSelection:
          selectedCharacterId != null &&
          characters.byId(selectedCharacterId!) == null,
    );
  }
}

import 'board_session.dart';
import '../../domain/board/cell_coordinate.dart';
import '../../domain/terrain/terrain.dart';
import '../../domain/terrain/edge_wall.dart';

/// Borrador transitorio de presentación, nunca una edición parcial del escenario.
final class LayerDraft {
  LayerDraft({
    required this.tool,
    required this.type,
    required this.rectangle,
    required this.eraseWalls,
    required this.eraseLayer,
    this.brush = TerrainBrush.hindering,
    Iterable<CellCoordinate> cells = const [],
    Iterable<EdgeWall> edges = const [],
    this.figureId,
    this.pending = false,
  }) : cells = Set.unmodifiable(cells),
       edges = Set.unmodifiable(edges);
  final EditorTool tool;
  final TerrainType type;
  final TerrainBrush brush;
  final bool rectangle, eraseWalls, pending;
  final EraseLayer eraseLayer;
  final Set<CellCoordinate> cells;
  final Set<EdgeWall> edges;
  final String? figureId;
  LayerDraft update({
    Iterable<CellCoordinate>? cells,
    Iterable<EdgeWall>? edges,
    String? figureId,
    bool pending = false,
  }) => LayerDraft(
    tool: tool,
    type: type,
    rectangle: rectangle,
    eraseWalls: eraseWalls,
    eraseLayer: eraseLayer,
    brush: brush,
    cells: cells ?? this.cells,
    edges: edges ?? this.edges,
    figureId: figureId,
    pending: pending,
  );
}

import '../board/board_dimensions.dart';
import '../board/cell_coordinate.dart';
import '../terrain/edge_wall.dart';
import 'exact_fraction.dart';

/// Unidades de casilla, origen en la esquina superior izquierda, Y hacia abajo.
final class LogicalPoint {
  const LogicalPoint(this.x, this.y);
  factory LogicalPoint.center(CellCoordinate cell) => LogicalPoint(
    ExactFraction(cell.column * 2 + 1, 2),
    ExactFraction(cell.row * 2 + 1, 2),
  );
  final ExactFraction x, y;
  @override
  bool operator ==(Object other) =>
      other is LogicalPoint && x == other.x && y == other.y;
  @override
  int get hashCode => Object.hash(x, y);
  @override
  String toString() => '($x, $y)';
}

/// Candidata explícita. No elige automáticamente referencias de bases múltiples.
final class SightPath {
  const SightPath({
    required this.id,
    required this.origin,
    required this.destination,
  });
  final String id;
  final CellCoordinate origin, destination;
}

sealed class TraceEvent {
  const TraceEvent(this.t, this.point);
  final ExactFraction t;
  final LogicalPoint point;
}

final class TraceStart extends TraceEvent {
  const TraceStart(super.t, super.point);
}

final class TraceEnd extends TraceEvent {
  const TraceEnd(super.t, super.point);
}

/// Intervalo cuyo interior está dentro de una casilla. Nunca incluye celdas
/// tocadas solo por una esquina. En el caso degenerado representa el punto fijo.
final class CellPass extends TraceEvent {
  const CellPass(super.t, super.point, this.until, this.exit, this.cell);
  final ExactFraction until;
  final LogicalPoint exit;
  final CellCoordinate cell;
}

enum ContactKind { edgeInterior, vertexEndpoint }

final class EdgeContact {
  const EdgeContact(this.edge, this.kind, this.hasWall);
  final EdgeWall edge;
  final ContactKind kind;
  final bool hasWall;
}

final class GridCrossing extends TraceEvent {
  GridCrossing(
    super.t,
    super.point,
    Iterable<EdgeContact> contacts,
    Iterable<CellCoordinate> cornerOnly,
  ) : contacts = List.unmodifiable(contacts),
      cornerOnly = List.unmodifiable(cornerOnly);
  final List<EdgeContact> contacts;

  /// Las dos celdas laterales que solo tocan un vértice, sin paso interior.
  final List<CellCoordinate> cornerOnly;
  bool get isVertex => contacts.first.kind == ContactKind.vertexEndpoint;
}

final class GeometricTrace {
  GeometricTrace(this.path, Iterable<TraceEvent> events)
    : events = List.unmodifiable(events);
  final SightPath path;
  final List<TraceEvent> events;
  Iterable<CellPass> get segments => events.whereType<CellPass>();
  Iterable<GridCrossing> get crossings => events.whereType<GridCrossing>();
  bool get isDegenerate => path.origin == path.destination;
}

/// Intersecciones exactas de un segmento centro-a-centro. No interpreta reglas.
final class SightGeometry {
  const SightGeometry();
  List<GeometricTrace> traceCandidates(
    BoardDimensions dimensions,
    Iterable<SightPath> paths, {
    WallLayer walls = const WallLayer.empty(),
  }) {
    final values = paths.toList();
    if (values.length > 16 ||
        values.any((path) => path.id.isEmpty) ||
        values.map((path) => path.id).toSet().length != values.length) {
      throw ArgumentError(
        'Se admiten hasta 16 candidatas con identidades únicas.',
      );
    }
    return List.unmodifiable(
      values.map((path) => trace(dimensions, path, walls: walls)),
    );
  }

  GeometricTrace trace(
    BoardDimensions dimensions,
    SightPath path, {
    WallLayer walls = const WallLayer.empty(),
  }) {
    if (!dimensions.contains(path.origin) ||
        !dimensions.contains(path.destination)) {
      throw ArgumentError('Origen o destino fuera del tablero.');
    }
    if (walls.edges.values.any((edge) => !edge.isInternal(dimensions))) {
      throw ArgumentError('Muro fuera del tablero.');
    }
    final a = LogicalPoint.center(path.origin),
        b = LogicalPoint.center(path.destination);
    final dx = b.x - a.x, dy = b.y - a.y;
    LogicalPoint at(ExactFraction t) =>
        LogicalPoint(a.x + dx * t, a.y + dy * t);
    final cuts = {ExactFraction.zero, ExactFraction.one};
    void cut(int k, ExactFraction start, ExactFraction delta) {
      if (delta == ExactFraction.zero) return;
      final t = (ExactFraction(k) - start) / delta;
      if (t.compareTo(ExactFraction.zero) > 0 &&
          t.compareTo(ExactFraction.one) < 0) {
        cuts.add(t);
      }
    }

    for (var x = 1; x < dimensions.columns; x++) {
      cut(x, a.x, dx);
    }
    for (var y = 1; y < dimensions.rows; y++) {
      cut(y, a.y, dy);
    }
    final sorted = cuts.toList()..sort();
    final events = <TraceEvent>[TraceStart(ExactFraction.zero, a)];
    for (var i = 0; i < sorted.length - 1; i++) {
      final t = sorted[i], until = sorted[i + 1], point = at(t);
      if (i > 0) {
        final vertex = point.x.isInteger && point.y.isInteger;
        final x = point.x.floor, y = point.y.floor;
        final edges = <EdgeWall>[];
        final cornerOnly = <CellCoordinate>[];
        if (vertex) {
          edges.addAll([
            EdgeWall(axis: EdgeAxis.horizontal, column: x - 1, row: y),
            EdgeWall(axis: EdgeAxis.horizontal, column: x, row: y),
            EdgeWall(axis: EdgeAxis.vertical, column: x, row: y - 1),
            EdgeWall(axis: EdgeAxis.vertical, column: x, row: y),
          ]);
          final before = at((sorted[i - 1] + t) / ExactFraction(2));
          final after = at((t + until) / ExactFraction(2));
          for (final col in [x - 1, x]) {
            for (final row in [y - 1, y]) {
              if ((col != before.x.floor || row != before.y.floor) &&
                  (col != after.x.floor || row != after.y.floor)) {
                cornerOnly.add(CellCoordinate(column: col, row: row));
              }
            }
          }
        } else {
          edges.add(
            EdgeWall(
              axis: point.x.isInteger ? EdgeAxis.vertical : EdgeAxis.horizontal,
              column: x,
              row: y,
            ),
          );
        }
        edges.sort((a, b) => a.id.compareTo(b.id));
        events.add(
          GridCrossing(t, point, [
            for (final edge in edges)
              EdgeContact(
                edge,
                vertex ? ContactKind.vertexEndpoint : ContactKind.edgeInterior,
                walls.contains(edge),
              ),
          ], cornerOnly),
        );
      }
      final middle = at((t + until) / ExactFraction(2));
      events.add(
        CellPass(
          t,
          point,
          until,
          at(until),
          CellCoordinate(column: middle.x.floor, row: middle.y.floor),
        ),
      );
    }
    events.add(TraceEnd(ExactFraction.one, b));
    return GeometricTrace(path, events);
  }
}

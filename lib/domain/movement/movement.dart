import '../board/cell_coordinate.dart';
import '../rules/line_of_sight.dart';
import '../terrain/terrain.dart';
import '../terrain/edge_wall.dart';

enum MovementStatus { valid, invalid, notEvaluated }

String movementLabel(MovementStatus status) => switch (status) {
  MovementStatus.valid => 'RUTA VÁLIDA',
  MovementStatus.invalid => 'RUTA INVÁLIDA',
  MovementStatus.notEvaluated => 'NO EVALUADA',
};

final class MovementContext {
  const MovementContext({
    this.rulesVersion = VisionContext.supportedVersion,
    this.specialEffects = false,
  });
  final String rulesVersion;
  final bool specialEffects;
}

final class MovementEvent {
  const MovementEvent(this.step, this.cell, this.rule, this.reason);
  final int step;
  final CellCoordinate cell;
  final String rule, reason;
  String get citation => rule == 'SCOPE' ? rule : '§$rule';
}

final class StepEvaluation {
  const StepEvaluation(
    this.status,
    this.reason,
    this.rule, {
    this.stop = false,
    this.destroyedBlocking = const [],
    this.destroyedWalls = const [],
  });
  final MovementStatus status;
  final String reason, rule;
  final bool stop;
  final List<CellCoordinate> destroyedBlocking;
  final List<EdgeWall> destroyedWalls;
}

final class MovementChanges {
  MovementChanges({
    required this.terrain,
    required this.walls,
    required Iterable<CellCoordinate> blocking,
    required Iterable<EdgeWall> destroyedWalls,
    required Iterable<CellCoordinate> debris,
  }) : blocking = Set.unmodifiable(blocking),
       destroyedWalls = Set.unmodifiable(destroyedWalls),
       debris = Set.unmodifiable(debris);
  final TerrainLayer terrain;
  final WallLayer walls;
  final Set<CellCoordinate> blocking, debris;
  final Set<EdgeWall> destroyedWalls;
}

final class RouteEvaluation {
  RouteEvaluation({
    required this.status,
    required Iterable<CellCoordinate> route,
    required this.budget,
    required this.reason,
    required Iterable<MovementEvent> events,
    this.changes,
    this.mustStop = false,
    this.complete = true,
  }) : route = List.unmodifiable(route),
       events = List.unmodifiable(events);
  final MovementStatus status;
  final List<CellCoordinate> route;
  final int budget;
  final String reason;
  final List<MovementEvent> events;
  final MovementChanges? changes;
  final bool mustStop, complete;
  int get cost => route.isEmpty ? 0 : route.length - 1;
  int get remaining => budget - cost;
  bool get canConfirm => complete && status == MovementStatus.valid && cost > 0;
}

final class RouteSearch {
  RouteSearch(Iterable<RouteEvaluation> routes, this.reason, this.visited)
    : routes = List.unmodifiable(routes);
  final List<RouteEvaluation> routes;
  final String reason;
  final int visited;
}

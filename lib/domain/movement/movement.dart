import '../board/cell_coordinate.dart';
import '../rules/line_of_sight.dart';

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
  });
  final MovementStatus status;
  final String reason, rule;
  final bool stop;
}

final class RouteEvaluation {
  RouteEvaluation({
    required this.status,
    required Iterable<CellCoordinate> route,
    required this.budget,
    required this.reason,
    required Iterable<MovementEvent> events,
  }) : route = List.unmodifiable(route),
       events = List.unmodifiable(events);
  final MovementStatus status;
  final List<CellCoordinate> route;
  final int budget;
  final String reason;
  final List<MovementEvent> events;
  int get cost => route.isEmpty ? 0 : route.length - 1;
  int get remaining => budget - cost;
  bool get canConfirm => status == MovementStatus.valid && cost > 0;
}

final class RouteSearch {
  RouteSearch(Iterable<RouteEvaluation> routes, this.reason, this.visited)
    : routes = List.unmodifiable(routes);
  final List<RouteEvaluation> routes;
  final String reason;
  final int visited;
}

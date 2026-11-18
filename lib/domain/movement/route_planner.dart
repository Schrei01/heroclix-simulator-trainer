import 'dart:collection';

import '../board/cell_coordinate.dart';
import '../characters/movement_ability.dart';
import '../rules/line_of_sight.dart';
import 'movement.dart';
import 'movement_rules_service.dart';

/// BFS con costo unitario, solo expande prefijos verificables. Un prefijo puede
/// atravesar un aliado/B permitido aunque aún no sea un destino legal.
final class RoutePlanner {
  const RoutePlanner({this.rules = const MovementRulesService()});
  final MovementRulesService rules;

  RouteSearch search(
    VisionSnapshot world,
    String id,
    CellCoordinate destination, {
    MovementContext context = const MovementContext(),
  }) {
    final f = rules.figure(world, id);
    if (f == null) return RouteSearch([], 'Elige una figura.', 0);
    final initial = rules.evaluate(world, id, [f.position], context: context);
    if (initial.status != MovementStatus.valid) {
      return RouteSearch([], initial.reason, 0);
    }
    if (f.movementAbilities.contains(MovementAbility.destroyBlocking)) {
      return _destructive(world, id, destination, context, initial);
    }
    final solutions = <RouteEvaluation>[];
    final steps = <(CellCoordinate, CellCoordinate), StepEvaluation>{};
    final enemies = <CellCoordinate, bool>{};
    var total = 0;
    // Una búsqueda por cada primer paso proporciona hasta tres alternativas
    // verificadas con distinto inicio, sin prometer enumerar todos los caminos.
    final firstSteps = _neighbors(f.position, world);
    if (destination == f.position) {
      return RouteSearch([initial], initial.reason, 1);
    }
    for (final first in firstSteps) {
      final queue = Queue<List<CellCoordinate>>()..add([f.position, first]);
      final seen = <CellCoordinate>{f.position};
      while (queue.isNotEmpty) {
        final path = queue.removeFirst(), cell = path.last;
        if (seen.contains(cell) || path.length - 1 > f.speed) continue;
        total++;
        final edge = (path[path.length - 2], cell);
        final step = steps.putIfAbsent(
          edge,
          () => rules.validateTranslation(world, f, edge.$1, edge.$2),
        );
        if (step.status != MovementStatus.valid) continue;
        if (cell == destination && rules.landing(world, f, cell) == null) {
          // Nunca se ofrece una alternativa sin validar también la ruta completa.
          final verified = rules.evaluate(world, id, path, context: context);
          if (verified.status == MovementStatus.valid) {
            solutions.add(verified);
            break;
          }
        }
        final stopped =
            step.stop ||
            (!f.movementAbilities.contains(MovementAbility.characters) &&
                !f.movementAbilities.contains(MovementAbility.moveThrough) &&
                enemies.putIfAbsent(
                  cell,
                  () => rules.besideEnemy(world, f, cell, referenceOnly: true),
                ));
        if (stopped) continue;
        seen.add(cell);
        for (final next in _neighbors(cell, world)) {
          if (!seen.contains(next)) queue.add([...path, next]);
        }
      }
    }
    solutions.sort((a, b) => a.cost.compareTo(b.cost));
    return RouteSearch(
      solutions.take(3),
      solutions.isEmpty
          ? 'No se encontró ruta válida bajo las reglas implementadas y la velocidad declarada.'
          : 'Alternativas verificadas; costo en pasos. No son rutas exhaustivas.',
      total,
    );
  }

  RouteSearch _destructive(
    VisionSnapshot world,
    String id,
    CellCoordinate destination,
    MovementContext context,
    RouteEvaluation initial,
  ) {
    final f = rules.figure(world, id)!;
    if (destination == f.position) {
      return RouteSearch([initial], initial.reason, 1);
    }
    final solutions = <RouteEvaluation>[];
    var visited = 0;
    const limit = 4096;
    String sorted(Iterable<String> values) =>
        (values.toList()..sort()).join(',');
    String key(CellCoordinate cell, RouteEvaluation e) =>
        '${cell.label}|'
        '${sorted(e.changes?.blocking.map((c) => c.label) ?? const [])}|'
        '${sorted(e.changes?.destroyedWalls.map((w) => w.id) ?? const [])}';
    for (final first in _neighbors(f.position, world)) {
      final queue = Queue<List<CellCoordinate>>()..add([f.position, first]);
      final seen = <String>{key(f.position, initial)};
      while (queue.isNotEmpty && visited < limit) {
        final path = queue.removeFirst();
        if (path.length - 1 > f.speed) continue;
        final prefix = rules.evaluate(
          world,
          id,
          path,
          context: context,
          prefix: true,
        );
        visited++;
        if (prefix.status != MovementStatus.valid ||
            !seen.add(key(path.last, prefix))) {
          continue;
        }
        if (path.last == destination) {
          final verified = rules.evaluate(world, id, path, context: context);
          if (verified.status == MovementStatus.valid) {
            solutions.add(verified);
            break;
          }
        }
        if (prefix.mustStop || path.length - 1 >= f.speed) continue;
        for (final next in _neighbors(path.last, world)) {
          queue.add([...path, next]);
        }
      }
      if (visited >= limit) break;
    }
    solutions.sort((a, b) => a.cost.compareTo(b.cost));
    return RouteSearch(
      solutions.take(3),
      visited >= limit
          ? 'Búsqueda de destrucción limitada a $limit prefijos; las alternativas mostradas están verificadas. No encontrar una no prueba que sea imposible.'
          : solutions.isEmpty
          ? 'No se encontró ruta válida bajo las reglas implementadas y la velocidad declarada.'
          : 'Alternativas verificadas con destrucción simulada; no son rutas exhaustivas.',
      visited,
    );
  }

  Iterable<CellCoordinate> _neighbors(
    CellCoordinate c,
    VisionSnapshot w,
  ) sync* {
    for (var y = -1; y <= 1; y++) {
      for (var x = -1; x <= 1; x++) {
        if (x == 0 && y == 0 || c.column + x < 0 || c.row + y < 0) continue;
        final next = CellCoordinate(column: c.column + x, row: c.row + y);
        if (w.dimensions.contains(next)) yield next;
      }
    }
  }
}

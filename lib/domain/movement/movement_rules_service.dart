import '../board/cell_coordinate.dart';
import '../characters/character.dart';
import '../characters/movement_ability.dart';
import '../characters/vision_ability.dart';
import '../rules/line_of_sight.dart';
import '../terrain/edge_wall.dart';
import '../terrain/terrain.dart';
import 'movement.dart';

/// Perfil de traslación sin giro. No resuelve dados, acciones ni poderes libres.
final class MovementRulesService {
  const MovementRulesService();

  Character? figure(VisionSnapshot world, String id) =>
      world.characters.where((f) => f.id == id).firstOrNull;

  StepEvaluation? scope(
    VisionSnapshot world,
    Character mover,
    MovementContext context,
  ) {
    if (context.rulesVersion != VisionContext.supportedVersion ||
        context.specialEffects) {
      return const StepEvaluation(
        MovementStatus.notEvaluated,
        'Versión o efecto de movimiento sin soporte.',
        'SCOPE',
      );
    }
    if (!mover.footprint.isSupported ||
        world.characters.any((f) => f.size != FigureSize.normal) ||
        mover.movementAbilities.any((a) => !a.supported)) {
      return const StepEvaluation(
        MovementStatus.notEvaluated,
        'Tamaño, formato de base o capacidad de movimiento sin soporte.',
        'SCOPE',
      );
    }
    final occupied = <CellCoordinate>{};
    for (final f in world.characters) {
      final levels = <int>{};
      for (final c in f.occupiedCells) {
        if (!world.dimensions.contains(c) ||
            !occupied.add(c) ||
            world.terrain.at(c).type == TerrainType.blocking) {
          return const StepEvaluation(
            MovementStatus.notEvaluated,
            'Escenario con ocupación incompatible; corrige su posición de estudio.',
            '13.2',
          );
        }
        levels.add(world.terrain.at(c).level);
      }
      if (levels.length != 1) {
        return const StepEvaluation(
          MovementStatus.notEvaluated,
          'Base en varios niveles sin perfil de vuelo o tamaño especial.',
          '16.5g',
        );
      }
      if (_internalWall(world, f, f.position)) {
        return const StepEvaluation(
          MovementStatus.notEvaluated,
          'La base original ocupa un muro; corrige la posición de estudio.',
          '13.2',
        );
      }
    }
    return null;
  }

  bool _blocked(VisionSnapshot w, CellCoordinate c) =>
      w.terrain.at(c).type == TerrainType.blocking;
  bool _wall(VisionSnapshot w, CellCoordinate a, CellCoordinate b) =>
      w.walls.edges.containsKey(EdgeWall.between(a, b).id);
  Character? _occupant(VisionSnapshot w, CellCoordinate c, String excluding) =>
      w.characters
          .where((f) => f.id != excluding && f.occupiedCells.contains(c))
          .firstOrNull;

  /// Adyacencia real: las mejoras de movimiento no retiran muros del mapa.
  bool adjacent(VisionSnapshot w, CellCoordinate a, CellCoordinate b) {
    final dx = b.column - a.column, dy = b.row - a.row;
    if (a == b ||
        dx.abs() > 1 ||
        dy.abs() > 1 ||
        w.terrain.at(a).level != w.terrain.at(b).level) {
      return false;
    }
    if (dx == 0 || dy == 0) return !_wall(w, a, b);
    final sides = [
      CellCoordinate(column: a.column, row: b.row),
      CellCoordinate(column: b.column, row: a.row),
    ];
    return sides.any(
      (s) => !_blocked(w, s) && !_wall(w, a, s) && !_wall(w, s, b),
    );
  }

  bool besideEnemy(
    VisionSnapshot w,
    Character f,
    CellCoordinate anchor, {
    bool referenceOnly = false,
  }) => w.characters
      .where((other) => other.id != f.id && other.teamId != f.teamId)
      .any(
        (other) => (referenceOnly ? [anchor] : f.footprint.cellsAt(anchor)).any(
          (a) => other.occupiedCells.any((b) => adjacent(w, a, b)),
        ),
      );

  StepEvaluation _orthogonal(
    VisionSnapshot w,
    Character f,
    CellCoordinate a,
    CellCoordinate b,
  ) {
    final ignoresB = f.movementAbilities.contains(MovementAbility.blocking);
    final outdoor = f.movementAbilities.contains(
      MovementAbility.outdoorBlocking,
    );
    final ignoresTerrain = ignoresB || (outdoor && !w.terrain.isIndoor(b));
    // Un muro que coincide con un límite amarillo es Indoor (§15.1c).
    final ignoresWall =
        ignoresB ||
        (outdoor && !w.terrain.isIndoor(a) && !w.terrain.isIndoor(b));
    if ((!ignoresTerrain && _blocked(w, b)) ||
        (!ignoresWall && _wall(w, a, b))) {
      return StepEvaluation(
        MovementStatus.invalid,
        _wall(w, a, b) ? 'Muro cruzado.' : 'Terreno bloqueado en ${b.label}.',
        _wall(w, a, b) ? '16.4a' : '16.3a',
      );
    }
    final occupant = _occupant(w, b, f.id);
    if (occupant != null &&
        occupant.teamId != f.teamId &&
        !f.movementAbilities.contains(MovementAbility.characters) &&
        !f.movementAbilities.contains(MovementAbility.moveThrough)) {
      return const StepEvaluation(
        MovementStatus.invalid,
        'La casilla de paso está ocupada por una figura enemiga.',
        '10.7d',
      );
    }
    final changed = w.terrain.at(a).level != w.terrain.at(b).level;
    final transition = w.terrain.transitions.contains(EdgeWall.between(a, b));
    final stop =
        changed &&
        !transition &&
        !f.movementAbilities.contains(MovementAbility.elevated);
    return StepEvaluation(
      MovementStatus.valid,
      stop
          ? 'Cruza borde de altura: debe terminar aquí.'
          : changed && transition
          ? 'Cruza las dos casillas conectadas de transición.'
          : ignoresB && (_blocked(w, b) || _wall(w, a, b))
          ? 'IM Bloqueado ignora B/muro para pasar.'
          : outdoor && (_blocked(w, b) || _wall(w, a, b))
          ? 'IM Bloqueado exterior permite atravesar B/muro Outdoor.'
          : changed && f.movementAbilities.contains(MovementAbility.elevated)
          ? 'IM Elevación permite continuar al cruzar altura.'
          : occupant != null
          ? 'Paso por figura permitido; no permite terminar ocupado.'
          : w.terrain.at(b).type == TerrainType.hindering
          ? 'H no añade costo de movimiento.'
          : w.terrain.at(b).type == TerrainType.water
          ? 'Agua se considera despejado: sin costo adicional.'
          : w.terrain.isIndoor(b)
          ? 'Paso Indoor: el límite amarillo no añade costo ni es un muro.'
          : 'Paso permitido.',
      stop
          ? '16.5a'
          : changed && transition
          ? '16.7b'
          : ignoresB && (_blocked(w, b) || _wall(w, a, b))
          ? '27.5b'
          : outdoor && (_blocked(w, b) || _wall(w, a, b))
          ? '27.5c'
          : changed && f.movementAbilities.contains(MovementAbility.elevated)
          ? '27.5a'
          : occupant != null
          ? (occupant.teamId == f.teamId
                ? '10.7a'
                : f.movementAbilities.contains(MovementAbility.characters)
                ? '27.5e'
                : '27.5f')
          : w.terrain.at(b).type == TerrainType.hindering
          ? '16.2a'
          : w.terrain.at(b).type == TerrainType.water
          ? '16.6'
          : w.terrain.isIndoor(b)
          ? '15.1'
          : '10.2',
      stop: stop,
    );
  }

  /// Un paso cuesta una casilla incluso si es diagonal. Las dos mitades de la
  /// esquina se inspeccionan como alternativas, no como dos pasos consumidos.
  StepEvaluation validateStep(
    VisionSnapshot w,
    Character f,
    CellCoordinate a,
    CellCoordinate b,
  ) {
    if (!w.dimensions.contains(a) || !w.dimensions.contains(b)) {
      return const StepEvaluation(
        MovementStatus.invalid,
        'Paso fuera del tablero.',
        '3.1',
      );
    }
    final dx = (b.column - a.column).abs(), dy = (b.row - a.row).abs();
    if (dx > 1 || dy > 1 || dx + dy == 0) {
      return const StepEvaluation(
        MovementStatus.invalid,
        'El siguiente paso debe ser una casilla vecina; no se rellenan saltos.',
        '10.2',
      );
    }
    if (dx == 0 || dy == 0) return _orthogonal(w, f, a, b);
    final sides = [
      CellCoordinate(column: a.column, row: b.row),
      CellCoordinate(column: b.column, row: a.row),
    ];
    final alternatives = <StepEvaluation>[];
    for (final s in sides) {
      final first = _orthogonal(w, f, a, s), last = _orthogonal(w, f, s, b);
      // Una transición a distinto nivel solo permite cruzar ortogonalmente.
      final changes =
          w.terrain.at(a).level != w.terrain.at(s).level ||
          w.terrain.at(s).level != w.terrain.at(b).level;
      final stop =
          changes && !f.movementAbilities.contains(MovementAbility.elevated);
      alternatives.add(
        first.status == MovementStatus.invalid
            ? first
            : last.status == MovementStatus.invalid
            ? last
            : StepEvaluation(
                MovementStatus.valid,
                stop
                    ? 'Esquina por altura: debe detenerse; la transición no se cruza en diagonal.'
                    : 'Esquina por el lado menos restrictivo.',
                '16.8a',
                stop: stop,
              ),
      );
    }
    final descriptions = [
      for (var i = 0; i < alternatives.length; i++)
        '${sides[i].label}: ${alternatives[i].reason}',
    ];
    alternatives.sort(
      (a, b) =>
          (a.status == MovementStatus.invalid
                  ? 2
                  : a.stop
                  ? 1
                  : 0)
              .compareTo(
                b.status == MovementStatus.invalid
                    ? 2
                    : b.stop
                    ? 1
                    : 0,
              ),
    );
    final best = alternatives.first;
    return StepEvaluation(
      best.status,
      '${best.reason} Lados: ${descriptions.join(' / ')}',
      best.status == MovementStatus.invalid ? '16.8a' : best.rule,
      stop: best.stop,
    );
  }

  StepEvaluation? landing(
    VisionSnapshot w,
    Character f,
    CellCoordinate anchor,
  ) {
    final levels = <int>{};
    if (_internalWall(w, f, anchor)) {
      return const StepEvaluation(
        MovementStatus.invalid,
        'La base final ocupa un muro interior de su huella.',
        '13.2',
      );
    }
    for (final c in f.footprint.cellsAt(anchor)) {
      if (!w.dimensions.contains(c)) {
        return const StepEvaluation(
          MovementStatus.invalid,
          'La base final sale del tablero.',
          '24.2d',
        );
      }
      if (_blocked(w, c) || _occupant(w, c, f.id) != null) {
        return StepEvaluation(
          MovementStatus.invalid,
          'No puede terminar sobre B o una figura en ${c.label}.',
          '13.2',
        );
      }
      levels.add(w.terrain.at(c).level);
    }
    if (levels.length != 1) {
      return const StepEvaluation(
        MovementStatus.invalid,
        'La base normal no puede terminar en niveles diferentes.',
        '16.5g',
      );
    }
    return null;
  }

  bool _internalWall(VisionSnapshot w, Character f, CellCoordinate anchor) {
    final cells = f.footprint.cellsAt(anchor).toSet();
    return w.walls.edges.values.any(
      (e) => cells.contains(e.firstCell) && cells.contains(e.secondCell),
    );
  }

  RouteEvaluation evaluate(
    VisionSnapshot w,
    String id,
    Iterable<CellCoordinate> path, {
    MovementContext context = const MovementContext(),
  }) {
    final route = List<CellCoordinate>.of(path), f = figure(w, id);
    final events = <MovementEvent>[];
    RouteEvaluation finish(
      MovementStatus status,
      String reason,
      String rule,
      int index,
    ) {
      if (route.isNotEmpty) {
        events.add(
          MovementEvent(
            index,
            route[index.clamp(0, route.length - 1)],
            rule,
            reason,
          ),
        );
      }
      return RouteEvaluation(
        status: status,
        route: route,
        budget: f?.speed ?? 0,
        reason: reason,
        events: events,
      );
    }

    if (f == null || route.isEmpty || route.first != f.position) {
      return finish(
        MovementStatus.notEvaluated,
        'Elige una figura y comienza en su ancla original.',
        'SCOPE',
        0,
      );
    }
    final unsupported = scope(w, f, context);
    if (unsupported != null) {
      return finish(
        unsupported.status,
        unsupported.reason,
        unsupported.rule,
        0,
      );
    }
    final startsBesideEnemy = besideEnemy(w, f, f.position);
    if (startsBesideEnemy &&
        !f.movementAbilities.contains(MovementAbility.characters)) {
      return finish(
        MovementStatus.notEvaluated,
        'Debe resolver separación antes de mover. No se tiran dados ni se supone éxito; IM Atravesar también requiere separación.',
        '10.8',
        0,
      );
    }
    if (startsBesideEnemy) {
      events.add(
        MovementEvent(
          0,
          f.position,
          '27.5e',
          'IM Personajes concede separación automática; no se tira un dado.',
        ),
      );
    }
    var mustStop = false;
    for (var i = 1; i < route.length; i++) {
      if (mustStop) {
        return finish(
          MovementStatus.invalid,
          'El movimiento debía terminar en el paso anterior.',
          '10.7b / 16.5a',
          i,
        );
      }
      if (i > f.speed) {
        return finish(
          MovementStatus.invalid,
          'La ruta excede la velocidad declarada ${f.speed}.',
          '10.2',
          i,
        );
      }
      final result = validateTranslation(w, f, route[i - 1], route[i]);
      events.add(MovementEvent(i, route[i], result.rule, result.reason));
      if (i == route.length - 1) {
        final finalLanding = landing(w, f, route[i]);
        if (finalLanding != null) {
          return finish(
            finalLanding.status,
            finalLanding.reason,
            finalLanding.rule,
            i,
          );
        }
      }
      if (result.status != MovementStatus.valid) {
        return finish(result.status, result.reason, result.rule, i);
      }
      mustStop =
          result.stop ||
          (!f.movementAbilities.contains(MovementAbility.characters) &&
              !f.movementAbilities.contains(MovementAbility.moveThrough) &&
              besideEnemy(w, f, route[i], referenceOnly: true));
      if (!mustStop &&
          besideEnemy(w, f, route[i], referenceOnly: true) &&
          (f.movementAbilities.contains(MovementAbility.characters) ||
              f.movementAbilities.contains(MovementAbility.moveThrough))) {
        events.add(
          MovementEvent(
            i,
            route[i],
            f.movementAbilities.contains(MovementAbility.characters)
                ? '27.5e'
                : '27.5f',
            'La mejora permite continuar junto a una figura enemiga.',
          ),
        );
      }
      if (mustStop) {
        events.add(
          MovementEvent(
            i,
            route[i],
            result.stop ? '16.5a' : '10.7b',
            'Debe terminar el movimiento en esta posición.',
          ),
        );
      }
    }
    final end = landing(w, f, route.last);
    if (end != null) {
      return finish(end.status, end.reason, end.rule, route.length - 1);
    }
    return finish(
      MovementStatus.valid,
      'Ruta verificable con velocidad declarada; no valida una acción ni un turno.',
      '10.2 / 13.2',
      route.length - 1,
    );
  }

  StepEvaluation validateTranslation(
    VisionSnapshot w,
    Character f,
    CellCoordinate from,
    CellCoordinate to,
  ) {
    final reference = validateStep(w, f, from, to);
    if (reference.status != MovementStatus.valid ||
        f.footprint == Footprint.single) {
      return reference;
    }
    // Subconjunto conservador: §24.2d solo mueve la referencia. Si otra parte
    // exige una maniobra distinta, no se afirma ilegalidad general de la base.
    for (var y = 0; y < f.footprint.height; y++) {
      for (var x = 0; x < f.footprint.width; x++) {
        if (x == 0 && y == 0) continue;
        final a = CellCoordinate(column: from.column + x, row: from.row + y);
        final b = CellCoordinate(column: to.column + x, row: to.row + y);
        final part = validateStep(w, f, a, b);
        if (part.status != MovementStatus.valid ||
            part.stop != reference.stop) {
          return StepEvaluation(
            MovementStatus.notEvaluated,
            'Otra parte de la base requiere una referencia o giro fuera del perfil de traslación verificado (${b.label}).',
            '24.2d',
          );
        }
      }
    }
    return reference;
  }
}

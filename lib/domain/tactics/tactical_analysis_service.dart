import '../board/cell_coordinate.dart';
import '../characters/character.dart';
import '../characters/vision_ability.dart';
import '../movement/movement.dart';
import '../movement/movement_rules_service.dart';
import '../movement/route_planner.dart';
import '../rules/distance_service.dart';
import '../rules/line_of_sight.dart';
import '../rules/line_of_sight_service.dart';
import '../rules/target_analysis_service.dart';
import 'tactical_diagnostic.dart';

/// Métricas definidas y evidencia compacta; ninguna regla de visión o movimiento
/// se vuelve a implementar aquí. No calcula jugadas óptimas ni ataques legales.
final class TacticalAnalysisService {
  const TacticalAnalysisService({
    this.movement = const MovementRulesService(),
    this.distance = const DistanceService(),
    this.vision = const LineOfSightService(),
    this.enemyLimit = 32,
  });
  final MovementRulesService movement;
  final DistanceService distance;
  final VisionEvaluator vision;
  final int enemyLimit;
  Character? actor(VisionSnapshot w, String id) =>
      w.characters.where((f) => f.id == id).firstOrNull;
  VisionSnapshot contextualize(
    VisionSnapshot w,
    String id,
    TacticalContext c, {
    CellCoordinate? position,
  }) => VisionSnapshot(
    dimensions: w.dimensions,
    terrain: w.terrain,
    walls: w.walls,
    characters: w.characters.map((f) {
      if (f.id != id) return f;
      final d = f.data;
      return f.revised(
        CharacterDraft(
          name: d.name,
          teamId: d.teamId,
          position: position ?? d.position,
          footprint: d.footprint,
          speed: d.speed,
          range: d.range,
          size: d.size,
          abilities: c.withoutImprovements
              ? d.abilities.where((a) => !a.supported)
              : d.abilities,
          movementAbilities: c.withoutImprovements
              ? d.movementAbilities.where((a) => !a.supported)
              : d.movementAbilities,
        ),
      );
    }),
  );
  VisionContext _visionContext(TacticalContext c) => VisionContext(
    rulesVersion: c.rulesVersion,
    features: [if (c.unknownEffects) VisionFeature.powersOrSizes],
  );
  MovementContext movementContext(TacticalContext c) => MovementContext(
    rulesVersion: c.rulesVersion,
    specialEffects: c.unknownEffects,
  );
  PositionDiagnostic inspect(
    VisionSnapshot original,
    String sourceId,
    TacticalContext context, {
    CellCoordinate? at,
    void Function(int done, int total)? onEnemy,
  }) {
    final w = contextualize(original, sourceId, context, position: at),
        source = actor(w, sourceId);
    if (source == null) throw ArgumentError('Selecciona una figura activa.');
    final enemies =
        w.characters
            .where((f) => f.id != sourceId && f.teamId != source.teamId)
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    final results = <EnemyDiagnostic>[], limits = <String>{};
    final counts = {for (final m in TacticalMetric.values) m: 0},
        unknown = {for (final m in TacticalMetric.values) m: 0};
    final cap = enemyLimit.clamp(1, 64);
    final ctx = _visionContext(context);
    LineDiagnostic summarize(
      TargetEvaluation sight,
      TargetEvaluation combined,
    ) => LineDiagnostic(
      visibility: sight.vision.status,
      range: combined.range,
      combined: combined.status,
      combinedVisibility: combined.vision.status,
      from: sight.vision.origin?.cell,
      to: sight.vision.destination?.cell,
      rangeFrom: combined.vision.origin?.cell,
      rangeTo: combined.vision.destination?.cell,
      distance: combined.distance.squares,
      reason: sight.vision.explanation,
      rules: List.unmodifiable({
        ...sight.vision.decisive.expand((o) => o.rules).map((r) => r.citation),
        ...combined.rules.map((r) => r.citation),
      }),
    );
    void add(TacticalMetric m, bool? value) {
      if (value == null) {
        unknown[m] = unknown[m]! + 1;
      } else if (value) {
        counts[m] = counts[m]! + 1;
      }
    }

    for (final enemy in enemies.take(cap)) {
      final cache = _PairCache(vision),
          service = TargetAnalysisService(vision: cache, distance: distance);
      final out = service.evaluateTarget(
            w,
            source,
            enemy,
            ctx,
            visionOnly: true,
          ),
          ranged = service.evaluateTarget(w, source, enemy, ctx),
          incoming = service.evaluateTarget(
            w,
            enemy,
            source,
            ctx,
            visionOnly: true,
          ),
          threatening = service.evaluateTarget(w, enemy, source, ctx);
      final a = summarize(out, ranged), b = summarize(incoming, threatening);
      results.add(EnemyDiagnostic(enemy.id, enemy.label, a, b));
      add(TacticalMetric.visible, a.canSee);
      add(TacticalMetric.seenBy, b.canSee);
      add(
        TacticalMetric.inRange,
        a.range == RangeStatus.notEvaluated
            ? null
            : a.range == RangeStatus.within,
      );
      add(
        TacticalMetric.hindered,
        a.visibility == VisionStatus.notEvaluated
            ? null
            : a.visibility == VisionStatus.hindered,
      );
      add(
        TacticalMetric.blocked,
        a.visibility == VisionStatus.notEvaluated
            ? null
            : a.visibility == VisionStatus.blocked,
      );
      add(
        TacticalMetric.threats,
        b.combined == TargetStatus.notEvaluated
            ? null
            : b.combined == TargetStatus.inRangeClear ||
                  b.combined == TargetStatus.inRangeHindered,
      );
      onEnemy?.call(
        results.length,
        enemies.length < cap ? enemies.length : cap,
      );
    }
    final omitted = enemies.length - results.length;
    if (omitted > 0) {
      limits.add(
        'Se analizaron ${results.length} de ${enemies.length} enemigos; el resto está No evaluado.',
      );
    }
    if (context.unknownEffects ||
        context.rulesVersion != VisionContext.supportedVersion ||
        source.size != FigureSize.normal ||
        !source.footprint.isSupported ||
        source.abilities.any((a) => !a.supported)) {
      limits.add(
        'Contexto o perfil sin soporte completo; no autoriza acciones ni propuestas categóricas.',
      );
    }
    if (unknown.values.any((n) => n > 0)) {
      limits.add(
        'Hay líneas o alcances No evaluados; los recuentos son mínimos confirmados.',
      );
    }
    return PositionDiagnostic(
      cell: source.position,
      context: context,
      totalEnemies: enemies.length,
      enemies: results,
      metrics: {
        for (final m in TacticalMetric.values)
          m: MetricCount(counts[m]!, unknown[m]! + omitted),
      },
      terrain: source.occupiedCells.map((c) => w.terrain.at(c).type),
      levels: source.occupiedCells.map((c) => w.terrain.at(c).level),
      limits: limits,
    );
  }

  TacticalCandidate candidate(
    VisionSnapshot original,
    String id,
    CellCoordinate destination,
    TacticalContext context, {
    bool compareImprovements = false,
    void Function(int, int)? onEnemy,
  }) {
    final world = contextualize(original, id, context),
        source = actor(world, id);
    TacticalCandidate no(CandidateStatus status, String reason) =>
        TacticalCandidate(cell: destination, status: status, reason: reason);
    if (source == null) {
      return no(CandidateStatus.notEvaluated, 'Falta figura activa.');
    }
    final start = movement.evaluate(world, id, [
      source.position,
    ], context: movementContext(context));
    if (start.status != MovementStatus.valid) {
      return no(CandidateStatus.notEvaluated, start.reason);
    }
    final landing = movement.landing(world, source, destination);
    if (landing != null) {
      return no(
        landing.status == MovementStatus.notEvaluated
            ? CandidateStatus.notEvaluated
            : CandidateStatus.invalid,
        landing.reason,
      );
    }
    final search = RoutePlanner(rules: movement)
        .search(world, id, destination, context: movementContext(context));
    if (search.routes.isEmpty) {
      return no(CandidateStatus.notEvaluated, search.reason);
    }
    final route = movement.evaluate(
      world,
      id,
      search.routes.first.route,
      context: movementContext(context),
    );
    if (route.status != MovementStatus.valid) {
      return no(CandidateStatus.notEvaluated, route.reason);
    }
    final position = inspect(
      original,
      id,
      context,
      at: destination,
      onEnemy: onEnemy,
    );
    RouteEvaluation? alternateMovement;
    PositionDiagnostic? alternate;
    if (compareImprovements) {
      final alternative = context.without,
          aw = contextualize(original, id, alternative);
      alternateMovement = movement.evaluate(
        aw,
        id,
        route.route,
        context: movementContext(alternative),
      );
      alternate = inspect(original, id, alternative, at: destination);
    }
    return TacticalCandidate(
      cell: destination,
      status: CandidateStatus.legal,
      reason: 'Ruta verificada bajo el perfil implementado; no es un permiso de ataque.',
      route: route,
      position: position,
      alternate: alternate,
      alternateMovement: alternateMovement,
    );
  }

  List<CellCoordinate> pool(
    VisionSnapshot w,
    String id,
    TacticalContext context,
  ) {
    final source = actor(w, id);
    if (source == null) return const [];
    final cells = <CellCoordinate>[];
    for (var row = 0; row < w.dimensions.rows; row++) {
      for (var column = 0; column < w.dimensions.columns; column++) {
        final c = CellCoordinate(column: column, row: row);
        if (c == source.position) continue;
        final d = distance.measure(
          w.dimensions,
          source.position,
          c,
          rulesVersion: context.rulesVersion,
        );
        if (d.squares != null && d.squares! <= source.speed) cells.add(c);
      }
    }
    cells.sort((a, b) {
      final da = distance.measure(w.dimensions, source.position, a).squares!,
          db = distance.measure(w.dimensions, source.position, b).squares!;
      if (da != db) return da.compareTo(db);
      final row = a.row.compareTo(b.row);
      return row != 0 ? row : a.column.compareTo(b.column);
    });
    return List.unmodifiable(cells);
  }

  List<TacticalCandidate> ordered(
    Iterable<TacticalCandidate> candidates,
    TacticalPriority priority,
  ) {
    final result = candidates
        .where((c) => c.status == CandidateStatus.legal && c.position!.complete)
        .toList();
    result.sort((a, b) {
      final primary = switch (priority) {
        TacticalPriority.seeMore =>
          b.position!.metrics[TacticalMetric.visible]!.known.compareTo(
            a.position!.metrics[TacticalMetric.visible]!.known,
          ),
        TacticalPriority.reduceExposure =>
          a.position!.metrics[TacticalMetric.seenBy]!.known.compareTo(
            b.position!.metrics[TacticalMetric.seenBy]!.known,
          ),
        TacticalPriority.minimizeMovement => a.route!.cost.compareTo(
          b.route!.cost,
        ),
      };
      if (primary != 0) return primary;
      final cost = a.route!.cost.compareTo(b.route!.cost);
      if (cost != 0) return cost;
      final row = a.cell.row.compareTo(b.cell.row);
      return row != 0 ? row : a.cell.column.compareTo(b.cell.column);
    });
    return List.unmodifiable(result);
  }
}

final class _PairCache implements VisionEvaluator {
  _PairCache(this.delegate);
  final VisionEvaluator delegate;
  final _cache = <Object, VisionEvaluation>{};
  @override
  VisionEvaluation evaluate(
    VisionSnapshot w,
    VisionEndpoint a,
    VisionEndpoint b,
    VisionContext context,
  ) {
    final key = (a.cell, a.figureId, b.cell, b.figureId);
    return _cache.putIfAbsent(key, () => delegate.evaluate(w, a, b, context));
  }
}

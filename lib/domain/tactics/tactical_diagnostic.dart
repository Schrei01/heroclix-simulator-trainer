import '../board/cell_coordinate.dart';
import '../movement/movement.dart';
import '../rules/line_of_sight.dart';
import '../rules/target_analysis_service.dart';
import '../terrain/terrain.dart';

enum TacticalPriority {
  seeMore('Ver más objetivos'),
  reduceExposure('Reducir líneas enemigas'),
  minimizeMovement('Minimizar movimiento');

  const TacticalPriority(this.label);
  final String label;
}

final class TacticalContext {
  const TacticalContext({
    this.rulesVersion = VisionContext.supportedVersion,
    this.withoutImprovements = false,
    this.unknownEffects = false,
  });
  final String rulesVersion;
  final bool withoutImprovements, unknownEffects;
  TacticalContext get without => TacticalContext(
    rulesVersion: rulesVersion,
    withoutImprovements: true,
    unknownEffects: unknownEffects,
  );
  String get key => '$rulesVersion:$withoutImprovements:$unknownEffects';
}

enum TacticalMetric {
  visible(
    'Objetivos visibles',
    'Visión del activo, sin exigir alcance.',
    '11.4 / 24.2e',
  ),
  seenBy(
    'Enemigos que lo ven',
    'Visión desde cada enemigo, con su propia ficha.',
    '11.4 / 27.6',
  ),
  inRange(
    'Enemigos en su alcance',
    'Distancia y alcance declarados; no exige visión.',
    '11.3b / 11.5',
  ),
  hindered(
    'Líneas salientes obstaculizadas',
    'Incluidas entre las visibles.',
    '16.2b',
  ),
  blocked(
    'Líneas salientes bloqueadas',
    'Obstáculos activos en la línea de visión.',
    '16.3b / 16.4b',
  ),
  threats(
    'Amenazas conocidas',
    'Enemigo con visión y alcance usando un mismo par.',
    '11.5',
  );

  const TacticalMetric(this.label, this.scope, this.rules);
  final String label, scope, rules;
  static const excluded =
      'No valida ataques, acciones, adyacencia para atacar, daño, dados, modificadores ni probabilidad de victoria.';
}

final class MetricCount {
  const MetricCount(this.known, this.unknown);
  final int known, unknown;
  bool get complete => unknown == 0;
  String get text =>
      unknown == 0 ? '$known' : '≥$known · $unknown No evaluados';
}

final class LineDiagnostic {
  const LineDiagnostic({
    required this.visibility,
    required this.range,
    required this.combined,
    required this.combinedVisibility,
    required this.from,
    required this.to,
    required this.rangeFrom,
    required this.rangeTo,
    required this.distance,
    required this.reason,
    required this.rules,
  });
  final VisionStatus visibility, combinedVisibility;
  final RangeStatus range;
  final TargetStatus combined;
  final CellCoordinate? from, to, rangeFrom, rangeTo;
  final int? distance;
  final String reason;
  final List<String> rules;
  bool? get canSee => visibility == VisionStatus.notEvaluated
      ? null
      : visibility != VisionStatus.blocked;
}

final class EnemyDiagnostic {
  const EnemyDiagnostic(this.id, this.label, this.outgoing, this.incoming);
  final String id, label;
  final LineDiagnostic outgoing, incoming;
}

final class PositionDiagnostic {
  PositionDiagnostic({
    required this.cell,
    required this.context,
    required this.totalEnemies,
    required Iterable<EnemyDiagnostic> enemies,
    required Map<TacticalMetric, MetricCount> metrics,
    required Iterable<TerrainType> terrain,
    required Iterable<int> levels,
    required Iterable<String> limits,
  }) : enemies = List.unmodifiable(enemies),
       metrics = Map.unmodifiable(metrics),
       terrain = Set.unmodifiable(terrain),
       levels = Set.unmodifiable(levels),
       limits = List.unmodifiable(limits);
  final CellCoordinate cell;
  final TacticalContext context;
  final int totalEnemies;
  final List<EnemyDiagnostic> enemies;
  final Map<TacticalMetric, MetricCount> metrics;
  final Set<TerrainType> terrain;
  final Set<int> levels;
  final List<String> limits;
  int get omitted => totalEnemies - enemies.length;
  bool get complete =>
      limits.isEmpty && metrics.values.every((m) => m.complete);
}

enum CandidateStatus { legal, invalid, notEvaluated }

final class TacticalCandidate {
  const TacticalCandidate({
    required this.cell,
    required this.status,
    required this.reason,
    this.route,
    this.position,
    this.alternate,
    this.alternateMovement,
  });
  final CellCoordinate cell;
  final CandidateStatus status;
  final String reason;
  final RouteEvaluation? route, alternateMovement;
  final PositionDiagnostic? position, alternate;
}

final class MetricDifference {
  const MetricDifference(this.before, this.after);
  final MetricCount before, after;
  int? get exact =>
      before.complete && after.complete ? after.known - before.known : null;
}

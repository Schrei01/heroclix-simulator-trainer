import '../characters/character.dart';
import 'distance_service.dart';
import 'line_of_sight.dart';
import 'line_of_sight_service.dart';

enum RangeStatus { within, outside, notEvaluated }

enum TargetStatus {
  inRangeClear,
  inRangeHindered,
  blocked,
  outOfRange,
  notEvaluated,
}

enum TargetFilter { enemies, allies, all }

final class TargetEvaluation {
  TargetEvaluation({
    required this.source,
    required this.target,
    required this.distance,
    required this.range,
    required this.vision,
    required Iterable<String> evaluated,
    required Iterable<String> pending,
  }) : evaluated = List.unmodifiable(evaluated),
       pending = List.unmodifiable(pending);
  final Character source, target;
  final DistanceMeasurement distance;
  final RangeStatus range;
  final VisionEvaluation vision;
  final List<String> evaluated, pending;
  int get declaredRange => source.range;
  TargetStatus get status {
    if (range == RangeStatus.notEvaluated || vision.canSee == null) {
      return TargetStatus.notEvaluated;
    }
    if (range == RangeStatus.outside) return TargetStatus.outOfRange;
    return switch (vision.status) {
      VisionStatus.clear => TargetStatus.inRangeClear,
      VisionStatus.hindered => TargetStatus.inRangeHindered,
      VisionStatus.blocked => TargetStatus.blocked,
      VisionStatus.notEvaluated => TargetStatus.notEvaluated,
    };
  }

  List<TacticalRule> get rules => [
    TacticalRule.distance,
    TacticalRule.range,
    TacticalRule.source,
    TacticalRule.targets,
    TacticalRule.attack,
    if (source.footprint != Footprint.single ||
        target.footprint != Footprint.single)
      TacticalRule.multiBase,
    if (status == TargetStatus.notEvaluated) TacticalRule.limit,
  ];
}

final class TargetReport {
  TargetReport({
    required this.sourceId,
    required Iterable<TargetEvaluation> targets,
    this.error,
  }) : targets = List.unmodifiable(targets);
  final String sourceId;
  final List<TargetEvaluation> targets;
  final String? error;
}

/// Análisis preliminar de todas las demás figuras. El filtro de equipo es de
/// consulta: no afirma que una figura aliada sea un objetivo legal de ataque.
final class TargetAnalysisService {
  const TargetAnalysisService({
    this.vision = const LineOfSightService(),
    this.distance = const DistanceService(),
  });
  final VisionEvaluator vision;
  final DistanceService distance;
  TargetReport evaluate(
    VisionSnapshot snapshot,
    String sourceId,
    VisionContext context,
  ) {
    final sources = snapshot.characters.where((f) => f.id == sourceId).toList();
    if (sources.length != 1) {
      return TargetReport(
        sourceId: sourceId,
        targets: [],
        error: 'Elige una figura de origen válida.',
      );
    }
    final source = sources.single;
    final targets = <TargetEvaluation>[];
    for (final target in snapshot.characters) {
      if (target.id == sourceId) continue;
      final sight = vision.evaluate(
        snapshot,
        VisionEndpoint(source.position, figureId: source.id),
        VisionEndpoint(target.position, figureId: target.id),
        context,
      );
      final bases =
          source.footprint != Footprint.single ||
          target.footprint != Footprint.single;
      final metric = bases
          ? const DistanceMeasurement(
              reason: 'Base múltiple: distancia y referencias pendientes de soporte (§24.2e).',
            )
          : distance.measure(
              snapshot.dimensions,
              source.position,
              target.position,
              rulesVersion: context.rulesVersion,
            );
      final rangeUnknown =
          !metric.evaluated ||
          context.features.isNotEmpty ||
          sight.observations.any(
            (o) =>
                o.rules.contains(VisionRule.occupancy) ||
                (o.effect == VisionEffect.unsupported && o.rules.length == 1),
          );
      final range = rangeUnknown
          ? RangeStatus.notEvaluated
          : metric.squares! <= source.range
          ? RangeStatus.within
          : RangeStatus.outside;
      targets.add(
        TargetEvaluation(
          source: source,
          target: target,
          distance: metric,
          range: range,
          vision: sight,
          evaluated: [
            if (metric.evaluated)
              'Distancia entre casillas: ${metric.squares}.',
            if (range != RangeStatus.notEvaluated)
              'Comparación con alcance declarado ${source.range}.',
            if (sight.canSee != null) 'Visión bajo el perfil básico de 06.',
          ],
          pending: [
            if (!metric.evaluated) metric.reason!,
            if (range == RangeStatus.notEvaluated)
              'Comparación de alcance no evaluada para este caso.',
            if (sight.canSee == null) sight.explanation,
            'Legalidad completa de ataque: acciones, poderes, estados, adyacencia y número de objetivos no comprobados.',
            if (source.teamId == target.teamId)
              'Mismo equipo: consultar el efecto concreto antes de atacar.',
          ],
        ),
      );
    }
    return TargetReport(sourceId: sourceId, targets: targets);
  }
}

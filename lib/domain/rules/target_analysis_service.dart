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

/// Misma referencia para alcance y visión (§11.5); bases según §24.2e.
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
    return TargetReport(
      sourceId: sourceId,
      targets: [
        for (final target in snapshot.characters)
          if (target.id != sourceId)
            evaluateTarget(snapshot, sources.single, target, context),
      ],
    );
  }

  TargetEvaluation evaluateTarget(
    VisionSnapshot snapshot,
    Character source,
    Character target,
    VisionContext context, {
    bool visionOnly = false,
  }) {
    final supported =
        source.footprint.isSupported &&
        target.footprint.isSupported &&
        [source, target].every(
          (f) =>
              f.occupiedCells
                  .map((c) => snapshot.terrain.at(c).level)
                  .toSet()
                  .length ==
              1,
        );
    final origins = supported ? source.occupiedCells : [source.position];
    final destinations = supported ? target.occupiedCells : [target.position];
    final candidates = <TargetEvaluation>[];
    for (final from in origins) {
      for (final to in destinations) {
        final sight = vision.evaluate(
          snapshot,
          VisionEndpoint(from, figureId: source.id),
          VisionEndpoint(to, figureId: target.id),
          context,
        );
        final metric = supported
            ? distance.measure(
                snapshot.dimensions,
                from,
                to,
                rulesVersion: context.rulesVersion,
              )
            : const DistanceMeasurement(
                reason: 'Base sin soporte o en niveles distintos: referencias no evaluadas.',
              );
        final unknown =
            !metric.evaluated ||
            context.features.isNotEmpty ||
            (context.laboratoryAbilities ?? source.abilities).any(
              (a) => !a.supported,
            ) ||
            sight.observations.any(
              (o) =>
                  o.rules.contains(VisionRule.occupancy) ||
                  (o.effect == VisionEffect.unsupported && o.rules.length == 1),
            );
        final range = unknown
            ? RangeStatus.notEvaluated
            : metric.squares! <= source.range
            ? RangeStatus.within
            : RangeStatus.outside;
        candidates.add(
          TargetEvaluation(
            source: source,
            target: target,
            distance: metric,
            range: range,
            vision: sight,
            evaluated: [
              if (metric.evaluated)
                'Distancia del par ${from.label} / ${to.label}: ${metric.squares}.',
              if (range != RangeStatus.notEvaluated)
                'Comparación con alcance declarado ${source.range}.',
              if (sight.canSee != null)
                'Visión con elevación, bases y capacidades verificadas.',
            ],
            pending: [
              if (!metric.evaluated) metric.reason!,
              if (range == RangeStatus.notEvaluated)
                'Comparación de alcance no evaluada para este caso.',
              if (sight.canSee == null) sight.explanation,
              'Legalidad completa de ataque: acciones, poderes no modelados, estados, adyacencia y número de objetivos no comprobados.',
              if (source.teamId == target.teamId)
                'Mismo equipo: consultar el efecto concreto antes de atacar.',
            ],
          ),
        );
      }
    }
    final successes = candidates
        .where(
          (c) => visionOnly
              ? c.vision.canSee == true
              : c.status == TargetStatus.inRangeClear ||
                    c.status == TargetStatus.inRangeHindered,
        )
        .toList();
    final unknown = candidates
        .where((c) => c.status == TargetStatus.notEvaluated)
        .toList();
    final choices = successes.isNotEmpty
        ? successes
        : unknown.isNotEmpty
        ? unknown
        : candidates.toList();
    choices.sort((a, b) {
      final status = visionOnly
          ? a.vision.status.index.compareTo(b.vision.status.index)
          : a.status.index.compareTo(b.status.index);
      return status != 0
          ? status
          : (a.distance.squares ?? 999).compareTo(b.distance.squares ?? 999);
    });
    final chosen = choices.first;
    final refs = [
      for (final c in candidates)
        VisionReference(
          c.vision.origin!.cell,
          c.vision.destination!.cell,
          c.vision.status,
          c.distance.squares,
        ),
    ];
    return TargetEvaluation(
      source: source,
      target: target,
      distance: chosen.distance,
      range: chosen.range,
      vision: chosen.vision.withReferences(refs),
      evaluated: [
        'Se consultaron ${candidates.length} pares; distancia y visión usan el mismo par elegido.',
        ...chosen.evaluated,
      ],
      pending: chosen.pending,
    );
  }
}

import '../characters/character.dart';
import '../movement/movement.dart';
import '../movement/movement_rules_service.dart';
import '../rules/distance_service.dart';
import '../rules/line_of_sight.dart';
import '../rules/line_of_sight_service.dart';
import '../rules/target_analysis_service.dart';
import 'exercise.dart';

/// Adapta respuestas a los servicios existentes. No contiene reglas de terreno,
/// distancia, adyacencia ni visibilidad propias.
final class ExerciseEvaluator {
  const ExerciseEvaluator({this.activeVersion = RuleSetVersion.current});
  final RuleSetVersion activeVersion;
  static const movement = MovementRulesService(),
      targets = TargetAnalysisService();
  Character? _figure(Exercise e, String id) =>
      e.world.characters.where((f) => f.id == id).firstOrNull;
  VisionEvaluation? _vision(Exercise e, {Character? target}) {
    final source = _figure(e, e.sourceId),
        dest = target ?? _figure(e, e.targetId);
    final context = VisionContext(rulesVersion: e.rules.value);
    if (source != null && dest != null) {
      return targets
          .evaluateTarget(e.world, source, dest, context, visionOnly: true)
          .vision;
    }
    final a = e.origin ?? source?.position, b = e.destination ?? dest?.position;
    if (a == null || b == null) return null;
    return const LineOfSightService().evaluate(
      e.world,
      VisionEndpoint(a, figureId: source?.id),
      VisionEndpoint(b, figureId: dest?.id),
      context,
    );
  }

  ExerciseCheck check(Exercise e) {
    ExerciseCheck no(String s) => ExerciseCheck(eligible: false, reason: s);
    if (e.rules.value != activeVersion.value ||
        activeVersion.value != VisionContext.supportedVersion) {
      return no(
        'Edición ${e.rules.value} distinta del corrector ${activeVersion.value}; no se recalifica con otras reglas.',
      );
    }
    if (e.type == QuestionType.manual) {
      return ExerciseCheck(
        eligible: true,
        manual: true,
        reason: 'Evaluación manual: no se asigna acierto automáticamente.',
      );
    }
    final actual = <String>{}, evidence = <String>[];
    final source = _figure(e, e.sourceId), dest = _figure(e, e.targetId);
    switch (e.metric) {
      case ExerciseMetric.vision:
        if (e.type == QuestionType.target) {
          if (source == null) return no('Falta figura de origen.');
          final options = e.world.characters.where(
            (f) => f.id != source.id && f.teamId != source.teamId,
          );
          for (final f in options) {
            final v = _vision(e, target: f);
            if (v == null || v.canSee == null) {
              return no(v?.explanation ?? 'Objetivo no evaluado.');
            }
            if (v.canSee == true) actual.add(f.id);
            evidence.add(
              '${f.label}: ${_visionLabel(v.status)}. ${v.explanation}',
            );
          }
        } else {
          final v = _vision(e);
          if (v == null || v.canSee == null) {
            return no(v?.explanation ?? 'Faltan extremos de visión.');
          }
          actual.add(v.status.name);
          evidence.add(v.explanation);
        }
      case ExerciseMetric.reason:
        final v = _vision(e);
        if (v == null || v.canSee == null) {
          return no(v?.explanation ?? 'Visión no evaluada.');
        }
        final rules = v.decisive
            .expand((o) => o.rules)
            .map((r) => r.id)
            .toSet();
        actual.addAll(
          e.options.where((o) => rules.contains(o.id)).map((o) => o.id),
        );
        evidence.addAll(v.decisive.map((o) => o.description));
      case ExerciseMetric.distance:
        final a = e.origin ?? source?.position,
            b = e.destination ?? dest?.position;
        if (a == null || b == null) return no('Faltan casillas de distancia.');
        final d = const DistanceService().measure(
          e.world.dimensions,
          a,
          b,
          rulesVersion: e.rules.value,
        );
        if (!d.evaluated) return no(d.reason ?? 'Distancia no evaluada.');
        actual.add('${d.squares}');
        evidence.add(
          'Conteo entre ${a.label} y ${b.label}: ${d.squares}. §11.3a.',
        );
      case ExerciseMetric.range:
        if (source == null || dest == null) {
          return no('Faltan figuras para alcance.');
        }
        final t = targets.evaluateTarget(
          e.world,
          source,
          dest,
          VisionContext(rulesVersion: e.rules.value),
        );
        if (t.status == TargetStatus.notEvaluated) {
          return no(t.pending.join(' '));
        }
        actual.add(t.status.name);
        evidence.add(
          'Distancia ${t.distance.squares}, alcance declarado ${source.range}. ${t.vision.explanation}',
        );
      case ExerciseMetric.movement:
        if (source == null) return no('Falta figura de movimiento.');
        final paths = e.type == QuestionType.route
            ? [e.solutionRoute]
            : e.candidates.map((c) => [source.position, c]);
        var index = 0;
        for (final path in paths) {
          final r = movement.evaluate(
            e.world,
            source.id,
            path,
            context: MovementContext(rulesVersion: e.rules.value),
          );
          if (r.status == MovementStatus.notEvaluated) return no(r.reason);
          if (r.status == MovementStatus.valid) {
            actual.add(
              e.type == QuestionType.route
                  ? 'valid'
                  : e.candidates[index].label,
            );
          }
          evidence.add('${path.map((c) => c.label).join(' / ')}: ${r.reason}');
          index++;
        }
        if (e.type == QuestionType.route &&
            (e.solutionRoute.isEmpty ||
                e.solutionRoute.last != e.destination)) {
          return no('La ruta de verificación no llega al destino declarado.');
        }
      case ExerciseMetric.position:
        if (source == null || dest == null) {
          return no('Faltan figuras para comparar posiciones.');
        }
        for (final c in e.candidates) {
          final move = movement.evaluate(e.world, source.id, [
            source.position,
            c,
          ], context: MovementContext(rulesVersion: e.rules.value));
          if (move.status == MovementStatus.notEvaluated) {
            return no(move.reason);
          }
          if (move.status != MovementStatus.valid) {
            evidence.add('${c.label}: ${move.reason}');
            continue;
          }
          final next = source.revised(source.data.at(c));
          final future = VisionSnapshot(
            dimensions: e.world.dimensions,
            terrain: e.world.terrain,
            walls: e.world.walls,
            characters: e.world.characters.map(
              (f) => f.id == source.id ? next : f,
            ),
          );
          final t = targets.evaluateTarget(
            future,
            next,
            dest,
            VisionContext(rulesVersion: e.rules.value),
          );
          if (t.status == TargetStatus.notEvaluated) {
            return no(t.pending.join(' '));
          }
          if (t.status == TargetStatus.inRangeClear) actual.add(c.label);
          evidence.add(
            '${c.label}: distancia ${t.distance.squares}, alcance ${source.range}; ${_visionLabel(t.vision.status)}.',
          );
        }
      case ExerciseMetric.manual:
        return no('Corrector manual incompatible.');
    }
    if (actual.isEmpty ||
        actual.length != e.expected.length ||
        !actual.containsAll(e.expected)) {
      return ExerciseCheck(
        eligible: false,
        reason: 'La solución de verificación no coincide con el motor; ejercicio inhabilitado.',
        actual: actual,
        evidence: evidence,
      );
    }
    if ([QuestionType.choice, QuestionType.justification].contains(e.type) &&
        !e.options.map((o) => o.id).toSet().containsAll(actual)) {
      return no('La solución no figura entre las opciones.');
    }
    return ExerciseCheck(
      eligible: true,
      reason: 'Solución verificada con la edición ${e.rules.value}.',
      actual: actual,
      evidence: evidence,
    );
  }

  Evaluation evaluate(Exercise e, Answer answer) {
    final proof = check(e);
    if (!proof.eligible) {
      return Evaluation(EvaluationOutcome.notEvaluated, Feedback(proof.reason));
    }
    final requiredKind = switch (e.type) {
      QuestionType.choice || QuestionType.justification => AnswerKind.choice,
      QuestionType.target => AnswerKind.target,
      QuestionType.cell => AnswerKind.cell,
      QuestionType.route => AnswerKind.route,
      QuestionType.manual => AnswerKind.text,
    };
    if (answer.kind != requiredKind || answer.empty) {
      return Evaluation(
        EvaluationOutcome.incomplete,
        Feedback('Completa una respuesta antes de comprobar.'),
      );
    }
    if (proof.manual) {
      return Evaluation(
        EvaluationOutcome.manual,
        Feedback(
          'Revisión manual registrada. Compara tu razonamiento con la guía; no se asigna acierto ni porcentaje automático.',
          solution: e.manualGuide,
          references: e.references,
        ),
      );
    }
    var correct = proof.actual.contains(answer.value);
    final evidence = List<String>.of(proof.evidence);
    if (e.type == QuestionType.route) {
      final result = movement.evaluate(
        e.world,
        e.sourceId,
        answer.route,
        context: MovementContext(rulesVersion: e.rules.value),
      );
      if (result.status == MovementStatus.notEvaluated) {
        return Evaluation(
          EvaluationOutcome.notEvaluated,
          Feedback(result.reason),
        );
      }
      correct =
          result.status == MovementStatus.valid &&
          answer.route.last == e.destination;
      evidence.add(result.reason);
      if (answer.route.last != e.destination) {
        evidence.add('La ruta debe terminar en ${e.destination?.label}.');
      }
      evidence.addAll(
        result.events.map(
          (x) => 'Paso ${x.step}, ${x.cell.label}: ${x.reason} (${x.citation})',
        ),
      );
    }
    final solution = e.type == QuestionType.route
        ? 'Una ruta válida: ${e.solutionRoute.map((c) => c.label).join(' / ')}'
        : e.expected
              .map(
                (v) =>
                    e.options.where((o) => o.id == v).firstOrNull?.label ??
                    e.world.characters
                        .where((f) => f.id == v)
                        .firstOrNull
                        ?.label ??
                    v,
              )
              .join(', ');
    return Evaluation(
      correct ? EvaluationOutcome.correct : EvaluationOutcome.incorrect,
      Feedback(
        e.explanation,
        solution: solution,
        references: e.references,
        evidence: evidence,
      ),
    );
  }

  String _visionLabel(VisionStatus s) => switch (s) {
    VisionStatus.clear => 'Despejada',
    VisionStatus.hindered => 'Obstaculizada',
    VisionStatus.blocked => 'Bloqueada',
    VisionStatus.notEvaluated => 'No evaluada',
  };
}

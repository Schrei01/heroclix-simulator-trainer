import '../board/cell_coordinate.dart';
import '../characters/team.dart';
import '../rules/line_of_sight.dart';

enum SkillCategory {
  vision('Línea de visión'),
  terrain('Terreno y muros'),
  distance('Distancias y alcance'),
  movement('Movimiento'),
  elevation('Elevaciones y capacidades'),
  position('Posiciones sencillas');

  const SkillCategory(this.label);
  final String label;
}

enum Difficulty {
  basic('Básico'),
  intermediate('Intermedio'),
  advanced('Avanzado');

  const Difficulty(this.label);
  final String label;
}

enum QuestionType {
  choice('Elección múltiple'),
  target('Tocar objetivo visible'),
  cell('Elegir casilla'),
  route('Trazar ruta'),
  justification('Justificar el dictamen'),
  manual('Respuesta textual · manual');

  const QuestionType(this.label);
  final String label;
}

enum ExerciseMetric {
  vision,
  reason,
  distance,
  range,
  movement,
  position,
  manual,
}

final class RuleSetVersion {
  const RuleSetVersion(this.value);
  static const current = RuleSetVersion(VisionContext.supportedVersion);
  final String value;
}

final class ExerciseOption {
  const ExerciseOption(this.id, this.label);
  final String id, label;
}

final class Exercise {
  Exercise({
    required this.id,
    required this.title,
    required this.instruction,
    required this.category,
    required this.difficulty,
    required this.type,
    required this.metric,
    required this.world,
    required this.explanation,
    this.rules = RuleSetVersion.current,
    this.revision = 1,
    this.personal = false,
    this.sourceId = 'figure-1',
    this.targetId = 'figure-2',
    this.origin,
    this.destination,
    Iterable<ExerciseOption> options = const [],
    Iterable<String> expected = const [],
    Iterable<CellCoordinate> candidates = const [],
    Iterable<CellCoordinate> solutionRoute = const [],
    Iterable<String> hints = const [],
    Iterable<String> references = const [],
    Iterable<Team> teams = const [Team.blue, Team.red],
    this.manualGuide = '',
    this.snapshotId = 's-00000000000000000000000000000000',
    DateTime? createdAt,
  }) : options = List.unmodifiable(options),
       expected = Set.unmodifiable(expected),
       candidates = List.unmodifiable(candidates),
       solutionRoute = List.unmodifiable(solutionRoute),
       hints = List.unmodifiable(hints),
       references = List.unmodifiable(references),
       teams = List.unmodifiable(teams),
       createdAt = createdAt ?? DateTime.utc(2026, 11, 16) {
    if (!RegExp(r'^(hc10-[a-z][0-9]{2}|personal-[a-f0-9]{32})$').hasMatch(id) ||
        title.trim().isEmpty ||
        title.length > 80 ||
        instruction.trim().isEmpty ||
        instruction.length > 2000 ||
        explanation.length > 3000 ||
        revision < 1 ||
        revision > 999 ||
        rules.value.isEmpty ||
        rules.value.length > 40 ||
        this.options.length > 8 ||
        this.options.map((o) => o.id).toSet().length != this.options.length ||
        this.options.any(
          (o) =>
              o.id.isEmpty ||
              o.id.length > 40 ||
              o.label.trim().isEmpty ||
              o.label.length > 240,
        ) ||
        this.candidates.length > 12 ||
        this.solutionRoute.length > 101 ||
        this.hints.length > 5 ||
        this.hints.any((s) => s.length > 1000) ||
        this.references.length > 20 ||
        this.references.any((s) => s.length > 160) ||
        !this.createdAt.isUtc ||
        manualGuide.length > 3000 ||
        this.expected.length > 32) {
      throw ArgumentError('Ejercicio inválido o demasiado grande.');
    }
    if ((type == QuestionType.manual) != (metric == ExerciseMetric.manual) ||
        (type == QuestionType.route && metric != ExerciseMetric.movement) ||
        (type == QuestionType.justification &&
            metric != ExerciseMetric.reason) ||
        (type == QuestionType.target && metric != ExerciseMetric.vision) ||
        (type == QuestionType.cell &&
            metric != ExerciseMetric.movement &&
            metric != ExerciseMetric.position) ||
        (type == QuestionType.choice &&
            ![
              ExerciseMetric.vision,
              ExerciseMetric.distance,
              ExerciseMetric.range,
            ].contains(metric)) ||
        (type == QuestionType.manual && manualGuide.trim().isEmpty) ||
        (type != QuestionType.manual && this.expected.isEmpty) ||
        ([QuestionType.choice, QuestionType.justification].contains(type) &&
            this.options.length < 2)) {
      throw ArgumentError(
        'Tipo, corrector o solución de ejercicio incompatibles.',
      );
    }
  }
  final String id,
      title,
      instruction,
      explanation,
      sourceId,
      targetId,
      manualGuide,
      snapshotId;
  final SkillCategory category;
  final Difficulty difficulty;
  final QuestionType type;
  final ExerciseMetric metric;
  final RuleSetVersion rules;
  final int revision;
  final bool personal;
  final VisionSnapshot world;
  final List<Team> teams;
  final CellCoordinate? origin, destination;
  final List<ExerciseOption> options;
  final Set<String> expected;
  final List<CellCoordinate> candidates, solutionRoute;
  final List<String> hints, references;
  final DateTime createdAt;
  String get progressKey => '$id@$revision@${rules.value}';
}

enum AnswerKind { choice, target, cell, route, text }

final class Answer {
  Answer(
    this.kind, {
    this.value = '',
    Iterable<CellCoordinate> route = const [],
  }) : route = List.unmodifiable(route) {
    if (value.length > 2000 || this.route.length > 102) {
      throw ArgumentError('Respuesta demasiado grande.');
    }
  }
  final AnswerKind kind;
  final String value;
  final List<CellCoordinate> route;
  bool get empty =>
      kind == AnswerKind.route ? route.length < 2 : value.trim().isEmpty;
}

enum EvaluationOutcome { correct, incorrect, notEvaluated, manual, incomplete }

final class Feedback {
  Feedback(
    this.explanation, {
    this.solution = '',
    Iterable<String> references = const [],
    Iterable<String> evidence = const [],
  }) : references = List.unmodifiable(references),
       evidence = List.unmodifiable(evidence);
  final String explanation, solution;
  final List<String> references, evidence;
}

final class Evaluation {
  const Evaluation(this.outcome, this.feedback);
  final EvaluationOutcome outcome;
  final Feedback feedback;
  bool get recordable => [
    EvaluationOutcome.correct,
    EvaluationOutcome.incorrect,
    EvaluationOutcome.manual,
  ].contains(outcome);
}

final class ExerciseCheck {
  ExerciseCheck({
    required this.eligible,
    required this.reason,
    Iterable<String> actual = const [],
    Iterable<String> evidence = const [],
    this.manual = false,
  }) : actual = Set.unmodifiable(actual),
       evidence = List.unmodifiable(evidence);
  final bool eligible, manual;
  final String reason;
  final Set<String> actual;
  final List<String> evidence;
}

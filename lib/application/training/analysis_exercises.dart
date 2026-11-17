import 'dart:isolate';

import '../board/board_session.dart';
import '../scenarios/scenario_document.dart';
import '../../domain/board/cell_coordinate.dart';
import '../../domain/rules/line_of_sight.dart';
import '../../domain/training/exercise.dart';
import '../../domain/training/exercise_evaluator.dart';
import '../../domain/tactics/tactical_diagnostic.dart';

final class AnalysisExerciseRequest {
  const AnalysisExerciseRequest(
    this.original,
    this.sourceId,
    this.rulesVersion,
    this.selected,
    this.current,
    this.candidates,
    this.targetId,
    this.routeQuestion,
  );
  final BoardSession original;
  final String sourceId, rulesVersion;
  final TacticalCandidate selected;
  final PositionDiagnostic current;
  final List<TacticalCandidate> candidates;
  final String? targetId;
  final bool routeQuestion;
}

Future<Exercise> buildAnalysisExercise(AnalysisExerciseRequest r) =>
    Isolate.run(
      () => exerciseFromAnalysis(
        original: r.original,
        sourceId: r.sourceId,
        rulesVersion: r.rulesVersion,
        selected: r.selected,
        current: r.current,
        candidates: r.candidates,
        targetId: r.targetId,
        routeQuestion: r.routeQuestion,
      ),
    );

/// Ejecutable en isolate. Usa resultados tipados y vuelve a comprobar soluciones
/// con el corrector del Entrenador; nunca guarda una respuesta elegida a ojo.
Exercise exerciseFromAnalysis({
  required BoardSession original,
  required String sourceId,
  required String rulesVersion,
  required TacticalCandidate selected,
  required PositionDiagnostic current,
  required Iterable<TacticalCandidate> candidates,
  String? targetId,
  bool routeQuestion = true,
}) {
  if (selected.status != CandidateStatus.legal ||
      selected.route == null ||
      !selected.route!.canConfirm) {
    throw const FormatException('Selecciona un destino con ruta verificada.');
  }
  final snapshot = VisionSnapshot(
    dimensions: original.dimensions,
    characters: original.characters.all,
    terrain: original.terrain,
    walls: original.walls,
  );
  final routes = <CellCoordinate, List<CellCoordinate>>{
    current.cell: [current.cell],
  };
  final diagnostics = <CellCoordinate, PositionDiagnostic>{
    current.cell: current,
  };
  for (final c in [selected, ...candidates]) {
    if (c.status == CandidateStatus.legal &&
        c.position != null &&
        routes.length < 4) {
      routes[c.cell] = c.route!.route;
      diagnostics[c.cell] = c.position!;
    }
  }
  final expected = <String>{};
  if (!routeQuestion) {
    if (targetId == null) {
      throw const FormatException('Selecciona el enemigo de la pregunta.');
    }
    for (final entry in diagnostics.entries) {
      final enemy = entry.value.enemies
          .where((e) => e.id == targetId)
          .firstOrNull;
      if (enemy == null || enemy.outgoing.canSee == null) {
        throw const FormatException(
          'Visión del objetivo No evaluada en alguna posición.',
        );
      }
      if (enemy.outgoing.canSee == true) expected.add(entry.key.label);
    }
    if (expected.isEmpty || expected.length == routes.length) {
      throw const FormatException(
        'Hace falta contraste: alguna posición debe ver al objetivo y otra no. Prueba otra página u objetivo.',
      );
    }
  }
  final e = Exercise(
    id: 'personal-${ScenarioDocument.newId().substring(2)}',
    personal: true,
    title: routeQuestion
        ? 'Llegar a ${selected.cell.label}'
        : 'Visión desde posiciones comparadas',
    instruction: routeQuestion
        ? 'Traza una ruta legal del origen hasta ${selected.cell.label} dentro de la velocidad declarada.'
        : 'Elige una posición desde la que el activo vea al objetivo indicado. Las rutas de acceso ya están verificadas. Obstaculizada también es visible; no se pregunta por alcance.',
    category: routeQuestion ? SkillCategory.movement : SkillCategory.position,
    difficulty: Difficulty.advanced,
    type: routeQuestion ? QuestionType.route : QuestionType.choice,
    metric: routeQuestion
        ? ExerciseMetric.movement
        : ExerciseMetric.visibilityFromPositions,
    world: snapshot,
    teams: original.teams,
    rules: RuleSetVersion(rulesVersion),
    createdAt: DateTime.now().toUtc(),
    snapshotId: ScenarioDocument.newId(),
    sourceId: sourceId,
    targetId: targetId ?? '',
    destination: routeQuestion ? selected.cell : null,
    candidates: routeQuestion ? const [] : routes.keys,
    candidateRoutes: routeQuestion ? const {} : routes,
    options: routeQuestion
        ? const []
        : [for (final c in routes.keys) ExerciseOption(c.label, c.label)],
    expected: routeQuestion ? const ['valid'] : expected,
    solutionRoute: routeQuestion ? selected.route!.route : const [],
    hints: const [
      'Comprueba por separado la ruta de acceso y la línea hacia el destino.',
    ],
    references: const ['10.2', '11.4', '11.5'],
    explanation: routeQuestion
        ? 'Se acepta cualquier ruta verificada al destino dentro del presupuesto.'
        : 'Se comparan las posiciones mediante los servicios de movimiento y visión. La visibilidad no garantiza un ataque legal.',
  );
  final proof = const ExerciseEvaluator().check(e);
  if (!proof.eligible) {
    throw FormatException('No puede autocorregirse: ${proof.reason}');
  }
  return e;
}

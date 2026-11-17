import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/domain/training/curated_exercises.dart';
import 'package:heroclix_simulator_trainer/domain/training/exercise.dart';
import 'package:heroclix_simulator_trainer/domain/training/exercise_evaluator.dart';
import 'package:heroclix_simulator_trainer/domain/characters/character.dart';
import 'package:heroclix_simulator_trainer/domain/characters/vision_ability.dart';
import 'package:heroclix_simulator_trainer/application/training/personal_exercise.dart';

import 'support/training_fixtures.dart';

void main() {
  const evaluator = ExerciseEvaluator();
  test('banco versionado de 24 IDs estables, seis categorías, tres dificultades y cinco tipos', () {
    expect(curatedBankVersion, 1);
    expect(curatedExercises.length, 24);
    expect(curatedExercises.map((e) => e.id).toSet().length, 24);
    for (final category in SkillCategory.values) {
      expect(curatedExercises.where((e) => e.category == category).length, 4);
    }
    expect(
      curatedExercises.map((e) => e.difficulty).toSet(),
      Difficulty.values.toSet(),
    );
    expect(curatedExercises.map((e) => e.type).toSet().length, 5);
  });
  for (final e in curatedExercises) {
    test(
      '${e.id}: solución guardada coincide con motores y la respuesta correcta explica',
      () {
        final proof = evaluator.check(e);
        expect(
          proof.eligible,
          true,
          reason: '${proof.reason}: ${proof.actual}',
        );
        final result = evaluator.evaluate(e, correctTrainingAnswer(e));
        expect(result.outcome, EvaluationOutcome.correct);
        expect(result.feedback.explanation, isNotEmpty);
        expect(result.feedback.references, isNotEmpty);
        expect(result.feedback.evidence, isNotEmpty);
      },
    );
  }
  for (final id in [
    'hc10-v02',
    'hc10-t01',
    'hc10-v04',
    'hc10-m03',
    'hc10-m02',
  ]) {
    test(
      '$id: respuesta errada en cada uno de los cinco tipos conserva explicación',
      () {
        final e = trainingExercise(id);
        final answer = switch (e.type) {
          QuestionType.choice || QuestionType.justification => Answer(
            AnswerKind.choice,
            value: e.options.firstWhere((o) => !e.expected.contains(o.id)).id,
          ),
          QuestionType.target => Answer(AnswerKind.target, value: 'figure-1'),
          QuestionType.cell => Answer(AnswerKind.cell, value: 'D4'),
          QuestionType.route => Answer(
            AnswerKind.route,
            route: [tc('A1'), tc('C1')],
          ),
          _ => throw StateError('Tipo inesperado'),
        };
        final result = evaluator.evaluate(e, answer);
        expect(result.outcome, EvaluationOutcome.incorrect);
        expect(result.feedback.solution, isNotEmpty);
        expect(result.feedback.references, isNotEmpty);
      },
    );
  }
  test('solución obsoleta y regla distinta inhabilitan, sin recalificación silenciosa', () {
    final bad = personalFixture(wrongGolden: true),
        future = personalFixture(version: 'futura');
    for (final e in [bad, future]) {
      expect(evaluator.check(e).eligible, false);
      expect(
        evaluator
            .evaluate(e, Answer(AnswerKind.choice, value: 'clear'))
            .outcome,
        EvaluationOutcome.notEvaluated,
      );
    }
    expect(
      const ExerciseEvaluator(activeVersion: RuleSetVersion('futura'))
          .check(curatedExercises.first)
          .eligible,
      false,
    );
  });
  test(
    'motor No evaluado inhabilita el ejercicio; no se transforma en incorrecto',
    () {
      var scenario = trainingScenario();
      final f = scenario.session.characters.byId('figure-1')!;
      scenario = scenario.revised(
        session: scenario.session.editCharacter(
          f.id,
          CharacterDraft(
            name: f.name,
            teamId: f.teamId,
            position: f.position,
            abilities: [VisionAbility.other],
          ),
        ),
      );
      final e = personalExercise(
        id: 'personal-22222222222222222222222222222222',
        title: 'Sin soporte',
        instruction: '¿Se ve?',
        scenario: scenario,
        category: SkillCategory.vision,
        difficulty: Difficulty.advanced,
        type: QuestionType.choice,
        metric: ExerciseMetric.vision,
        explanation: 'Pendiente.',
        options: const [
          ExerciseOption('clear', 'Sí'),
          ExerciseOption('blocked', 'No'),
        ],
        expected: ['clear'],
        sourceId: 'figure-1',
        targetId: 'figure-2',
      );
      expect(evaluator.check(e).eligible, false);
      expect(
        evaluator
            .evaluate(e, Answer(AnswerKind.choice, value: 'clear'))
            .recordable,
        false,
      );
    },
  );
  test('personal automático verifica; texto libre siempre revisión manual', () {
    final automatic = personalFixture(), manual = personalFixture(manual: true);
    expect(
      evaluator.evaluate(automatic, correctTrainingAnswer(automatic)).outcome,
      EvaluationOutcome.correct,
    );
    final r = evaluator.evaluate(manual, correctTrainingAnswer(manual));
    expect(r.outcome, EvaluationOutcome.manual);
    expect(r.feedback.solution, manual.manualGuide);
    expect(
      evaluator.evaluate(automatic, Answer(AnswerKind.choice)).outcome,
      EvaluationOutcome.incomplete,
    );
  });
  test(
    'otra ruta legal se acepta; no obliga a copiar la solución de regresión',
    () {
      final e = trainingExercise('hc10-m01');
      final r = evaluator.evaluate(
        e,
        Answer(AnswerKind.route, route: ['A1', 'B2', 'C2', 'D1'].map(tc)),
      );
      expect(r.outcome, EvaluationOutcome.correct);
    },
  );
}

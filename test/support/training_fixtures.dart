import 'package:heroclix_simulator_trainer/application/scenarios/scenario_document.dart';
import 'package:heroclix_simulator_trainer/application/training/personal_exercise.dart';
import 'package:heroclix_simulator_trainer/application/training/training_codec.dart';
import 'package:heroclix_simulator_trainer/domain/training/curated_exercises.dart';
import 'package:heroclix_simulator_trainer/domain/training/exercise.dart';

Exercise trainingExercise(String id) =>
    curatedExercises.singleWhere((e) => e.id == id);
ScenarioDocument trainingScenario() => ScenarioDocument.fresh(
  name: 'Escenario personal',
  session: TrainingCodec.session(curatedExercises.first),
);
Exercise personalFixture({
  bool manual = false,
  String version = '2026-07-01',
  bool wrongGolden = false,
  String id = 'personal-11111111111111111111111111111111',
}) => personalExercise(
  id: id,
  title: manual ? 'Razonamiento propio' : 'Visión personal',
  instruction: manual ? 'Explica tu decisión.' : '¿Cómo es la visión de A a B?',
  scenario: trainingScenario().revised(rulesVersion: version),
  category: SkillCategory.vision,
  difficulty: Difficulty.basic,
  type: manual ? QuestionType.manual : QuestionType.choice,
  metric: manual ? ExerciseMetric.manual : ExerciseMetric.vision,
  explanation: 'Escenario libre con ambos extremos normales.',
  sourceId: 'figure-1',
  targetId: 'figure-2',
  options: manual
      ? const []
      : const [
          ExerciseOption('clear', 'Despejada propia'),
          ExerciseOption('blocked', 'Bloqueada propia'),
        ],
  expected: manual ? const [] : [wrongGolden ? 'blocked' : 'clear'],
  manualGuide: manual ? 'Compara los obstáculos y explica tu criterio.' : '',
  hints: ['Revisa los extremos.'],
);
Answer correctTrainingAnswer(Exercise e) => switch (e.type) {
  QuestionType.choice || QuestionType.justification => Answer(
    AnswerKind.choice,
    value: e.expected.first,
  ),
  QuestionType.target => Answer(AnswerKind.target, value: e.expected.first),
  QuestionType.cell => Answer(AnswerKind.cell, value: e.expected.first),
  QuestionType.route => Answer(AnswerKind.route, route: e.solutionRoute),
  QuestionType.manual => Answer(
    AnswerKind.text,
    value: 'Mi razonamiento para revisar.',
  ),
};

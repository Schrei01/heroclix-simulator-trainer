import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/application/training/training_repository.dart';
import 'package:heroclix_simulator_trainer/domain/training/exercise.dart';
import 'package:heroclix_simulator_trainer/presentation/training/training_controller.dart';

import 'support/training_fixtures.dart';
import 'support/scenario_fakes.dart';

void main() {
  Future<TrainingController> setup(MemoryStore store) async {
    final c = TrainingController(TrainingRepository(store));
    addTearDown(c.dispose);
    await c.initialize();
    return c;
  }

  test('reinicio restaura intentos, porcentaje, completados, último intento y pista', () async {
    final store = MemoryStore(),
        c = await setup(store),
        e = trainingExercise('hc10-v01');
    await c.submit(e, Answer(AnswerKind.choice, value: 'blocked'), 'try-1');
    await c.submit(e, correctTrainingAnswer(e), 'try-2', usedHint: true);
    final restarted = await setup(store),
        stats = restarted.stats(SkillCategory.vision);
    expect(stats.attempts, 2);
    expect(stats.correct, 1);
    expect(stats.percentage, 50);
    expect(stats.completed, 1);
    expect(restarted.progress(e)!.lastAt.isUtc, true);
    expect(restarted.progress(e)!.usedHint, true);
    expect(restarted.last(e)!.lastAnswer.value, 'clear');
  });
  test(
    'practicar errores solo último fallo elegible, excluye manual y obsoleto',
    () async {
      final c = await setup(MemoryStore()),
          a = trainingExercise('hc10-v01'),
          b = trainingExercise('hc10-v02');
      await c.submit(a, Answer(AnswerKind.choice, value: 'blocked'), 'wrong-a');
      await c.submit(b, correctTrainingAnswer(b), 'right-b');
      expect(c.exercises.where(c.isMistake).map((e) => e.id), [a.id]);
      await c.submit(a, correctTrainingAnswer(a), 'right-a');
      expect(c.exercises.where(c.isMistake), isEmpty);
      final manual = personalFixture(manual: true);
      await c.add(manual);
      await c.submit(manual, correctTrainingAnswer(manual), 'manual');
      expect(c.isMistake(manual), false);
    },
  );
  test('revisión y reinicio de pregunta no escriben; token repetido no duplica intento', () async {
    final store = MemoryStore(),
        c = await setup(store),
        e = trainingExercise('hc10-v01');
    await c.submit(e, correctTrainingAnswer(e), 'same-token');
    final writes = store.writes;
    c.last(e);
    c.check(e);
    c.stats(SkillCategory.vision);
    expect(store.writes, writes);
    await c.submit(e, correctTrainingAnswer(e), 'same-token');
    expect(c.progress(e)!.attempts, 1);
  });
  test('manual cuenta revisión sin contaminar porcentaje; reset conserva personales', () async {
    final store = MemoryStore(),
        c = await setup(store),
        manual = personalFixture(manual: true),
        e = trainingExercise('hc10-v01');
    await c.add(manual);
    await c.submit(e, correctTrainingAnswer(e), 'a');
    await c.submit(manual, correctTrainingAnswer(manual), 'b');
    final stats = c.stats(SkillCategory.vision);
    expect(stats.attempts, 2);
    expect(stats.manualReviews, 1);
    expect(stats.percentage, 100);
    expect(stats.completed, 1);
    await c.reset();
    expect(c.repository.data.progress, isEmpty);
    expect(c.repository.data.personal.single.id, manual.id);
    final again = await setup(store);
    expect(again.repository.data.personal.length, 1);
    expect(again.repository.data.progress, isEmpty);
  });
  test('fallo de escritura conserva datos y permite reintentar sin contar dos veces', () async {
    final store = MemoryStore(),
        c = await setup(store),
        e = trainingExercise('hc10-v01');
    store.failWrite = true;
    expect(await c.submit(e, correctTrainingAnswer(e), 'retry'), isNull);
    expect(c.progress(e), isNull);
    expect(c.error, isNotNull);
    store.failWrite = false;
    await c.submit(e, correctTrainingAnswer(e), 'retry');
    expect(c.progress(e)!.attempts, 1);
  });
  test('No evaluado o solución incorrecta no suma intentos ni guarda ejercicio automático', () async {
    final store = MemoryStore(),
        c = await setup(store),
        bad = personalFixture(wrongGolden: true);
    final r = await c.submit(
      bad,
      Answer(AnswerKind.choice, value: 'clear'),
      'no-eval',
    );
    expect(r!.outcome, EvaluationOutcome.notEvaluated);
    expect(store.writes, 0);
    expect(await c.add(bad), false);
    expect(c.repository.data.personal, isEmpty);
  });
  test('cambio de edición conserva revisión vieja sin calificarla con el corrector nuevo', () async {
    final store = MemoryStore(),
        c = await setup(store),
        old = personalFixture();
    await c.add(old);
    await c.submit(old, correctTrainingAnswer(old), 'old');
    final future = personalFixture(version: 'futura');
    expect(c.check(future).eligible, false);
    expect(c.last(future)!.rulesVersion, '2026-07-01');
    expect(c.progress(future), isNull);
    final writes = store.writes;
    expect(
      (await c.submit(
        future,
        correctTrainingAnswer(future),
        'future',
      ))!.outcome,
      EvaluationOutcome.notEvaluated,
    );
    expect(store.writes, writes);
  });
}

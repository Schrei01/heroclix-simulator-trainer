import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/application/training/analysis_exercises.dart';
import 'package:heroclix_simulator_trainer/application/training/training_codec.dart';
import 'package:heroclix_simulator_trainer/application/training/training_repository.dart';
import 'package:heroclix_simulator_trainer/domain/tactics/tactical_analysis_service.dart';
import 'package:heroclix_simulator_trainer/domain/tactics/tactical_diagnostic.dart';
import 'package:heroclix_simulator_trainer/domain/training/exercise.dart';
import 'package:heroclix_simulator_trainer/domain/training/exercise_evaluator.dart';

import 'support/tactics_contract.dart';
import 'support/vision_contract.dart';
import 'support/scenario_fakes.dart';
import 'support/training_fixtures.dart';
import 'vision_state_test.dart' show visionSession;

void main() {
  AnalysisExerciseRequest request(bool route) {
    const s = TacticalAnalysisService(), ctx = TacticalContext();
    final world = tacticalWorld();
    final current = s.inspect(world, 'figure-1', ctx),
        candidate = s.candidate(world, 'figure-1', vc('B2'), ctx);
    return AnalysisExerciseRequest(
      visionSession(world),
      'figure-1',
      '2026-07-01',
      candidate,
      current,
      [candidate],
      'figure-2',
      route,
    );
  }

  for (final route in [true, false]) {
    test(
      'ejercicio generado ${route ? 'ruta' : 'visibilidad'} en isolate, persistencia y corrector reales',
      () async {
        final e = await buildAnalysisExercise(request(route));
        expect(const ExerciseEvaluator().check(e).eligible, true);
        final result = const ExerciseEvaluator().evaluate(
          e,
          correctTrainingAnswer(e),
        );
        expect(result.outcome, EvaluationOutcome.correct);
        final store = MemoryStore(), repo = TrainingRepository(store);
        await repo.load();
        await repo.add(e);
        final again = TrainingRepository(store);
        await again.load();
        final restored = again.data.personal.single;
        expect(restored.id, e.id);
        expect(
          const ExerciseEvaluator()
              .evaluate(restored, correctTrainingAnswer(restored))
              .outcome,
          EvaluationOutcome.correct,
        );
        if (!route) {
          expect(restored.candidateRoutes.length, 2);
          expect(restored.expected, {'B2'});
          expect(
            const ExerciseEvaluator()
                .evaluate(restored, Answer(AnswerKind.choice, value: 'A1'))
                .outcome,
            EvaluationOutcome.incorrect,
          );
        }
      },
    );
  }
  test('formato 2 de 10 migra sin perder progreso/personales y respalda antes de reemplazar', () async {
    final store = MemoryStore(), repo = TrainingRepository(store);
    await repo.load();
    final e = personalFixture();
    await repo.add(e);
    await repo.record(
      e,
      correctTrainingAnswer(e),
      const ExerciseEvaluator().evaluate(e, correctTrainingAnswer(e)),
      'previous',
    );
    final map = jsonDecode(store.documents['working']!) as Map<String, dynamic>;
    map['trainingSchemaVersion'] = 2;
    for (final e in map['personalExercises'] as List) {
      (e as Map).remove('candidateRoutes');
    }
    final raw = jsonEncode(map);
    store.documents['working'] = raw;
    store.writes = 0;
    final migrated = TrainingRepository(store);
    await migrated.load();
    expect(store.writes, 0);
    expect(migrated.data.progress.single.correct, 1);
    final generated = await buildAnalysisExercise(request(true));
    await migrated.add(generated);
    expect(store.documents['schema2-working'], raw);
    expect(migrated.data.personal.length, 2);
    expect(migrated.data.progress.single.correct, 1);
    expect(jsonDecode(store.documents['working']!)['trainingSchemaVersion'], 3);
  });
  test('fallo de respaldo 2 conserva original', () async {
    final store = MemoryStore(),
        map = const TrainingCodec().toMap(
          TrainingData(personal: [personalFixture()]),
        );
    map['trainingSchemaVersion'] = 2;
    final raw = jsonEncode(map);
    store.documents['working'] = raw;
    final repo = TrainingRepository(store);
    await repo.load();
    store.failWrite = true;
    await expectLater(
      repo.resetProgress(),
      throwsA(isA<FileSystemException>()),
    );
    expect(store.documents['working'], raw);
  });
  test(
    'rutas alteradas o duplicadas impiden autocorrección/importación',
    () async {
      const codec = TrainingCodec();
      final e = await buildAnalysisExercise(request(false)),
          map = codec.exerciseMap(e);
      final routes = map['candidateRoutes'] as List;
      (routes.last as Map)['route'] = ['A1', 'D4', 'B2'];
      final altered = codec.exerciseFrom(map);
      expect(const ExerciseEvaluator().check(altered).eligible, false);
      routes.add(routes.first);
      expect(() => codec.exerciseFrom(map), throwsFormatException);
    },
  );
}

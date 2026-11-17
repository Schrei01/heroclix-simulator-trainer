// ignore_for_file: avoid_print
import 'package:heroclix_simulator_trainer/domain/training/curated_exercises.dart';
import 'package:heroclix_simulator_trainer/domain/training/exercise_evaluator.dart';

void main() {
  var passed = 0;
  for (final e in curatedExercises) {
    final proof = const ExerciseEvaluator().check(e);
    if (!proof.eligible || proof.manual) {
      throw StateError(
        '${e.id}: ${proof.reason}; motor ${proof.actual}, esperado ${e.expected}',
      );
    }
    print('OK ${e.id}: ${proof.actual.join(', ')}');
    passed++;
  }
  print(
    '$passed/${curatedExercises.length} soluciones del banco verificadas con los motores existentes.',
  );
}

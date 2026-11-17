import 'package:flutter/foundation.dart';

import '../../application/training/training_repository.dart';
import '../../application/scenarios/scenario_repository.dart';
import '../../domain/training/curated_exercises.dart';
import '../../domain/training/exercise.dart';
import '../../domain/training/exercise_evaluator.dart';
import '../../domain/training/progress.dart';

final class TrainingController extends ChangeNotifier {
  TrainingController(
    this.repository, {
    this.scenarios,
    this.evaluator = const ExerciseEvaluator(),
  });
  final TrainingRepository repository;
  final ScenarioRepository? scenarios;
  final ExerciseEvaluator evaluator;
  bool loading = true, busy = false, _closed = false, _ready = false;
  String? error;
  Future<void>? _initializing;
  final _checks = <Exercise, ExerciseCheck>{};
  List<Exercise> get exercises => [
    ...curatedExercises,
    ...repository.data.personal,
  ];
  bool get ready => _ready && !loading;
  void _changed() {
    if (!_closed) notifyListeners();
  }

  Future<void> initialize({bool reload = false}) {
    if (_initializing != null) return _initializing!;
    if (_ready && !reload) return Future.value();
    final future = _load();
    _initializing = future;
    return future.whenComplete(() => _initializing = null);
  }

  Future<void> _load() async {
    loading = true;
    error = null;
    _changed();
    try {
      await repository.load();
      _ready = true;
      _checks.clear();
    } catch (e) {
      _ready = false;
      error =
          'No se pudo abrir el progreso. El archivo original se conserva. $e';
    } finally {
      loading = false;
      _changed();
    }
  }

  ExerciseCheck check(Exercise e) =>
      _checks.putIfAbsent(e, () => evaluator.check(e));
  ExerciseProgress? progress(Exercise e) =>
      repository.data.progress.where((p) => p.key == e.progressKey).firstOrNull;
  ExerciseProgress? last(Exercise e) {
    final records =
        repository.data.progress.where((p) => p.exerciseId == e.id).toList()
          ..sort((a, b) => b.lastAt.compareTo(a.lastAt));
    return records.firstOrNull;
  }

  CategoryProgress stats(SkillCategory category) => CategoryProgress(
    repository.data.progress.where(
      (p) =>
          p.category == category &&
          p.rulesVersion == evaluator.activeVersion.value,
    ),
  );
  bool isMistake(Exercise e) =>
      check(e).eligible &&
      !check(e).manual &&
      progress(e)?.lastEvaluation.outcome == EvaluationOutcome.incorrect;
  Future<Evaluation?> submit(
    Exercise e,
    Answer answer,
    String token, {
    bool usedHint = false,
  }) async {
    if (!ready || busy) return null;
    final result = evaluator.evaluate(e, answer);
    if (!result.recordable) return result;
    busy = true;
    error = null;
    _changed();
    try {
      await repository.record(e, answer, result, token, usedHint: usedHint);
      return result;
    } catch (e) {
      error =
          'No se guardó el intento; las estadísticas anteriores se conservan. Vuelve a comprobar. $e';
      return null;
    } finally {
      busy = false;
      _changed();
    }
  }

  Future<bool> add(Exercise e) async {
    if (!ready || busy) return false;
    final proof = evaluator.check(e);
    if (!proof.eligible) {
      error = 'No puede guardarse para autocorrección: ${proof.reason}';
      _changed();
      return false;
    }
    busy = true;
    error = null;
    _changed();
    try {
      await repository.add(e);
      return true;
    } catch (e) {
      error = 'No se guardó el ejercicio. $e';
      return false;
    } finally {
      busy = false;
      _changed();
    }
  }

  Future<void> reset() async {
    if (!ready || busy) return;
    busy = true;
    error = null;
    _changed();
    try {
      await repository.resetProgress();
    } catch (e) {
      error = 'No se reiniciaron las estadísticas. $e';
    } finally {
      busy = false;
      _changed();
    }
  }

  Future<void> flush() => repository.settled;
  void generatedExerciseAdded() {
    _checks.clear();
    _changed();
  }

  @override
  void dispose() {
    _closed = true;
    super.dispose();
  }
}

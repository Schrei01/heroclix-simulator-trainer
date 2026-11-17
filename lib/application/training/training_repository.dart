import 'dart:convert';

import '../../domain/training/exercise.dart';
import '../../domain/training/progress.dart';
import '../ports/local_document_store.dart';
import 'training_codec.dart';

/// Raíz privada distinta de escenarios. Publica estado solo tras escritura atómica.
final class TrainingRepository {
  TrainingRepository(this.store, {this.codec = const TrainingCodec()});
  final LocalDocumentStore store;
  final TrainingCodec codec;
  TrainingData data = TrainingData();
  bool _loaded = false;
  String? _legacy;
  int? _legacyVersion;
  Future<void> _tail = Future.value();
  Future<void> get settled => _tail;
  Future<T> _queue<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> load() => _queue(() async {
    _loaded = false;
    final raw = await store.read('working');
    final next = raw == null ? TrainingData() : codec.decode(raw);
    _legacyVersion = raw == null
        ? null
        : (jsonDecode(raw) as Map)['trainingSchemaVersion'] as int;
    _legacy = (_legacyVersion == 1 || _legacyVersion == 2) ? raw : null;
    data = next;
    _loaded = true;
  });
  Future<void> _write(TrainingData next) async {
    if (!_loaded) throw StateError('Abre el progreso antes de guardarlo.');
    final raw = codec.encode(next);
    if (_legacy != null &&
        await store.read('schema$_legacyVersion-working') == null) {
      await store.write('schema$_legacyVersion-working', _legacy!);
    }
    await store.write('working', raw);
    data = next;
    _legacy = null;
  }

  Future<void> add(Exercise exercise) => _queue(() async {
    if (!exercise.personal || data.personal.any((e) => e.id == exercise.id)) {
      throw ArgumentError('Identidad de ejercicio inválida o repetida.');
    }
    await _write(
      TrainingData(
        personal: [...data.personal, exercise],
        progress: data.progress,
      ),
    );
  });
  Future<void> record(
    Exercise e,
    Answer answer,
    Evaluation evaluation,
    String attemptId, {
    bool usedHint = false,
    DateTime? at,
  }) => _queue(() async {
    if (!evaluation.recordable) {
      throw ArgumentError('Respuesta sin corregir; no altera estadísticas.');
    }
    if (data.progress.any((p) => p.lastAttemptId == attemptId)) return;
    final old = data.progress.where((p) => p.key == e.progressKey).firstOrNull;
    final next = ExerciseProgress(
      exerciseId: e.id,
      revision: e.revision,
      rulesVersion: e.rules.value,
      category: e.category,
      attempts: (old?.attempts ?? 0) + 1,
      correct:
          (old?.correct ?? 0) +
          (evaluation.outcome == EvaluationOutcome.correct ? 1 : 0),
      manualReviews:
          (old?.manualReviews ?? 0) +
          (evaluation.outcome == EvaluationOutcome.manual ? 1 : 0),
      lastAt: at ?? DateTime.now().toUtc(),
      lastAttemptId: attemptId,
      lastAnswer: answer,
      lastEvaluation: evaluation,
      usedHint: usedHint,
    );
    await _write(
      TrainingData(
        personal: data.personal,
        progress: [...data.progress.where((p) => p.key != e.progressKey), next],
      ),
    );
  });
  Future<void> resetProgress() =>
      _queue(() => _write(TrainingData(personal: data.personal)));
}

/// Solo para composición sin plataforma y pruebas; main inyecta archivos privados.
final class SessionTrainingStore implements LocalDocumentStore {
  final _values = <String, String>{};
  @override
  Future<String?> read(String id) async => _values[id];
  @override
  Future<void> write(String id, String document) async {
    _values[id] = document;
  }

  @override
  Future<void> delete(String id) async {
    _values.remove(id);
  }

  @override
  Future<List<String>> listIds() async => _values.keys.toList();
}

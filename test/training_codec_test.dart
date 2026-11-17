import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/application/training/training_codec.dart';
import 'package:heroclix_simulator_trainer/application/training/training_repository.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_codec.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_repository.dart';
import 'package:heroclix_simulator_trainer/domain/training/exercise_evaluator.dart';
import 'package:heroclix_simulator_trainer/infrastructure/local/file_document_store.dart';

import 'support/training_fixtures.dart';
import 'support/scenario_fakes.dart';

void main() {
  const codec = TrainingCodec();
  test('roundtrip determinista con snapshot, opciones, guía y capacidades', () {
    final data = TrainingData(
      personal: [
        personalFixture(),
        personalFixture(
          manual: true,
          id: 'personal-22222222222222222222222222222222',
        ),
      ],
    );
    final raw = codec.encode(data), restored = codec.decode(raw);
    expect(codec.encode(restored), raw);
    expect(restored.personal.first.options.first.label, 'Despejada propia');
    expect(
      const ExerciseEvaluator().check(restored.personal.first).eligible,
      true,
    );
    expect(restored.personal.last.manualGuide, isNotEmpty);
  });
  test(
    'esquema 1 migra revisión/pista sin perder progreso ni copia original',
    () async {
      final store = MemoryStore(), repo = TrainingRepository(store);
      await repo.load();
      final e = personalFixture();
      await repo.add(e);
      await repo.record(
        e,
        correctTrainingAnswer(e),
        const ExerciseEvaluator().evaluate(e, correctTrainingAnswer(e)),
        'legacy-try',
      );
      final map =
          jsonDecode(store.documents['working']!) as Map<String, dynamic>;
      map['trainingSchemaVersion'] = 1;
      for (final p in map['progress'] as List) {
        (p as Map).remove('revision');
        p.remove('usedHint');
      }
      final raw = jsonEncode(map);
      store.documents['working'] = raw;
      store.writes = 0;
      final migrated = TrainingRepository(store);
      await migrated.load();
      expect(store.writes, 0);
      expect(migrated.data.progress.single.revision, 1);
      expect(migrated.data.progress.single.usedHint, false);
      expect(migrated.data.progress.single.correct, 1);
      await migrated.resetProgress();
      expect(store.documents['schema1-working'], raw);
      expect(migrated.data.personal.single.id, e.id);
      expect(
        jsonDecode(store.documents['working']!)['trainingSchemaVersion'],
        2,
      );
    },
  );
  test('fallar respaldo legacy protege archivo y progreso', () async {
    final store = MemoryStore(),
        raw = jsonEncode({
          ...codec.toMap(TrainingData(personal: [personalFixture()])),
          'trainingSchemaVersion': 1,
        });
    store.documents['working'] = raw;
    final repo = TrainingRepository(store);
    await repo.load();
    store.failWrite = true;
    await expectLater(
      repo.resetProgress(),
      throwsA(isA<FileSystemException>()),
    );
    expect(store.documents['working'], raw);
    expect(repo.data.personal.length, 1);
  });
  test(
    'esquema futuro/campos desconocidos/solución duplicada no sobrescriben',
    () async {
      final base = codec.toMap(TrainingData(personal: [personalFixture()]));
      for (final corrupt in <void Function(Map<String, dynamic>)>[
        (m) => m['trainingSchemaVersion'] = 99,
        (m) => m['bankVersion'] = 99,
        (m) => m['unknown'] = true,
        (m) =>
            ((m['personalExercises'] as List).first as Map)['type'] = 'unknown',
        (m) => ((m['personalExercises'] as List).first as Map)['options'] = [
          {'id': 'clear', 'label': 'A'},
          {'id': 'clear', 'label': 'B'},
        ],
      ]) {
        final map = jsonDecode(jsonEncode(base)) as Map<String, dynamic>;
        corrupt(map);
        final raw = jsonEncode(map),
            store = MemoryStore()..documents['working'] = raw,
            repo = TrainingRepository(store);
        await expectLater(repo.load(), throwsFormatException);
        await expectLater(repo.resetProgress(), throwsStateError);
        expect(store.documents['working'], raw);
        expect(store.writes, 0);
      }
      expect(
        () => codec.decode(' ' * (TrainingCodec.maxBytes + 1)),
        throwsFormatException,
      );
    },
  );
  test('snapshot de escenario legado se migra mediante ScenarioCodec sin reglas duplicadas', () {
    final map = codec.exerciseMap(personalFixture());
    final old = jsonDecode(
      File('test/fixtures/scenario_schema1.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    map['scenario'] = old;
    final e = codec.exerciseFrom(map),
        migrated = codec.exerciseMap(e)['scenario'] as Map;
    expect(migrated['schemaVersion'], 3);
    expect(migrated['terrain'], old['terrain']);
    expect(migrated['walls'], old['walls']);
    expect(
      (migrated['characters'] as List).length,
      (old['characters'] as List).length,
    );
  });
  test('almacenamiento real separado conserva escenarios y restablece progreso', () async {
    final root = await Directory.systemTemp.createTemp('heroclix-training-');
    addTearDown(() async {
      final prefix =
          '${Directory.systemTemp.absolute.path}${Platform.pathSeparator}heroclix-training-';
      if (!root.absolute.path.startsWith(prefix)) {
        throw StateError('Directorio inesperado.');
      }
      await root.delete(recursive: true);
    });
    final scenarios = ScenarioRepository(FileDocumentStore(() async => root)),
        doc = trainingScenario();
    await scenarios.save(doc);
    final original = await scenarios.store.read(doc.id);
    FileDocumentStore store() =>
        FileDocumentStore(() async => Directory('${root.path}/training_v1'));
    final repo = TrainingRepository(store());
    await repo.load();
    final e = personalFixture();
    await repo.add(e);
    await repo.record(
      e,
      correctTrainingAnswer(e),
      const ExerciseEvaluator().evaluate(e, correctTrainingAnswer(e)),
      'disk',
    );
    final restarted = TrainingRepository(store());
    await restarted.load();
    expect(restarted.data.progress.single.correct, 1);
    expect(await scenarios.store.read(doc.id), original);
    expect((await scenarios.list()).single.id, doc.id);
    expect(const ScenarioCodec().decode(original!).id, doc.id);
  });
}

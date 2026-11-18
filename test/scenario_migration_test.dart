import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_codec.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_repository.dart';
import 'package:heroclix_simulator_trainer/domain/characters/vision_ability.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/edge_wall.dart';

import 'support/vision_contract.dart';
import 'support/scenario_fakes.dart';

import 'package:heroclix_simulator_trainer/infrastructure/local/file_document_store.dart';

void main() {
  final legacy = File('test/fixtures/scenario_schema1.json').readAsStringSync();
  const codec = ScenarioCodec();
  test('respaldo de migración en archivos reales conserva original y no aparece en biblioteca', () async {
    final directory = await Directory.systemTemp.createTemp(
      'heroclix-schema2-',
    );
    addTearDown(() async {
      final prefix =
          '${Directory.systemTemp.absolute.path}${Platform.pathSeparator}heroclix-schema2-';
      if (!directory.absolute.path.startsWith(prefix)) {
        throw StateError('Directorio temporal inesperado.');
      }
      await directory.delete(recursive: true);
    });
    final store = FileDocumentStore(() async => directory),
        doc = codec.decode(legacy);
    await store.write(doc.id, legacy);
    await ScenarioRepository(store).save(doc);
    expect(await store.read('schema1-${doc.id}'), legacy);
    expect(
      (await ScenarioRepository(store).open(doc.id)).session.characters.length,
      2,
    );
    expect(await store.listIds(), [doc.id]);
  });
  test(
    'fixture real de 07 migra de esquema 1 a 4 sin perder metadatos ni capas',
    () {
      final old = jsonDecode(legacy) as Map<String, dynamic>;
      expect(old['schemaVersion'], 1);
      final doc = codec.decode(legacy), migrated = codec.toMap(doc);
      expect(migrated['schemaVersion'], 4);
      for (final field in [
        'metadata',
        'board',
        'teams',
        'terrain',
        'walls',
        'counters',
      ]) {
        expect(migrated[field], old[field], reason: field);
      }
      for (var i = 0; i < doc.session.characters.length; i++) {
        final f = Map<String, dynamic>.from(
          (migrated['characters'] as List)[i] as Map,
        );
        expect(f.remove('size'), 'normal');
        expect(f.remove('visionAbilities'), isEmpty);
        expect(f.remove('movementAbilities'), isEmpty);
        expect(f, (old['characters'] as List)[i]);
      }
      expect(migrated['transitions'], isEmpty);
      expect(codec.encode(codec.decode(codec.encode(doc))), codec.encode(doc));
    },
  );
  test('esquema 2 conserva capacidades, tamaño y transición', () {
    var doc = codec.decode(legacy);
    var session = doc.session.paintElevation([vc('A1')], 2);
    session = session.setTransition(
      EdgeWall.between(vc('A1'), vc('A2')),
      remove: false,
    );
    final f = session.characters.byId('figure-1')!;
    session = session.editCharacter(f.id, f.data.at(f.position));
    doc = doc.revised(session: session);
    final map = codec.toMap(doc);
    ((map['characters'] as List).first as Map)['visionAbilities'] = [
      'blocking',
      'elevated',
    ];
    ((map['characters'] as List).first as Map)['size'] = 'giant';
    final restored = codec.fromMap(map);
    expect(restored.session.characters.byId('figure-1')!.abilities, {
      VisionAbility.blocking,
      VisionAbility.elevated,
    });
    expect(
      restored.session.characters.byId('figure-1')!.size,
      FigureSize.giant,
    );
    expect(restored.session.terrain.transitions.length, 1);
  });
  test(
    'antes de sobrescribir esquema 1 conserva copia exacta una sola vez',
    () async {
      final store = MemoryStore(), doc = codec.decode(legacy);
      store.documents[doc.id] = legacy;
      final repository = ScenarioRepository(store);
      expect(codec.toMap(await repository.open(doc.id))['schemaVersion'], 4);
      expect(store.documents[doc.id], legacy);
      await repository.save(doc);
      expect(store.documents['schema1-${doc.id}'], legacy);
      expect(jsonDecode(store.documents[doc.id]!)['schemaVersion'], 4);
      final backup = store.documents['schema1-${doc.id}'];
      await repository.save(doc.revised(name: 'Editado'));
      expect(store.documents['schema1-${doc.id}'], backup);
      expect(await store.listIds(), [doc.id]);
    },
  );
  test(
    'autoguardado antiguo conserva respaldo; fallo de respaldo no sobrescribe',
    () async {
      final store = MemoryStore(), doc = codec.decode(legacy);
      final raw = jsonEncode({
        'workspaceSchemaVersion': 1,
        'document': jsonDecode(legacy),
        'dirty': true,
        'saved': false,
      });
      store.documents['working'] = raw;
      final repository = ScenarioRepository(store);
      final working = (await repository.readWorking())!;
      store.failWrite = true;
      await expectLater(
        repository.saveWorking(working),
        throwsA(isA<FileSystemException>()),
      );
      expect(store.documents['working'], raw);
      store.failWrite = false;
      await repository.saveWorking(WorkingScenario(doc, true, false));
      expect(store.documents['schema1-working'], raw);
      expect(
        jsonDecode(store.documents['working']!)['document']['schemaVersion'],
        4,
      );
    },
  );
  test(
    'IDs de capacidad desconocidos o duplicados se rechazan sin perder origen',
    () {
      for (final abilities in [
        ['desconocida'],
        ['blocking', 'blocking'],
      ]) {
        final map = codec.toMap(codec.decode(legacy));
        ((map['characters'] as List).first as Map)['visionAbilities'] =
            abilities;
        expect(() => codec.fromMap(map), throwsFormatException);
      }
      expect(codec.decode(legacy).session.characters.length, 2);
    },
  );
}

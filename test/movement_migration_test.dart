import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_codec.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_repository.dart';
import 'package:heroclix_simulator_trainer/domain/characters/movement_ability.dart';
import 'package:heroclix_simulator_trainer/infrastructure/local/file_document_store.dart';

import 'support/scenario_fakes.dart';

void main() {
  const codec = ScenarioCodec();
  test('adaptador real admite respaldo esquema 2 y lo excluye de biblioteca', () async {
    final directory = await Directory.systemTemp.createTemp(
      'heroclix-schema3-',
    );
    addTearDown(() async {
      final prefix =
          '${Directory.systemTemp.absolute.path}${Platform.pathSeparator}heroclix-schema3-';
      if (!directory.absolute.path.startsWith(prefix)) {
        throw StateError('Ruta temporal inesperada.');
      }
      await directory.delete(recursive: true);
    });
    final store = FileDocumentStore(() async => directory),
        doc = codec.decode(
          File('test/fixtures/scenario_schema1.json').readAsStringSync(),
        );
    final map = codec.toMap(doc);
    map['schemaVersion'] = 2;
    for (final f in map['characters'] as List) {
      (f as Map).remove('movementAbilities');
    }
    final raw = jsonEncode(map);
    await store.write(doc.id, raw);
    await ScenarioRepository(store).save(codec.decode(raw));
    expect(await store.read('schema2-${doc.id}'), raw);
    expect(await store.listIds(), [doc.id]);
  });
  Map<String, dynamic> legacy2() {
    final map = codec.toMap(
      codec.decode(
        File('test/fixtures/scenario_schema1.json').readAsStringSync(),
      ),
    );
    map['schemaVersion'] = 2;
    for (final f in map['characters'] as List) {
      (f as Map).remove('movementAbilities');
    }
    ((map['characters'] as List).first as Map)['visionAbilities'] = [
      'blocking',
    ];
    return map;
  }

  test('esquema 2 migra a 3 conservando cada campo y añade IM vacías', () {
    final old = legacy2(),
        decoded = codec.fromMap(old),
        next = codec.toMap(decoded);
    next['schemaVersion'] = 2;
    for (final f in next['characters'] as List) {
      expect((f as Map).remove('movementAbilities'), isEmpty);
    }
    expect(next, old);
  });
  test(
    'capacidades IM persisten ordenadas; desconocidas/duplicadas se rechazan',
    () {
      final doc = codec.fromMap(legacy2()), map = codec.toMap(doc);
      final f = (map['characters'] as List).first as Map;
      f['movementAbilities'] = ['characters', 'elevated'];
      final restored = codec.fromMap(map);
      expect(restored.session.characters.byId('figure-1')!.movementAbilities, {
        MovementAbility.characters,
        MovementAbility.elevated,
      });
      expect(
        codec
            .decode(codec.encode(restored))
            .session
            .characters
            .byId('figure-1')!
            .movementAbilities,
        restored.session.characters.byId('figure-1')!.movementAbilities,
      );
      for (final caps in [
        ['unknown'],
        ['elevated', 'elevated'],
      ]) {
        f['movementAbilities'] = caps;
        expect(() => codec.fromMap(map), throwsFormatException);
      }
    },
  );
  test(
    'respaldo exacto esquema 2 antes de guardar; fallo preserva original',
    () async {
      final store = MemoryStore(),
          raw = jsonEncode(legacy2()),
          doc = codec.decode(raw);
      store.documents[doc.id] = raw;
      final repo = ScenarioRepository(store);
      await repo.open(doc.id);
      expect(store.writes, 0);
      store.failWrite = true;
      await expectLater(repo.save(doc), throwsA(isA<FileSystemException>()));
      expect(store.documents[doc.id], raw);
      store.failWrite = false;
      await repo.save(doc);
      expect(store.documents['schema2-${doc.id}'], raw);
      expect(await store.listIds(), [doc.id]);
      await repo.save(doc.revised(name: 'Editado'));
      expect(store.documents['schema2-${doc.id}'], raw);
    },
  );
  test(
    'autoguardado de esquema 2 conserva copia completa del envoltorio',
    () async {
      final store = MemoryStore(),
          raw = jsonEncode({
            'workspaceSchemaVersion': 1,
            'document': legacy2(),
            'dirty': true,
            'saved': false,
          });
      store.documents['working'] = raw;
      final repo = ScenarioRepository(store);
      final doc = (await repo.readWorking())!;
      await repo.saveWorking(doc);
      expect(store.documents['schema2-working'], raw);
      expect(
        jsonDecode(store.documents['working']!)['document']['schemaVersion'],
        3,
      );
    },
  );
}

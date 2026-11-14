import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_codec.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_document.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_repository.dart';
import 'package:heroclix_simulator_trainer/infrastructure/local/file_document_store.dart';

import 'support/scenario_fakes.dart';
import 'scenario_codec_test.dart' show sampleDocument, character, cell;

Future<Directory> testDirectory() async {
  final root = await Directory.systemTemp.createTemp('heroclix04-');
  addTearDown(() async {
    if (!await root.exists()) return;
    final resolved = await root.resolveSymbolicLinks(),
        temp = await Directory.systemTemp.resolveSymbolicLinks();
    if (!resolved.toLowerCase().startsWith(
      '$temp${Platform.pathSeparator}heroclix04-'.toLowerCase(),
    )) {
      throw StateError(
        'La limpieza no permanece en el directorio temporal de la prueba.',
      );
    }
    await root.delete(recursive: true);
  });
  return root;
}

void main() {
  const codec = ScenarioCodec();
  test('archivos reales: reemplazo íntegro, lectura tras nueva instancia y borrado por ID', () async {
    final root = await testDirectory(),
        store = FileDocumentStore(() async => root),
        repo = ScenarioRepository(FileDocumentStore(() async => root));
    final doc = sampleDocument();
    await store.write(doc.id, codec.encode(doc));
    final edited = doc.revised(name: 'Renombrado');
    await store.write(doc.id, codec.encode(edited));
    expect(codec.encode(await repo.open(doc.id)), codec.encode(edited));
    expect(await store.listIds(), [doc.id]);
    expect(
      (await root.list().toList()).where((file) => file.path.contains('.tmp-')),
      isEmpty,
    );
    await store.delete(doc.id);
    expect(await store.read(doc.id), isNull);
    await store.delete(doc.id);
  });
  test('almacenamiento rechaza rutas, bytes enormes y limpia temporal si no puede reemplazar', () async {
    final root = await testDirectory(),
        store = FileDocumentStore(() async => root);
    for (final id in [
      '../escape',
      'working/../x',
      'C:\\archivo',
      's-${'a' * 32}/x',
      'working.json',
      '',
    ]) {
      await expectLater(store.write(id, '{}'), throwsArgumentError);
      await expectLater(store.read(id), throwsArgumentError);
      await expectLater(store.delete(id), throwsArgumentError);
    }
    await expectLater(
      store.write('working', 'x' * (FileDocumentStore.maxStoredBytes + 1)),
      throwsFormatException,
    );
    await File('${root.path}${Platform.pathSeparator}working.json')
        .writeAsBytes(Uint8List(FileDocumentStore.maxStoredBytes + 1));
    await expectLater(store.read('working'), throwsFormatException);
    final id = ScenarioDocument.newId();
    await Directory('${root.path}${Platform.pathSeparator}$id.json').create();
    await expectLater(
      store.write(id, '{}'),
      throwsA(isA<FileSystemException>()),
    );
    expect(
      (await root.list().toList()).where((file) => file.path.contains('.tmp-')),
      isEmpty,
    );
  });
  test('un fallo al resolver directorio puede reintentarse', () async {
    final root = await testDirectory();
    var fail = true;
    final store = FileDocumentStore(() async {
      if (fail) throw const FileSystemException('Fallo');
      return root;
    });
    await expectLater(
      store.read('working'),
      throwsA(isA<FileSystemException>()),
    );
    fail = false;
    await store.write('working', '{}');
    expect(await store.read('working'), '{}');
  });
  test('cerrar y reconstruir controladores recupera el documento completo y vacía historial', () async {
    final store = MemoryStore(),
        controller = await persistentController(MemoryStore());
    controller.dispose();
    final first = await persistentController(store);
    first.loadScenario(sampleDocument().session);
    first.workspace!.edited(first.value);
    first.saveCharacter(character('L8'));
    await first.workspace!.flush();
    final encoded = codec.encode(first.workspace!.current);
    expect(first.history.canUndo, isTrue);
    first.dispose();
    final restored = await persistentController(store);
    addTearDown(restored.dispose);
    expect(codec.encode(restored.workspace!.current), encoded);
    expect(restored.history.canUndo, isFalse);
    expect(restored.history.canRedo, isFalse);
    expect(restored.value.characters.length, 3);
    expect(restored.value.studyConflicts, {cell('C3')});
  });
  test('nombres iguales, guardar como, renombrar, duplicar y eliminar abierto sin perder tablero', () async {
    final store = MemoryStore(), controller = await persistentController(store);
    addTearDown(controller.dispose);
    final workspace = controller.workspace!;
    controller.saveCharacter(character('A1'));
    expect(await workspace.save(name: 'Gemelos'), isTrue);
    final first = workspace.current.id;
    controller.saveCharacter(character('C1'));
    expect(await workspace.saveAs('Gemelos', '2026-07-01'), isTrue);
    final second = workspace.current.id;
    expect(second, isNot(first));
    expect((await workspace.library()).map((item) => item.document!.name), [
      'Gemelos',
      'Gemelos',
    ]);
    expect(controller.history.canUndo, isFalse);
    expect(await workspace.rename(first, 'Renombrado', '2026-07-01'), isTrue);
    expect(await workspace.duplicate(first, 'Gemelos'), isTrue);
    expect((await workspace.library()).length, 3);
    expect(await workspace.open(first), isTrue);
    expect(controller.value.characters.length, 1);
    final session = controller.value;
    expect(await workspace.delete(first), isTrue);
    expect(controller.value, same(session));
    expect(workspace.saved, isFalse);
    expect(workspace.dirty, isTrue);
    expect((await workspace.library()).length, 2);
    expect((await workspace.repository.readWorking())!.saved, isFalse);
  });
  test('errores de escritura mantienen memoria nueva y archivo anterior; reintento lo recupera', () async {
    final store = MemoryStore(), controller = await persistentController(store);
    addTearDown(controller.dispose);
    final workspace = controller.workspace!;
    final disk = store.documents['working'];
    store.failWrite = true;
    controller.saveCharacter(character('A1'));
    expect(await workspace.flush(), isFalse);
    expect(controller.value.characters.length, 1);
    expect(store.documents['working'], disk);
    expect(workspace.error, isNotNull);
    expect(workspace.dirty, isTrue);
    expect(await workspace.save(), isFalse);
    expect(workspace.saved, isFalse);
    store.failWrite = false;
    expect(await workspace.retry(), isTrue);
    expect(
      (await workspace.repository.readWorking())!
          .document
          .session
          .characters
          .length,
      1,
    );
  });
  test('error al abrir/crear/guardar como conserva identidad, historial y sesión abierta', () async {
    final store = MemoryStore(), controller = await persistentController(store);
    addTearDown(controller.dispose);
    final workspace = controller.workspace!;
    controller.saveCharacter(character('A1'));
    await workspace.save();
    final id = workspace.current.id,
        session = controller.value,
        count = controller.history.undoCount;
    store.failRead = true;
    expect(await workspace.open(id), isFalse);
    expect(controller.value, same(session));
    expect(workspace.current.id, id);
    store.failRead = false;
    store.failWrite = true;
    expect(await workspace.create('Nuevo', '2026-07-01'), isFalse);
    expect(await workspace.saveAs('Copia', '2026-07-01'), isFalse);
    expect(controller.value, same(session));
    expect(workspace.current.id, id);
    expect(controller.history.undoCount, count);
    store.failWrite = false;
    store.failDelete = true;
    expect(await workspace.delete(id), isFalse);
    expect(store.documents.containsKey(id), isTrue);
  });
  test('autoguardado de versión desconocida no se pisa; sustituirlo explícitamente conserva copia', () async {
    final store = MemoryStore();
    const raw =
        '{"workspaceSchemaVersion":999,"document":{},"dirty":false,"saved":false}';
    store.documents['working'] = raw;
    final controller = await persistentController(store);
    addTearDown(controller.dispose);
    final workspace = controller.workspace!;
    expect(workspace.recoveryBlocked, isTrue);
    controller.saveCharacter(character('A1'));
    await workspace.flush();
    expect(store.documents['working'], raw);
    expect(await workspace.retry(), isFalse);
    expect(controller.value.characters.length, 1);
    expect(await workspace.saveAs('Rescate', '2026-07-01'), isTrue);
    expect(
      store.documents.entries
          .where((entry) => entry.key.startsWith('recovery-'))
          .single
          .value,
      raw,
    );
    expect(workspace.recoveryBlocked, isFalse);
    expect(
      (await workspace.repository.readWorking())!
          .document
          .session
          .characters
          .length,
      1,
    );
  });
  test('archivo dañado en biblioteca no se sobrescribe al guardar y otras entradas siguen visibles', () async {
    final store = MemoryStore(), controller = await persistentController(store);
    addTearDown(controller.dispose);
    final workspace = controller.workspace!;
    await workspace.save();
    final id = workspace.current.id;
    store.documents[id] = '{"schemaVersion":999}';
    final session = controller.value;
    expect(await workspace.open(id), isFalse);
    expect(controller.value, same(session));
    expect(await workspace.save(), isFalse);
    expect(store.documents[id], '{"schemaVersion":999}');
    final items = await workspace.library();
    expect(items.single.document, isNull);
    expect(items.single.error, isNotNull);
    expect(await workspace.saveAs('Otra copia', '2026-07-01'), isTrue);
    expect((await workspace.library()).length, 2);
  });
  test('una edición durante guardado no queda marcada como guardada por una revisión anterior', () async {
    final store = MemoryStore(), controller = await persistentController(store);
    addTearDown(controller.dispose);
    final workspace = controller.workspace!;
    controller.saveCharacter(character('A1'));
    await workspace.flush();
    store.gate = Completer<void>();
    final saving = workspace.save();
    await Future<void>.delayed(Duration.zero);
    controller.saveCharacter(character('C1'));
    expect(controller.value.characters.length, 2);
    store.gate!.complete();
    expect(await saving, isTrue);
    store.gate = null;
    await workspace.flush();
    expect(workspace.dirty, isTrue);
    expect(
      (await workspace.repository.open(workspace.current.id))
          .session
          .characters
          .length,
      1,
    );
    expect(
      (await workspace.repository.readWorking())!
          .document
          .session
          .characters
          .length,
      2,
    );
  });
  test('escenario borrado que aún aparecía guardado se recupera como borrador pendiente', () async {
    final store = MemoryStore(), first = await persistentController(store);
    first.saveCharacter(character('A1'));
    await first.workspace!.save();
    final id = first.workspace!.current.id;
    first.dispose();
    store.documents.remove(id);
    final restored = await persistentController(store);
    addTearDown(restored.dispose);
    expect(restored.value.characters.length, 1);
    expect(restored.workspace!.saved, isFalse);
    expect(restored.workspace!.dirty, isTrue);
  });
  test('abrir/importar reinicia historial y crea identidad distinta al archivo importado', () async {
    final store = MemoryStore(), controller = await persistentController(store);
    addTearDown(controller.dispose);
    final workspace = controller.workspace!;
    controller.saveCharacter(character('A1'));
    expect(controller.history.canUndo, isTrue);
    final imported = sampleDocument();
    expect(await workspace.importDocument(imported), isTrue);
    expect(workspace.current.id, isNot(imported.id));
    expect(controller.history.canUndo, isFalse);
    final map = codec.toMap(workspace.current), source = codec.toMap(imported);
    map.remove('metadata');
    source.remove('metadata');
    expect(jsonEncode(map), jsonEncode(source));
    expect((await workspace.library()).length, 1);
  });
}

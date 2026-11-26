import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/application/priority/priority_repository.dart';
import 'package:heroclix_simulator_trainer/application/priority/priority_session_codec.dart';
import 'package:heroclix_simulator_trainer/domain/priority/priority.dart';
import 'package:heroclix_simulator_trainer/infrastructure/local/file_document_store.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_controller.dart';

import 'support/priority_stage3_fixtures.dart';
import 'support/priority_stage4_fixtures.dart';

void main() {
  late Directory root;
  late FileDocumentStore store;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('gridlab-priority-stage4-');
    store = FileDocumentStore(
      () async => root,
      maxBytes: PrioritySessionCodec.maxBytes,
      maxDocuments: 10000,
    );
  });
  tearDown(() async {
    // Only remove individual files created in this dedicated test directory.
    await for (final entity in root.list(followLinks: false)) {
      if (entity is File) await entity.delete();
    }
    await root.delete();
  });
  PriorityController controller(PriorityFakeClock elapsed) =>
      PriorityController(
        repository: PriorityRepository(store),
        inputCooldown: Duration.zero,
        elapsedClock: elapsed.read,
      );
  void act(PriorityController c, PriorityCommand command) =>
      expect(c.dispatch(command, expectedRevision: c.value!.revision), isTrue);

  test(
    'archivos reales: reinicio, respuesta, undo, archivo y resultados',
    () async {
      final elapsed = PriorityFakeClock();
      final a = controller(elapsed);
      await a.initialize();
      expect(a.start(priorityConfig(3, first: 'J2')), isTrue);
      act(a, const PriorityCommand.setVictoryPoints('J1', 85));
      act(a, const PriorityCommand.setAdditionalActions('J3', 2));
      elapsed.advance(const Duration(seconds: 8));
      a.synchronizeClock();
      act(a, const PriorityCommand.action('J2'));
      act(
        a,
        const PriorityCommand.setRemainingTime('J3', Duration(minutes: 7)),
      );
      expect(
        a.swapVisualSeats('J1', 'J3', configuration: a.value!.configuration),
        isTrue,
      );
      final expected = gameFields(a.value!);
      final seats = a.visualSeatOrder;
      final id = a.session!.id;
      expect(await a.flush(), isTrue);
      a.dispose();
      await a.flush();

      elapsed.advance(const Duration(days: 50));
      final b = controller(elapsed);
      await b.initialize();
      expect(b.ready, isTrue);
      expect(gameFields(b.value!), expected);
      expect(b.visualSeatOrder, seats);
      expect(b.value!.isPaused, isTrue);
      elapsed.advance(const Duration(hours: 4));
      b.synchronizeClock();
      expect(gameFields(b.value!), expected);
      act(b, const PriorityCommand.resume());
      act(b, const PriorityCommand.responseAction('J3'));
      expect(b.value!.priorityPlayerId, 'J1');
      expect(b.undo(), isTrue);
      expect(b.value!.isPaused, isTrue);
      expect(b.value!.pendingResponders, ['J3', 'J1']);
      expect(b.value!.player('J3').availableActions, 5);
      expect(b.value!.player('J1').victoryPoints, 85);
      expect(await b.parkAndReset(), isTrue);
      b.dispose();

      final c = controller(elapsed);
      await c.initialize();
      expect(c.value, isNull);
      expect(c.savedMatches.single.id, id);
      expect(await c.openSaved(id), isTrue);
      expect(c.value!.isPaused, isTrue);
      expect(c.value!.priorityPlayerId, 'J3');
      act(c, const PriorityCommand.finish());
      expect(await c.flush(), isTrue);
      expect(await c.parkAndReset(), isTrue);
      c.dispose();

      final d = controller(elapsed);
      await d.initialize();
      expect(d.value, isNull);
      expect(d.savedMatches.single.finished, isTrue);
      final saved = await d.readSaved(id);
      expect(saved.match.standings.first.player.id, 'J1');
      expect(saved.count('J2', PriorityEventType.action), 1);
      expect(saved.count('J3', PriorityEventType.responseAction), 0);
      expect(saved.match.player('J2').spentTime, const Duration(seconds: 8));
      expect(saved.history.where((e) => e.undoOf != null).length, 1);
      expect(await d.deleteSaved(id), isTrue);
      expect(d.savedMatches, isEmpty);
      d.dispose();
    },
  );

  test('archivo principal corrupto recupera copia válida sin red', () async {
    final c = controller(PriorityFakeClock());
    await c.initialize();
    c.start(priorityConfig(2));
    act(c, const PriorityCommand.free('J1'));
    await c.flush();
    c.dispose();
    await c.flush();
    final backup = await store.read(PriorityRepository.backupId);
    expect(backup, isNotNull);
    await File('${root.path}/working.json').writeAsString('{interrumpido');
    final repository = PriorityRepository(store);
    final d = PriorityController(repository: repository);
    await d.initialize();
    expect(repository.recoveredBackup, isTrue);
    expect(d.value!.underlyingPhase, PriorityPhase.freeResponse);
    expect(d.value!.pendingResponders, ['J2']);
    expect(d.value!.isPaused, isTrue);
    expect(await d.flush(), isTrue);
    d.dispose();
    await d.flush();
  });

  test(
    'límite ampliado aislado y fallo de tamaño conserva archivo anterior',
    () async {
      final large = 'a' * (FileDocumentStore.maxStoredBytes + 10);
      await store.write('working', large);
      expect(await store.read('working'), large);
      final defaultStore = FileDocumentStore(() async => root);
      await expectLater(defaultStore.read('working'), throwsFormatException);
      await expectLater(
        defaultStore.write('working', large),
        throwsFormatException,
      );
      final tinyStore = FileDocumentStore(() async => root, maxBytes: 16);
      await expectLater(
        tinyStore.write('working', 'b' * 17),
        throwsFormatException,
      );
      expect(await store.read('working'), large);
      expect((await root.list().toList()).length, 1);
    },
  );
}

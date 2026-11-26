import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/application/priority/priority_repository.dart';
import 'package:heroclix_simulator_trainer/application/priority/priority_session.dart';
import 'package:heroclix_simulator_trainer/application/priority/priority_session_codec.dart';
import 'package:heroclix_simulator_trainer/domain/priority/priority.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_controller.dart';

import 'support/priority_stage3_fixtures.dart';
import 'support/priority_stage4_fixtures.dart';

const codec = PrioritySessionCodec();
const snapshots = PrioritySnapshotCodec();

void command(PriorityController c, PriorityCommand command) =>
    expect(c.dispatch(command, expectedRevision: c.value!.revision), isTrue);

void main() {
  test(
    'persistencia acepta nombres e IDs válidos del motor sin truncarlos',
    () {
      final id = 'identidad' * 100;
      final name = 'Jugador de prueba ' * 100;
      final c = PriorityController(inputCooldown: Duration.zero)
        ..start(
          PriorityConfiguration(
            players: [
              PriorityPlayerConfiguration(id: id, name: name, buildPoints: 300),
              PriorityPlayerConfiguration(
                id: 'otro',
                name: 'Otro',
                buildPoints: 300,
              ),
            ],
          ),
        );
      addTearDown(c.dispose);
      command(c, PriorityCommand.action(id));
      final saved = codec.decode(codec.encode(c.session))!;
      expect(saved.match.activePlayerId, id);
      expect(saved.match.player(id).name, name.trim());
      expect(saved.undo.single.match.player(id).consumedActions, 0);
      expect(saved.history.last.playerId, id);
    },
  );

  for (var count = 2; count <= 6; count++) {
    for (final clockEnabled in [false, true]) {
      for (final free in [false, true]) {
        test(
          '$count recuperación ${free ? 'FREE' : 'ACTION'} reloj $clockEnabled conserva estado completo',
          () async {
            final store = PriorityTestStore(), elapsed = PriorityFakeClock();
            final c = await savedPriority(
              store,
              count: count,
              clock: clockEnabled,
              first: 'J$count',
              elapsed: elapsed,
            );
            addTearDown(c.dispose);
            command(c, const PriorityCommand.setVictoryPoints('J1', 55));
            command(c, PriorityCommand.setAdditionalActions('J$count', 2));
            if (clockEnabled) {
              command(
                c,
                const PriorityCommand.setRemainingTime(
                  'J1',
                  Duration(seconds: 37),
                ),
              );
              command(c, const PriorityCommand.resume());
            }
            elapsed.advance(const Duration(seconds: 2));
            c.synchronizeClock();
            command(
              c,
              free
                  ? PriorityCommand.free('J$count')
                  : PriorityCommand.action('J$count'),
            );
            if (count > 2) {
              final responding = c.value!.priorityPlayerId!;
              command(
                c,
                free
                    ? PriorityCommand.responseFree(responding)
                    : PriorityCommand.responseAction(responding),
              );
            }
            elapsed.advance(const Duration(seconds: 1));
            c.synchronizeClock();
            c.swapVisualSeats(
              'J1',
              'J$count',
              configuration: c.value!.configuration,
            );
            expect(await c.flush(), isTrue);
            final before = c.value!, seats = c.visualSeatOrder.toList();
            final historySize = c.session!.history.length,
                undoSize = c.session!.undo.length;
            final restartedTime = PriorityFakeClock()
              ..advance(const Duration(days: 30));
            final recovered = PriorityController(
              repository: PriorityRepository(store.cloneDisk()),
              inputCooldown: Duration.zero,
              elapsedClock: restartedTime.read,
            );
            addTearDown(recovered.dispose);
            await recovered.initialize();
            expect(recovered.ready, isTrue);
            expect(gameFields(recovered.value!), gameFields(before));
            expect(recovered.value!.isPaused, clockEnabled);
            expect(recovered.value!.revision, greaterThan(before.revision));
            expect(recovered.visualSeatOrder, seats);
            expect(recovered.session!.history.length, historySize + 1);
            expect(recovered.session!.undo.length, undoSize);
            restartedTime.advance(const Duration(hours: 8));
            recovered.synchronizeClock();
            expect(gameFields(recovered.value!), gameFields(before));
            if (clockEnabled) {
              command(recovered, const PriorityCommand.resume());
            }
            while (recovered.value!.hasResponseWindow) {
              final responding = recovered.value!.priorityPlayerId!;
              command(
                recovered,
                free
                    ? PriorityCommand.responseFree(responding)
                    : PriorityCommand.responseAction(responding),
              );
            }
            expect(recovered.value!.underlyingPhase, PriorityPhase.activeTurn);
            expect(recovered.value!.priorityPlayerId, 'J$count');
            expect(await recovered.flush(), isTrue);
          },
        );
      }
    }

    test(
      '$count Deshacer consecutivo restaura operaciones, eliminación y final',
      () {
        final elapsed = PriorityFakeClock();
        final c = PriorityController(
          inputCooldown: Duration.zero,
          elapsedClock: elapsed.read,
        )..start(priorityConfig(count));
        addTearDown(c.dispose);
        final states = <(PriorityMatch, List<String>)>[];
        void act(PriorityCommand op) {
          states.add((c.value!, c.visualSeatOrder.toList()));
          command(c, op);
        }

        act(const PriorityCommand.action('J1'));
        while (c.value!.hasResponseWindow) {
          act(PriorityCommand.pass(c.value!.priorityPlayerId!));
        }
        act(const PriorityCommand.endTurn('J1'));
        act(const PriorityCommand.free('J2'));
        while (c.value!.hasResponseWindow) {
          act(PriorityCommand.responseFree(c.value!.priorityPlayerId!));
        }
        act(const PriorityCommand.setVictoryPoints('J1', 85));
        act(const PriorityCommand.setAdditionalActions('J1', 2));
        act(
          const PriorityCommand.setRemainingTime('J1', Duration(seconds: 50)),
        );
        command(
          c,
          const PriorityCommand.resume(),
        ); // Clock controls do not consume undo steps.
        states.add((c.value!, c.visualSeatOrder.toList()));
        c.swapVisualSeats(
          'J1',
          'J$count',
          configuration: c.value!.configuration,
        );
        act(const PriorityCommand.eliminate('J1'));
        if (c.value!.phase != PriorityPhase.finished) {
          act(const PriorityCommand.finish());
        }
        act(PriorityCommand.setVictoryPoints('J$count', 99));
        var revision = c.value!.revision;
        for (final expected in states.reversed) {
          expect(c.undo(), isTrue);
          expect(gameFields(c.value!), gameFields(expected.$1));
          expect(c.visualSeatOrder, expected.$2);
          expect(
            c.value!.isPaused,
            expected.$1.underlyingPhase != PriorityPhase.finished,
          );
          expect(c.value!.revision, greaterThan(revision));
          revision = c.value!.revision;
        }
        expect(c.canUndo, isFalse);
        expect(c.undo(), isFalse);
        expect(
          c.session!.history
              .where((e) => e.kind == PriorityLogKind.undo)
              .length,
          states.length,
        );
        expect(c.session!.count('J1', PriorityEventType.action), 0);
        expect(
          c.value!.players.every((p) => !p.eliminated && p.victoryPoints == 0),
          isTrue,
        );
      },
    );

    for (final clock in [false, true]) {
      test(
        '$count codec de snapshots tras 400 transiciones aleatorias, reloj $clock',
        () {
          final random = Random(count * 31 + (clock ? 1 : 0));
          var m = priorityGame(count, clock: clock);
          for (var i = 0; i < 400; i++) {
            if (i % 3 == 0) {
              m = priorityEngine
                  .reseat(m, m.turnOrder.toList()..shuffle(random))
                  .match;
            }
            final c = snapshots.readConfiguration(
              jsonDecode(jsonEncode(snapshots.configuration(m.configuration))),
            );
            final restored = snapshots.readState(
              jsonDecode(jsonEncode(snapshots.state(m))),
              c,
            );
            expect(snapshots.state(restored), snapshots.state(m));
            if (m.phase == PriorityPhase.finished) {
              m = priorityGame(count, clock: clock);
              continue;
            }
            final commands = <PriorityCommand>[
              const PriorityCommand.resume(),
              const PriorityCommand.pause(),
              if (random.nextInt(20) == 0) const PriorityCommand.finish(),
              for (final p in m.players) ...[
                PriorityCommand.action(p.id),
                PriorityCommand.free(p.id),
                PriorityCommand.pass(p.id),
                PriorityCommand.responseAction(p.id),
                PriorityCommand.responseFree(p.id),
                PriorityCommand.endTurn(p.id),
                PriorityCommand.setAdditionalActions(p.id, random.nextInt(4)),
                PriorityCommand.setVictoryPoints(p.id, random.nextInt(100)),
                if (clock)
                  PriorityCommand.setRemainingTime(
                    p.id,
                    Duration(seconds: random.nextInt(5)),
                  ),
                if (random.nextInt(5) == 0) PriorityCommand.eliminate(p.id),
              ],
            ].where((op) => priorityEngine.rejection(m, op) == null).toList();
            final transition = priorityEngine.apply(
              m,
              commands[random.nextInt(commands.length)],
            );
            for (final e in transition.events) {
              expect(
                snapshots.event(
                  snapshots.readEvent(
                    jsonDecode(jsonEncode(snapshots.event(e))),
                    c,
                  ),
                ),
                snapshots.event(e),
              );
            }
            m = priorityEngine
                .advanceTime(
                  transition.match,
                  Duration(milliseconds: random.nextInt(1000)),
                )
                .match;
          }
        },
      );
    }
  }

  test(
    'historial agrupa pases automáticos y Deshacer los excluye del resumen',
    () {
      final c = PriorityController(inputCooldown: Duration.zero)
        ..start(priorityConfig(3, clock: false));
      addTearDown(c.dispose);
      command(c, const PriorityCommand.action('J1'));
      command(c, const PriorityCommand.responseAction('J2'));
      command(c, const PriorityCommand.pass('J3'));
      command(c, const PriorityCommand.setAdditionalActions('J1', 1));
      // Base is three; exhaust the future responder without resetting the turn.
      for (var n = 0; n < 2; n++) {
        command(c, const PriorityCommand.action('J1'));
        command(c, const PriorityCommand.responseAction('J2'));
        command(c, const PriorityCommand.pass('J3'));
      }
      command(c, const PriorityCommand.action('J1'));
      expect(
        c.session!.history.last.events.any(
          (e) =>
              e.type == PriorityEventType.automaticPass && e.playerId == 'J2',
        ),
        isTrue,
      );
      expect(c.session!.count('J2', PriorityEventType.automaticPass), 1);
      expect(c.undo(), isTrue);
      expect(c.session!.count('J2', PriorityEventType.automaticPass), 0);
      expect(c.session!.count('J1', PriorityEventType.action), 3);
    },
  );

  test('reloj no genera historial por tick; agotamiento queda pausado al recuperar', () async {
    final store = PriorityTestStore(), clock = PriorityFakeClock();
    final c = await savedPriority(
      store,
      count: 2,
      time: const Duration(seconds: 2),
      elapsed: clock,
    );
    addTearDown(c.dispose);
    final count = c.session!.history.length;
    for (var i = 0; i < 15; i++) {
      clock.advance(const Duration(milliseconds: 100));
      c.synchronizeClock();
    }
    expect(c.session!.history.length, count);
    clock.advance(const Duration(seconds: 2));
    c.synchronizeClock();
    expect(
      c.session!.history.last.events.any(
        (e) => e.type == PriorityEventType.timeExpired,
      ),
      isTrue,
    );
    await c.flush();
    final b = PriorityController(
      repository: PriorityRepository(store.cloneDisk()),
      inputCooldown: Duration.zero,
    );
    addTearDown(b.dispose);
    await b.initialize();
    expect(b.value!.isPaused, isTrue);
    expect(b.value!.player('J1').remainingTime, Duration.zero);
    expect(b.can(const PriorityCommand.resume()), isFalse);
    expect(b.value!.players.any((p) => p.eliminated), isFalse);
  });

  test(
    'persisten la pila Deshacer, anulaciones y nuevas operaciones tras volver',
    () async {
      final store = PriorityTestStore();
      final a = await savedPriority(store, clock: false);
      addTearDown(a.dispose);
      for (var i = 0; i < 8; i++) {
        command(a, const PriorityCommand.adjustVictoryPoints('J1', 5));
      }
      for (var i = 0; i < 3; i++) {
        expect(a.undo(), isTrue);
      }
      command(a, const PriorityCommand.setVictoryPoints('J2', 20));
      await a.flush();
      final b = PriorityController(
        repository: PriorityRepository(store.cloneDisk()),
        inputCooldown: Duration.zero,
      );
      addTearDown(b.dispose);
      await b.initialize();
      expect(b.session!.undo.length, 6);
      expect(b.session!.undoneEntries.length, 3);
      for (var i = 0; i < 6; i++) {
        expect(b.undo(), isTrue);
      }
      expect(b.value!.players.every((p) => p.victoryPoints == 0), isTrue);
      expect(b.canUndo, isFalse);
      expect(await b.flush(), isTrue);
      expect(
        codec.decode(b.repository!.codec.encode(b.session))!.undo,
        isEmpty,
      );
    },
  );

  test(
    'Deshacer invalida callbacks antiguos y no consume una operación rechazada',
    () {
      final c = PriorityController(inputCooldown: Duration.zero)
        ..start(priorityConfig(2, clock: false));
      addTearDown(c.dispose);
      final revision = c.value!.revision;
      command(c, const PriorityCommand.action('J1'));
      expect(c.undo(), isTrue);
      final length = c.session!.history.length;
      expect(
        c.dispatch(
          const PriorityCommand.action('J1'),
          expectedRevision: revision,
        ),
        isFalse,
      );
      expect(c.session!.history.length, length);
      command(c, const PriorityCommand.action('J1'));
      expect(c.value!.player('J1').consumedActions, 1);
    },
  );

  test(
    'recuperación respeta pendientes de ronda y elimina sin duplicar turnos',
    () async {
      final store = PriorityTestStore();
      final a = await savedPriority(store, count: 4, first: 'J3');
      addTearDown(a.dispose);
      command(a, const PriorityCommand.endTurn('J3'));
      command(a, const PriorityCommand.endTurn('J4'));
      command(a, const PriorityCommand.eliminate('J2'));
      expect(a.value!.roundPending, ['J1']);
      await a.flush();
      final b = PriorityController(
        repository: PriorityRepository(store.cloneDisk()),
        inputCooldown: Duration.zero,
      );
      addTearDown(b.dispose);
      await b.initialize();
      command(b, const PriorityCommand.resume());
      command(b, const PriorityCommand.endTurn('J1'));
      expect(b.value!.round, 2);
      expect(b.value!.activePlayerId, 'J3');
      expect(b.value!.roundPending, ['J3', 'J4', 'J1']);
    },
  );

  test('guardar, cambiar de partida, recuperar y consultar finalizadas sin pérdida', () async {
    final store = PriorityTestStore();
    final c = await savedPriority(store);
    addTearDown(c.dispose);
    command(c, const PriorityCommand.action('J1'));
    command(c, const PriorityCommand.responseAction('J2'));
    command(c, const PriorityCommand.pass('J3'));
    command(c, const PriorityCommand.endTurn('J1'));
    command(c, const PriorityCommand.setVictoryPoints('J2', 150));
    command(c, const PriorityCommand.finish());
    final finishedId = c.session!.id;
    expect(await c.parkAndReset(), isTrue);
    expect(c.start(priorityConfig(2)), isTrue);
    final otherId = c.session!.id;
    command(c, const PriorityCommand.action('J1'));
    expect(await c.parkAndReset(), isTrue);
    expect(await c.openSaved(otherId), isTrue);
    expect(c.value!.underlyingPhase, PriorityPhase.actionResponse);
    expect(c.value!.isPaused, isTrue);
    final summary = await c.readSaved(finishedId);
    expect(summary.match.phase, PriorityPhase.finished);
    expect(summary.match.standings.first.player.id, 'J2');
    expect(summary.count('J1', PriorityEventType.action), 1);
    expect(summary.count('J2', PriorityEventType.responseAction), 1);
    expect(summary.count('J3', PriorityEventType.voluntaryPass), 1);
    expect(c.session!.id, otherId);
    expect(c.savedMatches.length, 2);
    expect(await c.deleteSaved(otherId), isFalse);
    expect(await c.deleteSaved(finishedId), isTrue);
    expect(c.savedMatches.length, 1);
  });

  for (final failedId in ['all', 'working']) {
    test(
      'fallo de escritura $failedId conserva partida y bloquea reemplazo hasta reintentar',
      () async {
        final store = PriorityTestStore();
        final c = await savedPriority(store);
        addTearDown(c.dispose);
        expect(await c.flush(), isTrue);
        final previous = store.documents['working'];
        if (failedId == 'all') {
          store.failWrite = true;
        } else {
          store.failWriteIds.add('working');
        }
        command(c, const PriorityCommand.setVictoryPoints('J1', 25));
        expect(await c.flush(), isFalse);
        expect(c.storageError, isNotNull);
        expect(store.documents['working'], previous);
        expect(await c.parkAndReset(), isFalse);
        expect(c.value!.player('J1').victoryPoints, 25);
        expect(c.start(priorityConfig(2)), isFalse);
        expect(() => c.reset(), throwsStateError);
        store.failWrite = false;
        store.failWriteIds.clear();
        expect(await c.flush(), isTrue);
        expect(c.storageError, isNull);
        expect(await c.parkAndReset(), isTrue);
        expect(c.value, isNull);
        expect(c.savedMatches.single.match.player('J1').victoryPoints, 25);
      },
    );
  }

  test(
    'escrituras se serializan y los toques rápidos se guardan completos',
    () async {
      final store = PriorityTestStore();
      final c = await savedPriority(store, clock: false);
      addTearDown(c.dispose);
      await c.flush();
      final gate = store.gate = Completer<void>();
      for (var i = 0; i < 30; i++) {
        command(c, const PriorityCommand.adjustVictoryPoints('J1', 5));
      }
      final flushed = c.flush();
      await Future<void>.delayed(Duration.zero);
      expect(c.value!.player('J1').victoryPoints, 150);
      gate.complete();
      expect(await flushed, isTrue);
      expect(store.maxActiveWrites, 1);
      final saved = codec.decode(store.documents['working']!)!;
      expect(saved.match.player('J1').victoryPoints, 150);
      expect(saved.undo.length, 30);
    },
  );

  test('copia anterior recupera un working dañado y no se sobrescribe con corrupción', () async {
    final store = PriorityTestStore();
    final a = await savedPriority(store, clock: false);
    addTearDown(a.dispose);
    command(a, const PriorityCommand.setVictoryPoints('J1', 25));
    await a.flush();
    final valid = store.documents['working']!;
    final damaged = store.cloneDisk()
      ..documents[PriorityRepository.backupId] = valid
      ..documents['working'] = '{roto';
    final b = PriorityController(
      repository: PriorityRepository(damaged),
      inputCooldown: Duration.zero,
    );
    addTearDown(b.dispose);
    await b.initialize();
    expect(b.ready, isTrue);
    expect(b.repository!.recoveredBackup, isTrue);
    expect(b.value!.player('J1').victoryPoints, 25);
    expect(await b.flush(), isTrue);
    expect(
      codec
          .decode(damaged.documents[PriorityRepository.backupId]!)!
          .match
          .player('J1')
          .victoryPoints,
      25,
    );
  });

  for (final raw in [
    '{roto',
    '{"prioritySchema":99}',
    '{"prioritySchema":1,"checksum":"malo","payload":null}',
  ]) {
    test('inicio inválido no permite sobrescribir el archivo: $raw', () async {
      final store = PriorityTestStore()..documents['working'] = raw;
      final original = Map<String, String>.from(store.documents);
      final c = PriorityController(repository: PriorityRepository(store));
      addTearDown(c.dispose);
      expect(c.start(priorityConfig(2)), isFalse);
      await c.initialize();
      expect(c.ready, isFalse);
      expect(c.storageError, isNotNull);
      expect(c.start(priorityConfig(2)), isFalse);
      expect(store.documents, original);
    });
  }

  test(
    'archivos guardados dañados no ocultan los válidos ni se borran',
    () async {
      final store = PriorityTestStore();
      final c = await savedPriority(store, clock: false);
      addTearDown(c.dispose);
      await c.parkAndReset();
      final badId = PrioritySession.newId();
      store.documents[badId] = '{roto';
      await c.refreshLibrary();
      expect(c.savedMatches.length, 1);
      expect(c.libraryError, isNotNull);
      expect(store.documents[badId], '{roto');
      expect(await c.openSaved(badId), isFalse);
      expect(c.value, isNull);
    },
  );

  final corruptions = <String, void Function(Map<String, dynamic>)>{
    'prioridad desconocida': (p) => (p['state'] as Map)['priority'] = 'otro',
    'cola duplicada': (p) => (p['state'] as Map)['pending'] = ['J2', 'J2'],
    'activo como respuesta': (p) => (p['state'] as Map)['pending'] = ['J1'],
    'acciones negativas': (p) =>
        ((p['state'] as Map)['players'] as List)[0]['consumed'] = -1,
    'PV negativos': (p) =>
        ((p['state'] as Map)['players'] as List)[0]['pv'] = -1,
    'reloj sin valor': (p) =>
        ((p['state'] as Map)['players'] as List)[0]['remaining'] = null,
    'fase inventada': (p) => (p['state'] as Map)['phase'] = 'falsa',
    'ronda mayor que turno': (p) => (p['state'] as Map)['round'] = 9,
    'asientos duplicados': (p) => p['seats'] = ['J1', 'J1', 'J3'],
    'pila ausente': (p) => p['undo'] = <Object?>[],
    'registro desconocido': (p) => (p['history'] as List)[0]['kind'] = 'otro',
    'ID incorrecto': (p) => p['id'] = '../archivo',
    'hora sin zona UTC': (p) => p['created'] = '2026-11-26T10:00:00',
    'secuencia incorrecta': (p) => (p['history'] as List)[0]['id'] = 55,
  };
  for (final entry in corruptions.entries) {
    test('codec rechaza ${entry.key} aunque el checksum coincida', () {
      final c = PriorityController(inputCooldown: Duration.zero)
        ..start(priorityConfig(3));
      addTearDown(c.dispose);
      command(c, const PriorityCommand.action('J1'));
      final root = jsonDecode(codec.encode(c.session)) as Map<String, dynamic>;
      entry.value(root['payload'] as Map<String, dynamic>);
      root['checksum'] = PrioritySessionCodec.checksum(
        jsonEncode(root['payload']),
      );
      expect(() => codec.decode(jsonEncode(root)), throwsFormatException);
    });
  }
}

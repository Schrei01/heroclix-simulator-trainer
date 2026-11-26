import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/application/priority/priority_repository.dart';
import 'package:heroclix_simulator_trainer/application/priority/priority_session_codec.dart';
import 'package:heroclix_simulator_trainer/domain/priority/priority.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_controller.dart';

import 'support/priority_stage3_fixtures.dart';
import 'support/priority_stage4_fixtures.dart';

void act(PriorityController c, PriorityCommand op) =>
    expect(c.dispatch(op, expectedRevision: c.value!.revision), isTrue);

void main() {
  for (var count = 2; count <= 6; count++) {
    for (final free in [false, true]) {
      test(
        '$count ${free ? 'FREE' : 'ACTION'}: cada par de asientos conserva prioridad y reordena solo pendientes',
        () {
          for (var a = 0; a < count; a++) {
            for (var b = a + 1; b < count; b++) {
              final c = PriorityController(
                inputCooldown: Duration.zero,
                elapsedClock: () => Duration.zero,
              )..start(priorityConfig(count));
              act(
                c,
                free
                    ? const PriorityCommand.free('J1')
                    : const PriorityCommand.action('J1'),
              );
              if (count > 2) act(c, const PriorityCommand.pass('J2'));
              final before = c.value!;
              final order = c.visualSeatOrder.toList();
              expect(
                c.swapVisualSeats(
                  order[a],
                  order[b],
                  configuration: before.configuration,
                ),
                isTrue,
              );
              expect(c.value!.configuration, same(before.configuration));
              expect(c.value!.players, orderedEquals(before.players));
              expect(c.value!.activePlayerId, before.activePlayerId);
              expect(c.value!.priorityPlayerId, before.priorityPlayerId);
              expect(c.value!.round, before.round);
              expect(c.value!.turn, before.turn);
              expect(
                c.value!.pendingResponders.toSet(),
                before.pendingResponders.toSet(),
              );
              final nextOrder = c.visualSeatOrder;
              final pendingStart = nextOrder.indexOf(before.priorityPlayerId!);
              final expected = [
                for (var n = 0; n < count; n++)
                  nextOrder[(pendingStart + n) % count],
              ].where(before.pendingResponders.contains).toList();
              expect(c.value!.pendingResponders, expected);
              final snapshot = gameFields(c.value!);
              final encoded = const PrioritySessionCodec().encode(c.session);
              expect(
                gameFields(const PrioritySessionCodec().decode(encoded)!.match),
                snapshot,
              );
              while (c.value!.hasResponseWindow) {
                act(c, PriorityCommand.pass(c.value!.priorityPlayerId!));
              }
              act(c, const PriorityCommand.endTurn('J1'));
              expect(
                c.value!.activePlayerId,
                nextOrder[(nextOrder.indexOf('J1') + 1) % count],
              );
              expect(c.value!.configuration.startingPlayerId, 'J1');
              c.dispose();
            }
          }
        },
      );
    }
  }

  test('ronda parcial conserva pendientes y sigue vecinos aunque uno ya haya jugado', () {
    final c = PriorityController(inputCooldown: Duration.zero)
      ..start(priorityConfig(4, clock: false));
    addTearDown(c.dispose);
    act(c, const PriorityCommand.endTurn('J1'));
    c.swapVisualSeats('J1', 'J3', configuration: c.value!.configuration);
    expect(c.value!.turnOrder, ['J3', 'J2', 'J1', 'J4']);
    expect(c.value!.roundPending, ['J2', 'J4', 'J3']);
    for (final id in ['J2', 'J1', 'J4', 'J3']) {
      expect(c.value!.activePlayerId, id);
      expect(c.value!.round, 1);
      act(c, PriorityCommand.endTurn(id));
    }
    expect(c.value!.round, 2);
    expect(c.value!.activePlayerId, 'J2');
    act(c, const PriorityCommand.eliminate('J1'));
    act(c, const PriorityCommand.endTurn('J2'));
    expect(c.value!.activePlayerId, 'J4');
  });

  test(
    'rechaza órdenes inválidos y no muta configuración ni estado original',
    () {
      final match = priorityGame(3);
      for (final order in <List<String>>[
        [],
        ['J1', 'J2'],
        ['J1', 'J2', 'J2'],
        ['J1', 'J2', 'otro'],
      ]) {
        expect(() => priorityEngine.reseat(match, order), throwsArgumentError);
      }
      expect(priorityEngine.reseat(match, match.turnOrder).match, same(match));
      expect(() => match.turnOrder.add('otro'), throwsUnsupportedError);
      expect(
        () => priorityEngine.reseat(
          priorityEngine.configure(priorityConfig(3)),
          ['J3', 'J2', 'J1'],
        ),
        throwsA(isA<PriorityException>()),
      );
      expect(match.turnOrder, ['J1', 'J2', 'J3']);
    },
  );

  test('nuevo orden y respuesta parcial sobreviven reinicio y Deshacer restaura ambos', () async {
    final store = PriorityTestStore();
    final a = await savedPriority(store, count: 6);
    addTearDown(a.dispose);
    act(a, const PriorityCommand.setVictoryPoints('J2', 85));
    act(a, const PriorityCommand.action('J1'));
    act(a, const PriorityCommand.responseAction('J2'));
    act(a, const PriorityCommand.pass('J3'));
    a.swapVisualSeats('J4', 'J6', configuration: a.value!.configuration);
    expect(a.value!.pendingResponders, ['J4', 'J6', 'J5']);
    await a.flush();
    final b = PriorityController(
      repository: PriorityRepository(store.cloneDisk()),
      inputCooldown: Duration.zero,
    );
    addTearDown(b.dispose);
    await b.initialize();
    expect(b.value!.isPaused, isTrue);
    expect(b.value!.turnOrder, ['J1', 'J2', 'J3', 'J6', 'J5', 'J4']);
    expect(b.value!.pendingResponders, ['J4', 'J6', 'J5']);
    expect(b.value!.player('J2').victoryPoints, 85);
    expect(b.undo(), isTrue);
    expect(b.value!.turnOrder, ['J1', 'J2', 'J3', 'J4', 'J5', 'J6']);
    expect(b.visualSeatOrder, b.value!.turnOrder);
    expect(b.value!.pendingResponders, ['J4', 'J5', 'J6']);
    expect(b.value!.isPaused, isTrue);
  });

  for (final swaps in [1, 2]) {
    test(
      'migra formato 1 con $swaps intercambios, incluyendo checkpoints sin perder estado',
      () async {
        final a = PriorityController(inputCooldown: Duration.zero)
          ..start(priorityConfig(4));
        addTearDown(a.dispose);
        act(a, const PriorityCommand.action('J1'));
        act(a, const PriorityCommand.pass('J2'));
        for (var n = 0; n < swaps; n++) {
          a.swapVisualSeats('J1', 'J4', configuration: a.value!.configuration);
        }
        final codec = const PrioritySessionCodec();
        final root =
            jsonDecode(codec.encode(a.session)) as Map<String, dynamic>;
        final payload = root['payload'] as Map<String, dynamic>;
        void legacyState(Map<String, dynamic> s) {
          s.remove('order');
          s['revision'] =
              3; // In v1 swaps did not increment the engine revision.
          s['roundPending'] = ['J1', 'J2', 'J3', 'J4'];
          if (s['phase'] == 'actionResponse') {
            s['pending'] = s['priority'] == 'J2'
                ? ['J2', 'J3', 'J4']
                : ['J3', 'J4'];
          }
        }

        legacyState(payload['state'] as Map<String, dynamic>);
        for (final raw in payload['undo'] as List<dynamic>) {
          legacyState(
            (raw as Map<String, dynamic>)['state'] as Map<String, dynamic>,
          );
        }
        root['prioritySchema'] = 1;
        root['checksum'] = PrioritySessionCodec.checksum(jsonEncode(payload));
        final store = PriorityTestStore()
          ..documents['working'] = jsonEncode(root);
        final b = PriorityController(
          repository: PriorityRepository(store),
          inputCooldown: Duration.zero,
        );
        addTearDown(b.dispose);
        await b.initialize();
        expect(b.ready, isTrue);
        expect(b.value!.activePlayerId, 'J1');
        expect(b.value!.priorityPlayerId, 'J3');
        expect(b.value!.turnOrder, b.visualSeatOrder);
        expect(b.value!.pendingResponders, ['J3', 'J4']);
        expect(b.value!.isPaused, isTrue);
        expect(await b.flush(), isTrue);
        expect(
          (jsonDecode(store.documents['working']!) as Map)['prioritySchema'],
          2,
        );
        for (var n = 0; n < swaps; n++) {
          expect(b.undo(), isTrue);
        }
        expect(b.value!.turnOrder, ['J1', 'J2', 'J3', 'J4']);
        expect(b.value!.pendingResponders, ['J3', 'J4']);
      },
    );
  }
}

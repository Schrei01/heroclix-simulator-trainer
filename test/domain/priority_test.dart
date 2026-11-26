import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/domain/priority/priority.dart';

const engine = PriorityEngine();

PriorityConfiguration configuration(
  int count, {
  int points = 300,
  int additional = 0,
  String? first,
  List<String>? order,
}) => PriorityConfiguration(
  players: [
    for (final id in order ?? List.generate(count, (i) => 'J${i + 1}'))
      PriorityPlayerConfiguration(
        id: id,
        name: 'Jugador $id',
        buildPoints: points,
        additionalActions: additional,
      ),
  ],
  startingPlayerId: first,
);

PriorityMatch started(int count, {int points = 300, int additional = 0}) =>
    engine
        .apply(
          engine.configure(
            configuration(count, points: points, additional: additional),
          ),
          const PriorityCommand.start(),
        )
        .match;

PriorityMatch closeWindow(PriorityMatch match, {bool respond = false}) {
  var next = match;
  while (next.hasResponseWindow) {
    final id = next.priorityPlayerId!;
    next = engine
        .apply(
          next,
          !respond
              ? PriorityCommand.pass(id)
              : next.phase == PriorityPhase.actionResponse
              ? PriorityCommand.responseAction(id)
              : PriorityCommand.responseFree(id),
        )
        .match;
  }
  return next;
}

List<Object?> snapshot(PriorityMatch match) => [
  match.phase,
  match.underlyingPhase,
  match.isPaused,
  match.activePlayerId,
  match.priorityPlayerId,
  match.pendingResponders,
  match.turn,
  match.round,
  match.revision,
  for (final p in match.players)
    [
      p.id,
      p.name,
      p.baseActions,
      p.additionalActions,
      p.consumedActions,
      p.totalActions,
      p.availableActions,
    ],
];

void rejects(
  PriorityMatch match,
  PriorityCommand command,
  PriorityError error,
) {
  final before = snapshot(match);
  expect(engine.rejection(match, command), error);
  expect(
    () => engine.apply(match, command),
    throwsA(isA<PriorityException>().having((e) => e.code, 'code', error)),
  );
  expect(snapshot(match), before, reason: 'Un rechazo no modifica la partida.');
}

void invariants(PriorityMatch match) {
  expect(match.players.length, inInclusiveRange(2, 6));
  expect(match.players.map((p) => p.id).toSet().length, match.players.length);
  expect(match.underlyingPhase, isNot(PriorityPhase.paused));
  for (final p in match.players) {
    expect(p.baseActions, greaterThanOrEqualTo(1));
    expect(p.additionalActions, greaterThanOrEqualTo(0));
    expect(p.consumedActions, greaterThanOrEqualTo(0));
    expect(p.totalActions, p.baseActions + p.additionalActions);
    expect(p.availableActions, max(0, p.totalActions - p.consumedActions));
  }
  if (match.phase == PriorityPhase.configuration) {
    expect(match.activePlayerId, isNull);
    expect(match.priorityPlayerId, isNull);
    expect(match.turn, 0);
    expect(match.round, 0);
    expect(match.pendingResponders, isEmpty);
    return;
  }
  expect(match.round, 1 + (match.turn - 1) ~/ match.players.length);
  expect(match.activePlayerId, isNotNull);
  if (match.phase == PriorityPhase.finished) {
    expect(match.priorityPlayerId, isNull);
    expect(match.pendingResponders, isEmpty);
    expect(match.isPaused, isFalse);
  } else if (match.hasResponseWindow) {
    expect(match.pendingResponders, isNotEmpty);
    expect(match.priorityPlayerId, match.pendingResponders.first);
    expect(match.pendingResponders, isNot(contains(match.activePlayerId)));
    expect(
      match.pendingResponders.toSet().length,
      match.pendingResponders.length,
    );
    if (match.underlyingPhase == PriorityPhase.actionResponse) {
      expect(
        match.player(match.priorityPlayerId!).availableActions,
        greaterThan(0),
      );
    }
  } else {
    expect(match.pendingResponders, isEmpty);
    expect(match.priorityPlayerId, match.activePlayerId);
  }
}

List<PriorityCommand> commands(PriorityMatch match) => [
  const PriorityCommand.start(),
  const PriorityCommand.pause(),
  const PriorityCommand.resume(),
  const PriorityCommand.finish(),
  for (final id in [...match.players.map((p) => p.id), 'inexistente']) ...[
    PriorityCommand.action(id),
    PriorityCommand.free(id),
    PriorityCommand.responseAction(id),
    PriorityCommand.responseFree(id),
    PriorityCommand.pass(id),
    PriorityCommand.endTurn(id),
    PriorityCommand.setAdditionalActions(id, -1),
    PriorityCommand.setAdditionalActions(id, 0),
    PriorityCommand.setAdditionalActions(id, 3),
  ],
];

void main() {
  group('Configuración y modelos', () {
    for (final (points, expected) in [
      (0, 1),
      (1, 1),
      (99, 1),
      (100, 1),
      (199, 1),
      (200, 2),
      (299, 2),
      (300, 3),
      (399, 3),
      (600, 6),
      (10000, 100),
    ]) {
      test('$points puntos dan $expected acciones base', () {
        final p = configuration(2, points: points, additional: 2).players.first;
        expect(p.baseActions, expected);
        expect(p.totalActions, expected + 2);
      });
    }
    for (final count in [0, 1, 7, 8]) {
      test('Rechaza $count jugadores', () {
        expect(() => configuration(count), throwsArgumentError);
      });
    }
    test('Rechaza nombres/IDs vacíos y cantidades negativas en ejecución', () {
      for (final text in ['', ' ', '\n\t']) {
        expect(
          () => PriorityPlayerConfiguration(
            id: text,
            name: 'N',
            buildPoints: 300,
          ),
          throwsArgumentError,
        );
        expect(
          () => PriorityPlayerConfiguration(
            id: 'ID',
            name: text,
            buildPoints: 300,
          ),
          throwsArgumentError,
        );
      }
      expect(() => configuration(2, points: -1), throwsArgumentError);
      expect(() => configuration(2, additional: -1), throwsArgumentError);
      expect(() => configuration(2, first: 'J3'), throwsArgumentError);
      expect(() => configuration(2, first: ''), throwsArgumentError);
      expect(() => configuration(2, order: ['J1', 'J1']), throwsArgumentError);
    });
    test('Normaliza textos y rechaza IDs duplicados después de normalizar', () {
      final p = PriorityPlayerConfiguration(
        id: ' J1 ',
        name: ' Ana ',
        buildPoints: 1,
      );
      expect(p.id, 'J1');
      expect(p.name, 'Ana');
      expect(() => PriorityConfiguration(players: [p, p]), throwsArgumentError);
      expect(
        () => configuration(2, order: ['J1', ' J1 ']),
        throwsArgumentError,
      );
    });
    test(
      'Permite nombres iguales y puntos/adicionales distintos por jugador',
      () {
        final c = PriorityConfiguration(
          players: [
            PriorityPlayerConfiguration(id: 'a', name: 'Ana', buildPoints: 199),
            PriorityPlayerConfiguration(
              id: 'b',
              name: 'Ana',
              buildPoints: 400,
              additionalActions: 2,
            ),
          ],
        );
        final match = engine.configure(c);
        expect(match.player('a').totalActions, 1);
        expect(match.player('b').totalActions, 6);
        expect(() => match.player('no'), throwsArgumentError);
      },
    );
    test('Colecciones externas y snapshots no permiten mutación', () {
      final players = configuration(3).players.toList();
      final c = PriorityConfiguration(players: players);
      players.clear();
      expect(c.players.length, 3);
      expect(() => c.players.clear(), throwsUnsupportedError);
      final initial = engine.configure(c);
      final start = engine.apply(initial, const PriorityCommand.start());
      final response = engine.apply(
        start.match,
        const PriorityCommand.action('J1'),
      );
      expect(() => response.match.players.clear(), throwsUnsupportedError);
      expect(
        () => response.match.pendingResponders.clear(),
        throwsUnsupportedError,
      );
      expect(() => response.events.clear(), throwsUnsupportedError);
      expect(initial.phase, PriorityPhase.configuration);
      expect(start.match.player('J1').consumedActions, 0);
      expect(response.match.player('J1').consumedActions, 1);
      expect(response.match.configuration.players.first.additionalActions, 0);
    });
    test('El sorteo valida antes de utilizar la fuente aleatoria', () {
      final random = CountingRandom();
      expect(
        () => PriorityConfiguration.randomStart(players: [], random: random),
        throwsArgumentError,
      );
      expect(random.calls, 0);
    });

    test(
      'Rechaza desbordamiento del total en configuración y modificaciones',
      () {
        const maxInt = 0x7fffffffffffffff;
        expect(() => configuration(2, additional: maxInt), throwsArgumentError);
        final initial = started(2);
        rejects(
          initial,
          const PriorityCommand.setAdditionalActions('J1', maxInt),
          PriorityError.invalidAdditionalActions,
        );
        final nearLimit = engine
            .apply(
              initial,
              const PriorityCommand.setAdditionalActions('J1', maxInt - 3),
            )
            .match;
        expect(nearLimit.player('J1').totalActions, maxInt);
        final action = engine
            .apply(nearLimit, const PriorityCommand.action('J1'))
            .match;
        expect(action.player('J1').availableActions, maxInt - 1);
        final manyPoints = configuration(2, points: maxInt);
        expect(manyPoints.players.first.baseActions, maxInt ~/ 100);
      },
    );
  });

  test('Ejemplo obligatorio: J1 ACTION → J2 RESPONSE ACTION → J3 PASS', () {
    var match = started(3);
    expect(match.players.map((p) => p.availableActions), [3, 3, 3]);
    expect(match.activePlayerId, 'J1');
    expect(match.priorityPlayerId, 'J1');
    match = engine.apply(match, const PriorityCommand.action('J1')).match;
    expect(match.players.map((p) => p.availableActions), [2, 3, 3]);
    expect(match.activePlayerId, 'J1');
    expect(match.priorityPlayerId, 'J2');
    expect(match.pendingResponders, ['J2', 'J3']);
    match = engine
        .apply(match, const PriorityCommand.responseAction('J2'))
        .match;
    expect(match.players.map((p) => p.availableActions), [2, 2, 3]);
    expect(match.priorityPlayerId, 'J3');
    match = engine.apply(match, const PriorityCommand.pass('J3')).match;
    expect(match.players.map((p) => p.availableActions), [2, 2, 3]);
    expect(match.priorityPlayerId, 'J1');
    expect(match.phase, PriorityPhase.activeTurn);
    match = engine.apply(match, const PriorityCommand.endTurn('J1')).match;
    expect(match.players.map((p) => p.availableActions), [3, 3, 3]);
    expect(match.activePlayerId, 'J2');
    expect(match.priorityPlayerId, 'J2');
    expect(match.turn, 2);
    expect(match.round, 1);
    match = engine.apply(match, const PriorityCommand.action('J2')).match;
    expect(match.players.map((p) => p.availableActions), [3, 2, 3]);
    expect(match.pendingResponders, ['J3', 'J1']);
    match = engine.apply(match, const PriorityCommand.pass('J3')).match;
    expect(match.priorityPlayerId, 'J1');
    match = engine
        .apply(match, const PriorityCommand.responseAction('J1'))
        .match;
    expect(match.priorityPlayerId, 'J2');
    expect(match.players.map((p) => p.availableActions), [2, 2, 3]);
  });

  for (var count = 2; count <= 6; count++) {
    group('$count jugadores', () {
      test('Estado de configuración y arranque', () {
        final configured = engine.configure(configuration(count));
        invariants(configured);
        expect(configured.revision, 0);
        final result = engine.apply(configured, const PriorityCommand.start());
        invariants(result.match);
        expect(result.match.revision, 1);
        expect(result.events.map((e) => e.type), [
          PriorityEventType.started,
          PriorityEventType.turnStarted,
          PriorityEventType.priorityChanged,
        ]);
        expect(
          result.events.every(
            (e) => e.playerId == 'J1' && e.turn == 1 && e.round == 1,
          ),
          isTrue,
        );
      });

      for (var start = 0; start < count; start++) {
        test('Ciclos horarios de turno/prioridad desde asiento $start', () {
          final order = List.generate(count, (i) => 'asiento-${count - i}');
          var match = engine
              .apply(
                engine.configure(
                  configuration(count, order: order, first: order[start]),
                ),
                const PriorityCommand.start(),
              )
              .match;
          for (var t = 0; t < count * 3; t++) {
            final active = order[(start + t) % count];
            expect(match.activePlayerId, active);
            expect(match.priorityPlayerId, active);
            expect(match.turn, t + 1);
            expect(match.round, t ~/ count + 1);
            match = engine.apply(match, PriorityCommand.action(active)).match;
            expect(match.pendingResponders, [
              for (var offset = 1; offset < count; offset++)
                order[(start + t + offset) % count],
            ]);
            final responded = <String>[];
            while (match.hasResponseWindow) {
              final id = match.priorityPlayerId!;
              expect(match.activePlayerId, active);
              expect(responded, isNot(contains(id)));
              responded.add(id);
              match = engine
                  .apply(match, PriorityCommand.responseAction(id))
                  .match;
            }
            expect(responded.length, count - 1);
            expect(match.players.every((p) => p.consumedActions == 1), isTrue);
            match = engine.apply(match, PriorityCommand.endTurn(active)).match;
            expect(
              match.players.every(
                (p) => p.consumedActions == 0 && p.availableActions == 3,
              ),
              isTrue,
            );
            invariants(match);
          }
        });
      }

      test('Sorteo reproducible y sin alterar el orden de asientos', () {
        final seats = configuration(count).players;
        final a = Random(732);
        final b = Random(732);
        final selected = <String>{};
        for (var i = 0; i < 100; i++) {
          final ca = PriorityConfiguration.randomStart(
            players: seats,
            random: a,
          );
          final cb = PriorityConfiguration.randomStart(
            players: seats,
            random: b,
          );
          expect(ca.startingPlayerId, cb.startingPlayerId);
          expect(ca.players, seats);
          selected.add(ca.startingPlayerId);
        }
        expect(selected.length, count);
      });

      test('ACTION/RESPONSE ACTION consumen exactamente una acción', () {
        final before = started(count);
        final opened = engine.apply(before, const PriorityCommand.action('J1'));
        expect(opened.match.player('J1').consumedActions, 1);
        expect(opened.events.first.type, PriorityEventType.action);
        final closed = closeWindow(opened.match, respond: true);
        expect(closed.players.every((p) => p.availableActions == 2), isTrue);
        expect(closed.turn, 1);
        expect(closed.round, 1);
        expect(closed.priorityPlayerId, 'J1');
        expect(closed.pendingResponders, isEmpty);
        expect(before.players.every((p) => p.availableActions == 3), isTrue);
      });

      test('FREE y RESPONSE FREE admiten cero acciones y no consumen', () {
        var match = started(count, points: 0);
        match = closeWindow(
          engine.apply(match, const PriorityCommand.action('J1')).match,
          respond: true,
        );
        expect(match.players.every((p) => p.availableActions == 0), isTrue);
        rejects(
          match,
          const PriorityCommand.action('J1'),
          PriorityError.noActions,
        );
        for (var cycle = 0; cycle < 4; cycle++) {
          final open = engine.apply(match, const PriorityCommand.free('J1'));
          expect(open.match.phase, PriorityPhase.freeResponse);
          expect(open.match.pendingResponders.length, count - 1);
          expect(
            open.events.any((e) => e.type == PriorityEventType.automaticPass),
            isFalse,
          );
          match = closeWindow(open.match, respond: true);
          expect(match.players.every((p) => p.consumedActions == 1), isTrue);
          invariants(match);
        }
      });

      for (final free in [false, true]) {
        test(
          'PASS voluntario no consume en ventana ${free ? 'FREE' : 'ACTION'}',
          () {
            var match = engine
                .apply(
                  started(count),
                  free
                      ? const PriorityCommand.free('J1')
                      : const PriorityCommand.action('J1'),
                )
                .match;
            while (match.hasResponseWindow) {
              final id = match.priorityPlayerId!;
              final result = engine.apply(match, PriorityCommand.pass(id));
              expect(result.match.player(id).consumedActions, 0);
              expect(result.events.first.type, PriorityEventType.voluntaryPass);
              expect(result.events.first.playerId, id);
              match = result.match;
            }
            expect(match.priorityPlayerId, 'J1');
          },
        );
      }

      test(
        'Pases automáticos consecutivos, registrados sin otorgar prioridad',
        () {
          var match = started(count, points: 0);
          match = engine
              .apply(match, const PriorityCommand.setAdditionalActions('J1', 2))
              .match;
          match = closeWindow(
            engine.apply(match, const PriorityCommand.action('J1')).match,
            respond: true,
          );
          final skipped = engine.apply(
            match,
            const PriorityCommand.action('J1'),
          );
          expect(skipped.match.phase, PriorityPhase.activeTurn);
          expect(skipped.match.priorityPlayerId, 'J1');
          expect(
            skipped.events
                .where((e) => e.type == PriorityEventType.automaticPass)
                .map((e) => e.playerId),
            [for (var i = 2; i <= count; i++) 'J$i'],
          );
          expect(
            skipped.events.where(
              (e) => e.type == PriorityEventType.priorityChanged,
            ),
            isEmpty,
          );
          expect(
            skipped.match.players.skip(1).every((p) => p.consumedActions == 1),
            isTrue,
          );
          expect(
            skipped.events.every((e) => e.turn == 1 && e.round == 1),
            isTrue,
          );
          invariants(skipped.match);
        },
      );

      for (final free in [false, true]) {
        test(
          'Todas las combinaciones de reactivos en ${free ? 'FREE' : 'ACTION'}',
          () {
            // Enumerate all 3^(N-1) choices: unavailable, voluntary pass, response.
            final combinations = pow(3, count - 1).toInt();
            for (var code = 0; code < combinations; code++) {
              var match = started(count, points: 100, additional: 1);
              match = closeWindow(
                engine.apply(match, const PriorityCommand.action('J1')).match,
                respond: true,
              );
              final choices = <String, int>{};
              var digits = code;
              for (var i = 2; i <= count; i++) {
                choices['J$i'] = digits % 3;
                digits ~/= 3;
              }
              for (final entry in choices.entries) {
                if (entry.value == 0) {
                  match = engine
                      .apply(
                        match,
                        PriorityCommand.setAdditionalActions(entry.key, 0),
                      )
                      .match;
                }
              }
              final allEvents = <PriorityEvent>[];
              var result = engine.apply(
                match,
                free
                    ? const PriorityCommand.free('J1')
                    : const PriorityCommand.action('J1'),
              );
              match = result.match;
              allEvents.addAll(result.events);
              final expectedOrder = [
                for (final entry in choices.entries)
                  if (free || entry.value != 0) entry.key,
              ];
              final observedOrder = <String>[];
              while (match.hasResponseWindow) {
                final id = match.priorityPlayerId!;
                observedOrder.add(id);
                result = engine.apply(
                  match,
                  choices[id] == 1
                      ? PriorityCommand.pass(id)
                      : free
                      ? PriorityCommand.responseFree(id)
                      : PriorityCommand.responseAction(id),
                );
                match = result.match;
                allEvents.addAll(result.events);
                invariants(match);
              }
              expect(observedOrder, expectedOrder, reason: 'Combinación $code');
              expect(
                allEvents
                    .where((e) => e.type == PriorityEventType.automaticPass)
                    .map((e) => e.playerId),
                [
                  if (!free)
                    for (final entry in choices.entries)
                      if (entry.value == 0) entry.key,
                ],
              );
              for (final p in match.players) {
                final expectedConsumed = p.id == 'J1'
                    ? (free ? 1 : 2)
                    : (!free && choices[p.id] == 2 ? 2 : 1);
                expect(
                  p.consumedActions,
                  expectedConsumed,
                  reason: 'Combinación $code, jugador ${p.id}',
                );
              }
              expect(match.priorityPlayerId, 'J1');
              expect(match.turn, 1);
              final reset = engine
                  .apply(match, const PriorityCommand.endTurn('J1'))
                  .match;
              expect(
                reset.players.every(
                  (p) =>
                      p.consumedActions == 0 &&
                      p.availableActions == p.totalActions,
                ),
                isTrue,
              );
            }
          },
        );
      }

      test(
        'Modificar acciones conserva consumo, aplica mínimo cero y persiste',
        () {
          var match = started(count, additional: 1);
          for (var i = 0; i < 4; i++) {
            match = closeWindow(
              engine.apply(match, const PriorityCommand.action('J1')).match,
              respond: true,
            );
          }
          expect(match.players.every((p) => p.consumedActions == 4), isTrue);
          for (final p in match.players) {
            final result = engine.apply(
              match,
              PriorityCommand.setAdditionalActions(p.id, 0),
            );
            match = result.match;
            expect(match.player(p.id).totalActions, 3);
            expect(match.player(p.id).availableActions, 0);
            expect(match.player(p.id).consumedActions, 4);
            expect(result.events.single.previousValue, 1);
            expect(result.events.single.value, 0);
            match = engine
                .apply(match, PriorityCommand.setAdditionalActions(p.id, 3))
                .match;
            expect(match.player(p.id).availableActions, 2);
            expect(match.player(p.id).consumedActions, 4);
          }
          match = engine
              .apply(match, const PriorityCommand.endTurn('J1'))
              .match;
          expect(
            match.players.every(
              (p) =>
                  p.additionalActions == 3 &&
                  p.consumedActions == 0 &&
                  p.availableActions == 6,
            ),
            isTrue,
          );
        },
      );

      test('Ejemplo 4 totales/2 consumidas → 3/1 → 4/2', () {
        var match = started(count, additional: 1);
        for (var i = 0; i < 2; i++) {
          match = closeWindow(
            engine.apply(match, const PriorityCommand.action('J1')).match,
            respond: true,
          );
        }
        for (final p in match.players) {
          match = engine
              .apply(match, PriorityCommand.setAdditionalActions(p.id, 0))
              .match;
          expect(match.player(p.id).availableActions, 1);
          expect(match.player(p.id).consumedActions, 2);
          match = engine
              .apply(match, PriorityCommand.setAdditionalActions(p.id, 1))
              .match;
          expect(match.player(p.id).availableActions, 2);
        }
      });

      for (final phase in [
        PriorityPhase.activeTurn,
        PriorityPhase.actionResponse,
        PriorityPhase.freeResponse,
      ]) {
        test('Pausa y reanudación preservan fase $phase y ventana', () {
          var match = started(count);
          if (phase != PriorityPhase.activeTurn) {
            match = engine
                .apply(
                  match,
                  phase == PriorityPhase.actionResponse
                      ? const PriorityCommand.action('J1')
                      : const PriorityCommand.free('J1'),
                )
                .match;
          }
          final before = snapshot(match);
          final paused = engine.apply(match, const PriorityCommand.pause());
          expect(paused.match.phase, PriorityPhase.paused);
          expect(paused.match.underlyingPhase, phase);
          expect(paused.match.pendingResponders, match.pendingResponders);
          expect(paused.match.priorityPlayerId, match.priorityPlayerId);
          final resumed = engine.apply(
            paused.match,
            const PriorityCommand.resume(),
          );
          expect(snapshot(resumed.match).take(8), before.take(8));
          expect(snapshot(resumed.match).skip(9), before.skip(9));
          expect(resumed.match.revision, match.revision + 2);
          invariants(resumed.match);
        });
      }

      test('Finalización desde turno, ventana o pausa es terminal', () {
        final active = started(count);
        final action = engine
            .apply(active, const PriorityCommand.action('J1'))
            .match;
        final free = engine
            .apply(active, const PriorityCommand.free('J1'))
            .match;
        for (final original in [active, action, free]) {
          for (final match in [
            original,
            engine.apply(original, const PriorityCommand.pause()).match,
          ]) {
            final end = engine.apply(match, const PriorityCommand.finish());
            expect(end.match.phase, PriorityPhase.finished);
            expect(end.match.players, match.players);
            expect(end.match.turn, match.turn);
            expect(end.events.single.type, PriorityEventType.finished);
            invariants(end.match);
            for (final command in commands(end.match)) {
              expect(engine.rejection(end.match, command), isNotNull);
              expect(
                () => engine.apply(end.match, command),
                throwsA(isA<PriorityException>()),
              );
            }
          }
        }
      });

      test('Matriz de operaciones inválidas por fase y por jugador', () {
        final config = engine.configure(configuration(count));
        final active = engine
            .apply(config, const PriorityCommand.start())
            .match;
        final action = engine
            .apply(active, const PriorityCommand.action('J1'))
            .match;
        final free = engine
            .apply(active, const PriorityCommand.free('J1'))
            .match;
        for (final match in [
          config,
          active,
          action,
          free,
          engine.apply(action, const PriorityCommand.pause()).match,
          engine.apply(active, const PriorityCommand.finish()).match,
        ]) {
          final allowed = <(PriorityOperation, String?, int?)>{
            if (match.phase == PriorityPhase.configuration)
              (PriorityOperation.start, null, null),
            if (match.phase == PriorityPhase.activeTurn) ...{
              (PriorityOperation.action, 'J1', null),
              (PriorityOperation.free, 'J1', null),
              (PriorityOperation.endTurn, 'J1', null),
            },
            if (match.phase == PriorityPhase.actionResponse) ...{
              (PriorityOperation.responseAction, 'J2', null),
              (PriorityOperation.pass, 'J2', null),
            },
            if (match.phase == PriorityPhase.freeResponse) ...{
              (PriorityOperation.responseFree, 'J2', null),
              (PriorityOperation.pass, 'J2', null),
            },
            if (match.phase == PriorityPhase.paused)
              (PriorityOperation.resume, null, null),
            if ([
              PriorityPhase.activeTurn,
              PriorityPhase.actionResponse,
              PriorityPhase.freeResponse,
            ].contains(match.phase)) ...{
              (PriorityOperation.pause, null, null),
              for (final p in match.players) ...{
                (PriorityOperation.setAdditionalActions, p.id, 0),
                (PriorityOperation.setAdditionalActions, p.id, 3),
              },
            },
            if (match.phase != PriorityPhase.configuration &&
                match.phase != PriorityPhase.finished)
              (PriorityOperation.finish, null, null),
          };
          for (final command in commands(match)) {
            final error = engine.rejection(match, command);
            expect(
              error == null,
              allowed.contains((
                command.operation,
                command.playerId,
                command.additionalActions,
              )),
              reason:
                  '${match.phase}: ${command.operation} ${command.playerId}',
            );
            if (error != null) {
              rejects(match, command, error);
            } else {
              final before = snapshot(match);
              final result = engine.apply(match, command);
              invariants(result.match);
              expect(snapshot(match), before);
              expect(result.match.revision, match.revision + 1);
            }
          }
        }
        rejects(
          action,
          const PriorityCommand.responseFree('J2'),
          PriorityError.invalidPhase,
        );
        rejects(
          free,
          const PriorityCommand.responseAction('J2'),
          PriorityError.invalidPhase,
        );
        rejects(
          action,
          const PriorityCommand.action('J2'),
          PriorityError.invalidPhase,
        );
        rejects(
          action,
          const PriorityCommand.free('J2'),
          PriorityError.invalidPhase,
        );
        rejects(
          action,
          const PriorityCommand.endTurn('J1'),
          PriorityError.invalidPhase,
        );
        rejects(
          action,
          const PriorityCommand.endTurn('J2'),
          PriorityError.invalidPhase,
        );
        rejects(
          action,
          const PriorityCommand.responseAction('J1'),
          PriorityError.notPriorityHolder,
        );
        rejects(
          active,
          const PriorityCommand.action('J2'),
          PriorityError.notPriorityHolder,
        );
        rejects(
          active,
          const PriorityCommand.free('J2'),
          PriorityError.notPriorityHolder,
        );
        rejects(
          active,
          const PriorityCommand.endTurn('J2'),
          PriorityError.notPriorityHolder,
        );
        rejects(
          active,
          const PriorityCommand.pass('J1'),
          PriorityError.invalidPhase,
        );
        rejects(
          active,
          const PriorityCommand.responseAction('J1'),
          PriorityError.invalidPhase,
        );
        rejects(
          active,
          const PriorityCommand.responseFree('J1'),
          PriorityError.invalidPhase,
        );
        rejects(
          active,
          const PriorityCommand.setAdditionalActions('J2', -1),
          PriorityError.invalidAdditionalActions,
        );
        rejects(
          active,
          const PriorityCommand.action('no'),
          PriorityError.unknownPlayer,
        );
        rejects(
          active,
          const PriorityCommand.start(),
          PriorityError.invalidPhase,
        );
      });

      test(
        'Secuencias reproducibles: 1500 operaciones y comandos rechazados',
        () {
          final random = Random(117 + count);
          var match = started(count, points: 100);
          for (var step = 0; step < 1500; step++) {
            final options = commands(match)
                .where((c) => c.operation != PriorityOperation.finish)
                .toList();
            final command = options[random.nextInt(options.length)];
            final before = snapshot(match);
            final error = engine.rejection(match, command);
            if (error != null) {
              rejects(match, command, error);
            } else {
              final a = engine.apply(match, command);
              final b = engine.apply(match, command);
              expect(snapshot(a.match), snapshot(b.match));
              expect(
                a.events.map(
                  (e) => [
                    e.type,
                    e.playerId,
                    e.turn,
                    e.round,
                    e.previousValue,
                    e.value,
                  ],
                ),
                b.events.map(
                  (e) => [
                    e.type,
                    e.playerId,
                    e.turn,
                    e.round,
                    e.previousValue,
                    e.value,
                  ],
                ),
              );
              expect(snapshot(match), before);
              match = a.match;
            }
            invariants(match);
          }
        },
      );
    });
  }

  group('Cambios durante una ventana', () {
    PriorityMatch consumedBonus() {
      var match = started(3, points: 0, additional: 1);
      return closeWindow(
        engine.apply(match, const PriorityCommand.action('J1')).match,
        respond: true,
      );
    }

    test('Perder la última acción del reactivo actual pasa inmediatamente', () {
      var match = consumedBonus();
      match = engine.apply(match, const PriorityCommand.action('J1')).match;
      final result = engine.apply(
        match,
        const PriorityCommand.setAdditionalActions('J2', 0),
      );
      expect(result.match.pendingResponders, ['J3']);
      expect(result.match.priorityPlayerId, 'J3');
      expect(result.match.player('J2').consumedActions, 1);
      expect(result.events.map((e) => e.type), [
        PriorityEventType.additionalActionsChanged,
        PriorityEventType.automaticPass,
        PriorityEventType.priorityChanged,
      ]);
      rejects(
        result.match,
        const PriorityCommand.responseAction('J2'),
        PriorityError.notPriorityHolder,
      );
    });

    test('Pendiente futuro sin acciones espera hasta que le corresponda', () {
      var match = consumedBonus();
      match = engine.apply(match, const PriorityCommand.action('J1')).match;
      var change = engine.apply(
        match,
        const PriorityCommand.setAdditionalActions('J3', 0),
      );
      expect(change.match.priorityPlayerId, 'J2');
      expect(change.match.pendingResponders, ['J2', 'J3']);
      expect(change.events.length, 1);
      final advance = engine.apply(
        change.match,
        const PriorityCommand.pass('J2'),
      );
      expect(advance.match.phase, PriorityPhase.activeTurn);
      expect(advance.events.map((e) => e.type), [
        PriorityEventType.voluntaryPass,
        PriorityEventType.automaticPass,
        PriorityEventType.priorityChanged,
      ]);
      change = engine.apply(
        change.match,
        const PriorityCommand.setAdditionalActions('J3', 1),
      );
      final recovered = engine.apply(
        change.match,
        const PriorityCommand.pass('J2'),
      );
      expect(recovered.match.priorityPlayerId, 'J3');
      expect(recovered.match.player('J3').availableActions, 1);
      expect(
        recovered.events.any((e) => e.type == PriorityEventType.automaticPass),
        isFalse,
      );
    });

    test('Recuperar acciones después del pase no reabre su oportunidad', () {
      var match = consumedBonus();
      match = engine.apply(match, const PriorityCommand.action('J1')).match;
      match = engine
          .apply(match, const PriorityCommand.setAdditionalActions('J2', 0))
          .match;
      match = engine
          .apply(match, const PriorityCommand.setAdditionalActions('J2', 2))
          .match;
      expect(match.pendingResponders, ['J3']);
      rejects(
        match,
        const PriorityCommand.responseAction('J2'),
        PriorityError.notPriorityHolder,
      );
      match = closeWindow(match);
      expect(match.priorityPlayerId, 'J1');
      expect(match.player('J2').availableActions, 2);
    });

    test('Cambios en FREE nunca generan pase automático', () {
      var match = consumedBonus();
      match = engine.apply(match, const PriorityCommand.free('J1')).match;
      final result = engine.apply(
        match,
        const PriorityCommand.setAdditionalActions('J2', 0),
      );
      expect(result.match.player('J2').availableActions, 0);
      expect(result.match.priorityPlayerId, 'J2');
      expect(result.events.length, 1);
      expect(
        engine.rejection(
          result.match,
          const PriorityCommand.responseFree('J2'),
        ),
        isNull,
      );
    });

    test('Cambiar al activo no interrumpe las respuestas pendientes', () {
      var match = consumedBonus();
      match = engine.apply(match, const PriorityCommand.action('J1')).match;
      final changed = engine.apply(
        match,
        const PriorityCommand.setAdditionalActions('J1', 0),
      );
      expect(changed.match.player('J1').consumedActions, 2);
      expect(changed.match.player('J1').availableActions, 0);
      expect(changed.match.pendingResponders, ['J2', 'J3']);
      expect(changed.events.length, 1);
    });

    test('Una respuesta o pase no puede repetirse ni crear otra ventana', () {
      var match = engine
          .apply(started(3), const PriorityCommand.action('J1'))
          .match;
      match = engine
          .apply(match, const PriorityCommand.responseAction('J2'))
          .match;
      expect(match.pendingResponders, ['J3']);
      rejects(
        match,
        const PriorityCommand.responseAction('J2'),
        PriorityError.notPriorityHolder,
      );
      rejects(
        match,
        const PriorityCommand.pass('J2'),
        PriorityError.notPriorityHolder,
      );
      match = engine.apply(match, const PriorityCommand.pass('J3')).match;
      rejects(
        match,
        const PriorityCommand.pass('J3'),
        PriorityError.invalidPhase,
      );
      rejects(
        match,
        const PriorityCommand.responseAction('J3'),
        PriorityError.invalidPhase,
      );
      expect(match.players.map((p) => p.consumedActions), [1, 1, 0]);
    });

    test('Eventos de cambio de ronda asignados a su turno correspondiente', () {
      var match = started(2);
      match = engine.apply(match, const PriorityCommand.endTurn('J1')).match;
      final result = engine.apply(match, const PriorityCommand.endTurn('J2'));
      expect(result.events.map((e) => [e.type, e.playerId, e.turn, e.round]), [
        [PriorityEventType.turnEnded, 'J2', 2, 1],
        [PriorityEventType.turnStarted, 'J1', 3, 2],
        [PriorityEventType.priorityChanged, 'J1', 3, 2],
      ]);
    });
  });
}

final class CountingRandom implements Random {
  int calls = 0;
  @override
  int nextInt(int max) {
    calls++;
    return 0;
  }

  @override
  bool nextBool() => throw UnimplementedError();
  @override
  double nextDouble() => throw UnimplementedError();
}

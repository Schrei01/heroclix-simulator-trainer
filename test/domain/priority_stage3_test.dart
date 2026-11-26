import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/domain/priority/priority.dart';

import '../support/priority_stage3_fixtures.dart';

void rejected(
  PriorityMatch match,
  PriorityCommand command,
  PriorityError error,
) {
  expect(priorityEngine.rejection(match, command), error);
  expect(
    () => priorityEngine.apply(match, command),
    throwsA(isA<PriorityException>().having((e) => e.code, 'code', error)),
  );
}

void invariant(PriorityMatch match) {
  final live = match.players.where((p) => !p.eliminated).toList();
  expect(live, isNotEmpty);
  expect(match.roundPending.toSet().length, match.roundPending.length);
  expect(
    match.pendingResponders.toSet().length,
    match.pendingResponders.length,
  );
  for (final p in match.players) {
    expect(p.victoryPoints, greaterThanOrEqualTo(0));
    expect(p.remainingTime!, greaterThanOrEqualTo(Duration.zero));
    expect(p.spentTime, greaterThanOrEqualTo(Duration.zero));
    if (p.eliminated) {
      expect(p.availableActions, 0);
      expect(match.pendingResponders, isNot(contains(p.id)));
      expect(match.roundPending, isNot(contains(p.id)));
      expect(match.priorityPlayerId, isNot(p.id));
    }
  }
  if (match.phase == PriorityPhase.finished) {
    expect(match.priorityPlayerId, isNull);
    expect(match.pendingResponders, isEmpty);
    return;
  }
  expect(live.length, greaterThanOrEqualTo(2));
  expect(match.player(match.activePlayerId!).eliminated, isFalse);
  expect(match.roundPending.first, match.activePlayerId);
  expect(match.player(match.priorityPlayerId!).eliminated, isFalse);
  if (match.hasResponseWindow) {
    expect(match.pendingResponders.first, match.priorityPlayerId);
    expect(match.pendingResponders, isNot(contains(match.activePlayerId)));
  } else {
    expect(match.priorityPlayerId, match.activePlayerId);
  }
}

void main() {
  test('configuración de reloj válida, opcional y compatible con sorteo', () {
    expect(priorityConfig(2, clock: false).clockEnabled, isFalse);
    for (final time in [Duration.zero, const Duration(seconds: -1)]) {
      expect(() => priorityConfig(2, time: time), throwsArgumentError);
    }
    final random = PriorityConfiguration.randomStart(
      players: priorityConfig(6).players,
      random: Random(10),
      clockEnabled: true,
      initialTime: const Duration(seconds: 7),
    );
    expect(random.initialTime, const Duration(seconds: 7));
    expect(random.clockEnabled, isTrue);
  });

  for (var n = 2; n <= 6; n++) {
    group('$n jugadores', () {
      test('solo descuenta prioridad y transfiere en ACTION, FREE, PASS y END TURN', () {
        var match = priorityGame(n);
        final initial = match;
        var charged = priorityEngine.advanceTime(
          match,
          const Duration(seconds: 3),
        );
        match = charged.match;
        expect(charged.events, isEmpty);
        expect(match.revision, initial.revision);
        expect(
          match.player('J1').remainingTime,
          const Duration(minutes: 29, seconds: 57),
        );
        expect(initial.player('J1').remainingTime, const Duration(minutes: 30));
        match = priorityStep(match, const PriorityCommand.action('J1'));
        for (var i = 2; i <= n; i++) {
          expect(match.priorityPlayerId, 'J$i');
          match = priorityEngine.advanceTime(match, Duration(seconds: i)).match;
          match = priorityStep(
            match,
            i.isEven
                ? PriorityCommand.responseAction('J$i')
                : PriorityCommand.pass('J$i'),
          );
        }
        match = priorityStep(match, const PriorityCommand.free('J1'));
        for (var i = 2; i <= n; i++) {
          match = priorityEngine
              .advanceTime(match, const Duration(seconds: 1))
              .match;
          match = priorityStep(match, PriorityCommand.responseFree('J$i'));
        }
        for (var i = 2; i <= n; i++) {
          expect(match.player('J$i').spentTime, Duration(seconds: i + 1));
        }
        final before = match.players.map((p) => p.remainingTime).toList();
        match = priorityStep(match, const PriorityCommand.endTurn('J1'));
        expect(match.players.map((p) => p.remainingTime), before);
        expect(match.priorityPlayerId, 'J2');
        expect(match.players.every((p) => p.consumedActions == 0), isTrue);
      });

      test('pausa conserva ventana, no cobra durante pausa y corrección requiere reanudar', () {
        var match = priorityStep(
          priorityGame(n),
          const PriorityCommand.action('J1'),
        );
        final pending = match.pendingResponders;
        match = priorityEngine
            .advanceTime(match, const Duration(seconds: 4))
            .match;
        match = priorityStep(match, const PriorityCommand.pause());
        final paused = match;
        expect(
          priorityEngine.advanceTime(match, const Duration(hours: 4)).match,
          same(paused),
        );
        match = priorityStep(
          match,
          const PriorityCommand.setRemainingTime('J2', Duration(seconds: 12)),
        );
        expect(match.isPaused, isTrue);
        expect(match.player('J2').spentTime, const Duration(seconds: 4));
        expect(match.pendingResponders, pending);
        match = priorityStep(match, const PriorityCommand.resume());
        expect(match.phase, PriorityPhase.actionResponse);
        match = priorityEngine
            .advanceTime(match, const Duration(seconds: 2))
            .match;
        expect(match.player('J2').remainingTime, const Duration(seconds: 10));
      });

      test(
        'agotamiento exacto detiene todos sin eliminar y no repite eventos',
        () {
          var match = priorityGame(n, time: const Duration(seconds: 10));
          final expired = priorityEngine.advanceTime(
            match,
            const Duration(hours: 1),
          );
          match = expired.match;
          expect(match.isPaused, isTrue);
          expect(match.pauseReason, PriorityPauseReason.timeExpired);
          expect(match.timedOutPlayerId, 'J1');
          expect(match.player('J1').remainingTime, Duration.zero);
          expect(match.player('J1').spentTime, const Duration(seconds: 10));
          expect(match.players.every((p) => !p.eliminated), isTrue);
          expect(
            match.players
                .skip(1)
                .every((p) => p.remainingTime == const Duration(seconds: 10)),
            isTrue,
          );
          expect(
            expired.events
                .where((e) => e.type == PriorityEventType.timeExpired)
                .length,
            1,
          );
          expect(
            priorityEngine.advanceTime(match, const Duration(days: 10)).match,
            same(match),
          );
          rejected(
            match,
            const PriorityCommand.resume(),
            PriorityError.timeExhausted,
          );
          rejected(
            match,
            const PriorityCommand.action('J1'),
            PriorityError.invalidPhase,
          );
          match = priorityStep(
            match,
            const PriorityCommand.setRemainingTime('J1', Duration(seconds: 20)),
          );
          expect(match.isPaused, isTrue);
          match = priorityStep(match, const PriorityCommand.resume());
          expect(match.timedOutPlayerId, isNull);
          expect(match.player('J1').spentTime, const Duration(seconds: 10));
        },
      );

      test(
        'puntuaciones, correcciones, empates y restablecimiento de acciones',
        () {
          var match = priorityGame(n);
          match = priorityStep(
            match,
            const PriorityCommand.adjustVictoryPoints('J1', 100),
          );
          match = priorityStep(
            match,
            const PriorityCommand.adjustVictoryPoints('J1', -20),
          );
          match = priorityStep(
            match,
            const PriorityCommand.setVictoryPoints('J2', 80),
          );
          expect(match.standings.take(2).map((s) => s.position), [1, 1]);
          expect(match.standings.take(2).map((s) => s.player.id), ['J1', 'J2']);
          if (n > 2) expect(match.standings[2].position, 3);
          expect(() => match.standings.clear(), throwsUnsupportedError);
          rejected(
            match,
            const PriorityCommand.adjustVictoryPoints('J1', -81),
            PriorityError.invalidPoints,
          );
          rejected(
            match,
            const PriorityCommand.setVictoryPoints('J1', -1),
            PriorityError.invalidPoints,
          );
          match = priorityStep(match, const PriorityCommand.pause());
          match = priorityStep(
            match,
            const PriorityCommand.adjustVictoryPoints('J1', 1),
          );
          expect(match.player('J1').victoryPoints, 81);
          match = priorityStep(match, const PriorityCommand.resume());
          match = priorityStep(match, const PriorityCommand.endTurn('J1'));
          expect(match.player('J1').victoryPoints, 81);
          expect(match.player('J2').victoryPoints, 80);
        },
      );

      for (final free in [false, true]) {
        test(
          'elimina cada asiento durante ventana ${free ? 'FREE' : 'ACTION'}',
          () {
            for (var removed = 1; removed <= n; removed++) {
              var match = priorityGame(n);
              match = priorityStep(
                match,
                PriorityCommand.setVictoryPoints('J$removed', 123),
              );
              match = priorityStep(
                match,
                free
                    ? const PriorityCommand.free('J1')
                    : const PriorityCommand.action('J1'),
              );
              final prior = match;
              match = priorityStep(
                match,
                PriorityCommand.eliminate('J$removed'),
              );
              expect(prior.player('J$removed').eliminated, isFalse);
              expect(match.player('J$removed').eliminated, isTrue);
              expect(match.player('J$removed').victoryPoints, 123);
              invariant(match);
              if (n == 2) {
                expect(match.phase, PriorityPhase.finished);
              } else if (removed == 1) {
                expect(match.turn, 2);
                expect(match.activePlayerId, 'J2');
                expect(match.pendingResponders, isEmpty);
                expect(
                  match.players
                      .where((p) => !p.eliminated)
                      .every((p) => p.consumedActions == 0),
                  isTrue,
                );
              } else {
                expect(match.activePlayerId, 'J1');
                expect(match.priorityPlayerId, removed == 2 ? 'J3' : 'J2');
                expect(match.pendingResponders, isNot(contains('J$removed')));
                while (match.hasResponseWindow) {
                  match = priorityStep(
                    match,
                    PriorityCommand.pass(match.priorityPlayerId!),
                  );
                }
                expect(match.priorityPlayerId, 'J1');
                rejected(
                  match,
                  PriorityCommand.eliminate('J$removed'),
                  PriorityError.eliminatedPlayer,
                );
                rejected(
                  match,
                  PriorityCommand.setAdditionalActions('J$removed', 0),
                  PriorityError.eliminatedPlayer,
                );
                rejected(
                  match,
                  PriorityCommand.setRemainingTime(
                    'J$removed',
                    const Duration(seconds: 1),
                  ),
                  PriorityError.eliminatedPlayer,
                );
                match = priorityStep(
                  match,
                  PriorityCommand.adjustVictoryPoints('J$removed', -23),
                );
                expect(match.player('J$removed').victoryPoints, 100);
              }
            }
          },
        );
      }

      test('partida finaliza al quedar uno y congela todos los relojes', () {
        var match = priorityGame(n);
        match = priorityEngine
            .advanceTime(match, const Duration(seconds: 1))
            .match;
        for (var i = 2; i <= n; i++) {
          match = priorityStep(
            match,
            PriorityCommand.setVictoryPoints('J$i', i * 10),
          );
          match = priorityStep(match, PriorityCommand.eliminate('J$i'));
        }
        expect(match.phase, PriorityPhase.finished);
        expect(match.priorityPlayerId, isNull);
        expect(match.isPaused, isFalse);
        expect(
          match.standings.first.player.id,
          'J$n',
        ); // Survivor is not an invented winner.
        expect(
          priorityEngine.advanceTime(match, const Duration(days: 1)).match,
          same(match),
        );
        final frozenTimes = match.players.map((p) => p.remainingTime).toList();
        match = priorityStep(
          match,
          const PriorityCommand.setVictoryPoints('J1', 999),
        );
        expect(match.standings.first.player.id, 'J1');
        expect(match.phase, PriorityPhase.finished);
        expect(match.priorityPlayerId, isNull);
        expect(match.players.map((p) => p.remainingTime), frozenTimes);
        rejected(
          match,
          const PriorityCommand.eliminate('J1'),
          PriorityError.invalidPhase,
        );
        rejected(
          match,
          const PriorityCommand.resume(),
          PriorityError.invalidPhase,
        );
      });

      test('secuencias aleatorias con puntuación, reloj y eliminación conservan invariantes', () {
        final random = Random(909 + n);
        for (var game = 0; game < 20; game++) {
          var match = priorityGame(n, time: const Duration(seconds: 15));
          for (var commandIndex = 0; commandIndex < 100; commandIndex++) {
            if (match.phase == PriorityPhase.finished) break;
            invariant(match);
            final id = 'J${1 + random.nextInt(n)}';
            final choices = [
              PriorityCommand.action(id),
              PriorityCommand.free(id),
              PriorityCommand.pass(id),
              PriorityCommand.responseAction(id),
              PriorityCommand.responseFree(id),
              PriorityCommand.endTurn(id),
              PriorityCommand.eliminate(id),
              PriorityCommand.adjustVictoryPoints(id, random.nextInt(11) - 5),
              PriorityCommand.setRemainingTime(
                id,
                Duration(seconds: random.nextInt(20)),
              ),
              const PriorityCommand.pause(),
              const PriorityCommand.resume(),
            ];
            final command = choices[random.nextInt(choices.length)];
            if (priorityEngine.rejection(match, command) == null) {
              match = priorityStep(match, command);
            }
            match = priorityEngine
                .advanceTime(
                  match,
                  Duration(milliseconds: random.nextInt(2000)),
                )
                .match;
          }
          invariant(match);
        }
      });
    });
  }

  test(
    'microsegundos y retrasos de actualización no acumulan error ni revisiones',
    () {
      var incremental = priorityGame(2, time: const Duration(seconds: 1));
      final original = incremental;
      for (var i = 0; i < 999; i++) {
        incremental = priorityEngine
            .advanceTime(incremental, const Duration(microseconds: 1000))
            .match;
      }
      final once = priorityEngine
          .advanceTime(original, const Duration(milliseconds: 999))
          .match;
      expect(
        incremental.player('J1').remainingTime,
        once.player('J1').remainingTime,
      );
      expect(incremental.revision, original.revision);
      incremental = priorityEngine
          .advanceTime(incremental, const Duration(microseconds: 1000))
          .match;
      expect(incremental.isPaused, isTrue);
      expect(incremental.revision, original.revision + 1);
    },
  );

  test(
    'un pase automático no activa reloj agotado; FREE sí abre su oportunidad',
    () {
      var match = priorityGame(3);
      for (var i = 0; i < 3; i++) {
        match = priorityStep(match, const PriorityCommand.free('J1'));
        match = priorityStep(match, const PriorityCommand.responseFree('J2'));
        match = priorityStep(match, const PriorityCommand.pass('J3'));
      }
      // Consume all J2 actions with real ACTION responses.
      for (var i = 0; i < 3; i++) {
        match = priorityStep(match, const PriorityCommand.action('J1'));
        match = priorityStep(match, const PriorityCommand.responseAction('J2'));
        match = priorityStep(match, const PriorityCommand.pass('J3'));
      }
      match = priorityStep(
        match,
        const PriorityCommand.setAdditionalActions('J1', 2),
      );
      match = priorityStep(
        match,
        const PriorityCommand.setRemainingTime('J2', Duration.zero),
      );
      match = priorityStep(match, const PriorityCommand.resume());
      match = priorityStep(match, const PriorityCommand.action('J1'));
      expect(match.priorityPlayerId, 'J3');
      expect(match.isPaused, isFalse);
      match = priorityStep(match, const PriorityCommand.pass('J3'));
      match = priorityStep(match, const PriorityCommand.free('J1'));
      expect(match.priorityPlayerId, 'J2');
      expect(match.isPaused, isTrue);
      expect(match.timedOutPlayerId, 'J2');
    },
  );

  test('rondas siguen los asientos supervivientes, no el tamaño inicial', () {
    var match = priorityGame(4, first: 'J3');
    match = priorityStep(match, const PriorityCommand.eliminate('J4'));
    expect(match.roundPending, ['J3', 'J1', 'J2']);
    match = priorityStep(match, const PriorityCommand.endTurn('J3'));
    expect(match.activePlayerId, 'J1');
    match = priorityStep(match, const PriorityCommand.eliminate('J1'));
    expect(match.activePlayerId, 'J2');
    expect(match.round, 1);
    match = priorityStep(match, const PriorityCommand.endTurn('J2'));
    expect(match.activePlayerId, 'J3');
    expect(match.round, 2);
    expect(match.roundPending, ['J3', 'J2']);
    match = priorityStep(match, const PriorityCommand.eliminate('J3'));
    expect(match.phase, PriorityPhase.finished);
  });

  test(
    'eliminar último pendiente o ya respondido no duplica oportunidades',
    () {
      var match = priorityStep(
        priorityGame(4),
        const PriorityCommand.free('J1'),
      );
      match = priorityStep(match, const PriorityCommand.responseFree('J2'));
      match = priorityStep(match, const PriorityCommand.eliminate('J2'));
      expect(match.pendingResponders, ['J3', 'J4']);
      match = priorityStep(match, const PriorityCommand.pass('J3'));
      match = priorityStep(match, const PriorityCommand.eliminate('J4'));
      expect(match.priorityPlayerId, 'J1');
      expect(match.pendingResponders, isEmpty);
    },
  );

  test(
    'corrección a cero pausa sin eliminar y permite eliminar al agotado',
    () {
      var match = priorityStep(
        priorityGame(3),
        const PriorityCommand.setRemainingTime('J1', Duration.zero),
      );
      expect(match.timedOutPlayerId, 'J1');
      rejected(
        match,
        const PriorityCommand.resume(),
        PriorityError.timeExhausted,
      );
      match = priorityStep(match, const PriorityCommand.eliminate('J1'));
      expect(match.isPaused, isTrue);
      expect(match.activePlayerId, 'J2');
      expect(match.timedOutPlayerId, isNull);
      match = priorityStep(match, const PriorityCommand.resume());
      expect(match.isPaused, isFalse);
    },
  );

  test(
    'eliminar al reactivo agotado conserva ventana pausada para los demás',
    () {
      var match = priorityStep(
        priorityGame(3, time: const Duration(seconds: 5)),
        const PriorityCommand.free('J1'),
      );
      match = priorityEngine
          .advanceTime(match, const Duration(seconds: 6))
          .match;
      expect(match.timedOutPlayerId, 'J2');
      match = priorityStep(match, const PriorityCommand.eliminate('J2'));
      expect(match.isPaused, isTrue);
      expect(match.underlyingPhase, PriorityPhase.freeResponse);
      expect(match.priorityPlayerId, 'J3');
      expect(match.activePlayerId, 'J1');
      expect(match.pendingResponders, ['J3']);
      match = priorityStep(match, const PriorityCommand.resume());
      match = priorityStep(match, const PriorityCommand.pass('J3'));
      expect(match.priorityPlayerId, 'J1');
    },
  );

  test('operaciones inválidas de nuevas funciones y límites enteros', () {
    var match = priorityGame(3, clock: false);
    expect(
      priorityEngine.advanceTime(match, const Duration(days: 5)).match,
      same(match),
    );
    rejected(
      match,
      const PriorityCommand.setRemainingTime('J1', Duration(seconds: 1)),
      PriorityError.invalidTime,
    );
    expect(
      () => priorityEngine.advanceTime(match, const Duration(seconds: -1)),
      throwsArgumentError,
    );
    rejected(
      match,
      const PriorityCommand.eliminate('otro'),
      PriorityError.unknownPlayer,
    );
    match = priorityStep(
      match,
      const PriorityCommand.setVictoryPoints('J1', 0x7fffffffffffffff),
    );
    rejected(
      match,
      const PriorityCommand.adjustVictoryPoints('J1', 1),
      PriorityError.invalidPoints,
    );
    expect(match.player('J1').victoryPoints, 0x7fffffffffffffff);
    match = priorityGame(3);
    rejected(
      match,
      const PriorityCommand.setRemainingTime('J1', Duration(seconds: -1)),
      PriorityError.invalidTime,
    );
    final config = priorityEngine.configure(priorityConfig(3));
    for (final c in [
      const PriorityCommand.eliminate('J1'),
      const PriorityCommand.setVictoryPoints('J1', 0),
      const PriorityCommand.setRemainingTime('J1', Duration(seconds: 1)),
    ]) {
      rejected(config, c, PriorityError.invalidPhase);
    }
  });
}

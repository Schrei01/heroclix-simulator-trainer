import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/domain/priority/priority.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_controller.dart';

import 'support/priority_stage3_fixtures.dart';

void main() {
  for (var n = 2; n <= 6; n++) {
    test('$n participantes: cobro al ejecutar sin depender de ticks', () {
      final clock = PriorityFakeClock();
      final c = PriorityController(
        inputCooldown: Duration.zero,
        elapsedClock: clock.read,
      );
      addTearDown(c.dispose);
      c.start(priorityConfig(n));
      clock.advance(const Duration(milliseconds: 1234));
      final revision = c.value!.revision;
      expect(
        c.dispatch(
          const PriorityCommand.action('J1'),
          expectedRevision: revision,
        ),
        isTrue,
      );
      expect(
        c.value!.player('J1').spentTime,
        const Duration(milliseconds: 1234),
      );
      for (var i = 2; i <= n; i++) {
        clock.advance(Duration(milliseconds: i * 100));
        expect(
          c.dispatch(
            PriorityCommand.pass('J$i'),
            expectedRevision: c.value!.revision,
          ),
          isTrue,
        );
        expect(
          c.value!.player('J$i').spentTime,
          Duration(milliseconds: i * 100),
        );
      }
      expect(c.value!.priorityPlayerId, 'J1');
      expect(
        c.value!.player('J1').spentTime,
        const Duration(milliseconds: 1234),
      );
    });
  }

  test('caducidad entre render y pulsación rechaza la acción y no consume', () {
    final clock = PriorityFakeClock();
    final c = PriorityController(elapsedClock: clock.read);
    addTearDown(c.dispose);
    c.start(priorityConfig(3, time: const Duration(seconds: 3)));
    final revision = c.value!.revision;
    clock.advance(const Duration(seconds: 30));
    expect(
      c.dispatch(
        const PriorityCommand.action('J1'),
        expectedRevision: revision,
      ),
      isFalse,
    );
    expect(c.value!.isPaused, isTrue);
    expect(c.value!.player('J1').consumedActions, 0);
    expect(c.value!.player('J1').spentTime, const Duration(seconds: 3));
    final events = c.events;
    c.synchronizeClock();
    expect(c.events, same(events));
  });

  test('segundo plano cobra hasta salir y conserva pausa hasta reanudar', () {
    final clock = PriorityFakeClock();
    final c = PriorityController(
      inputCooldown: Duration.zero,
      elapsedClock: clock.read,
    );
    addTearDown(c.dispose);
    c.start(priorityConfig(3));
    c.dispatch(
      const PriorityCommand.free('J1'),
      expectedRevision: c.value!.revision,
    );
    clock.advance(const Duration(seconds: 7));
    c.setForeground(false);
    expect(c.value!.pauseReason, PriorityPauseReason.background);
    expect(c.value!.player('J2').spentTime, const Duration(seconds: 7));
    final revision = c.value!.revision;
    clock.advance(const Duration(hours: 2));
    c.setForeground(false);
    expect(c.value!.revision, revision);
    expect(c.can(const PriorityCommand.resume()), isFalse);
    c.setForeground(true);
    expect(c.value!.isPaused, isTrue);
    expect(c.value!.player('J2').spentTime, const Duration(seconds: 7));
    expect(c.can(const PriorityCommand.resume()), isTrue);
    c.dispatch(
      const PriorityCommand.resume(),
      expectedRevision: c.value!.revision,
    );
    clock.advance(const Duration(seconds: 2));
    c.synchronizeClock();
    expect(c.value!.player('J2').spentTime, const Duration(seconds: 9));
    expect(c.value!.phase, PriorityPhase.freeResponse);
    expect(c.value!.pendingResponders, ['J2', 'J3']);
  });

  test('sin reloj no cambia estado al salir ni inicia un cronómetro', () {
    final clock = PriorityFakeClock();
    final c = PriorityController(elapsedClock: clock.read);
    addTearDown(c.dispose);
    c.start(priorityConfig(2, clock: false));
    final before = c.value;
    clock.advance(const Duration(hours: 20));
    c.synchronizeClock();
    c.pauseForNavigation();
    c.setForeground(false);
    c.setForeground(true);
    expect(c.value, same(before));
    expect(c.value!.players.every((p) => p.remainingTime == null), isTrue);
  });

  test('inicio en segundo plano y corrección manual no arrancan solos', () {
    final clock = PriorityFakeClock();
    final c = PriorityController(
      inputCooldown: Duration.zero,
      elapsedClock: clock.read,
    );
    addTearDown(c.dispose);
    c.setForeground(false);
    c.start(priorityConfig(3));
    expect(c.value!.isPaused, isTrue);
    c.setForeground(true);
    c.dispatch(
      const PriorityCommand.resume(),
      expectedRevision: c.value!.revision,
    );
    clock.advance(const Duration(seconds: 4));
    c.prepareTimeCorrection();
    clock.advance(const Duration(hours: 1));
    c.dispatch(
      const PriorityCommand.setRemainingTime('J1', Duration(seconds: 15)),
      expectedRevision: c.value!.revision,
    );
    expect(c.value!.isPaused, isTrue);
    expect(c.value!.player('J1').spentTime, const Duration(seconds: 4));
    expect(c.value!.player('J1').remainingTime, const Duration(seconds: 15));
  });

  testWidgets(
    'ticker publica tiempo real sin cambiar revisión y se cancela al terminar',
    (t) async {
      final clock = PriorityFakeClock();
      final c = PriorityController(
        inputCooldown: Duration.zero,
        elapsedClock: clock.read,
      );
      c.start(priorityConfig(2, time: const Duration(seconds: 10)));
      final revision = c.value!.revision;
      clock.advance(const Duration(seconds: 3));
      await t.pump(const Duration(milliseconds: 100));
      expect(c.value!.player('J1').remainingTime, const Duration(seconds: 7));
      expect(c.value!.revision, revision);
      c.dispatch(
        const PriorityCommand.eliminate('J2'),
        expectedRevision: c.value!.revision,
      );
      final finished = c.value;
      clock.advance(const Duration(hours: 1));
      await t.pump(const Duration(seconds: 5));
      expect(c.value, same(finished));
      c.reset();
      c.start(priorityConfig(3));
      c.dispose();
      await t.pump(const Duration(seconds: 1));
    },
  );

  test(
    'la disponibilidad se notifica también al volver de segundo plano pausado',
    () {
      final clock = PriorityFakeClock();
      final c = PriorityController(elapsedClock: clock.read);
      addTearDown(c.dispose);
      c.start(priorityConfig(3));
      c.setForeground(false);
      var notifications = 0;
      c.addListener(() => notifications++);
      c.setForeground(true);
      expect(notifications, 1);
      expect(c.can(const PriorityCommand.resume()), isTrue);
    },
  );
}

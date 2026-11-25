import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/domain/priority/priority.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_controller.dart';

PriorityConfiguration players(int count, {int points = 300}) =>
    PriorityConfiguration(
      players: [
        for (var i = 1; i <= count; i++)
          PriorityPlayerConfiguration(
            id: 'J$i',
            name: 'Jugador $i',
            buildPoints: points,
          ),
      ],
    );

void main() {
  for (var count = 2; count <= 6; count++) {
    test('$count jugadores: adaptador coincide con motor en cada comando', () {
      final controller = PriorityController(inputCooldown: Duration.zero);
      addTearDown(controller.dispose);
      final config = players(count);
      const engine = PriorityEngine();
      var expected = engine
          .apply(engine.configure(config), const PriorityCommand.start())
          .match;
      expect(controller.start(config), isTrue);
      void apply(PriorityCommand command) {
        final transition = engine.apply(expected, command);
        expect(
          controller.dispatch(command, expectedRevision: expected.revision),
          isTrue,
        );
        expected = transition.match;
        expect(controller.value!.phase, expected.phase);
        expect(controller.value!.priorityPlayerId, expected.priorityPlayerId);
        expect(controller.value!.pendingResponders, expected.pendingResponders);
        expect(controller.value!.turn, expected.turn);
        expect(controller.value!.round, expected.round);
        expect(
          controller.value!.players.map(
            (p) => [p.totalActions, p.consumedActions, p.availableActions],
          ),
          expected.players.map(
            (p) => [p.totalActions, p.consumedActions, p.availableActions],
          ),
        );
        expect(
          controller.events.map((e) => [e.type, e.playerId]),
          transition.events.map((e) => [e.type, e.playerId]),
        );
      }

      for (var turn = 0; turn < count * 2; turn++) {
        final active = expected.activePlayerId!;
        apply(PriorityCommand.action(active));
        while (expected.hasResponseWindow) {
          apply(PriorityCommand.responseAction(expected.priorityPlayerId!));
        }
        apply(PriorityCommand.free(active));
        while (expected.hasResponseWindow) {
          apply(PriorityCommand.pass(expected.priorityPlayerId!));
        }
        apply(PriorityCommand.setAdditionalActions(active, 2));
        apply(PriorityCommand.endTurn(active));
      }
    });
  }

  test('no reemplaza una partida en curso y rechaza revisiones antiguas', () {
    final c = PriorityController(inputCooldown: Duration.zero);
    addTearDown(c.dispose);
    expect(c.can(const PriorityCommand.action('J1')), isFalse);
    expect(
      c.dispatch(const PriorityCommand.action('J1'), expectedRevision: 0),
      isFalse,
    );
    c.start(players(3));
    final initial = c.value;
    expect(c.start(players(6)), isFalse);
    expect(c.value, same(initial));
    expect(
      c.dispatch(
        const PriorityCommand.action('J2'),
        expectedRevision: initial!.revision,
      ),
      isFalse,
    );
    expect(c.value, same(initial));
    expect(
      c.dispatch(
        const PriorityCommand.action('J1'),
        expectedRevision: initial.revision,
      ),
      isTrue,
    );
    final changed = c.value;
    expect(
      c.dispatch(
        const PriorityCommand.pass('J2'),
        expectedRevision: initial.revision,
      ),
      isFalse,
    );
    expect(c.value, same(changed));
    expect(
      c.dispatch(
        const PriorityCommand.responseFree('J2'),
        expectedRevision: changed!.revision,
      ),
      isFalse,
    );
    expect(c.value, same(changed));
  });

  testWidgets(
    'pulsación doble protegida aunque la prioridad regrese sin respuestas',
    (t) async {
      final c = PriorityController();
      c.start(players(2, points: 100));
      bool send(PriorityCommand command) =>
          c.dispatch(command, expectedRevision: c.value!.revision);
      send(const PriorityCommand.setAdditionalActions('J1', 3));
      send(const PriorityCommand.action('J1'));
      send(const PriorityCommand.responseAction('J2'));
      expect(c.can(const PriorityCommand.action('J1')), isFalse);
      await t.pump(const Duration(milliseconds: 351));
      expect(send(const PriorityCommand.action('J1')), isTrue);
      expect(c.value!.priorityPlayerId, 'J1');
      expect(
        c.events.any((e) => e.type == PriorityEventType.automaticPass),
        isTrue,
      );
      final revision = c.value!.revision;
      expect(send(const PriorityCommand.action('J1')), isFalse);
      expect(c.value!.revision, revision);
      expect(c.can(const PriorityCommand.free('J1')), isTrue);
      await t.pump(const Duration(milliseconds: 351));
      expect(send(const PriorityCommand.action('J1')), isTrue);
      c.dispose();
      await t.pump(const Duration(seconds: 1));
    },
  );

  testWidgets('reset cancela bloqueos y permite nueva configuración', (
    t,
  ) async {
    final c = PriorityController();
    c.start(players(2));
    c.dispatch(
      const PriorityCommand.action('J1'),
      expectedRevision: c.value!.revision,
    );
    c.reset();
    expect(c.value, isNull);
    expect(c.events, isEmpty);
    c.start(players(6));
    expect(c.can(const PriorityCommand.action('J1')), isTrue);
    c.dispose();
    await t.pump(const Duration(seconds: 1));
  });
}

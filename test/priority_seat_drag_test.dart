import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:heroclix_simulator_trainer/domain/priority/priority.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_controller.dart';

import 'priority_screen_test.dart' show mount, press, enter, key, selectCount;
import 'support/priority_stage3_fixtures.dart';

Future<void> dragSeat(WidgetTester t, String source, String target) async {
  final gesture = await t.startGesture(
    t.getCenter(key('priority-drag-$source')),
  );
  await t.pump(const Duration(milliseconds: 600));
  await gesture.moveTo(t.getCenter(key('priority-drop-$target')));
  await t.pump(const Duration(milliseconds: 50));
  expect(key('priority-drop-highlight-$target'), findsOneWidget);
  await gesture.up();
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() => WidgetController.hitTestWarningShouldBeFatal = true);

  for (var count = 2; count <= 6; count++) {
    test(
      '$count: intercambios cambian el orden conservando jugadores, turno e inicial',
      () {
        final c = PriorityController(inputCooldown: Duration.zero)
          ..start(priorityConfig(count, clock: false, first: 'J2'));
        addTearDown(c.dispose);
        final before = c.value!;
        final events = c.events;
        for (var a = 0; a < count; a++) {
          for (var b = a + 1; b < count; b++) {
            final seats = c.visualSeatOrder.toList();
            final source = seats[a], target = seats[b];
            expect(
              c.swapVisualSeats(
                source,
                target,
                configuration: before.configuration,
              ),
              isTrue,
            );
            seats[a] = target;
            seats[b] = source;
            expect(c.visualSeatOrder, seats);
            expect(c.value!.players, orderedEquals(before.players));
            expect(c.value!.priorityPlayerId, before.priorityPlayerId);
            expect(c.value!.turnOrder, seats);
            expect(c.value!.revision, greaterThan(before.revision));
            expect(c.events, same(events));
            expect(c.value!.configuration.startingPlayerId, 'J2');
            expect(c.value!.activePlayerId, 'J2');
          }
        }
        expect(() => c.visualSeatOrder.add('otro'), throwsUnsupportedError);
      },
    );
  }

  test('rechaza IDs, sesión anterior, intercambio propio y segundo plano', () {
    final c = PriorityController(inputCooldown: Duration.zero);
    addTearDown(c.dispose);
    final config = priorityConfig(2, clock: false);
    expect(c.swapVisualSeats('J1', 'J2', configuration: config), isFalse);
    c.start(config);
    for (final pair in [('J1', 'J1'), ('J1', 'otro'), ('otro', 'J2')]) {
      expect(
        c.swapVisualSeats(pair.$1, pair.$2, configuration: config),
        isFalse,
      );
    }
    c.setForeground(false);
    expect(c.swapVisualSeats('J1', 'J2', configuration: config), isFalse);
    c.setForeground(true);
    c.reset();
    expect(c.visualSeatOrder, isEmpty);
    c.start(priorityConfig(2, clock: false));
    expect(c.swapVisualSeats('J1', 'J2', configuration: config), isFalse);
    expect(c.visualSeatOrder, ['J1', 'J2']);
  });

  test('tres: conserva la respuesta en curso y pasa turno según las nuevas posiciones', () {
    final c = PriorityController(inputCooldown: Duration.zero)
      ..start(priorityConfig(3, clock: false));
    addTearDown(c.dispose);
    void act(PriorityCommand command) => expect(
      c.dispatch(command, expectedRevision: c.value!.revision),
      isTrue,
    );
    act(const PriorityCommand.action('J1'));
    final window = c.value!;
    expect(
      c.swapVisualSeats('J1', 'J3', configuration: window.configuration),
      isTrue,
    );
    expect(c.value!.activePlayerId, window.activePlayerId);
    expect(c.value!.priorityPlayerId, window.priorityPlayerId);
    act(const PriorityCommand.responseAction('J2'));
    act(const PriorityCommand.pass('J3'));
    act(const PriorityCommand.endTurn('J1'));
    expect(c.value!.activePlayerId, 'J3');
    expect(c.value!.players.map((p) => p.availableActions), [3, 3, 3]);
    act(const PriorityCommand.action('J3'));
    expect(c.value!.pendingResponders, ['J2', 'J1']);
    expect(c.visualSeatOrder, ['J3', 'J2', 'J1']);
  });

  test('mover asiento no reinicia ni transfiere el reloj con prioridad', () {
    final clock = PriorityFakeClock();
    final c = PriorityController(
      inputCooldown: Duration.zero,
      elapsedClock: clock.read,
    )..start(priorityConfig(2, time: const Duration(seconds: 20)));
    addTearDown(c.dispose);
    clock.advance(const Duration(seconds: 3));
    c.synchronizeClock();
    expect(
      c.swapVisualSeats('J1', 'J2', configuration: c.value!.configuration),
      isTrue,
    );
    clock.advance(const Duration(seconds: 2));
    c.synchronizeClock();
    expect(c.value!.player('J1').remainingTime, const Duration(seconds: 15));
    expect(c.value!.player('J2').remainingTime, const Duration(seconds: 20));
    expect(c.value!.priorityPlayerId, 'J1');
  });

  for (var count = 2; count <= 6; count++) {
    for (final size in [const Size(360, 800), const Size(800, 360)]) {
      testWidgets(
        '$count en $size: arrastra al inicial sin cambiar su identidad',
        (t) async {
          t.view.devicePixelRatio = 1;
          t.view.physicalSize = size;
          addTearDown(t.view.resetDevicePixelRatio);
          addTearDown(t.view.resetPhysicalSize);
          final c = PriorityController(inputCooldown: Duration.zero)
            ..start(priorityConfig(count, clock: false, first: 'J2'));
          addTearDown(c.dispose);
          await mount(t, c);
          await t.pumpAndSettle();
          final sourceBounds = t.getRect(key('priority-panel-J2'));
          final targetBounds = t.getRect(key('priority-panel-J1'));
          final color = t
              .widget<Text>(key('priority-player-name-J2'))
              .style!
              .color;
          final match = c.value!;
          await dragSeat(t, 'J2', 'J1');
          expect(t.getRect(key('priority-panel-J2')), targetBounds);
          expect(t.getRect(key('priority-panel-J1')), sourceBounds);
          expect(
            t.widget<Text>(key('priority-player-name-J2')).style!.color,
            color,
          );
          expect(c.value!.players, orderedEquals(match.players));
          expect(c.value!.activePlayerId, match.activePlayerId);
          expect(c.value!.priorityPlayerId, match.priorityPlayerId);
          expect(c.value!.turnOrder, c.visualSeatOrder);
          expect(c.value!.configuration.startingPlayerId, 'J2');
          expect(key('priority-score-apply'), findsNothing);
          expect(t.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'configuración: mueve al inicial y conserva su selección al empezar',
    (t) async {
      final c = PriorityController(inputCooldown: Duration.zero);
      addTearDown(c.dispose);
      await mount(t, c);
      await selectCount(t, 3);
      await enter(t, 'priority-name-J2', 'Primero');
      await press(t, 'priority-setup-select-J2');
      await t.ensureVisible(key('priority-setup-seats'));
      await t.pumpAndSettle();
      await dragSeat(t, 'J2', 'J3');
      expect(
        find.descendant(
          of: key('priority-setup-view-J2'),
          matching: find.text('INICIA'),
        ),
        findsOneWidget,
      );
      await press(t, 'priority-start');
      expect(c.value!.configuration.startingPlayerId, 'J2');
      expect(c.value!.activePlayerId, 'J2');
      expect(c.value!.priorityPlayerId, 'J2');
      expect(c.value!.players.map((p) => p.id), ['J1', 'J3', 'J2']);
    },
  );

  testWidgets('soltar fuera cancela; conserva posiciones y no abre gestión', (
    t,
  ) async {
    final c = PriorityController(inputCooldown: Duration.zero)
      ..start(priorityConfig(2, clock: false));
    addTearDown(c.dispose);
    await mount(t, c);
    await t.pumpAndSettle();
    final gesture = await t.startGesture(t.getCenter(key('priority-drag-J1')));
    await t.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(const Offset(4, 4));
    await gesture.up();
    await t.pumpAndSettle();
    expect(c.visualSeatOrder, ['J1', 'J2']);
    expect(key('priority-score-apply'), findsNothing);
  });

  testWidgets('posición visual se conserva al volver a abrir la pantalla', (
    t,
  ) async {
    final c = PriorityController(inputCooldown: Duration.zero)
      ..start(priorityConfig(3, clock: false));
    addTearDown(c.dispose);
    await mount(t, c);
    await t.pumpAndSettle();
    final target = t.getRect(key('priority-panel-J3'));
    await dragSeat(t, 'J1', 'J3');
    await t.pumpWidget(const SizedBox.shrink());
    await mount(t, c);
    await t.pumpAndSettle();
    expect(t.getRect(key('priority-panel-J1')), target);
    expect(c.value!.configuration.startingPlayerId, 'J1');
  });

  testWidgets(
    'reloj agotado sin aviso permite abrir gestión con orientación nueva tras arrastrar',
    (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(360, 800);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetPhysicalSize);
      final clock = PriorityFakeClock();
      final c = PriorityController(
        inputCooldown: Duration.zero,
        elapsedClock: clock.read,
      )..start(priorityConfig(2, time: const Duration(seconds: 1)));
      addTearDown(c.dispose);
      await mount(t, c);
      clock.advance(const Duration(seconds: 2));
      c.synchronizeClock();
      await t.pumpAndSettle();
      c.swapVisualSeats('J1', 'J2', configuration: c.value!.configuration);
      await t.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      await press(t, 'priority-player-menu-J1');
      final rotation = find.ancestor(
        of: key('priority-score-apply'),
        matching: find.byType(RotatedBox),
      );
      expect(t.widget<RotatedBox>(rotation.first).quarterTurns, 2);
      await t.pumpWidget(const SizedBox.shrink());
      c.reset();
    },
  );
}

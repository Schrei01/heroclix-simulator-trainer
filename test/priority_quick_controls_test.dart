import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:heroclix_simulator_trainer/domain/priority/priority.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_controller.dart';

import 'priority_screen_test.dart' show mount, press, enter, key;
import 'support/priority_stage3_fixtures.dart';

Future<void> step(WidgetTester t, String player, {bool plus = true}) async {
  final button = key('priority-score-${plus ? 'plus' : 'minus'}-$player');
  await t.ensureVisible(button);
  await t.tap(button);
  await t.pump(const Duration(milliseconds: 20));
}

String delta(WidgetTester t, String id) =>
    t.widget<Text>(key('priority-score-delta-$id')).data!;

void main() {
  setUpAll(() => WidgetController.hitTestWarningShouldBeFatal = true);

  testWidgets('cada toque suma; acumula, se difumina y reinicia tras 3 s', (
    t,
  ) async {
    // Keep the production input cooldown: score taps must never be discarded.
    final c = PriorityController()..start(priorityConfig(3, clock: false));
    addTearDown(c.dispose);
    await mount(t, c);
    final before = c.value!;
    for (var i = 1; i <= 10; i++) {
      await step(t, 'J1');
      expect(c.value!.player('J1').victoryPoints, i * 5);
      expect(delta(t, 'J1'), '+${i * 5}');
    }
    await t.pump(const Duration(seconds: 1));
    final fade = t.widget<FadeTransition>(key('priority-score-feedback-J1'));
    expect(fade.opacity.value, inExclusiveRange(0, 1));
    await step(t, 'J1');
    expect(delta(t, 'J1'), '+55');
    await t.pump(const Duration(milliseconds: 2900));
    expect(key('priority-score-delta-J1'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 101));
    expect(key('priority-score-delta-J1'), findsNothing);
    expect(c.value!.player('J1').victoryPoints, 55);
    await step(t, 'J1');
    expect(delta(t, 'J1'), '+5');
    expect(c.value!.player('J1').victoryPoints, 60);
    expect(c.value!.turn, before.turn);
    expect(c.value!.round, before.round);
    expect(c.value!.priorityPlayerId, before.priorityPlayerId);
    expect(c.value!.players.map((p) => p.availableActions), [3, 3, 3]);
    await t.pumpWidget(const SizedBox.shrink());
    c.reset();
  });

  testWidgets(
    'resta 5, no admite negativos y cada jugador tiene su acumulado',
    (t) async {
      final c = PriorityController()..start(priorityConfig(3, clock: false));
      addTearDown(c.dispose);
      await mount(t, c);
      expect(
        t.widget<IconButton>(key('priority-score-minus-J1')).onPressed,
        isNull,
      );
      await step(t, 'J1');
      await step(t, 'J1');
      await step(t, 'J2');
      expect(delta(t, 'J1'), '+10');
      expect(delta(t, 'J2'), '+5');
      await step(t, 'J1', plus: false);
      expect(delta(t, 'J1'), '-5');
      await step(t, 'J1', plus: false);
      expect(delta(t, 'J1'), '-10');
      expect(c.value!.player('J1').victoryPoints, 0);
      expect(
        t.widget<IconButton>(key('priority-score-minus-J1')).onPressed,
        isNull,
      );
      expect(c.value!.player('J2').victoryPoints, 5);
      await t.pumpWidget(const SizedBox.shrink());
      c.reset();
    },
  );

  testWidgets('suma rápida respeta límites del motor y corrección manual', (
    t,
  ) async {
    final c = PriorityController(inputCooldown: Duration.zero)
      ..start(priorityConfig(2, clock: false));
    addTearDown(c.dispose);
    c.dispatch(
      const PriorityCommand.setVictoryPoints('J1', 0x7fffffffffffffff),
      expectedRevision: c.value!.revision,
    );
    await mount(t, c);
    expect(
      t.widget<IconButton>(key('priority-score-plus-J1')).onPressed,
      isNull,
    );
    await step(t, 'J1', plus: false);
    expect(c.value!.player('J1').victoryPoints, 0x7fffffffffffffff - 5);
    await press(t, 'priority-player-menu-J1');
    await enter(t, 'priority-score-input', '5');
    await press(t, 'priority-score-apply');
    expect(c.value!.player('J1').victoryPoints, 0x7fffffffffffffff);
    expect(t.takeException(), isNull);
  });

  for (var count = 2; count <= 6; count++) {
    testWidgets('calavera confirma y elimina al activo en mesa de $count', (
      t,
    ) async {
      final c = PriorityController(inputCooldown: Duration.zero)
        ..start(priorityConfig(count, clock: false));
      addTearDown(c.dispose);
      await mount(t, c);
      await press(t, 'priority-skull-J1');
      expect(find.text('¿Eliminar a Jugador 1?'), findsOneWidget);
      expect(c.value!.player('J1').eliminated, isFalse);
      await press(t, 'priority-eliminate-confirm');
      expect(c.value!.player('J1').eliminated, isTrue);
      expect(t.widget<IconButton>(key('priority-skull-J1')).onPressed, isNull);
      if (count == 2) {
        expect(c.value!.phase, PriorityPhase.finished);
        expect(key('priority-ranking-title'), findsOneWidget);
        await press(t, 'priority-ranking-close');
      } else {
        expect(c.value!.activePlayerId, 'J2');
        expect(c.value!.priorityPlayerId, 'J2');
      }
      // PV remain editable even after elimination / finishing.
      await step(t, 'J1');
      expect(c.value!.player('J1').victoryPoints, 5);
      await t.pumpWidget(const SizedBox.shrink());
      c.reset();
    });
  }

  testWidgets('calavera cancela y luego elimina al reactivo con prioridad', (
    t,
  ) async {
    final c = PriorityController(inputCooldown: Duration.zero)
      ..start(priorityConfig(3, clock: false));
    addTearDown(c.dispose);
    await mount(t, c);
    await press(t, 'priority-action-J1');
    await press(t, 'priority-skull-J2');
    await t.tap(find.text('Cancelar'));
    await t.pumpAndSettle();
    expect(c.value!.player('J2').eliminated, isFalse);
    expect(c.value!.priorityPlayerId, 'J2');
    await press(t, 'priority-skull-J2');
    await press(t, 'priority-eliminate-confirm');
    expect(c.value!.priorityPlayerId, 'J3');
    expect(c.value!.activePlayerId, 'J1');
  });

  testWidgets(
    'solo minutos: corrección redondeada hacia arriba y reemplazo explícito',
    (t) async {
      final clock = PriorityFakeClock();
      final c = PriorityController(
        inputCooldown: Duration.zero,
        elapsedClock: clock.read,
      )..start(priorityConfig(2, time: const Duration(seconds: 61)));
      addTearDown(c.dispose);
      await mount(t, c);
      await press(t, 'priority-player-menu-J1');
      await press(t, 'priority-correct-time');
      expect(key('priority-time-seconds'), findsNothing);
      expect(
        t.widget<TextField>(key('priority-time-minutes')).controller!.text,
        '2',
      );
      for (final invalid in ['-1', '1.5', 'abc', '9223372036854775807']) {
        await enter(t, 'priority-time-minutes', invalid);
        await press(t, 'priority-time-apply');
        expect(
          c.value!.player('J1').remainingTime,
          const Duration(seconds: 61),
        );
      }
      await enter(t, 'priority-time-minutes', '0');
      await press(t, 'priority-time-apply');
      expect(c.value!.player('J1').remainingTime, Duration.zero);
      expect(c.value!.isPaused, isTrue);
      await t.pumpWidget(const SizedBox.shrink());
      c.reset();
    },
  );

  testWidgets(
    'el acumulado sigue al mismo jugador al girar y se limpia al reiniciar',
    (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(360, 800);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetPhysicalSize);
      final c = PriorityController(inputCooldown: Duration.zero)
        ..start(priorityConfig(6, clock: false));
      addTearDown(c.dispose);
      await mount(t, c);
      await step(t, 'J2');
      t.view.physicalSize = const Size(800, 360);
      await t.pump();
      expect(delta(t, 'J2'), '+5');
      expect(key('priority-score-delta-J1'), findsNothing);
      c.reset();
      await t.pump();
      c.start(priorityConfig(6, clock: false));
      await t.pump();
      expect(key('priority-score-delta-J2'), findsNothing);
      expect(c.value!.player('J2').victoryPoints, 0);
    },
  );

  testWidgets('controles accesibles en 320×320 con texto 300 %', (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(320, 320);
    t.platformDispatcher.textScaleFactorTestValue = 3;
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    final c = PriorityController(inputCooldown: Duration.zero)
      ..start(priorityConfig(6, clock: false));
    addTearDown(c.dispose);
    await mount(t, c);
    await step(t, 'J6');
    await step(t, 'J6', plus: false);
    await press(t, 'priority-skull-J6');
    expect(key('priority-eliminate-confirm'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  for (final size in [const Size(360, 800), const Size(800, 360)]) {
    testWidgets(
      'seis jugadores en $size: acciones y barra completas sin desplazar',
      (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = size;
        addTearDown(t.view.resetDevicePixelRatio);
        addTearDown(t.view.resetPhysicalSize);
        final c = PriorityController(inputCooldown: Duration.zero)
          ..start(priorityConfig(6, clock: false));
        addTearDown(c.dispose);
        await mount(t, c);
        for (var i = 1; i <= 6; i++) {
          final bounds = t.getRect(key('priority-panel-J$i'));
          final controls = [
            'priority-score-plus-J$i',
            'priority-score-minus-J$i',
            'priority-skull-J$i',
            'priority-count-J$i',
            for (final op
                in i == 1
                    ? ['action', 'free', 'endTurn']
                    : ['responseAction', 'responseFree', 'pass'])
              'priority-$op-J$i',
          ];
          for (final id in controls) {
            final rect = t.getRect(key(id));
            expect(bounds.contains(rect.topLeft), isTrue, reason: id);
            expect(
              bounds.contains(rect.bottomRight - const Offset(.1, .1)),
              isTrue,
              reason: id,
            );
          }
        }
        expect(t.takeException(), isNull);
      },
    );
  }
}

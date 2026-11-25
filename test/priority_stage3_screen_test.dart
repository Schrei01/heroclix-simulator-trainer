import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:heroclix_simulator_trainer/app.dart';
import 'package:heroclix_simulator_trainer/domain/priority/priority.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_controller.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_input.dart';

import 'priority_screen_test.dart' show mount, press, enter, key;
import 'support/priority_stage3_fixtures.dart';
import 'support/test_clock.dart';

void main() {
  setUpAll(() => WidgetController.hitTestWarningShouldBeFatal = true);

  test('formato de tiempo y parseo seguro de minutos/segundos', () {
    expect(priorityTimeLabel(const Duration(microseconds: 1)), '00:01');
    expect(
      priorityTimeLabel(const Duration(minutes: 59, seconds: 59)),
      '59:59',
    );
    expect(priorityTimeLabel(const Duration(hours: 25)), '25:00:00');
    expect(priorityDurationInput('0', '0'), isNull);
    expect(priorityDurationInput('0', '0', allowZero: true), Duration.zero);
    for (final pair in [
      ('0', '60'),
      ('-1', '0'),
      ('a', '0'),
      ('9223372036854775807', '0'),
    ]) {
      expect(priorityDurationInput(pair.$1, pair.$2), isNull);
    }
    expect(
      priorityDurationInput('2', '59'),
      const Duration(minutes: 2, seconds: 59),
    );
  });

  testWidgets(
    'configura reloj, transfiere prioridad, pausa, expira y corrige',
    (t) async {
      final clock = PriorityFakeClock();
      final c = PriorityController(
        inputCooldown: Duration.zero,
        elapsedClock: clock.read,
      );
      addTearDown(c.dispose);
      await mount(t, c);
      expect(key('priority-clock-minutes'), findsNothing);
      await press(t, 'priority-clock-enabled');
      await enter(t, 'priority-clock-minutes', '0');
      await enter(t, 'priority-clock-seconds', '5');
      await press(t, 'priority-start');
      expect(c.value!.configuration.initialTime, const Duration(seconds: 5));
      expect(key('priority-clock-J1'), findsOneWidget);
      clock.advance(const Duration(seconds: 2));
      c.synchronizeClock();
      await t.pump();
      expect(t.widget<Text>(key('priority-clock-J1')).data, '00:03');
      expect(t.widget<Text>(key('priority-clock-J2')).data, '00:05');
      await press(t, 'priority-action-J1');
      clock.advance(const Duration(seconds: 1));
      c.synchronizeClock();
      await t.pump();
      expect(t.widget<Text>(key('priority-clock-J2')).data, '00:04');
      await press(t, 'priority-pause-resume');
      clock.advance(const Duration(hours: 1));
      c.synchronizeClock();
      await t.pump();
      expect(t.widget<Text>(key('priority-clock-J2')).data, '00:04');
      await press(t, 'priority-pause-resume');
      await press(t, 'priority-pass-J2');
      clock.advance(const Duration(seconds: 4));
      c.synchronizeClock();
      await t.pump();
      expect(key('priority-time-expired'), findsOneWidget);
      expect(c.value!.players.every((p) => !p.eliminated), isTrue);
      expect(
        t.widget<IconButton>(key('priority-pause-resume')).onPressed,
        isNull,
      );
      await press(t, 'priority-player-menu-J1');
      await press(t, 'priority-correct-time');
      await enter(t, 'priority-time-seconds', '9');
      await press(t, 'priority-time-apply');
      await press(t, 'priority-player-close');
      expect(c.value!.isPaused, isTrue);
      expect(c.value!.player('J1').spentTime, const Duration(seconds: 5));
      await press(t, 'priority-pause-resume');
      expect(c.value!.player('J1').remainingTime, const Duration(seconds: 9));
      expect(c.value!.isPaused, isFalse);
      await t.pumpWidget(const SizedBox.shrink());
      c.reset();
    },
  );

  testWidgets(
    'reloj opcional: rechaza tiempo inválido y oculta todos sus controles al desactivar',
    (t) async {
      final clock = PriorityFakeClock();
      final c = PriorityController(
        inputCooldown: Duration.zero,
        elapsedClock: clock.read,
      );
      addTearDown(c.dispose);
      await mount(t, c);
      await press(t, 'priority-clock-enabled');
      await enter(t, 'priority-clock-minutes', '0');
      await enter(t, 'priority-clock-seconds', '0');
      await press(t, 'priority-start');
      expect(c.value, isNull);
      expect(key('priority-setup-error'), findsOneWidget);
      await enter(t, 'priority-clock-seconds', '60');
      await press(t, 'priority-start');
      expect(c.value, isNull);
      await press(t, 'priority-clock-enabled');
      await press(t, 'priority-start');
      expect(key('priority-clock-J1'), findsNothing);
      expect(key('priority-pause-resume'), findsNothing);
      await press(t, 'priority-player-menu-J1');
      expect(key('priority-correct-time'), findsNothing);
      expect(key('priority-score-input'), findsOneWidget);
    },
  );

  testWidgets(
    'suma, resta, corrige puntos y consulta clasificación con empates',
    (t) async {
      final c = PriorityController(inputCooldown: Duration.zero)
        ..start(priorityConfig(3, clock: false));
      addTearDown(c.dispose);
      await mount(t, c);
      await press(t, 'priority-player-menu-J2');
      await enter(t, 'priority-score-input', '120');
      await press(t, 'priority-score-apply');
      expect(c.value!.player('J2').victoryPoints, 120);
      await press(t, 'priority-score-mode-add');
      await t.tap(find.text('Restar puntos').last);
      await t.pumpAndSettle();
      await enter(t, 'priority-score-input', '20');
      await press(t, 'priority-score-apply');
      expect(c.value!.player('J2').victoryPoints, 100);
      await press(t, 'priority-score-mode-add');
      await t.tap(find.text('Corregir total').last);
      await t.pumpAndSettle();
      await enter(t, 'priority-score-input', '80');
      await press(t, 'priority-score-apply');
      expect(c.value!.player('J2').victoryPoints, 80);
      await press(t, 'priority-score-mode-add');
      await t.tap(find.text('Restar puntos').last);
      await t.pumpAndSettle();
      await enter(t, 'priority-score-input', '81');
      await press(t, 'priority-score-apply');
      expect(c.value!.player('J2').victoryPoints, 80);
      expect(find.textContaining('los puntos no pueden'), findsOneWidget);
      await press(t, 'priority-player-close');
      c.dispatch(
        const PriorityCommand.setVictoryPoints('J1', 80),
        expectedRevision: c.value!.revision,
      );
      await t.pump();
      await press(t, 'priority-standings');
      expect(find.text('1. Jugador 1: 80 PV · No eliminado'), findsOneWidget);
      expect(find.text('1. Jugador 2: 80 PV · No eliminado'), findsOneWidget);
      expect(find.text('3. Jugador 3: 0 PV · No eliminado'), findsOneWidget);
      expect(find.textContaining('Ganador'), findsNothing);
    },
  );

  for (final removed in ['J1', 'J2', 'J3']) {
    testWidgets('eliminación confirmada de $removed durante respuesta', (
      t,
    ) async {
      final clock = PriorityFakeClock();
      final c = PriorityController(
        inputCooldown: Duration.zero,
        elapsedClock: clock.read,
      )..start(priorityConfig(3));
      addTearDown(c.dispose);
      c.dispatch(
        PriorityCommand.setVictoryPoints(removed, 77),
        expectedRevision: c.value!.revision,
      );
      c.dispatch(
        const PriorityCommand.action('J1'),
        expectedRevision: c.value!.revision,
      );
      await mount(t, c);
      await press(t, 'priority-player-menu-$removed');
      await press(t, 'priority-eliminate');
      await t.tap(find.text('Cancelar'));
      await t.pumpAndSettle();
      expect(c.value!.player(removed).eliminated, isFalse);
      await press(t, 'priority-eliminate');
      await press(t, 'priority-eliminate-confirm');
      expect(c.value!.player(removed).eliminated, isTrue);
      expect(c.value!.player(removed).victoryPoints, 77);
      expect(key('priority-eliminated-$removed'), findsOneWidget);
      expect(c.value!.pendingResponders, isNot(contains(removed)));
      expect(c.value!.priorityPlayerId, removed == 'J2' ? 'J3' : 'J2');
      expect(c.value!.activePlayerId, removed == 'J1' ? 'J2' : 'J1');
      await t.pumpWidget(const SizedBox.shrink());
      c.reset();
    });
  }

  testWidgets(
    'último superviviente finaliza y abre clasificación sin inventar ganador',
    (t) async {
      final c = PriorityController(inputCooldown: Duration.zero)
        ..start(priorityConfig(2, clock: false));
      addTearDown(c.dispose);
      c.dispatch(
        const PriorityCommand.setVictoryPoints('J2', 100),
        expectedRevision: c.value!.revision,
      );
      await mount(t, c);
      await press(t, 'priority-player-menu-J2');
      await press(t, 'priority-eliminate');
      await press(t, 'priority-eliminate-confirm');
      expect(c.value!.phase, PriorityPhase.finished);
      expect(find.text('Partida finalizada'), findsOneWidget);
      expect(find.text('1. Jugador 2: 100 PV · Eliminado'), findsOneWidget);
      expect(find.textContaining('Ganador'), findsNothing);
      await press(t, 'priority-ranking-close');
      expect(c.can(const PriorityCommand.action('J1')), isFalse);
      expect(key('priority-pause-resume'), findsNothing);
      await press(t, 'priority-player-menu-J1');
      await enter(t, 'priority-score-input', '150');
      await press(t, 'priority-score-apply');
      await press(t, 'priority-player-close');
      await press(t, 'priority-standings');
      expect(find.text('1. Jugador 1: 150 PV · No eliminado'), findsOneWidget);
      expect(c.value!.phase, PriorityPhase.finished);
      expect(c.value!.priorityPlayerId, isNull);
    },
  );

  testWidgets(
    'ciclo de vida real del widget y navegación requieren reanudación manual',
    (t) async {
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final clock = PriorityFakeClock();
      final c = PriorityController(
        inputCooldown: Duration.zero,
        elapsedClock: clock.read,
      )..start(priorityConfig(3));
      await t.pumpWidget(HeroClixApp(clock: testClock, priorityController: c));
      await press(t, 'mode-priority');
      await press(t, 'priority-free-J1');
      clock.advance(const Duration(seconds: 3));
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await t.pump();
      clock.advance(const Duration(hours: 3));
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pumpAndSettle();
      expect(c.value!.isPaused, isTrue);
      expect(c.value!.player('J2').spentTime, const Duration(seconds: 3));
      expect(
        t.widget<IconButton>(key('priority-pause-resume')).onPressed,
        isNotNull,
      );
      await press(t, 'priority-pause-resume');
      expect(c.value!.phase, PriorityPhase.freeResponse);
      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      expect(c.value!.isPaused, isTrue);
      await press(t, 'mode-priority');
      expect(c.value!.isPaused, isTrue);
      expect(c.value!.pendingResponders, ['J2', 'J3']);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(800, 360),
    const Size(320, 320),
  ]) {
    for (final scale in [1.0, 3.0]) {
      for (final count in [2, 6]) {
        testWidgets(
          'gestión y relojes: $count en $size texto $scale con teclado',
          (t) async {
            t.view.devicePixelRatio = 1;
            t.view.physicalSize = size;
            t.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(t.view.resetDevicePixelRatio);
            addTearDown(t.view.resetPhysicalSize);
            addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
            addTearDown(t.view.resetViewInsets);
            final clock = PriorityFakeClock();
            final c = PriorityController(
              inputCooldown: Duration.zero,
              elapsedClock: clock.read,
            )..start(priorityConfig(count));
            addTearDown(c.dispose);
            await mount(t, c);
            await press(t, 'priority-player-menu-J$count');
            t.view.viewInsets = const FakeViewPadding(bottom: 140);
            await t.pumpAndSettle();
            await enter(t, 'priority-score-input', '100');
            await press(t, 'priority-score-apply');
            expect(c.value!.player('J$count').victoryPoints, 100);
            await press(t, 'priority-correct-time');
            await enter(t, 'priority-time-minutes', '1');
            await enter(t, 'priority-time-seconds', '7');
            await press(t, 'priority-time-apply');
            expect(
              c.value!.player('J$count').remainingTime,
              const Duration(minutes: 1, seconds: 7),
            );
            await press(t, 'priority-player-close');
            expect(c.value!.isPaused, isTrue);
            expect(t.takeException(), isNull);
            await t.pumpWidget(const SizedBox.shrink());
            c.reset();
          },
        );
      }
    }
  }
}

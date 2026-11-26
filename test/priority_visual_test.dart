import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:heroclix_simulator_trainer/domain/priority/priority.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_controller.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_table_layout.dart';

import 'priority_screen_test.dart' show mount, press, key;
import 'support/priority_stage3_fixtures.dart';

void main() {
  for (final count in [3, 4]) {
    for (final landscape in [false, true]) {
      test(
        '$count participantes: orientación por asiento, horizontal $landscape',
        () {
          final seats = priorityTableSeats(
            landscape ? const Size(800, 360) : const Size(360, 800),
            count,
          );
          expect(
            seats.map((s) => s.quarterTurns),
            count == 3 ? [1, 3, 0] : (landscape ? [0, 2, 2, 0] : [1, 1, 3, 3]),
          );
        },
      );
    }
  }

  test(
    '5 y 6 mantienen los lados y orientaciones, enumerados en sentido horario',
    () {
      for (final count in [5, 6]) {
        expect(
          priorityTableSeats(
            const Size(360, 800),
            count,
          ).map((s) => s.quarterTurns),
          count == 5 ? [1, 1, 3, 3, 3] : [1, 1, 1, 3, 3, 3],
        );
        expect(
          priorityTableSeats(
            const Size(800, 360),
            count,
          ).map((s) => s.quarterTurns),
          count == 5 ? [0, 2, 2, 0, 0] : [0, 2, 2, 2, 0, 0],
        );
      }
    },
  );

  testWidgets('aviso flotante accesible con texto 300 % en pantalla pequeña', (
    t,
  ) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(320, 320);
    t.platformDispatcher.textScaleFactorTestValue = 3;
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    final clock = PriorityFakeClock();
    final c = PriorityController(
      inputCooldown: Duration.zero,
      elapsedClock: clock.read,
    )..start(priorityConfig(6, time: const Duration(seconds: 1)));
    addTearDown(c.dispose);
    await mount(t, c);
    clock.advance(const Duration(seconds: 2));
    c.synchronizeClock();
    await t.pumpAndSettle();
    expect(key('priority-time-expired'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.tap(find.text('Ver'));
    await t.pumpAndSettle();
    expect(key('priority-correct-time'), findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());
    c.reset();
  });

  testWidgets(
    'mesa sin franja ni rótulo de prioridad; borde y roles accesibles',
    (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(360, 800);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetPhysicalSize);
      final c = PriorityController(inputCooldown: Duration.zero)
        ..start(priorityConfig(3, clock: false));
      addTearDown(c.dispose);
      await mount(t, c);
      expect(key('priority-turn-status'), findsNothing);
      expect(key('priority-status'), findsNothing);
      expect(key('priority-response-status'), findsNothing);
      expect(find.text('PRIORIDAD'), findsNothing);
      expect(find.text('ACTIVO'), findsOneWidget);
      expect(find.text('REACTIVO'), findsNWidgets(2));
      expect(
        t.getRect(key('priority-table')).top,
        closeTo(t.getRect(find.byType(AppBar)).bottom, .01),
      );
      expect(t.getRect(key('priority-table')).bottom, 800);
      await press(t, 'priority-action-J1');
      expect(
        t.widget<Semantics>(key('priority-has-priority-J2')).properties.label,
        'Con prioridad',
      );
      final panel = t.widget<Material>(key('priority-panel-J2'));
      expect((panel.shape! as RoundedRectangleBorder).side.width, 3);
      expect(key('priority-active-J1'), findsOneWidget);
      expect(find.text('PRIORIDAD'), findsNothing);
    },
  );

  testWidgets('botones rectangulares en mesa y diálogos de gestión', (t) async {
    final c = PriorityController(inputCooldown: Duration.zero)
      ..start(priorityConfig(3, clock: false));
    addTearDown(c.dispose);
    await mount(t, c);
    void check(Finder button) {
      final theme = Theme.of(t.element(button));
      final shape =
          theme.filledButtonTheme.style!.shape!.resolve({})!
              as RoundedRectangleBorder;
      expect(
        shape.borderRadius.resolve(TextDirection.ltr).topLeft,
        const Radius.circular(6),
      );
    }

    check(key('priority-action-J1'));
    await press(t, 'priority-player-menu-J2');
    check(key('priority-score-apply'));
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'agotamiento avisa sin reducir mesa ni repetir avisos por refresco',
    (t) async {
      final clock = PriorityFakeClock();
      final c = PriorityController(
        inputCooldown: Duration.zero,
        elapsedClock: clock.read,
      )..start(priorityConfig(2, time: const Duration(seconds: 1)));
      addTearDown(c.dispose);
      await mount(t, c);
      final bounds = t.getRect(key('priority-table'));
      clock.advance(const Duration(seconds: 2));
      c.synchronizeClock();
      await t.pumpAndSettle();
      expect(key('priority-time-expired'), findsOneWidget);
      expect(t.getRect(key('priority-table')), bounds);
      c.setForeground(false);
      c.setForeground(true);
      await t.pumpAndSettle();
      await t.pump(const Duration(seconds: 9));
      await t.pumpAndSettle();
      expect(key('priority-time-expired'), findsNothing);
      expect(c.value!.isPaused, isTrue);
      expect(c.value!.player('J1').eliminated, isFalse);
      c.dispatch(
        const PriorityCommand.setRemainingTime('J1', Duration(seconds: 1)),
        expectedRevision: c.value!.revision,
      );
      c.dispatch(
        const PriorityCommand.resume(),
        expectedRevision: c.value!.revision,
      );
      clock.advance(const Duration(seconds: 2));
      c.synchronizeClock();
      await t.pumpAndSettle();
      expect(key('priority-time-expired'), findsOneWidget);
      await t.tap(find.text('Ver'));
      await t.pumpAndSettle();
      expect(key('priority-correct-time'), findsOneWidget);
      await t.pumpWidget(const SizedBox.shrink());
      c.reset();
    },
  );
}

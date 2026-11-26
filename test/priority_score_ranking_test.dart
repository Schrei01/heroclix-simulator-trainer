import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:heroclix_simulator_trainer/domain/priority/priority.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_controller.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_rank_badge.dart';
import 'package:heroclix_simulator_trainer/presentation/theme/app_theme.dart';

import 'priority_screen_test.dart' show mount, key;
import 'priority_quick_controls_test.dart' show step;
import 'support/priority_stage3_fixtures.dart';

String rank(WidgetTester t, String id) =>
    t.widget<Text>(key('priority-rank-$id')).data!;

void main() {
  testWidgets('posiciones 1–6 con círculos dorados, bronce y verdes', (
    t,
  ) async {
    final c = PriorityController(inputCooldown: Duration.zero)
      ..start(priorityConfig(6, clock: false));
    addTearDown(c.dispose);
    for (var i = 1; i <= 6; i++) {
      c.dispatch(
        PriorityCommand.setVictoryPoints('J$i', (7 - i) * 25),
        expectedRevision: c.value!.revision,
      );
    }
    await mount(t, c);
    for (var i = 1; i <= 6; i++) {
      expect(rank(t, 'J$i'), '$i');
      final expectedColor = i <= 2
          ? PriorityRankBadge.gold
          : i == 3
          ? PriorityRankBadge.bronze
          : AppTheme.accent;
      final decoration =
          t.widget<Container>(key('priority-rank-badge-J$i')).decoration!
              as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect((decoration.border! as Border).top.color, expectedColor);
      expect(
        t.widget<Text>(key('priority-rank-J$i')).style!.color,
        expectedColor,
      );
    }
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'posiciones se actualizan con ±5, corrección y empates compartidos',
    (t) async {
      final c = PriorityController(inputCooldown: Duration.zero)
        ..start(priorityConfig(3, clock: false));
      addTearDown(c.dispose);
      await mount(t, c);
      expect([for (var i = 1; i <= 3; i++) rank(t, 'J$i')], ['1', '1', '1']);
      await step(t, 'J2');
      expect([for (var i = 1; i <= 3; i++) rank(t, 'J$i')], ['2', '1', '2']);
      await step(t, 'J1');
      expect([for (var i = 1; i <= 3; i++) rank(t, 'J$i')], ['1', '1', '3']);
      await step(t, 'J3');
      expect([for (var i = 1; i <= 3; i++) rank(t, 'J$i')], ['1', '1', '1']);
      await step(t, 'J2', plus: false);
      expect([for (var i = 1; i <= 3; i++) rank(t, 'J$i')], ['1', '3', '1']);
      c.dispatch(
        const PriorityCommand.setVictoryPoints('J3', 100),
        expectedRevision: c.value!.revision,
      );
      await t.pump();
      expect([for (var i = 1; i <= 3; i++) rank(t, 'J$i')], ['2', '3', '1']);
      c.dispatch(
        const PriorityCommand.eliminate('J3'),
        expectedRevision: c.value!.revision,
      );
      await t.pump();
      expect(rank(t, 'J3'), '1');
      expect(c.value!.player('J3').victoryPoints, 100);
      expect(c.value!.activePlayerId, 'J1');
      await t.pumpWidget(const SizedBox.shrink());
      c.reset();
    },
  );

  testWidgets(
    'PV en negrilla al doble de tamaño, centrados entre menos y más',
    (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(800, 360);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetPhysicalSize);
      final c = PriorityController(inputCooldown: Duration.zero)
        ..start(priorityConfig(6, clock: false));
      addTearDown(c.dispose);
      for (var i = 1; i <= 6; i++) {
        c.dispatch(
          PriorityCommand.setVictoryPoints('J$i', i * 25),
          expectedRevision: c.value!.revision,
        );
      }
      await mount(t, c);
      for (var i = 1; i <= 6; i++) {
        final text = t.widget<Text>(key('priority-score-J$i'));
        expect(text.style!.fontSize, 22);
        expect(text.style!.fontWeight, FontWeight.w900);
        final scoreCenter = t.getCenter(key('priority-score-J$i'));
        final panelCenter = t.getCenter(key('priority-panel-J$i'));
        expect(scoreCenter.dx, closeTo(panelCenter.dx, .01));
        final buttonsCenter =
            (t.getCenter(key('priority-score-minus-J$i')).dx +
                t.getCenter(key('priority-score-plus-J$i')).dx) /
            2;
        expect(scoreCenter.dx, closeTo(buttonsCenter, .01));
        expect(
          scoreCenter.dy,
          closeTo(t.getCenter(key('priority-score-minus-J$i')).dy, .01),
        );
        expect(
          scoreCenter.dy,
          closeTo(t.getCenter(key('priority-score-plus-J$i')).dy, .01),
        );
      }
      final centerBefore = t.getCenter(key('priority-score-J1'));
      await step(t, 'J1');
      expect(t.getCenter(key('priority-score-J1')), centerBefore);
      expect(
        t
            .getRect(key('priority-score-J1'))
            .overlaps(t.getRect(key('priority-score-delta-J1'))),
        isFalse,
      );
      await t.pumpAndSettle();
      expect(key('priority-score-delta-J1'), findsNothing);
      expect(t.getCenter(key('priority-score-J1')), centerBefore);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('conserva PV completos y ranking con texto ampliado y límites', (
    t,
  ) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(320, 320);
    t.platformDispatcher.textScaleFactorTestValue = 3;
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    final c = PriorityController(inputCooldown: Duration.zero)
      ..start(priorityConfig(6, clock: false));
    addTearDown(c.dispose);
    c.dispatch(
      const PriorityCommand.setVictoryPoints('J6', 0x7fffffffffffffff),
      expectedRevision: c.value!.revision,
    );
    await mount(t, c);
    expect(
      t.widget<Text>(key('priority-score-J6')).data,
      '9223372036854775807 PV',
    );
    expect(rank(t, 'J6'), '1');
    expect(rank(t, 'J1'), '2');
    await step(t, 'J6', plus: false);
    expect(c.value!.player('J6').victoryPoints, 0x7fffffffffffffff - 5);
    expect(rank(t, 'J6'), '1');
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox.shrink());
    c.reset();
  });
}

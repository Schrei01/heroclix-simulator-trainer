import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:heroclix_simulator_trainer/domain/priority/priority.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_active_indicator.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_controller.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_table_layout.dart';

import 'priority_screen_test.dart' show mount, key;
import 'support/priority_stage3_fixtures.dart';

BoxDecoration glow(WidgetTester t, String id) =>
    t.widget<DecoratedBox>(key('priority-active-glow-$id')).decoration
        as BoxDecoration;

void main() {
  testWidgets(
    'ACTIVO en negrilla, color propio y brillo breve sin alterar partida',
    (t) async {
      final c = PriorityController(inputCooldown: Duration.zero)
        ..start(priorityConfig(3, clock: false));
      addTearDown(c.dispose);
      final initial = c.value!;
      await mount(t, c);
      final text = t.widget<Text>(key('priority-active-J1'));
      expect(text.data, 'ACTIVO');
      expect(text.style!.fontWeight, FontWeight.w900);
      expect(text.style!.color, priorityPlayerColors.first);
      final resting = glow(t, 'J1');
      await t.pump(const Duration(milliseconds: 800));
      expect(
        glow(t, 'J1').boxShadow!.single.blurRadius,
        greaterThan(resting.boxShadow!.single.blurRadius),
      );
      await t.pumpAndSettle();
      expect(glow(t, 'J1'), resting);
      expect(t.binding.hasScheduledFrame, isFalse);
      expect(c.value, same(initial));
    },
  );

  testWidgets(
    'sigue al activo durante respuestas, cambia de turno y desaparece al finalizar',
    (t) async {
      final c = PriorityController(inputCooldown: Duration.zero)
        ..start(priorityConfig(3, clock: false));
      addTearDown(c.dispose);
      void act(PriorityCommand command) => expect(
        c.dispatch(command, expectedRevision: c.value!.revision),
        isTrue,
      );
      await mount(t, c);
      act(const PriorityCommand.action('J1'));
      await t.pump();
      expect(key('priority-active-glow-J1'), findsOneWidget);
      expect(key('priority-active-glow-J2'), findsNothing);
      final priorityPanel = t.widget<Material>(key('priority-panel-J2'));
      expect(
        (priorityPanel.shape! as RoundedRectangleBorder).side.color,
        const Color(0xFFFFD878),
      );
      act(const PriorityCommand.pass('J2'));
      act(const PriorityCommand.pass('J3'));
      act(const PriorityCommand.endTurn('J1'));
      await t.pump();
      expect(key('priority-active-glow-J1'), findsNothing);
      expect(
        t.widget<Text>(key('priority-active-J2')).style!.color,
        priorityPlayerColors[1],
      );
      act(const PriorityCommand.eliminate('J2'));
      await t.pump();
      expect(key('priority-active-glow-J2'), findsNothing);
      expect(key('priority-active-glow-J3'), findsOneWidget);
      act(const PriorityCommand.eliminate('J1'));
      await t.pumpAndSettle();
      expect(c.value!.phase, PriorityPhase.finished);
      expect(find.byType(PriorityActiveIndicator), findsNothing);
      expect(key('priority-ranking-title'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('movimiento reducido mantiene ACTIVO iluminado sin animación', (
    t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const Scaffold(
          body: PriorityActiveIndicator(playerId: 'J1', color: Colors.blue),
        ),
      ),
    );
    await t.pumpAndSettle();
    final resting = glow(t, 'J1');
    await t.pump(const Duration(milliseconds: 800));
    expect(glow(t, 'J1'), resting);
    expect(find.text('ACTIVO'), findsOneWidget);
    expect(t.binding.hasScheduledFrame, isFalse);
  });

  testWidgets(
    'activar movimiento reducido durante el brillo lo detiene suavemente',
    (t) async {
      final reduced = ValueNotifier(false);
      addTearDown(reduced.dispose);
      await t.pumpWidget(
        MaterialApp(
          builder: (context, child) => ValueListenableBuilder<bool>(
            valueListenable: reduced,
            builder: (context, value, _) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: value),
              child: child!,
            ),
          ),
          home: const Scaffold(
            body: PriorityActiveIndicator(playerId: 'J1', color: Colors.blue),
          ),
        ),
      );
      final resting = glow(t, 'J1');
      await t.pump(const Duration(milliseconds: 800));
      expect(glow(t, 'J1'), isNot(resting));
      reduced.value = true;
      await t.pumpAndSettle();
      expect(glow(t, 'J1'), resting);
      expect(t.binding.hasScheduledFrame, isFalse);
      await t.pumpWidget(const SizedBox.shrink());
      expect(t.takeException(), isNull);
    },
  );
}

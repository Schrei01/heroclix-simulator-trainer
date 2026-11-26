import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:heroclix_simulator_trainer/app.dart';
import 'package:heroclix_simulator_trainer/domain/priority/priority.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_controller.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_screen.dart';
import 'package:heroclix_simulator_trainer/presentation/theme/app_theme.dart';

import 'priority_controller_test.dart' show players;
import 'support/test_clock.dart';

Finder key(String key) => find.byKey(ValueKey(key));
Future<void> press(WidgetTester t, String id) async {
  if ((id == 'priority-standings' || id == 'priority-new-game') &&
      key(id).evaluate().isEmpty) {
    await t.tap(key('priority-more'));
    await t.pumpAndSettle();
  }
  await t.ensureVisible(key(id));
  await t.tap(key(id));
  await t.pumpAndSettle();
}

Future<void> enter(WidgetTester t, String id, String text) async {
  await t.ensureVisible(key(id));
  await t.enterText(key(id), text);
  await t.pump();
}

bool enabled(WidgetTester t, String id) =>
    t.widget<FilledButton>(key(id)).onPressed != null;

Future<void> mount(WidgetTester t, PriorityController controller) =>
    t.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        home: PriorityScreen(controller: controller),
      ),
    );

Future<void> selectCount(WidgetTester t, int count) async {
  await press(t, 'priority-player-count');
  if (find.text('$count jugadores').evaluate().isEmpty) {
    await t.scrollUntilVisible(
      find.text('$count jugadores'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
  }
  await t.ensureVisible(find.text('$count jugadores').last);
  await t.pumpAndSettle();
  await t.tap(find.text('$count jugadores').last);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() => WidgetController.hitTestWarningShouldBeFatal = true);

  for (var count = 2; count <= 6; count++) {
    testWidgets('configura $count participantes y empieza con sus valores', (
      t,
    ) async {
      final c = PriorityController(inputCooldown: Duration.zero);
      addTearDown(c.dispose);
      await mount(t, c);
      await selectCount(t, count);
      await enter(t, 'priority-build-points', '400');
      for (var i = 1; i <= count; i++) {
        await enter(t, 'priority-name-J$i', 'Nombre $i');
        await enter(t, 'priority-additional-J$i', '$i');
      }
      await press(t, 'priority-start');
      expect(c.value!.players.length, count);
      for (var i = 1; i <= count; i++) {
        expect(c.value!.player('J$i').name, 'Nombre $i');
        expect(c.value!.player('J$i').baseActions, 4);
        expect(c.value!.player('J$i').totalActions, 4 + i);
        expect(key('priority-panel-J$i'), findsOneWidget);
      }
      expect(enabled(t, 'priority-action-J1'), isTrue);
      expect(enabled(t, 'priority-responseAction-J2'), isFalse);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('ejemplo obligatorio completo desde controles de la mesa', (
    t,
  ) async {
    final c = PriorityController(inputCooldown: Duration.zero)
      ..start(players(3));
    addTearDown(c.dispose);
    await mount(t, c);
    expect(key('priority-active-J1'), findsOneWidget);
    expect(key('priority-has-priority-J1'), findsOneWidget);
    await press(t, 'priority-action-J1');
    expect(c.value!.players.map((p) => p.availableActions), [2, 3, 3]);
    expect(key('priority-active-J1'), findsOneWidget);
    expect(key('priority-has-priority-J2'), findsOneWidget);
    expect(enabled(t, 'priority-endTurn-J1'), isFalse);
    expect(enabled(t, 'priority-action-J1'), isFalse);
    expect(enabled(t, 'priority-responseAction-J2'), isTrue);
    expect(enabled(t, 'priority-responseFree-J2'), isFalse);
    expect(enabled(t, 'priority-pass-J3'), isFalse);
    await press(t, 'priority-responseAction-J2');
    await press(t, 'priority-pass-J3');
    expect(c.value!.players.map((p) => p.availableActions), [2, 2, 3]);
    expect(key('priority-has-priority-J1'), findsOneWidget);
    await press(t, 'priority-endTurn-J1');
    expect(c.value!.players.map((p) => p.availableActions), [3, 3, 3]);
    expect(c.value!.activePlayerId, 'J2');
    expect(c.value!.turn, 2);
    await press(t, 'priority-action-J2');
    expect(c.value!.pendingResponders, ['J3', 'J1']);
    await press(t, 'priority-pass-J3');
    await press(t, 'priority-responseAction-J1');
    expect(c.value!.priorityPlayerId, 'J2');
    expect(c.value!.players.map((p) => p.availableActions), [2, 2, 3]);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'edición de adicionales conserva consumo y pasa al quedar a cero',
    (t) async {
      final c = PriorityController(inputCooldown: Duration.zero)
        ..start(players(2, points: 100));
      addTearDown(c.dispose);
      c.dispatch(
        const PriorityCommand.setAdditionalActions('J2', 1),
        expectedRevision: c.value!.revision,
      );
      await mount(t, c);
      await press(t, 'priority-action-J1');
      await press(t, 'priority-responseAction-J2');
      await press(t, 'priority-free-J1');
      expect(enabled(t, 'priority-responseAction-J2'), isFalse);
      expect(enabled(t, 'priority-responseFree-J2'), isTrue);
      await press(t, 'priority-responseFree-J2');
      await press(t, 'priority-count-J1');
      await enter(t, 'priority-edit-additional', '2');
      await press(t, 'priority-edit-apply');
      expect(c.value!.player('J1').consumedActions, 1);
      expect(c.value!.player('J1').availableActions, 2);
      await press(t, 'priority-action-J1');
      await press(t, 'priority-count-J2');
      await enter(t, 'priority-edit-additional', '0');
      await press(t, 'priority-edit-apply');
      expect(c.value!.player('J2').consumedActions, 1);
      expect(c.value!.player('J2').availableActions, 0);
      expect(c.value!.priorityPlayerId, 'J1');
      expect(
        c.events.any((e) => e.type == PriorityEventType.automaticPass),
        isTrue,
      );
      expect(key('priority-automatic-pass'), findsNothing);
      await press(t, 'priority-free-J1');
      expect(enabled(t, 'priority-responseFree-J2'), isTrue);
      await press(t, 'priority-responseFree-J2');
      await press(t, 'priority-endTurn-J1');
      expect(c.value!.players.map((p) => p.availableActions), [3, 1]);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'orden, jugador inicial manual, sorteo y reducción de participantes',
    (t) async {
      final c = PriorityController(inputCooldown: Duration.zero);
      addTearDown(c.dispose);
      await mount(t, c);
      await selectCount(t, 3);
      await enter(t, 'priority-name-J1', 'Ana');
      await enter(t, 'priority-name-J2', 'Bruno');
      await press(t, 'priority-down-J1');
      expect(
        t.getTopLeft(key('priority-seat-J2')).dy,
        lessThan(t.getTopLeft(key('priority-seat-J1')).dy),
      );
      await press(t, 'priority-setup-select-J3');
      await press(t, 'priority-start');
      expect(c.value!.activePlayerId, 'J3');
      expect(c.value!.players.map((p) => p.id), ['J2', 'J1', 'J3']);
      c.reset();
      await t.pumpAndSettle();
      await selectCount(
        t,
        2,
      ); // Removing the chosen player selects the first seat.
      await press(t, 'priority-start');
      expect(c.value!.players.map((p) => p.id), ['J2', 'J1']);
      expect(c.value!.players.map((p) => p.name), ['Bruno', 'Ana']);
      expect(c.value!.activePlayerId, 'J2');
      c.reset();
      await t.pumpAndSettle();
      await press(t, 'priority-draw');
      await press(t, 'priority-start');
      expect(['J1', 'J2'], contains(c.value!.activePlayerId));
      expect(c.value!.players.map((p) => p.id), ['J2', 'J1']);
    },
  );

  testWidgets(
    'formularios rechazan vacío, negativos, texto y total desbordado',
    (t) async {
      final c = PriorityController();
      addTearDown(c.dispose);
      await mount(t, c);
      await enter(t, 'priority-name-J1', ' ');
      await enter(t, 'priority-build-points', '-1');
      await enter(t, 'priority-additional-J2', 'abc');
      await press(t, 'priority-start');
      expect(c.value, isNull);
      expect(find.text('Escribe un nombre.'), findsOneWidget);
      expect(
        find.text('Escribe un entero igual o mayor que cero.'),
        findsNWidgets(2),
      );
      await enter(t, 'priority-name-J1', 'Ana');
      await enter(t, 'priority-build-points', '300');
      await enter(t, 'priority-additional-J2', '9223372036854775807');
      await press(t, 'priority-start');
      expect(c.value, isNull);
      expect(key('priority-setup-error'), findsOneWidget);
      await enter(t, 'priority-additional-J2', '0');
      await press(t, 'priority-start');
      expect(c.value, isNotNull);
      await press(t, 'priority-count-J1');
      await enter(t, 'priority-edit-additional', '-1');
      await press(t, 'priority-edit-apply');
      expect(c.value!.player('J1').additionalActions, 0);
      expect(
        find.text('Escribe un entero igual o mayor que cero.'),
        findsOneWidget,
      );
      await enter(t, 'priority-edit-additional', '9223372036854775807');
      await press(t, 'priority-edit-apply');
      expect(c.value!.player('J1').additionalActions, 0);
      expect(find.textContaining('No se pudo aplicar'), findsOneWidget);
    },
  );

  testWidgets(
    'navegación conserva partida en memoria y nueva requiere confirmación',
    (t) async {
      final c = PriorityController(inputCooldown: Duration.zero);
      await t.pumpWidget(HeroClixApp(clock: testClock, priorityController: c));
      await press(t, 'mode-priority');
      await press(t, 'priority-start');
      await press(t, 'priority-action-J1');
      final match = c.value;
      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      await press(t, 'mode-editor');
      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      await press(t, 'mode-priority');
      expect(c.value, same(match));
      expect(key('priority-has-priority-J2'), findsOneWidget);
      await press(t, 'priority-new-game');
      await t.tap(find.text('Cancelar'));
      await t.pumpAndSettle();
      expect(c.value, same(match));
      await press(t, 'priority-new-game');
      await press(t, 'priority-reset-confirm');
      expect(c.value, isNull);
      expect(key('priority-setup'), findsOneWidget);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('rotar la mesa conserva partida y ventana en curso', (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(360, 800);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPhysicalSize);
    final c = PriorityController(inputCooldown: Duration.zero)
      ..start(players(6));
    addTearDown(c.dispose);
    await mount(t, c);
    await press(t, 'priority-action-J1');
    await press(t, 'priority-pass-J2');
    final before = c.value;
    final portraitTurns = t
        .widget<RotatedBox>(key('priority-orientation-J1'))
        .quarterTurns;
    t.view.physicalSize = const Size(800, 360);
    await t.pumpAndSettle();
    expect(c.value, same(before));
    expect(
      t.widget<RotatedBox>(key('priority-orientation-J1')).quarterTurns,
      isNot(portraitTurns),
    );
    await press(t, 'priority-pass-J3');
    expect(c.value!.priorityPlayerId, 'J4');
    expect(t.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 568),
    const Size(360, 800),
    const Size(800, 360),
    const Size(568, 320),
    const Size(320, 320),
    const Size(1024, 768),
  ]) {
    for (final scale in [1.0, 2.0, 3.0]) {
      for (var count = 2; count <= 6; count++) {
        testWidgets('$count paneles en $size texto $scale sin desbordes', (
          t,
        ) async {
          t.view.devicePixelRatio = 1;
          t.view.physicalSize = size;
          t.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(t.view.resetDevicePixelRatio);
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          final c = PriorityController(inputCooldown: Duration.zero)
            ..start(players(count));
          addTearDown(c.dispose);
          await mount(t, c);
          for (var i = 1; i <= count; i++) {
            expect(key('priority-panel-J$i'), findsOneWidget);
            if (scale == 1) {
              final controls = find.descendant(
                of: key('priority-panel-J$i'),
                matching: find.byWidgetPredicate(
                  (w) => w is FilledButton || w is TextButton,
                ),
              );
              for (final control in controls.evaluate()) {
                final size = t.getSize(find.byWidget(control.widget));
                expect(size.width, greaterThanOrEqualTo(48));
                expect(size.height, greaterThanOrEqualTo(48));
              }
            }
          }
          await press(t, 'priority-action-J1');
          await press(t, 'priority-pass-J2');
          expect(t.takeException(), isNull);
        });
      }
    }
  }

  for (final size in [
    const Size(320, 568),
    const Size(800, 360),
    const Size(320, 320),
  ]) {
    testWidgets('configuración y teclado en $size con texto 3', (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = size;
      t.platformDispatcher.textScaleFactorTestValue = 3;
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final c = PriorityController(inputCooldown: Duration.zero);
      addTearDown(c.dispose);
      await mount(t, c);
      await selectCount(t, 6);
      await enter(t, 'priority-name-J6', 'Nombre largo de participante');
      await press(t, 'priority-start');
      expect(c.value!.players.length, 6);
      await press(t, 'priority-count-J6');
      t.view.viewInsets = const FakeViewPadding(bottom: 140);
      addTearDown(t.view.resetViewInsets);
      await t.pumpAndSettle();
      await enter(t, 'priority-edit-additional', '3');
      await press(t, 'priority-edit-apply');
      expect(c.value!.player('J6').additionalActions, 3);
      expect(t.takeException(), isNull);
    });
  }
}

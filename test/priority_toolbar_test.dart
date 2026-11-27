import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:heroclix_simulator_trainer/domain/priority/priority.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_controller.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_screen.dart';
import 'package:heroclix_simulator_trainer/presentation/theme/app_theme.dart';

import 'priority_screen_test.dart' show mount, press, key;
import 'support/priority_stage3_fixtures.dart';

void main() {
  setUpAll(() => WidgetController.hitTestWarningShouldBeFatal = true);

  testWidgets('barra: flecha verde deshace y X roja confirma finalización', (
    t,
  ) async {
    final clock = PriorityFakeClock();
    final c = PriorityController(
      inputCooldown: Duration.zero,
      elapsedClock: clock.read,
    )..start(priorityConfig(3));
    addTearDown(c.dispose);
    await mount(t, c);
    IconButton button(String name) =>
        t.widget<IconButton>(key('priority-toolbar-$name'));
    expect(button('undo').color, const Color(0xFF69DB8C));
    expect((button('undo').icon as Icon).icon, Icons.undo_rounded);
    expect(button('undo').onPressed, isNull);
    expect(button('finish').color, const Color(0xFFFF7070));
    expect((button('finish').icon as Icon).icon, Icons.cancel_outlined);
    await press(t, 'priority-action-J1');
    expect(button('undo').onPressed, isNotNull);
    await press(t, 'priority-toolbar-undo');
    expect(c.value!.activePlayerId, 'J1');
    expect(c.value!.priorityPlayerId, 'J1');
    expect(c.value!.player('J1').availableActions, 3);
    expect(c.value!.isPaused, isTrue);
    expect(button('undo').onPressed, isNull);
    await press(t, 'priority-toolbar-finish');
    await t.tap(find.text('Cancelar'));
    await t.pumpAndSettle();
    expect(c.value!.underlyingPhase, PriorityPhase.activeTurn);
    await press(t, 'priority-toolbar-finish');
    await press(t, 'priority-finish-confirm');
    expect(c.value, isNull);
    expect(c.savedMatches.single.finished, isTrue);
    expect(key('priority-ranking-title'), findsNothing);
    expect(key('priority-setup'), findsOneWidget);
    expect(key('priority-toolbar-finish'), findsNothing);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'clasificación y nueva partida se acceden desde el menú sin perder guardados',
    (t) async {
      final c = PriorityController(inputCooldown: Duration.zero)
        ..start(priorityConfig(3, clock: false));
      addTearDown(c.dispose);
      c.dispatch(
        const PriorityCommand.setVictoryPoints('J2', 55),
        expectedRevision: c.value!.revision,
      );
      await mount(t, c);
      expect(key('priority-standings'), findsNothing);
      expect(key('priority-new-game'), findsNothing);
      await press(t, 'priority-standings');
      expect(find.text('1. Jugador 2: 55 PV · No eliminado'), findsOneWidget);
      await press(t, 'priority-ranking-close');
      await press(t, 'priority-new-game');
      await t.tap(find.text('Cancelar'));
      await t.pumpAndSettle();
      expect(c.value!.player('J2').victoryPoints, 55);
      await press(t, 'priority-new-game');
      await press(t, 'priority-reset-confirm');
      expect(c.value, isNull);
      expect(c.savedMatches.single.match.player('J2').victoryPoints, 55);
      expect(key('priority-toolbar-undo'), findsNothing);
      expect(key('priority-toolbar-finish'), findsNothing);
      expect(key('priority-setup'), findsOneWidget);
    },
  );

  for (final size in [const Size(320, 320), const Size(800, 360)]) {
    for (final scale in [1.0, 3.0]) {
      testWidgets(
        'barra con Volver y reloj en $size texto $scale: accesos táctiles completos',
        (t) async {
          t.view.devicePixelRatio = 1;
          t.view.physicalSize = size;
          t.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(t.view.resetDevicePixelRatio);
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          final clock = PriorityFakeClock();
          final c = PriorityController(
            inputCooldown: Duration.zero,
            elapsedClock: clock.read,
          )..start(priorityConfig(6));
          addTearDown(c.dispose);
          c.dispatch(
            const PriorityCommand.action('J1'),
            expectedRevision: c.value!.revision,
          );
          await t.pumpWidget(
            MaterialApp(
              theme: AppTheme.dark,
              locale: const Locale('es'),
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              supportedLocales: const [Locale('es')],
              home: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: FilledButton(
                      key: const ValueKey('toolbar-test-open'),
                      onPressed: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PriorityScreen(controller: c),
                        ),
                      ),
                      child: const Text('Abrir'),
                    ),
                  ),
                ),
              ),
            ),
          );
          await press(t, 'toolbar-test-open');
          expect(find.byType(BackButton), findsOneWidget);
          final buttons = [
            find.byType(BackButton),
            key('priority-toolbar-undo'),
            key('priority-pause-resume'),
            key('priority-toolbar-finish'),
            key('priority-more'),
          ];
          for (var i = 0; i < buttons.length; i++) {
            final rect = t.getRect(buttons[i]);
            expect(rect.width, greaterThanOrEqualTo(48));
            expect(rect.height, greaterThanOrEqualTo(48));
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(size.width));
            for (var j = i + 1; j < buttons.length; j++) {
              expect(rect.overlaps(t.getRect(buttons[j])), isFalse);
            }
          }
          await press(t, 'priority-toolbar-undo');
          expect(c.value!.isPaused, isTrue);
          await press(t, 'priority-toolbar-finish');
          await press(t, 'priority-finish-confirm');
          expect(c.value, isNull);
          expect(c.savedMatches.single.finished, isTrue);
          expect(key('priority-ranking-title'), findsNothing);
          expect(key('priority-setup'), findsOneWidget);
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
}

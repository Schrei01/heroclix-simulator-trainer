import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_controller.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_screen.dart';
import 'package:heroclix_simulator_trainer/presentation/theme/app_theme.dart';

import 'priority_screen_test.dart' show key, press, enter, selectCount;
import 'priority_seat_drag_test.dart' show dragSeat;

Widget setupApp(
  PriorityController c, {
  int seed = 9,
  bool reduceMotion = false,
}) => MaterialApp(
  theme: AppTheme.dark,
  locale: const Locale('es'),
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  supportedLocales: const [Locale('es')],
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: child!,
  ),
  home: PriorityScreen(controller: c, random: Random(seed)),
);
Finder marker(String id) => find.descendant(
  of: key('priority-setup-view-$id'),
  matching: find.text('INICIA'),
);
Future<void> beginDraw(WidgetTester t) async {
  await t.ensureVisible(key('priority-setup-seats'));
  await t.tap(key('priority-draw'));
  await t.pump();
}

void main() {
  setUpAll(() => WidgetController.hitTestWarningShouldBeFatal = true);
  for (var count = 2; count <= 6; count++) {
    testWidgets(
      '$count: toque y sorteo animado recorren todos y respetan el resultado aleatorio',
      (t) async {
        final c = PriorityController(inputCooldown: Duration.zero);
        addTearDown(c.dispose);
        final seed = count * 11;
        await t.pumpWidget(setupApp(c, seed: seed));
        await selectCount(t, count);
        await press(t, 'priority-setup-select-J$count');
        expect(marker('J$count'), findsOneWidget);
        final expected = 'J${Random(seed).nextInt(count) + 1}';
        await beginDraw(t);
        expect(t.widget<FilledButton>(key('priority-start')).onPressed, isNull);
        expect(t.widget<IconButton>(key('priority-draw')).onPressed, isNull);
        expect(find.text('INICIA'), findsNothing);
        final visited = <String>{};
        for (var frame = 0; frame < 60; frame++) {
          for (var i = 1; i <= count; i++) {
            final h = key('priority-setup-highlight-J$i');
            if (h.evaluate().isNotEmpty &&
                t.widget<Text>(h).data == 'SORTEANDO') {
              visited.add('J$i');
            }
          }
          await t.pump(const Duration(milliseconds: 40));
        }
        await t.pumpAndSettle();
        expect(visited, {for (var i = 1; i <= count; i++) 'J$i'});
        expect(marker(expected), findsOneWidget);
        expect(find.text('SORTEANDO'), findsNothing);
        expect(c.value, isNull);
        await press(t, 'priority-start');
        expect(c.value!.configuration.startingPlayerId, expected);
        expect(c.value!.activePlayerId, expected);
        expect(
          c.value!.players.map((p) => p.availableActions),
          everyElement(3),
        );
        expect(t.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'explicaciones solo en ⓘ; toque y pulsación larga conservan datos',
    (t) async {
      final c = PriorityController(inputCooldown: Duration.zero);
      addTearDown(c.dispose);
      await t.pumpWidget(setupApp(c));
      await selectCount(t, 3);
      await enter(t, 'priority-name-J2', 'Inicial');
      await enter(t, 'priority-build-points', '400');
      await enter(t, 'priority-additional-J2', '2');
      expect(
        find.byWidgetPredicate((w) => w is DropdownButtonFormField<String>),
        findsNothing,
      );
      expect(
        find.textContaining('Turnos y prioridad siguen este orden:'),
        findsNothing,
      );
      expect(
        find.textContaining('Solo descuenta quien tiene la prioridad.'),
        findsNothing,
      );
      expect(find.textContaining('En la mesa, usa'), findsNothing);
      await press(t, 'priority-setup-help');
      expect(key('priority-setup-help-title'), findsOneWidget);
      expect(
        find.textContaining('Solo descuenta quien tiene prioridad.'),
        findsOneWidget,
      );
      expect(find.textContaining('El dado sortea'), findsOneWidget);
      expect(
        find.textContaining('Al finalizar cualquier turno'),
        findsOneWidget,
      );
      await press(t, 'priority-setup-help-close');
      await press(t, 'priority-setup-select-J2');
      await dragSeat(t, 'J1', 'J3');
      expect(marker('J2'), findsOneWidget);
      await press(t, 'priority-start');
      expect(c.value!.activePlayerId, 'J2');
      expect(c.value!.players.map((p) => p.id), ['J3', 'J2', 'J1']);
      expect(c.value!.player('J2').name, 'Inicial');
      expect(c.value!.player('J2').totalActions, 6);
      expect(key('priority-setup-help'), findsNothing);
    },
  );
  testWidgets(
    'repetir sorteo tras mover asientos usa los jugadores actuales sin iniciar',
    (t) async {
      final c = PriorityController(inputCooldown: Duration.zero);
      addTearDown(c.dispose);
      const seed = 23;
      await t.pumpWidget(setupApp(c, seed: seed));
      await selectCount(t, 6);
      await t.ensureVisible(key('priority-setup-seats'));
      await dragSeat(t, 'J1', 'J6');
      final random = Random(seed);
      final order = ['J6', 'J2', 'J3', 'J4', 'J5', 'J1'];
      String? winner;
      for (var roll = 0; roll < 3; roll++) {
        winner = order[random.nextInt(order.length)];
        await press(t, 'priority-draw');
        expect(marker(winner), findsOneWidget);
        expect(c.value, isNull);
      }
      await press(t, 'priority-start');
      expect(c.value!.activePlayerId, winner);
      expect(c.value!.turnOrder, order);
    },
  );

  testWidgets('sorteo valida los datos y conserva errores visibles', (t) async {
    final c = PriorityController();
    addTearDown(c.dispose);
    await t.pumpWidget(setupApp(c));
    await enter(t, 'priority-name-J1', ' ');
    await press(t, 'priority-draw');
    expect(c.value, isNull);
    expect(key('priority-setup-error'), findsOneWidget);
    expect(find.text('SORTEANDO'), findsNothing);
    expect(marker('J1'), findsOneWidget);
    expect(t.widget<FilledButton>(key('priority-start')).onPressed, isNotNull);
  });
  for (final cancel in [
    'toque',
    'cantidad',
    'arrastre',
    'ayuda',
    'segundo plano',
    'salir',
  ]) {
    testWidgets('cancelar sorteo por $cancel evita una selección tardía', (
      t,
    ) async {
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final c = PriorityController(inputCooldown: Duration.zero);
      addTearDown(c.dispose);
      var seed = 0;
      while (Random(seed).nextInt(3) == 1) {
        seed++;
      }
      await t.pumpWidget(setupApp(c, seed: seed));
      await selectCount(t, 3);
      await press(t, 'priority-setup-select-J2');
      await beginDraw(t);
      await t.pump(const Duration(milliseconds: 200));
      var expected = 'J2';
      switch (cancel) {
        case 'toque':
          await press(t, 'priority-setup-select-J3');
          expected = 'J3';
        case 'cantidad':
          await selectCount(t, 2);
        case 'arrastre':
          await dragSeat(t, 'J1', 'J3');
        case 'ayuda':
          await press(t, 'priority-setup-help');
          await press(t, 'priority-setup-help-close');
        case 'segundo plano':
          t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
          await t.pump();
          t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        case 'salir':
          await t.pumpWidget(const SizedBox.shrink());
          await t.pump(const Duration(seconds: 3));
          expect(t.takeException(), isNull);
          await t.pumpWidget(setupApp(c, seed: seed));
          expected = 'J1';
      }
      await t.pump(const Duration(seconds: 3));
      await t.pumpAndSettle();
      expect(find.text('SORTEANDO'), findsNothing);
      expect(marker(expected), findsOneWidget);
      expect(c.value, isNull);
      await press(t, 'priority-start');
      expect(c.value!.activePlayerId, expected);
      expect(t.takeException(), isNull);
    });
  }
  for (final midDraw in [false, true]) {
    testWidgets(
      'movimiento reducido ${midDraw ? 'durante' : 'antes del'} sorteo conserva elección',
      (t) async {
        final c = PriorityController();
        addTearDown(c.dispose);
        const seed = 11;
        await t.pumpWidget(setupApp(c, seed: seed, reduceMotion: !midDraw));
        if (midDraw) {
          await beginDraw(t);
          await t.pump(const Duration(milliseconds: 300));
          await t.pumpWidget(setupApp(c, seed: seed, reduceMotion: true));
        } else {
          await press(t, 'priority-draw');
        }
        await t.pumpAndSettle();
        expect(find.text('SORTEANDO'), findsNothing);
        expect(marker('J${Random(seed).nextInt(2) + 1}'), findsOneWidget);
        expect(
          t.widget<FilledButton>(key('priority-start')).onPressed,
          isNotNull,
        );
        await t.pump(const Duration(seconds: 3));
        expect(t.takeException(), isNull);
      },
    );
  }
  for (final size in [const Size(320, 320), const Size(800, 360)]) {
    for (final count in [2, 6]) {
      testWidgets(
        'diagrama/dado/ayuda $count en $size texto 300 %: objetivos accesibles',
        (t) async {
          t.view.devicePixelRatio = 1;
          t.view.physicalSize = size;
          t.platformDispatcher.textScaleFactorTestValue = 3;
          addTearDown(t.view.resetDevicePixelRatio);
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          final c = PriorityController();
          addTearDown(c.dispose);
          await t.pumpWidget(setupApp(c));
          await selectCount(t, count);
          await press(t, 'priority-setup-help');
          await press(t, 'priority-setup-help-close');
          await t.ensureVisible(key('priority-setup-seats'));
          final dice = t.getRect(key('priority-draw'));
          expect(dice.width, greaterThanOrEqualTo(48));
          expect(dice.height, greaterThanOrEqualTo(48));
          for (var i = 1; i <= count; i++) {
            final seat = t.getRect(key('priority-setup-select-J$i'));
            expect(seat.width, greaterThanOrEqualTo(48));
            expect(seat.height, greaterThanOrEqualTo(48));
            expect(seat.overlaps(dice), isFalse);
          }
          await press(t, 'priority-setup-select-J$count');
          await press(t, 'priority-start');
          expect(c.value!.activePlayerId, 'J$count');
          expect(t.takeException(), isNull);
        },
      );
    }
  }
}

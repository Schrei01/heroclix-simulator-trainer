import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:heroclix_simulator_trainer/app.dart';
import 'package:heroclix_simulator_trainer/application/priority/priority_repository.dart';
import 'package:heroclix_simulator_trainer/application/priority/priority_session.dart';
import 'package:heroclix_simulator_trainer/application/priority/priority_session_codec.dart';
import 'package:heroclix_simulator_trainer/domain/priority/priority.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_controller.dart';

import 'priority_screen_test.dart' show mount, press, key;
import 'support/priority_stage3_fixtures.dart';
import 'support/priority_stage4_fixtures.dart';
import 'support/test_clock.dart';

void act(PriorityController c, PriorityCommand op) =>
    expect(c.dispatch(op, expectedRevision: c.value!.revision), isTrue);
Future<void> menu(WidgetTester t, String option) async {
  await press(t, 'priority-more');
  await press(t, 'priority-menu-$option');
}

void main() {
  setUpAll(() => WidgetController.hitTestWarningShouldBeFatal = true);

  testWidgets('ciclo de vida guarda y otra app recupera la respuesta pausada', (
    t,
  ) async {
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final store = PriorityTestStore(), elapsed = PriorityFakeClock();
    final a = await savedPriority(store, elapsed: elapsed);
    await t.pumpWidget(HeroClixApp(clock: testClock, priorityController: a));
    await press(t, 'mode-priority');
    await press(t, 'priority-free-J1');
    act(a, const PriorityCommand.setVictoryPoints('J2', 65));
    elapsed.advance(const Duration(seconds: 4));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await t.pumpAndSettle();
    expect(a.value!.isPaused, isTrue);
    expect(a.value!.player('J2').spentTime, const Duration(seconds: 4));
    // No explicit flush: the app lifecycle must have persisted the latest state.
    final disk = store.cloneDisk();
    await t.pumpWidget(const SizedBox.shrink());
    elapsed.advance(const Duration(days: 10));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final b = PriorityController(
      repository: PriorityRepository(disk),
      elapsedClock: elapsed.read,
    );
    await t.pumpWidget(HeroClixApp(clock: testClock, priorityController: b));
    await t.pumpAndSettle();
    await press(t, 'mode-priority');
    expect(b.value!.underlyingPhase, PriorityPhase.freeResponse);
    expect(b.value!.pendingResponders, ['J2', 'J3']);
    expect(b.value!.priorityPlayerId, 'J2');
    expect(b.value!.activePlayerId, 'J1');
    expect(b.value!.player('J2').victoryPoints, 65);
    expect(b.value!.player('J2').spentTime, const Duration(seconds: 4));
    expect(b.value!.isPaused, isTrue);
    await press(t, 'priority-pause-resume');
    await press(t, 'priority-responseFree-J2');
    expect(b.value!.priorityPlayerId, 'J3');
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox.shrink());
    await b.flush();
  });

  testWidgets(
    'recupera ventana, reanuda manualmente y Deshacer consecutivo desde historial',
    (t) async {
      final store = PriorityTestStore();
      final a = await savedPriority(store);
      addTearDown(a.dispose);
      act(a, const PriorityCommand.setVictoryPoints('J1', 55));
      act(a, const PriorityCommand.action('J1'));
      await a.flush();
      final elapsed = PriorityFakeClock();
      final b = PriorityController(
        repository: PriorityRepository(store.cloneDisk()),
        inputCooldown: Duration.zero,
        elapsedClock: elapsed.read,
      );
      addTearDown(b.dispose);
      await b.initialize();
      await mount(t, b);
      await t.pumpAndSettle();
      expect(key('priority-has-priority-J2'), findsOneWidget);
      expect(key('priority-active-J1'), findsOneWidget);
      expect(
        t.widget<FilledButton>(key('priority-responseAction-J2')).onPressed,
        isNull,
      );
      expect(t.widget<Text>(key('priority-score-J1')).data, '55 PV');
      await press(t, 'priority-pause-resume');
      await press(t, 'priority-responseAction-J2');
      expect(b.value!.priorityPlayerId, 'J3');
      await menu(t, 'history');
      expect(key('priority-history-title'), findsOneWidget);
      await press(t, 'priority-history-undo');
      expect(b.value!.pendingResponders, ['J2', 'J3']);
      expect(b.value!.isPaused, isTrue);
      expect(b.value!.player('J2').availableActions, 3);
      await press(t, 'priority-history-undo');
      expect(b.value!.underlyingPhase, PriorityPhase.activeTurn);
      expect(b.value!.priorityPlayerId, 'J1');
      expect(b.value!.player('J1').availableActions, 3);
      expect(b.value!.player('J1').victoryPoints, 55);
      expect(
        b.session!.history.where((e) => e.kind == PriorityLogKind.undo).length,
        2,
      );
      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      expect(key('priority-active-J1'), findsOneWidget);
      expect(b.value!.isPaused, isTrue);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
      await b.flush();
    },
  );

  testWidgets(
    'fallo de guardado impide nueva partida y permite reintentar sin perder PV',
    (t) async {
      final store = PriorityTestStore();
      final c = await savedPriority(store, clock: false);
      addTearDown(c.dispose);
      await c.flush();
      await mount(t, c);
      store.failWrite = true;
      act(c, const PriorityCommand.setVictoryPoints('J1', 25));
      await c.flush();
      await t.pumpAndSettle();
      expect(key('priority-storage-error'), findsOneWidget);
      await press(t, 'priority-new-game');
      await press(t, 'priority-reset-confirm');
      expect(c.value!.player('J1').victoryPoints, 25);
      store.failWrite = false;
      await press(t, 'priority-retry-save');
      expect(c.storageError, isNull);
      await press(t, 'priority-new-game');
      await press(t, 'priority-reset-confirm');
      expect(c.value, isNull);
      expect(c.savedMatches.single.match.player('J1').victoryPoints, 25);
      expect(key('priority-setup'), findsOneWidget);
    },
  );

  testWidgets(
    'finalización manual confirma, resume operaciones y abre historial',
    (t) async {
      final c = PriorityController(inputCooldown: Duration.zero)
        ..start(priorityConfig(3, clock: false));
      addTearDown(c.dispose);
      act(c, const PriorityCommand.action('J1'));
      act(c, const PriorityCommand.responseAction('J2'));
      act(c, const PriorityCommand.pass('J3'));
      await mount(t, c);
      await menu(t, 'finish');
      await t.tap(find.text('Cancelar'));
      await t.pumpAndSettle();
      expect(c.value!.phase, PriorityPhase.activeTurn);
      await menu(t, 'finish');
      await press(t, 'priority-finish-confirm');
      expect(c.value!.phase, PriorityPhase.finished);
      expect(key('priority-ranking-title'), findsOneWidget);
      expect(key('priority-result-stats-J1'), findsOneWidget);
      expect(find.text('ACTION 1 · FREE 0'), findsOneWidget);
      await press(t, 'priority-result-history');
      expect(key('priority-history-title'), findsOneWidget);
      expect(c.value!.phase, PriorityPhase.finished);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'consulta finalizada desde almacenamiento nuevo sin abrir partida activa',
    (t) async {
      final store = PriorityTestStore();
      final a = await savedPriority(store, clock: false);
      addTearDown(a.dispose);
      act(a, const PriorityCommand.setVictoryPoints('J1', 120));
      act(a, const PriorityCommand.finish());
      final id = a.session!.id;
      await a.parkAndReset();
      final b = PriorityController(
        repository: PriorityRepository(store.cloneDisk()),
      );
      addTearDown(b.dispose);
      await b.initialize();
      await mount(t, b);
      await menu(t, 'saved');
      expect(key('priority-library-title'), findsOneWidget);
      await press(t, 'priority-consult-$id');
      expect(key('priority-saved-results'), findsOneWidget);
      expect(find.text('1. Jugador 1: 120 PV · No eliminado'), findsOneWidget);
      expect(b.value, isNull);
      await t.scrollUntilVisible(key('priority-saved-history'), 200);
      await press(t, 'priority-saved-history');
      expect(key('priority-history-title'), findsOneWidget);
      expect(key('priority-history-undo'), findsNothing);
      expect(b.value, isNull);
    },
  );

  testWidgets('retomar guardada confirma y conserva la otra partida', (
    t,
  ) async {
    final clock = PriorityFakeClock();
    final c = PriorityController(
      inputCooldown: Duration.zero,
      elapsedClock: clock.read,
    )..start(priorityConfig(3, first: 'J2'));
    addTearDown(c.dispose);
    act(c, const PriorityCommand.action('J2'));
    final firstId = c.session!.id;
    await c.parkAndReset();
    c.start(priorityConfig(2));
    final secondId = c.session!.id;
    await mount(t, c);
    await menu(t, 'saved');
    await press(t, 'priority-continue-$firstId');
    await t.tap(find.text('Cancelar'));
    await t.pumpAndSettle();
    expect(c.session!.id, secondId);
    await press(t, 'priority-continue-$firstId');
    await press(t, 'priority-open-confirm');
    expect(c.session!.id, firstId);
    expect(c.value!.configuration.startingPlayerId, 'J2');
    expect(c.value!.activePlayerId, 'J2');
    expect(c.value!.priorityPlayerId, 'J3');
    expect(c.value!.underlyingPhase, PriorityPhase.actionResponse);
    expect(c.value!.isPaused, isTrue);
    expect(c.savedMatches.length, 2);
    expect(key('priority-table'), findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'descartar guardada exige confirmación y no afecta otra partida',
    (t) async {
      final c = PriorityController(inputCooldown: Duration.zero)
        ..start(priorityConfig(2, clock: false));
      addTearDown(c.dispose);
      final id = c.session!.id;
      await c.parkAndReset();
      await mount(t, c);
      await menu(t, 'saved');
      await press(t, 'priority-delete-$id');
      await t.tap(find.text('Cancelar'));
      await t.pumpAndSettle();
      expect(c.savedMatches.length, 1);
      await press(t, 'priority-delete-$id');
      await press(t, 'priority-delete-saved-confirm');
      expect(c.savedMatches, isEmpty);
      expect(find.text('Todavía no hay partidas guardadas.'), findsOneWidget);
    },
  );

  testWidgets(
    'lectura dañada y recuperación se muestran en 320×320 con texto 300 %',
    (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(320, 320);
      t.platformDispatcher.textScaleFactorTestValue = 3;
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final store = PriorityTestStore()..documents['working'] = '{roto';
      final c = PriorityController(repository: PriorityRepository(store));
      addTearDown(c.dispose);
      await c.initialize();
      await mount(t, c);
      await t.pumpAndSettle();
      expect(key('priority-start'), findsNothing);
      expect(key('priority-retry-load'), findsOneWidget);
      expect(t.takeException(), isNull);
      final valid = PriorityController()
        ..start(priorityConfig(2, clock: false));
      addTearDown(valid.dispose);
      store.documents['working'] = const PrioritySessionCodec().encode(
        valid.session,
      );
      await press(t, 'priority-retry-load');
      expect(c.ready, isTrue);
      expect(key('priority-table'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
      await c.flush();
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(800, 360),
    const Size(320, 320),
  ]) {
    for (final scale in [1.0, 3.0]) {
      testWidgets('historial y biblioteca en $size texto $scale', (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = size;
        t.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(t.view.resetDevicePixelRatio);
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final c = PriorityController(inputCooldown: Duration.zero)
          ..start(priorityConfig(6, clock: false));
        addTearDown(c.dispose);
        act(c, const PriorityCommand.action('J1'));
        await mount(t, c);
        await menu(t, 'history');
        expect(key('priority-history-title'), findsOneWidget);
        await press(t, 'priority-history-undo');
        expect(c.value!.underlyingPhase, PriorityPhase.activeTurn);
        await t.tap(find.byType(BackButton));
        await t.pumpAndSettle();
        await menu(t, 'saved');
        expect(key('priority-library-title'), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }
  }
}

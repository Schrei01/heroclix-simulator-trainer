import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/application/priority/priority_repository.dart';
import 'package:heroclix_simulator_trainer/domain/priority/priority.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_controller.dart';

import 'priority_screen_test.dart' show mount, press, key;
import 'support/priority_stage3_fixtures.dart';
import 'support/priority_stage4_fixtures.dart';

void act(PriorityController c, PriorityCommand op) =>
    expect(c.dispatch(op, expectedRevision: c.value!.revision), isTrue);
Future<void> finish(WidgetTester t) async {
  await press(t, 'priority-toolbar-finish');
  await press(t, 'priority-finish-confirm');
}

void main() {
  setUpAll(() => WidgetController.hitTestWarningShouldBeFatal = true);

  testWidgets(
    'finalizar con reloj en marcha guarda antes de volver y se consulta tras reinicio',
    (t) async {
      final store = PriorityTestStore();
      var micros = 0;
      final c = PriorityController(
        repository: PriorityRepository(store),
        inputCooldown: Duration.zero,
        elapsedClock: () => Duration(microseconds: micros += 1000),
      );
      addTearDown(c.dispose);
      await c.initialize();
      c.start(priorityConfig(3));
      act(c, const PriorityCommand.setVictoryPoints('J2', 125));
      act(c, const PriorityCommand.action('J1'));
      final id = c.session!.id;
      await mount(t, c);
      await finish(t);
      expect(c.value, isNull);
      expect(key('priority-setup'), findsOneWidget);
      expect(key('priority-ranking-title'), findsNothing);
      expect(key('priority-ranking-close'), findsNothing);
      final saved = await c.readSaved(id);
      expect(saved.match.phase, PriorityPhase.finished);
      expect(saved.match.priorityPlayerId, isNull);
      expect(saved.match.player('J2').victoryPoints, 125);
      expect(saved.count('J1', PriorityEventType.action), 1);
      final spent = saved.match.players.map((p) => p.spentTime).toList();
      await t.pump(const Duration(seconds: 10));
      expect(
        (await c.readSaved(id)).match.players.map((p) => p.spentTime),
        spent,
      );
      final b = PriorityController(
        repository: PriorityRepository(store.cloneDisk()),
      );
      addTearDown(b.dispose);
      await b.initialize();
      expect(b.value, isNull);
      expect(b.savedMatches.single.finished, isTrue);
      expect((await b.readSaved(id)).match.player('J2').victoryPoints, 125);
      expect(t.takeException(), isNull);
    },
  );

  for (final failure in ['all', 'archive', 'working']) {
    testWidgets(
      'fallo de $failure no pierde resultados; reintentar guarda y vuelve sin resumen',
      (t) async {
        final store = PriorityTestStore();
        final c = await savedPriority(store);
        addTearDown(c.dispose);
        act(c, const PriorityCommand.setVictoryPoints('J1', 85));
        final id = c.session!.id;
        await c.flush();
        await mount(t, c);
        if (failure == 'all') {
          store.failWrite = true;
        } else {
          store.failWriteIds.add(failure == 'archive' ? id : 'working');
        }
        await finish(t);
        expect(c.value!.phase, PriorityPhase.finished);
        expect(c.value!.player('J1').victoryPoints, 85);
        expect(c.session!.id, id);
        expect(key('priority-storage-error'), findsOneWidget);
        expect(key('priority-setup'), findsNothing);
        expect(key('priority-ranking-title'), findsNothing);
        store.failWrite = false;
        store.failWriteIds.clear();
        await press(t, 'priority-retry-save');
        expect(c.value, isNull);
        expect(key('priority-setup'), findsOneWidget);
        expect(key('priority-ranking-title'), findsNothing);
        final archived = await c.repository!.read(id);
        expect(archived.match.phase, PriorityPhase.finished);
        expect(archived.match.player('J1').victoryPoints, 85);
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'deshacer después de un fallo de guardado cancela el retorno pendiente',
    (t) async {
      final store = PriorityTestStore();
      final c = await savedPriority(store);
      addTearDown(c.dispose);
      await c.flush();
      await mount(t, c);
      store.failWrite = true;
      await finish(t);
      expect(c.value!.phase, PriorityPhase.finished);
      await press(t, 'priority-toolbar-undo');
      expect(c.value!.underlyingPhase, PriorityPhase.activeTurn);
      expect(c.value!.isPaused, isTrue);
      store.failWrite = false;
      await press(t, 'priority-retry-save');
      expect(c.value!.underlyingPhase, PriorityPhase.activeTurn);
      expect(c.storageError, isNull);
      expect(key('priority-table'), findsOneWidget);
      expect(key('priority-setup'), findsNothing);
      await finish(t);
      expect(c.value, isNull);
      expect(key('priority-setup'), findsOneWidget);
      expect(key('priority-ranking-title'), findsNothing);
    },
  );
}

import 'dart:ui' show PointerDeviceKind;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:heroclix_simulator_trainer/app.dart';
import 'package:heroclix_simulator_trainer/application/priority/priority_repository.dart';
import 'package:heroclix_simulator_trainer/domain/priority/priority.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_controller.dart';

import 'priority_screen_test.dart' show mount, press, key, enter;
import 'support/priority_stage3_fixtures.dart';
import 'support/priority_stage4_fixtures.dart';
import 'support/test_clock.dart';

void main() {
  setUpAll(() => WidgetController.hitTestWarningShouldBeFatal = true);

  testWidgets(
    'acciones, respuestas, pases, PV y Deshacer no muestran letreros inferiores',
    (t) async {
      final clock = PriorityFakeClock();
      final c = PriorityController(
        inputCooldown: Duration.zero,
        elapsedClock: clock.read,
      )..start(priorityConfig(3));
      addTearDown(c.dispose);
      await mount(t, c);
      for (final id in [
        'action-J1',
        'responseAction-J2',
        'pass-J3',
        'endTurn-J1',
        'free-J2',
        'responseFree-J3',
        'pass-J1',
      ]) {
        await press(t, 'priority-$id');
        expect(find.byType(SnackBar), findsNothing);
      }
      await t.ensureVisible(key('priority-score-plus-J1'));
      await t.tap(key('priority-score-plus-J1'));
      await t.pump(const Duration(milliseconds: 20));
      expect(c.value!.player('J1').victoryPoints, 5);
      expect(key('priority-score-delta-J1'), findsOneWidget);
      await press(t, 'priority-toolbar-undo');
      expect(c.value!.player('J1').victoryPoints, 0);
      expect(c.value!.isPaused, isTrue);
      expect(find.byType(SnackBar), findsNothing);
      expect(
        find.text('Operación deshecha. Los relojes quedan pausados.'),
        findsNothing,
      );
      await press(t, 'priority-pause-resume');
      await press(t, 'priority-count-J1');
      await enter(t, 'priority-edit-additional', '1');
      await press(t, 'priority-edit-apply');
      expect(find.byType(SnackBar), findsNothing);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'mantener pulsados PV/posición y pasar por controles no abre etiquetas',
    (t) async {
      final c = PriorityController(inputCooldown: Duration.zero)
        ..start(priorityConfig(3, clock: false));
      addTearDown(c.dispose);
      await mount(t, c);
      for (final id in ['priority-score-J1', 'priority-rank-badge-J1']) {
        await t.longPress(key(id));
        await t.pumpAndSettle();
        expect(find.text('0 puntos de victoria'), findsNothing);
        expect(find.text('Posición 1 por puntos de victoria'), findsNothing);
      }
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      for (final id in [
        'priority-count-J1',
        'priority-score-plus-J1',
        'priority-skull-J1',
        'priority-toolbar-finish',
        'priority-more',
      ]) {
        await t.ensureVisible(key(id));
        await mouse.moveTo(t.getCenter(key(id)));
        await t.pump(const Duration(seconds: 1));
        expect(
          find.textContaining('Editar acciones de Jugador 1.'),
          findsNothing,
        );
        expect(find.text('Sumar 5 PV a Jugador 1'), findsNothing);
        expect(find.text('Eliminar a Jugador 1'), findsNothing);
        expect(find.text('Finalizar partida'), findsNothing);
        expect(find.text('Más opciones'), findsNothing);
        expect(find.byType(SnackBar), findsNothing);
      }
      await mouse.removePointer();
      expect(t.takeException(), isNull);
    },
  );

  for (final backup in [false, true]) {
    testWidgets(
      'recuperación ${backup ? 'de copia válida' : 'normal'} sin popup conserva la información en Historial',
      (t) async {
        final store = PriorityTestStore();
        final a = await savedPriority(store);
        addTearDown(a.dispose);
        a.dispatch(
          const PriorityCommand.action('J1'),
          expectedRevision: a.value!.revision,
        );
        await a.flush();
        final disk = store.cloneDisk();
        if (backup) {
          disk.documents[PriorityRepository.backupId] =
              disk.documents['working']!;
          disk.documents['working'] = '{roto';
        }
        final c = PriorityController(
          repository: PriorityRepository(disk),
          inputCooldown: Duration.zero,
        );
        addTearDown(c.dispose);
        await c.initialize();
        await mount(t, c);
        await t.pumpAndSettle();
        expect(c.value!.isPaused, isTrue);
        expect(c.value!.pendingResponders, ['J2', 'J3']);
        expect(find.byType(SnackBar), findsNothing);
        expect(c.recoveryNotice, isNotNull);
        await press(t, 'priority-more');
        await press(t, 'priority-menu-history');
        final notice = t
            .widget<Text>(key('priority-history-recovery-notice'))
            .data!;
        expect(
          notice,
          contains(backup ? 'copia anterior válida' : 'Partida recuperada'),
        );
        expect(find.byType(SnackBar), findsNothing);
        await t.pumpWidget(const SizedBox.shrink());
        await c.flush();
      },
    );
  }

  testWidgets(
    'controles conservan sus nombres accesibles al ocultar las etiquetas visuales',
    (t) async {
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final semantics = t.ensureSemantics();
      final clock = PriorityFakeClock();
      final c = PriorityController(
        inputCooldown: Duration.zero,
        elapsedClock: clock.read,
      )..start(priorityConfig(3));
      await t.pumpWidget(HeroClixApp(clock: testClock, priorityController: c));
      await press(t, 'mode-priority');
      await press(t, 'priority-action-J1');
      final labels = <String, String>{
        'priority-toolbar-undo': 'Deshacer última operación',
        'priority-pause-resume': 'Pausar',
        'priority-toolbar-finish': 'Finalizar partida',
        'priority-more': 'Más opciones',
        'priority-score-plus-J1': 'Sumar 5 PV a Jugador 1',
        'priority-score-minus-J1': 'Restar 5 PV a Jugador 1',
        'priority-skull-J1': 'Eliminar a Jugador 1',
        'priority-count-J1': 'Editar acciones de Jugador 1',
      };
      for (final entry in labels.entries) {
        expect(
          t.getSemantics(key(entry.key)).getSemanticsData().label,
          contains(entry.value),
        );
      }
      expect(
        t.getSemantics(find.byType(BackButton)).getSemanticsData().label,
        MaterialLocalizations.of(t.element(find.byType(BackButton)))
            .backButtonTooltip,
      );
      expect(find.byType(SnackBar), findsNothing);
      expect(t.takeException(), isNull);
      semantics.dispose();
      await t.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'error de consulta permanece en la biblioteca y no genera SnackBar',
    (t) async {
      final store = PriorityTestStore();
      final c = await savedPriority(store, clock: false);
      addTearDown(c.dispose);
      final id = c.session!.id;
      await c.parkAndReset();
      await mount(t, c);
      await press(t, 'priority-more');
      await press(t, 'priority-menu-saved');
      store.failRead = true;
      await press(t, 'priority-consult-$id');
      expect(key('priority-library-operation-error'), findsOneWidget);
      expect(key('priority-saved-$id'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      store.failRead = false;
      await press(t, 'priority-consult-$id');
      expect(key('priority-saved-results'), findsOneWidget);
      expect(c.value, isNull);
      expect(find.byType(SnackBar), findsNothing);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:heroclix_simulator_trainer/application/board/board_session.dart';
import 'package:heroclix_simulator_trainer/domain/characters/movement_ability.dart';
import 'package:heroclix_simulator_trainer/domain/movement/movement.dart';
import 'package:heroclix_simulator_trainer/presentation/movement/movement_controls.dart';
import 'package:heroclix_simulator_trainer/presentation/movement/movement_painter.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/editor_controller.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/character_dialog.dart';
import 'package:heroclix_simulator_trainer/presentation/vision/tactical_controls.dart';

import 'support/movement_contract.dart';
import 'support/vision_contract.dart';
import 'vision_editor_test.dart' show openRules;
import 'editor_test.dart' show cellPosition;
import 'character_editor_test.dart' show press;

Finder mk(String id) => find.byKey(ValueKey(id));
Future<void> openMovement(WidgetTester tester, EditorController c) async {
  showMovementReport(tester.element(find.byType(Scaffold).last), c);
  await tester.pumpAndSettle();
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'herramienta construye ruta tocando casillas y confirmar conserva undo',
    (t) async {
      final c = await openRules(t, data: mw());
      c.selectCharacter('figure-1');
      await press(t, 'tool-movement');
      expect(find.text('Ensayo de movimiento'), findsOneWidget);
      await press(t, 'movement-close');
      await t.tapAt(cellPosition(t, c, 'B1'));
      await t.pumpAndSettle();
      await t.tapAt(cellPosition(t, c, 'C1'));
      await t.pumpAndSettle();
      expect(c.movement.route, [vc('A1'), vc('B1'), vc('C1')]);
      expect(c.value.characters.byId('figure-1')!.position, vc('A1'));
      expect(
        t
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .any((p) => p.foregroundPainter is MovementPainter),
        true,
      );
      await press(t, 'movement-report');
      await press(t, 'movement-confirm');
      expect(c.value.characters.byId('figure-1')!.position, vc('C1'));
      c.undo();
      expect(c.value.characters.byId('figure-1')!.position, vc('A1'));
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('inválida bloquea confirmar; quitar paso y cancelar no mueve', (
    t,
  ) async {
    final c = await openRules(t, data: mw());
    c.setTool(EditorTool.movement);
    c.beginMovement('figure-1');
    c.movementCell(vc('D4'));
    await t.pumpAndSettle();
    await openMovement(t, c);
    expect(t.widget<Text>(mk('movement-result')).data, 'RUTA INVÁLIDA');
    expect(t.widget<FilledButton>(mk('movement-confirm')).onPressed, isNull);
    await press(t, 'movement-close');
    await press(t, 'movement-back');
    expect(c.movement.route, [vc('A1')]);
    await press(t, 'movement-cancel');
    expect(c.movement.sourceId, isNull);
    expect(c.value.characters.byId('figure-1')!.position, vc('A1'));
  });
  testWidgets(
    'busca alternativas, aplica ensayo y muestra comparación y registro',
    (t) async {
      final c = await openRules(
        t,
        data: mw(extras: [vf(2, 'D4', team: 'team-2')]),
      );
      c.setTool(EditorTool.movement);
      c.beginMovement('figure-1');
      await t.pumpAndSettle();
      await openMovement(t, c);
      await t.enterText(mk('movement-destination'), 'C1');
      await press(t, 'movement-search');
      expect(c.movement.alternatives!.routes, isNotEmpty);
      await press(t, 'movement-route-0');
      expect(c.movement.result!.status, MovementStatus.valid);
      await press(t, 'movement-log');
      expect(find.textContaining('§10.2'), findsWidgets);
      await press(t, 'movement-comparison');
      expect(find.textContaining('Distancia 3'), findsWidgets);
      await press(t, 'movement-cancel-dialog');
      expect(c.value.characters.byId('figure-1')!.position, vc('A1'));
      expect(c.history.canUndo, false);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('Editor ofrece movimiento y el toque ensaya sin reposicionar', (
    t,
  ) async {
    final c = await openRules(t, data: mw());
    await press(t, 'tool-movement');
    await press(t, 'movement-close');
    await t.tapAt(cellPosition(t, c, 'A1'));
    await t.pumpAndSettle();
    await t.tapAt(cellPosition(t, c, 'B1'));
    await t.pumpAndSettle();
    expect(c.movement.route, [vc('A1'), vc('B1')]);
    expect(c.value.characters.byId('figure-1')!.position, vc('A1'));
    await press(t, 'movement-report');
    await press(t, 'movement-special');
    expect(t.widget<Text>(mk('movement-result')).data, 'NO EVALUADA');
    expect(t.widget<FilledButton>(mk('movement-confirm')).onPressed, isNull);
    expect(t.takeException(), isNull);
  });
  testWidgets('ficha persiste IM y editar alcance no la borra', (t) async {
    final c = await openRules(t, data: mw());
    showCharacterDialog(
      t.element(find.byType(Scaffold).last),
      c,
      character: c.value.characters.byId('figure-1'),
    );
    await t.pumpAndSettle();
    await press(t, 'movement-abilities');
    await press(t, 'movement-ability-characters');
    await press(t, 'save-character');
    expect(c.value.characters.byId('figure-1')!.movementAbilities, {
      MovementAbility.characters,
    });
    c.setTool(EditorTool.targets);
    c.setTargetSource('figure-1');
    await t.pumpAndSettle();
    showTargetList(t.element(find.byType(Scaffold).last), c);
    await t.pumpAndSettle();
    await press(t, 'target-edit-range');
    await t.enterText(mk('range-input'), '2');
    await press(t, 'range-save');
    expect(c.value.characters.byId('figure-1')!.movementAbilities, {
      MovementAbility.characters,
    });
    expect(t.takeException(), isNull);
  });
  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(800, 360), 1.0),
    (const Size(320, 320), 3.0),
  ]) {
    testWidgets('movimiento sin desbordes en $size texto $scale', (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = size;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      t.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final c = await openRules(t, data: mw());
      c.setTool(EditorTool.movement);
      c.beginMovement('figure-1');
      c.movementCell(vc('B1'));
      await t.pumpAndSettle();
      await openMovement(t, c);
      await press(t, 'movement-log');
      await press(t, 'movement-close');
      expect(t.takeException(), isNull);
    });
  }
}

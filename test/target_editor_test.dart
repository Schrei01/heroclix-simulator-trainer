import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:heroclix_simulator_trainer/application/board/board_session.dart';
import 'package:heroclix_simulator_trainer/domain/rules/target_analysis_service.dart';
import 'package:heroclix_simulator_trainer/presentation/vision/tactical_controls.dart';

import 'character_editor_test.dart' show press;
import 'editor_test.dart' show cellPosition;
import 'vision_editor_test.dart' show openRules, vp;
import 'support/vision_contract.dart';

Finder tk(String id) => find.byKey(ValueKey(id));
Future<void> closeDialog(WidgetTester tester) async {
  final close = find.text('Cerrar').last;
  await tester.ensureVisible(close);
  await tester.tap(close);
  await tester.pumpAndSettle();
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets('elegir origen desde la lista sin selección previa', (
    tester,
  ) async {
    final c = await openRules(tester);
    c.updateSight((p) => p.clear());
    c.clearSelection();
    c.setTool(EditorTool.targets);
    showTargetList(tester.element(find.byType(Scaffold).last), c);
    await tester.pumpAndSettle();
    expect(c.tactical.sourceId, isNull);
    await tester.tap(tk('target-source-null'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A · Figura 1 · A1').last);
    await tester.pumpAndSettle();
    expect(c.tactical.sourceId, 'figure-1');
    expect(tk('target-figure-2'), findsOneWidget);
    await closeDialog(tester);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'medir dos casillas vacías, diferencias, cero y anotación del segmento',
    (tester) async {
      final c = await openRules(
        tester,
        data: vs(source: false, destination: false),
      );
      c.setTool(EditorTool.distance);
      await tester.pumpAndSettle();
      await tester.tapAt(cellPosition(tester, c, 'A1'));
      await tester.pumpAndSettle();
      await tester.tapAt(cellPosition(tester, c, 'D3'));
      await tester.pumpAndSettle();
      expect(c.tactical.measurement!.squares, 3);
      expect(vp(tester).annotation, 'D: 3');
      expect(vp(tester).evaluation, isNull);
      await tester.ensureVisible(tk('distance-summary'));
      await tester.tap(tk('distance-summary'));
      await tester.pumpAndSettle();
      expect(find.text('3 casillas'), findsOneWidget);
      await press(tester, 'distance-deltas');
      expect(find.text('Diferencia de filas: 2 · columnas: 3'), findsOneWidget);
      await closeDialog(tester);
      c.updateSight((p) => p.chooseOrigin = false);
      await tester.tapAt(cellPosition(tester, c, 'A1'));
      await tester.pumpAndSettle();
      expect(c.tactical.measurement!.squares, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'lista enemiga, filtro aliados, selección y detalle comparten motor',
    (tester) async {
      final c = await openRules(tester, data: vs(extras: [vf(3, 'A3')]));
      c.selectCharacter('figure-1');
      c.setTool(EditorTool.targets);
      showTargetList(tester.element(find.byType(Scaffold).last), c);
      await tester.pumpAndSettle();
      expect(tk('target-figure-2'), findsOneWidget);
      expect(tk('target-figure-3'), findsNothing);
      await tester.tap(tk('target-filter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aliadas').last);
      await tester.pumpAndSettle();
      expect(tk('target-figure-3'), findsOneWidget);
      expect(tk('target-figure-2'), findsNothing);
      await tester.ensureVisible(tk('target-figure-3'));
      await tester.tap(tk('target-figure-3'));
      await tester.pumpAndSettle();
      expect(c.tactical.selected!.target.id, 'figure-3');
      expect(vp(tester).highlightTarget, true);
      expect(vp(tester).annotation, 'D: 2 / A: 4');
      await tester.ensureVisible(tk('selected-target-summary'));
      await tester.tap(tk('selected-target-summary'));
      await tester.pumpAndSettle();
      expect(find.text(targetLabel(c.tactical.selected!.status)), findsWidgets);
      expect(find.textContaining('no significa ataque legal'), findsOneWidget);
      expect(find.textContaining('Mismo equipo'), findsOneWidget);
      await closeDialog(tester);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'editar alcance en lista actualiza clasificación; entrada inválida y undo',
    (tester) async {
      final c = await openRules(tester);
      c.selectCharacter('figure-1');
      c.setTool(EditorTool.targets);
      showTargetList(tester.element(find.byType(Scaffold).last), c);
      await tester.pumpAndSettle();
      await press(tester, 'target-edit-range');
      await tester.enterText(tk('range-input'), '-1');
      await press(tester, 'range-save');
      expect(find.text('Introduce un entero de 0 a 99.'), findsOneWidget);
      await tester.enterText(tk('range-input'), '2');
      await press(tester, 'range-save');
      expect(c.tactical.visible.single.status, TargetStatus.outOfRange);
      expect(find.textContaining('Fuera de alcance'), findsOneWidget);
      await closeDialog(tester);
      c.undo();
      await tester.pumpAndSettle();
      expect(c.tactical.visible.single.status, TargetStatus.inRangeClear);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'simulador permite medir y consultar objetivos sin editar piezas',
    (tester) async {
      final c = await openRules(tester, mode: 'simulator');
      final original = c.value.characters;
      await press(tester, 'analysis-mode');
      await tester.tap(tk('mode-distance'));
      await tester.pumpAndSettle();
      expect(c.value.tool, EditorTool.distance);
      await tester.tapAt(cellPosition(tester, c, 'A2'));
      await tester.pumpAndSettle();
      await tester.tapAt(cellPosition(tester, c, 'D4'));
      await tester.pumpAndSettle();
      expect(c.tactical.measurement!.squares, 3);
      expect(c.value.characters, same(original));
      c.selectCharacter('figure-1');
      await press(tester, 'analysis-mode');
      await tester.tap(tk('mode-targets'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(tk('target-figure-2'));
      await tester.tap(tk('target-figure-2'));
      await tester.pumpAndSettle();
      expect(c.tactical.selected!.target.id, 'figure-2');
      expect(c.value.characters, same(original));
      expect(tester.takeException(), isNull);
    },
  );
  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(800, 360), 1.0),
    (const Size(320, 320), 3.0),
  ]) {
    testWidgets('objetivos y medición accesibles en $size texto $scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final c = await openRules(tester, mode: 'referee');
      c.selectCharacter('figure-1');
      c.setTool(EditorTool.targets);
      showTargetList(tester.element(find.byType(Scaffold).last), c);
      await tester.pumpAndSettle();
      await tester.ensureVisible(tk('target-figure-2'));
      await tester.tap(tk('target-figure-2'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(tk('selected-target-summary'));
      await tester.tap(tk('selected-target-summary'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(tk('target-result'));
      expect(find.textContaining('En alcance'), findsWidgets);
      await closeDialog(tester);
      c.setTool(EditorTool.distance);
      await tester.pumpAndSettle();
      await tester.ensureVisible(tk('distance-summary'));
      await tester.tap(tk('distance-summary'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(tk('distance-result'));
      expect(tester.takeException(), isNull);
      await closeDialog(tester);
    });
  }
}

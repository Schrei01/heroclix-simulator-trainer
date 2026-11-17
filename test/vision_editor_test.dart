import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:heroclix_simulator_trainer/app.dart';
import 'package:heroclix_simulator_trainer/application/board/board_session.dart';
import 'package:heroclix_simulator_trainer/domain/rules/line_of_sight.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/terrain.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/editor_controller.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/editor_screen.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/sight_painter.dart';
import 'package:heroclix_simulator_trainer/presentation/vision/vision_controls.dart';

import 'editor_test.dart' show cellPosition;
import 'character_editor_test.dart' show press;
import 'vision_state_test.dart' show visionSession, chooseVision;
import 'support/vision_contract.dart';

Finder vk(String id) => find.byKey(ValueKey(id));
Future<EditorController> openRules(
  WidgetTester tester, {
  VisionSnapshot? data,
}) async {
  final controller = EditorController();
  controller.loadScenario(visionSession(data));
  chooseVision(controller);
  await tester.pumpWidget(HeroClixApp(controller: controller));
  const label = 'Abrir editor';
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
  controller.setTool(EditorTool.vision);
  await tester.pumpAndSettle();
  return controller;
}

SightPainter vp(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((p) => p.foregroundPainter)
    .whereType<SightPainter>()
    .single;
Future<void> report(WidgetTester tester) async {
  if (vk('selected-target-summary').evaluate().isNotEmpty) {
    await press(tester, 'selected-target-summary');
  } else if (vk('sight-verdict').evaluate().isNotEmpty) {
    await press(tester, 'sight-verdict');
  } else {
    await press(tester, 'board-view-options');
    await tester.tap(find.text('Dictamen de visión').last);
    await tester.pumpAndSettle();
  }
}

Future<void> closeReport(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Cerrar'));
  await tester.tap(find.text('Cerrar'));
  await tester.pumpAndSettle();
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'dictamen muestra texto, color, icono y límite de ataque; efectos especiales invalidan',
    (tester) async {
      final controller = await openRules(tester);
      await report(tester);
      expect(tester.widget<Text>(vk('vision-result')).data, 'DESPEJADA');
      expect(find.textContaining('No comprueba alcance'), findsOneWidget);
      expect(find.byIcon(visionIcon(VisionStatus.clear)), findsWidgets);
      await press(tester, 'vision-special-effects');
      expect(tester.widget<Text>(vk('vision-result')).data, 'NO EVALUADA');
      expect(controller.vision.result!.canSee, isNull);
      await press(tester, 'vision-special-effects');
      expect(controller.vision.result!.status, VisionStatus.clear);
      await closeReport(tester);
      expect(vp(tester).evaluation!.status, VisionStatus.clear);
      expect(vp(tester).evaluation!.status, controller.vision.result!.status);
    },
  );
  testWidgets(
    'modificar terreno actualiza panel, referencias y resaltado decisivo',
    (tester) async {
      final controller = await openRules(tester);
      await report(tester);
      controller.attempt(
        (s) => s.paintTerrain([vc('B1')], TerrainType.hindering),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(vk('vision-result')).data, 'OBSTACULIZADA');
      await press(tester, 'vision-log');
      await tester.ensureVisible(find.textContaining('V04 · §16.2b'));
      await tester.pumpAndSettle();
      expect(find.textContaining('V04 · §16.2b'), findsWidgets);
      await closeReport(tester);
      controller.attempt(
        (s) => s.paintTerrain([vc('B1')], TerrainType.blocking),
      );
      await tester.pumpAndSettle();
      expect(vp(tester).evaluation!.status, VisionStatus.blocked);
      expect(
        vp(tester).evaluation!.decisive.any((o) => o.cells.contains(vc('B1'))),
        isTrue,
      );
      await report(tester);
      expect(tester.widget<Text>(vk('vision-result')).data, 'BLOQUEADA');
      await press(tester, 'vision-show-causes');
      await closeReport(tester);
      expect(vp(tester).showCauses, isFalse);
    },
  );
  testWidgets('borrar origen no conserva dictamen ni línea; undo restaura', (
    tester,
  ) async {
    final controller = await openRules(tester);
    controller.deleteCharacter('figure-1');
    await tester.pumpAndSettle();
    expect(vp(tester).trace, isNull);
    await report(tester);
    expect(tester.widget<Text>(vk('vision-result')).data, 'NO EVALUADA');
    expect(find.textContaining('eliminada'), findsWidgets);
    controller.undo();
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(vk('vision-result')).data, 'DESPEJADA');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'visión del Editor no mueve al mantener pulsado y permite volver a edición explícita',
    (tester) async {
      final controller = await openRules(tester);
      expect(find.byType(EditorScreen), findsOneWidget);
      final before = controller.value.characters;
      await tester.longPressAt(cellPosition(tester, controller, 'A1'));
      await tester.pumpAndSettle();
      expect(controller.value.characters, same(before));
      await press(tester, 'tool-select');
      expect(find.byType(EditorScreen), findsOneWidget);
      controller.moveCharacter('figure-2', vc('D4'));
      await tester.pumpAndSettle();
      await press(tester, 'tool-vision');
      expect(controller.vision.result!.destination!.cell, vc('D4'));
      expect(controller.vision.result!.status, VisionStatus.clear);
      await report(tester);
      expect(
        find.textContaining('no sustituye una decisión oficial'),
        findsOneWidget,
      );
    },
  );
  testWidgets('visión del Editor conserva evaluación al ajustar la cámara', (
    tester,
  ) async {
    final controller = await openRules(tester);
    final before = controller.vision.result;
    await press(tester, 'reset-camera');
    expect(controller.vision.result, same(before));
    expect(vp(tester).evaluation, same(before));
    await report(tester);
    expect(tester.widget<Text>(vk('vision-result')).data, 'DESPEJADA');
    expect(tester.takeException(), isNull);
  });
  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(800, 360), 1.0),
    (const Size(320, 320), 3.0),
  ]) {
    testWidgets('Editor e informe accesibles en $size texto $scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final controller = await openRules(
        tester,
        data: vs(terrain: {'B1': TerrainType.hindering}),
      );
      await report(tester);
      expect(tester.widget<Text>(vk('vision-result')).data, 'OBSTACULIZADA');
      await press(tester, 'vision-special-effects');
      expect(controller.vision.result!.status, VisionStatus.notEvaluated);
      await closeReport(tester);
      expect(tester.takeException(), isNull);
    });
  }
}

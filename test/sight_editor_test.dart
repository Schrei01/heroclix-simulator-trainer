import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:heroclix_simulator_trainer/application/board/board_session.dart';
import 'package:heroclix_simulator_trainer/application/board/sight_probe.dart';
import 'package:heroclix_simulator_trainer/domain/characters/character.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/sight_painter.dart';

import 'editor_test.dart' show openEditor, cellPosition;
import 'character_editor_test.dart' show press;
import 'sight_probe_test.dart' show figure, c, endpoints;

Finder key(String id) => find.byKey(ValueKey(id));
Future<void> text(WidgetTester tester, String id, String value) async {
  await tester.ensureVisible(key(id));
  await tester.enterText(key(id), value);
  await tester.pumpAndSettle();
}

SightPainter painter(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((w) => w.foregroundPainter)
    .whereType<SightPainter>()
    .single;
void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'toques eligen extremos, inspector muestra vértices y controles no cambian mundo',
    (tester) async {
      final controller = await openEditor(tester);
      await press(tester, 'tool-vision');
      await tester.tapAt(cellPosition(tester, controller, 'A1'));
      await tester.pumpAndSettle();
      await tester.tapAt(cellPosition(tester, controller, 'D4'));
      await tester.pumpAndSettle();
      expect(controller.sight.trace!.segments.map((s) => s.cell.label), [
        'A1',
        'B2',
        'C3',
        'D4',
      ]);
      final world = controller.value.characters;
      await press(tester, 'sight-inspect');
      expect(find.text('Inspección geométrica'), findsOneWidget);
      expect(find.textContaining('Vértice · t=1/6'), findsOneWidget);
      expect(find.textContaining('Solo esquina: A2, B1'), findsOneWidget);
      await press(tester, 'sight-show-line');
      await press(tester, 'sight-show-cells');
      await press(tester, 'sight-show-contacts');
      await tester.ensureVisible(find.text('Cerrar'));
      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();
      expect(painter(tester).line, isFalse);
      expect(painter(tester).cells, isFalse);
      expect(painter(tester).contacts, isFalse);
      expect(controller.value.characters, same(world));
      expect(controller.history.canUndo, isFalse);
      await press(tester, 'sight-swap');
      expect(controller.sight.trace!.path.origin, c('D4'));
      await press(tester, 'sight-clear');
      expect(controller.sight.trace, isNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'coordenadas inválidas no sustituyen trayectoria y casilla idéntica es explícita',
    (tester) async {
      final controller = await openEditor(tester);
      endpoints(controller);
      await press(tester, 'tool-vision');
      await press(tester, 'sight-endpoints');
      final original = controller.sight.trace;
      await text(tester, 'sight-cell-destination', 'Z40');
      await press(tester, 'apply-sight-endpoints');
      expect(key('sight-endpoint-error'), findsOneWidget);
      expect(controller.sight.trace, same(original));
      await text(tester, 'sight-cell-destination', 'A1');
      await press(tester, 'apply-sight-endpoints');
      expect(controller.sight.trace!.isDegenerate, isTrue);
      await press(tester, 'sight-inspect');
      expect(find.textContaining('segmento de longitud cero'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('base 2×2 pide referencia explícita; cancelar no elige extremo', (
    tester,
  ) async {
    final controller = await openEditor(tester);
    controller.saveCharacter(figure('A1', footprint: Footprint.square2));
    await tester.pumpAndSettle();
    await press(tester, 'tool-vision');
    await tester.tapAt(cellPosition(tester, controller, 'B2'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('La evaluación completa de bases'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(controller.sight.origin, isNull);
    await tester.tapAt(cellPosition(tester, controller, 'B2'));
    await tester.pumpAndSettle();
    await press(tester, 'confirm-sight-reference');
    expect(controller.sight.origin!.figureId, 'figure-1');
    expect(controller.sight.origin!.resolve(controller.value), c('B2'));
    await tester.tapAt(cellPosition(tester, controller, 'D4'));
    await tester.pumpAndSettle();
    expect(controller.sight.trace!.path.origin, c('B2'));
    final before = controller.value.characters;
    // Mantener pulsado en Visión no mueve una figura ni abre su ficha.
    await tester.longPressAt(cellPosition(tester, controller, 'A1'));
    await tester.pumpAndSettle();
    expect(controller.value.characters, same(before));
    expect(tester.takeException(), isNull);
  });
  testWidgets('formulario permite figura y una de sus cuatro referencias', (
    tester,
  ) async {
    final controller = await openEditor(tester);
    controller.saveCharacter(figure('A1', footprint: Footprint.square2));
    await tester.pumpAndSettle();
    await press(tester, 'tool-vision');
    await press(tester, 'sight-endpoints');
    await press(tester, 'sight-source-origin');
    await tester.tap(find.text('A · Prueba · A1').last);
    await tester.pumpAndSettle();
    await press(tester, 'sight-ref-origin-figure-1');
    await tester.tap(find.text('B2').last);
    await tester.pumpAndSettle();
    await text(tester, 'sight-cell-destination', 'D4');
    await press(tester, 'apply-sight-endpoints');
    expect(controller.sight.trace!.path.origin, c('B2'));
    expect(controller.sight.origin!.columnOffset, 1);
    expect(controller.sight.origin!.rowOffset, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'zoom y giro conservan resultado; mover/borrar figura actualiza la superposición',
    (tester) async {
      final controller = await openEditor(tester);
      controller.saveCharacter(figure('A1'));
      controller.setSightEndpoint(
        const ProbeEndpoint.figure('figure-1'),
        asOrigin: true,
      );
      controller.setSightEndpoint(ProbeEndpoint.cell(c('D4')), asOrigin: false);
      await press(tester, 'tool-vision');
      final before = controller.sight.trace;
      await press(tester, 'zoom-in');
      expect(controller.sight.trace, same(before));
      tester.view.physicalSize = const Size(900, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpAndSettle();
      expect(controller.sight.trace, same(before));
      expect(
        tester.getTopLeft(key('sight-status')).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(key('board-viewport')).dy),
        reason:
            'El estado debe quedar fuera del tablero para no tapar el destino.',
      );
      controller.setTool(EditorTool.select);
      controller.moveCharacter('figure-1', c('B1'));
      await tester.pumpAndSettle();
      expect(painter(tester).trace!.path.origin, c('B1'));
      controller.deleteCharacter('figure-1');
      await tester.pumpAndSettle();
      expect(painter(tester).trace, isNull);
      controller.setTool(EditorTool.vision);
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(key('sight-status')).data,
        contains('eliminada'),
      );
      controller.undo();
      await tester.pumpAndSettle();
      expect(painter(tester).trace, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );
  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(800, 360), 1.0),
    (const Size(320, 320), 3.0),
  ]) {
    testWidgets('extremos e inspector accesibles en $size texto $scale', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = await openEditor(tester);
      // Cambiar solo escala del sistema de texto sin duplicar la aplicación.
      // El builder de la app toma la escala de la plataforma.
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      if (key('tool-vision').evaluate().isEmpty) {
        await tester.drag(key('tools-left'), const Offset(0, -160));
        await tester.pumpAndSettle();
      }
      await press(tester, 'tool-vision');
      await press(tester, 'sight-endpoints');
      await text(tester, 'sight-cell-origin', 'A1');
      await text(tester, 'sight-cell-destination', 'D4');
      await press(tester, 'apply-sight-endpoints');
      await press(tester, 'sight-inspect');
      await tester.ensureVisible(key('sight-summary'));
      await tester.pumpAndSettle();
      expect(find.textContaining('4 tramos interiores'), findsOneWidget);
      await tester.ensureVisible(find.text('Cerrar'));
      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();
      expect(controller.sight.trace!.segments.length, 4);
      expect(tester.takeException(), isNull);
    });
  }
}

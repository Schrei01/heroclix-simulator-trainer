import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/app.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_dimensions.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_viewport.dart';
import 'package:heroclix_simulator_trainer/domain/board/cell_coordinate.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/editor_controller.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/editor_screen.dart';
import 'package:material_ui/material_ui.dart';

Future<EditorController> openEditor(WidgetTester tester) async {
  await tester.pumpWidget(const HeroClixApp());
  await tester.ensureVisible(find.text('Abrir editor'));
  await tester.tap(find.text('Abrir editor'));
  await tester.pumpAndSettle();
  return tester.widget<EditorScreen>(find.byType(EditorScreen)).controller;
}

Offset cellPosition(
  WidgetTester tester,
  EditorController controller,
  String label,
) {
  final state = controller.value;
  final scene = const BoardGeometry().cellCenter(
    CellCoordinate.parse(label),
    state.dimensions,
  );
  final point = state.camera.sceneToViewport(scene);
  return tester.getTopLeft(find.byKey(const ValueKey('board-viewport'))) +
      Offset(point.x, point.y);
}

Future<void> configureSize(
  WidgetTester tester,
  String rows,
  String columns,
) async {
  await tester.tap(find.byKey(const ValueKey('board-size-button')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('board-rows')), rows);
  await tester.enterText(find.byKey(const ValueKey('board-columns')), columns);
  await tester.tap(find.byKey(const ValueKey('apply-board-size')));
  await tester.pumpAndSettle();
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets('el teclado del diálogo no cambia cámara ni selección', (
    tester,
  ) async {
    tester.view.viewPadding = const FakeViewPadding(bottom: 24);
    tester.view.padding = const FakeViewPadding(bottom: 24);
    addTearDown(tester.view.resetViewPadding);
    addTearDown(tester.view.resetPadding);
    final controller = await openEditor(tester);
    await tester.tapAt(cellPosition(tester, controller, 'B2'));
    await tester.pump();
    final original = controller.value;
    await tester.tap(find.byKey(const ValueKey('board-size-button')));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    tester.view.padding = const FakeViewPadding();
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(controller.value.camera, original.camera);
    expect(controller.value.viewport, original.viewport);
    expect(controller.value.selectedCell, original.selectedCell);
    tester.view.resetViewInsets();
    tester.view.padding = const FakeViewPadding(bottom: 24);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(controller.value, same(original));
  });
  testWidgets('tablero inicial, selección, deselección y borde compartido', (
    tester,
  ) async {
    final controller = await openEditor(tester);
    expect(controller.value.dimensions.cellCount, 16);
    expect(find.text('Editor · 4 × 4'), findsOneWidget);
    expect(find.text('Cuadrícula vacía · toca una casilla'), findsOneWidget);
    await tester.tapAt(cellPosition(tester, controller, 'A1'));
    await tester.pump();
    expect(controller.value.selectedCell, CellCoordinate.parse('A1'));
    expect(find.text('Seleccionada: A1'), findsOneWidget);
    await tester.tapAt(cellPosition(tester, controller, 'A1'));
    await tester.pump();
    expect(controller.value.selectedCell, isNull);

    final point = controller.value.camera.sceneToViewport(
      const BoardPoint(96, 96),
    );
    await tester.tapAt(
      tester.getTopLeft(find.byKey(const ValueKey('board-viewport'))) +
          Offset(point.x, point.y),
    );
    await tester.pump();
    expect(controller.value.selectedCell, CellCoordinate.parse('B2'));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'entradas vacías, no enteras y fuera de límites no alteran el tablero',
    (tester) async {
      final controller = await openEditor(tester);
      await tester.tapAt(cellPosition(tester, controller, 'C2'));
      await tester.pump();
      final original = controller.value;
      await configureSize(tester, '', '12');
      expect(find.text('Introduce un valor.'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('board-rows')), 'abc');
      await tester.tap(find.byKey(const ValueKey('apply-board-size')));
      await tester.pump();
      expect(find.text('Introduce un número entero.'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('board-rows')), '1');
      await tester.enterText(find.byKey(const ValueKey('board-columns')), '41');
      await tester.tap(find.byKey(const ValueKey('apply-board-size')));
      await tester.pump();
      expect(find.text('El valor debe estar entre 2 y 40.'), findsNWidgets(2));
      expect(controller.value, same(original));
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(controller.value.selectedCell, CellCoordinate.parse('C2'));
    },
  );

  testWidgets(
    'cambio rectangular confirma antes de descartar selección; cancelar conserva todo',
    (tester) async {
      final controller = await openEditor(tester);
      await tester.tapAt(cellPosition(tester, controller, 'D4'));
      await tester.pump();
      await configureSize(tester, '8', '12');
      expect(find.text('¿Cambiar el tamaño?'), findsOneWidget);
      expect(controller.value.dimensions, BoardDimensions.initial);
      await tester.tap(find.byKey(const ValueKey('cancel-resize')));
      await tester.pumpAndSettle();
      expect(controller.value.selectedCell, CellCoordinate.parse('D4'));
      await tester.tap(find.byKey(const ValueKey('apply-board-size')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-resize')));
      await tester.pumpAndSettle();
      expect(controller.value.dimensions.cellCount, 96);
      expect(controller.value.dimensions.rows, 8);
      expect(controller.value.dimensions.columns, 12);
      expect(controller.value.selectedCell, isNull);
    },
  );

  testWidgets(
    'pan y pinza real no seleccionan; zoom y cámara no pierden selección',
    (tester) async {
      final controller = await openEditor(tester);
      final viewport = find.byKey(const ValueKey('board-viewport'));
      final initialCamera = controller.value.camera;
      await tester.dragFrom(tester.getCenter(viewport), const Offset(100, 55));
      await tester.pumpAndSettle();
      expect(controller.value.camera, isNot(initialCamera));
      expect(controller.value.selectedCell, isNull);
      await tester.tap(find.byKey(const ValueKey('reset-camera')));
      await tester.pumpAndSettle();
      final center = tester.getCenter(viewport);
      final first = await tester.createGesture(pointer: 7);
      final second = await tester.createGesture(pointer: 8);
      await first.down(center - const Offset(40, 0));
      await second.down(center + const Offset(40, 0));
      await tester.pump();
      for (var step = 1; step <= 4; step++) {
        await first.moveTo(center - Offset(40 + step * 10, 0));
        await second.moveTo(center + Offset(40 + step * 10, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await first.up();
      await second.up();
      await tester.pumpAndSettle();
      expect(controller.value.camera.scale, greaterThan(initialCamera.scale));
      expect(controller.value.selectedCell, isNull);

      await tester.tap(find.byKey(const ValueKey('reset-camera')));
      await tester.pumpAndSettle();
      await tester.tapAt(cellPosition(tester, controller, 'B2'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('zoom-in')));
      await tester.tap(find.byKey(const ValueKey('center-board')));
      await tester.pumpAndSettle();
      expect(controller.value.selectedCell, CellCoordinate.parse('B2'));
    },
  );

  testWidgets('opciones independientes y herramientas futuras deshabilitadas', (
    tester,
  ) async {
    final controller = await openEditor(tester);
    for (final id in ['distance', 'targets']) {
      final button = tester.widget<IconButton>(
        find.byKey(ValueKey('tool-$id')),
      );
      expect(button.onPressed, isNotNull);
      expect(button.tooltip, isNot(contains('Próximamente')));
    }
    for (final id in ['movement']) {
      final button = tester.widget<IconButton>(
        find.byKey(ValueKey('tool-$id')),
      );
      expect(button.onPressed, isNull);
      expect(button.tooltip, contains('Próximamente'));
    }
    await tester.tapAt(cellPosition(tester, controller, 'A2'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('board-view-options')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('grid-option')));
    await tester.pumpAndSettle();
    expect(controller.value.showGrid, isFalse);
    expect(controller.value.showCoordinates, isTrue);
    await tester.tap(find.byKey(const ValueKey('board-view-options')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('coordinates-option')));
    await tester.pumpAndSettle();
    expect(controller.value.showCoordinates, isFalse);
    expect(controller.value.selectedCell, CellCoordinate.parse('A2'));
    await tester.tap(find.byKey(const ValueKey('board-view-options')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('clear-selection-option')));
    await tester.pumpAndSettle();
    expect(controller.value.selectedCell, isNull);
  });

  testWidgets(
    'la sesión se conserva al volver al inicio y al girar con mapa 40×40',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final controller = await openEditor(tester);
      await configureSize(tester, '40', '40');
      await tester.tapAt(cellPosition(tester, controller, 'AA1'));
      await tester.pump();
      expect(controller.value.selectedCell, CellCoordinate.parse('AA1'));
      tester.view.physicalSize = const Size(800, 400);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('tools-left')), findsOneWidget);
      expect(controller.value.selectedCell, CellCoordinate.parse('AA1'));
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Abrir editor'));
      await tester.tap(find.text('Abrir editor'));
      await tester.pumpAndSettle();
      expect(controller.value.dimensions.cellCount, 1600);
      expect(controller.value.selectedCell, CellCoordinate.parse('AA1'));
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(800, 360),
    const Size(320, 320),
    const Size(568, 320),
    const Size(1024, 768),
  ]) {
    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets(
        'editor y configuración sin desbordes en $size, texto x$scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final controller = await openEditor(tester);
          expect(controller.value.viewport!.width, greaterThan(0));
          expect(controller.value.viewport!.height, greaterThan(0));
          expect(tester.takeException(), isNull);
          await tester.tap(find.byKey(const ValueKey('board-size-button')));
          await tester.pumpAndSettle();
          expect(find.text('Tamaño del tablero'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

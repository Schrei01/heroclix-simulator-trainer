import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:heroclix_simulator_trainer/domain/board/cell_coordinate.dart';
import 'package:heroclix_simulator_trainer/domain/characters/character.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/edge_wall.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/terrain.dart';

import 'editor_test.dart' show openEditor, cellPosition;
import 'character_editor_test.dart' show press, edit, keyed;

CellCoordinate c(String text) => CellCoordinate.parse(text);
CharacterDraft data(String cell) =>
    CharacterDraft(name: 'Figura', teamId: 'team-1', position: c(cell));
EdgeWall wall(String a, String b) => EdgeWall.between(c(a), c(b));
Future<void> menu(WidgetTester tester, String key, String text) async {
  await press(tester, key);
  await tester.ensureVisible(find.text(text).last);
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'tocar y arrastrar terreno ocupado no mueve figuras; trazo rápido atómico sin huecos',
    (tester) async {
      final controller = await openEditor(tester);
      controller.saveCharacter(data('B2'));
      await tester.pump();
      await press(tester, 'tool-terrain');
      final before = controller.value, command = controller.lastEdit;
      final gesture = await tester.startGesture(
        cellPosition(tester, controller, 'A2'),
      );
      await gesture.moveTo(cellPosition(tester, controller, 'D2'));
      await tester.pump();
      expect(controller.value.terrain.isEmpty, isTrue);
      expect(controller.lastEdit, same(command));
      expect(controller.draft.value!.cells.length, 4);
      expect(keyed('layer-preview-status'), findsOneWidget);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(controller.value.terrain.cells.length, 4);
      expect(controller.value.characters, same(before.characters));
      expect(controller.value.characters.all.single.position, c('B2'));
      expect(controller.value.camera, before.camera);
      expect(
        controller.lastEdit!.reverse(controller.value).terrain,
        same(before.terrain),
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('rectángulo con previa puede cancelarse o aplicarse completo', (
    tester,
  ) async {
    final controller = await openEditor(tester);
    await press(tester, 'tool-terrain');
    await menu(tester, 'terrain-brush', 'Rellenar rectángulo');
    Future<void> drag() async {
      final gesture = await tester.startGesture(
        cellPosition(tester, controller, 'A1'),
      );
      await gesture.moveTo(cellPosition(tester, controller, 'C3'));
      await gesture.up();
      await tester.pumpAndSettle();
    }

    await drag();
    expect(controller.draft.value!.pending, isTrue);
    expect(controller.draft.value!.cells.length, 9);
    expect(controller.value.terrain.isEmpty, isTrue);
    await press(tester, 'cancel-layer-preview');
    expect(controller.draft.value, isNull);
    expect(controller.value.terrain.isEmpty, isTrue);
    await drag();
    await press(tester, 'apply-layer-preview');
    expect(controller.value.terrain.cells.length, 9);
    expect(controller.draft.value, isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'cancelar gesto o añadir segundo dedo descarta trazo; pinza navega sin pintar',
    (tester) async {
      final controller = await openEditor(tester);
      await press(tester, 'tool-terrain');
      var first = await tester.startGesture(
        cellPosition(tester, controller, 'A1'),
        pointer: 1,
      );
      await first.moveTo(cellPosition(tester, controller, 'C1'));
      await tester.pump();
      await first.cancel();
      await tester.pumpAndSettle();
      expect(controller.value.terrain.isEmpty, isTrue);
      first = await tester.startGesture(
        cellPosition(tester, controller, 'B2'),
        pointer: 2,
      );
      final second = await tester.startGesture(
        cellPosition(tester, controller, 'C3'),
        pointer: 3,
      );
      await tester.pump();
      expect(controller.draft.value, isNull);
      await first.moveBy(const Offset(-30, -20));
      await second.moveBy(const Offset(30, 20));
      await tester.pump();
      await first.up();
      await second.up();
      await tester.pumpAndSettle();
      expect(controller.value.terrain.isEmpty, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('bloqueado sobre figura se rechaza sin opción de estudio', (
    tester,
  ) async {
    final controller = await openEditor(tester);
    controller.saveCharacter(data('B2'));
    await tester.pump();
    final characters = controller.value.characters;
    await press(tester, 'tool-terrain');
    await press(tester, 'terrain-blocking');
    await tester.tapAt(cellPosition(tester, controller, 'B2'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No se puede pintar bloqueado'), findsOneWidget);
    expect(find.byKey(const ValueKey('confirm-study-terrain')), findsNothing);
    expect(controller.value.terrain.isEmpty, isTrue);
    expect(controller.value.characters, same(characters));
    await tester.tapAt(cellPosition(tester, controller, 'B2'));
    await tester.pumpAndSettle();
    expect(controller.value.terrain.isEmpty, isTrue);
    expect(controller.value.studyConflicts, isEmpty);
    expect(controller.value.characters, same(characters));
    await press(tester, 'terrain-clear');
    await tester.tapAt(cellPosition(tester, controller, 'B2'));
    await tester.pumpAndSettle();
    expect(controller.value.studyConflicts, isEmpty);
    expect(controller.value.characters, same(characters));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'muros sobre bordes compartidos, trazo continuo y borrado solo de muro',
    (tester) async {
      final controller = await openEditor(tester);
      controller.saveCharacter(data('A1'));
      controller.attempt(
        (s) => s.paintTerrain([c('A1')], TerrainType.hindering),
      );
      await tester.pump();
      await press(tester, 'tool-walls');
      final before = controller.value;
      Offset edge(String a, String b) => Offset.lerp(
        cellPosition(tester, controller, a),
        cellPosition(tester, controller, b),
        .5,
      )!;
      final gesture = await tester.startGesture(edge('A1', 'B1'));
      await gesture.moveTo(edge('A4', 'B4'));
      await tester.pump();
      expect(controller.value.walls.isEmpty, isTrue);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(controller.value.walls.edges.length, 4);
      expect(controller.value.walls.contains(wall('B1', 'A1')), isTrue);
      await tester.tapAt(edge('A1', 'B1'));
      await tester.pumpAndSettle();
      expect(controller.value.walls.edges.length, 4);
      await menu(tester, 'wall-action', 'Borrar muro');
      await tester.tapAt(edge('A1', 'B1'));
      await tester.pumpAndSettle();
      expect(controller.value.walls.edges.length, 3);
      expect(controller.value.characters, same(before.characters));
      expect(controller.value.terrain, same(before.terrain));
      controller.attempt((s) => s.clearWalls());
      await tester.pump();
      await menu(tester, 'wall-action', 'Añadir muro');
      final horizontal = await tester.startGesture(edge('A1', 'A2'));
      await horizontal.moveTo(edge('D1', 'D2'));
      await horizontal.up();
      await tester.pumpAndSettle();
      expect(controller.value.walls.edges.length, 4);
      expect(
        controller.value.walls.edges.values.every(
          (edge) => edge.axis == EdgeAxis.horizontal,
        ),
        isTrue,
      );
      await press(tester, 'tool-erase');
      await menu(tester, 'erase-layer', 'Borrar muro');
      await tester.tapAt(edge('A1', 'A2'));
      await tester.pumpAndSettle();
      expect(controller.value.walls.edges.length, 3);
      expect(controller.value.terrain, same(before.terrain));
      expect(controller.value.characters, same(before.characters));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('borde externo no se edita y explica la restricción', (
    tester,
  ) async {
    final controller = await openEditor(tester);
    await press(tester, 'tool-walls');
    final a = cellPosition(tester, controller, 'A1'),
        b = cellPosition(tester, controller, 'B1');
    await tester.tapAt(Offset(a.dx - (b.dx - a.dx) / 2, a.dy));
    await tester.pumpAndSettle();
    expect(controller.value.walls.isEmpty, isTrue);
    expect(find.textContaining('bordes externos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Borrar figura conserva terreno y muro; pintar despejado es una operación distinta',
    (tester) async {
      final controller = await openEditor(tester);
      controller.saveCharacter(data('A1'));
      controller.attempt(
        (s) => s.paintTerrain([c('A1')], TerrainType.hindering).editWalls([
          wall('A1', 'B1'),
        ], erase: false),
      );
      await tester.pump();
      final before = controller.value;
      await press(tester, 'tool-erase');
      await menu(tester, 'erase-layer', 'Borrar figura');
      await tester.tapAt(cellPosition(tester, controller, 'A1'));
      await tester.pumpAndSettle();
      await press(tester, 'confirm-erase-figure');
      expect(controller.value.characters.isEmpty, isTrue);
      expect(controller.value.terrain, same(before.terrain));
      expect(controller.value.walls, same(before.walls));
      expect(tester.takeException(), isNull);
    },
  );
  for (final layer in ['terrain', 'walls', 'figures']) {
    testWidgets(
      'limpiar solo $layer pide confirmar y conserva otras capas con zoom',
      (tester) async {
        final controller = await openEditor(tester);
        controller.saveCharacter(data('A1'));
        controller.attempt(
          (s) => s.paintTerrain([c('A1')], TerrainType.hindering).editWalls([
            wall('A1', 'B1'),
          ], erase: false),
        );
        await tester.pump();
        await press(tester, 'zoom-in');
        final before = controller.value;
        Future<void> open() async {
          await press(tester, 'board-view-options');
          await press(tester, 'clear-$layer-option');
        }

        await open();
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(controller.value, same(before));
        await open();
        await press(tester, 'confirm-clear-layer');
        final after = controller.value;
        expect(after.camera, before.camera);
        if (layer == 'terrain') {
          expect(after.terrain.isEmpty, isTrue);
        } else {
          expect(after.terrain, same(before.terrain));
        }
        if (layer == 'walls') {
          expect(after.walls.isEmpty, isTrue);
        } else {
          expect(after.walls, same(before.walls));
        }
        if (layer == 'figures') {
          expect(after.characters.isEmpty, isTrue);
        } else {
          expect(after.characters, same(before.characters));
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'coordenadas: rectángulo previsualizado y muro entre vecinos validado',
    (tester) async {
      final controller = await openEditor(tester);
      await press(tester, 'tool-terrain');
      await press(tester, 'edit-coordinates');
      await edit(tester, 'layer-start', 'A1');
      await edit(tester, 'layer-end', 'C2');
      await press(tester, 'preview-coordinates');
      expect(controller.value.terrain.isEmpty, isTrue);
      expect(controller.draft.value!.cells.length, 6);
      await press(tester, 'apply-layer-preview');
      expect(controller.value.terrain.cells.length, 6);
      await press(tester, 'tool-walls');
      await press(tester, 'edit-coordinates');
      await edit(tester, 'layer-start', 'A1');
      await edit(tester, 'layer-end', 'C3');
      await press(tester, 'preview-coordinates');
      expect(find.textContaining('vecinas ortogonales'), findsOneWidget);
      expect(controller.value.walls.isEmpty, isTrue);
      await edit(tester, 'layer-end', 'B1');
      await press(tester, 'preview-coordinates');
      expect(controller.value.walls.contains(wall('A1', 'B1')), isTrue);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('crear figura sobre bloqueado se rechaza sin opción de estudio', (
    tester,
  ) async {
    final controller = await openEditor(tester);
    controller.attempt((s) => s.paintTerrain([c('A1')], TerrainType.blocking));
    await tester.pump();
    await press(tester, 'tool-characters');
    await tester.tapAt(cellPosition(tester, controller, 'A1'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('La base toca terreno bloqueado'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('confirm-study-character')), findsNothing);
    expect(controller.value.characters.isEmpty, isTrue);
    await tester.tapAt(cellPosition(tester, controller, 'A1'));
    await tester.pumpAndSettle();
    expect(controller.value.characters.isEmpty, isTrue);
    expect(controller.value.studyConflicts, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'capas conservadas tras giro y volver al inicio; previa se cancela',
    (tester) async {
      final controller = await openEditor(tester);
      controller.saveCharacter(data('A1'));
      controller.attempt(
        (s) => s.paintTerrain([c('B2')], TerrainType.hindering).editWalls([
          wall('A1', 'B1'),
        ], erase: false),
      );
      await tester.pump();
      final before = controller.value;
      await press(tester, 'tool-terrain');
      await menu(tester, 'terrain-brush', 'Rellenar rectángulo');
      final gesture = await tester.startGesture(
        cellPosition(tester, controller, 'C3'),
      );
      await gesture.up();
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(1200, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpAndSettle();
      expect(controller.draft.value, isNull);
      expect(controller.value.terrain, same(before.terrain));
      expect(controller.value.walls, same(before.walls));
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Abrir editor'));
      await tester.tap(find.text('Abrir editor'));
      await tester.pumpAndSettle();
      expect(controller.value.terrain, same(before.terrain));
      expect(controller.value.walls, same(before.walls));
      expect(controller.value.characters, same(before.characters));
    },
  );
  testWidgets(
    'girar con confirmación compacta cierra previa sin editar el mapa',
    (tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = await openEditor(tester);
      await press(tester, 'tool-terrain');
      await press(tester, 'edit-coordinates');
      await edit(tester, 'layer-start', 'A1');
      await press(tester, 'preview-coordinates');
      expect(keyed('apply-layer-preview'), findsOneWidget);
      tester.view.physicalSize = const Size(600, 900);
      await tester.pumpAndSettle();
      expect(controller.draft.value, isNull);
      expect(keyed('apply-layer-preview'), findsNothing);
      expect(controller.value.terrain.isEmpty, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(800, 360),
    const Size(320, 320),
  ]) {
    testWidgets(
      'herramientas y coordenadas sin desbordes en $size texto 300 %',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await openEditor(tester);
        await press(tester, 'tool-terrain');
        await press(tester, 'edit-coordinates');
        await edit(tester, 'layer-start', 'A1');
        await press(tester, 'preview-coordinates');
        await press(tester, 'cancel-layer-preview');
        expect(tester.takeException(), isNull);
      },
    );
  }
}

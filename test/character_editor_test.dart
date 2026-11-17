import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/domain/board/cell_coordinate.dart';
import 'package:heroclix_simulator_trainer/domain/characters/character.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/editor_controller.dart';
import 'package:material_ui/material_ui.dart';

import 'editor_test.dart' show cellPosition;
import 'editor_test.dart' as editor;

import 'package:heroclix_simulator_trainer/domain/board/board_dimensions.dart';

import 'editor_test.dart' show configureSize;

Future<EditorController> openEditor(WidgetTester tester) async {
  final c = await editor.openEditor(tester);
  c.changeDimensions(BoardDimensions(rows: 4, columns: 4));
  await tester.pumpAndSettle();
  return c;
}

Finder keyed(String key) => find.byKey(ValueKey(key));
CharacterDraft data(String cell, {Footprint footprint = Footprint.single}) =>
    CharacterDraft(
      name: 'Figura',
      teamId: 'team-1',
      position: CellCoordinate.parse(cell),
      footprint: footprint,
    );
Future<void> press(WidgetTester tester, String key) async {
  await tester.ensureVisible(keyed(key));
  await tester.pumpAndSettle();
  await tester.tap(keyed(key));
  await tester.pumpAndSettle();
}

Future<void> edit(WidgetTester tester, String key, String text) async {
  await tester.ensureVisible(keyed(key));
  await tester.enterText(keyed(key), text);
  await tester.pump();
}

Future<void> openFigure(WidgetTester tester) => press(tester, 'edit-character');
Future<void> startFigure(
  WidgetTester tester,
  EditorController controller,
  String cell,
) async {
  await press(tester, 'tool-characters');
  await tester.tapAt(cellPosition(tester, controller, cell));
  await tester.pumpAndSettle();
  await openFigure(tester);
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'cambiar de T1 a T2 conserva identidad y reducción rechazada conserva figuras',
    (tester) async {
      final controller = await openEditor(tester);
      controller.saveCharacter(data('D4'));
      await tester.pump();
      final id = controller.value.selectedCharacterId;
      await openFigure(tester);
      await press(tester, 'character-team-team-1');
      await tester.tap(find.text('T2 · Rojo · Rayas').last);
      await tester.pumpAndSettle();
      await press(tester, 'save-character');
      expect(controller.value.selectedCharacterId, id);
      expect(controller.value.selectedCharacter!.teamId, 'team-2');
      final before = controller.value;
      await configureSize(tester, '2', '2');
      await press(tester, 'confirm-resize');
      expect(controller.value, same(before));
      expect(find.textContaining('quedaría fuera del tablero'), findsOneWidget);
    },
  );
  testWidgets(
    'destino de arrastre fuera del tablero muestra rechazo sin mover',
    (tester) async {
      final controller = await openEditor(tester);
      controller.saveCharacter(data('A1'));
      await tester.pump();
      final repo = controller.value.characters;
      final gesture = await tester.startGesture(
        cellPosition(tester, controller, 'A1'),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.moveTo(
        tester.getTopLeft(keyed('board-viewport')) + const Offset(3, 3),
      );
      await tester.pump();
      expect(find.textContaining('fuera del tablero'), findsOneWidget);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(controller.value.characters, same(repo));
    },
  );
  for (final size in [
    const Size(320, 568),
    const Size(800, 360),
    const Size(320, 320),
  ]) {
    for (final scale in [1.0, 3.0]) {
      testWidgets('ficha y equipos accesibles en $size texto x$scale', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final controller = await openEditor(tester);
        controller.saveCharacter(data('A1'));
        await tester.pump();
        await openFigure(tester);
        await edit(tester, 'character-name', 'Accesible');
        await press(tester, 'new-team');
        await edit(tester, 'team-name', 'Otro');
        await press(tester, 'save-team');
        await press(tester, 'save-character');
        expect(controller.value.selectedCharacter!.name, 'Accesible');
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
    'crear desde casilla, editar datos, seleccionar figura o casilla',
    (tester) async {
      final controller = await openEditor(tester);
      await startFigure(tester, controller, 'A1');
      await edit(tester, 'character-name', 'Exploradora');
      await edit(tester, 'character-speed', '8');
      await edit(tester, 'character-range', '5');
      await press(tester, 'save-character');
      final original = controller.value.selectedCharacter!;
      expect(original.name, 'Exploradora');
      expect(original.position.label, 'A1');
      await openFigure(tester);
      await edit(tester, 'character-name', 'Guardiana');
      await edit(tester, 'character-position', 'B2');
      await press(tester, 'save-character');
      expect(controller.value.selectedCharacter!.id, original.id);
      expect(controller.value.selectedCharacter!.name, 'Guardiana');
      await press(tester, 'tool-select');
      await tester.tapAt(cellPosition(tester, controller, 'A1'));
      await tester.pump();
      expect(controller.value.selectedCharacterId, isNull);
      await tester.tapAt(cellPosition(tester, controller, 'B2'));
      await tester.pump();
      expect(controller.value.selectedCharacterId, original.id);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('errores de datos y ocupación explicados sin alterar escenario', (
    tester,
  ) async {
    final controller = await openEditor(tester);
    controller.saveCharacter(data('A1'));
    controller.saveCharacter(data('B1'));
    await tester.pump();
    final original = controller.value;
    await openFigure(tester);
    await edit(tester, 'character-name', '😀' * 80);
    await press(tester, 'save-character');
    expect(find.text('El nombre es demasiado largo.'), findsOneWidget);
    expect(controller.value, same(original));
    await edit(tester, 'character-name', 'Figura');
    await edit(tester, 'character-position', '??');
    await press(tester, 'save-character');
    expect(find.text('Usa una coordenada como A1.'), findsOneWidget);
    await edit(tester, 'character-position', 'A1');
    await press(tester, 'save-character');
    expect(find.textContaining('ocupada por la ficha A'), findsOneWidget);
    expect(controller.value, same(original));
    await edit(tester, 'character-position', 'E1');
    await press(tester, 'save-character');
    expect(find.textContaining('base completa'), findsOneWidget);
    expect(controller.value, same(original));
    await edit(tester, 'character-speed', '-1');
    await press(tester, 'save-character');
    expect(find.text('Entero de 0 a 99.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'duplicar, cambiar equipo, crear otro equipo y borrar con confirmación',
    (tester) async {
      final controller = await openEditor(tester);
      controller.saveCharacter(data('A1'));
      await tester.pump();
      final original = controller.value.selectedCharacter!;
      await openFigure(tester);
      await press(tester, 'duplicate-character');
      await press(tester, 'new-team');
      await edit(tester, 'team-name', 'Aliados');
      await press(tester, 'save-team');
      await press(tester, 'save-character');
      final copy = controller.value.selectedCharacter!;
      expect(copy.id, isNot(original.id));
      expect(copy.label, 'B');
      expect(copy.teamId, 'team-3');
      expect(controller.value.teams.last.code, 'T3');
      await openFigure(tester);
      await press(tester, 'delete-character');
      expect(find.textContaining('recuperarla con Deshacer'), findsOneWidget);
      await press(tester, 'confirm-delete-character');
      expect(controller.value.characters.length, 1);
      expect(controller.value.characters.byId(original.id), same(original));
      await press(tester, 'character-roster');
      await press(tester, 'roster-${original.id}');
      expect(find.text('Ficha A'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('base 2×2 advierte representación y rechaza borde', (
    tester,
  ) async {
    final controller = await openEditor(tester);
    await startFigure(tester, controller, 'D4');
    await press(tester, 'character-footprint');
    await tester.tap(find.text('2 × 2').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('El anclaje indica'), findsOneWidget);
    await press(tester, 'save-character');
    expect(controller.value.characters.length, 1);
    expect(controller.value.selectedCharacter!.footprint, Footprint.single);
    expect(find.textContaining('base completa'), findsOneWidget);
    await edit(tester, 'character-position', 'C3');
    await press(tester, 'save-character');
    expect(controller.value.selectedCharacter!.occupiedCells.length, 4);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'arrastrar muestra preview, confirma atómicamente y rechaza solapar',
    (tester) async {
      final controller = await openEditor(tester);
      controller.saveCharacter(data('A1'));
      controller.saveCharacter(data('C1'));
      await tester.pump();
      final a = controller.value.characters.all.first;
      final gesture = await tester.startGesture(
        cellPosition(tester, controller, 'A1'),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.moveTo(cellPosition(tester, controller, 'B2'));
      await tester.pump();
      expect(find.text('✓ Destino válido: B2'), findsOneWidget);
      expect(controller.value.characters.byId(a.id)!.position.label, 'A1');
      await gesture.up();
      await tester.pumpAndSettle();
      expect(controller.value.characters.byId(a.id)!.position.label, 'B2');
      final second = await tester.startGesture(
        cellPosition(tester, controller, 'B2'),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await second.moveTo(cellPosition(tester, controller, 'C1'));
      await tester.pump();
      expect(find.textContaining('ocupada por la ficha B'), findsOneWidget);
      await second.up();
      await tester.pumpAndSettle();
      expect(controller.value.characters.byId(a.id)!.position.label, 'B2');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('cancelar arrastre y añadir segundo dedo conserva ocupación', (
    tester,
  ) async {
    final controller = await openEditor(tester);
    controller.saveCharacter(data('A1'));
    await tester.pump();
    final repository = controller.value.characters;
    var gesture = await tester.startGesture(
      cellPosition(tester, controller, 'A1'),
      pointer: 1,
    );
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(cellPosition(tester, controller, 'B2'));
    await tester.pump();
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(controller.value.characters, same(repository));
    gesture = await tester.startGesture(
      cellPosition(tester, controller, 'A1'),
      pointer: 2,
    );
    await tester.pump(const Duration(milliseconds: 600));
    final finger = await tester.startGesture(
      cellPosition(tester, controller, 'C3'),
      pointer: 3,
    );
    await tester.pump();
    expect(keyed('drag-status'), findsNothing);
    await gesture.up();
    await finger.up();
    await tester.pumpAndSettle();
    expect(controller.value.characters, same(repository));
    expect(tester.takeException(), isNull);
  });
  testWidgets('arrastre desde celda secundaria conserva anclaje 2×2', (
    tester,
  ) async {
    final controller = await openEditor(tester);
    controller.saveCharacter(data('A1', footprint: Footprint.square2));
    await tester.pump();
    final gesture = await tester.startGesture(
      cellPosition(tester, controller, 'B2'),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(cellPosition(tester, controller, 'C3'));
    await tester.pump();
    expect(find.text('✓ Destino válido: B2'), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.value.selectedCharacter!.position.label, 'B2');
  });
  testWidgets('figuras conservadas tras zoom, pan, giro y navegación', (
    tester,
  ) async {
    final controller = await openEditor(tester);
    controller.saveCharacter(data('B2'));
    await tester.pump();
    final repository = controller.value.characters;
    await press(tester, 'zoom-in');
    await tester.drag(keyed('board-viewport'), const Offset(35, 25));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(1200, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpAndSettle();
    expect(controller.value.characters, same(repository));
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Abrir editor'));
    await tester.tap(find.text('Abrir editor'));
    await tester.pumpAndSettle();
    expect(controller.value.characters, same(repository));
    expect(controller.value.characters.all.single.position.label, 'B2');
    expect(tester.takeException(), isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:heroclix_simulator_trainer/application/board/board_session.dart';
import 'package:heroclix_simulator_trainer/domain/board/cell_coordinate.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/terrain.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/edge_wall.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/editor_controller.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/sight_painter.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/character_dialog.dart';

import 'editor_test.dart' show openEditor, cellPosition;
import 'character_editor_test.dart' show press, data, edit, openFigure;

CellCoordinate ic(String text) => CellCoordinate.parse(text);
EdgeWall ie(String a, String b) => EdgeWall.between(ic(a), ic(b));
Future<void> tapCell(WidgetTester t, EditorController c, String at) async {
  await t.tapAt(cellPosition(t, c, at));
  await t.pumpAndSettle();
}

Future<void> eraseLayer(WidgetTester t, String name) async {
  await press(t, 'erase-layer');
  await t.tap(find.text(name).last);
  await t.pumpAndSettle();
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'terreno integra seis pinceles; E2/E3 por toque y despejado conserva altura',
    (t) async {
      final c = await openEditor(t);
      expect(c.value.dimensions.rows, 10);
      expect(c.value.dimensions.columns, 10);
      expect(find.byKey(const ValueKey('tool-elevation')), findsNothing);
      await press(t, 'tool-terrain');
      final viewport = t.getRect(find.byKey(const ValueKey('board-viewport')));
      expect(viewport.contains(cellPosition(t, c, 'A1')), isTrue);
      expect(viewport.contains(cellPosition(t, c, 'J10')), isTrue);
      for (final brush in TerrainBrush.values) {
        expect(find.byKey(ValueKey('terrain-${brush.name}')), findsOneWidget);
      }
      await press(t, 'terrain-elevated');
      await tapCell(t, c, 'B2');
      expect(c.value.terrain.at(ic('B2')).level, 2);
      expect(find.byKey(const ValueKey('elevation-level')), findsNothing);
      await tapCell(t, c, 'B2');
      expect(c.value.terrain.at(ic('B2')).level, 3);
      await press(t, 'terrain-hindering');
      await tapCell(t, c, 'B2');
      expect(c.value.terrain.at(ic('B2')).type, TerrainType.hindering);
      await press(t, 'terrain-clear');
      await tapCell(t, c, 'B2');
      expect(c.value.terrain.at(ic('B2')).type, TerrainType.clear);
      expect(c.value.terrain.at(ic('B2')).level, 3);
      c.undo();
      expect(c.value.terrain.at(ic('B2')).type, TerrainType.hindering);
      c.redo();
      expect(c.value.terrain.at(ic('B2')).level, 3);
    },
  );
  testWidgets(
    'transición por dos casillas: valida, dibuja, cambia orientación y permite deshacer',
    (t) async {
      final c = await openEditor(t);
      c.attempt((s) => s.paintElevation([ic('B1'), ic('A2')], 2));
      await press(t, 'tool-terrain');
      await press(t, 'terrain-transition');
      await tapCell(t, c, 'A1');
      expect(c.transitionStart, ic('A1'));
      expect(c.value.terrain.transitions, isEmpty);
      await tapCell(t, c, 'B1');
      expect(c.transitionStart, isNull);
      expect(c.value.terrain.transitions, {ie('A1', 'B1')});
      await tapCell(t, c, 'A1');
      await tapCell(t, c, 'A2');
      expect(c.value.terrain.transitions.length, 2);
      c.undo();
      expect(c.value.terrain.transitions, {ie('A1', 'B1')});
      c.redo();
      expect(c.value.terrain.transitions.length, 2);
      await tapCell(t, c, 'C1');
      await press(t, 'terrain-elevated');
      expect(c.transitionStart, isNull);
      await tapCell(t, c, 'D1');
      expect(c.value.terrain.at(ic('D1')).level, 2);
    },
  );
  for (final (a, b, wall) in [
    ('A1', 'A1', false),
    ('A1', 'C1', false),
    ('A1', 'B2', false),
    ('C1', 'D1', false),
    ('A1', 'B1', true),
  ]) {
    testWidgets(
      'transición inválida $a/$b muro=$wall anuncia sin cambiar escenario',
      (t) async {
        final c = await openEditor(t);
        c.attempt(
          (s) => s.paintElevation([ic('B1'), ic('B2'), ic('C1'), ic('D1')], 2),
        );
        if (wall) c.attempt((s) => s.editWalls([ie(a, b)], erase: false));
        await press(t, 'tool-terrain');
        await press(t, 'terrain-transition');
        final before = c.history.undoCount;
        await tapCell(t, c, a);
        await tapCell(t, c, b);
        expect(c.value.terrain.transitions, isEmpty);
        expect(c.history.undoCount, before);
        expect(c.transitionStart, isNull);
        expect(find.byType(SnackBar), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'Borrar retira transición, terreno o elevación conservando las demás capas y Deshacer',
    (t) async {
      final c = await openEditor(t);
      c.attempt(
        (s) => s
            .paintElevation([ic('B1')], 2)
            .paintTerrain([ic('B1')], TerrainType.hindering)
            .setTransition(ie('A1', 'B1'), remove: false),
      );
      await press(t, 'tool-erase');
      await eraseLayer(t, 'Borrar transición');
      await t.tapAt(
        Offset.lerp(cellPosition(t, c, 'A1'), cellPosition(t, c, 'B1'), .5)!,
      );
      await t.pumpAndSettle();
      expect(c.value.terrain.transitions, isEmpty);
      expect(c.value.terrain.at(ic('B1')).level, 2);
      c.undo();
      await t.pumpAndSettle();
      expect(c.value.terrain.transitions, {ie('A1', 'B1')});
      await eraseLayer(t, 'Borrar terreno');
      await tapCell(t, c, 'B1');
      expect(c.value.terrain.at(ic('B1')).level, 2);
      expect(c.value.terrain.at(ic('B1')).type, TerrainType.clear);
      expect(c.value.terrain.transitions, {ie('A1', 'B1')});
      c.undo();
      await t.pumpAndSettle();
      await eraseLayer(t, 'Borrar elevación');
      await tapCell(t, c, 'B1');
      expect(c.value.terrain.at(ic('B1')).level, 1);
      expect(c.value.terrain.at(ic('B1')).type, TerrainType.hindering);
      expect(c.value.terrain.transitions, isEmpty);
      c.undo();
      expect(c.value.terrain.at(ic('B1')).level, 2);
      expect(c.value.terrain.transitions, {ie('A1', 'B1')});
    },
  );
  testWidgets(
    'Selección: segundo toque pregunta; cancelar conserva y borrar sigue personaje, terreno, altura',
    (t) async {
      final c = await openEditor(t);
      c.attempt(
        (s) => s.paintElevation([ic('B2')], 2).paintTerrain([
          ic('B2'),
        ], TerrainType.hindering),
      );
      c.saveCharacter(data('B2'));
      await t.pumpAndSettle();
      await tapCell(t, c, 'B2');
      expect(find.byKey(const ValueKey('confirm-delete-cell')), findsNothing);
      await tapCell(t, c, 'B2');
      expect(find.text('¿Borrar el personaje A?'), findsOneWidget);
      await t.tap(find.text('Cancelar'));
      await t.pumpAndSettle();
      expect(c.value.characters.length, 1);
      await tapCell(t, c, 'B2');
      await press(t, 'confirm-delete-cell');
      expect(c.value.characters.isEmpty, isTrue);
      expect(c.value.terrain.at(ic('B2')).type, TerrainType.hindering);
      await tapCell(t, c, 'B2');
      await tapCell(t, c, 'B2');
      expect(find.text('¿Borrar el terreno obstaculizado?'), findsOneWidget);
      await press(t, 'confirm-delete-cell');
      expect(c.value.terrain.at(ic('B2')).type, TerrainType.clear);
      expect(c.value.terrain.at(ic('B2')).level, 2);
      await tapCell(t, c, 'B2');
      expect(find.text('¿Borrar la elevación E2?'), findsOneWidget);
      await press(t, 'confirm-delete-cell');
      expect(c.value.terrain.at(ic('B2')).level, 1);
      c.undo();
      c.undo();
      c.undo();
      expect(c.value.characters.length, 1);
      expect(c.value.terrain.at(ic('B2')).type, TerrainType.hindering);
      expect(c.value.terrain.at(ic('B2')).level, 2);
    },
  );
  testWidgets(
    'ficha sin permitir bloqueado ni Otra excepción; Targeting desplegable conserva mejoras',
    (t) async {
      final c = await openEditor(t);
      c.saveCharacter(data('A1'));
      c.attempt((s) => s.paintTerrain([ic('B1')], TerrainType.blocking));
      await t.pumpAndSettle();
      await openFigure(t);
      expect(find.byKey(const ValueKey('allow-study-position')), findsNothing);
      expect(find.byKey(const ValueKey('ability-blocking')), findsNothing);
      await press(t, 'targeting-abilities');
      await press(t, 'ability-blocking');
      expect(find.byKey(const ValueKey('ability-other')), findsNothing);
      await press(t, 'movement-abilities');
      expect(
        find.byKey(const ValueKey('movement-ability-other')),
        findsNothing,
      );
      await edit(t, 'character-position', 'B1');
      await press(t, 'save-character');
      expect(find.byType(CharacterDialog), findsOneWidget);
      expect(c.value.characters.all.single.position, ic('A1'));
      await edit(t, 'character-position', 'A1');
      await press(t, 'save-character');
      expect(c.value.characters.all.single.abilities.single.name, 'blocking');
    },
  );
  testWidgets(
    'Visión: mismo origen/destino limpia todas las marcas; el dictamen queda solo arriba',
    (t) async {
      final c = await openEditor(t);
      c.saveCharacter(data('A1'));
      c.saveCharacter(data('D1'));
      await press(t, 'tool-vision');
      await tapCell(t, c, 'A1');
      await tapCell(t, c, 'D1');
      expect(find.byKey(const ValueKey('vision-map-verdict')), findsOneWidget);
      final footer = t
          .widget<Text>(find.byKey(const ValueKey('sight-status')))
          .data!;
      expect(footer, isNot(contains('DESPEJADA')));
      await tapCell(t, c, 'D1');
      final painter = t
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.foregroundPainter)
          .whereType<SightPainter>()
          .single;
      expect(c.sight.origin, isNull);
      expect(c.sight.destination, isNull);
      expect(c.value.selectedCell, isNull);
      expect(c.value.selectedCharacterId, isNull);
      expect(c.vision.result, isNull);
      expect(painter.trace, isNull);
      expect(find.byKey(const ValueKey('vision-map-verdict')), findsNothing);
      await tapCell(t, c, 'A1');
      await tapCell(t, c, 'D1');
      expect(c.vision.result, isNotNull);
    },
  );
  for (final (size, scale) in [
    (const Size(360, 800), 1.0),
    (const Size(800, 360), 1.0),
    (const Size(320, 320), 3.0),
  ]) {
    testWidgets(
      'seis terrenos caben y se pueden elegir en $size texto $scale',
      (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = size;
        t.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(t.view.resetDevicePixelRatio);
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final c = await openEditor(t);
        await press(t, 'tool-terrain');
        final palette = t.getRect(
          find.byKey(const ValueKey('terrain-palette')),
        );
        for (final brush in TerrainBrush.values) {
          final button = find.byKey(ValueKey('terrain-${brush.name}'));
          final rect = t.getRect(button);
          expect(rect.left, greaterThanOrEqualTo(palette.left));
          expect(rect.right, lessThanOrEqualTo(palette.right));
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.height, greaterThanOrEqualTo(48));
          await press(t, 'terrain-${brush.name}');
          expect(c.value.terrainBrush, brush);
        }
        expect(t.takeException(), isNull);
      },
    );
  }
}

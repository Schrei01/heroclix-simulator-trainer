import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:heroclix_simulator_trainer/domain/board/cell_coordinate.dart';
import 'package:heroclix_simulator_trainer/domain/characters/character.dart';
import 'package:heroclix_simulator_trainer/domain/characters/vision_ability.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/terrain.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/character_dialog.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/elevation_controls.dart';

import 'editor_test.dart' show openEditor, cellPosition;
import 'character_editor_test.dart' show press, edit, openFigure;

CellCoordinate qc(String label) => CellCoordinate.parse(label);

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'tres iconos de terreno centrados: elegir no pinta, tocar mapa sí, cambiar herramienta los oculta',
    (tester) async {
      final c = await openEditor(tester);
      await press(tester, 'tool-terrain');
      expect(find.byKey(const ValueKey('terrain-type')), findsNothing);
      final map = tester.getRect(find.byKey(const ValueKey('board-viewport'))),
          palette = tester.getRect(
            find.byKey(const ValueKey('terrain-palette')),
          );
      expect(palette.center.dx, closeTo(map.center.dx, 1));
      expect(palette.top, greaterThanOrEqualTo(map.bottom));
      final before = c.history.undoCount;
      for (final type in [
        TerrainType.blocking,
        TerrainType.hindering,
        TerrainType.clear,
      ]) {
        await press(tester, 'terrain-${type.name}');
        expect(c.value.terrainType, type);
        expect(c.history.undoCount, before);
        expect(c.value.terrain.isEmpty, isTrue);
        expect(find.byType(PopupMenuItem<TerrainType>), findsNothing);
      }
      await press(tester, 'terrain-blocking');
      await tester.tapAt(cellPosition(tester, c, 'B2'));
      await tester.pumpAndSettle();
      expect(c.value.terrain.at(qc('B2')).type, TerrainType.blocking);
      await press(tester, 'terrain-hindering');
      await tester.tapAt(cellPosition(tester, c, 'B2'));
      await tester.pumpAndSettle();
      expect(c.value.terrain.at(qc('B2')).type, TerrainType.hindering);
      await press(tester, 'terrain-clear');
      await tester.tapAt(cellPosition(tester, c, 'B2'));
      await tester.pumpAndSettle();
      expect(c.value.terrain.at(qc('B2')).type, TerrainType.clear);
      await press(tester, 'tool-select');
      expect(find.byKey(const ValueKey('terrain-palette')), findsNothing);
    },
  );
  testWidgets(
    'colocar crea inmediatamente varias figuras por defecto, selecciona y permite deshacer/editar',
    (tester) async {
      final c = await openEditor(tester);
      await press(tester, 'tool-characters');
      final history = c.history.undoCount;
      for (final cell in ['A1', 'B1', 'C1']) {
        await tester.tapAt(cellPosition(tester, c, cell));
        await tester.pumpAndSettle();
        expect(find.byType(CharacterDialog), findsNothing);
        final figure = c.value.selectedCharacter!;
        expect(figure.position, qc(cell));
        expect(figure.name, 'Figura');
        expect(figure.teamId, c.value.teams.first.id);
        expect(figure.footprint, Footprint.single);
        expect(figure.size, FigureSize.normal);
        expect(figure.speed, 6);
        expect(figure.range, 4);
        expect(figure.abilities, isEmpty);
        expect(figure.movementAbilities, isEmpty);
      }
      expect(c.value.characters.all.map((f) => f.label), ['A', 'B', 'C']);
      expect(c.history.undoCount, history + 3);
      await tester.tapAt(cellPosition(tester, c, 'A1'));
      await tester.pumpAndSettle();
      expect(c.value.characters.length, 3);
      expect(find.byType(CharacterDialog), findsNothing);
      final id = c.value.selectedCharacterId;
      await openFigure(tester);
      await edit(tester, 'character-name', 'Editada');
      await edit(tester, 'character-speed', '8');
      await press(tester, 'save-character');
      expect(c.value.selectedCharacterId, id);
      expect(c.value.selectedCharacter!.name, 'Editada');
      expect(c.value.selectedCharacter!.speed, 8);
      c.undo();
      expect(c.value.characters.byId(id!)!.name, 'Figura');
      c.undo();
      expect(c.value.characters.length, 2);
      c.redo();
      expect(c.value.characters.length, 3);
    },
  );
  testWidgets(
    'altura inicial 2 sobre suelo, respeta altura existente y permite volver a nivel 1',
    (tester) async {
      final c = await openEditor(tester);
      await tester.tapAt(cellPosition(tester, c, 'B2'));
      await tester.pumpAndSettle();
      showElevationDialog(tester.element(find.byType(Scaffold)), c);
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('elevation-level'));
      expect(tester.widget<TextField>(field).controller!.text, '2');
      await press(tester, 'elevation-apply');
      expect(c.value.terrain.at(qc('B2')).level, 2);
      showElevationDialog(tester.element(find.byType(Scaffold)), c);
      await tester.pumpAndSettle();
      await tester.enterText(field, '3');
      await press(tester, 'elevation-apply');
      showElevationDialog(tester.element(find.byType(Scaffold)), c);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text, '3');
      await tester.enterText(field, '1');
      await press(tester, 'elevation-apply');
      expect(c.value.terrain.at(qc('B2')).level, 1);
    },
  );
  for (final (size, scale) in [
    (const Size(360, 800), 1.0),
    (const Size(800, 360), 1.0),
    (const Size(320, 320), 3.0),
  ]) {
    testWidgets('paleta táctil y selección en $size texto $scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final c = await openEditor(tester);
      await press(tester, 'tool-terrain');
      for (final type in TerrainType.values) {
        final button = find.byKey(ValueKey('terrain-${type.name}'));
        expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
        expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
        await press(tester, 'terrain-${type.name}');
        expect(c.value.terrainType, type);
      }
      expect(tester.takeException(), isNull);
    });
  }
}

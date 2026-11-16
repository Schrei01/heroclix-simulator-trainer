import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:heroclix_simulator_trainer/application/board/board_session.dart';
import 'package:heroclix_simulator_trainer/application/board/sight_probe.dart';
import 'package:heroclix_simulator_trainer/domain/characters/character.dart';
import 'package:heroclix_simulator_trainer/domain/characters/vision_ability.dart';
import 'package:heroclix_simulator_trainer/domain/rules/line_of_sight.dart';
import 'package:heroclix_simulator_trainer/domain/rules/target_analysis_service.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/edge_wall.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/terrain.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/character_dialog.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/elevation_controls.dart';
import 'package:heroclix_simulator_trainer/presentation/vision/tactical_controls.dart';

import 'support/vision_contract.dart';
import 'support/target_contract.dart';
import 'vision_editor_test.dart' show openRules, report, closeReport, vp;
import 'target_editor_test.dart' show closeDialog;
import 'character_editor_test.dart' show press;

Finder ak(String key) => find.byKey(ValueKey(key));
void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'pie del editor identifica la referencia automática real, no el anclaje',
    (tester) async {
      final c = await openRules(
        tester,
        data: ranged(
          vs(
            target: 'B3',
            targetBase: Footprint.rectangle(width: 1, height: 2),
            walls: [EdgeWall.between(vc('A2'), vc('B2'))],
          ),
          2,
        ),
      );
      c.setTool(EditorTool.vision);
      await tester.pumpAndSettle();
      expect(c.vision.result!.destination!.cell, vc('B4'));
      expect(vp(tester).trace!.path.destination, vc('B4'));
      expect(tester.widget<Text>(ak('sight-status')).data, contains('A1 a B4'));
    },
  );
  testWidgets('laboratorio cambia dictamen y registro sin modificar ficha', (
    tester,
  ) async {
    final c = await openRules(
      tester,
      data: vs(terrain: {'B1': TerrainType.blocking}),
    );
    await report(tester);
    expect(c.vision.result!.status, VisionStatus.blocked);
    await press(tester, 'vision-laboratory');
    await press(tester, 'lab-blocking');
    expect(tester.widget<Text>(ak('vision-result')).data, 'DESPEJADA');
    expect(find.textContaining('HIPÓTESIS TEMPORAL'), findsOneWidget);
    expect(c.value.characters.byId('figure-1')!.abilities, isEmpty);
    expect(
      c.vision.result!.observations.any(
        (o) => o.rules.contains(VisionRule.improvedBlocking),
      ),
      true,
    );
    await press(tester, 'vision-laboratory');
    expect(c.vision.result!.status, VisionStatus.blocked);
    await closeReport(tester);
    expect(tester.takeException(), isNull);
  });
  testWidgets('ficha guarda capacidad; editar alcance la conserva', (
    tester,
  ) async {
    final c = await openRules(
      tester,
      data: vs(terrain: {'B1': TerrainType.blocking}),
    );
    showCharacterDialog(
      tester.element(find.byType(Scaffold).last),
      c,
      character: c.value.characters.byId('figure-1'),
    );
    await tester.pumpAndSettle();
    await press(tester, 'ability-blocking');
    await press(tester, 'save-character');
    expect(c.value.characters.byId('figure-1')!.abilities, {
      VisionAbility.blocking,
    });
    expect(c.vision.result!.status, VisionStatus.clear);
    c.setTool(EditorTool.targets);
    showTargetList(tester.element(find.byType(Scaffold).last), c);
    await tester.pumpAndSettle();
    await press(tester, 'target-edit-range');
    await tester.enterText(ak('range-input'), '2');
    await press(tester, 'range-save');
    expect(c.value.characters.byId('figure-1')!.abilities, {
      VisionAbility.blocking,
    });
    expect(c.tactical.visible.single.status, TargetStatus.outOfRange);
    await closeDialog(tester);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'formulario de alturas valida nivel, pinta región y añade transición',
    (tester) async {
      final c = await openRules(tester);
      showElevationDialog(tester.element(find.byType(Scaffold).last), c);
      await tester.pumpAndSettle();
      await tester.enterText(ak('elevation-level'), '0');
      await press(tester, 'elevation-apply');
      expect(ak('elevation-error'), findsOneWidget);
      await tester.enterText(ak('elevation-level'), '2');
      await tester.enterText(ak('elevation-to'), 'B2');
      await press(tester, 'elevation-apply');
      expect(c.value.terrain.at(vc('B2')).level, 2);
      showElevationDialog(tester.element(find.byType(Scaffold).last), c);
      await tester.pumpAndSettle();
      await tester.enterText(ak('elevation-from'), 'B1');
      await tester.enterText(ak('elevation-to'), 'C1');
      await press(tester, 'transition-add');
      expect(c.value.terrain.transitions.length, 1);
      c.undo();
      await tester.pumpAndSettle();
      expect(c.value.terrain.transitions, isEmpty);
      expect(c.value.terrain.at(vc('B2')).level, 2);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'árbitro explica pares; Objetivos conserva su par de alcance y visión',
    (tester) async {
      final world = ranged(
        vs(
          target: 'B3',
          targetBase: Footprint.rectangle(width: 1, height: 2),
          walls: [EdgeWall.between(vc('A2'), vc('B2'))],
        ),
        2,
      );
      final c = await openRules(tester, data: world, mode: 'referee');
      await report(tester);
      expect(c.vision.result!.status, VisionStatus.clear);
      await press(tester, 'vision-reference-pairs');
      expect(find.textContaining('B4'), findsWidgets);
      await closeReport(tester);
      c.setTool(EditorTool.targets);
      c.selectTarget('figure-2');
      await tester.pumpAndSettle();
      expect(vp(tester).evaluation!.status, VisionStatus.blocked);
      expect(vp(tester).trace!.path.destination, vc('B3'));
      await report(tester);
      expect(tester.widget<Text>(ak('target-result')).data, 'Visión bloqueada');
      await press(tester, 'target-vision-log');
      expect(tester.widget<Text>(ak('vision-result')).data, 'BLOQUEADA');
      await closeDialog(tester);
      await closeDialog(tester);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'informe de destino borrado con origen de casilla no inventa referencia',
    (tester) async {
      final c = await openRules(tester);
      c.setSightEndpoint(ProbeEndpoint.cell(vc('A1')), asOrigin: true);
      c.deleteCharacter('figure-2');
      await tester.pumpAndSettle();
      expect(c.vision.result!.destination, isNull);
      await report(tester);
      expect(tester.widget<Text>(ak('vision-result')).data, 'NO EVALUADA');
      expect(tester.takeException(), isNull);
      await closeReport(tester);
    },
  );
  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(800, 360), 1.0),
    (const Size(320, 320), 3.0),
  ]) {
    testWidgets('laboratorio y altura accesibles en $size texto $scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final c = await openRules(tester, data: vs(elevations: {'B1': 2}));
      await report(tester);
      await press(tester, 'vision-laboratory');
      await press(tester, 'lab-elevated');
      expect(c.vision.result!.status, VisionStatus.clear);
      await closeReport(tester);
      showElevationDialog(tester.element(find.byType(Scaffold).last), c);
      await tester.pumpAndSettle();
      await tester.ensureVisible(ak('elevation-level'));
      await tester.enterText(ak('elevation-level'), '3');
      await press(tester, 'elevation-apply');
      expect(c.value.terrain.at(vc('A1')).level, 3);
      expect(tester.takeException(), isNull);
    });
  }
}

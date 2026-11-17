// Ejecutar explícitamente: flutter test tool/preview_test.dart
// Capturas de render Flutter; no representan una prueba en Android real.
import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/app.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_dimensions.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_viewport.dart';
import 'package:heroclix_simulator_trainer/domain/board/cell_coordinate.dart';
import 'package:heroclix_simulator_trainer/domain/characters/character.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/editor_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:heroclix_simulator_trainer/application/board/board_session.dart';
import 'package:heroclix_simulator_trainer/application/board/layer_draft.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/terrain.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/edge_wall.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/editing_geometry.dart';

import '../test/support/scenario_fakes.dart';

import 'package:heroclix_simulator_trainer/application/board/sight_probe.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_document.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_codec.dart';

import '../test/vision_state_test.dart' show visionSession, chooseVision;
import '../test/support/vision_contract.dart' show vs;
import '../test/support/vision_contract.dart' show vf;

import 'package:heroclix_simulator_trainer/presentation/vision/tactical_controls.dart';
import 'package:heroclix_simulator_trainer/presentation/vision/vision_controls.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/elevation_controls.dart';
import 'package:heroclix_simulator_trainer/domain/characters/vision_ability.dart';

import '../test/support/advanced_vision_contract.dart' show capable;
import '../test/support/target_contract.dart' show ranged;
import '../test/support/movement_contract.dart' show mw;

import 'package:heroclix_simulator_trainer/presentation/movement/movement_controls.dart';
import 'package:heroclix_simulator_trainer/application/training/training_repository.dart';
import 'package:heroclix_simulator_trainer/application/training/training_codec.dart';
import 'package:heroclix_simulator_trainer/domain/training/exercise.dart';
import 'package:heroclix_simulator_trainer/domain/training/curated_exercises.dart';
import 'package:heroclix_simulator_trainer/presentation/training/training_controller.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/board_canvas.dart';

import '../test/support/training_fixtures.dart';
import '../test/character_editor_test.dart' show press;
import '../test/editor_test.dart' show cellPosition;

import 'package:heroclix_simulator_trainer/presentation/tactics/tactical_screen.dart';
import 'package:heroclix_simulator_trainer/presentation/tactics/position_analysis_controller.dart';
import 'package:heroclix_simulator_trainer/presentation/tactics/diagnostic_png.dart';
import 'package:heroclix_simulator_trainer/application/training/analysis_exercises.dart';

import '../test/support/tactics_contract.dart' show tacticalWorld, tacticCaps;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final sdkPath =
        Platform.environment['FLUTTER_ROOT'] ??
        '${Platform.environment['USERPROFILE']}/develop/flutter';
    final font = File(
      '$sdkPath/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
    );
    final loader = FontLoader('sans-serif')
      ..addFont(Future.value(ByteData.sublistView(await font.readAsBytes())));
    await loader.load();
    final iconFont = File(
      '$sdkPath/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
    );
    final iconLoader = FontLoader('MaterialIcons')
      ..addFont(
        Future.value(ByteData.sublistView(await iconFont.readAsBytes())),
      );
    await iconLoader.load();
  });

  for (final (name, size, dimensions) in [
    ('session_clear', const Size(400, 900), null),
    ('session_blocked', const Size(400, 900), null),
    ('session_hindered', const Size(1000, 720), null),
    ('session_unknown', const Size(400, 900), null),
    ('session_compact', const Size(320, 320), null),
    ('session_fresh', const Size(400, 900), null),
    ('quick_palette_portrait', const Size(400, 900), BoardDimensions.initial),
    ('quick_palette_landscape', const Size(1000, 700), BoardDimensions.initial),
    ('quick_palette_compact', const Size(320, 320), BoardDimensions.initial),
    ('quick_character', const Size(400, 900), null),
    ('quick_elevation', const Size(400, 900), BoardDimensions.initial),
    ('final_home', const Size(1000, 720), null),
    ('final_about', const Size(400, 900), null),
    ('final_about_compact', const Size(320, 568), null),
    ('final_guide', const Size(400, 900), null),
    ('final_examples', const Size(1000, 720), null),
    ('final_example', const Size(400, 900), null),
    ('final_licenses', const Size(400, 900), null),
    ('tactics_overview', const Size(400, 900), null),
    ('tactics_map', const Size(1000, 720), null),
    ('tactics_comparison', const Size(400, 900), null),
    ('tactics_hypothesis', const Size(1000, 720), null),
    ('tactics_uncertainty', const Size(400, 900), null),
    ('tactics_evidence', const Size(1000, 720), null),
    ('tactics_exercise', const Size(400, 900), null),
    ('tactics_export', const Size(1000, 720), null),
    ('training_bank', const Size(400, 900), null),
    ('training_question', const Size(400, 900), null),
    ('training_feedback', const Size(400, 900), null),
    ('training_route', const Size(1000, 700), null),
    ('training_progress', const Size(400, 900), null),
    ('training_personal', const Size(400, 900), null),
    ('training_manual', const Size(400, 900), null),
    ('training_unknown', const Size(400, 900), null),
    ('movement_route', const Size(400, 900), BoardDimensions.initial),
    ('movement_invalid', const Size(400, 900), BoardDimensions.initial),
    ('movement_report', const Size(400, 900), BoardDimensions.initial),
    ('movement_comparison', const Size(1000, 700), BoardDimensions.initial),
    ('movement_alternatives', const Size(400, 900), BoardDimensions.initial),
    ('movement_unknown', const Size(400, 900), BoardDimensions.initial),
    ('advanced_elevation', const Size(400, 900), BoardDimensions.initial),
    ('advanced_base', const Size(400, 900), BoardDimensions.initial),
    ('advanced_base_report', const Size(400, 900), BoardDimensions.initial),
    ('advanced_laboratory', const Size(400, 900), BoardDimensions.initial),
    ('advanced_record', const Size(1000, 700), BoardDimensions.initial),
    ('advanced_form', const Size(400, 900), BoardDimensions.initial),
    ('advanced_referee', const Size(400, 900), BoardDimensions.initial),
    (
      'tactical_distance',
      const Size(400, 900),
      BoardDimensions(rows: 8, columns: 8),
    ),
    (
      'tactical_distance_report',
      const Size(400, 900),
      BoardDimensions(rows: 8, columns: 8),
    ),
    (
      'tactical_list',
      const Size(400, 900),
      BoardDimensions(rows: 8, columns: 8),
    ),
    (
      'tactical_target',
      const Size(1000, 600),
      BoardDimensions(rows: 8, columns: 8),
    ),
    (
      'tactical_detail',
      const Size(400, 900),
      BoardDimensions(rows: 8, columns: 8),
    ),
    (
      'tactical_unknown',
      const Size(400, 900),
      BoardDimensions(rows: 8, columns: 8),
    ),
    ('inicio_vertical', const Size(400, 900), null),
    ('inicio_horizontal', const Size(1000, 700), null),
    ('vision_clear', const Size(400, 900), BoardDimensions.initial),
    ('vision_hindered', const Size(400, 900), BoardDimensions.initial),
    ('vision_blocked', const Size(400, 900), BoardDimensions.initial),
    ('vision_corner', const Size(1000, 600), BoardDimensions.initial),
    ('vision_unknown', const Size(400, 900), BoardDimensions.initial),
    ('vision_report', const Size(400, 900), BoardDimensions.initial),
    ('vision_record', const Size(400, 900), BoardDimensions.initial),
    ('vision_referee', const Size(400, 900), BoardDimensions.initial),
    (
      'vision_a1_d6',
      const Size(400, 900),
      BoardDimensions(rows: 6, columns: 4),
    ),
    ('geometria_vertical', const Size(400, 900), BoardDimensions.initial),
    ('geometria_horizontal', const Size(1000, 600), BoardDimensions.initial),
    ('geometria_inspector', const Size(400, 900), BoardDimensions.initial),
    ('geometria_eventos', const Size(400, 900), BoardDimensions.initial),
    ('geometria_base', const Size(400, 900), BoardDimensions.initial),
    (
      'geometria_40x40',
      const Size(1000, 700),
      BoardDimensions(rows: 40, columns: 40),
    ),
    (
      'biblioteca_vertical',
      const Size(400, 900),
      BoardDimensions(rows: 4, columns: 4),
    ),
    (
      'guardar_como',
      const Size(400, 900),
      BoardDimensions(rows: 4, columns: 4),
    ),
    (
      'png_opciones',
      const Size(400, 900),
      BoardDimensions(rows: 4, columns: 4),
    ),
    (
      'guardado_error',
      const Size(400, 900),
      BoardDimensions(rows: 4, columns: 4),
    ),
    (
      'terreno_vertical',
      const Size(400, 900),
      BoardDimensions(rows: 4, columns: 4),
    ),
    (
      'terreno_horizontal',
      const Size(1000, 600),
      BoardDimensions(rows: 4, columns: 4),
    ),
    ('leyenda', const Size(400, 900), BoardDimensions(rows: 4, columns: 4)),
    ('conflicto', const Size(400, 900), BoardDimensions(rows: 4, columns: 4)),
    (
      'figuras_vertical',
      const Size(400, 900),
      BoardDimensions(rows: 4, columns: 4),
    ),
    (
      'figuras_horizontal',
      const Size(1000, 600),
      BoardDimensions(rows: 4, columns: 4),
    ),
    (
      'ficha_vertical',
      const Size(400, 900),
      BoardDimensions(rows: 4, columns: 4),
    ),
    (
      'editor_vertical',
      const Size(400, 900),
      BoardDimensions(rows: 8, columns: 12),
    ),
    (
      'editor_horizontal',
      const Size(1000, 600),
      BoardDimensions(rows: 8, columns: 12),
    ),
    (
      'editor_40x40',
      const Size(1000, 700),
      BoardDimensions(rows: 40, columns: 40),
    ),
  ]) {
    testWidgets('renderiza $name', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      if (name == 'final_about_compact') {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      }
      if (name == 'quick_palette_compact') {
        tester.platformDispatcher.textScaleFactorTestValue = 3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      }
      if (name == 'session_compact') {
        tester.platformDispatcher.textScaleFactorTestValue = 3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      }
      final key = GlobalKey();
      final store = MemoryStore();
      // Cada render posee su propio almacenamiento, sin canal de plataforma.
      final persistent = await persistentController(
        store,
        persistWorkingSession: false,
      );
      if (!name.startsWith('session_')) {
        await persistent.workspace!.save(name: 'Escenario de ejemplo');
      }
      final training = TrainingController(
        TrainingRepository(MemoryStore()),
        scenarios: persistent.workspace!.repository,
      );
      await training.initialize();
      if (name == 'training_personal') {
        persistent.loadScenario(TrainingCodec.session(curatedExercises.first));
        persistent.workspace!.edited(persistent.value);
        await persistent.workspace!.save();
      }
      if (name == 'training_manual') {
        await training.add(personalFixture(manual: true));
      }
      if (name == 'training_unknown') {
        await training.repository.store.write(
          'working',
          const TrainingCodec().encode(
            TrainingData(personal: [personalFixture(version: 'futura')]),
          ),
        );
        await training.initialize(reload: true);
      }
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: HeroClixApp(
            controller: persistent,
            trainingController: training,
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (name.startsWith('session_')) {
        if (name != 'session_fresh') {
          persistent.loadScenario(
            visionSession(
              vs(
                terrain: {
                  'B1': name == 'session_blocked'
                      ? TerrainType.blocking
                      : name == 'session_hindered'
                      ? TerrainType.hindering
                      : TerrainType.clear,
                },
              ),
            ),
          );
          persistent.workspace!.edited(persistent.value);
        }
        await tester.ensureVisible(find.text('Abrir editor'));
        await tester.tap(find.text('Abrir editor'));
        await tester.pumpAndSettle();
        if (name == 'session_fresh') {
          expect(persistent.value.characters.isEmpty, isTrue);
          expect(persistent.value.nextCharacter, 1);
        } else {
          await press(tester, 'tool-vision');
          await tester.tapAt(cellPosition(tester, persistent, 'A1'));
          await tester.pumpAndSettle();
          await tester.tapAt(cellPosition(tester, persistent, 'D1'));
          await tester.pumpAndSettle();
          if (name == 'session_unknown') {
            persistent.updateVision((v) => v.specialEffects = true);
            await tester.pumpAndSettle();
          }
          expect(
            find.byKey(const ValueKey('vision-map-verdict')),
            findsOneWidget,
          );
        }
      }
      if (name == 'quick_character') {
        await press(tester, 'mode-editor');
        await press(tester, 'tool-characters');
        await tester.tapAt(cellPosition(tester, persistent, 'A1'));
        await tester.pumpAndSettle();
        expect(persistent.value.characters.length, 1);
      }
      if (name.startsWith('final_') && name != 'final_home') {
        final button = name == 'final_guide'
            ? 'open-guide'
            : name == 'final_examples' || name == 'final_example'
            ? 'open-examples'
            : 'open-about';
        await press(tester, button);
        if (name == 'final_example') await press(tester, 'example-diagonal');
        if (name == 'final_licenses') await press(tester, 'open-licenses');
      }
      if (dimensions != null) {
        await tester.ensureVisible(find.text('Abrir editor'));
        await tester.tap(find.text('Abrir editor'));
        await tester.pumpAndSettle();
        final controller = tester
            .widget<EditorScreen>(find.byType(EditorScreen))
            .controller;
        controller.changeDimensions(dimensions);
        for (final (position, team, footprint) in [
          ('A1', 'team-1', Footprint.single),
          ('C1', 'team-2', Footprint.single),
          ('B3', 'team-2', Footprint.square2),
        ]) {
          controller.saveCharacter(
            CharacterDraft(
              name: 'Figura de prueba',
              teamId: team,
              position: CellCoordinate.parse(position),
              footprint: footprint,
            ),
          );
        }
        controller.attempt(
          (session) => session
              .paintTerrain([
                CellCoordinate.parse('A1'),
                CellCoordinate.parse('A2'),
              ], TerrainType.hindering)
              .paintTerrain(
                [CellCoordinate.parse('D1'), CellCoordinate.parse('C4')],
                TerrainType.blocking,
                allowStudy: true,
              )
              .editWalls([
                EdgeWall.between(
                  CellCoordinate.parse('A1'),
                  CellCoordinate.parse('B1'),
                ),
                EdgeWall.between(
                  CellCoordinate.parse('B2'),
                  CellCoordinate.parse('C2'),
                ),
                EdgeWall.between(
                  CellCoordinate.parse('A2'),
                  CellCoordinate.parse('A3'),
                ),
              ], erase: false),
        );
        await tester.pumpAndSettle();
        final cell = CellCoordinate.parse(
          dimensions.columns == 40
              ? 'AA20'
              : dimensions.columns == 4
              ? 'D2'
              : 'D6',
        );
        final point = controller.value.camera.sceneToViewport(
          const BoardGeometry().cellCenter(cell, dimensions),
        );
        await tester.tapAt(
          tester.getTopLeft(find.byKey(const ValueKey('board-viewport'))) +
              Offset(point.x, point.y),
        );
        await tester.pumpAndSettle();
        expect(controller.value.selectedCell, cell);
        if (name.startsWith('figuras') || name.startsWith('ficha')) {
          controller.selectCharacter(controller.value.characters.all.last.id);
          await tester.pumpAndSettle();
        }
        if (name.startsWith('ficha')) {
          await tester.tap(find.byKey(const ValueKey('edit-character')));
          await tester.pumpAndSettle();
        }
        if (name.startsWith('quick_palette')) {
          controller.setTool(EditorTool.terrain);
          await tester.pumpAndSettle();
        }
        if (name == 'quick_elevation') {
          await press(tester, 'tool-elevation');
          expect(
            tester
                .widget<TextField>(
                  find.byKey(const ValueKey('elevation-level')),
                )
                .controller!
                .text,
            '2',
          );
        }
        if (name.startsWith('terreno')) {
          controller.setTool(EditorTool.terrain);
          controller.configureLayers(rectangle: true);
          await tester.pumpAndSettle();
          await tester.ensureVisible(
            find.byKey(const ValueKey('tool-terrain')),
          );
          controller.draft.value = LayerDraft(
            tool: EditorTool.terrain,
            type: TerrainType.hindering,
            rectangle: true,
            eraseWalls: false,
            eraseLayer: EraseLayer.figures,
            cells: const EditingGeometry().rectangle(
              CellCoordinate.parse('A2'),
              CellCoordinate.parse('C3'),
            ),
            pending: true,
          );
          await tester.pumpAndSettle();
        }
        if (name == 'leyenda') {
          await tester.tap(find.byKey(const ValueKey('board-view-options')));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Leyenda y capas'));
          await tester.pumpAndSettle();
        }
        if (name == 'conflicto') {
          controller.setTool(EditorTool.terrain);
          controller.configureLayers(type: TerrainType.blocking);
          await tester.pumpAndSettle();
          final point = controller.value.camera.sceneToViewport(
            const BoardGeometry().cellCenter(
              CellCoordinate.parse('A1'),
              dimensions,
            ),
          );
          await tester.tapAt(
            tester.getTopLeft(find.byKey(const ValueKey('board-viewport'))) +
                Offset(point.x, point.y),
          );
          await tester.pumpAndSettle();
        }
        if (name == 'biblioteca_vertical') {
          await controller.workspace!.save();
          await controller.workspace!.duplicate(
            controller.workspace!.current.id,
            'Escenario de ejemplo',
          );
          await tester.tap(find.byKey(const ValueKey('scenario-library')));
          await tester.pumpAndSettle();
        }
        if (name == 'guardar_como' || name == 'png_opciones') {
          await tester.tap(find.byKey(const ValueKey('board-view-options')));
          await tester.pumpAndSettle();
          final item = find.byKey(
            ValueKey(
              name == 'guardar_como' ? 'save-as-scenario' : 'export-png',
            ),
          );
          await tester.ensureVisible(item);
          await tester.tap(item);
          await tester.pumpAndSettle();
        }
        if (name == 'guardado_error') {
          store.failWrite = true;
          controller.saveCharacter(
            CharacterDraft(
              name: 'Otra figura',
              teamId: 'team-1',
              position: CellCoordinate.parse('D2'),
            ),
          );
          await tester.pumpAndSettle();
          await persistent.workspace!.save();
          await tester.ensureVisible(
            find.byKey(const ValueKey('autosave-status')),
          );
          await tester.tap(find.byKey(const ValueKey('autosave-status')));
          await tester.pumpAndSettle();
        }
        if (name.startsWith('geometria')) {
          controller.setTool(EditorTool.vision);
          controller.setSightEndpoint(
            ProbeEndpoint.cell(CellCoordinate.parse('A1')),
            asOrigin: true,
          );
          controller.setSightEndpoint(
            ProbeEndpoint.cell(
              CellCoordinate.parse(
                name == 'geometria_40x40'
                    ? 'AN39'
                    : name == 'geometria_horizontal'
                    ? 'D3'
                    : 'D4',
              ),
            ),
            asOrigin: false,
          );
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.byKey(const ValueKey('tool-vision')));
          await tester.pumpAndSettle();
          controller.resetCamera();
          await tester.pumpAndSettle();
          if (name == 'geometria_inspector' || name == 'geometria_eventos') {
            final button = find.byKey(const ValueKey('sight-inspect'));
            await tester.ensureVisible(button);
            await tester.pumpAndSettle();
            await tester.tap(button);
            await tester.pumpAndSettle();
            if (name == 'geometria_eventos') {
              await tester.ensureVisible(
                find.byKey(const ValueKey('sight-event-2')),
              );
              await tester.pumpAndSettle();
            }
          }
          if (name == 'geometria_base') {
            final point = controller.value.camera.sceneToViewport(
              const BoardGeometry().cellCenter(
                CellCoordinate.parse('C4'),
                dimensions,
              ),
            );
            await tester.tapAt(
              tester.getTopLeft(find.byKey(const ValueKey('board-viewport'))) +
                  Offset(point.x, point.y),
            );
            await tester.pumpAndSettle();
          }
        }
        if (name.startsWith('movement_')) {
          controller.loadScenario(
            visionSession(
              mw(
                extras: [vf(2, 'D1', team: 'team-2')],
                walls: [
                  EdgeWall.between(
                    CellCoordinate.parse('B1'),
                    CellCoordinate.parse('C1'),
                  ),
                ],
              ),
            ),
          );
          controller.setTool(EditorTool.movement);
          controller.beginMovement('figure-1');
          controller.movementCell(
            CellCoordinate.parse(name == 'movement_invalid' ? 'D4' : 'B2'),
          );
          if (name == 'movement_unknown') {
            controller.updateMovement((m) => m.setEffects(true));
          }
          await tester.pumpAndSettle();
          if (name != 'movement_route' && name != 'movement_invalid') {
            showMovementReport(
              tester.element(find.byType(Scaffold).last),
              controller,
            );
            await tester.pumpAndSettle();
            if (name == 'movement_comparison') {
              await tester.ensureVisible(
                find.byKey(const ValueKey('movement-comparison')),
              );
              await tester.tap(
                find.byKey(const ValueKey('movement-comparison')),
              );
              await tester.pumpAndSettle();
              await tester.ensureVisible(find.textContaining('Distancia 3'));
              await tester.pumpAndSettle();
            }
            if (name == 'movement_alternatives') {
              controller.updateMovement(
                (m) => m.search(CellCoordinate.parse('C1')),
              );
              await tester.pumpAndSettle();
              await tester.ensureVisible(
                find.byKey(const ValueKey('movement-route-0')),
              );
              await tester.pumpAndSettle();
            }
          }
        }
        if (name.startsWith('advanced_')) {
          final base = name.startsWith('advanced_base');
          final elevated = [
            'advanced_elevation',
            'advanced_form',
            'advanced_referee',
          ].contains(name);
          final world = base
              ? ranged(
                  vs(
                    target: 'B3',
                    targetBase: Footprint.rectangle(width: 1, height: 2),
                    walls: [
                      EdgeWall.between(
                        CellCoordinate.parse('A2'),
                        CellCoordinate.parse('B2'),
                      ),
                    ],
                  ),
                  2,
                )
              : elevated
              ? capable(
                  vs(
                    elevations: {'A1': 2, 'A2': 2, 'B1': 2, 'B2': 2},
                    terrain: {'D1': TerrainType.hindering},
                  ),
                  [VisionAbility.elevated],
                )
              : capable(
                  vs(
                    terrain: {
                      'B1': TerrainType.hindering,
                      'C1': TerrainType.blocking,
                    },
                  ),
                  name == 'advanced_record' ? [VisionAbility.hindering] : [],
                );
          controller.loadScenario(visionSession(world));
          if (elevated) {
            controller.attempt(
              (s) => s.setTransition(
                EdgeWall.between(
                  CellCoordinate.parse('B1'),
                  CellCoordinate.parse('C1'),
                ),
                remove: false,
              ),
            );
          }
          chooseVision(controller);
          controller.setTool(EditorTool.vision);
          await tester.pumpAndSettle();
          controller.resetCamera();
          await tester.pumpAndSettle();
          var context = tester.element(find.byType(EditorScreen));
          if (name == 'advanced_referee') {
            await tester.tap(find.byTooltip('Atrás').last);
            await tester.pumpAndSettle();
            await tester.ensureVisible(find.text('Abrir árbitro'));
            await tester.tap(find.text('Abrir árbitro'));
            await tester.pumpAndSettle();
            controller.resetCamera();
            await tester.pumpAndSettle();
            context = tester.element(
              find.byKey(const ValueKey('vision-report')),
            );
          }
          if (name == 'advanced_laboratory') {
            controller.updateVision(
              (v) => v.laboratoryAbilities = {VisionAbility.blocking},
            );
          }
          if ([
            'advanced_base_report',
            'advanced_laboratory',
            'advanced_record',
            'advanced_referee',
          ].contains(name)) {
            showVisionReport(context, controller);
            await tester.pumpAndSettle();
            if (name == 'advanced_record' || name == 'advanced_base_report') {
              final key = name == 'advanced_record'
                  ? 'vision-log'
                  : 'vision-reference-pairs';
              await tester.ensureVisible(find.byKey(ValueKey(key)));
              await tester.tap(find.byKey(ValueKey(key)));
              await tester.pumpAndSettle();
            }
            if (name == 'advanced_laboratory') {
              await tester.ensureVisible(
                find.byKey(const ValueKey('vision-laboratory')),
              );
            }
          }
          if (name == 'advanced_form') {
            showElevationDialog(context, controller);
            await tester.pumpAndSettle();
          }
        }
        if (name.startsWith('tactical_')) {
          final world = vs(
            rows: 8,
            columns: 8,
            terrain: {'A2': TerrainType.blocking, 'B2': TerrainType.hindering},
            extras: [
              vf(3, 'H8'),
              vf(4, 'D4', team: 'team-2'),
              vf(5, 'A3', team: 'team-2'),
              vf(6, 'F8', team: 'team-2'),
              vf(
                7,
                'G1',
                team: 'team-2',
                footprint: Footprint.square2,
                size: FigureSize.giant,
              ),
            ],
          );
          controller.loadScenario(visionSession(world));
          if (name.startsWith('tactical_distance')) {
            controller.setTool(EditorTool.distance);
            controller.setSightEndpoint(
              ProbeEndpoint.cell(CellCoordinate.parse('A1')),
              asOrigin: true,
            );
            controller.setSightEndpoint(
              ProbeEndpoint.cell(CellCoordinate.parse('D6')),
              asOrigin: false,
            );
          } else {
            controller.selectCharacter('figure-1');
            controller.setTool(EditorTool.targets);
            if (name != 'tactical_list') {
              controller.selectTarget(
                name == 'tactical_unknown' ? 'figure-7' : 'figure-4',
              );
            }
          }
          await tester.pumpAndSettle();
          controller.resetCamera();
          await tester.pumpAndSettle();
          final context = tester.element(find.byType(EditorScreen));
          if (name == 'tactical_list') showTargetList(context, controller);
          if (name == 'tactical_detail') showTargetReport(context, controller);
          if (name == 'tactical_distance_report') {
            controller.updateTactical((t) => t.showDeltas = true);
            showDistanceReport(context, controller);
          }
          await tester.pumpAndSettle();
        }
        if (name.startsWith('vision_')) {
          final world = name == 'vision_a1_d6'
              ? vs(target: 'D6', rows: 6, terrain: {'B4': TerrainType.blocking})
              : name == 'vision_corner'
              ? vs(
                  target: 'B2',
                  terrain: {
                    'B1': TerrainType.blocking,
                    'A2': TerrainType.hindering,
                  },
                )
              : vs(
                  terrain: {
                    if (name != 'vision_clear' && name != 'vision_unknown')
                      'B1': name == 'vision_blocked'
                          ? TerrainType.blocking
                          : TerrainType.hindering,
                  },
                );
          controller.loadScenario(visionSession(world));
          controller.workspace!.edited(controller.value);
          chooseVision(controller);
          controller.setTool(EditorTool.vision);
          if (name == 'vision_unknown') {
            controller.updateVision((v) => v.specialEffects = true);
          }
          await tester.pumpAndSettle();
          controller.resetCamera();
          await tester.pumpAndSettle();
          if (name == 'vision_referee') {
            await tester.tap(find.byTooltip('Atrás').last);
            await tester.pumpAndSettle();
            await tester.ensureVisible(find.text('Abrir árbitro'));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Abrir árbitro'));
            await tester.pumpAndSettle();
            controller.resetCamera();
            await tester.pumpAndSettle();
          }
          if (name == 'vision_report' || name == 'vision_record') {
            await tester.tap(find.byKey(const ValueKey('board-view-options')));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Dictamen de visión').last);
            await tester.pumpAndSettle();
            if (name == 'vision_record') {
              final log = find.byKey(const ValueKey('vision-log'));
              await tester.ensureVisible(log);
              await tester.pumpAndSettle();
              await tester.tap(log);
              await tester.pumpAndSettle();
              await tester.ensureVisible(
                find.byKey(const ValueKey('vision-observation-2')),
              );
              await tester.pumpAndSettle();
            }
          }
          await tester.runAsync(() async {
            final doc = ScenarioDocument.fresh(
              name: name,
              session: visionSession(world),
            );
            const codec = ScenarioCodec();
            final file = File('build/verification/session-vision/$name.json');
            await file.parent.create(recursive: true);
            await file.writeAsString(codec.encode(doc));
            await File('build/verification/session-vision/$name-working.json')
                .writeAsString(
                  jsonEncode({
                    'workspaceSchemaVersion': 1,
                    'document': codec.toMap(doc),
                    'dirty': true,
                    'saved': false,
                  }),
                );
          });
        }
      }
      if (name.startsWith('training_')) {
        await tester.ensureVisible(find.text('Abrir entrenador'));
        await tester.tap(find.text('Abrir entrenador'));
        await tester.pumpAndSettle();
        if (name == 'training_personal') {
          await press(tester, 'training-new');
          await tester.enterText(
            find.byKey(const ValueKey('personal-title')),
            'Mi práctica de visión',
          );
          await tester.enterText(
            find.byKey(const ValueKey('personal-question')),
            '¿Cómo es la visión entre las dos figuras?',
          );
          await tester.pumpAndSettle();
        } else if (name == 'training_progress') {
          await training.submit(
            curatedExercises[0],
            correctTrainingAnswer(curatedExercises[0]),
            'preview-1',
          );
          await training.submit(
            curatedExercises[1],
            Answer(AnswerKind.choice, value: 'blocked'),
            'preview-2',
          );
          await tester.pumpAndSettle();
          await press(tester, 'training-progress');
          await tester.ensureVisible(
            find.byKey(const ValueKey('training-stats-vision')),
          );
          await tester.pumpAndSettle();
        } else if (name == 'training_unknown') {
          await tester.ensureVisible(
            find.byKey(
              ValueKey(
                'training-start-${training.repository.data.personal.single.id}',
              ),
            ),
          );
          await tester.pumpAndSettle();
        } else if (!['training_bank'].contains(name)) {
          final id = name == 'training_manual'
              ? training.repository.data.personal.single.id
              : name == 'training_route'
              ? 'hc10-m02'
              : 'hc10-v02';
          await press(tester, 'training-start-$id');
          if (name == 'training_feedback') {
            await press(tester, 'training-option-hindered');
            await press(tester, 'training-check');
            await tester.ensureVisible(
              find.byKey(const ValueKey('training-feedback')),
            );
            await tester.pumpAndSettle();
          } else if (name == 'training_manual') {
            await tester.ensureVisible(
              find.byKey(const ValueKey('training-text')),
            );
            await tester.enterText(
              find.byKey(const ValueKey('training-text')),
              'Primero revisaría los obstáculos y las capacidades declaradas.',
            );
            await press(tester, 'training-check');
            await tester.ensureVisible(
              find.byKey(const ValueKey('training-feedback')),
            );
            await tester.pumpAndSettle();
          } else if (name == 'training_route') {
            for (final label in ['A2', 'B3', 'C2', 'C1']) {
              await tester.ensureVisible(
                find.byKey(const ValueKey('board-viewport')),
              );
              await tester.pumpAndSettle();
              final board = tester.widget<BoardCanvas>(
                find.byType(BoardCanvas),
              );
              await tester.tapAt(cellPosition(tester, board.controller, label));
              await tester.pumpAndSettle();
            }
          }
        }
      }
      if (name.startsWith('tactics_')) {
        final world = name == 'tactics_hypothesis'
            ? tacticCaps(tacticalWorld(), it: [VisionAbility.blocking])
            : name == 'tactics_uncertainty'
            ? tacticCaps(tacticalWorld(), it: [VisionAbility.other])
            : tacticalWorld();
        persistent.loadScenario(visionSession(world));
        persistent.selectCharacter('figure-1');
        final analysis = PositionAnalysisController(persistent);
        if (name == 'tactics_hypothesis') analysis.setComparison(true);
        await tester.runAsync(() => analysis.analyze());
        analysis.select(
          CellCoordinate.parse(name == 'tactics_hypothesis' ? 'B1' : 'B2'),
        );
        if (name == 'tactics_exercise') {
          final e = await tester.runAsync(
            () => buildAnalysisExercise(
              AnalysisExerciseRequest(
                analysis.original,
                'figure-1',
                analysis.context.rulesVersion,
                analysis.chosen!,
                analysis.current!,
                analysis.candidates,
                'figure-2',
                false,
              ),
            ),
          );
          await training.repository.add(e!);
          training.generatedExerciseAdded();
          analysis.dispose();
          await tester.ensureVisible(find.text('Abrir entrenador'));
          await tester.tap(find.text('Abrir entrenador'));
          await tester.pumpAndSettle();
          await press(tester, 'training-start-${e.id}');
        } else {
          Navigator.of(tester.element(find.byType(Scaffold))).push<void>(
            MaterialPageRoute(
              builder: (_) =>
                  TacticalScreen(editor: persistent, analysis: analysis),
            ),
          );
          await tester.pumpAndSettle();
          if (name == 'tactics_comparison') {
            await tester.ensureVisible(
              find.byKey(const ValueKey('position-comparison')),
            );
          }
          if (name == 'tactics_map' || name == 'tactics_export') {
            await tester.ensureVisible(
              find.byKey(const ValueKey('board-viewport')),
            );
          }
          if (name == 'tactics_uncertainty') {
            await tester.ensureVisible(
              find.byKey(const ValueKey('position-current')),
            );
          }
          if (name == 'tactics_hypothesis') {
            await tester.ensureVisible(
              find.text('HIPÓTESIS sin mejoras soportadas'),
            );
          }
          if (name == 'tactics_evidence') {
            await press(tester, 'position-enemy-evidence');
            await tester.ensureVisible(find.text('Enemigo B'));
          }
          await tester.pumpAndSettle();
          if (name == 'tactics_export') {
            await tester.runAsync(() async {
              final bytes = await diagnosticPng(
                analysis.original,
                analysis.current!,
                analysis.candidates,
                analysis.chosen,
                analysis.priority,
              );
              final file = File(
                'build/verification/session-vision/diagnostico.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes);
            });
          }
        }
      }
      expect(tester.takeException(), isNull);

      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        try {
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final output = File('build/previews/session-vision/$name.png');
          await output.parent.create(recursive: true);
          await output.writeAsBytes(bytes!.buffer.asUint8List());
        } finally {
          image.dispose();
        }
      });
    });
  }
}

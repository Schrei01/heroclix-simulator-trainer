import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:heroclix_simulator_trainer/app.dart';
import 'package:heroclix_simulator_trainer/application/board/board_session.dart';
import 'package:heroclix_simulator_trainer/application/examples/local_examples.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_codec.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_repository.dart';
import 'package:heroclix_simulator_trainer/application/training/personal_exercise.dart';
import 'package:heroclix_simulator_trainer/application/training/training_repository.dart';
import 'package:heroclix_simulator_trainer/domain/app_info.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_dimensions.dart';
import 'package:heroclix_simulator_trainer/domain/board/cell_coordinate.dart';
import 'package:heroclix_simulator_trainer/domain/characters/character.dart';
import 'package:heroclix_simulator_trainer/domain/rules/line_of_sight.dart';
import 'package:heroclix_simulator_trainer/domain/rules/target_analysis_service.dart';
import 'package:heroclix_simulator_trainer/domain/training/exercise.dart';
import 'package:heroclix_simulator_trainer/domain/training/exercise_evaluator.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/terrain.dart';
import 'package:heroclix_simulator_trainer/infrastructure/local/file_document_store.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/editor_controller.dart';
import 'package:heroclix_simulator_trainer/presentation/scenarios/workspace_controller.dart';
import 'package:heroclix_simulator_trainer/presentation/scenarios/board_png_exporter.dart';
import 'package:heroclix_simulator_trainer/presentation/training/training_controller.dart';
import 'package:heroclix_simulator_trainer/presentation/training/exercise_screen.dart';
import 'package:heroclix_simulator_trainer/presentation/help/info_screen.dart';
import 'package:heroclix_simulator_trainer/presentation/theme/app_theme.dart';
import 'package:heroclix_simulator_trainer/presentation/vision/vision_controls.dart';

import 'character_editor_test.dart' show press;
import 'vision_state_test.dart' show chooseVision;
import 'support/scenario_fakes.dart';

CellCoordinate fc(String value) => CellCoordinate.parse(value);

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  test('versión distribuida, perfil y pubspec coinciden', () {
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('version: ${AppInfo.version}+${AppInfo.build}'),
    );
    expect(AppInfo.rules, VisionContext.supportedVersion);
  });
  test(
    'sin espacio: conserva documento anterior y permite reintentar',
    () async {
      final store = MemoryStore();
      final editor = await persistentController(store);
      addTearDown(editor.dispose);
      expect(await editor.workspace!.save(name: 'Conservar'), isTrue);
      final id = editor.workspace!.current.id,
          previous = store.documents[editor.workspace!.current.id];
      store.failWrite = true;
      store.writeError = const OSError('No space left on device', 28);
      editor.saveCharacter(
        CharacterDraft(
          name: 'Cambio pendiente',
          teamId: 'team-1',
          position: fc('A1'),
        ),
      );
      expect(await editor.workspace!.save(), isFalse);
      expect(store.documents[id], previous);
      expect(editor.workspace!.error, contains('espacio disponible'));
      store.failWrite = false;
      expect(await editor.workspace!.save(), isTrue);
      expect(
        (await editor.workspace!.repository.open(id)).session.characters.length,
        1,
      );
    },
  );
  for (final example in localExamples) {
    test(
      'ejemplo ${example.id}: copia nueva, codec y solución reglamentaria verificada',
      () {
        final a = example.copy(), b = example.copy();
        expect(a.id, isNot(b.id));
        final copy = const ScenarioCodec().decode(
          const ScenarioCodec().encode(a),
        );
        expect(copy.session.characters.length, a.session.characters.length);
        expect(copy.rulesVersion, AppInfo.rules);
        expect(
          const ExerciseEvaluator().check(example.exercise).eligible,
          isTrue,
        );
        expect(example.exercise.references, isNotEmpty);
      },
    );
  }
  testWidgets('los cuatro modos abren y comparten escena sin mutarla', (
    tester,
  ) async {
    final c = await persistentController(MemoryStore());
    c.loadScenario(localExamples.first.copy().session);
    await tester.pumpWidget(HeroClixApp(controller: c));
    final before = c.value.characters.all.first.position;
    for (final id in ['editor', 'simulator', 'referee', 'trainer']) {
      await press(tester, 'mode-$id');
      expect(tester.takeException(), isNull);
      expect(c.value.characters.all.first.position, before);
      await tester.tap(find.byTooltip('Atrás'));
      await tester.pumpAndSettle();
    }
  });
  testWidgets(
    'ejemplo exige preservar cambios, cancelar conserva y abrir copia no reemplaza biblioteca',
    (tester) async {
      final store = MemoryStore(), c = await persistentController(store);
      c.saveCharacter(
        CharacterDraft(name: 'Original', teamId: 'team-1', position: fc('A1')),
      );
      final originalId = c.workspace!.current.id;
      await tester.pumpWidget(HeroClixApp(controller: c));
      await press(tester, 'open-examples');
      await press(tester, 'example-wall');
      await press(tester, 'open-example-copy');
      expect(find.text('Cambios fuera de la biblioteca'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(c.workspace!.current.id, originalId);
      expect(c.value.characters.all.single.name, 'Original');
      await c.workspace!.save();
      await press(tester, 'open-example-copy');
      expect(c.workspace!.current.id, isNot(originalId));
      expect(c.value.characters.length, 2);
      expect(
        (await c.workspace!.repository.open(originalId))
            .session
            .characters
            .all
            .single
            .name,
        'Original',
      );
      expect((await c.workspace!.library()).length, 2);
    },
  );
  testWidgets(
    'aceptación: crear, guardar, reabrir, visión, alcance, mover, ejercicio, resolver, JSON y PNG',
    (tester) async {
      final root = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('heroclix12-'),
      ))!;
      addTearDown(
        () => tester.runAsync(() async {
          final resolved = await root.resolveSymbolicLinks(),
              temp = await Directory.systemTemp.resolveSymbolicLinks();
          if (!resolved.toLowerCase().startsWith(
            '$temp${Platform.pathSeparator}heroclix12-'.toLowerCase(),
          )) {
            throw StateError(
              'Directorio de prueba fuera del temporal previsto.',
            );
          }
          await root.delete(recursive: true);
        }),
      );
      Future<EditorController> restore() async {
        final c = EditorController();
        final w = WorkspaceController(
          persistWorkingSession: true,
          repository: ScenarioRepository(FileDocumentStore(() async => root)),
          readSession: () => c.value,
          loadSession: c.loadScenario,
        );
        c.attachWorkspace(w);
        await w.initialize();
        return c;
      }

      final restored = (await tester.runAsync(() async {
        final c = await restore();
        c.attempt(
          (s) => s.changeDimensions(BoardDimensions(rows: 6, columns: 6)),
        );
        c.saveCharacter(
          CharacterDraft(
            name: 'Activo',
            teamId: 'team-1',
            position: fc('A1'),
            speed: 4,
            range: 4,
          ),
        );
        c.saveCharacter(
          CharacterDraft(
            name: 'Objetivo',
            teamId: 'team-2',
            position: fc('D1'),
            speed: 4,
            range: 4,
          ),
        );
        c.attempt((s) => s.paintTerrain([fc('B1')], TerrainType.hindering));
        expect(await c.workspace!.save(name: 'Aceptación 12'), isTrue);
        final id = c.workspace!.current.id;
        await c.workspace!.flush();
        c.dispose();
        final again = await restore();
        expect(again.workspace!.current.id, id);
        expect(await again.workspace!.open(id), isTrue);
        chooseVision(again);
        expect(again.vision.result!.status, VisionStatus.hindered);
        expect(
          again.vision.result!.decisive.expand((o) => o.rules),
          isNotEmpty,
        );
        again.enableTargets();
        again.updateTactical((t) => t.sourceId = 'figure-1');
        final target = again.tactical.report!.targets.single;
        expect(target.distance.squares, 3);
        expect(target.status, TargetStatus.inRangeHindered);
        again.setTool(EditorTool.movement);
        again.beginMovement('figure-1');
        again.movementCell(fc('A2'));
        expect(again.confirmMovement(), isNull);
        expect(again.value.characters.byId('figure-1')!.position, fc('A2'));
        expect(await again.workspace!.save(), isTrue);
        final e = personalExercise(
          id: 'personal-${'c' * 32}',
          title: 'Visión desde la escena guardada',
          instruction: '¿Cómo es la visión de A a B?',
          scenario: await again.workspace!.repository.open(id),
          category: SkillCategory.vision,
          difficulty: Difficulty.basic,
          type: QuestionType.choice,
          metric: ExerciseMetric.vision,
          sourceId: 'figure-1',
          targetId: 'figure-2',
          options: const [
            ExerciseOption('clear', 'Despejada'),
            ExerciseOption('hindered', 'Obstaculizada'),
            ExerciseOption('blocked', 'Bloqueada'),
          ],
          expected: ['clear'],
          explanation:
              'Desde A2, B1 solo toca el vértice y el otro lado queda libre.',
        );
        final trainingRoot = Directory('${root.path}/training_v1');
        final repo = TrainingRepository(
          FileDocumentStore(() async => trainingRoot),
        );
        final t = TrainingController(
          repo,
          scenarios: again.workspace!.repository,
        );
        await t.initialize();
        expect(await t.add(e), isTrue);
        final json = const ScenarioCodec().encode(again.workspace!.current);
        final external = File('${root.path}/intercambio.json');
        await external.writeAsString(json);
        final imported = const ScenarioCodec().decode(
          await external.readAsString(),
        );
        expect(await again.workspace!.importDocument(imported), isTrue);
        expect(again.value.characters.byId('figure-1')!.position, fc('A2'));
        return (
          editor: again,
          training: t,
          exercise: e,
          trainingRoot: trainingRoot,
        );
      }))!;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: ExerciseScreen(
            controller: restored.training,
            exercises: [restored.exercise],
            index: 0,
          ),
        ),
      );
      await press(tester, 'training-option-clear');
      await tester.ensureVisible(find.byKey(const ValueKey('training-check')));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('training-check')));
        await restored.training.flush();
      });
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('training-feedback')), findsOneWidget);
      expect(restored.training.progress(restored.exercise)!.correct, 1);
      await tester.runAsync(() async {
        await restored.training.flush();
        final reopened = TrainingRepository(
          FileDocumentStore(() async => restored.trainingRoot),
        );
        await reopened.load();
        expect(reopened.data.personal.single.id, restored.exercise.id);
        expect(reopened.data.progress.single.correct, 1);
        final png = await const BoardPngExporter().render(
          restored.editor.value,
        );
        final external = File('${root.path}/intercambio.png');
        await external.writeAsBytes(png.bytes);
        final codec = await ui.instantiateImageCodec(
          await external.readAsBytes(),
        );
        final frame = await codec.getNextFrame();
        expect(frame.image.width, png.width);
        expect(frame.image.height, png.height);
        frame.image.dispose();
        codec.dispose();
        final evidence = Directory('build/verification/prompt-12');
        await evidence.create(recursive: true);
        await File('${evidence.path}/aceptacion.json').writeAsString(
          const ScenarioCodec().encode(restored.editor.workspace!.current),
        );
        await File('${evidence.path}/aceptacion.png').writeAsBytes(png.bytes);
      });
      await tester.pumpWidget(const SizedBox.shrink());
      restored.editor.dispose();
      restored.training.dispose();
    },
  );
  for (final (size, scale) in [
    (const Size(360, 800), 1.0),
    (const Size(800, 360), 1.0),
    (const Size(320, 320), 3.0),
  ]) {
    for (final help in [true, false]) {
      testWidgets(
        '${help ? 'guía' : 'acerca de'} sin desbordes en $size, texto $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.dark,
              home: help ? const QuickGuideScreen() : const AboutScreen(),
            ),
          );
          final end = find.text(
            help
                ? 'Todo el análisis, ejemplos, ejercicios y licencias funciona sin internet ni cuenta. El selector de archivos puede mostrar proveedores externos que requieran conexión; elige almacenamiento del dispositivo para trabajar offline.'
                : 'Licencias de dependencias',
          );
          await tester.ensureVisible(end);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('licencias abre página local real desde Acerca de', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const AboutScreen()),
    );
    await press(tester, 'open-licenses');
    expect(find.byType(LicensePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('objetivos táctiles y etiquetas accesibles en inicio', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(const HeroClixApp());
      await tester.ensureVisible(find.byKey(const ValueKey('open-about')));
      await tester.pumpAndSettle();
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      expect(tester, meetsGuideline(labeledTapTargetGuideline));
      expect(tester, meetsGuideline(textContrastGuideline));
    } finally {
      semantics.dispose();
    }
  });
  test('colores de estados contrastan y cada estado tiene texto e icono', () {
    double ratio(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05);
    }

    for (final status in VisionStatus.values) {
      expect(visionLabel(status), isNotEmpty);
      expect(visionIcon(status), isNotNull);
      expect(
        ratio(visionColor(status), AppTheme.background),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        ratio(visionColor(status), AppTheme.surface),
        greaterThanOrEqualTo(4.5),
      );
    }
  });
}

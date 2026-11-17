import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:heroclix_simulator_trainer/app.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_repository.dart';
import 'package:heroclix_simulator_trainer/application/training/training_repository.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_dimensions.dart';
import 'package:heroclix_simulator_trainer/domain/board/cell_coordinate.dart';
import 'package:heroclix_simulator_trainer/domain/characters/character.dart';
import 'package:heroclix_simulator_trainer/domain/rules/line_of_sight.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/terrain.dart';
import 'package:heroclix_simulator_trainer/domain/training/curated_exercises.dart';
import 'package:heroclix_simulator_trainer/domain/training/exercise_evaluator.dart';
import 'package:heroclix_simulator_trainer/infrastructure/local/file_document_store.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/editor_controller.dart';
import 'package:heroclix_simulator_trainer/presentation/scenarios/workspace_controller.dart';
import 'package:heroclix_simulator_trainer/presentation/vision/vision_controls.dart';

import 'support/scenario_fakes.dart';
import 'support/vision_contract.dart';
import 'support/training_fixtures.dart' show correctTrainingAnswer;
import 'vision_state_test.dart' show visionSession;
import 'editor_test.dart' show cellPosition;
import 'character_editor_test.dart' show press;

CharacterDraft sessionFigure(String at) => CharacterDraft(
  name: 'Figura',
  teamId: 'team-1',
  position: CellCoordinate.parse(at),
);

Future<EditorController> temporaryController(
  ScenarioRepository repository,
) async {
  final c = EditorController();
  final w = WorkspaceController(
    repository: repository,
    readSession: () => c.value,
    loadSession: c.loadScenario,
  );
  c.attachWorkspace(w);
  await w.initialize();
  return c;
}

Future<EditorController> traceFromUi(
  WidgetTester tester, {
  String mode = 'editor',
  VisionSnapshot? world,
  String first = 'A1',
  String last = 'D1',
}) async {
  final c = EditorController()..loadScenario(visionSession(world ?? vs()));
  await tester.pumpWidget(HeroClixApp(controller: c));
  final label = mode == 'editor'
      ? 'Abrir editor'
      : mode == 'referee'
      ? 'Abrir árbitro'
      : 'Abrir simulador';
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
  if (mode == 'editor') await press(tester, 'tool-vision');
  expect(c.vision.enabled, isTrue);
  await tester.tapAt(cellPosition(tester, c, first));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('vision-map-verdict')), findsNothing);
  await tester.tapAt(cellPosition(tester, c, last));
  await tester.pumpAndSettle();
  return c;
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  test('arranque nuevo ignora recuperación AA, usa escenario vacío y empieza otra vez desde A', () async {
    final store = MemoryStore(), old = await persistentController(store);
    old.changeDimensions(BoardDimensions(rows: 6, columns: 6));
    for (var i = 0; i < 27; i++) {
      old.saveCharacter(
        sessionFigure(CellCoordinate(column: i % 6, row: i ~/ 6).label),
      );
    }
    expect(old.value.selectedCharacter!.label, 'AA');
    await old.workspace!.flush();
    old.dispose();
    final legacy = store.documents['working'], writes = store.writes;
    store.failRead = true;
    final fresh = await temporaryController(ScenarioRepository(store));
    addTearDown(fresh.dispose);
    expect(fresh.workspace!.persistWorkingSession, isFalse);
    expect(fresh.workspace!.error, isNull);
    expect(fresh.value.dimensions, BoardDimensions.initial);
    expect(fresh.value.characters.isEmpty, isTrue);
    fresh.saveCharacter(sessionFigure('A1'));
    expect(fresh.value.selectedCharacter!.label, 'A');
    await fresh.workspace!.flush();
    expect(store.documents['working'], legacy);
    expect(store.writes, writes);
  });
  test('biblioteca explícita persiste, cambios temporales no y abrir guardado es una decisión explícita', () async {
    final store = MemoryStore();
    final c = await temporaryController(ScenarioRepository(store));
    c.saveCharacter(sessionFigure('A1'));
    store.failWrite = true;
    expect(await c.workspace!.save(), isFalse);
    store.failWrite = false;
    expect(await c.workspace!.retry(), isTrue);
    expect(await c.workspace!.save(name: 'Conservar'), isTrue);
    final id = c.workspace!.current.id;
    c.saveCharacter(sessionFigure('B2'));
    await c.workspace!.flush();
    expect(store.documents.containsKey('working'), isFalse);
    c.dispose();
    final fresh = await temporaryController(ScenarioRepository(store));
    addTearDown(fresh.dispose);
    expect(fresh.value.characters.isEmpty, isTrue);
    expect((await fresh.workspace!.library()).single.id, id);
    expect(await fresh.workspace!.open(id), isTrue);
    expect(fresh.value.characters.length, 1);
    expect(fresh.value.characters.all.single.position, vc('A1'));
    expect(store.documents.containsKey('working'), isFalse);
  });
  test('archivos reales: escenario arranca vacío; biblioteca y progreso del Entrenador conservados', () async {
    final root = await Directory.systemTemp.createTemp('heroclix-session-');
    addTearDown(() async {
      final resolved = await root.resolveSymbolicLinks(),
          temp = await Directory.systemTemp.resolveSymbolicLinks();
      if (!resolved.toLowerCase().startsWith(
        '$temp${Platform.pathSeparator}heroclix-session-'.toLowerCase(),
      )) {
        throw StateError('Temporal fuera del directorio previsto.');
      }
      await root.delete(recursive: true);
    });
    ScenarioRepository scenes() =>
        ScenarioRepository(FileDocumentStore(() async => root));
    TrainingRepository training() => TrainingRepository(
      FileDocumentStore(() async => Directory('${root.path}/training_v1')),
    );
    final first = await temporaryController(scenes());
    first.saveCharacter(sessionFigure('A1'));
    expect(await first.workspace!.save(name: 'Biblioteca'), isTrue);
    final id = first.workspace!.current.id;
    final t = training(), exercise = curatedExercises.first;
    await t.load();
    final answer = correctTrainingAnswer(exercise);
    await t.record(
      exercise,
      answer,
      const ExerciseEvaluator().evaluate(exercise, answer),
      'session-test',
    );
    await first.workspace!.flush();
    first.dispose();
    final fresh = await temporaryController(scenes());
    addTearDown(fresh.dispose);
    expect(fresh.value.characters.isEmpty, isTrue);
    expect((await scenes().open(id)).session.characters.length, 1);
    final again = training();
    await again.load();
    expect(again.data.progress.single.correct, 1);
    expect(await File('${root.path}/working.json').exists(), isFalse);
  });
  testWidgets(
    'cambiar de sección y segundo plano conservan la sesión mientras vive la app',
    (tester) async {
      final store = MemoryStore();
      final live = await temporaryController(ScenarioRepository(store));
      await tester.pumpWidget(HeroClixApp(controller: live));
      await press(tester, 'mode-editor');
      await press(tester, 'tool-characters');
      for (final at in ['A1', 'D1']) {
        await tester.tapAt(cellPosition(tester, live, at));
        await tester.pumpAndSettle();
      }
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Atrás'));
      await tester.pumpAndSettle();
      await press(tester, 'mode-simulator');
      expect(live.value.characters.all.map((f) => f.label), ['A', 'B']);
      expect(store.documents, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  for (final (mode, terrain, status) in [
    ('editor', TerrainType.clear, VisionStatus.clear),
    ('simulator', TerrainType.hindering, VisionStatus.hindered),
    ('referee', TerrainType.blocking, VisionStatus.blocked),
  ]) {
    testWidgets(
      '$mode: elegir dos figuras publica ${status.name} arriba del mapa sin abrir menús',
      (tester) async {
        final c = await traceFromUi(
          tester,
          mode: mode,
          world: vs(terrain: {'B1': terrain}),
        );
        final banner = find.byKey(const ValueKey('vision-map-verdict'));
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('vision-map-result')))
              .data,
          contains(visionLabel(status)),
        );
        expect(c.vision.result!.status, status);
        expect(find.byType(Dialog), findsNothing);
        expect(
          tester.getRect(banner).bottom,
          lessThanOrEqualTo(
            tester.getRect(find.byKey(const ValueKey('board-viewport'))).top +
                1,
          ),
        );
        await press(tester, 'vision-map-verdict');
        expect(
          tester.widget<Text>(find.byKey(const ValueKey('vision-result'))).data,
          visionLabel(status),
        );
      },
    );
  }
  testWidgets(
    'dictamen se recalcula y conserva No evaluado; limpiar retira el resultado anterior',
    (tester) async {
      final c = await traceFromUi(tester);
      final text = find.byKey(const ValueKey('vision-map-result'));
      c.attempt((s) => s.paintTerrain([vc('B1')], TerrainType.blocking));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(text).data, contains('BLOQUEADA'));
      c.updateVision((v) => v.specialEffects = true);
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(text).data, contains('NO EVALUADA'));
      c.updateVision((v) => v.specialEffects = false);
      c.deleteCharacter('figure-2');
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(text).data, contains('NO EVALUADA'));
      await press(tester, 'sight-clear');
      expect(text, findsNothing);
    },
  );
  testWidgets(
    'base múltiple usa referencias automáticas sin interrumpir el trazado',
    (tester) async {
      final c = await traceFromUi(
        tester,
        world: vs(sourceBase: Footprint.square2, target: 'D4'),
        first: 'B2',
        last: 'D4',
      );
      expect(find.byType(Dialog), findsNothing);
      expect(c.vision.automaticReferences, isTrue);
      expect(c.vision.result!.status, VisionStatus.clear);
      expect(find.byKey(const ValueKey('vision-map-verdict')), findsOneWidget);
    },
  );
  testWidgets(
    'A1–D6 con B4 bloqueado sigue despejada por el vértice en dictamen inmediato',
    (tester) async {
      final c = await traceFromUi(
        tester,
        world: vs(rows: 6, target: 'D6', terrain: {'B4': TerrainType.blocking}),
        last: 'D6',
      );
      expect(c.vision.result!.status, VisionStatus.clear);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('vision-map-result')))
            .data,
        contains('DESPEJADA'),
      );
    },
  );
  for (final (mode, size, scale) in [
    ('editor', const Size(360, 800), 1.0),
    ('simulator', const Size(800, 360), 1.0),
    ('editor', const Size(320, 320), 3.0),
  ]) {
    testWidgets(
      'dictamen inmediato $mode sin desbordes en $size texto $scale',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await traceFromUi(tester, mode: mode);
        if (scale > 1) {
          expect(
            tester
                .widget<Text>(find.byKey(const ValueKey('vision-map-result')))
                .data,
            'DESPEJADA',
          );
        }
        expect(
          find.byKey(const ValueKey('vision-map-verdict')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}

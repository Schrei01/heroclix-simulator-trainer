import 'support/test_clock.dart';

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:heroclix_simulator_trainer/app.dart';
import 'package:heroclix_simulator_trainer/application/board/board_edit.dart';
import 'package:heroclix_simulator_trainer/application/training/training_repository.dart';
import 'package:heroclix_simulator_trainer/domain/tactics/tactical_diagnostic.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/editor_controller.dart';
import 'package:heroclix_simulator_trainer/presentation/tactics/position_analysis_controller.dart';
import 'package:heroclix_simulator_trainer/presentation/tactics/tactical_screen.dart';
import 'package:heroclix_simulator_trainer/presentation/training/training_controller.dart';
import 'package:heroclix_simulator_trainer/presentation/training/training_painter.dart';

import 'support/tactics_contract.dart';
import 'support/vision_contract.dart';
import 'support/scenario_fakes.dart';
import 'vision_state_test.dart' show visionSession;
import 'character_editor_test.dart' show press;
import 'training_editor_test.dart' show trainingTap;

Finder pk(String key) => find.byKey(ValueKey(key));
Future<void> settleTactics(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 160 && !done(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<(EditorController, PositionAnalysisController, TrainingController)>
openPosition(
  WidgetTester t, {
  bool precompute = true,
  FakeScenarioFiles? files,
}) async {
  final editor = EditorController()
    ..loadScenario(visionSession(tacticalWorld()));
  editor.files = files;
  editor.selectCharacter('figure-1');
  final c = PositionAnalysisController(editor),
      trainer = TrainingController(TrainingRepository(MemoryStore()));
  await trainer.initialize();
  if (precompute) await t.runAsync(() => c.analyze(only: vc('B2')));
  await t.pumpWidget(
    HeroClixApp(
      clock: testClock,
      controller: editor,
      trainingController: trainer,
    ),
  );
  Navigator.of(t.element(find.byType(Scaffold))).push<void>(
    MaterialPageRoute(
      builder: (_) => TacticalScreen(editor: editor, analysis: c),
    ),
  );
  await t.pumpAndSettle();
  return (editor, c, trainer);
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets('Editor ofrece analizar posición; cancelar cálculo no mueve', (
    t,
  ) async {
    final editor = EditorController()
      ..loadScenario(visionSession(tacticalWorld()));
    editor.selectCharacter('figure-1');
    await t.pumpWidget(HeroClixApp(clock: testClock, controller: editor));
    await t.ensureVisible(find.text('Abrir editor'));
    await t.tap(find.text('Abrir editor'));
    await t.pumpAndSettle();
    await press(t, 'tool-positionAnalysis');
    expect(find.byType(TacticalScreen), findsOneWidget);
    await press(t, 'position-run');
    if (pk('position-cancel').evaluate().isNotEmpty) {
      await press(t, 'position-cancel');
    }
    await press(t, 'position-back');
    expect(editor.value.characters.byId('figure-1')!.position, vc('A1'));
    expect(editor.history.canUndo, false);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'comparación conserva escenario; orden y evidencia son explícitos',
    (t) async {
      final (editor, c, _) = await openPosition(t);
      final original = editor.value;
      expect(pk('position-comparison'), findsOneWidget);
      expect(find.textContaining('Cambio +1'), findsWidgets);
      await press(t, 'position-priority');
      await t.tap(find.text('Reducir líneas enemigas').last);
      await t.pumpAndSettle();
      expect(c.priority, TacticalPriority.reduceExposure);
      await press(t, 'position-enemy-evidence');
      expect(
        find.textContaining('Alcance/visión del mismo par:'),
        findsOneWidget,
      );
      expect(BoardEdit.sameContent(original, editor.value), true);
      await press(t, 'position-back');
      expect(editor.history.canUndo, false);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('confirmación explícita aplica y deshacer restaura origen', (
    t,
  ) async {
    final (editor, _, _) = await openPosition(t);
    await press(t, 'position-confirm');
    await press(t, 'position-confirm-yes');
    expect(editor.value.characters.byId('figure-1')!.position, vc('B2'));
    editor.undo();
    expect(editor.value.characters.byId('figure-1')!.position, vc('A1'));
    expect(t.takeException(), isNull);
  });
  testWidgets('hipótesis se etiqueta y efecto no modelado queda No evaluado', (
    t,
  ) async {
    final (_, c, _) = await openPosition(t);
    await press(t, 'position-improvements');
    await t.runAsync(() => c.analyze(only: vc('B2')));
    await t.pumpAndSettle();
    expect(find.textContaining('HIPÓTESIS: se desactivan'), findsOneWidget);
    expect(pk('position-current-without'), findsOneWidget);
    await press(t, 'position-unknown');
    await t.runAsync(() => c.analyze(only: vc('B2')));
    await t.pumpAndSettle();
    expect(c.chosen!.status, CandidateStatus.notEvaluated);
    expect(pk('position-confirm'), findsNothing);
    expect(find.textContaining('No evaluado:'), findsWidgets);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'crear recorrido desde comparación se practica realmente en Entrenador',
    (t) async {
      final (editor, _, trainer) = await openPosition(t);
      await t.ensureVisible(pk('position-exercise-route'));
      await t.tap(pk('position-exercise-route'));
      await t.pump();
      await settleTactics(t, () => trainer.repository.data.personal.isNotEmpty);
      expect(trainer.repository.data.personal.length, 1);
      final e = trainer.repository.data.personal.single;
      await press(t, 'position-open-trainer');
      await press(t, 'training-start-${e.id}');
      await trainingTap(t, 'B2');
      await press(t, 'training-check');
      expect(t.widget<Text>(pk('training-feedback')).data, 'Acierto');
      expect(editor.value.characters.byId('figure-1')!.position, vc('A1'));
      expect(editor.history.canUndo, false);
      expect(
        t
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .any((p) => p.foregroundPainter is TrainingPainter),
        true,
      );
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'crear pregunta de posición visible guarda rutas y se autocorrige',
    (t) async {
      final (_, _, trainer) = await openPosition(t);
      await t.ensureVisible(pk('position-exercise-visibility'));
      await t.tap(pk('position-exercise-visibility'));
      await t.pump();
      await settleTactics(t, () => trainer.repository.data.personal.isNotEmpty);
      final e = trainer.repository.data.personal.single;
      expect(e.candidateRoutes.length, 2);
      await press(t, 'position-open-trainer');
      await press(t, 'training-start-${e.id}');
      await press(t, 'training-option-B2');
      await press(t, 'training-check');
      expect(t.widget<Text>(pk('training-feedback')).data, 'Acierto');
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('exportación real del resumen usa adaptador y nombre genérico', (
    t,
  ) async {
    final files = FakeScenarioFiles();
    await openPosition(t, files: files);
    await press(t, 'position-export-text');
    expect(files.savedName, 'heroclix_diagnostico.txt');
    expect(files.savedMime, 'text/plain');
    expect(utf8.decode(files.savedBytes!), contains('No es una jugada óptima'));
    expect(t.takeException(), isNull);
  });
  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(800, 360), 1.0),
    (const Size(320, 320), 3.0),
  ]) {
    testWidgets('analizador sin desbordes en $size texto $scale', (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = size;
      t.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await openPosition(t);
      await press(t, 'position-definitions');
      await press(t, 'position-back');
      expect(t.takeException(), isNull);
    });
  }
}

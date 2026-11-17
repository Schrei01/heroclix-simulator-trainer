import 'support/test_clock.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:heroclix_simulator_trainer/app.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_repository.dart';
import 'package:heroclix_simulator_trainer/application/training/training_codec.dart';
import 'package:heroclix_simulator_trainer/application/training/training_repository.dart';
import 'package:heroclix_simulator_trainer/domain/training/exercise.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/board_canvas.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/editor_controller.dart';
import 'package:heroclix_simulator_trainer/presentation/training/training_controller.dart';
import 'package:heroclix_simulator_trainer/presentation/training/training_painter.dart';

import 'support/training_fixtures.dart';
import 'support/scenario_fakes.dart';
import 'editor_test.dart' show cellPosition;
import 'character_editor_test.dart' show press;

Finder tk(String id) => find.byKey(ValueKey(id));
Future<(TrainingController, EditorController)> openTrainer(
  WidgetTester t, {
  MemoryStore? store,
  ScenarioRepository? scenarios,
}) async {
  final trainer = TrainingController(
        TrainingRepository(store ?? MemoryStore()),
        scenarios: scenarios,
      ),
      editor = EditorController();
  await trainer.initialize();
  await t.pumpWidget(
    HeroClixApp(
      clock: testClock,
      controller: editor,
      trainingController: trainer,
    ),
  );
  await t.ensureVisible(find.text('Abrir entrenador'));
  await t.tap(find.text('Abrir entrenador'));
  await t.pumpAndSettle();
  return (trainer, editor);
}

Future<void> trainingTap(WidgetTester t, String label) async {
  final canvas = t.widget<BoardCanvas>(find.byType(BoardCanvas));
  await t.ensureVisible(tk('board-viewport'));
  await t.pumpAndSettle();
  await t.tapAt(cellPosition(t, canvas.controller, label));
  await t.pumpAndSettle();
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'no revela solución antes de comprobar; pista, repetir y revisión no suman intentos',
    (t) async {
      final store = MemoryStore();
      final (c, editor) = await openTrainer(t, store: store);
      final e = trainingExercise('hc10-v02');
      await press(t, 'training-start-${e.id}');
      expect(tk('training-solution'), findsNothing);
      await press(t, 'training-option-clear');
      expect(c.progress(e), isNull);
      expect(tk('training-feedback'), findsNothing);
      await press(t, 'training-hint');
      expect(tk('training-hint-0'), findsOneWidget);
      expect(store.writes, 0);
      await press(t, 'training-check');
      expect(
        t.widget<Text>(tk('training-feedback')).data,
        'Respuesta incorrecta',
      );
      expect(c.progress(e)!.attempts, 1);
      expect(
        t.getRect(tk('training-feedback')).top,
        lessThan(t.view.physicalSize.height),
      );
      expect(c.progress(e)!.usedHint, true);
      await press(t, 'training-repeat');
      expect(c.progress(e)!.attempts, 1);
      expect(tk('training-solution'), findsNothing);
      await press(t, 'training-option-hindered');
      await press(t, 'training-check');
      expect(c.progress(e)!.attempts, 2);
      expect(c.progress(e)!.correct, 1);
      await press(t, 'training-back');
      await t.pumpAndSettle();
      final writes = store.writes;
      await press(t, 'training-review-${e.id}');
      expect(find.textContaining('Revisión guardada.'), findsOneWidget);
      await press(t, 'training-review-close');
      expect(store.writes, writes);
      expect(editor.value.characters.isEmpty, true);
      expect(editor.history.canUndo, false);
      expect(t.takeException(), isNull);
    },
  );
  for (final (id, cell) in [('hc10-v04', 'D4'), ('hc10-m03', 'A2')]) {
    testWidgets('$id se responde tocando el tablero', (t) async {
      final (c, _) = await openTrainer(t);
      await press(t, 'training-start-$id');
      await trainingTap(t, cell);
      expect(tk('training-feedback'), findsNothing);
      await press(t, 'training-check');
      expect(t.widget<Text>(tk('training-feedback')).data, 'Acierto');
      expect(c.progress(trainingExercise(id))!.correct, 1);
      expect(t.takeException(), isNull);
    });
  }
  testWidgets(
    'trazar ruta usa tablero independiente y color neutral antes de comprobar',
    (t) async {
      final (c, editor) = await openTrainer(t);
      await press(t, 'training-start-hc10-m01');
      for (final cell in ['B2', 'C2', 'D1']) {
        await trainingTap(t, cell);
      }
      final painter = t
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((p) => p.foregroundPainter)
          .whereType<TrainingPainter>()
          .single;
      expect(painter.outcome, isNull);
      expect(editor.value.characters.isEmpty, true);
      await press(t, 'training-check');
      expect(t.widget<Text>(tk('training-feedback')).data, 'Acierto');
      expect(c.progress(trainingExercise('hc10-m01'))!.correct, 1);
      await press(t, 'training-next');
      expect(tk('training-solution'), findsNothing);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('justificación y filtros de categoría/dificultad funcionan', (
    t,
  ) async {
    await openTrainer(t);
    await press(t, 'training-category');
    await t.tap(find.text('Terreno y muros').last);
    await t.pumpAndSettle();
    expect(tk('training-start-hc10-v01'), findsNothing);
    expect(tk('training-start-hc10-t01'), findsOneWidget);
    await press(t, 'training-start-hc10-t01');
    await press(t, 'training-option-V06');
    await press(t, 'training-check');
    expect(t.widget<Text>(tk('training-feedback')).data, 'Acierto');
    expect(find.textContaining('16.4b'), findsWidgets);
  });
  testWidgets(
    'practicar errores muestra solo el último fallo y revisar no escribe',
    (t) async {
      final store = MemoryStore();
      final (c, _) = await openTrainer(t, store: store);
      final e = trainingExercise('hc10-v01');
      await c.submit(e, Answer(AnswerKind.choice, value: 'blocked'), 'wrong');
      await t.pumpAndSettle();
      final writes = store.writes;
      await press(t, 'training-mistakes');
      expect(tk('training-start-hc10-v01'), findsOneWidget);
      expect(tk('training-start-hc10-v02'), findsNothing);
      expect(store.writes, writes);
      await press(t, 'training-review-hc10-v01');
      await press(t, 'training-review-close');
      expect(store.writes, writes);
    },
  );
  testWidgets(
    'autor crea ejercicio automático de biblioteca con opciones propias sin editar origen',
    (t) async {
      final scenarios = ScenarioRepository(MemoryStore()),
          doc = trainingScenario();
      await scenarios.save(doc);
      final original = await scenarios.store.read(doc.id);
      final (c, editor) = await openTrainer(t, scenarios: scenarios);
      await press(t, 'training-new');
      await t.enterText(tk('personal-title'), 'Visión creada por mí');
      await t.enterText(
        tk('personal-question'),
        '¿Cómo es la visión de A a B?',
      );
      await t.ensureVisible(tk('personal-option-clear'));
      await t.enterText(tk('personal-option-clear'), 'Libre de obstáculos');
      await t.ensureVisible(tk('personal-hint'));
      await t.enterText(tk('personal-hint'), 'Mira el recorrido.');
      await t.ensureVisible(tk('personal-explanation'));
      await t.enterText(
        tk('personal-explanation'),
        'El escenario tiene una línea libre.',
      );
      await press(t, 'personal-save');
      expect(tk('personal-error'), findsNothing);
      final e = c.repository.data.personal.single;
      expect(e.options.first.label, 'Libre de obstáculos');
      expect(c.check(e).eligible, true);
      expect(await scenarios.store.read(doc.id), original);
      expect(editor.value.characters.isEmpty, true);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'autor manual, revisión textual y reset con confirmación conservan ejercicio',
    (t) async {
      final scenarios = ScenarioRepository(MemoryStore());
      await scenarios.save(trainingScenario());
      final (c, _) = await openTrainer(t, scenarios: scenarios);
      await press(t, 'training-new');
      await press(t, 'personal-kind');
      await t.tap(find.text('Texto · evaluación manual').last);
      await t.pumpAndSettle();
      await t.enterText(tk('personal-title'), 'Explicar mi criterio');
      await t.enterText(tk('personal-question'), '¿Qué revisarías primero?');
      await t.ensureVisible(tk('personal-guide'));
      await t.enterText(
        tk('personal-guide'),
        'Compara tu explicación con los obstáculos y perfiles.',
      );
      await press(t, 'personal-save');
      final e = c.repository.data.personal.single;
      await press(t, 'training-start-${e.id}');
      await t.ensureVisible(tk('training-text'));
      await t.enterText(tk('training-text'), 'Primero revisaría el muro.');
      await press(t, 'training-check');
      expect(t.widget<Text>(tk('training-feedback')).data, 'Revisión manual');
      expect(c.stats(SkillCategory.vision).percentage, isNull);
      expect(c.stats(SkillCategory.vision).manualReviews, 1);
      await press(t, 'training-back');
      await t.pumpAndSettle();
      await press(t, 'training-reset');
      await t.tap(find.text('Cancelar').last);
      await t.pumpAndSettle();
      expect(c.repository.data.progress.length, 1);
      await press(t, 'training-reset');
      await press(t, 'training-reset-confirm');
      expect(c.repository.data.progress, isEmpty);
      expect(c.repository.data.personal.single.id, e.id);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'edición sin soporte queda visible e inhabilitada para autocorrección',
    (t) async {
      final store = MemoryStore();
      store.documents['working'] = const TrainingCodec().encode(
        TrainingData(personal: [personalFixture(version: 'futura')]),
      );
      final (c, _) = await openTrainer(t, store: store);
      final e = c.repository.data.personal.single;
      await t.ensureVisible(tk('training-start-${e.id}'));
      await t.pumpAndSettle();
      expect(
        t.widget<FilledButton>(tk('training-start-${e.id}')).onPressed,
        isNull,
      );
      expect(
        find.textContaining('Autocorrección inhabilitada:'),
        findsOneWidget,
      );
      expect(store.writes, 0);
    },
  );
  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(800, 360), 1.0),
    (const Size(320, 320), 3.0),
  ]) {
    testWidgets(
      'entrenador, pregunta y progreso sin desbordes en $size texto $scale',
      (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = size;
        t.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(t.view.resetDevicePixelRatio);
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        await openTrainer(t);
        await press(t, 'training-progress');
        await press(t, 'training-start-hc10-v01');
        await press(t, 'training-option-clear');
        await press(t, 'training-check');
        await press(t, 'training-repeat');
        expect(t.takeException(), isNull);
      },
    );
  }
}

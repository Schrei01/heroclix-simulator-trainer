import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/application/board/board_edit.dart';
import 'package:heroclix_simulator_trainer/domain/characters/character.dart';
import 'package:heroclix_simulator_trainer/domain/characters/vision_ability.dart';
import 'package:heroclix_simulator_trainer/domain/tactics/tactical_diagnostic.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/edge_wall.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/editor_controller.dart';
import 'package:heroclix_simulator_trainer/presentation/tactics/position_analysis_controller.dart';

import 'support/tactics_contract.dart';
import 'support/vision_contract.dart';
import 'support/scenario_fakes.dart';
import 'vision_state_test.dart' show visionSession;

void main() {
  test(
    'cambiar edición mediante workspace invalida caché sin mutar figuras',
    () async {
      final editor = await persistentController(MemoryStore());
      addTearDown(editor.dispose);
      editor.loadScenario(visionSession(tacticalWorld()));
      editor.workspace!.edited(editor.value);
      await editor.workspace!.save();
      final c = PositionAnalysisController(editor)..chooseSource('figure-1');
      addTearDown(c.dispose);
      await c.analyze(only: vc('B2'));
      final initial = editor.value;
      await editor.workspace!.save(rulesVersion: 'futura');
      expect(c.current, isNull);
      await c.analyze(only: vc('B2'));
      expect(c.chosen!.status, CandidateStatus.notEvaluated);
      expect(c.current!.metrics[TacticalMetric.visible]!.unknown, 1);
      expect(BoardEdit.sameContent(initial, editor.value), true);
    },
  );
  (EditorController, PositionAnalysisController) setup() {
    final editor = EditorController()
      ..loadScenario(visionSession(tacticalWorld()));
    final c = PositionAnalysisController(editor)..chooseSource('figure-1');
    addTearDown(c.dispose);
    addTearDown(editor.dispose);
    return (editor, c);
  }

  test('isolate real calcula actual y candidato; consulta no altera contenido ni historial', () async {
    final (editor, c) = setup();
    final initial = editor.value;
    await c.analyze(only: vc('B2'));
    expect(c.busy, false);
    expect(c.error, isNull);
    expect(c.current!.metrics[TacticalMetric.visible]!.known, 0);
    expect(c.chosen!.position!.metrics[TacticalMetric.visible]!.known, 1);
    expect(BoardEdit.sameContent(initial, editor.value), true);
    expect(editor.history.canUndo, false);
  });
  test(
    'prioridad y cámara conservan caché; consulta repetida reutiliza página',
    () async {
      final (editor, c) = setup();
      await c.analyze(only: vc('B2'));
      final current = c.current;
      c.setPriority(TacticalPriority.reduceExposure);
      editor.zoom(1.2);
      expect(c.current, same(current));
      await c.analyze(only: vc('B2'));
      expect(c.cacheHits, 1);
      expect(c.current, same(current));
      expect(c.selected, vc('B2'));
      expect(c.chosen!.status, CandidateStatus.legal);
    },
  );
  test('muro, capacidades y efecto general invalidan resultados', () async {
    final (editor, c) = setup();
    await c.analyze(only: vc('B2'));
    editor.attempt(
      (s) => s.editWalls([EdgeWall.between(vc('B1'), vc('C1'))], erase: true),
    );
    expect(c.current, isNull);
    await c.analyze(only: vc('B2'));
    expect(c.current!.metrics[TacticalMetric.visible]!.known, 1);
    final f = editor.value.characters.byId('figure-1')!;
    editor.saveCharacter(
      CharacterDraft(
        name: f.name,
        teamId: f.teamId,
        position: f.position,
        abilities: [VisionAbility.other],
      ),
      id: f.id,
    );
    expect(c.current, isNull);
    await c.analyze(only: vc('B2'));
    expect(c.current!.complete, false);
    editor.updateVision((v) => v.specialEffects = true);
    expect(c.current, isNull);
    await c.analyze(only: vc('B2'));
    expect(c.chosen!.status, CandidateStatus.notEvaluated);
  });
  test(
    'cancelar cálculo no publica resultados tardíos ni mueve la figura',
    () async {
      final (editor, c) = setup();
      final initial = editor.value;
      final pending = c.analyze();
      expect(c.busy, true);
      c.cancel();
      await pending;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(c.cancelled, true);
      expect(c.busy, false);
      expect(c.current, isNull);
      expect(c.candidates, isEmpty);
      expect(BoardEdit.sameContent(initial, editor.value), true);
      expect(editor.history.canUndo, false);
    },
  );
  test('confirmación revalida y se deshace como una operación', () async {
    final (editor, c) = setup();
    await c.analyze(only: vc('B2'));
    expect(c.confirm(), isNull);
    expect(editor.value.characters.byId('figure-1')!.position, vc('B2'));
    expect(editor.history.undoCount, 1);
    expect(c.current, isNull);
    editor.undo();
    expect(editor.value.characters.byId('figure-1')!.position, vc('A1'));
    editor.redo();
    expect(editor.value.characters.byId('figure-1')!.position, vc('B2'));
  });
  test('otra edición y carga descartan páginas anteriores', () async {
    final (editor, c) = setup();
    await c.analyze(only: vc('B2'));
    editor.loadScenario(visionSession(tacticalWorld(wall: false)));
    expect(c.current, isNull);
    await c.analyze(only: vc('B2'));
    expect(c.current!.metrics[TacticalMetric.visible]!.known, 1);
    c.setUnknown(true);
    expect(c.current, isNull);
    await c.analyze(only: vc('B2'));
    expect(c.current!.complete, false);
    expect(c.chosen!.status, CandidateStatus.notEvaluated);
  });
  test(
    'página segmentada, comparación de mejoras y cancelación de selección',
    () async {
      final (editor, c) = setup();
      c.setComparison(true);
      await c.analyze();
      expect(
        c.candidates.length,
        lessThanOrEqualTo(PositionAnalysisController.pageSize),
      );
      expect(c.alternateCurrent, isNotNull);
      final candidate = c.candidates
          .where((p) => p.status == CandidateStatus.legal)
          .first;
      c.select(candidate.cell);
      expect(c.chosen, isNotNull);
      c.cancel();
      expect(editor.value.characters.byId('figure-1')!.position, vc('A1'));
      expect(c.chosen!.alternate, isNotNull);
    },
  );
}

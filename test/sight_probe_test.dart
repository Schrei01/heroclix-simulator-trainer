import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/application/board/board_session.dart';
import 'package:heroclix_simulator_trainer/application/board/sight_probe.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_codec.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_dimensions.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_viewport.dart';
import 'package:heroclix_simulator_trainer/domain/board/cell_coordinate.dart';
import 'package:heroclix_simulator_trainer/domain/characters/character.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/edge_wall.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/terrain.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/editor_controller.dart';

import 'support/scenario_fakes.dart';

CellCoordinate c(String label) => CellCoordinate.parse(label);
CharacterDraft figure(String label, {Footprint footprint = Footprint.single}) =>
    CharacterDraft(
      name: 'Prueba',
      teamId: 'team-1',
      position: c(label),
      footprint: footprint,
    );
void endpoints(EditorController controller) {
  controller.setSightEndpoint(ProbeEndpoint.cell(c('A1')), asOrigin: true);
  controller.setSightEndpoint(ProbeEndpoint.cell(c('D4')), asOrigin: false);
}

void main() {
  test('inspeccionar, invertir y ocultar no modifica documento, autoguardado o historial', () async {
    final store = MemoryStore(), controller = await persistentController(store);
    addTearDown(controller.dispose);
    await controller.workspace!.save();
    final before = const ScenarioCodec().encode(controller.workspace!.current),
        writes = store.writes;
    endpoints(controller);
    final trace = controller.sight.trace!;
    controller.updateSight((p) {
      p.swap();
      p.showCells = false;
      p.showLine = false;
      p.showContacts = false;
    });
    expect(controller.sight.trace!.path.origin, c('D4'));
    expect(
      controller.sight.trace!.segments.map((s) => s.cell),
      trace.segments.map((s) => s.cell).toList().reversed,
    );
    expect(controller.history.canUndo, isFalse);
    expect(controller.workspace!.dirty, isFalse);
    expect(const ScenarioCodec().encode(controller.workspace!.current), before);
    expect(store.writes, writes);
  });
  test('una figura 2×2 sigue la referencia relativa al mover y deshacer', () {
    final controller = EditorController();
    addTearDown(controller.dispose);
    controller.saveCharacter(figure('A1', footprint: Footprint.square2));
    controller.setSightEndpoint(
      const ProbeEndpoint.figure('figure-1', columnOffset: 1, rowOffset: 1),
      asOrigin: true,
    );
    controller.setSightEndpoint(ProbeEndpoint.cell(c('D4')), asOrigin: false);
    expect(controller.sight.trace!.path.origin, c('B2'));
    controller.moveCharacter('figure-1', c('B2'));
    expect(controller.sight.trace!.path.origin, c('C3'));
    controller.undo();
    expect(controller.sight.trace!.path.origin, c('B2'));
    controller.redo();
    expect(controller.sight.trace!.path.origin, c('C3'));
  });
  test(
    'borrar figura elimina resultado obsoleto y undo recupera trayectoria',
    () {
      final controller = EditorController();
      addTearDown(controller.dispose);
      controller.saveCharacter(figure('A1'));
      controller.setSightEndpoint(
        const ProbeEndpoint.figure('figure-1'),
        asOrigin: true,
      );
      controller.setSightEndpoint(ProbeEndpoint.cell(c('D4')), asOrigin: false);
      controller.deleteCharacter('figure-1');
      expect(controller.sight.trace, isNull);
      expect(controller.sight.error, contains('eliminada'));
      controller.undo();
      expect(controller.sight.error, isNull);
      expect(controller.sight.trace!.path.origin, c('A1'));
    },
  );
  test('cambiar huella invalida referencia y deshacer la restaura', () {
    final controller = EditorController();
    addTearDown(controller.dispose);
    controller.saveCharacter(figure('A1', footprint: Footprint.square2));
    controller.setSightEndpoint(
      const ProbeEndpoint.figure('figure-1', columnOffset: 1, rowOffset: 1),
      asOrigin: true,
    );
    controller.setSightEndpoint(ProbeEndpoint.cell(c('D4')), asOrigin: false);
    controller.saveCharacter(figure('A1'), id: 'figure-1');
    expect(controller.sight.trace, isNull);
    expect(controller.sight.error, contains('base'));
    controller.undo();
    expect(controller.sight.trace, isNotNull);
  });
  test(
    'reducir invalida casilla fija sin recortar y ampliar o undo recupera',
    () {
      final controller = EditorController();
      addTearDown(controller.dispose);
      endpoints(controller);
      controller.changeDimensions(BoardDimensions(rows: 2, columns: 2));
      expect(controller.sight.trace, isNull);
      expect(controller.sight.error, contains('fuera del tablero'));
      controller.undo();
      expect(controller.sight.trace!.path.destination, c('D4'));
    },
  );
  test(
    'editar muro recalcula contactos; terreno y cámara no repiten geometría',
    () {
      final controller = EditorController();
      addTearDown(controller.dispose);
      endpoints(controller);
      final initial = controller.sight.trace;
      controller.resizeViewport(ViewportSize(300, 600));
      controller.zoom(1.25);
      controller.attempt(
        (s) => s.paintTerrain([c('A1')], TerrainType.hindering),
      );
      expect(identical(controller.sight.trace, initial), isTrue);
      final edge = EdgeWall.between(c('A1'), c('B1'));
      controller.attempt((s) => s.editWalls([edge], erase: false));
      expect(identical(controller.sight.trace, initial), isFalse);
      expect(
        controller.sight.trace!.crossings.first.contacts
            .where((c) => c.hasWall)
            .single
            .edge,
        edge,
      );
      controller.undo();
      expect(
        controller.sight.trace!.crossings
            .expand((c) => c.contacts)
            .any((c) => c.hasWall),
        isFalse,
      );
    },
  );
  test(
    'casilla fija no sigue figura y cargar otra escena limpia referencias',
    () {
      final controller = EditorController();
      addTearDown(controller.dispose);
      controller.saveCharacter(figure('A1'));
      endpoints(controller);
      controller.moveCharacter('figure-1', c('B1'));
      expect(controller.sight.trace!.path.origin, c('A1'));
      controller.loadScenario(BoardSession.initial());
      expect(controller.sight.trace, isNull);
      expect(controller.sight.origin, isNull);
      expect(controller.sight.destination, isNull);
    },
  );
  test('extremos inválidos fallan incluso si aún falta el segundo', () {
    final p = SightProbe();
    p.setEndpoint(ProbeEndpoint.cell(c('E1')), asOrigin: true);
    p.evaluate(BoardSession.initial());
    expect(p.error, contains('fuera del tablero'));
    expect(p.trace, isNull);
    expect(
      () =>
          const ProbeEndpoint.figure('missing').resolve(BoardSession.initial()),
      throwsArgumentError,
    );
    final session = BoardSession.initial().createCharacter(figure('A1'));
    expect(
      () => const ProbeEndpoint.figure(
        'figure-1',
        columnOffset: -1,
      ).resolve(session),
      throwsArgumentError,
    );
  });
}

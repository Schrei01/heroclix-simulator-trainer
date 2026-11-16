import 'package:flutter/foundation.dart';

import '../../application/board/board_session.dart';
import '../../domain/board/board_dimensions.dart';
import '../../domain/board/board_viewport.dart';
import '../../domain/board/cell_coordinate.dart';
import '../../domain/characters/character.dart';
import '../../domain/characters/character_repository.dart';
import '../../domain/characters/team.dart';
import '../../application/board/board_edit.dart';
import '../../application/board/layer_draft.dart';
import '../../domain/terrain/terrain.dart';
import '../scenarios/workspace_controller.dart';
import '../../application/ports/scenario_files.dart';
import '../../application/board/sight_probe.dart';
import '../../application/board/vision_analysis.dart';
import '../../domain/rules/line_of_sight.dart';
import '../../application/board/tactical_analysis.dart';
import '../../application/board/movement_analysis.dart';

/// Adaptador de notificación: la sesión y las conversiones usan Dart puro.
final class EditorController extends ValueNotifier<BoardSession> {
  EditorController() : super(BoardSession.initial());
  final draft = ValueNotifier<LayerDraft?>(null);
  final history = EditorHistory();
  final sight = SightProbe();
  final vision = VisionAnalysis();
  final tactical = TacticalAnalysis();
  final movement = MovementAnalysis();
  String get rulesVersion =>
      workspace?.current.rulesVersion ?? VisionContext.supportedVersion;
  void _evaluateVision(BoardSession next) {
    tactical.sync(
      next,
      sight,
      VisionContext(
        rulesVersion: rulesVersion,
        features: [if (vision.specialEffects) VisionFeature.powersOrSizes],
        laboratoryAbilities: vision.laboratoryAbilities,
      ),
    );
    vision.evaluate(
      next,
      sight,
      rulesVersion,
      selectedTarget: next.tool == EditorTool.targets
          ? tactical.selected?.vision
          : null,
    );
  }

  void updateTactical(void Function(TacticalAnalysis) change) {
    change(tactical);
    _evaluateVision(value);
    notifyListeners();
  }

  void enableTargets() => updateTactical((t) {
    t.enabled = true;
    t.sourceId ??= value.selectedCharacterId ?? sight.origin?.figureId;
  });
  void selectTarget(String id) {
    final source = tactical.sourceId;
    if (source == null || value.characters.byId(id) == null || source == id) {
      return;
    }
    tactical.selectedTargetId = id;
    final selected = tactical.report?.targets
        .where((t) => t.target.id == id)
        .firstOrNull;
    final sourceFigure = value.characters.byId(source);
    final targetFigure = value.characters.byId(id);
    if (sourceFigure == null || targetFigure == null) return;
    final from = selected?.vision.origin?.cell ?? sourceFigure.position;
    final to = selected?.vision.destination?.cell ?? targetFigure.position;
    sight.setEndpoint(
      ProbeEndpoint.figure(
        source,
        columnOffset: from.column - sourceFigure.position.column,
        rowOffset: from.row - sourceFigure.position.row,
      ),
      asOrigin: true,
    );
    sight.setEndpoint(
      ProbeEndpoint.figure(
        id,
        columnOffset: to.column - targetFigure.position.column,
        rowOffset: to.row - targetFigure.position.row,
      ),
      asOrigin: false,
    );
    vision.enabled = true;
    sight.evaluate(value);
    _evaluateVision(value);
    value = value.selectCharacter(id);
  }

  void updateVision(void Function(VisionAnalysis) change) {
    change(vision);
    _evaluateVision(value);
    notifyListeners();
  }

  void _onWorkspace() {
    _evaluateVision(value);
    notifyListeners();
  }

  @override
  set value(BoardSession next) {
    movement.sync(next);
    sight.evaluate(next);
    _evaluateVision(next);
    super.value = next;
  }

  void setSightEndpoint(ProbeEndpoint endpoint, {required bool asOrigin}) {
    sight.setEndpoint(endpoint, asOrigin: asOrigin);
    sight.evaluate(value);
    _evaluateVision(value);
    notifyListeners();
  }

  void updateSight(void Function(SightProbe) change) {
    change(sight);
    sight.evaluate(value);
    _evaluateVision(value);
    notifyListeners();
  }

  WorkspaceController? workspace;
  ScenarioFiles? files;
  bool fileBusy = false, _closed = false;
  void setFileBusy(bool busy) {
    fileBusy = busy;
    if (!_closed) notifyListeners();
  }

  void attachWorkspace(WorkspaceController workspace) {
    this.workspace = workspace;
    workspace.addListener(_onWorkspace);
    notifyListeners();
  }

  void loadScenario(BoardSession session) {
    cancelDraft();
    sight.clear();
    vision.clear();
    tactical.clear();
    movement.clear();
    history.clear();
    _lastEdit = null;
    value = session;
  }

  String? undo() => _historyOperation(true);
  String? redo() => _historyOperation(false);
  String? _historyOperation(bool undo) {
    if (workspace?.loading == true || workspace?.switching == true) {
      return 'Espera a que termine la operación de archivo.';
    }
    try {
      final before = value;
      final after = undo ? history.undo(before) : history.redo(before);
      if (after != before) {
        cancelDraft();
        value = after;
        workspace?.edited(after);
      }
      return null;
    } on StateError {
      return 'El historial no corresponde al escenario actual.';
    }
  }

  BoardEdit? _lastEdit;
  BoardEdit? get lastEdit => _lastEdit;
  void cancelDraft() => draft.value = null;
  void configureLayers({
    TerrainType? type,
    bool? rectangle,
    bool? removeWalls,
    EraseLayer? erase,
  }) {
    cancelDraft();
    value = value.configureLayers(
      type: type,
      rectangle: rectangle,
      removeWalls: removeWalls,
      erase: erase,
    );
  }

  @override
  void dispose() {
    _closed = true;
    workspace?.removeListener(_onWorkspace);
    workspace?.dispose();
    draft.dispose();
    super.dispose();
  }

  void resizeViewport(ViewportSize size) => value = value.resizeViewport(size);
  void setCamera(BoardCamera camera) => value = value.withCamera(camera);
  void tap(BoardPoint point) => value = value.tapViewport(point);
  void clearSelection() => value = value.clearSelection();
  void changeDimensions(BoardDimensions dimensions) =>
      attempt((session) => session.changeDimensions(dimensions));
  void toggleGrid() => value = value.toggleGrid();
  void toggleCoordinates() => value = value.toggleCoordinates();
  void zoom(double factor) => value = value.zoom(factor);
  void centerCamera() => value = value.centerCamera();
  void resetCamera() => value = value.resetCamera();
  void setTool(EditorTool tool) {
    cancelDraft();
    if (tool != EditorTool.movement) movement.clear();
    if (tool == EditorTool.targets) enableTargets();
    value = value.setTool(tool);
    if (tool == EditorTool.movement &&
        movement.sourceId == null &&
        value.selectedCharacterId != null) {
      beginMovement(value.selectedCharacterId!);
    }
  }

  void updateMovement(void Function(MovementAnalysis) change) {
    change(movement);
    notifyListeners();
  }

  void beginMovement(String id) {
    movement.begin(value, id, rulesVersion);
    notifyListeners();
  }

  void movementCell(CellCoordinate cell) {
    if (movement.sourceId == null) {
      final f = value.characters.at(cell);
      if (f != null) beginMovement(f.id);
    } else {
      updateMovement((m) => m.append(cell));
    }
  }

  String? confirmMovement() {
    final m = movement, original = m.original, id = m.sourceId;
    if (original == null ||
        id == null ||
        m.context.rulesVersion != rulesVersion ||
        !BoardEdit.sameContent(original, value)) {
      m.clear();
      notifyListeners();
      return 'El escenario cambió; inicia otro ensayo.';
    }
    final fresh = MovementAnalysis.rules.evaluate(
      m.snapshot(value),
      id,
      m.route,
      context: m.context,
    );
    if (!fresh.canConfirm) return fresh.reason;
    return moveCharacter(id, fresh.route.last);
  }

  void setTargetSource(String id) {
    sight.clear();
    updateTactical((t) {
      t.enabled = true;
      t.sourceId = id;
      t.selectedTargetId = null;
    });
  }

  void selectCharacter(String id) => value = value.selectCharacter(id);
  void deleteCharacter(String id) =>
      attempt((session) => session.deleteCharacter(id));
  String? attempt(BoardSession Function(BoardSession) operation) {
    if (workspace?.loading == true || workspace?.switching == true) {
      return 'Espera a que termine la operación de archivo.';
    }
    try {
      final before = value;
      final after = operation(before);
      final command = BoardEdit.between(before, after);
      if (command.changesLayers) {
        _lastEdit = command;
        history.record(command);
        cancelDraft();
      }
      value = after;
      if (command.changesLayers) workspace?.edited(after);
      return null;
    } on PlacementException catch (error) {
      return error.message;
    } on ArgumentError catch (error) {
      return error.message?.toString() ?? 'Datos inválidos.';
    }
  }

  String? saveCharacter(
    CharacterDraft data, {
    String? id,
    bool allowStudy = false,
  }) => attempt(
    (session) => id == null
        ? session.createCharacter(data, allowStudy: allowStudy)
        : session.editCharacter(id, data, allowStudy: allowStudy),
  );
  String? moveCharacter(String id, CellCoordinate cell) =>
      attempt((session) => session.moveCharacter(id, cell));
  String? addTeam(String name, int color, TeamPattern pattern) => attempt(
    (session) => session.addTeam(name: name, color: color, pattern: pattern),
  );
}

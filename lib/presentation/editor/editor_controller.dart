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

/// Adaptador de notificación: la sesión y las conversiones usan Dart puro.
final class EditorController extends ValueNotifier<BoardSession> {
  EditorController() : super(BoardSession.initial());
  final draft = ValueNotifier<LayerDraft?>(null);
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
    draft.dispose();
    super.dispose();
  }

  void resizeViewport(ViewportSize size) => value = value.resizeViewport(size);
  void setCamera(BoardCamera camera) => value = value.withCamera(camera);
  void tap(BoardPoint point) => value = value.tapViewport(point);
  void clearSelection() => value = value.clearSelection();
  void changeDimensions(BoardDimensions dimensions) =>
      value = value.changeDimensions(dimensions);
  void toggleGrid() => value = value.toggleGrid();
  void toggleCoordinates() => value = value.toggleCoordinates();
  void zoom(double factor) => value = value.zoom(factor);
  void centerCamera() => value = value.centerCamera();
  void resetCamera() => value = value.resetCamera();
  void setTool(EditorTool tool) {
    cancelDraft();
    value = value.setTool(tool);
  }

  void selectCharacter(String id) => value = value.selectCharacter(id);
  void deleteCharacter(String id) =>
      attempt((session) => session.deleteCharacter(id));
  String? attempt(BoardSession Function(BoardSession) operation) {
    try {
      final before = value;
      final after = operation(before);
      final command = BoardEdit.between(before, after);
      if (command.changesLayers) {
        _lastEdit = command;
        cancelDraft();
      }
      value = after;
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

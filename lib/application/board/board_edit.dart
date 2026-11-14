import 'board_session.dart';

/// Referencias a contenido inmutable por operación terminada, nunca por píxel.
final class BoardEdit {
  BoardEdit.between(this._before, this._after);
  final BoardSession _before, _after;
  static bool sameContent(BoardSession a, BoardSession b) =>
      a.dimensions == b.dimensions &&
      a.terrain == b.terrain &&
      a.walls == b.walls &&
      a.characters == b.characters &&
      a.teams == b.teams;
  bool get changesLayers => !sameContent(_before, _after);
  BoardSession reverse(BoardSession current) {
    if (!sameContent(current, _after)) {
      throw StateError('El comando no corresponde al estado actual.');
    }
    return current.restoreContent(_before);
  }

  BoardSession apply(BoardSession current) {
    if (!sameContent(current, _before)) {
      throw StateError('El comando no corresponde al estado actual.');
    }
    return current.restoreContent(_after);
  }
}

final class EditorHistory {
  EditorHistory({this.limit = 100}) {
    if (limit < 1 || limit > 1000) throw RangeError.range(limit, 1, 1000);
  }
  final int limit;
  final _undo = <BoardEdit>[], _redo = <BoardEdit>[];
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  int get undoCount => _undo.length;
  void record(BoardEdit edit) {
    if (!edit.changesLayers) return;
    _undo.add(edit);
    if (_undo.length > limit) _undo.removeAt(0);
    _redo.clear();
  }

  BoardSession undo(BoardSession current) {
    if (!canUndo) return current;
    final result = _undo.last.reverse(current);
    _redo.add(_undo.removeLast());
    return result;
  }

  BoardSession redo(BoardSession current) {
    if (!canRedo) return current;
    final result = _redo.last.apply(current);
    _undo.add(_redo.removeLast());
    return result;
  }

  void clear() {
    _undo.clear();
    _redo.clear();
  }
}

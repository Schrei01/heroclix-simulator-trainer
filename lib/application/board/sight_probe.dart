import '../../domain/board/cell_coordinate.dart';
import '../../domain/geometry/sight_geometry.dart';
import 'board_session.dart';

/// Extremo fijo o referencia relativa a la huella de una figura que puede moverse.
final class ProbeEndpoint {
  const ProbeEndpoint.cell(CellCoordinate this.cell)
    : figureId = null,
      columnOffset = 0,
      rowOffset = 0;
  const ProbeEndpoint.figure(
    String id, {
    this.columnOffset = 0,
    this.rowOffset = 0,
  }) : figureId = id,
       cell = null;
  final CellCoordinate? cell;
  final String? figureId;
  final int columnOffset, rowOffset;
  CellCoordinate resolve(BoardSession session) {
    if (figureId == null) {
      if (cell == null || !session.dimensions.contains(cell!)) {
        throw ArgumentError('Casilla de referencia fuera del tablero.');
      }
      return cell!;
    }
    final figure = session.characters.byId(figureId!);
    if (figure == null) {
      throw ArgumentError(
        'La figura de un extremo fue eliminada. Vuelve a elegirlo.',
      );
    }
    if (columnOffset < 0 ||
        rowOffset < 0 ||
        columnOffset >= figure.footprint.width ||
        rowOffset >= figure.footprint.height) {
      throw ArgumentError(
        'La referencia ya no pertenece a la base de la figura. Vuelve a elegirla.',
      );
    }
    final result = CellCoordinate(
      column: figure.position.column + columnOffset,
      row: figure.position.row + rowOffset,
    );
    if (!session.dimensions.contains(result)) {
      throw ArgumentError('Figura fuera del tablero.');
    }
    return result;
  }

  String describe(BoardSession session) {
    try {
      final resolved = resolve(session);
      if (figureId == null) return 'Casilla ${resolved.label}';
      final figure = session.characters.byId(figureId!)!;
      return '${figure.label} · ${figure.name} · ref ${resolved.label} · base ${figure.footprint.label}';
    } on ArgumentError catch (error) {
      return error.message.toString();
    }
  }
}

/// Estado transitorio de inspección, separado del mundo guardado y del historial.
final class SightProbe {
  ProbeEndpoint? origin, destination;
  bool chooseOrigin = true;
  bool showLine = true, showCells = true, showContacts = true;
  GeometricTrace? trace;
  String? error;
  BoardSession? _evaluated;
  void setEndpoint(ProbeEndpoint endpoint, {required bool asOrigin}) {
    if (asOrigin) {
      origin = endpoint;
    } else {
      destination = endpoint;
    }
    chooseOrigin = !asOrigin;
    _evaluated = null;
  }

  void swap() {
    final previous = origin;
    origin = destination;
    destination = previous;
    _evaluated = null;
  }

  void clear() {
    origin = destination = null;
    trace = null;
    error = null;
    _evaluated = null;
    chooseOrigin = true;
  }

  void evaluate(BoardSession session) {
    final old = _evaluated;
    if (old != null &&
        old.dimensions == session.dimensions &&
        old.characters == session.characters &&
        old.walls == session.walls) {
      return;
    }
    _evaluated = session;
    trace = null;
    error = null;
    try {
      final a = origin?.resolve(session), b = destination?.resolve(session);
      if (a != null && b != null) {
        trace = const SightGeometry().trace(
          session.dimensions,
          SightPath(id: 'selected', origin: a, destination: b),
          walls: session.walls,
        );
      }
    } on ArgumentError catch (exception) {
      error = exception.message.toString();
    }
  }
}

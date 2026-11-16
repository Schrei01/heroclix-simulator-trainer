import 'dart:math' as math;

import '../board/board_dimensions.dart';
import '../board/cell_coordinate.dart';
import 'line_of_sight.dart';

enum TacticalRule {
  distance('D01', '11.3a', 26),
  range('D02', '11.3b', 26),
  source('D03', '11.4a', 27),
  targets('D04', '11.5', 28),
  attack('D05', '12.1', 28),
  multiBase('D06', '24.2e', 70),
  limit('SCOPE', 'Límite de implementación', null);

  const TacticalRule(this.id, this.section, this.page);
  final String id, section;
  final int? page;
  String get citation =>
      '$id · ${page == null ? section : '§$section · p. $page'}';
}

final class DistanceMeasurement {
  const DistanceMeasurement({
    this.squares,
    this.rows,
    this.columns,
    this.reason,
  });
  final int? squares, rows, columns;
  final String? reason;
  bool get evaluated => squares != null;
  List<TacticalRule> get rules => [
    TacticalRule.distance,
    if (!evaluated) TacticalRule.limit,
  ];
}

/// §11.3a: cero en origen, un incremento por casilla en ocho direcciones.
/// max(|Δfila|, |Δcolumna|) es la cuenta mínima derivada de esa regla.
/// Mide casillas: no busca rutas de movimiento ni evita obstáculos.
final class DistanceService {
  const DistanceService();
  DistanceMeasurement measure(
    BoardDimensions dimensions,
    CellCoordinate origin,
    CellCoordinate destination, {
    String rulesVersion = VisionContext.supportedVersion,
  }) {
    if (rulesVersion != VisionContext.supportedVersion) {
      return const DistanceMeasurement(
        reason: 'Versión de reglas sin soporte.',
      );
    }
    if (!dimensions.contains(origin) || !dimensions.contains(destination)) {
      return const DistanceMeasurement(
        reason: 'Origen o destino fuera del tablero.',
      );
    }
    final rows = (destination.row - origin.row).abs();
    final columns = (destination.column - origin.column).abs();
    return DistanceMeasurement(
      squares: math.max(rows, columns),
      rows: rows,
      columns: columns,
    );
  }
}
